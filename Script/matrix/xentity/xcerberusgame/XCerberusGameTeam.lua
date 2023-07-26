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

-- 检查自机和机器人是否有相同的角色id
function XCerberusGameTeam:CheckHasSameCharacterIdButNotEntityId(entityId)
    local checkCharacterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    for pos, entityIdInTeam in pairs(self:GetEntityIds()) do
        if XEntityHelper.GetCharacterIdByEntityId(entityIdInTeam) == checkCharacterId and entityIdInTeam ~= entityId then
            return true, pos
        end
    end
    return false, -1
end

return XCerberusGameTeam