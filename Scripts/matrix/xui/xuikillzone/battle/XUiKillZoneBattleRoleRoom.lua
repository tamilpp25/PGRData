local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
---@class XUiKillZoneBattleRoleRoom : XUiBattleRoleRoomDefaultProxy
local XUiKillZoneBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiKillZoneBattleRoleRoom")

---@param team XTeam
function XUiKillZoneBattleRoleRoom:Ctor(team, stageId)
    self.Team = team
    self.StageId = stageId
end

function XUiKillZoneBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiKillZone/Battle/XUiKillZoneBattleRoomRoleDetail")
end

function XUiKillZoneBattleRoleRoom:GetAutoCloseInfo()
    local endTime = XDataCenter.KillZoneManager.GetEndTime()
    return true, endTime, function(isClose)
        if isClose then
            XDataCenter.KillZoneManager.OnActivityEnd()
        end
    end
end

function XUiKillZoneBattleRoleRoom:GetTipDescs()
    return { XUiHelper.GetText("KillZoneTeamRoleLimitTip") }
end

function XUiKillZoneBattleRoleRoom:EnterFight(team, stageId, challengeCount, isAssist)
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
    XDataCenter.FubenManager.EnterFight(stageConfig, team:GetId(), isAssist, challengeCount)
end

function XUiKillZoneBattleRoleRoom:AOPOnStartAfter(rootUi)
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false) -- 隐藏队伍预设
end

function XUiKillZoneBattleRoleRoom:AOPOnCharacterClickBefore(rootUi, index)
    local entityId = rootUi.Team:GetEntityIdByTeamPos(index)
    local entityCount = rootUi.Team:GetEntityCount()
    -- 只能上阵一个角色
    if not XTool.IsNumberValid(entityId) and entityCount >= 1 then
        XUiManager.TipText("KillZoneTeamRoleLimitTip")
        return true
    end
    return false
end

function XUiKillZoneBattleRoleRoom:AOPOnClickFight(rootUi)
    local entityCount = rootUi.Team:GetEntityCount()
    if entityCount > 1 then
        XUiManager.TipText("KillZoneTeamRoleLimitTip")
        return true
    end
    return false
end

return XUiKillZoneBattleRoleRoom