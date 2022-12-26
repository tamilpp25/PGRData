local XUiGridInfestorExploreEvent = require("XUi/XUiFubenInfestorExplore/XUiGridInfestorExploreEvent")

local XUiGridInfestorExploreContract = XClass(nil, "XUiGridInfestorExploreContract")

function XUiGridInfestorExploreContract:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:SetSelect(false)
end

function XUiGridInfestorExploreContract:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridInfestorExploreContract:Refresh(shopEventId)
    local cost = XFubenInfestorExploreConfigs.GetEventGoodsCost(shopEventId)
    self.TxtPrice.text = cost

    self.EventGrid = self.EventGrid or XUiGridInfestorExploreEvent.New(self.GridEvent, self.RootUi)
    self.EventGrid:Refresh(shopEventId)

    self.ImgSellOut.gameObject:SetActiveEx(XDataCenter.FubenInfestorExploreManager.IsShopEventSellOut())
end

function XUiGridInfestorExploreContract:SetSelect(value)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(value)
    end
end

return XUiGridInfestorExploreContract