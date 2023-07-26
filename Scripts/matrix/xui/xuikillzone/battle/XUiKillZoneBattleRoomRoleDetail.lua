local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
---@class XUiKillZoneBattleRoomRoleDetail : XUiBattleRoomRoleDetailDefaultProxy
local XUiKillZoneBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiKillZoneBattleRoomRoleDetail")

---@param team XTeam
function XUiKillZoneBattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
    self.Team = team
    self.Pos = pos
end

function XUiKillZoneBattleRoomRoleDetail:GetEntities(characterType)
    local roles = XDataCenter.CharacterManager.GetOwnCharacterList(characterType)
    local robotIdList = XKillZoneConfigs.GetStageRobotIds(self.StageId)
    -- 添加机器人
    if XTool.IsTableEmpty(robotIdList) then
        return roles
    end
    for _, robotId in pairs(robotIdList) do
        local entity = XRobotManager.GetRobotById(robotId)
        if entity then
            table.insert(roles, entity)
        end
    end
    return roles
end

function XUiKillZoneBattleRoomRoleDetail:GetAutoCloseInfo()
    local endTime = XDataCenter.KillZoneManager.GetEndTime()
    return true, endTime, function(isClose)
        if isClose then
            XDataCenter.KillZoneManager.OnActivityEnd()
        end
    end
end

return XUiKillZoneBattleRoomRoleDetail