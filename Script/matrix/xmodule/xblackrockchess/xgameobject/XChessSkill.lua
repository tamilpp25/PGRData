
--技能选中个数
local SkillSearchCount = {
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_ATTACK] = 3,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_SKILL1] = 5,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_SKILL2] = 9,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUNA_ATTACK] = 3,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUNA_SKILL2] = 5,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUNA_SKILL3] = 9,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUCIA_SKILL1] = 9,
}

local SkillDamageType = {
    Center2Around = 1, --中心伤害高，边缘伤害低
    ExtraRound = 2, --额外回合与常规回合伤害
    Master2Assist = 3, --主攻击与协助攻击
    Default = 4, --默认，全部同一个伤害（取第一个参数）
    MultiDamage = 5, --多段伤害
    Hypotenuse = 6, -- 对斜角造成的伤害与十字边不同
    Default2 = 7, --默认，全部同一个伤害（取第二个参数）
}

local SkillType2Damage = {
    --霰弹枪
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_ATTACK] = SkillDamageType.Center2Around,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_SKILL1] = SkillDamageType.Center2Around,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.SHOTGUN_SKILL2] = SkillDamageType.Center2Around,
    --小刀
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_ATTACK] = SkillDamageType.ExtraRound,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.KNIFE_SKILL2] = SkillDamageType.ExtraRound,
    --露娜
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUNA_ATTACK] = SkillDamageType.Master2Assist,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUNA_SKILL1] = SkillDamageType.MultiDamage,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUNA_SKILL2] = SkillDamageType.Master2Assist,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUNA_SKILL3] = SkillDamageType.Default,
    --露西亚
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUCIA_ATTACK] = SkillDamageType.ExtraRound,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUCIA_SKILL1] = SkillDamageType.ExtraRound,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUCIA_SKILL2] = SkillDamageType.ExtraRound,
    --薇拉
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_ATTACK] = SkillDamageType.Hypotenuse,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL1] = SkillDamageType.Default,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_RED_SKILL1] = SkillDamageType.Default,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL2] = SkillDamageType.Default,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_RED_SKILL2] = SkillDamageType.Default,
    [XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL3] = SkillDamageType.Default,
}

---@class XChessSkill 棋子技能
---@field _Imp XBlackRockChess.XSkill
---@field _Control XBlackRockChessControl
local XChessSkill = XClass(nil, "XChessSkill")

function XChessSkill:Ctor(control, skillId, roleId)
    self._Control = control
    self._Id = skillId
    self._RoleId = roleId
    self._DamageFunc = {
        [SkillDamageType.Center2Around] = handler(self, self.GetCenter2AroundDps),
        [SkillDamageType.ExtraRound] = handler(self, self.GetExtraRoundDps),
        [SkillDamageType.Master2Assist] = handler(self, self.GetMaster2AssistDps),
        [SkillDamageType.Default] = handler(self, self.GetDefaultDps),
        [SkillDamageType.Default2] = handler(self, self.GetDefaultDps2),
        [SkillDamageType.MultiDamage] = handler(self, self.GetMultiDamageDps),
        [SkillDamageType.Hypotenuse] = handler(self, self.GetHypotenuseDps),
    }
    self._Cd = 0
    self._SkillUsedTimes = 0
    
    local defaultCd = self._Control:GetWeaponSkillCd(roleId, skillId, true)
    local initCd = self._Control:GetWeaponSkillInitCd(skillId)
    self._IsZeroCd = defaultCd == 0 and initCd == 0
end

function XChessSkill:SetImp(imp)
    self._Imp = imp
    self:InitImp()
end

function XChessSkill:IsInitImp()
    return self._Imp ~= nil
end

