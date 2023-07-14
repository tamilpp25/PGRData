local XAssignMember = XClass(nil, "XAssignMember")

function XAssignMember:Ctor(index)
    self.Index = index -- 队伍位置
    self.CharacterId = nil
end

function XAssignMember:GetIndex() return self.Index end

function XAssignMember:GetCharacterId() return self.CharacterId or 0 end

function XAssignMember:HasCharacter() return (self.CharacterId and self.CharacterId ~= 0) end

function XAssignMember:SetCharacterId(characterId)
    self.CharacterId = characterId
end

function XAssignMember:GetCharacterAbility()
    return self:HasCharacter() and XDataCenter.CharacterManager.GetCharacterAbilityById(self.CharacterId) or 0
end

function XAssignMember:GetCharacterSkillInfo()
    return self:HasCharacter() and XDataCenter.CharacterManager.GetCaptainSkillInfo(self.CharacterId) or nil
end

function XAssignMember:GetCharacterType()
    return self:HasCharacter() and XCharacterConfigs.GetCharacterType(self.CharacterId)
end

return XAssignMember