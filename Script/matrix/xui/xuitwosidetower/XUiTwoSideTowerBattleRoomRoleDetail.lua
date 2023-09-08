local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")

---@class XUiTwoSideTowerBattleRoomRoleDetail : XUiBattleRoomRoleDetailDefaultProxy
local XUiTwoSideTowerBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiTwoSideTowerBattleRoomRoleDetail")

---@param team XTeam
function XUiTwoSideTowerBattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
end

function XUiTwoSideTowerBattleRoomRoleDetail:GetEntities(characterType)
    ---@type XTwoSideTowerAgency
    local twoSideTowerAgency = XMVCA:GetAgency(ModuleId.XTwoSideTower)
    local robotIds = twoSideTowerAgency:GetRobotIds()
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    local roleIds = characterAgency:GetRobotAndCharacterIdList(robotIds, characterType)
    return XEntityHelper.GetEntityByIds(roleIds)
end

function XUiTwoSideTowerBattleRoomRoleDetail:GetAutoCloseInfo()
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

function XUiTwoSideTowerBattleRoomRoleDetail:GetFilterControllerConfig()
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    return characterAgency:GetModelCharacterFilterController()["UiTwoSideTowerBattle"]
end

return XUiTwoSideTowerBattleRoomRoleDetail
