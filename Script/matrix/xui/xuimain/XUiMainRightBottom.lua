local XUiMainPanelBase = require("XUi/XUiMain/XUiMainPanelBase")
local XUiMainRightBottom = XClass(XUiMainPanelBase, "XUiMainRightBottom")

local TipsMainViewTextMovePauseInterval = CS.XGame.ClientConfig:GetFloat("TipsMainViewTextMovePauseInterval")
local TipsMainViewTextMoveSpeed = CS.XGame.ClientConfig:GetFloat("TipsMainViewTextMoveSpeed")

local TipsType = {
    Normal = 1,
    Music  = 2,
}

--主界面会频繁打开，采用常量缓存
local RedPointConditionGroup = {
    --终端
    Terminal = {
        XRedPointConditions.Types.CONDITION_MAIN_TERMINAL
    }
}

function XUiMainRightBottom:OnStart(rootUi)
    -- self.Transform = rootUi.PanelRightBottom.gameObject.transform
    self.RootUi = rootUi
    -- XTool.InitUiObject(self)
    self.GridTips = {}
    --Filter
    self:CheckFilterFunctions()
    
    
    self.BtnTerminal.CallBack = function() self:OnBtnTerminalClick() end
    
    --RedPoint
    self.TerminalRedPoint = XRedPointManager.AddRedPointEvent(self.BtnTerminal, self.OnCheckBtnTerminalRedPoint, self, RedPointConditionGroup.Terminal)
    
    self.TxtTips.gameObject:SetActiveEx(false)
    self.TxtMusic.gameObject:SetActiveEx(false)
    
    self.LayoutGroup = self.TipsContent:GetComponent("XAutoLayoutGroup")
end

function XUiMainRightBottom:OnEnable()
    self:RefreshTips()
    self:CheckRedPoint()
    self:StartTimer()
    --界面状态事件，也会触发红点检查
    XEventManager.AddEventListener(XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE, self.RefreshTips, self)
end

function XUiMainRightBottom:OnDisable()
    if self.ScrollSequence then
        self.ScrollSequence:Kill()
        self.ScrollSequence = nil
    end
    self:StopTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE, self.RefreshTips, self)

    self:ClearGrids()
end

function XUiMainRightBottom:OnDestroy()
    if self.TerminalRedPoint then
        XRedPointManager.RemoveRedPointEvent(self.TerminalRedPoint)
    end
end

function XUiMainRightBottom:CheckFilterFunctions()

end

function XUiMainRightBottom:StartTimer()
 
end

function XUiMainRightBottom:StopTimer()
  
end

function XUiMainRightBottom:GetScrollTips()
    -- 月卡优先级 大于 礼包优先级
    local tipList = {}

    if XDataCenter.PurchaseManager.CheckYKContinueBuy() then
        table.insert(tipList, {
            Tips = XUiHelper.GetText("PurchaseYKExpireDes"),
            Type = TipsType.Normal
        })
    end

    local giftCount = XDataCenter.PurchaseManager.ExpireCount or 0
    if giftCount == 1 then
        table.insert(tipList,
                {
                    Tips = XUiHelper.GetText("PurchaseGiftValitimeTips1"),
                    Type = TipsType.Normal
                })
    elseif giftCount > 1 then
        table.insert(tipList,
                {
                    Tips = XUiHelper.GetText("PurchaseGiftValitimeTips2"),
                    Type = TipsType.Normal
                })
    end
    
    -- 宿舍终端提示 可领取 > 可派遣
    local dispatchedCount, unDispatchCount = XDataCenter.DormQuestManager.GetEntranceShowData()
    if dispatchedCount > 0 then
        table.insert(tipList,
                {
                    Tips = XUiHelper.GetText("DormQuestTerminalMainTeamRegress", dispatchedCount),
                    Type = TipsType.Normal
                })
    elseif unDispatchCount > 0 then
        table.insert(tipList,
                {
                    Tips = XUiHelper.GetText("DormQuestTerminalMainTeamFree", unDispatchCount),
                    Type = TipsType.Normal
                })
    end
    
    if XTool.IsTableEmpty(tipList) then
        local albumId = XDataCenter.MusicPlayerManager.GetUiMainNeedPlayedAlbumId()
        local template = XMusicPlayerConfigs.GetAlbumTemplateById(albumId)
        if template then
            local name = string.format("%s - %s",
                    string.gsub(XUiHelper.ReplaceTextNewLine(template.Name), "\n", ""),
                    string.gsub(XUiHelper.ReplaceTextNewLine(template.Composer), "\n", ""))
            table.insert(tipList, {
                Tips = name,
                Type = TipsType.Music
            })
        end
    end
    
    return tipList
