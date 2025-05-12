---@class XUiRiftFightLayerSelect:XLuaUi 大秘境关卡选择界面
---@field _Control XRiftControl
local XUiRiftFightLayerSelect = XLuaUiManager.Register(XLuaUi, "UiRiftFightLayerSelect")

local ItemIds = {
    XDataCenter.ItemManager.ItemId.RiftGold,
    XDataCenter.ItemManager.ItemId.RiftCoin
}

function XUiRiftFightLayerSelect:OnAwake()
    ---@type XUiGridRiftStage[]
    self._Grids = {}

    self:BindHelpBtn(self.BtnHelp, "RiftHelp")
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnShop, self.OnBtnTaskClick) -- 任务按钮
    self:RegisterClickEvent(self.BtnLuck, self.OnBtnLuckClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnAttribute, self.OnBtnAttributeClick)
    self:RegisterClickEvent(self.BtnPluginBag, self.OnBtnPluginBagClick)
    self:RegisterClickEvent(self.BtnCharacter, self.OnBtnCharacterClick)
    self:RegisterClickEvent(self.BtnMopup, self.OnBtnMopupClick) -- 派遣(扫荡)
    self.BtnAttributeRedEventId = XRedPointManager.AddRedPointEvent(self.BtnAttribute, self.OnCheckAttribute, self, { XRedPointConditions.Types.CONDITION_RIFT_ATTRIBUTE })
end

function XUiRiftFightLayerSelect:OnStart(chapterId)
    -- 从战斗回来 会先执行OnResume再OnStart
    self:UpdateChapter(self.ChapterId or chapterId)

    local endTimeSecond = self._Control:GetTime()
    self:SetAutoCloseInfo(endTimeSecond, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
        -- 扫荡cd倒计时
        local mopupTime
        if self._MopupUnlock then
            local leftTime = self._Control:GetMopupCountDown()
            if leftTime and leftTime > 0 then
                local remainTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.MAIN)
                mopupTime = XUiHelper.GetText("RiftMopupTime", remainTime)
                if self.BtnMopup.ButtonState ~= CS.UiButtonState.Disable then
                    self.BtnMopup:SetButtonState(CS.UiButtonState.Disable)
                end
            elseif self.BtnMopup.ButtonState ~= CS.UiButtonState.Normal then
                self.BtnMopup:SetButtonState(CS.UiButtonState.Normal)
            end
            self.BtnMopup:ShowReddot(not leftTime or leftTime <= 0)
            self.BtnMopup:SetNameByGroup(0, mopupTime or XUiHelper.GetText("RiftMopupRefresh"))
        end
    end, nil, 0)
end

function XUiRiftFightLayerSelect:OnEnable()
    self:UpdateView()

    -- 检测区域是否全部通关 弹提示
    self.Chapter:CheckFirstPassAndOpenTipFun(function(nextChapterId)
        self._Control:SetAutoOpenChapterDetail(nextChapterId)
        self:Close()
    end)
end

function XUiRiftFightLayerSelect:OnDestroy()
    self:StopProgressTween()
    XRedPointManager.RemoveRedPointEvent(self.BtnAttributeRedEventId)
    self._Control:SetFirstPassChapterTrigger(nil) -- 关闭界面时清掉标记 防止从主界面进入时打开前往下一章弹框（只会在战斗结束后出现）
end

function XUiRiftFightLayerSelect:OnReleaseInst()
    return self.ChapterId
end

function XUiRiftFightLayerSelect:OnResume(chapterId)
    self:UpdateChapter(chapterId)
    self:UpdateView()
end

function XUiRiftFightLayerSelect:UpdateChapter(chapterId)
    self.ChapterId = chapterId
    ---@type XRiftChapter
    self.Chapter = self._Control:GetEntityChapterById(chapterId)

    self:RefreshMopupUnlock()
    self.BtnAttribute:SetNameByGroup(0, self._Control:GetFuncUnlockById(XEnumConst.Rift.FuncUnlockId.Plugin).Desc)
end

