XFavorabilityConfigs = XFavorabilityConfigs or {}

--todo:使用该变量的模块后续替换为XEnumConst内的版本
XFavorabilityConfigs.RewardUnlockType = {
    FightAbility = 1,
    TrustLv = 2,
    CharacterLv = 3,
    Quality = 4,
}

--todo:使用该变量的模块后续替换为XEnumConst内的版本
XFavorabilityConfigs.SoundEventType = {
    FirstTimeObtain = 1, -- 首次获得角色
    LevelUp = 2, -- 角色升级
    Evolve = 3, -- 角色进化
    GradeUp = 4, -- 角色升军阶
    SkillUp = 5, -- 角色技能升级
    WearWeapon = 6, -- 角色穿戴武器
    MemberJoinTeam = 7, --角色入队(队员)
    CaptainJoinTeam = 8, --角色入队（队长）
}


function XFavorabilityConfigs.Init()
    
end

-- [好感度档案-动作]
--todo:使用该接口的模块后续替换为接口内的Agency接口
function XFavorabilityConfigs.GetCharacterActionById(characterId)
    return XMVCA.XFavorability:GetCharacterActionById(characterId)
end