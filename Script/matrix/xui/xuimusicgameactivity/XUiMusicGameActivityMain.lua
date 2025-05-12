local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@field _Control XMusicGameActivityControl
---@class XUiMusicGameActivityMain : XLuaUi
local XUiMusicGameActivityMain = XLuaUiManager.Register(XLuaUi, "UiMusicGameActivityMain")

function XUiMusicGameActivityMain:OnAwake()
    ---@type XGridCD[]
    self.GridCdDic = {}
    self.GridTaskRewardsItemDic = {}
    self:InitButton()
    self:InitTimes()

    -- 红点事件
    self.TaskRed = self:AddRedPointEvent(self.BtnTask, self.OnCommonRefreshRedPoint, self, {XRedPointConditions.Types.CONDITION_MUSICGAME_TASK}, self.BtnTask)
    self.RhythmGameRed = self:AddRedPointEvent(self.BtnRhythmGameTaiko, self.OnCommonRefreshRedPoint, self, {XRedPointConditions.Types.CONDITION_MUSICGAME_ENTRANCE_RHYTHMGAME}, self.BtnRhythmGameTaiko)
    self.ArrangementRed = self:AddRedPointEvent(self.BtnArrangementGame, self.OnCommonRefreshRedPoint, self, {XRedPointConditions.Types.CONDITION_MUSICGAME_ENTRANCE_ARRANGEMENT}, self.BtnArrangementGame)
end

function XUiMusicGameActivityMain:OnCommonRefreshRedPoint(count, btn)
    btn:ShowReddot(count >= 0)
end

function XUiMusicGameActivityMain:InitTimes()
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        else
            self:RefreshTitleByTimeId()
        end
    end)
end

function XUiMusicGameActivityMain:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnTask, self.OnBtnTaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSetting, self.OnBtnSettingClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRhythmGameTaiko, self.OnBtnRhythmGameTaikoClick)
    XUiHelper.RegisterClickEvent(self, self.BtnArrangementGame, self.OnBtnArrangementGameClick)
    self:BindHelpBtn(self.BtnHelp, "MusicGameActivityHelp")
end

function XUiMusicGameActivityMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiMusicGameActivityTask")
end

function XUiMusicGameActivityMain:OnBtnSettingClick()
    XLuaUiManager.Open("UiSet")
end

function XUiMusicGameActivityMain:OnBtnRhythmGameTaikoClick()
    local curRhythmeGameControlId = XMVCA.XMusicGameActivity:GetCurActivityConfig().RhythmGameControlId
    XMVCA.XRhythmGame:OpenEntrance(curRhythmeGameControlId, 0, false, function (mapId, scoreData)
        self._Control:MusicGameFinishRhythmRequest(mapId)
    end, true)
end

function XUiMusicGameActivityMain:OnBtnArrangementGameClick()
    local controlConfig = XMVCA.XMusicGameActivity:GetCurActivityConfig()

    -- 检查门票
    local itemId = XDataCenter.ItemManager.ItemId.MusicGameArrangementItem
    local itemCount = XDataCenter.ItemManager.GetCount(itemId)
    local itemName = XDataCenter.ItemManager.GetItemName(itemId)
    if itemCount < controlConfig.ArrangementUseItemCount then
        XUiManager.TipMsg(CS.XTextManager.GetText("AssetsBuyConsumeNotEnough", itemName))
        return
    end

    local curArrangementGameControlId = controlConfig.ArrangementGameControlId
    XMVCA.XArrangementGame:OpenUi(curArrangementGameControlId, function (gameMusicId, selections)
        self._Control:MusicGameArrangementRequest(gameMusicId, selections)
    end, controlConfig.ArrangementUseItemCount)
end

function XUiMusicGameActivityMain:OnStart()
    if self._Control:IsCanPopVolumeTip() then
        XLuaUiManager.Open("UiMusicGameActivityPopupVolSet")
    end
end

function XUiMusicGameActivityMain:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshUiShow()
end

