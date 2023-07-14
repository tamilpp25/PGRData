--
--Author: wujie
--Note: 回归活动发送邀请奖励格子

local XUiGridSendInvitation = XClass(nil, "XUiGridSendInvitation")

function XUiGridSendInvitation:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.GridCommon = XUiGridCommon.New(rootUi, self.PanelGridCommon)
    self.BtnGet.CallBack = function() self:OnBtnGetClick() end
end

function XUiGridSendInvitation:UpdateGetStatus()
    local isHaveGet = XDataCenter.RegressionManager.IsSendInvitationRewardHaveGet(self.InvitationRewardId)
    self.ImgGet.gameObject:SetActiveEx(isHaveGet)
    local isCanGet = XDataCenter.RegressionManager.IsSendInvitationRewardCanGet(self.InvitationRewardId)
    self.PanelEffect.gameObject:SetActiveEx(isCanGet)
end

function XUiGridSendInvitation:Refresh(id)
    if not id then return end
    self.InvitationRewardId = id
    local sendInvitationRewardTemplate = XRegressionConfigs.GetSendInvitationRewardTemplate(id)
    local rewardList = XRewardManager.GetRewardList(sendInvitationRewardTemplate.RewardId)
    local firstIndex = 1
    local reward = rewardList[firstIndex]
    if reward then
        self.GridCommon:Refresh(reward)
    end
    local needAcceptedCount = sendInvitationRewardTemplate.People
    self.TxtInvitationNum.text = needAcceptedCount
    self:UpdateGetStatus()
end

function XUiGridSendInvitation:OnBtnGetClick()
    if not self.InvitationRewardId then return end
    if not XDataCenter.RegressionManager.IsInvitationActivityInTime() then
        XUiManager.TipError(CS.XTextManager.GetText("RegressionInvitationActivityOver"))
        return
    end

    if XDataCenter.RegressionManager.IsSendInvitationRewardHaveGet(self.InvitationRewardId) then
        XUiManager.TipError(CS.XTextManager.GetText("RegressionTaskScheduleRewardHaveGet"))
    elseif XDataCenter.RegressionManager.IsSendInvitationRewardCanGet(self.InvitationRewardId) then
        XDataCenter.RegressionManager.RequestGetInviteReward(self.InvitationRewardId, function()
            self:UpdateGetStatus()
        end)
    else
        XUiManager.TipError(CS.XTextManager.GetText("RegressionSendInvitationRewardNeedMore"))
    end
end

return XUiGridSendInvitation