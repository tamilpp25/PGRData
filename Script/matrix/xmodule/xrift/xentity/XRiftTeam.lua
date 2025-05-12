local XTeam = require("XEntity/XTeam/XTeam")

---@class XRiftTeam:XTeam 大秘境【队伍】实例（机器人也能记录进队伍信息），大秘境的队伍信息保存在本地
local XRiftTeam = XClass(XTeam, "XRiftTeam")

function XRiftTeam:GetSaveKey()
    return self.Id.."|PlayerId:"..XPlayer.Id.."RiftTeamFix1".."ActivtyId:".. XMVCA.XRift:GetCurrentConfig().Id
end

function XRiftTeam:CheckIsPosEmpty(pos)
    local entityId = self:GetEntityIdByTeamPos(pos)
    return not XTool.IsNumberValid(entityId)
end

function XRiftTeam:CheckHasSameCharacterIdButNotEntityId(entityId)
    local checkCharacterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    for pos, entityIdInTeam in pairs(self:GetEntityIds()) do
        if XEntityHelper.GetCharacterIdByEntityId(entityIdInTeam) == checkCharacterId and entityIdInTeam ~= entityId then
            return true, pos
        end
    end
    return false, -1
end

-- 返回真正的character列表
function XRiftTeam:GetShowCharacterIds()
    local result = {}
    for k, roleId in ipairs(self:GetEntityIds()) do
        if not self:CheckIsPosEmpty(k) then
            local xRole = XMVCA.XRift:GetEntityRoleById(roleId)
            table.insert(result, xRole:GetCharacterId())
        end
    end
    return result
end

function XRiftTeam:GetCaptainSkillDesc()
    local captainRoleId = self:GetCaptainPosEntityId()
    if not captainRoleId or captainRoleId <= 0 then
        return
    end

    local xRole = XMVCA.XRift:GetEntityRoleById(captainRoleId)
    return xRole:GetCaptainSkillDesc()
end

function XRiftTeam:SetAttrTemplateId(templateId)
    self.s_templateId = templateId
end

function XRiftTeam:GetAttrTemplateId()
    return self.s_templateId
end

function XRiftTeam:GetShowAttrTemplateId()
    local res = self.s_templateId or 1 
    local attr = XMVCA.XRift:GetAttrTemplate(res)
    if attr:IsEmpty() then
        res = 1
    end
    return res
end

function XRiftTeam:SetLuckyStage(bo)
    self.s_IsLuckyStage = bo
end

function XRiftTeam:IsLuckyStage()
    return self.s_IsLuckyStage
end

return XRiftTeam