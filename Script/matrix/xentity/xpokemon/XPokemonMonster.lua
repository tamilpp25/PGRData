local XPokemonMonsterSkillGroup = require("XEntity/XPokemon/XPokemonMonsterSkillGroup")

local type = type
local pairs = pairs
local ipairs = ipairs
local tableInsert = table.insert
local MonsterType = XPokemonConfigs.MonsterType
local FixToInt = FixToInt

local Default = {
    _Id = 0,
    _Level = 0,
    _Star = 0,
    _CreateTime = 0,
    _Ability = 0, --战力
    _SkillGroupIdList = {},
    _SkillGroupDic = {},
    _Attribute = {},
}

local XPokemonMonster = XClass(nil, "XPokemonMonster")

function XPokemonMonster:Ctor(monsterId)
    for key, value in pairs(Default) do
        if type(value) == "table" then
            self[key] = {}
        else
            self[key] = value
        end
    end

    self._Id = monsterId
    self:InitSkillGroups()

    XEventManager.AddEventListener(XEventId.EVENT_ATTRIBUTE_MANAGER_INIT, handler(self, self.DelayUpdateAttribute))
end

function XPokemonMonster:UpdateData(data)
    if not data then return end

    self._CreateTime = data.CreateTime

    self:UpdateStar(data.Star)
    self:UpdateLevel(data.Level)
    self:UpdateUsingSkills(data.SkillIdList)
end

----------------------------------------------等级/星级相关 begin--------------------------------
function XPokemonMonster:GetStar()
    return self._Star
end

function XPokemonMonster:IsMaxStar()
    return self._Star == XPokemonConfigs.GetMonsterStarMaxStar(self._Id)
end

function XPokemonMonster:UpStar(addStar)
    local newStar = self._Star + addStar
    self:UpdateStar(newStar)
end

function XPokemonMonster:UpdateStar(star)
    if not star then return end

    self._Star = star
    self:TryUnlockSkills()
end

function XPokemonMonster:GetLevel()
    return self._Level
end

function XPokemonMonster:GetMaxLevel()
    return XPokemonConfigs.GetMonsterStarMaxLevel(self._Id, self._Star)
end

function XPokemonMonster:IsMaxLevel()
    return self._Level == self:GetMaxLevel()
end

function XPokemonMonster:UpLevel(addLevel)
    local newLevel = self._Level + addLevel
    self:UpdateLevel(newLevel)
end

function XPokemonMonster:UpdateLevel(level)
    if not level then return end

    self._Level = level
    self:UpdateAttribute()
end

function XPokemonMonster:GetLevelUpCostItemInfo()
    if self:IsMaxLevel() then return 0, 0 end
    return XPokemonConfigs.GetMonsterLevelCostItemInfo(self._Id, self._Level)
end

function XPokemonMonster:GetStarUpCostItemInfo()
    if self:IsMaxStar() then return 0, 0 end
    return XPokemonConfigs.GetMonsterStarCostItemInfo(self._Id, self._Star)
end
----------------------------------------------等级/星级相关 end--------------------------------
----------------------------------------------属性相关 begin--------------------------------
local _WaitForUpdateAttr--属性表加载慢于属性同步接口，延迟更新
function XPokemonMonster:DelayUpdateAttribute()
    if not _WaitForUpdateAttr then
        return
    end

    self:UpdateAttribute()
    _WaitForUpdateAttr = nil
end

function XPokemonMonster:UpdateAttribute()
    if not XAttribManager.IsInited() then
        _WaitForUpdateAttr = true
        return
    end

    local monsterId = self._Id
    local npcId = XPokemonConfigs.GetMonsterNpcId(monsterId)

    self._Attribute = XAttribManager.GetNpcBaseAttribsByNpcIdWithReviseId(npcId, self._Level)
    self:UpdateAbility()
end

function XPokemonMonster:UpdateAbility()
    local rateMonster, rateHp, rateAttack = XPokemonConfigs.GetMonsterAbilityRate(self._Id)
    self._Ability = XMath.ToMinInt(rateMonster + self:GetHp() * rateHp + self:GetAttack() * rateAttack)
end

function XPokemonMonster:GetAbility()
    return self._Ability
end

function XPokemonMonster:GetHp()
    return FixToInt(self._Attribute[XNpcAttribType.Life])
end

function XPokemonMonster:GetAttack()
    return FixToInt(self._Attribute[XNpcAttribType.AttackNormal])
end

function XPokemonMonster:GetPreHpAndPreAttack(preLevel)
    local maxLevel = self:GetMaxLevel()
    preLevel = preLevel < maxLevel and preLevel or maxLevel
    local npcId = XPokemonConfigs.GetMonsterNpcId(self._Id)
    local attribute = XAttribManager.GetNpcBaseAttribsByNpcIdWithReviseId(npcId, preLevel)
    return FixToInt(attribute[XNpcAttribType.Life]), FixToInt(attribute[XNpcAttribType.AttackNormal])
