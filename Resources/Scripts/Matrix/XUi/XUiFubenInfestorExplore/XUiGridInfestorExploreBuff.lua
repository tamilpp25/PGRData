local XUiGridInfestorExploreBuff = XClass(nil, "XUiGridInfestorExploreBuff")

function XUiGridInfestorExploreBuff:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridInfestorExploreBuff:Refresh(buffId)
    self.TxtName.text = XFubenInfestorExploreConfigs.GetBuffName(buffId)
    self.TxtDetails.text = XFubenInfestorExploreConfigs.GetBuffDes(buffId)
    self.RImgBuffIcon:SetRawImage(XFubenInfestorExploreConfigs.GetBuffIcon(buffId))
end

return XUiGridInfestorExploreBuff