function XChessSkill:InitImp()
    local range = self._Control:GetWeaponSkillRange(self._Id)
    self._Cost = self._Control:GetWeaponSkillCost(0, self._Id, true)
    self._IsDizzy = self._Control:IsDizzy(self._Id)
    self._IsPassive = self._Control:IsPassive(self._Id)
    self._ExtraTurn = self._Control:GetWeaponSkillExtraTurn(self._Id)
    self._IsPenetrate = self._Control:GetWeaponSkillIsPenetrate(self._Id)
    local skillType = self._Control:GetWeaponSkillType(self._Id)
    self._Imp:InitParam(self._Id, range, skillType, self._Control:GetWeaponSkillParams(self._Id))
    local searchCount = SkillSearchCount[skillType] or 0
    self._Imp:CreateSputtering(searchCount)
    self._Imp:CreateAssistSputtering(self._Control:GetWeaponSkillAssistRange(self._Id))
    self._SkillType = skillType
end

function XChessSkill:GetSkillType()
    return self._SkillType
end

function XChessSkill:IsPassive()
    return self._IsPassive
end

function XChessSkill:AddMoveRange(range)
    if not self._Imp then
        return
    end
    self._Imp.AddMoveRange = self._Imp.AddMoveRange + range
end

function XChessSkill:GetShotCenter()
    if not self._Imp then
        return CS.UnityEngine.Vector2Int.zero
    end
    return self._Imp:GetAttackTarget()
end

function XChessSkill:GetId()
    return self._Id
end

function XChessSkill:IsDizzy()
    return self._IsDizzy
end

function XChessSkill:IsExtraTurn(turn)
    turn = turn or 0
    return self._ExtraTurn > 0 and self._ExtraTurn >= turn
end

function XChessSkill:GetCost()
    return self._Cost
end

function XChessSkill:AddSkillCost(value)
    self._Cost = math.max(0, self._Cost + value)
end

function XChessSkill:GetCd()
    return self._Cd
end

function XChessSkill:IsEnoughEnergy()
    -- 薇拉大招特殊判断
    if self._SkillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL3 then
        -- 必须在红怒模式下
        if not self._Control:IsEnterRedModel() then
            return false
        end
        local params = self._Control:GetWeaponSkillParams(self._Id)
        local energyCost = self._SkillUsedTimes >= 1 and params[3] or params[2]
        return self._Control:GetEnergy() >= energyCost
    end
    return self._Control:GetEnergy() >= self:GetCost()
end

function XChessSkill:IsCountDown()
    if not self._Cd then
        return false
    end
    return self._Cd <= 0
end

function XChessSkill:CouldUseSkill()
    if not self:IsCountDown() then
        return false
    end
    return self:IsEnoughEnergy()
end

function XChessSkill:UpdateData(leftCd, times)
    self:SetSkillUseTimes(times)
    self._Cd = leftCd
end

---增加技能在没有进入Cd的情况下所使用的次数
function XChessSkill:AddSkillUsedTimes()
    self:SetSkillUseTimes(self._SkillUsedTimes + 1)
end

---技能进入Cd时 重置技能使用次数
function XChessSkill:UpdateSkillUsedTimes(cd)
    if cd ~= self._Cd then
        self:SetSkillUseTimes(0)
    end
end

function XChessSkill:SetSkillUseTimes(times)
    self._SkillUsedTimes = times
    if self._Imp then
        self._Imp.SkillUsedTimes = self._SkillUsedTimes
    end
end

function XChessSkill:GetSkillUsedTimes()
    return self._SkillUsedTimes
end

--获取技能伤害，纯技能伤害
function XChessSkill:GetDamage(isCenter, isExtraTurn, isAssist, isMulti, isHypotenuse)
    local damage = 0
    if self:IsPassive() then
        return damage
    end
    local damageType = SkillType2Damage[self._SkillType]
    if not damageType then
        return damage
    end
    local func = self._DamageFunc[damageType]
    if not func then
        return damage
    end
    return func(isCenter, isExtraTurn, isAssist, isMulti, isHypotenuse)
end

function XChessSkill:GetCenter2AroundDps(isCenter, isExtraTurn, isAssist, isMulti, isHypotenuse)
    local params = self._Control:GetWeaponSkillParams(self._Id)
    return isCenter and params[1] or params[2]
end

