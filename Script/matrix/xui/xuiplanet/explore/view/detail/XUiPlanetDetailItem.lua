local XUiPlanetDetailItemPanel = require("XUi/XUiPlanet/Explore/View/Detail/XUiPlanetDetailItemPanel")

---@class XUiPlanetDetailItem:XLuaUi
local XUiPlanetDetailItem = XLuaUiManager.Register(XLuaUi, "UiPlanetDetailItem")

function XUiPlanetDetailItem:Ctor()
    ---@type XUiPlanetDetailItemPanel
    self._Panel = false
end

function XUiPlanetDetailItem:OnAwake()
    self:BindExitBtns(self.BtnClose)
    self.PanelTitleList.gameObject:SetActiveEx(false)
    self.PanelItemList.gameObject:SetActiveEx(true)
    self._Panel = XUiPlanetDetailItemPanel.New(self.PanelItemList)
end

function XUiPlanetDetailItem:OnEnable()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PAUSE_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.ITEM)
end

function XUiPlanetDetailItem:OnDisable()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.ITEM)
end

---@param item XPlanetItem
function XUiPlanetDetailItem:OnStart(item)
    self._Panel:Update(item)
end

return XUiPlanetDetailItem
