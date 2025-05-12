
local XUiPanelTurntableRewardShow = XClass(XUiNode, 'XUiPanelTurntableRewardShow')

function XUiPanelTurntableRewardShow:OnEnable()
    self:PlayEnableAnimation()
end

function XUiPanelTurntableRewardShow:PlayEnableAnimation()
    self:PlayAnimationWithMask('PanelSettllementEnable')
end


return XUiPanelTurntableRewardShow