local XUiRepeatChallengeReward = XClass(require('XUi/XUiActivityBase/XUiPanelSkip'), 'XUiRepeatChallengeReward')

local XUiGridRepeatChallengeReward = require('XUi/XUiActivityBase/XUiGridRepeatChallengeReward')

function XUiRepeatChallengeReward:Ctor(ui)
    self:InitMilestoneGrids()
    self._GridList = {}
end

function XUiRepeatChallengeReward:OnHide()
    self.GameObject:SetActiveEx(false)
end

function XUiRepeatChallengeReward:InitMilestoneGrids()
    self.PanelNewbieActive.gameObject:SetActiveEx(false)
    self._GridBeginPosX = self.PanelNewbieActive.transform.anchoredPosition.x
end

---@overload
function XUiRepeatChallengeReward:Refresh(activityCfg)
    self.Super.Refresh(self, activityCfg)
    self._activityCfg = activityCfg
    self:RefreshTaskData()
end

function XUiRepeatChallengeReward:RefreshTaskData()
    -- 约定参数索引2放置的是TaskTimeLimit表的Id
    if not XTool.IsNumberValid(self._activityCfg.Params[2]) then
        self:SetTaskProcessActive(false)
        XLog.Error('复刷关Client/Activity表的配置未配置有效的任务')
    else
        self._TaskTimeLimitId = self._activityCfg.Params[2]
        self:SetTaskProcessActive(true)
        self:RefreshProcess()
        self:RefreshMilestoneGrids()
        self:RefreshProcessBar()
    end
end

--- 更新当前进度
function XUiRepeatChallengeReward:RefreshProcess()
    local curNumber = 0
    local TaskTotalNumber = 0

    -- 任务上限读最后一个任务的完成参数
    local taskListCfg = XTaskConfig.GetTimeLimitTaskCfg(self._TaskTimeLimitId)
    if taskListCfg then
        self._TaskIds = taskListCfg.TaskId
        self._TaskCount = #taskListCfg.TaskId
        local taskId = taskListCfg.TaskId[self._TaskCount]
        if XTool.IsNumberValid(taskId) then
            local taskCfg = XTaskConfig.GetTaskCfgById(taskId)
            if taskCfg then
                local taskConditionCfg = XTaskConfig.GetTaskCondition(taskCfg.Condition[1])
                TaskTotalNumber = taskConditionCfg.Params[1] or 0
                local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
                curNumber = taskData.Schedule[1] and taskData.Schedule[1].Value or 0
            end
        end
    end
    curNumber = curNumber > TaskTotalNumber and TaskTotalNumber or curNumber
    self.TxtCurProgress.text = tostring(curNumber)
    self.TxtTotalProgress.text = '/'..tostring(TaskTotalNumber)
end

--- 更新里程碑奖励UI
function XUiRepeatChallengeReward:RefreshMilestoneGrids()
    -- 线分割若干均等距离的点，UI都在中央，因此需要补齐尾部的虚拟点
    local splitNum = self._TaskCount + 1
    local avgDistance = self.ImgProgress.transform.rect.width / splitNum

    for i = 1, self._TaskCount do
        if self._GridList[i] then
            self._GridList[i]:Refresh(self._TaskIds[i])
        else
            local obj = CS.UnityEngine.GameObject.Instantiate(self.PanelNewbieActive, self.PanelNewbieActive.transform.parent)
            local grid = XUiGridRepeatChallengeReward.New(obj, self)
            grid:Refresh(self._TaskIds[i])
            self._GridList[i] = grid
            grid.Transform.anchoredPosition = grid.Transform.anchoredPosition + Vector2.right * avgDistance * i
        end
    end
end

function XUiRepeatChallengeReward:RefreshProcessBar()
    local lenTotal = self.ImgProgress.transform.rect.width
    local curlen = 0
    for i, grid in ipairs(self._GridList) do
        if grid:TaskIsComplete() then
            curlen = grid.Transform.anchoredPosition.x - self._GridBeginPosX
        else
            break
        end
    end
    self.ImgProgress.fillAmount = curlen / lenTotal
end

function XUiRepeatChallengeReward:SetTaskProcessActive(active)
    self.ImgProgress.gameObject:SetActiveEx(active)
    self.PanelContent.gameObject:SetActiveEx(active)
end

---@return boolean 是否有可领取的奖励
function XUiRepeatChallengeReward:AcceptAllReward()
    local taskIds = {}

    if not XTool.IsTableEmpty(self._TaskIds) then
        for i, taskId in pairs(self._TaskIds) do
            if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                table.insert(taskIds, taskId)
            end
        end
    end

    if not XTool.IsTableEmpty(taskIds) then
        XDataCenter.TaskManager.FinishMultiTaskRequest(taskIds, function(rewardList)
            self:RefreshTaskData()
            XUiManager.OpenUiObtain(rewardList, nil, nil, nil)
            CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_INFO_UPDATE)
        end)
        return true
    else
        return false
    end
    
end

return XUiRepeatChallengeReward