local XUiGridGame2048StageStar = XClass(XUiNode, 'XUiGridGame2048StageStar')

function XUiGridGame2048StageStar:SetIsOn(isOn)
    self.ImgOn.gameObject:SetActiveEx(isOn)
    self.ImgOff.gameObject:SetActiveEx(not isOn)
end

return XUiGridGame2048StageStar