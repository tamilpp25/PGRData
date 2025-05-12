local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridTurntableTask : XUiNode
local XUiGridTurntableTask = XClass(XUiNode, "XUiGridTurntableTask")

function XUiGridTurntableTask:OnStart()
    self.BtnFinish.CallBack = handler(self, self.OnClickBtnReceive)
    self.BtnSkip.CallBack = handler(self, self.OnClickBtnSkip)
end

function XUiGridTurntableTask:UpdateGrid(data)
    self.Data = data
    self.TaskConfig = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
    self.TxtTaskName.text = self.TaskConfig.Title
    self.TxtTaskDescribe.text = self.TaskConfig.Desc
    local result = self.TaskConfig.Result > 0 and self.TaskConfig.Result or 1
    local scheduleValue = data.Schedule[1] and data.Schedule[1].Value or 0
    self.ImgProgress.fillAmount = scheduleValue / result
    scheduleValue = (scheduleValue >= result) and result or scheduleValue
    self.TxtTaskNumQian.text = XUiHelper.GetText("SlotMachineTaskNumProcess", scheduleValue, result)
    self.GridRewardList = self.GridRewardList or {}
    local rewardId = self.TaskConfig.RewardId
    local rewards = XRewardManager.GetRewardList(rewardId)
    local rewardsNum = #rewards
    for i = 1, rewardsNum do
        local grid = self.GridRewardList[i]
        if not grid then
            local go = i == 1 and self.GridCommon or XUiHelper.Instantiate(self.GridCommon, self.GridCommon.parent)
            grid = XUiGridCommon.New(self.RootUi, go)
            self.GridRewardList[i] = grid
        end
        grid:Refresh(rewards[i])
        grid.GameObject:SetActiveEx(true)
    end
    for i = rewardsNum + 1, #self.GridRewardList do
        self.GridRewardList[i].GameObject:SetActiveEx(false)
    end

    self:SetState(data.State)
end

function XUiGridTurntableTask:SetState(state)
    if state == XDataCenter.TaskManager.TaskState.Active then
        self.BtnSkip.gameObject:SetActiveEx(true)
        self.ImgComplete.gameObject:SetActiveEx(false)
        self.BtnFinish.gameObject:SetActiveEx(false)
    elseif state == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnSkip.gameObject:SetActiveEx(false)
        self.ImgComplete.gameObject:SetActiveEx(false)
        self.BtnFinish.gameObject:SetActiveEx(true)
    elseif state == XDataCenter.TaskManager.TaskState.Finish then
        self.BtnSkip.gameObject:SetActiveEx(false)
        self.ImgComplete.gameObject:SetActiveEx(true)
        self.BtnFinish.gameObject:SetActiveEx(false)
    end
end

function XUiGridTurntableTask:OnClickBtnReceive()
    if not self.Data then
        return
    end
    XDataCenter.TaskManager.FinishTask(self.Data.Id, function(rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
    end)
end

function XUiGridTurntableTask:OnClickBtnSkip()
    if not self.TaskConfig then
        return
    end
    XFunctionManager.SkipInterface(self.TaskConfig.SkipId)
end

return XUiGridTurntableTask