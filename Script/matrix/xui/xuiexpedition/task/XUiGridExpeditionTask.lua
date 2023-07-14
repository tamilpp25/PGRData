local XUiGridExpeditionTask = XClass(nil, "XUiGridExpeditionTask")

function XUiGridExpeditionTask:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:RegisterUiEvents()
    self.RewardGrids = {}
    self.GridCommon.gameObject:SetActiveEx(false)
end

function XUiGridExpeditionTask:Refresh(taskData)
    self.Data = taskData or self.Data

    self:UpdateRewards()
    self:UpdateProgress()
    self:UpdateTaskText()
end

function XUiGridExpeditionTask:UpdateRewards()
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    local rewards = XRewardManager.GetRewardList(config.RewardId)
    if not rewards then
        return
    end

    for i = 1, #rewards do
        local panel = self.RewardGrids[i]
        if not panel then
            local ui = XUiHelper.Instantiate(self.GridCommon, self.GridCommon.parent)
            panel = XUiGridCommon.New(self.RootUi, ui)
            self.RewardGrids[i] = panel
        end
        panel:Refresh(rewards[i])
    end
end

function XUiGridExpeditionTask:UpdateProgress()
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    -- 判断条件大于2 不显示进度条
    if #config.Condition < 2 then
        self.ImgProgress.transform.parent.gameObject:SetActiveEx(true)
        self.TxtTaskNumQian.gameObject:SetActiveEx(true)
        local result = config.Result > 0 and config.Result or 1
        XTool.LoopMap(self.Data.Schedule, function(_, pair)
            self.ImgProgress.fillAmount = pair.Value / result
            pair.Value = (pair.Value >= result) and result or pair.Value
            self.TxtTaskNumQian.text = pair.Value .. "/" .. result
        end)
    else
        self.ImgProgress.transform.parent.gameObject:SetActiveEx(false)
        self.TxtTaskNumQian.gameObject:SetActiveEx(false)
    end

    --更新按钮状态
    if self.Data.State ~= XDataCenter.TaskManager.TaskState.Achieved and self.Data.State ~= XDataCenter.TaskManager.TaskState.Finish then
        self.BtnSkip.gameObject:SetActiveEx(true)
        if config.SkipId == nil or config.SkipId == 0 then
            self.BtnSkip:SetButtonState(CS.UiButtonState.Disable)
        else
            self.BtnSkip:SetButtonState(CS.UiButtonState.Normal)
        end
    else
        self.BtnSkip.gameObject:SetActiveEx(false)
    end

    self.BtnFinish.gameObject:SetActiveEx(self.Data.State == XDataCenter.TaskManager.TaskState.Achieved)
    self.BtnReceiveHave.gameObject:SetActiveEx(self.Data.State == XDataCenter.TaskManager.TaskState.Finish)
end

function XUiGridExpeditionTask:UpdateTaskText()
    local config = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id)
    self.TxtTaskName.text = config.Title
    self.TxtTaskDescribe.text = config.Desc
end

function XUiGridExpeditionTask:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFinish, self.OnBtnFinishClick)
end

function XUiGridExpeditionTask:OnBtnSkipClick()
    local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.Data.Id).SkipId
    XFunctionManager.SkipInterface(skipId)
end

function XUiGridExpeditionTask:OnBtnFinishClick()
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
    end)
end

return XUiGridExpeditionTask