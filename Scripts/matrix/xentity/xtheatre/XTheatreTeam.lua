local XTeam = require("XEntity/XTeam/XTeam")
local XTheatreTeam = XClass(XTeam, "XTheatreTeam")

-- 获取当前队伍的角色类型
function XTheatreTeam:GetCharacterType()
    if self.CustomCharacterType then
        return self.CustomCharacterType
    end
    local entityId = nil
    for _, value in pairs(self.EntitiyIds) do
        if value > 0 then
            entityId = value
            break
        end
    end
    if entityId == nil then
        return XCharacterConfigs.CharacterType.Normal
    end
    local role = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetRole(entityId)
    if role == nil then return XCharacterConfigs.CharacterType.Normal end
    return role:GetCharacterViewModel():GetCharacterType()
end

--获得队伍队长技描述
function XTheatreTeam:GetCaptainSkillDesc()
    local entityId = self:GetCaptainPosEntityId()
    if not XTool.IsNumberValid(entityId) then
        return ""
    end

    local currRoles = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetCurrentRoles(true)
    local role = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetRole(entityId)
    if not role then
        return ""
    end

    local rawId = role:GetRawDataId()
    return role:GetIsLocalRole() and XDataCenter.CharacterManager.GetCaptainSkillDesc(rawId) or XRobotManager.GetRobotCaptainSkillDesc(rawId)
end

function XTheatreTeam:GetCharacterAndRobotIds()
    local entityIds = {}
    for _, adventureRoleId in pairs(self.EntitiyIds) do
        if XTool.IsNumberValid(adventureRoleId) then
            local role = XDataCenter.TheatreManager.GetCurrentAdventureManager():GetRole(adventureRoleId)
            local rawId = role:GetRawDataId()
            table.insert(entityIds, rawId)
        else
            table.insert(entityIds, adventureRoleId)
        end
    end
    return entityIds
end

--设置多队伍的队伍下标
function XTheatreTeam:SetTeamIndex(teamIndex)
    self.TeamIndex = teamIndex
end

function XTheatreTeam:GetTeamIndex()
    return self.TeamIndex
end

return XTheatreTeam