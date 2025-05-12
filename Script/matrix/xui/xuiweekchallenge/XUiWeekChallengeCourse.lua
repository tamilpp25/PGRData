local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiWeekChallengeCourse
local XUiWeekChallengeCourse = XClass(nil, "XUiWeekChallengeCourse")

function XUiWeekChallengeCourse:Ctor(ui)
    self._TaskCount = false
    self._RewardId = false
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:InitUi()
end

function XUiWeekChallengeCourse:SetReward(rewardId)
    self._RewardId = rewardId
    local itemId = XEntityHelper.GetRewardItemId(rewardId)
    self.GridCommon:Refresh(itemId, {ShowReceived = XDataCenter.WeekChallengeManager.IsRewardReceived(rewardId)})
end

function XUiWeekChallengeCourse:GetButtonComponent()
    return XUiHelper.TryGetComponent(self.Transform, "PanelReward/BtnClick", "Button")
end

function XUiWeekChallengeCourse:SetTaskCount(taskCount)
    XUiHelper.TryGetComponent(self.Transform, "TxtCurStage", "Text").text = taskCount or 0
    self._TaskCount = taskCount
    self:UpdateState()
end

function XUiWeekChallengeCourse:UpdateState()
    local isRewardReceived = XDataCenter.WeekChallengeManager.IsRewardReceived(self._TaskCount)
    self.PanelFinish.gameObject:SetActiveEx(isRewardReceived)

    local IsRewardCanReceived = XDataCenter.WeekChallengeManager.IsRewardCanReceived(self._TaskCount)
    self.PanelEffect.gameObject:SetActiveEx(IsRewardCanReceived)

    if self._RewardId then
        self:SetReward(self._RewardId)
    end
end

function XUiWeekChallengeCourse:InitUi()
    ---@type XUiGridCommon
    self.GridCommon = XUiGridCommon.New(false, self.Transform:Find("PanelReward/GridCommon"))
    self.PanelFinish = self.Transform:Find("PanelReward/PanelFinish")
    self.PanelEffect = self.Transform:Find("PanelReward/PanelEffect")
end

function XUiWeekChallengeCourse:CallClickItem()
    self.GridCommon:OnBtnClickClick()
end

return XUiWeekChallengeCourse
