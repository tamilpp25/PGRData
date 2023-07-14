local XUiGridDoomsdayResourceAllot = XClass(nil, "XUiGridDoomsdayResourceAllot")

function XUiGridDoomsdayResourceAllot:Refresh(resource)
    self.Resource = resource

    self.RImgTool:SetRawImage(XDoomsdayConfigs.ResourceConfig:GetProperty(resource:GetProperty("_CfgId"), "Icon"))

    self:RefreshCount()
end

function XUiGridDoomsdayResourceAllot:RefreshCount()
    self.AllotCount = self.AllotCount or 0

    self.Parent:BindViewModelPropertyToObj(
        self.Resource,
        function(count)
            self.TxtTool.text = count .. XDoomsdayConfigs.GetNumerText(-self.AllotCount)
        end,
        "_Count"
    )
end

function XUiGridDoomsdayResourceAllot:SetAllotCount(count)
    self.AllotCount = count
    self:RefreshCount()
end

return XUiGridDoomsdayResourceAllot
