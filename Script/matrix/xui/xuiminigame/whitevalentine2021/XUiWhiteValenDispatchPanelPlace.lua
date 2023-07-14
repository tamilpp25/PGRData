--
local XUiWhiteValenDispatchPanelPlace = XClass(nil, "")

function XUiWhiteValenDispatchPanelPlace:Ctor(rootUi, ui, place)
    self.RootUi = rootUi
    XTool.InitUiObjectByUi(self, ui)
    self.Place = place
    self:InitPlace()
end

function XUiWhiteValenDispatchPanelPlace:InitPlace()
    self.RImgRank:SetSprite(self.Place:GetRankIcon())
    self.TxtEventName.text = self.Place:GetEventName()
    self.TxtEventDescription.text = self.Place:GetEventDescription()
    self.ImgBg:SetRawImage(self.Place:GetBgPath())
end

return XUiWhiteValenDispatchPanelPlace