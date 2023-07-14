--######################## XUiReformBattleRoomRoleDetail ########################
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiReformBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiReformBattleRoomRoleDetail")

-- team : XTeam
function XUiReformBattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
    self.ReformActivityManager = XDataCenter.ReformActivityManager
    self.BaseStage = self.ReformActivityManager.GetBaseStage(self.StageId)
    self.EvolableStage = self.BaseStage:GetCurrentEvolvableStage()
    self.MemberGroup = self.EvolableStage:GetEvolvableGroupByType(XReformConfigs.EvolvableGroupType.Member)
end

-- characterType : XCharacterConfigs.CharacterType
function XUiReformBattleRoomRoleDetail:GetEntities(characterType)
    if characterType == XCharacterConfigs.CharacterType.Isomer then
        return {}
    end
    --[[
        同时满足参战的源和本地拥有同样的源角色的角色
    ]]
    local sources = self.MemberGroup:GetAllCanJoinTeamSources()
    local characterId, character, source
    for i = #sources, 1, -1 do
        source = sources[i]
        characterId = source:GetCharacterId()
        character = XDataCenter.CharacterManager.GetCharacter(characterId)
        if character then
            table.insert(sources, character)
        end
    end
    return sources
end

function XUiReformBattleRoomRoleDetail:GetCharacterViewModelByEntityId(entityId)
    local source = self.MemberGroup:GetSourceById(entityId)
    local reuslt = nil
    if source then
        reuslt = source:GetCharacterViewModel()
    elseif entityId > 0 then
        reuslt = XDataCenter.CharacterManager.GetCharacter(entityId):GetCharacterViewModel()
    end
    return reuslt
end

function XUiReformBattleRoomRoleDetail:GetCharacterType(entityId)
    return XCharacterConfigs.CharacterType.Normal
end

function XUiReformBattleRoomRoleDetail:CheckTeamHasSameCharacterId(team, checkEntityId)
    local checkCharacterId = self:GetCharacterIdByEntityId(checkEntityId)
    for pos, entityId in pairs(team:GetEntityIds()) do
        if self:GetCharacterIdByEntityId(entityId) == checkCharacterId then
            return pos ~= self.Pos
        end
    end
    return false
end

function XUiReformBattleRoomRoleDetail:SortEntitiesWithTeam(team, entities, sortTagType)
    table.sort(entities, function(entityA, entityB)
        local _, posA = team:GetEntityIdIsInTeam(entityA:GetId())
        local _, posB = team:GetEntityIdIsInTeam(entityB:GetId())
        local teamWeightA = posA ~= -1 and (10 - posA) * 1000000000 or 0
        local teamWeightB = posB ~= -1 and (10 - posB) * 1000000000 or 0
        local abilityA = entityA:GetCharacterViewModel():GetAbility() * 10
        local abilityB = entityB:GetCharacterViewModel():GetAbility() * 10
        local weightA = teamWeightA + abilityA + entityA:GetId() / 1000
        local weightB = teamWeightB + abilityB + entityB:GetId() / 1000
        return weightA > weightB
    end)
    return entities
end

function XUiReformBattleRoomRoleDetail:GetAutoCloseInfo()
    local endTime = self.ReformActivityManager.GetActivityEndTime()
    return true, endTime, function(isClose)
        if isClose then
            self.ReformActivityManager.HandleActivityEndTime()
        end
    end
end

function XUiReformBattleRoomRoleDetail:AOPOnStartBefore(rootUi)
    rootUi.BtnFilter.gameObject:SetActiveEx(false)
    rootUi.BtnGroupCharacterType.gameObject:SetActiveEx(false)
end

-- function XUiReformBattleRoomRoleDetail:GetChildPanelData()
--     if self.ChildPanelData == nil then
--         self.ChildPanelData = {
--             assetPath = "Assets/Product/Ui/Prefab/UiReformBtnEquipment.prefab", --XUiConfigs.GetComponentUrl("UiSuperTowerBattleRoomRoleDetail"),
--             proxy = UiReformBtnEquipment,
--             proxyArgs = { "StageId" }
--         }
--     end
--     return self.ChildPanelData
-- end

-- function XUiReformBattleRoomRoleDetail:GetGridProxy()
--     return XUiReformRoleGrid
-- end

--######################## 私有方法 ########################

function XUiReformBattleRoomRoleDetail:GetCharacterIdByEntityId(entityId)
    local result = entityId
    local source = self.MemberGroup:GetSourceById(entityId)
    if source then
        result = source:GetCharacterViewModel():GetId()
    end
    return result
end

return XUiReformBattleRoomRoleDetail