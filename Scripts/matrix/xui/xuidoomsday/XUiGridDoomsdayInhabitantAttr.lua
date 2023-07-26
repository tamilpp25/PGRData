local XUiGridDoomsdayInhabitantAttr = XClass(nil, "XUiGridDoomsdayInhabitantAttr")

function XUiGridDoomsdayInhabitantAttr:Ctor(showFullName)
    self.ShowFullName = showFullName
end

function XUiGridDoomsdayInhabitantAttr:Refresh(info)
    self.RImgAttr:SetRawImage(XDoomsdayConfigs.AttributeTypeConfig:GetProperty(info.AttrType, "BadIcon"))
    self.TxtTool1.text =
        self.ShowFullName and
        CsXTextManagerGetText(
            "DoomsdayInhabitantAttrBad",
            XDoomsdayConfigs.AttributeTypeConfig:GetProperty(info.AttrType, "BadName"),
            info.Count
        ) or
        info.Count
end

return XUiGridDoomsdayInhabitantAttr
