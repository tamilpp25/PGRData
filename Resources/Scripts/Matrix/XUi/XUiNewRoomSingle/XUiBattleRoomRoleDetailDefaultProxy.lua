local XUiBattleRoomRoleDetailDefaultProxy = XClass(nil, "XUiBattleRoomRoleDetailDefaultProxy")

-- characterType : XCharacterConfigs.CharacterType
function XUiBattleRoomRoleDetailDefaultProxy:GetEntities(characterType)
    return {}
end

function XUiBattleRoomRoleDetailDefaultProxy:GetFilterJudge()
    return function()
        return false
    end
end

function XUiBattleRoomRoleDetailDefaultProxy:GetEntityIndexById(entityId)
    if entityId == nil or entityId == 0 then return 1 end
    for i, v in ipairs(self:GetEntities()) do
        if v:GetId() == entityId then
            return i
        end
    end
    return 1
end

function XUiBattleRoomRoleDetailDefaultProxy:GetGridProxy()
    return nil
end

function XUiBattleRoomRoleDetailDefaultProxy:GetChildPanelData()
    return nil
end

function XUiBattleRoomRoleDetailDefaultProxy:GetCharacterViewModelByEntityId(entityId)
    return nil
end

function XUiBattleRoomRoleDetailDefaultProxy:GetCharacterType(entityId)
    return XCharacterConfigs.GetCharacterType(XEntityHelper.GetCharacterIdByEntityId(entityId))
end

function XUiBattleRoomRoleDetailDefaultProxy:CheckTeamHasSameCharacterId(team, checkEntityId)
    local checkCharacterId = XEntityHelper.GetCharacterIdByEntityId(checkEntityId)
    for _, entityId in pairs(team:GetEntityIds()) do
        if XEntityHelper.GetCharacterIdByEntityId(entityId) == checkCharacterId then
            return true
        end
    end
    return false
end

-- team : XTeam
-- sortTagType : XRoomCharFilterTipsConfigs.EnumSortTag
function XUiBattleRoomRoleDetailDefaultProxy:SortEntitiesWithTeam(team, entities, sortTagType)
    table.sort(entities, function(entityA, entityB)
        local _, posA = team:GetEntityIdIsInTeam(entityA:GetId())
        local _, posB = team:GetEntityIdIsInTeam(entityB:GetId())
        local teamWeightA = posA ~= -1 and (10 - posA) * 1000 or 0
        local teamWeightB = posB ~= -1 and (10 - posB) * 1000 or 0
        if teamWeightA == teamWeightB then
            return entityA:GetId() > entityB:GetId()
        else
            return teamWeightA > teamWeightB
        end
    end)
    return entities
end

function XUiBattleRoomRoleDetailDefaultProxy:GetAutoCloseInfo()
    return false
end

function XUiBattleRoomRoleDetailDefaultProxy:GetRoleDynamicGrid()
    
end

-- return { [XRoomCharFilterTipsConfigs.EnumSortTag.xxx] = true } 即为隐藏
function XUiBattleRoomRoleDetailDefaultProxy:GetHideSortTagDic()
    return nil
end

--######################## AOP ########################

function XUiBattleRoomRoleDetailDefaultProxy:AOPOnStartBefore(rootUi)
    
end

function XUiBattleRoomRoleDetailDefaultProxy:AOPOnStartAfter(rootUi)
    
end

function XUiBattleRoomRoleDetailDefaultProxy:AOPOnBtnJoinTeamClickedBefore(rootUi)

end

function XUiBattleRoomRoleDetailDefaultProxy:AOPOnBtnJoinTeamClickedAfter(rootUi)
    
end

return XUiBattleRoomRoleDetailDefaultProxy