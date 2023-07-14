local XUiGridOnlineBossTask = XClass(nil, "XUiGridOnlineBossTask")

function XUiGridOnlineBossTask:Ctor(ui, rootUi)
    self.GameObject = ui.GameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.BtnFinish.CallBack = function()
        self:OnBtnFinishClick()
    end
end

function XUiGridOnlineBossTask:Refresh(taskData, preTaskData)
    self.TaskData = taskData or self.TaskData
    self.PreTaskData = preTaskData or self.PreTaskData

    local lastTaskTargetCount
    if self.PreTaskData == nil then
        lastTaskTargetCount = 0
    else
        local preTaskCfg = XTaskConfig.GetTaskConfigById(self.PreTaskData.Id)
        lastTaskTargetCount = preTaskCfg.Result
    end

    local taskCfg = XTaskConfig.GetTaskConfigById(self.TaskData.Id)

    for _, scheduleCfg in pairs(self.TaskData.Schedule) do
        if scheduleCfg.Value > lastTaskTargetCount then
            self.Scrollbar.size = (scheduleCfg.Value - lastTaskTargetCount) / (taskCfg.Result - lastTaskTargetCount)
        end
    end

    local isAchieved = XDataCenter.TaskManager.CheckTaskAchieved(self.TaskData.Id)
    local isFinished = XDataCenter.TaskManager.CheckTaskFinished(self.TaskData.Id)

    self.PanelEffect.gameObject:SetActiveEx(isAchieved)
    self.BtnFinish.gameObject:SetActiveEx(isAchieved)
    self.PanelFinish.gameObject:SetActiveEx(isFinished)

    self.TxtNum.text = taskCfg.Result

    local rewards = XRewardManager.GetRewardList(taskCfg.RewardId)
    self.ItemCommon = XUiGridCommon.New(self.RootUi, self.GiftItem)
    self.ItemCommon:Refresh(rewards[1])
end

function XUiGridOnlineBossTask:OnBtnFinishClick()
    XDataCenter.TaskManager.FinishTask(self.TaskData.Id, function(rewards)
            XUiManager.OpenUiObtain(rewards, nil, function(...)
                    self:Refresh()
                end, nil)
        end)
end

return XUiGridOnlineBossTask