function XChessSkill:GetExtraRoundDps(isCenter, isExtraTurn, isAssist, isMulti, isHypotenuse)
    local params = self._Control:GetWeaponSkillParams(self._Id)
    local addDamage = params[3]
    return isExtraTurn and params[1] + addDamage or params[1]
end

function XChessSkill:GetMaster2AssistDps(isCenter, isExtraTurn, isAssist, isMulti, isHypotenuse)
    local params = self._Control:GetWeaponSkillParams(self._Id)
    return isAssist and params[2] or params[1]
end

function XChessSkill:GetDefaultDps(isCenter, isExtraTurn, isAssist, isMulti, isHypotenuse)
    local params = self._Control:GetWeaponSkillParams(self._Id)
    return params[1]
end

function XChessSkill:GetDefaultDps2(isCenter, isExtraTurn, isAssist, isMulti, isHypotenuse)
    local params = self._Control:GetWeaponSkillParams(self._Id)
    return params[2]
end

function XChessSkill:GetMultiDamageDps(isCenter, isExtraTurn, isAssist, isMulti, isHypotenuse)
    local params = self._Control:GetWeaponSkillParams(self._Id)
    return isMulti and params[2] or params[1]
end

function XChessSkill:GetHypotenuseDps(isCenter, isExtraTurn, isAssist, isMulti, isHypotenuse)
    local params = self._Control:GetWeaponSkillParams(self._Id)
    return isHypotenuse and params[2] or params[1]
end

--召唤出来的角色持续回合
function XChessSkill:GetSummonContinuationRound()
    local params = self._Control:GetWeaponSkillParams(self._Id)
    if self._SkillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUNA_SKILL3 then
        return params[3]
    end
    return 0
end

function XChessSkill:IsUnlock()
    return self._Control:IsSkillUnlock(self._Id)
end

--被召唤出来时，所有Cd为0
function XChessSkill:OnSummon()
    local cd = self._Control:GetWeaponSkillInitCd(self._Id)
    self:UpdateSkillUsedTimes(cd)
    self._Cd = cd
end

function XChessSkill:DoUse()
    local cd = self._Control:GetWeaponSkillCd(self._RoleId, self._Id, true)
    self:UpdateSkillUsedTimes(cd)
    self._Cd = cd
end

function XChessSkill:AddSkillCd(cd)
    if self._IsZeroCd then
        return
    end
    local cd = self._Cd + cd
    self:UpdateSkillUsedTimes(cd)
    self._Cd = cd
end

--- 是否造成击杀时刷新Cd
function XChessSkill:IsKillRefresh()
    return self._SkillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL3
end

function XChessSkill:TriggerPassive(isAuto, param)
    --本期只有薇拉大招有被动
    local startIndex
    if self._SkillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUNA_SKILL3 then
        startIndex = 4
    elseif self._SkillType == XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.VERA_SKILL3 then
        startIndex = 4
    end
    if not XTool.IsNumberValid(startIndex) then
        return
    end
    local params = self._Control:GetWeaponSkillParams(self._Id)
    local actor = self._Control:GetChessGamer():GetRole(self._RoleId)
    for i = startIndex, #params do
        local skillId = params[i]
        local roleSkill = actor:TryGetRoleSkill(skillId)
        if roleSkill then
            roleSkill:SetWeaponSkill(self)
            roleSkill:SetParam(param)
            roleSkill:Trigger(isAuto)
            actor:DispatchBuff(self._Id, roleSkill:GetTriggerTimes())
        end
    end
end

function XChessSkill:IsDisableSkill()
    if self._SkillType ~= XEnumConst.BLACK_ROCK_CHESS.WEAPON_SKILL_TYPE.LUNA_SKILL3 then
        return false
    end
    local actor = self._Control:GetChessGamer():GetRole(self._Control:GetAssistantRoleId())
    if not actor then
        return false
    end
    
    return actor:IsInBoard()
end

function XChessSkill:OnRelease()
    self._Imp = nil
    self._Control = nil
    self._DamageFunc = nil
end

return XChessSkill