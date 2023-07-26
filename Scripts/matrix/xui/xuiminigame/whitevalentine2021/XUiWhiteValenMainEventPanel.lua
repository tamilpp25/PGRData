-- 白色情人节约会活动主界面事件面板
local XUiWhiteValenMainEventPanel = XClass(nil, "XUiWhiteValenMainEventPanel")

function XUiWhiteValenMainEventPanel:Ctor(rootUi, ui)
    XTool.InitUiObjectByUi(self, ui)
    self.RootUi = rootUi
    self.PlaceManager = XDataCenter.WhiteValentineManager.GetPlaceManager()
    self:InitPlaces()
end

function XUiWhiteValenMainEventPanel:InitPlaces()
    self.Places = {}
    local places = self.PlaceManager:GetPlaceList()
    local XUiPlace = require("XUi/XUiMiniGame/WhiteValentine2021/XUiWhiteValenPlace")
    for _, place in pairs(places) do
        local order = place:GetOrderId()
        local ui = self["PanelGrid" .. order]
        if ui then
            local uiPlace = XUiPlace.New(self.RootUi, ui, place)
            self.Places[order] = uiPlace
        end
    end
end

function XUiWhiteValenMainEventPanel:RefreshPanel()
    for _, place in pairs(self.Places) do
        place:Refresh()
    end
end

function XUiWhiteValenMainEventPanel:RefreshPlaces(placeId)
    local place = self.PlaceManager:GetPlaceByPlaceId(placeId)
    local uiPlace = self.Places[place:GetOrderId()]
    if uiPlace then uiPlace:Refresh() end
    return uiPlace
end

function XUiWhiteValenMainEventPanel:OpenNewPlaces(placeDatas)
    if not placeDatas then return end
    for _, placeData in pairs(placeDatas) do
        local uiPlace = self:RefreshPlaces(placeData.Id)
        if uiPlace.AnimOpen then uiPlace.AnimOpen:Play() end
        if uiPlace.OpenEffect then uiPlace.OpenEffect.gameObject:SetActiveEx(true) end
    end
end

function XUiWhiteValenMainEventPanel:AddEventListeners()
    if self.ListenersAdded then return end
    self.ListenersAdded = true
    XEventManager.AddEventListener(XEventId.EVENT_WHITEVALENTINE_SHOW_PLACE, self.RefreshPanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_WHITEVALENTINE_REFRESH_PLACE, self.RefreshPlaces, self)
    XEventManager.AddEventListener(XEventId.EVENT_WHITEVALENTINE_OPEN_PLACE, self.OpenNewPlaces, self)
end

function XUiWhiteValenMainEventPanel:RemoveEventListeners()
    if not self.ListenersAdded then return end
    XEventManager.RemoveEventListener(XEventId.EVENT_WHITEVALENTINE_SHOW_PLACE, self.RefreshPanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_WHITEVALENTINE_REFRESH_PLACE, self.RefreshPlaces, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_WHITEVALENTINE_OPEN_PLACE, self.OpenNewPlaces, self)
    for _, place in pairs(self.Places) do
        place:RemoveDispatchingTimer()
    end
    self.ListenersAdded = false
end

return XUiWhiteValenMainEventPanel