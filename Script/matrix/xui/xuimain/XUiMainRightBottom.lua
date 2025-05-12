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
    self.TerminalRedPoint = self:AddRedPointEvent(self.BtnTerminal, self.OnCheckBtnTerminalRedPoint, self, RedPointConditionGroup.Terminal)
    
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
    XEventManager.AddEventListener(XEventId.EVENT_MAINUI_EXPENSIVE_ITEM_CHANGE, self.RefreshTips, self)
    XEventManager.AddEventListener(XEventId.EVENT_DORM_NOTIFY_DORMITORY_DATA, self.RefreshTips, self)

    XMVCA.XPreload:AddAgencyEvent(XAgencyEventId.EVENT_PRELOAD_DOWNLOAD_STATE, self.RefreshTips, self)
end

function XUiMainRightBottom:OnDisable()
    if self.ScrollSequence then
        self.ScrollSequence:Kill()
        self.ScrollSequence = nil
    end
    self:StopTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINUI_TERMINAL_STATUS_CHANGE, self.RefreshTips, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINUI_EXPENSIVE_ITEM_CHANGE, self.RefreshTips, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_NOTIFY_DORMITORY_DATA, self.RefreshTips, self)

    XMVCA.XPreload:RemoveAgencyEvent(XAgencyEventId.EVENT_PRELOAD_DOWNLOAD_STATE, self.RefreshTips, self)
    self:ClearGrids()

    self.ChangeColorFin = false
end

function XUiMainRightBottom:OnDestroy()

end

function XUiMainRightBottom:CheckFilterFunctions()

end

function XUiMainRightBottom:StartTimer()
 
end

function XUiMainRightBottom:StopTimer()
  
end

function XUiMainRightBottom:GetScrollTips()
    local tipList = XMVCA.XUiMain:GetScrollTipList(false)
    
    if XTool.IsTableEmpty(tipList) then
        local albumId = XMVCA.XAudio:GetUiMainNeedPlayedAlbumId()
        local template = XMVCA.XAudio:GetAlbumTemplateById(albumId)
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
    if not self.ChangeColorFin or not XDataCenter.DormManager.IsDormDataNotify then -- ChangeColorFin字段保证刷新在切换主题之后
        return
    end
    
    if self.ScrollSequence then
        self.ScrollSequence:Kill()
        self.ScrollSequence = nil
    end
   
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

function XUiMainRightBottom:AfterChangeColorCb()
    self:RefreshTips()
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