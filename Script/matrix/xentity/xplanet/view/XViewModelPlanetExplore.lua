local XPlanetDataBuilding = require("XEntity/XPlanet/Explore/XPlanetDataBuilding")

---@class XViewModelPlanetExplore
local XViewModelPlanetExplore = XClass(nil, "XViewModelPlanetExplore")

function XViewModelPlanetExplore:Ctor()
    ---@type XPlanetStage
    self._Stage = false
end

function XViewModelPlanetExplore:SetStage(stage)
    self._Stage = stage
end

function XViewModelPlanetExplore:GetStageId()
    return self._Stage:GetStageId()
end

function XViewModelPlanetExplore:GetStage()
    return self._Stage
end

function XViewModelPlanetExplore:GetPlanetName()
    return self._Stage:GetName()
end

function XViewModelPlanetExplore:GetPlanetDesc()
    return self._Stage:GetDesc()
end

function XViewModelPlanetExplore:GetPlanetIcon()
    return self._Stage:GetIcon()
end

function XViewModelPlanetExplore:GetBoss()
    return self._Stage:GetBoss()
end

function XViewModelPlanetExplore:GetTeam()
    return XDataCenter.PlanetExploreManager.GetTeam()
end

function XViewModelPlanetExplore:GetCharacter()
    return self:GetTeam():GetMembers()
end

function XViewModelPlanetExplore:GetBuildingSelected()
    return self._Stage:GetBuildingSelected()
end

function XViewModelPlanetExplore:GetBuildingSelected4View()
    local data = self._Stage:GetBuildingSelected()
    local result = {}
    for i = 1, #data do
        local id = data[i]
        ---@type XPlanetDataBuilding
        local building = XPlanetDataBuilding.New(id)
        if building:IsCanSelect() then
            result[#result + 1] = building
        end
    end
    return result
end

function XViewModelPlanetExplore:GetBuildingCapacity()
    return self._Stage:GetBuildingCapacity()
end

return XViewModelPlanetExplore