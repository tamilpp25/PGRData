local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiDlcMultiPlayerGiftRewardGridItem
local XUiDlcMultiPlayerGiftRewardGridItem = XClass(XUiGridCommon, "XUiDlcMultiPlayerGiftRewardGridItem")

function XUiDlcMultiPlayerGiftRewardGridItem:AutoInitUi()
    self.Super.AutoInitUi(self)
    self.TxtHas = XUiHelper.TryGetComponent(self.Transform, "HasTag/TxtHas", "Text")
    self.HasTagObj = XUiHelper.TryGetComponent(self.Transform, "HasTag", "RectTransform").gameObject
end

function XUiDlcMultiPlayerGiftRewardGridItem:Refresh(reward)
    self.Super.Refresh(self, reward)
    self.TxtHas.text = XUiHelper.GetText("MultiMouseHunterBpAlreadyGetReward")
end

function XUiDlcMultiPlayerGiftRewardGridItem:SetReceived(isReceive)
    self.Super.SetReceived(self, isReceive)
    self.HasTagObj:SetActiveEx(isReceive)
end

return XUiDlcMultiPlayerGiftRewardGridItem