end
----------------------------------------------属性相关 end--------------------------------
----------------------------------------------技能相关 begin--------------------------------
function XPokemonMonster:InitSkillGroups()
    local monsterId = self._Id
    local skillIds = XPokemonConfigs.GetMonsterSkillIds(monsterId)
    self._SkillGroupDic = {}
    self._SkillGroupIdList = {}
    for _, skillId in pairs(skillIds) do
        local skillGroupId = XPokemonConfigs.GetMonsterSkillGroupId(skillId)

        local skillGroup = self._SkillGroupDic[skillGroupId]
        if not skillGroup then
            skillGroup = XPokemonMonsterSkillGroup.New(skillGroupId)
            self._SkillGroupDic[skillGroupId] = skillGroup

            tableInsert(self._SkillGroupIdList, skillGroupId)
        end
        skillGroup:InitSkill(skillId)
    end
end

function XPokemonMonster:GetSkillGroup(skillGroupId)
    local skillGroup = self._SkillGroupDic[skillGroupId]
    if not skillGroup then
        XLog.Error("XPokemonMonster:GetSkillGroup error: 口袋妖怪怪物技能组获取失败, skillGroupId: " .. skillGroupId .. "monsterId: " .. self._Id)
        return
    end
    return skillGroup
end

function XPokemonMonster:GetUsingSkillIdList()
    local skillIds = {}

    for _, skillGroupId in ipairs(self._SkillGroupIdList) do
        local skillGroup = self:GetSkillGroup(skillGroupId)
        local skillId = skillGroup:GetUsingSkillId()
        if skillId > 0 then
            tableInsert(skillIds, skillId)
        end
    end

    return skillIds
end

function XPokemonMonster:GetCanSwitchSkillIds(skillId)
    local skillGroup = self:GetSkillGroupBySkillId(skillId)
    return skillGroup:GetSkillIds()
end

function XPokemonMonster:GetSkillGroupBySkillId(skillId)
    local skillGroupId = XPokemonConfigs.GetMonsterSkillGroupId(skillId)
    return self:GetSkillGroup(skillGroupId)
end

--设置使用中的技能
function XPokemonMonster:UpdateUsingSkills(usingSkillIds)
    if usingSkillIds then
        for _, skillId in pairs(usingSkillIds) do
            self:SwitchSkill(skillId)
        end
    end
end

function XPokemonMonster:IsSkillUsing(skillId)
    local skillGroup = self:GetSkillGroupBySkillId(skillId)
    return skillGroup:IsSkillUsing(skillId)
end

function XPokemonMonster:IsSkillUnlock(skillId)
    local skillGroup = self:GetSkillGroupBySkillId(skillId)
    return skillGroup:IsSkillUnlock(skillId)
end

function XPokemonMonster:IsSkillCanSwitch(skillId)
    local skillGroup = self:GetSkillGroupBySkillId(skillId)
    return skillGroup:IsSkillCanSwitch()
end

function XPokemonMonster:SwitchSkill(skillId)
    local skillGroup = self:GetSkillGroupBySkillId(skillId)
    skillGroup:SwitchSkill(skillId)
end

--获取该星级可解锁技能Id列表
function XPokemonMonster:GetStarUnlockSkillIds(star)
    local unlockSkillIds = {}
    for _, skillGroup in pairs(self._SkillGroupDic) do
        local skillIds = skillGroup:GetSkillIds()

        for _, skillId in pairs(skillIds) do
            local unlockStar = XPokemonConfigs.GetMonsterSkillUnlockStar(skillId)
            if unlockStar == star then
                tableInsert(unlockSkillIds, skillId)
            end
        end
    end
    return unlockSkillIds
end

--根据星级解锁所有技能
function XPokemonMonster:TryUnlockSkills()
    for _, skillGroup in pairs(self._SkillGroupDic) do
        local skillIds = skillGroup:GetSkillIds()
        for _, skillId in pairs(skillIds) do
            self:TryUnlockSkill(skillId)
        end
    end
end

function XPokemonMonster:IsSkillCanUnlock(skillId)
    local unlockStar = XPokemonConfigs.GetMonsterSkillUnlockStar(skillId)
    return self._Star >= unlockStar
end

function XPokemonMonster:TryUnlockSkill(skillId)
    if not self:IsSkillCanUnlock(skillId) then return end

    local skillGroup = self:GetSkillGroupBySkillId(skillId)
    skillGroup:UnlockSkill(skillId)
end
----------------------------------------------技能相关 end--------------------------------
return XPokemonMonster