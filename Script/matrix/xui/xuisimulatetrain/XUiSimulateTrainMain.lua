local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiSimulateTrainMain:XLuaUi
---@field private _Control XSimulateTrainControl
local XUiSimulateTrainMain = XLuaUiManager.Register(XLuaUi, "UiSimulateTrainMain")

function XUiSimulateTrainMain:OnAwake()
    self.BossUiObjs = { self.GridBoss1, self.GridBoss2, self.GridBoss3, self.GridBoss4 }
    self.BossTimeIds = {}
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:RegisterUiEvents()
end

function XUiSimulateTrainMain:OnStart()

end

function XUiSimulateTrainMain:OnEnable()
    self.ActivityId = self._Control:GetActivityId()
    self.EndTime = self._Control:GetActivityEndTime(self.ActivityId)
    self.BossIds = self._Control:GetActivityBossIds(self.ActivityId)
    self:Refresh()
    self:StartTimer()
end

function XUiSimulateTrainMain:OnDisable()
    self:ClearTimer()
    self._Control:SaveBossUnlock()
end

function XUiSimulateTrainMain:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "SimulateTrainHelp")
end

function XUiSimulateTrainMain:OnGridBossClick(index)
    local bossId = self.BossIds[index]
    local timeId = self.BossTimeIds[index]
    local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
    if not isInTime then
        local time =  XFunctionManager.GetStartTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
        local tips = time > 0 and XUiHelper.GetText("SimulateTrainBossUnlockTips", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY))
            or XUiHelper.GetText("BossSingleBossNotEnough")
        XUiManager.TipError(tips)
        return
    end
    
    XLuaUiManager.Open("UiSimulateTrainBossDetail", bossId)
end

function XUiSimulateTrainMain:Refresh()
    self.TxtTitle.text = self._Control:GetActivityName(self.ActivityId)
    self:RefreshTime()
    self:RefreshBossList()
end

function XUiSimulateTrainMain:RefreshTime()
    local gameTime = self.EndTime - XTime.GetServerNowTimestamp()
    if gameTime < 1 then
        self._Control:HandleActivityEnd()
        return
    end
    self.TxtTime.text = XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY)

    -- boss解锁时间
    for i, timeId in ipairs(self.BossTimeIds) do
        local bossId = self.BossIds[i]
        local uiObj = self.BossUiObjs[i]
        local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
        uiObj:GetObject("PanelLock").gameObject:SetActiveEx(not isInTime)
        if not isInTime then
            local time =  XFunctionManager.GetStartTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
            local tips = time > 0 and XUiHelper.GetText("SimulateTrainBossUnlockTips", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.ACTIVITY))
                or XUiHelper.GetText("BossSingleBossNotEnough")
            uiObj:GetObject("TxtLock").text = tips
        end

        -- 页签
        local finishCnt, allCnt, rewardIds = self:GetBossTaskData(bossId)
        uiObj:GetObject("GridBtn"):ShowTag(finishCnt <= 0 and isInTime)
    end
end

function XUiSimulateTrainMain:StartTimer()
    self:ClearTimer()
    self.ActivityTimer = XScheduleManager.ScheduleForever(function()
        self:RefreshTime()
    end, XScheduleManager.SECOND)
    self:RefreshTime()
end

function XUiSimulateTrainMain:ClearTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

-- 刷新Boss列表
function XUiSimulateTrainMain:RefreshBossList()
    for _, uiObj in ipairs(self.BossUiObjs) do
        uiObj.gameObject:SetActiveEx(false)
    end

    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, bossId in ipairs(self.BossIds) do
        local uiObj = self.BossUiObjs[i]
        uiObj.gameObject:SetActiveEx(true)
        self:RefreshBoss(i, uiObj, bossId)
    end
end

-- 刷新单个Boss
function XUiSimulateTrainMain:RefreshBoss(index, uiObj, bossId)
    local icon = self._Control:GetBossIcon(bossId)
    uiObj:GetObject("RImgBg"):SetRawImage(icon)

    local finishCnt, allCnt, rewardIds = self:GetBossTaskData(bossId)
    uiObj:GetObject("TxtCurNum").text = tostring(finishCnt)
    uiObj:GetObject("TxtMaxNum").text = tostring(allCnt)

    -- 解锁时间
    self.BossTimeIds[index] = self._Control:GetBossTimeId(bossId)

    -- 点击事件
    local btn = uiObj:GetObject("GridBtn")
    btn.CallBack = function()
        self:OnGridBossClick(index)
    end

    -- 红点
    local isRed = self._Control:IsShowBossRedPoint(bossId)
    btn:ShowReddot(isRed)
end

function XUiSimulateTrainMain:GetBossTaskData(bossId)
    local taskIds = self._Control:GetBossTaskIds(bossId)
    local allCnt = #taskIds
    local finishCnt = 0
    local rewardIds = {}
    for _, taskId in ipairs(taskIds) do
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        local taskCfg = XDataCenter.TaskManager.GetTaskTemplate(taskId)
        if taskData.State == XDataCenter.TaskManager.TaskState.Finish then
            finishCnt = finishCnt + 1
        end
        table.insert(rewardIds, taskCfg.RewardId)
    end
    
    return finishCnt, allCnt, rewardIds
end

return XUiSimulateTrainMain