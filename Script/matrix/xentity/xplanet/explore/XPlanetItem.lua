---@class XPlanetItem
local XPlanetItem = XClass(nil, "XPlanetItem")

function XPlanetItem:Ctor(id)
    self._Id = id
end

function XPlanetItem:GetIcon()
    return XPlanetStageConfigs.GetItemIcon(self._Id)
end

function XPlanetItem:GetId()
    return self._Id
end

function XPlanetItem:GetName()
    return XPlanetStageConfigs.GetItemName(self._Id)
end

function XPlanetItem:GetDesc()
    return XPlanetStageConfigs.GetItemDesc(self._Id)
end

function XPlanetItem:GetBuff()
    local events = XPlanetStageConfigs.GetItemEvents(self._Id)
    local buffList = XDataCenter.PlanetExploreManager.GetBuffList(events)
    return buffList
end

return XPlanetItem