
local XUiPanelSGHudContainer = require("XUi/XUiSkyGarden/XCafe/Panel/XUiPanelSGHudContainer")

---@class XUiSkyGardenCafeComponent : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XSkyGardenCafeControl
---@field _PanelCoffee XUiPanelSGHudContainer
---@field _PanelReview XUiPanelSGHudContainer
---@field _PanelExpression XUiPanelSGHudContainer
local XUiSkyGardenCafeComponent = XLuaUiManager.Register(XLuaUi, "UiSkyGardenCafeComponent")
local HudType = XMVCA.XSkyGardenCafe.HudType
local EventId = XMVCA.XBigWorldService.DlcEventId

function XUiSkyGardenCafeComponent:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenCafeComponent:OnStart()
    self:InitView()
    
    XEventManager.AddEventListener(EventId.EVENT_CAFE_HUD_REFRESH, self.RefreshHud, self)
    XEventManager.AddEventListener(EventId.EVENT_CAFE_HUD_HIDE, self.HideHud, self)
end

function XUiSkyGardenCafeComponent:OnDestroy()
    self:StopTimer()

    XEventManager.RemoveEventListener(EventId.EVENT_CAFE_HUD_REFRESH, self.RefreshHud, self)
    XEventManager.RemoveEventListener(EventId.EVENT_CAFE_HUD_HIDE, self.HideHud, self)
end

function XUiSkyGardenCafeComponent:InitUi()
    self._PanelCoffee = XUiPanelSGHudContainer.New(self.PanelCoffee, self, self.GridCoffee)
    self._PanelReview = XUiPanelSGHudContainer.New(self.PanelReview, self, self.GridFavorability)
    self._PanelExpression = XUiPanelSGHudContainer.New(self.PanelExpression, self, self.GridExpression)
    
    self._Timer = XScheduleManager.ScheduleForever(function()
        self._PanelCoffee:Update()
        self._PanelReview:Update()
        self._PanelExpression:Update()
    end, 0)
end

function XUiSkyGardenCafeComponent:InitCb()
end

function XUiSkyGardenCafeComponent:InitView()
end

function XUiSkyGardenCafeComponent:StopTimer()
    if not self._Timer then
        return
    end
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = nil
end

function XUiSkyGardenCafeComponent:RefreshHud(id, target, offset, type, value)
    if type == HudType.CoffeeHud then
        self._PanelCoffee:RefreshHud(id, target, offset, type, value)
    elseif type == HudType.ReviewHud then
        self._PanelReview:RefreshHud(id, target, offset, type, value)
    elseif type == HudType.EmojiHud then
        self._PanelExpression:RefreshHud(id, target, offset, type, value)
    end
end

function XUiSkyGardenCafeComponent:HideHud(id, type)
    if type == HudType.CoffeeHud then
        self._PanelCoffee:HideHud(id)
    elseif type == HudType.ReviewHud then
        self._PanelReview:HideHud(id)
    elseif type == HudType.EmojiHud then
        self._PanelExpression:HideHud(id)
    end
end