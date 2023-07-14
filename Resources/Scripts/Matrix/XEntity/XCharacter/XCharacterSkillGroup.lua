local Default = {
    __SkillGroupId = 0,
    __Level = 0,
    __CurSkillId = 0,
}

local XCharacterSkillGroup = XClass(nil, "XCharacterSkillGroup")

function XCharacterSkillGroup:Ctor(skillGroupId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self.__SkillGroupId = skillGroupId
end

function XCharacterSkillGroup:UpdateData(data)
    self.__CurSkillId = data.Id
    self.__Level = data.Level or 0
end

function XCharacterSkillGroup:GetLevel()
    return self.__Level
end

function XCharacterSkillGroup:SwitchSkill(skillId)
    self.__CurSkillId = skillId
end

function XCharacterSkillGroup:GetCurSKillId()
    return self.__CurSkillId
end

return XCharacterSkillGroup