function XUiMusicGameActivityMain:RefreshUiShow()
    -- 配置表数据
    -- 活动标题
    local curActivityConfig = XMVCA.XMusicGameActivity:GetCurActivityConfig()
    self.TxtTitle.text = curActivityConfig.Name

    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({XDataCenter.ItemManager.ItemId.MusicGameArrangementItem}, self.PanelSpecialTool, self)
    self.BtnArrangementGame:SetNameByGroup(1, curActivityConfig.ArrangementUseItemCount)
    self.BtnArrangementGame:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.MusicGameArrangementItem))

    -- 任务按钮的奖励todo
    local items = {XDataCenter.ItemManager.ItemId.PaidGem, XDataCenter.ItemManager.ItemId.TradeVoucher}
    local gridItem = self.BtnTask.TagObj.transform:FindTransform("Grid256New")
    for k, id in pairs(items) do
        local grid = self.GridTaskRewardsItemDic[k]
        if not grid then
            local uiGo = k == 1 and gridItem or XUiHelper.Instantiate(gridItem, gridItem.transform.parent)
            grid = XUiGridCommon.New(uiGo)
            self.GridTaskRewardsItemDic[k] = grid
        end
        grid:Refresh(id)
    end

    local taskGroupIds = XMVCA.XMusicGameActivity:GetTaskGroupIds()
    local isAllFinished = XTool.IsTableEmpty(taskGroupIds)
    for k, taskGroupId in pairs(taskGroupIds) do
        local taskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskGroupId)
        for k, v in pairs(taskDataList) do
            if v.State ~= XDataCenter.TaskManager.TaskState.Finish then
                isAllFinished = false
                break
            end
        end
        if isAllFinished then
            break
        end
    end
    self.BtnTask:ShowTag(not isAllFinished)

    -- 活动主界面的倒计时
    self:RefreshTitleByTimeId()

    -- 服务端数据
    local allPassArrangementMusicIds = XMVCA.XMusicGameActivity:GetPassArrangementMusicIds()
    local allArrangementControlConfig = XMVCA.XArrangementGame:GetModelArrangementGameControl()
    local curArrangementControlConfig = allArrangementControlConfig[curActivityConfig.ArrangementGameControlId]
    local resArrangementIds = {}
    for index, id in pairs(curArrangementControlConfig.MusicIds) do
        if table.contains(allPassArrangementMusicIds, id) then
            resArrangementIds[index] = id
        else
            resArrangementIds[index] = 0
        end
    end
    self.ResArrangementIds = resArrangementIds
    local XGridCD = require("XUi/XUiMusicGameActivity/Grid/XGridCD")
    for i = 1, 8, 1 do
        local arrangementMusicId = resArrangementIds[i]
        local parentTrans = self.ListCd:Find("Cd"..i)
        local gridCdRes = self.GridCdDic[i]
        if not gridCdRes then
            local ui = XUiHelper.Instantiate(self.GridCd, parentTrans)
            ui.transform:Reset()
            gridCdRes = XGridCD.New(ui, self)
            gridCdRes:RegisterOnClickCallback(function ()
                self:OpenUiArrangementGameStory(i)
            end)
            self.GridCdDic[i] = gridCdRes
        end

        -- 刷新数据
        gridCdRes:Open()
        gridCdRes:Refresh(arrangementMusicId)
    end

    -- 各按钮蓝点刷新
    XRedPointManager.Check(self.TaskRed, self.BtnTask)
    XRedPointManager.Check(self.RhythmGameRed, self.BtnRhythmGameTaiko)
    XRedPointManager.Check(self.ArrangementRed, self.BtnArrangementGame)
end

function XUiMusicGameActivityMain:OpenUiArrangementGameStory(index)
    local arrangementMusicId = self.ResArrangementIds[index]
    if not XTool.IsNumberValid(arrangementMusicId) then
        return
    end
    XLuaUiManager.Open("UiArrangementGameStory", arrangementMusicId)
end

function XUiMusicGameActivityMain:RefreshTitleByTimeId()
    local endTime = self._Control:GetActivityEndTime()
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    local str = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.CHATEMOJITIMER)
    self.TxtTime.text = str
end

function XUiMusicGameActivityMain:OnDisable()
    self.Super.OnDisable(self)
end

return XUiMusicGameActivityMain
