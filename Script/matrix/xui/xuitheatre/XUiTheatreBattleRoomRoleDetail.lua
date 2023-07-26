--######################## XUiTheatreRoleGrid ########################
local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
---@class XUiTheatreRoleGrid:XUiBattleRoomRoleGrid
---@field Super XUiBattleRoomRoleGrid
local XUiTheatreRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiTheatreRoleGrid")

---@param entity XTheatreAdventureRole
function XUiTheatreRoleGrid:SetData(entity)
    self.Super.SetData(self, entity)
    if not entity:GetIsLocalRole() then
        self.TxtLevel.text = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetCurrentLevel()

        self.TxtFight.gameObject:SetActiveEx(true)
        self.TxtFight.text = entity:GetAbility()
    end
end

function XUiTheatreRoleGrid:UpdateFight()
    if self.IsFragment then
        self.PanelFight.gameObject:SetActiveEx(false)
        return
    end

    self.TxtFight.gameObject:SetActiveEx(true)
    self.TxtLevel.text = self.Character:GetCharacterViewModel():GetLevel()
    self.TxtFight.text = self.Character:GetCharacterViewModel():GetAbility()
    self.PanelFight.gameObject:SetActiveEx(true)
end

--######################## XUiTheatreBattleRoomRoleDetail ########################
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")

---@class XUiTheatreBattleRoomRoleDetail:XUiBattleRoomRoleDetailDefaultProxy
local XUiTheatreBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiTheatreBattleRoomRoleDetail")

function XUiTheatreBattleRoomRoleDetail:Ctor()
    self.TheatreManager = XDataCenter.TheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    self.Chapter = self.AdventureManager:GetCurrentChapter()
    self._IdDir = {}
end

function XUiTheatreBattleRoomRoleDetail:AOPOnBtnJoinTeamClickedAfter(ui)
    local id = self._IdDir[ui.CurrentEntityId] and self._IdDir[ui.CurrentEntityId] or ui.CurrentEntityId
    ui.Team:UpdateEntityTeamPos(id, ui.Pos, true)
end

-- characterType : XCharacterConfigs.CharacterType
function XUiTheatreBattleRoomRoleDetail:GetEntities(characterType)
    local roles = self.AdventureManager:GetCurrentRoles(true)
    for _, role in ipairs(roles) do
        if not role:GetIsLocalRole() then
            local robotId = role:GetRawData().Id
            self._IdDir[robotId] = role:GetId()
        end
    end
    return roles
end

function XUiTheatreBattleRoomRoleDetail:GetCharacterViewModelByEntityId(entityId)
    local role = self.AdventureManager:GetRoleByRobotId(entityId)
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

function XUiTheatreBattleRoomRoleDetail:GetFilterControllerConfig()
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    return characterAgency:GetModelCharacterFilterController()["UiTheatreBattleRoomDetail"]
end

return XUiTheatreBattleRoomRoleDetail