function XUiRiftFightLayerSelect:UpdateView()
    self:PlayAvg()
    self:Refresh()
    self:PlayProgressTween()
    self.BtnCharacter:ShowReddot(self._Control:GetCharacterRedPoint())
    if not self.AssetActivityPanel then
        self.AssetActivityPanel = XUiHelper.NewPanelActivityAssetSafe(ItemIds, self.PanelSpecialTool, self)
    end
end

function XUiRiftFightLayerSelect:PlayAvg()
    local startStoryId = self.Chapter:GetConfig().StartStoryId
    local startAvgId = XTool.IsNumberValid(startStoryId) and self._Control:GetRiftStoryById(startStoryId).AvgId or nil
    local endStoryId = self.Chapter:GetConfig().EndStoryId
    local endAvgId = XTool.IsNumberValid(endStoryId) and self._Control:GetRiftStoryById(endStoryId).AvgId or nil

    local startKey = string.format("RiftStory_%s_%s", startStoryId, XPlayer.Id)
    local endKey = string.format("RiftStory_%s_%s", endStoryId, XPlayer.Id)

    if not XSaveTool.GetData(startKey) and XTool.IsNumberValid(startAvgId) then
        XDataCenter.MovieManager.PlayMovie(startAvgId, function()
            XSaveTool.SaveData(startKey, true)
            XDataCenter.GuideManager.CheckGuideOpen()    -- 触发引导
        end, nil, nil, false)
    end

    local chapter, layer = self._Control:GetCurrPlayingChapter()
    -- 刚进入下一章节时 chapter是新的 但是layer是上一关挑战关的 所以这里判断下chapter是否一致 避免这种情况
    if layer and layer:IsChallenge() and layer:CheckFirstPassed() and chapter:GetChapterId() == layer:GetConfig().ChapterId then
        if not XSaveTool.GetData(endKey) and XTool.IsNumberValid(endAvgId) then
            XDataCenter.MovieManager.PlayMovie(endAvgId, function()
                XSaveTool.SaveData(endKey, true)
                XDataCenter.GuideManager.CheckGuideOpen()    -- 触发引导
            end, nil, nil, false)
        end
    end
end

function XUiRiftFightLayerSelect:Refresh()
    self:RefreshUiShow()
    self:RefreshStageList()
    self:RefreshMopupUnlock()
    local isShowRed = self._Control:CheckTaskCanReward()
    self.BtnShop:ShowReddot(isShowRed)
end

function XUiRiftFightLayerSelect:RefreshMopupUnlock()
    self._MopupUnlock = self._Control:IsFuncUnlock(XEnumConst.Rift.FuncUnlockId.Mopup)
    self.BtnMopup.gameObject:SetActiveEx(self._MopupUnlock)
end

function XUiRiftFightLayerSelect:RefreshUiShow()
    -- 幸运值信息
    local progress = self._Control:GetLuckValueProgress()
    self.TxtLuckProgress.text = string.format("%s%%", math.floor(progress * 100))
    self.BtnLuck:ShowReddot(progress >= 1)
    local isUnlock = self._Control:IsFuncUnlock(XEnumConst.Rift.FuncUnlockId.LuckyStage)
    self.BtnLuck.gameObject:SetActiveEx(isUnlock)
    -- 属性加点按钮
    isUnlock = self._Control:IsFuncUnlock(XEnumConst.Rift.FuncUnlockId.Attribute)
    self.BtnAttribute:SetDisable(not isUnlock)
    -- 商店按钮
    XRedPointManager.Check(self.BtnAttributeRedEventId)
    local isShopRed = self._Control:IsShopRed()
    self.BtnShop:ShowReddot(isShopRed)
    -- 插件背包按钮
    local isPluginRed = self._Control:IsPluginBagRed()
    self.BtnPluginBag:ShowReddot(isPluginRed)
end

