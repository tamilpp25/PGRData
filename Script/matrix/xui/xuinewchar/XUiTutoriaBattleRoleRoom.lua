local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")

---@class XUiTutoriaBattleRoleRoom:XUiBattleRoleRoomDefaultProxy
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

-- 获取编队能取到的所有实体的Id，用于检查当前队伍是否有超出可选以外的实体id
-- 传参：pos字段正常情况下根据玩家点击角色位置产生，提前生成时无法确认pos具体值，因此不传递该值，仅传递stageId与team
-- 返回空表默认不做剔除检查
---@return table<number>
---@overload
function XUiTutoriaBattleRoleRoom:GetValidEntityIdList(stageId, team)
    local actId = XDataCenter.FubenNewCharActivityManager.GetCurOpenActivityId()
    if XTool.IsNumberValid(actId) then
        ---@type XTableTeachingActivity
        local cfg = XFubenNewCharConfig.GetDataById(actId)
        if table.contains(cfg.ChallengeStage, stageId) then
            return self.Super.GetValidEntityIdList(self, stageId, team)
        end
    end
    -- 试玩关教学屏蔽队伍自动剔除检查
    return nil
end

function XUiTutoriaBattleRoleRoom:GetRoleDetailProxy()
    return {
        GetEntities = function(proxy, characterType)
            local robotIds = XDataCenter.FubenNewCharActivityManager.GetCharacterList(self.StageId)
            if not XTool.IsTableEmpty(robotIds) then
                return XEntityHelper.GetEntityByIds(XMVCA.XCharacter:GetRobotAndCharacterIdList(robotIds, characterType)) 
            end
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
            return XTool.IsNumberValid(defaultCharacterType) and defaultCharacterType or XEnumConst.CHARACTER.CharacterType.Normal 
        end,
        GetFilterControllerConfig = function()
            ---@type XCharacterAgency
            local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
            return characterAgency:GetModelCharacterFilterController()["UiFunbenKoroTutoriaTeachingDetail"]
        end
    }
end

function XUiTutoriaBattleRoleRoom:AOPRefreshFightControlStateBefore(rootUi)
    return true
end

function XUiTutoriaBattleRoleRoom:CheckShowAnimationSet()
    return false
end

function XUiBattleRoleRoomDefaultProxy:CheckStageRobotIsUseCustomProxy(robotIds)
    return true
end

return XUiTutoriaBattleRoleRoom