-- 代办事件
---@class XUiPanelRogueSimAgencyEvent : XUiNode
---@field private _Control XRogueSimControl
---@field Parent XUiRogueSimPopupRoundEnd
local XUiPanelRogueSimAgencyEvent = XClass(XUiNode, "XUiPanelRogueSimAgencyEvent")

function XUiPanelRogueSimAgencyEvent:OnStart()
    self:RegisterUiEvents()
    self.GridMainUp.gameObject:SetActiveEx(false)
    self.GridCityUp.gameObject:SetActiveEx(false)
    self.GridExplore.gameObject:SetActiveEx(false)
    self.GridAreaBuy.gameObject:SetActiveEx(false)
    self.GridBuild.gameObject:SetActiveEx(false)
    self.GridEvent.gameObject:SetActiveEx(false)
    self.TxtNone.gameObject:SetActiveEx(false)
    -- 是否有格子
    self.IsHaveGrid = false
end

function XUiPanelRogueSimAgencyEvent:Refresh()
    self:ClearData()
    self.IsHaveGrid = false
    self:RefreshMainUp()
    self:RefreshCityUp()
    self:RefreshExplore()
    self:RefreshAreaBuy()
    self:RefreshBuild()
    self:RefreshEvent()
    self.Content.gameObject:SetActiveEx(self.IsHaveGrid)
    self.TxtNone.gameObject:SetActiveEx(not self.IsHaveGrid)
end

-- 主城升级
function XUiPanelRogueSimAgencyEvent:RefreshMainUp()
    local isCanLevelUp = self._Control:CheckMainLevelCanLevelUp()
    self.GridMainUp.gameObject:SetActiveEx(isCanLevelUp)
    if isCanLevelUp then
        self.IsHaveGrid = true
        self.GridMainUp:SetSpriteVisible(false)
    end
end

-- 城邦升级
function XUiPanelRogueSimAgencyEvent:RefreshCityUp()
    local cityCanLevelUpIds = self._Control.MapSubControl:GetCityCanLevelUpIds()
    local cityUpActive = not XTool.IsTableEmpty(cityCanLevelUpIds)
    self.GridCityUp.gameObject:SetActiveEx(cityUpActive)
    if cityUpActive then
        self.IsHaveGrid = true
        self.CityId = cityCanLevelUpIds[1]
        self.GridCityUp:SetNameByGroup(0, table.nums(cityCanLevelUpIds))
    end
end

-- 可探索的内容
function XUiPanelRogueSimAgencyEvent:RefreshExplore()
    local exploreGridIds = self._Control:GetCanExploreGridIds()
    local exploreActive = not XTool.IsTableEmpty(exploreGridIds)
    self.GridExplore.gameObject:SetActiveEx(exploreActive)
    if exploreActive then
        self.IsHaveGrid = true
        self.ExploreGridId = exploreGridIds[1]
        self.GridExplore:SetNameByGroup(0, table.nums(exploreGridIds))
    end
end

-- 可购买的区域
function XUiPanelRogueSimAgencyEvent:RefreshAreaBuy()
    local areaBuyGridIds = self._Control.MapSubControl:GetCanBuyAreaGridIds()
    local areaBuyActive = not XTool.IsTableEmpty(areaBuyGridIds)
    self.GridAreaBuy.gameObject:SetActiveEx(areaBuyActive)
    if areaBuyActive then
        self.IsHaveGrid = true
        self.AreaBuyGridId = areaBuyGridIds[1]
        self.GridAreaBuy:SetNameByGroup(0, table.nums(areaBuyGridIds))
    end
end

-- 可建造建筑
function XUiPanelRogueSimAgencyEvent:RefreshBuild()
    local buildableGridIds = self._Control.MapSubControl:GetBuildableGridIds()
    local buildActive = not XTool.IsTableEmpty(buildableGridIds)
    self.GridBuild.gameObject:SetActiveEx(buildActive)
    if buildActive then
        self.IsHaveGrid = true
        self.BuildGridId = buildableGridIds[1]
        self.GridBuild:SetNameByGroup(0, table.nums(buildableGridIds))
    end
end

-- 挂起事件和事件投机
function XUiPanelRogueSimAgencyEvent:RefreshEvent()
    local eventIds = self._Control.MapSubControl:GetPendingEventIds()
    local eventGambleIds = self._Control.MapSubControl:GetCanGetEventGambleIds()
    local eventActive = #eventIds > 0 or #eventGambleIds > 0
    self.GridEvent.gameObject:SetActiveEx(eventActive)
    if #eventIds > 0 then
        self.EventId = eventIds[1]
    end
    if #eventGambleIds > 0 then
        self.EventGambleId = eventGambleIds[1]
    end
    if eventActive then
        self.IsHaveGrid = true
        self.GridEvent:SetNameByGroup(0, #eventIds + #eventGambleIds)
    end
end

-- 清理数据
function XUiPanelRogueSimAgencyEvent:ClearData()
    self.CityId = 0
    self.ExploreGridId = 0
    self.AreaBuyGridId = 0
    self.BuildGridId = 0
    self.EventId = 0
    self.EventGambleId = 0
end

function XUiPanelRogueSimAgencyEvent:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.GridMainUp, self.OnGridMainUpClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.GridCityUp, self.OnGridCityUpClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.GridExplore, self.OnGridExploreClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.GridAreaBuy, self.OnGridAreaBuyClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.GridBuild, self.OnGridBuildClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.GridEvent, self.OnGridEventClick, nil, true)
end

function XUiPanelRogueSimAgencyEvent:OnGridMainUpClick()
    local gridId = self._Control:GetMainGridId()
    self.Parent:CloseAndSimulateGridClick(gridId)
end

function XUiPanelRogueSimAgencyEvent:OnGridCityUpClick()
    local gridId = self._Control.MapSubControl:GetCityGridIdById(self.CityId)
    self.Parent:CloseAndSimulateGridClick(gridId)
end

function XUiPanelRogueSimAgencyEvent:OnGridExploreClick()
    self.Parent:CloseAndJumpToGrid(self.ExploreGridId)
end

function XUiPanelRogueSimAgencyEvent:OnGridAreaBuyClick()
    self.Parent:CloseAndJumpToGrid(self.AreaBuyGridId)
end

function XUiPanelRogueSimAgencyEvent:OnGridBuildClick()
    self.Parent:CloseAndSimulateGridClick(self.BuildGridId)
end

function XUiPanelRogueSimAgencyEvent:OnGridEventClick()
    self.Parent:CloseAndOpenEventPopup(self.EventId, self.EventGambleId)
end

return XUiPanelRogueSimAgencyEvent
