-- 三头犬玩法【队伍】实例（机器人也能记录进队伍信息）
---@type XTeam XTeam
local XTeam = require("XEntity/XTeam/XTeam")
---@class XCerberusGameTeam:XTeam XCerberusGameTeam
local XCerberusGameTeam = XClass(XTeam, "XCerberusGameTeam")

function XCerberusGameTeam:GetSaveKey()
    return self.Id .."XCerberusGameTeam".. XPlayer.Id
end

function XCerberusGameTeam:LoadTeamData()
end

function XCerberusGameTeam:CheckIsPosEmpty(pos)
    local entityId = self:GetEntityIdByTeamPos(pos)
    return not XTool.IsNumberValid(entityId)
end

function XCerberusGameTeam:RefreshDataByCerberuseTeamInfo(teamInfo)
    if XTool.IsTableEmpty(teamInfo) then
        return
    end

    local roleIds = {0, 0, 0}
    for k, id in pairs(teamInfo.CharacterIdList) do
        if XTool.IsNumberValid(id) then
            roleIds[k] = id
        end
    end
    for k, id in pairs(teamInfo.RobotIdList) do
        if XTool.IsNumberValid(id) then
            roleIds[k] = id
        end
    end
    self:UpdateEntityIds(roleIds)
    self:UpdateCaptainPos(teamInfo.CaptainPos)
    self:UpdateFirstFightPos(teamInfo.FirstFightPos)
end

return XCerberusGameTeam