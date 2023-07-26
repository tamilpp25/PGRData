local XUiGridConsumeReward = XClass(nil, "XUiGridConsumeReward")

function XUiGridConsumeReward:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:Init(rootUi)
end

function XUiGridConsumeReward:Init(rootUi)
    self.RootUi = rootUi
    self.CommonGrid = XUiGridCommon.New(self.RootUi, self.GridCommon)
end

function XUiGridConsumeReward:Refresh(taskId)
    self.GameObject:SetActiveEx(true)
    self:RegisterBtnListener(taskId)
    self.TaskId = taskId
    local taskCfg = XTaskConfig.GetTaskCfgById(taskId)
    local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
    local rewardGood = XRewardManager.GetRewardList(taskCfg.RewardId)[1]
    self.CommonGrid:Refresh(rewardGood)
    if self.TxtNumber then
        self.TxtNumber.text = taskCfg.Result
    end

    self.PanelEffect.gameObject:SetActiveEx(false)
    self.BtnGet.gameObject:SetActiveEx(false)
    self.ImgReceive.gameObject:SetActiveEx(false)
    if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
        self.PanelEffect.gameObject:SetActiveEx(true)
        self.BtnGet.gameObject:SetActiveEx(true)
    elseif taskData.State == XDataCenter.TaskManager.TaskState.Finish then
        self.ImgReceive.gameObject:SetActiveEx(true)
    end
end

function XUiGridConsumeReward:RegisterBtnListener(taskId)
    self.BtnGet.CallBack = function ()
        XDataCenter.TaskManager.FinishTask(taskId, function(rewardGoodsList)
            XUiManager.OpenUiObtain(rewardGoodsList)
        end)
    end
end

return XUiGridConsumeReward