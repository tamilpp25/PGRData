local XUiGridDoomsdayTarget = XClass(nil, "XUiGridDoomsdayTarget")

function XUiGridDoomsdayTarget:Init()
    self:SetPassed(false)
end

function XUiGridDoomsdayTarget:Refresh(targetId)
    local desc = XDoomsdayConfigs.TargetConfig:GetProperty(targetId, "Desc")
    self.TxtActive.text = desc
    self.TxtUnActive.text = desc
end

function XUiGridDoomsdayTarget:SetPassed(value)
    self.PanelActive.gameObject:SetActiveEx(value)
    self.PanelUnActive.gameObject:SetActiveEx(not value)
end

return XUiGridDoomsdayTarget