end

function XUiMainRightBottom:RefreshTips()
    if self.ScrollSequence then
        self.ScrollSequence:Kill()
        self.ScrollSequence = nil
    end
    -- 月卡优先级 大于 礼包优先级
    local tipList = self:GetScrollTips()
    
    self.NeedScroll = not XTool.IsTableEmpty(tipList)

    for _, map in pairs(self.GridTips) do
        for _, grid in pairs(map or {}) do
            if grid and not XTool.UObjIsNil(grid.GameObject) then
                grid.GameObject:SetActiveEx(false)
            end
        end
    end

    for i, tip in ipairs(tipList) do
        self.GridTips[tip.Type] = self.GridTips[tip.Type] or {}
        local grid = self.GridTips[tip.Type][i]
        if not grid then
            local tmpGrid = tip.Type == TipsType.Normal and self.TxtTips.gameObject or self.TxtMusic.gameObject
            local ui = XUiHelper.Instantiate(tmpGrid, self.TipsContent)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.GridTips[tip.Type][i] = grid
        end
        grid.TxtTips.text = tip.Tips
        grid.GameObject:SetActiveEx(true)
        if tip.Type == TipsType.Normal then
            grid.Image2.gameObject:SetActiveEx(true)
            grid.Image1.gameObject:SetActiveEx(true)
        elseif tip.Type == TipsType.Music then
            grid.IconMusic.gameObject:SetActiveEx(true)
        end
    end
    self:ScrollTips()
end

function XUiMainRightBottom:ClearGrids()
    for _, map in pairs(self.GridTips) do
        for _, grid in pairs(map or {}) do
            if grid and not XTool.UObjIsNil(grid.GameObject) then
                XUiHelper.Destroy(grid.GameObject)
            end
        end
    end
    self.GridTips = {}
end

function XUiMainRightBottom:ScrollTips()
    if not self.NeedScroll then
        return
    end

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.TipsContent)
    local width = self.TipsContent.rect.width + self.LayoutGroup.Padding.horizontal
    local maskWidth = self.PanelTipText.sizeDelta.x
    local distance = width + maskWidth
    local sequence = CS.DG.Tweening.DOTween.Sequence()
    local pos = self.TipsContent.localPosition
    pos.x = pos.x + maskWidth
    self.TipsContent.localPosition = pos
    sequence:Append(self.TipsContent:DOLocalMoveX(-width, distance / TipsMainViewTextMoveSpeed))
    sequence:AppendInterval(TipsMainViewTextMovePauseInterval)
    sequence:SetLoops(-1)
    self.ScrollSequence = sequence
end

function XUiMainRightBottom:OnBtnTerminalClick()
    self.RootUi:OnShowTerminal(true)
end

function XUiMainRightBottom:CheckRedPoint()
    XRedPointManager.Check(self.TerminalRedPoint)
end

function XUiMainRightBottom:OnCheckBtnTerminalRedPoint(count)
    if self.BtnTerminal then
        self.BtnTerminal:ShowReddot(count >= 0)
    end
end

return XUiMainRightBottom