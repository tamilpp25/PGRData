local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
---@class XUiTheatre4BattleRoleRoom : XUiBattleRoleRoomDefaultProxy
local XUiTheatre4BattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiTheatre4BattleRoleRoom")

---@param team XTheatre4Team
function XUiTheatre4BattleRoleRoom:Ctor(team, stageId)
    self.Team = team
    self.StageId = stageId
end

function XUiTheatre4BattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiTheatre4/BattleRoom/XUiTheatre4BattleRoomRoleDetail")
end

---@param team XTheatre4Team
function XUiTheatre4BattleRoleRoom:EnterFight(team, stageId, challengeCount, isAssist)
    XMVCA.XTheatre4:EnterFight(stageId, team:GetId(), isAssist, challengeCount)
end

function XUiTheatre4BattleRoleRoom:AOPOnClickFight()
    return false
end

---@param rootUi XUiBattleRoleRoom
function XUiTheatre4BattleRoleRoom:AOPOnStartAfter(rootUi)
    rootUi.BtnTeamPrefab.gameObject:SetActiveEx(false)
end

return XUiTheatre4BattleRoleRoom
