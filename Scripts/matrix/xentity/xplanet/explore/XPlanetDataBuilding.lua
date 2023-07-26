---@class XPlanetDataBuilding
local XPlanetDataBuilding = XClass(nil, "XPlanetDataBuilding")

function XPlanetDataBuilding:Ctor(id)
    self._Id = id
    self._Buff = false
    self._Debuff = false
end

function XPlanetDataBuilding:GetId()
    return self._Id
end

function XPlanetDataBuilding:GetIcon()
    return XPlanetWorldConfigs.GetBuildingIconUrl(self:GetId())
end

function XPlanetDataBuilding:GetName()
    return XPlanetWorldConfigs.GetBuildingName(self:GetId())
end

function XPlanetDataBuilding:GetDesc()
    return XPlanetWorldConfigs.GetBuildingBgDesc(self:GetId())
end

function XPlanetDataBuilding:GetCost()
    return XPlanetWorldConfigs.GetBuildingCast(self:GetId())
end

function XPlanetDataBuilding:GetCostIcon()
    local itemId = XDataCenter.ItemManager.ItemId.PlanetRunningStageCoin
    return XItemConfigs.GetItemIconById(itemId)
end

function XPlanetDataBuilding:GetLevel()
    return XPlanetWorldConfigs.GetBuildingCycleLevelUp(self:GetId())
end

function XPlanetDataBuilding:GetBuff()
    if self._Buff then
        return self._Buff
    end
    local events = XPlanetWorldConfigs.GetBuildingEvents(self:GetId())
    local eventsBuff = {}
    for _, eventId in ipairs(events) do
        if XPlanetStageConfigs.GetEventIsIncrease(eventId) then
            table.insert(eventsBuff, eventId)
        end
    end
    -- 连携事件
    local combatEventId = XPlanetWorldConfigs.GetBuildingComboEvent(self:GetId())
    if XTool.IsNumberValid(combatEventId) and XPlanetStageConfigs.GetEventIsIncrease(combatEventId) then
        table.insert(eventsBuff, combatEventId)
    end
    local buffList = XDataCenter.PlanetExploreManager.GetBuffList(eventsBuff)
    self._Buff = {}
    -- 过滤不显示事件
    for _, buff in ipairs(buffList) do
        if buff:IsShow() then
            table.insert(self._Buff, buff)
        end
    end
    return self._Buff
end

function XPlanetDataBuilding:GetDebuff()
    if self._Debuff then
        return self._Debuff
    end
    local events = XPlanetWorldConfigs.GetBuildingEvents(self:GetId())
    local eventsDebuff = {}
    for _, eventId in ipairs(events) do
        if not XPlanetStageConfigs.GetEventIsIncrease(eventId) then
            table.insert(eventsDebuff, eventId)
        end
    end
    -- 连携事件
    local combatEventId = XPlanetWorldConfigs.GetBuildingComboEvent(self:GetId())
    if XTool.IsNumberValid(combatEventId) and not XPlanetStageConfigs.GetEventIsIncrease(combatEventId) then
        table.insert(eventsDebuff, combatEventId)
    end
    local buffList = XDataCenter.PlanetExploreManager.GetBuffList(eventsDebuff)
    self._Debuff = {}
    -- 过滤不显示事件
    for _, buff in ipairs(buffList) do
        if buff:IsShow() then
            table.insert(self._Debuff, buff)
        end
    end
    return self._Debuff
end

function XPlanetDataBuilding:IsCanSelect()
    return XPlanetWorldConfigs.GetBuildingIsCanSelect(self:GetId())
end

return XPlanetDataBuilding