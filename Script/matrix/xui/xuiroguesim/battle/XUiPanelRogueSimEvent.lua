---@class XUiPanelRogueSimEvent : XUiNode
---@field private _Control XRogueSimControl
---@field private Parent XUiRogueSimBattle
local XUiPanelRogueSimEvent = XClass(XUiNode, "XUiPanelRogueSimEvent")

function XUiPanelRogueSimEvent:OnStart()
    self:RegisterUiEvents()
    self.GridMainUp.gameObject:SetActiveEx(false)
    self.GridCityUp.gameObject:SetActiveEx(false)
    self.GridExplore.gameObject:SetActiveEx(false)
    self.GridAreaBuy.gameObject:SetActiveEx(false)
    self.GridBuild.gameObject:SetActiveEx(false)
    self.GridEvent.gameObject:SetActiveEx(false)
    self.IsMainShow = false
    self.IsCityShow = false
    self.IsExploreShow = false
    self.IsAreaBuyShow = false
    self.IsBuildShow = false
    self.IsEventShow = false
end

function XUiPanelRogueSimEvent:OnGetLuaEvents()
    return {
        XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE,
        XEventId.EVENT_ROGUE_SIM_BUILDING_ADD,
        XEventId.EVENT_ROGUE_SIM_EVENT_ADD,
        XEventId.EVENT_ROGUE_SIM_EVENT_REMOVE,
        XEventId.EVENT_ROGUE_SIM_REWARDS_CHANGE,
        XEventId.EVENT_ROGUE_SIM_EVENT_UPDATE,
        XEventId.EVENT_ROGUE_SIM_TURN_NUMBER_CHANGE,
        XEventId.EVENT_ROGUE_SIM_BUILDING_BLUEPRINT_CHANGE,
        XEventId.EVENT_ROGUE_SIM_TASK_CHANGE,
        XEventId.EVENT_ROGUE_SIM_EXPLORE_GRID,
        XEventId.EVENT_ROGUE_SIM_CITY_CHANGE,
        XEventId.EVENT_ROGUE_SIM_EVENT_GAMBLE_REMOVE,
        XEventId.EVENT_ROGUE_SIM_LOCAL_GRID_DATA_CHANGE,
    }
end

function XUiPanelRogueSimEvent:OnNotify(event, ...)
    self:Refresh()
end

function XUiPanelRogueSimEvent:PlayAnim(isShow, btn)
    ---@type UiObject
    local uiObj = btn:GetComponent("UiObject")
    if XTool.UObjIsNil(uiObj) then
        return
    end
    ---@type UnityEngine.RectTransform
    local enable = uiObj:GetObject("PanelEventEnable")
    ---@type UnityEngine.RectTransform
    local disable = uiObj:GetObject("PanelEventDisable")
    if isShow then
        btn.gameObject:SetActiveEx(true)
        enable:PlayTimelineAnimation()
    else
        if not btn.gameObject.activeSelf then
            return
        end
        disable:PlayTimelineAnimation(function()
            btn.gameObject:SetActiveEx(false)
        end)
    end
end

