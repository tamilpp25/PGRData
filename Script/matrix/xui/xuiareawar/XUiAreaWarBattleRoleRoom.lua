
---@class XUiAreaWarBattleRoleRoom : XUiBattleRoleRoomDefaultProxy
---@field Team XTeam
---@field StageId number
local XUiAreaWarBattleRoleRoom = XClass(require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy"), "XUiAreaWarBattleRoleRoom")

function XUiAreaWarBattleRoleRoom:Ctor(team, stateId)
    self.Team = team
    self.StageId = stateId
end

function XUiAreaWarBattleRoleRoom:GetAutoCloseInfo()
    return true, XDataCenter.AreaWarManager.GetEndTime(), function(isClose)
        if isClose then
            XDataCenter.AreaWarManager.OnActivityEnd()
        end
    end
end

function XUiAreaWarBattleRoleRoom:GetRoleDetailProxy()
    if self.DetailProxy then
        return self.DetailProxy
    end
    self.DetailProxy = require("XUi/XUiAreaWar/XUiAreaWarBattleRoomRoleDetail")
    return self.DetailProxy
end

--- 进入战斗
---@param team XTeam
---@return
--------------------------
function XUiAreaWarBattleRoleRoom:EnterFight(team, stageId, challengeCount, isAssist)
    if not XDataCenter.AreaWarManager.CheckBeforeEnterFight(stageId) then
        return
    end
    
    if not XTool.IsNumberValid(team:GetCaptainPosEntityId()) then
        XUiManager.TipText("TeamManagerCheckCaptainNil")
        return
    end

    if not XTool.IsNumberValid(team:GetFirstFightPosEntityId()) then
        XUiManager.TipText("TeamManagerCheckFirstFightNil")
    end
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
    
    XDataCenter.FubenManager.EnterFight(stageConfig, team:GetId(), isAssist, challengeCount)
end

return XUiAreaWarBattleRoleRoom