local XUiPlanetDetailRole = require("XUi/XUiPlanet/Explore/View/Detail/XUiPlanetDetailRole")
local XUiPlanetDetailRoleList = require("XUi/XUiPlanet/Explore/View/Detail/XUiPlanetDetailRoleList")

---@class XUiPlanetDetail02:XLuaUi
local XUiPlanetDetail02 = XLuaUiManager.Register(XLuaUi, "UiPlanetDetail02")

function XUiPlanetDetail02:Ctor()
    self._PanelCharacter = false
    self._PanelBoss = false
end

function XUiPlanetDetail02:OnAwake()
    self:BindExitBtns(self.BtnClose)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_PAUSE_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.DETAIL)
end

---@param role XPlanetRoleBase
---@param roleList XPlanetRoleBase[]
function XUiPlanetDetail02:OnStart(role, roleList)
    if roleList then
        self.PanelBoss.gameObject:SetActiveEx(false)
        self.PanelRole.gameObject:SetActiveEx(true)
        ---@type XUiPlanetDetailRoleList
        self._PanelCharacter = XUiPlanetDetailRoleList.New(self.PanelRole)
        self._PanelCharacter:SetRoleList(roleList)
        self._PanelCharacter:SetRoleSelected(role)
        return
    end

    ---@type XUiPlanetDetailRole
    self._PanelBoss = XUiPlanetDetailRole.New(self.PanelBoss)
    self._PanelBoss:Update(role)
    self.PanelBoss.gameObject:SetActiveEx(true)
    self.PanelRole.gameObject:SetActiveEx(false)
end

function XUiPlanetDetail02:OnEnable()
    if self._PanelCharacter then
        self._PanelCharacter:OnEnable()
    end
    if self._PanelBoss then
        self._PanelBoss:OnEnable()
    end
end

function XUiPlanetDetail02:OnDisable()
    if self._PanelCharacter then
        self._PanelCharacter:OnDisable()
    end
    if self._PanelBoss then
        self._PanelBoss:OnDisable()
    end
end

function XUiPlanetDetail02:OnDestroy()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.DETAIL)
end

return XUiPlanetDetail02