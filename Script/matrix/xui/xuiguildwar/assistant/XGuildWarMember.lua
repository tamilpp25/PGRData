---@class XGuildWarMember
local XGuildWarMember = XClass(nil, "XGuildWarMember")

function XGuildWarMember:Ctor(data)
    self:SetEmpty()
    if data then
        self:SetData(data)
    end
end

function XGuildWarMember:SetEmpty()
    self.EntityId = 0
    self.PlayerId = 0
end

function XGuildWarMember:GetEntityId()
    return self.EntityId
end

function XGuildWarMember:GetPlayerId()
    return self.PlayerId
end

function XGuildWarMember:GetData()
    return {
        EntityId = self.EntityId,
        PlayerId = self.PlayerId
    }
end

function XGuildWarMember:SetData(data)
    self.EntityId = data.EntityId
    self.PlayerId = data.PlayerId
end

function XGuildWarMember:GetAbility()
    if self:IsEmpty() then
        return 0
    end

    local ability = 0
    if self:IsMyCharacter() then
        ability = XMVCA.XCharacter:GetCharacterAbilityById(self.EntityId)
    else
        ability = XDataCenter.GuildWarManager.GetAssistantCharacterAbility(self.EntityId, self.PlayerId)
    end

    return ability
end

function XGuildWarMember:IsMyCharacter()
    return self.PlayerId == XPlayer.Id
end

function XGuildWarMember:IsAssitant()
    return not self:IsMyCharacter() and not self:IsEmpty()
end

function XGuildWarMember:IsRobot()
    return false
end

function XGuildWarMember:IsEmpty()
    return not self.EntityId or self.EntityId == 0
end

function XGuildWarMember:Equals(data)
    return self.EntityId == data.EntityId
        and self.PlayerId == data.PlayerId
end

--获取模型
function XGuildWarMember:GetCharacterViewModel()
    if self:IsEmpty() then
        return false
    end
    if self:IsMyCharacter() then
        local character = XDataCenter.CharacterManager.GetCharacter(self.EntityId)
        return character and character:GetCharacterViewModel()
    end
    return XDataCenter.GuildWarManager.GetAssistantCharacterViewModel(self.EntityId, self.PlayerId)
end

--获取拍档(宠物/小机器人)
function XGuildWarMember:GetPartner()
    if self:IsEmpty() then
        return false
    end
    if self:IsMyCharacter() then
        local partner = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(self.EntityId)
        return partner and partner:GetTemplateId()
    end
    return XDataCenter.GuildWarManager.GetAssistantCharacterPartner(self.EntityId, self.PlayerId)
end

--获得队长技能描述
function XGuildWarMember:GetCaptainSkillDesc()
    if self:IsEmpty() then
        return ""
    end

    if self:IsAssitant() then
        return XDataCenter.CharacterManager.GetCaptainSkillDesc(self.EntityId, true)
    elseif self:IsRobot() then --复制黏贴过来的 现在用不上
        return XRobotManager.GetRobotCaptainSkillDesc(self._RobotId)
    else
        return XDataCenter.CharacterManager.GetCaptainSkillDesc(self.EntityId)
    end
end

--获取小头像
function XGuildWarMember:GetSmallHeadIcon()
    if self:IsEmpty() then
        return ""
    end

    if self:IsAssitant() then
        return XDataCenter.CharacterManager.GetCharSmallHeadIcon(self.EntityId, true)
    elseif self:IsRobot() then --复制黏贴过来的 现在用不上
        return XRobotManager.GetRobotSmallHeadIcon(self._RobotId)
    else
        return XDataCenter.CharacterManager.GetCharSmallHeadIcon(self.EntityId)
    end
end

--检查援助角色是否已经失效
function XGuildWarMember:CheckValid()
    if not self:IsEmpty() and not self:IsMyCharacter() then
        return XDataCenter.GuildWarManager.IsAssistantCharacterValid(self.EntityId, self.PlayerId)
    end
    return true
end

return XGuildWarMember
