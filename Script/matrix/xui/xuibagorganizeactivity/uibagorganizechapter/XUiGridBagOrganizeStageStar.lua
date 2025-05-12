local XUiGridBagOrganizeStageStar = XClass(XUiNode, 'XUiGridBagOrganizeStageStar')

function XUiGridBagOrganizeStageStar:SetIsOn(isOn)
    self.ImgOn.gameObject:SetActiveEx(isOn)
    self.ImgOff.gameObject:SetActiveEx(not isOn)
end

return XUiGridBagOrganizeStageStar