local XPokemonMonsterSkill = require("XEntity/XPokemon/XPokemonMonsterSkill")

local type = type
local tableInsert = table.insert

local Default = {
    _Id = 0,
    _UsingSkillId = 0,
    _SkillIdList = {},
    _SkillDic = {},
}

local XPokemonMonsterSkillGroup = XClass(nil, "XPokemonMonsterSkillGroup")

function XPokemonMonsterSkillGroup:Ctor(id)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Id = id
end

function XPokemonMonsterSkillGroup:InitSkill(skillId)
    if self._SkillDic[skillId] then
        XLog.Error("XPokemonMonsterSkillGroup:InitSkill error: 口袋妖怪怪物技能配置重复, skillId: " .. skillId .. "skillGroupId: " .. self._Id)
        return
    end

    self._SkillDic[skillId] = XPokemonMonsterSkill.New(skillId)
    tableInsert(self._SkillIdList, skillId)
end

function XPokemonMonsterSkillGroup:GetSkill(skillId)
    local skill = self._SkillDic[skillId]
    if not skill then
        XLog.Error("XPokemonMonsterSkillGroup:GetSkill error: 口袋妖怪怪物技能获取失败, skillId: " .. skillId .. "skillGroupId: " .. self._Id)
        return
    end
    return skill
end

function XPokemonMonsterSkillGroup:GetSkillIds()
    return XTool.Clone(self._SkillIdList)
end

function XPokemonMonsterSkillGroup:GetUsingSkillId()
    return self._UsingSkillId
end

function XPokemonMonsterSkillGroup:IsSkillUnlock(skillId)
    local skill = self:GetSkill(skillId)
    return skill:IsUnlock()
end

function XPokemonMonsterSkillGroup:IsSkillUsing(skillId)
    return self._UsingSkillId == skillId
end

function XPokemonMonsterSkillGroup:UnlockSkill(skillId)
    local skill = self:GetSkill(skillId)
    skill:Unlock()

    --默认使用第一个解锁的技能
    if self:GetUsingSkillId() == 0 then
        self:SwitchSkill(skillId)
    end
end

function XPokemonMonsterSkillGroup:IsSkillCanSwitch()
    return #self._SkillIdList > 1
end

function XPokemonMonsterSkillGroup:SwitchSkill(skillId)
    if not self:IsSkillUnlock(skillId) then return end

    self._UsingSkillId = skillId
end

return XPokemonMonsterSkillGroup