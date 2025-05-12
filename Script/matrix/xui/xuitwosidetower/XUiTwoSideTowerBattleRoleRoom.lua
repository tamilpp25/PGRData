local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
---@class XUiTwoSideTowerBattleRoleRoom : XUiBattleRoleRoomDefaultProxy
local XUiTwoSideTowerBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy, "XUiTwoSideTowerBattleRoleRoom")

---@param team XTeam
function XUiTwoSideTowerBattleRoleRoom:Ctor(team, stageId)
    self.Team = team
    self.StageId = stageId
end

function XUiTwoSideTowerBattleRoleRoom:GetAutoCloseInfo()
    ---@type XTwoSideTowerAgency
    local twoSideTowerAgency = XMVCA:GetAgency(ModuleId.XTwoSideTower)
    local endTime = twoSideTowerAgency:GetActivityEndTime()
    return true, endTime, function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipText("ActivityAlreadyOver")
        end
    end
end

function XUiTwoSideTowerBattleRoleRoom:GetRoleDetailProxy()
    return require("XUi/XUiTwoSideTower/XUiTwoSideTowerBattleRoomRoleDetail")
end

---@param team XTeam
function XUiTwoSideTowerBattleRoleRoom:EnterFight(team, stageId, challengeCount, isAssist)
    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    fubenAgency:EnterFightByStageId(stageId, team:GetId(), isAssist, challengeCount)
end

function XUiTwoSideTowerBattleRoleRoom:AOPRefreshFightControlStateBefore(rootUi)
    return true
end

return XUiTwoSideTowerBattleRoleRoom
