local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiSimulateTrainBossDetail:XLuaUi
---@field private _Control XSimulateTrainControl
local XUiSimulateTrainBossDetail = XLuaUiManager.Register(XLuaUi, "UiSimulateTrainBossDetail")

function XUiSimulateTrainBossDetail:OnAwake()
    self.TaskUiObjs = { self.GridTask1, self.GridTask2, self.GridTask3, self.GridTask4 }
    self.TaskGridCommons = {}
    self:RegisterUiEvents()
end

function XUiSimulateTrainBossDetail:OnStart(bossId)
    self.BossId = bossId
end

function XUiSimulateTrainBossDetail:OnEnable()
    self.ActivityId = self._Control:GetActivityId()
    self.EndTime = self._Control:GetActivityEndTime(self.ActivityId)
    self.TaskIds = self._Control:GetBossTaskIds(self.BossId)
    self.TaskTypes = self._Control:GetBossTaskTypes(self.BossId)
    self:Refresh()
    self:StartTimer()
end

function XUiSimulateTrainBossDetail:OnDisable()
    self:ClearTimer()
end

function XUiSimulateTrainBossDetail:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "SimulateTrainHelp")
    self:RegisterClickEvent(self.BtnGo, self.OnBtnGoClick)
end

function XUiSimulateTrainBossDetail:OnBtnGoClick()
    local monsterId = self._Control:GetBossMonsterId(self.BossId)
    local stageId = XPracticeConfigs.GetSimulateTrainMonsterStageId(monsterId)
    local chapterId = XPracticeConfigs.GetPracticeChapterIdByStageId(stageId)
    XDataCenter.PracticeManager.OpenUiFubenPratice(chapterId, stageId)
end

-- 领取所有任务的奖励
function XUiSimulateTrainBossDetail:OnBtnGetTasksReward()
    local taskIds = {}
    for _, taskId in ipairs(self.TaskIds) do
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then 
            table.insert(taskIds, taskId)
        end
    end
    if #taskIds <= 0 then return end
    
    XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
        self:RefreshTaskList()
    end)
end

function XUiSimulateTrainBossDetail:Refresh()
    self:RefreshTaskList()
    self:RefreshBg()
    self:RefreshBtnGo()
end

-- 刷新任务列表
function XUiSimulateTrainBossDetail:RefreshTaskList()
    for _, uiObj in ipairs(self.TaskUiObjs) do
        uiObj.gameObject:SetActiveEx(false)
    end

    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, taskId in ipairs(self.TaskIds) do
        local uiObj = self.TaskUiObjs[i]
        uiObj.gameObject:SetActiveEx(true)

        local taskType = self.TaskTypes[i]
        local taskCfg = XDataCenter.TaskManager.GetTaskTemplate(taskId)
        local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
        local isAchieved = taskData.State == XDataCenter.TaskManager.TaskState.Achieved
        local isFinish = taskData.State == XDataCenter.TaskManager.TaskState.Finish
        local canGet = isAchieved and not isFinish
        local isComplete = isAchieved or isFinish

        uiObj:GetObject("TxtTitle").text = taskCfg.Title
        uiObj:GetObject("TxtDetail").text = taskCfg.Desc
        uiObj:GetObject("ImgNormalBg").gameObject:SetActiveEx(XEnumConst.SIMULATE_TRAIN.TASK_TYPE.NORMAL == taskType)
        uiObj:GetObject("ImgNormalCompleteBg").gameObject:SetActiveEx(XEnumConst.SIMULATE_TRAIN.TASK_TYPE.NORMAL == taskType and isComplete)
        uiObj:GetObject("ImgHardBg").gameObject:SetActiveEx(XEnumConst.SIMULATE_TRAIN.TASK_TYPE.HARD == taskType)
        uiObj:GetObject("ImgHardCompleteBg").gameObject:SetActiveEx(XEnumConst.SIMULATE_TRAIN.TASK_TYPE.HARD == taskType and isComplete)
        uiObj:GetObject("TagClear").gameObject:SetActiveEx(isComplete)

        -- 按钮回调
        local btnGetReward = uiObj:GetObject("BtnGetReward")
        btnGetReward.gameObject:SetActiveEx(canGet)
        btnGetReward.CallBack = function()
            self:OnBtnGetTasksReward()
        end
        
        -- 奖励
        local grids = self.TaskGridCommons[i]
        if not grids then
            grids = {}
            self.TaskGridCommons[i] = grids
        end

        local grid256New = uiObj:GetObject("Grid256New")
        local rewards = XRewardManager.GetRewardList(taskCfg.RewardId)
        for j, reward in ipairs(rewards) do
            local grid = grids[j]
            if not grid then
                local go = CSInstantiate(grid256New.gameObject, grid256New.transform.parent)
                grid = XUiGridCommon.New(self, go)
                grids[j] = grid
            end
            grid:Refresh(reward)
            grid:SetName("")
            grid.PanelEffect.gameObject:SetActiveEx(canGet)
        end
        grid256New.gameObject:SetActiveEx(false)
    end
end

function XUiSimulateTrainBossDetail:RefreshBg()
    local bgs = self._Control:GetBossUiDetailBgs(self.BossId)
    for i, bg in ipairs(bgs) do
        self["Bg" .. i]:SetRawImage(bg)
    end

    local monsterId = self._Control:GetBossMonsterId(self.BossId)
    local stageId = XPracticeConfigs.GetSimulateTrainMonsterStageId(monsterId)
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.TxtTitle.text = stageCfg.Name
end

function XUiSimulateTrainBossDetail:RefreshBtnGo()
    local isShowGo = not XLuaUiManager.IsUiLoad("UiPracticeBossDetail")
    self.BtnGo.gameObject:SetActiveEx(isShowGo)
end

function XUiSimulateTrainBossDetail:StartTimer()
    self:ClearTimer()
    self.ActivityTimer = XScheduleManager.ScheduleForever(function()
        local gameTime = self.EndTime - XTime.GetServerNowTimestamp()
        if gameTime < 1 then
            self._Control:HandleActivityEnd()
            return
        end
    end, XScheduleManager.SECOND)
end

function XUiSimulateTrainBossDetail:ClearTimer()
    if self.ActivityTimer then
        XScheduleManager.UnSchedule(self.ActivityTimer)
        self.ActivityTimer = nil
    end
end

return XUiSimulateTrainBossDetail