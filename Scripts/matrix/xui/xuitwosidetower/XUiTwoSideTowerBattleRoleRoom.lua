local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
local XUiTwoSideTowerBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiTwoSideTowerBattleRoleRoom")

function XUiTwoSideTowerBattleRoleRoom:Ctor(team, stageId)
    self.StageId = stageId
end

function XUiTwoSideTowerBattleRoleRoom:OnNotify(evt, ...)
    if evt == XEventId.EVENT_ACTIVITY_ON_RESET then
        XLuaUiManager.RunMain()
        XUiManager.TipMsg(XUiHelper.GetText("ActivityMainLineEnd"))
    end
end

function XUiTwoSideTowerBattleRoleRoom:GetRoleDetailProxy()
    return {
        GetEntities = function(proxy, characterType)
            local robotIds = XDataCenter.TwoSideTowerManager.GetActivityRobotIds()
            return XEntityHelper.GetEntityByIds(XDataCenter.CharacterManager.GetRobotAndCharacterIdList(robotIds, characterType))
        end,
        SortEntitiesWithTeam = function(proxy, team, entities, sortTagType)
            table.sort(entities, function(entityA, entityB)
                local _, posA = team:GetEntityIdIsInTeam(entityA:GetId())
                local _, posB = team:GetEntityIdIsInTeam(entityB:GetId())
                local teamWeightA = posA ~= -1 and (10 - posA) * 1000000 or 0
                local teamWeightB = posB ~= -1 and (10 - posB) * 1000000 or 0
                teamWeightA = teamWeightA + proxy:GetCharacterViewModelByEntityId(entityA:GetId()):GetAbility() + 300000
                teamWeightB = teamWeightB + proxy:GetCharacterViewModelByEntityId(entityB:GetId()):GetAbility() + 300000
                if teamWeightA == teamWeightB then
                    local idA = XEntityHelper.GetIsRobot(entityA:GetId()) and 0 or 2000000
                    local idB = XEntityHelper.GetIsRobot(entityB:GetId()) and 0 or 2000000
                    idA = idA  + entityA:GetId()
                    idB = idB + entityB:GetId()
                    return idA > idB
                else
                    return teamWeightA > teamWeightB
                end
            end)
            return entities
        end
    }
end

function XUiTwoSideTowerBattleRoleRoom:AOPRefreshFightControlStateBefore(rootUi)
    return true
end

function XUiTwoSideTowerBattleRoleRoom:AOPOnStartAfter()
    self:StartTimer()
end

function XUiTwoSideTowerBattleRoleRoom:AOPOnEnableAfter()
    self:StopTimer()
end

function XUiTwoSideTowerBattleRoleRoom:StartTimer()
    self:StopTimer()
    self.Timer = XScheduleManager.ScheduleForever(function()
        local now = XTime.GetServerNowTimestamp()
        local endTime = XDataCenter.TwoSideTowerManager.GetEndTime()
        if now >= endTime then
            self:StopTimer()
            XUiManager.TipText("ActivityAlreadyOver")
            XLuaUiManager.RunMain()
        end
    end, XScheduleManager.SECOND)
end

function XUiTwoSideTowerBattleRoleRoom:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiTwoSideTowerBattleRoleRoom