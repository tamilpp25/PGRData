local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
---@class XUiMainLine2BattleRoleRoom : XUiBattleRoleRoomDefaultProxy
local XUiMainLine2BattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiMainLine2BattleRoleRoom")

---@param team XTeam
function XUiMainLine2BattleRoleRoom:Ctor(team, stageId)
    self.Team = team
    self.StageId = stageId
end

---@param team XTeam
function XUiMainLine2BattleRoleRoom:EnterFight(team, stageId, challengeCount, isAssist)
    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    fubenAgency:EnterFightByStageId(self.StageId, self.Team:GetId())
end

function XUiMainLine2BattleRoleRoom:CheckStageRobotIsUseCustomProxy(robotIds)
    return true
end

return XUiMainLine2BattleRoleRoom
