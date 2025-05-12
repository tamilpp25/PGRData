local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPickFlipRewardGrid = XClass(nil, "XUiPickFlipRewardGrid")

function XUiPickFlipRewardGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    -- XPFReward
    self.Reward = nil
    -- XUiGridCommon
    self.GridCommon = nil
end

-- reward : XPFReward
function XUiPickFlipRewardGrid:SetData(reward)
    self.Reward = reward
    self.GridCommon = XUiGridCommon.New(self.RootUi, self.GameObject)
    self.GridCommon:Refresh(reward:GetShowItemId())
    self.TxtDownCount.text = reward:GetCount()
end

function XUiPickFlipRewardGrid:SetSelectStatus(value)
    self.ImgSelect.gameObject:SetActiveEx(value)
end

function XUiPickFlipRewardGrid:ShowDetailUi()
    self.GridCommon:OnBtnClickClick()
end

return XUiPickFlipRewardGrid