function XUiRiftFightLayerSelect:RefreshStageList()
    local resourceList = self.Chapter:GetAllFightLayersOrderList()
    local count = #resourceList

    -- 美术的特殊表现 不同节点数量 对应的位置不同
    local nodeIdx
    if count == 4 then
        nodeIdx = 7
    elseif count == 5 then
        nodeIdx = 11
    elseif count == 6 then
        nodeIdx = 1
    else
        nodeIdx = 1
        XLog.Error("没有该节点数对应的显示方案：" .. count)
    end

    self.GridStage.gameObject:SetActiveEx(true)
    self.GridStageChallenge.gameObject:SetActiveEx(true)

    for i, fightLayer in ipairs(resourceList) do
        local grid = self._Grids[i]
        if not grid then
            local parent = self["Stage" .. nodeIdx]
            if not parent then
                goto CONTINUE
            end
            local go
            if i == 1 then
                go = self.GridStage
                go:SetParent(parent, false)
            elseif i == count then
                go = self.GridStageChallenge -- 最后一关必定是挑战关
                go:SetParent(parent, false)
            else
                go = XUiHelper.Instantiate(self.GridStage, parent)
            end
            grid = require("XUi/XUiRift/Grid/XUiGridRiftStage").New(go, self)
            self._Grids[i] = grid
        end
        grid:Init(fightLayer)
        grid:Update()
        :: CONTINUE ::
        nodeIdx = nodeIdx + 1
    end
end

function XUiRiftFightLayerSelect:PlayProgressTween()
    for _, grid in pairs(self._Grids) do
        grid:PlayProgressTween()
    end
end

function XUiRiftFightLayerSelect:StopProgressTween()
    for _, grid in pairs(self._Grids) do
        grid:StopProgressTween()
    end
end

function XUiRiftFightLayerSelect:OnGridFightLayerSelected(fightLayer)
    -- 进入战斗层，记录进入打个卡
    if self._CurrSelectFightLayer ~= fightLayer then
        self._CurrSelectFightLayer = fightLayer
        --self.Transform:Find("Animation/QieHuan"):PlayTimelineAnimation()
    end
    self:Refresh()
end

function XUiRiftFightLayerSelect:OnBtnMopupClick()
    if self._Control:GetMopupCountDown() > 0 then
        XUiManager.TipError(XUiHelper.GetText("RiftSweepTimesLimit"))
        return
    end
    
    local title = CS.XTextManager.GetText("TipTitle")
    local content = CS.XTextManager.GetText("RiftSweepConfirm")
    XLuaUiManager.Open("UiDialog", title, content, XUiManager.DialogType.Normal, nil, function()
        self._Control:RiftSweepLayerRequest(function()
            self:Refresh()
        end)
    end)
end

function XUiRiftFightLayerSelect:OnBtnLuckClick()
    if self._Control:GetLuckValueProgress() < 1 then
        XUiManager.TipError(XUiHelper.GetText("RiftLuckStageLock"))
        return
    end

    self:OpenLuckyDetail()
end

function XUiRiftFightLayerSelect:OpenLuckyDetail()
    local luckyLayer = self._Control:GetLuckLayer()
    local group = luckyLayer:GetStageGroup()
    self._Control:SetCurrSelectRiftStage(group)
    -- 幸运关没有剧情
    XLuaUiManager.OpenWithCloseCallback("UiRiftPopupLuckyStageDetail", function()
        self:Refresh()
    end, luckyLayer, true)
end

function XUiRiftFightLayerSelect:OnBtnAttributeClick()
    local isUnlock = self._Control:IsFuncUnlock(XEnumConst.Rift.FuncUnlockId.Attribute)
    if isUnlock then
        XLuaUiManager.Open("UiRiftAttribute")
    else
        local funcUnlockCfg = self._Control:GetFuncUnlockById(XEnumConst.Rift.FuncUnlockId.Attribute)
        XUiManager.TipError(funcUnlockCfg.Desc)
    end
end

function XUiRiftFightLayerSelect:OnBtnCharacterClick()
    XLuaUiManager.Open("UiRiftCharacter", nil, nil, nil, true)
end

function XUiRiftFightLayerSelect:OnBtnPluginBagClick()
    XLuaUiManager.Open("UiRiftPluginBag")
end

function XUiRiftFightLayerSelect:OnBtnTaskClick()
    --self._Control:OpenUiShop()
    XLuaUiManager.Open("UiRiftTask")
end

function XUiRiftFightLayerSelect:OnCheckAttribute(count)
    self.BtnAttribute:ShowReddot(count >= 0)
end

function XUiRiftFightLayerSelect:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

return XUiRiftFightLayerSelect