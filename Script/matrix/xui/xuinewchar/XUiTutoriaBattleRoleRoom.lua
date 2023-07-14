local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiTutoriaBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiTutoriaBattleRoleRoom")

function XUiTutoriaBattleRoleRoom:Ctor(team, stageId)
    self.StageId = stageId
end

function XUiTutoriaBattleRoleRoom:OnNotify(evt, ...)
    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(XUiHelper.GetText("ActivityMainLineEnd"))
    end
end

function XUiTutoriaBattleRoleRoom:GetRoleDetailProxy()
    return {
        GetEntities = function(proxy, characterType)
            local robotIds = XDataCenter.FubenNewCharActivityManager.GetCharacterList(self.StageId)
            return XEntityHelper.GetEntityByIds(XDataCenter.CharacterManager.GetRobotAndCharacterIdList(robotIds, characterType))
        end,
        SortEntitiesWithTeam = function(proxy, team, entities, sortTagType)
            table.sort(entities, function(entityA, entityB)
                local _, posA = team:GetEntityIdIsInTeam(entityA:GetId())
                local _, posB = team:GetEntityIdIsInTeam(entityB:GetId())
                local teamWeightA = posA ~= -1 and (10 - posA) * 1000000 or 0
                local teamWeightB = posB ~= -1 and (10 - posB) * 1000000 or 0
                teamWeightA = teamWeightA + (XEntityHelper.GetIsRobot(entityA:GetId()) and 2000000 or 0)
                teamWeightB = teamWeightB + (XEntityHelper.GetIsRobot(entityB:GetId()) and 2000000 or 0)
                teamWeightA = teamWeightA + proxy:GetCharacterViewModelByEntityId(entityA:GetId()):GetAbility()
                teamWeightB = teamWeightB + proxy:GetCharacterViewModelByEntityId(entityB:GetId()):GetAbility()
                if teamWeightA == teamWeightB then
                    return entityA:GetId() > entityB:GetId()
                else
                    return teamWeightA > teamWeightB
                end
            end)
            return entities
        end,
        GetDefaultCharacterType = function (proxy)
            local defaultCharacterType = XFubenNewCharConfig:GetTryCharacterCharacterType(self.StageId)
            return XTool.IsNumberValid(defaultCharacterType) and defaultCharacterType or XCharacterConfigs.CharacterType.Normal 
        end
    }
end

function XUiTutoriaBattleRoleRoom:AOPRefreshFightControlStateBefore(rootUi)
    return true
end

return XUiTutoriaBattleRoleRoom