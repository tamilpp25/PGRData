local XUiGridInfestorExploreEvent = XClass(nil, "XUiGridInfestorExploreEvent")

function XUiGridInfestorExploreEvent:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiGridInfestorExploreEvent:Refresh(eventId)
    self.TxtName.text = XFubenInfestorExploreConfigs.GetEventName(eventId)
    self.TxtDetails.text = XFubenInfestorExploreConfigs.GetEventDes(eventId)
    self.RImgBuffIcon:SetRawImage(XFubenInfestorExploreConfigs.GetEventIcon(eventId))
    if self.ImgQuality then
        self.RootUi:SetUiSprite(XFubenInfestorExploreConfigs.GetEventQualityIcon(eventId))
    end
end

return XUiGridInfestorExploreEvent