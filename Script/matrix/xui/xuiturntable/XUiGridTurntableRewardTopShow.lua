local XUiGridTurntableProgressReward = require("XUi/XUiTurntable/XUiGridTurntableProgressReward")


local XUiGridTurntableRewardTopShow = XClass(XUiGridTurntableProgressReward, 'XUiPanelTopShow')

function XUiGridTurntableRewardTopShow:OnStart()
    self.Super.OnStart(self)
    self.BtnReward.CallBack = handler(self, self.OnExtendRewardBtnClick)
end

function XUiGridTurntableRewardTopShow:Update()
    self.Super.Update(self)
    self.BtnReward:SetButtonState(self._CanGain and CS.UiButtonState.Normal or CS.UiButtonState.Disable)

    self.BtnRewardAchieved.gameObject:SetActiveEx(self._HasGain)
    self.BtnRewardLock.gameObject:SetActiveEx(not self._CanGain and not self._HasGain)
end

function XUiGridTurntableRewardTopShow:OnExtendRewardBtnClick()
    if self._CanGain then
        self:OnClick()
    end
end


return XUiGridTurntableRewardTopShow