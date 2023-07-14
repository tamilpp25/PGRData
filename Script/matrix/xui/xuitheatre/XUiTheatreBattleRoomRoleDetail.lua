--######################## XUiTheatreRoleGrid ########################
local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
local XUiTheatreRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiTheatreRoleGrid")

function XUiTheatreRoleGrid:SetData(entity)
    self.Super.SetData(self, entity)
    if not entity:GetIsLocalRole() then
        self.TxtLevel.text = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetCurrentLevel()
        self.TxtPower.text = entity:GetAbility()
    end
end

--######################## XUiTheatreBattleRoomRoleDetail ########################
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiTheatreBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiTheatreBattleRoomRoleDetail")

function XUiTheatreBattleRoomRoleDetail:Ctor()
    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    self.Chapter = self.AdventureManager:GetCurrentChapter()
end

-- characterType : XCharacterConfigs.CharacterType
function XUiTheatreBattleRoomRoleDetail:GetEntities(characterType)
    local roles = self.AdventureManager:GetCurrentRoles(true)
    local result = {}
    for _, role in ipairs(roles) do
        if role:GetCharacterViewModel():GetCharacterType() == characterType then
            table.insert(result, role)
        end
    end
    return result
end

function XUiTheatreBattleRoomRoleDetail:GetCharacterViewModelByEntityId(entityId)
    local role = self.AdventureManager:GetRole(entityId)
    if role == nil then return nil end
    return role:GetCharacterViewModel()
end

-- team : XTeam
-- sortTagType : XRoomCharFilterTipsConfigs.EnumSortTag
function XUiTheatreBattleRoomRoleDetail:SortEntitiesWithTeam(team, entities, sortTagType)
    table.sort(entities, function(entityA, entityB)
        local _, posA = team:GetEntityIdIsInTeam(entityA:GetId())
        local _, posB = team:GetEntityIdIsInTeam(entityB:GetId())
        local teamWeightA = posA ~= -1 and (10 - posA) * 100000 or 0
        local teamWeightB = posB ~= -1 and (10 - posB) * 100000 or 0
        teamWeightA = teamWeightA + entityA:GetAbility()
        teamWeightB = teamWeightB + entityB:GetAbility()
        if teamWeightA == teamWeightB then
            return entityA:GetId() > entityB:GetId()
        else
            return teamWeightA > teamWeightB
        end
    end)
    return entities
end

function XUiTheatreBattleRoomRoleDetail:GetGridProxy()
    return XUiTheatreRoleGrid
end

return XUiTheatreBattleRoomRoleDetail