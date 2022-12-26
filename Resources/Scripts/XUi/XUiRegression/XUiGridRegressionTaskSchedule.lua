--
-- Author: wujie
-- Note: 回归任务活跃奖励格子相关

local XUiGridRegressionTaskSchedule = XClass(nil, "XUiGridRegressionTaskSchedule")

function XUiGridRegressionTaskSchedule:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self.GridCommon = XUiGridCommon.New(self.PanelGridCommon)
    self.BtnReward.CallBack = function() self:OnBtnRewardClick() end
end

function XUiGridRegressionTaskSchedule:InitRootUi(rootUi)
    self.GridCommon:Init(rootUi)
end

function XUiGridRegressionTaskSchedule:Refresh(rewardData)
    self.Data = rewardData
    self.TxtValue.text = rewardData.Schedule
    local rewardList = XRewardManager.GetRewardList(rewardData.RewardId)
    local firstRewardIndex = 1
    local reward = rewardList[firstRewardIndex]
    if not reward then
        XLog.ErrorTableDataNotFound("XUiGridRegressionTaskSchedule:Refresh",
        "reward", "Share/Reward/Reward.tab", "rewardData.Id", tostring(rewardData.Id))
        return
    end
    self.GridCommon:Refresh(reward)
    self:UpdateGetStatus()
end

function XUiGridRegressionTaskSchedule:UpdateGetStatus()
    if not self.Data then return end
    local isHaveGet = XDataCenter.RegressionManager.IsTaskScheduleRewardHaveGet(self.Data.Id)
    local isCanGet = XDataCenter.RegressionManager.IsTaskScheduleRewardCanGet(self.Data.Id)
    self.BtnReward.gameObject:SetActiveEx(isHaveGet or isCanGet)
    self.ImgGet.gameObject:SetActiveEx(isHaveGet)
    self.PanelEffect.gameObject:SetActiveEx(isCanGet)
end

function XUiGridRegressionTaskSchedule:OnBtnRewardClick()
    if not self.Data then return end
    local scheduleRewardId = self.Data.Id
    if XDataCenter.RegressionManager.IsTaskScheduleRewardHaveGet(scheduleRewardId) then
        XUiManager.TipError(CS.XTextManager.GetText("RegressionTaskScheduleRewardHaveGet"))
    elseif XDataCenter.RegressionManager.IsTaskScheduleRewardCanGet(scheduleRewardId) then
        XDataCenter.RegressionManager.RequestGetRegressionScheduleReward(scheduleRewardId, function ()
            self:UpdateGetStatus()
        end)
    end
end

return XUiGridRegressionTaskSchedule