function XUiPanelRogueSimEvent:Refresh()
    self:ClearData()

    -- 主城升级
    local isCanLevelUp = self._Control:CheckMainLevelCanLevelUp()
    if self.IsMainShow ~= isCanLevelUp then
        self.IsMainShow = isCanLevelUp
        self:PlayAnim(isCanLevelUp, self.GridMainUp)
    end
    if isCanLevelUp then
        self.GridMainUp:ActiveTextByGroup(1, false)
    end

    -- 城邦升级
    local cityCanLevelUpIds = self._Control.MapSubControl:GetCityCanLevelUpIds()
    local cityUpActive = not XTool.IsTableEmpty(cityCanLevelUpIds)
    if self.IsCityShow ~= cityUpActive then
        self.IsCityShow = cityUpActive
        self:PlayAnim(cityUpActive, self.GridCityUp)
    end
    if cityUpActive then
        self.CityId = cityCanLevelUpIds[1]
        self.GridCityUp:SetNameByGroup(1, table.nums(cityCanLevelUpIds))
    end

    -- 可探索的内容
    local exploreGridIds = self._Control:GetCanExploreGridIds()
    local exploreActive = not XTool.IsTableEmpty(exploreGridIds)
    if self.IsExploreShow ~= exploreActive then
        self.IsExploreShow = exploreActive
        self:PlayAnim(exploreActive, self.GridExplore)
    end
    if exploreActive then
        self.ExploreGridId = exploreGridIds[1]
        self.GridExplore:SetNameByGroup(1, table.nums(exploreGridIds))
    end

    -- 可购买的区域
    local areaBuyGridIds = self._Control.MapSubControl:GetCanBuyAreaGridIds()
    local areaBuyActive = not XTool.IsTableEmpty(areaBuyGridIds)
    if self.IsAreaBuyShow ~= areaBuyActive then
        self.IsAreaBuyShow = areaBuyActive
        self:PlayAnim(areaBuyActive, self.GridAreaBuy)
    end
    if areaBuyActive then
        self.AreaBuyGridId = areaBuyGridIds[1]
        self.GridAreaBuy:SetNameByGroup(1, table.nums(areaBuyGridIds))
    end

    -- 可建造建筑
    local buildableGridIds = self._Control.MapSubControl:GetBuildableGridIds()
    local buildActive = not XTool.IsTableEmpty(buildableGridIds)
    if self.IsBuildShow ~= buildActive then
        self.IsBuildShow = buildActive
        self:PlayAnim(buildActive, self.GridBuild)
    end
    if buildActive then
        self.BuildGridId = buildableGridIds[1]
        self.GridBuild:SetNameByGroup(1, table.nums(buildableGridIds))
    end

    -- 挂起事件和事件投机
    local eventIds = self._Control.MapSubControl:GetPendingEventIds()
    local eventGambleIds = self._Control.MapSubControl:GetCanGetEventGambleIds()
    local eventActive = #eventIds > 0 or #eventGambleIds > 0
    if self.IsEventShow ~= eventActive then
        self.IsEventShow = eventActive
        self:PlayAnim(eventActive, self.GridEvent)
    end
    if #eventIds > 0 then
        self.EventId = eventIds[1]
    end
    if #eventGambleIds > 0 then
        self.EventGambleId = eventGambleIds[1]
    end
    if eventActive then
        self.GridEvent:SetNameByGroup(1, #eventIds + #eventGambleIds)
    end
end

-- 清理数据
function XUiPanelRogueSimEvent:ClearData()
    self.CityId = 0
    self.ExploreGridId = 0
    self.AreaBuyGridId = 0
    self.BuildGridId = 0
    self.EventId = 0
    self.EventGambleId = 0
end

function XUiPanelRogueSimEvent:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.GridMainUp, self.OnGridMainUpClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.GridCityUp, self.OnGridCityUpClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.GridExplore, self.OnGridExploreClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.GridAreaBuy, self.OnGridAreaBuyClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.GridBuild, self.OnGridBuildClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.GridEvent, self.OnGridEventClick, nil, true)
end

function XUiPanelRogueSimEvent:OnGridMainUpClick()
    local gridId = self._Control:GetMainGridId()
    self._Control:SimulateGridClick(gridId)
end

function XUiPanelRogueSimEvent:OnGridCityUpClick()
    local gridId = self._Control.MapSubControl:GetCityGridIdById(self.CityId)
    self._Control:SimulateGridClick(gridId)
end

function XUiPanelRogueSimEvent:OnGridExploreClick()
    self._Control:CameraFocusGrid(self.ExploreGridId)
end

function XUiPanelRogueSimEvent:OnGridAreaBuyClick()
    self._Control:CameraFocusGrid(self.AreaBuyGridId)
end

function XUiPanelRogueSimEvent:OnGridBuildClick()
    self._Control:SimulateGridClick(self.BuildGridId)
end

function XUiPanelRogueSimEvent:OnGridEventClick()
    if XTool.IsNumberValid(self.EventGambleId) then
        self._Control.MapSubControl:EventGambleGridClick(self.EventGambleId)
        return
    end
    self._Control.MapSubControl:ExploreEventGrid(self.EventId)
end

return XUiPanelRogueSimEvent
