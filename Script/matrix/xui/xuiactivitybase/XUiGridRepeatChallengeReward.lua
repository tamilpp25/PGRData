local XUiGridRepeatChallengeReward = XClass(nil, 'XUiGridRepeatChallengeReward')

function XUiGridRepeatChallengeReward:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent;
    XTool.InitUiObject(self)
    ui.gameObject:SetActiveEx(true)
    
    XUiHelper.RegisterClickEvent(self, self.BtnActive, self.OnGridClickEvent)
end

function XUiGridRepeatChallengeReward:Refresh(taskId)
    -- 已领取
    self._IsAchieved = XDataCenter.TaskManager.CheckTaskFinished(taskId)
    -- 已完成
    self._IsComplete = XDataCenter.TaskManager.CheckTaskAchieved(taskId)
    self._TaskId = taskId
    
    -- 显示目标数
    local taskCfg = XTaskConfig.GetTaskCfgById(taskId)
    if taskCfg then
        local taskConditionCfg = XTaskConfig.GetTaskCondition(taskCfg.Condition[1])
        self.TxtValue.text = tostring(taskConditionCfg.Params[1])
    end
    
    -- 状态显示
    self.PanelEffect.gameObject:SetActiveEx(self._IsComplete and not self._IsAchieved)
    self.BigEffect.gameObject:SetActiveEx(self._IsComplete and not self._IsAchieved)
    self.ImgRe.gameObject:SetActiveEx(self._IsAchieved)
end

function XUiGridRepeatChallengeReward:OnGridClickEvent()
    if not self._IsComplete or not self.Parent:AcceptAllReward() then
        -- 打开详情
        local taskCfg = XTaskConfig.GetTaskCfgById(self._TaskId)
        if taskCfg then
            XUiManager.OpenUiTipRewardByRewardId(taskCfg.RewardId)
        end
    end
end

--- 任务达成，待领取和已领取都算
function XUiGridRepeatChallengeReward:TaskIsComplete()
    return self._IsAchieved or self._IsComplete
end

return XUiGridRepeatChallengeReward