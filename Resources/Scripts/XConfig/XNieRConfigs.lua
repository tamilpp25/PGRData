XNieRConfigs = XNieRConfigs or {}
local CLIENT_NIER_CHARACTERINFOMATION = "Client/Fuben/NieR/NieRCharacterInformation.tab"
local CLIENT_NIER_CHARACTERCLIENT = "Client/Fuben/NieR/NieRCharacterClient.tab"
local CLIENT_NIER_SHOP = "Client/Fuben/NieR/NieRShop.tab"
local CLIENT_NIER_REPEATSTAGECLIENT = "Client/Fuben/NieR/NieRRepeatableStageClient.tab"
local CLIENT_NIER_SUPPORTCLIENT = "Client/Fuben/NieR/NieRSupportClient.tab"
local CLIENT_NIER_SUPPORTSKILLCLIENT = "Client/Fuben/NieR/NieRSupportSkillClient.tab"
local CLIENT_NIER_TASK = "Client/Fuben/NieR/NieRTask.tab"
local CLIENT_NIER_EASTEREGGCLIENT = "Client/Fuben/NieR/NieREasterEggClient.tab"

local SHARE_NIER_ACTIVITY = "Share/Fuben/NieR/NieRActivity.tab"
local SHARE_NIER_CHAPTER = "Share/Fuben/NieR/NieRChapter.tab"
local SHARE_NIER_CHARACTER = "Share/Fuben/NieR/NieRCharacter.tab"
local SHARE_NIER_CHARACTERLEVEL = "Share/Fuben/NieR/NieRCharacterLevel.tab"
local SHARE_NIER_REPSTAGE = "Share/Fuben/NieR/NieRRepeatableStage.tab"
local SHARE_NIER_ABILITYGROUP = "Share/Fuben/NieR/NieRAbilityGroup.tab"

local SHARE_NIER_SUPPORT = "Share/Fuben/NieR/NieRSupport.tab"
local SHARE_NIER_SUPPORTLEVEL = "Share/Fuben/NieR/NieRSupportLevel.tab"
local SHARE_NIER_SUPPORTSKILLLEVEL = "Share/Fuben/NieR/NieRSupportSkillLevel.tab"

local SHARE_NIER_EASTEREGGCOM = "Share/Fuben/NieR/NieREasterEggCommunication.tab"
local SHARE_NIER_EASTEREGGINITMESSAGE = "Share/Fuben/NieR/NieREasterEggInitMessage.tab"
local SHARE_NIER_EASTEREGGLABLE = "Share/Fuben/NieR/NieREasterEggLabel.tab"
local SHARE_NIER_EASTEREGGMESSAGE = "Share/Fuben/NieR/NieREasterEggMessage.tab"

local NieRCharacterInforConfig = {}
local NieRCharacterInforDic = {}
local NieRCharacterClient = {}
local NieRCharacterShopClient = {}
local NieRRepeatableStageClient = {}
local ActivityConfig = {}
local ChapterConfig = {}
local CharacterConfig = {}
local CharacterLevelConfig = {}
local RepeatableStageConfig = {}
local AbilityGroupConfig = {}

local NieREasterEggConfigCom = {}
local NieREasterEggClientConfig = {}
local NieREasterEggInitMessageConfig = {}
local NieREasterEggLabelConfig = {}
local NieREasterEggMessageConfig = {}
local NieREasterEggClientDic = {}

local NieRSupportConfig = {}
local NieRSupportLevelConfig = {}
local NieRSupportLevelDic = {}
local NieRSupportMaxLevelDic = {}
local NieRSupportSkillLevelConfig = {}
local NieRSupportSkillLevelDic = {}
local NieRSupportMaxSkillLevelDic = {}
local NierRSupportConfigClient = {}
local NierRSupportSkillConfigClient = {}
local NieRSupportSkillLevelClientDic = {}

local CharacterList = {}
local CharacterLevelDic = {}
local CharacterMaxLevelDic = {}
local AbilityGroupDic = {}
local AbilityIdToType = {}

local NieRTaskConfig = {}


XNieRConfigs.NieRChInforStatue = {
    Lock = 1,
    UnLock = 2,
    CanUnLock = 3,
}

XNieRConfigs.NieRStageType = {
    AssignStage = 1,
    RepeatPoStage = 2,
    BossStage = 3,
    Teaching = 4,
    RepeatStage = 5
}

XNieRConfigs.NieRPodSkillType = {
    ActiveSkill = 0,
    PassiveSkill = 1,
}

XNieRConfigs.AbilityType = {
    Skill = 1,
    Fashion = 2,
    Weapon = 3,
    FourWafer = 4,
    TwoWafer = 5,
}

XNieRConfigs.EasterEggStoryType = {
    NoThing = 0,
    Leave = 1,
    Revive = 2,
}
local DefaultActivityId = 0
function XNieRConfigs.Init()
    NieRCharacterInforConfig = XTableManager.ReadByIntKey(CLIENT_NIER_CHARACTERINFOMATION, XTable.XTableNieRCharacterInformation, "Id")
    NieRCharacterClient = XTableManager.ReadByIntKey(CLIENT_NIER_CHARACTERCLIENT, XTable.XTableNieRCharacterClient, "CharacterId")
    NieRCharacterShopClient = XTableManager.ReadByIntKey(CLIENT_NIER_SHOP, XTable.XTableNieRShopClient, "ShopId")
    NieRRepeatableStageClient = XTableManager.ReadByIntKey(CLIENT_NIER_REPEATSTAGECLIENT, XTable.XTableNieRRepeatableStageClient, "StageId")
    NierRSupportConfigClient = XTableManager.ReadByIntKey(CLIENT_NIER_SUPPORTCLIENT, XTable.XTableNieRSupportClient, "SupportId")
    NierRSupportSkillConfigClient = XTableManager.ReadByIntKey(CLIENT_NIER_SUPPORTSKILLCLIENT, XTable.XTableNieRSupportSkillClient, "Id")

    ActivityConfig = XTableManager.ReadByIntKey(SHARE_NIER_ACTIVITY, XTable.XTableNieRActivity, "Id")
    ChapterConfig = XTableManager.ReadByIntKey(SHARE_NIER_CHAPTER, XTable.XTableNieRChapter, "ChapterId")
    CharacterConfig = XTableManager.ReadByIntKey(SHARE_NIER_CHARACTER, XTable.XTableNieRCharacter, "CharacterId")
    CharacterLevelConfig = XTableManager.ReadByIntKey(SHARE_NIER_CHARACTERLEVEL, XTable.XTableNieRCharacterLevel, "Id")
    RepeatableStageConfig = XTableManager.ReadByIntKey(SHARE_NIER_REPSTAGE, XTable.XTableNieRRepeatableStage, "RepeatableStageId")
    AbilityGroupConfig = XTableManager.ReadByIntKey(SHARE_NIER_ABILITYGROUP, XTable.XTableNieRAbilityGroup, "Id")

    NieRSupportConfig = XTableManager.ReadByIntKey(SHARE_NIER_SUPPORT, XTable.XTableNieRSupport, "SupportId")
    NieRSupportLevelConfig = XTableManager.ReadByIntKey(SHARE_NIER_SUPPORTLEVEL, XTable.XTableNieRSupportLevel, "Id")
    NieRSupportSkillLevelConfig = XTableManager.ReadByIntKey(SHARE_NIER_SUPPORTSKILLLEVEL, XTable.XTableNieRSupportSkillLevel, "Id")
    NieRTaskConfig = XTableManager.ReadByIntKey(CLIENT_NIER_TASK, XTable.XTableNieRTask, "TaskGroupId")

    NieREasterEggConfigCom = XTableManager.ReadByIntKey(SHARE_NIER_EASTEREGGCOM, XTable.XTableFunctionalCommunication, "Id")
    NieREasterEggClientConfig = XTableManager.ReadByIntKey(CLIENT_NIER_EASTEREGGCLIENT, XTable.XTableNieREasterEggClient, "Id")
    NieREasterEggInitMessageConfig = XTableManager.ReadByIntKey(SHARE_NIER_EASTEREGGINITMESSAGE, XTable.XTableNieREasterEggInitMessage, "Id")
    NieREasterEggLabelConfig = XTableManager.ReadByIntKey(SHARE_NIER_EASTEREGGLABLE, XTable.XTableNieREasterEggLabel, "Id")
    NieREasterEggMessageConfig = XTableManager.ReadByIntKey(SHARE_NIER_EASTEREGGMESSAGE, XTable.XTableNieREasterEggMessage, "Id")

    for _, config in pairs(CharacterConfig) do
        table.insert(CharacterList, config)
    end
    table.sort(CharacterList, function(a, b)
        return a.CharacterId < b.CharacterId
    end)

    for _, config in pairs(CharacterLevelConfig) do
        CharacterLevelDic[config.CharacterId] = CharacterLevelDic[config.CharacterId] or {}
        CharacterLevelDic[config.CharacterId][config.Level] = config

        if not CharacterMaxLevelDic[config.CharacterId] or CharacterMaxLevelDic[config.CharacterId] < config.Level then
            CharacterMaxLevelDic[config.CharacterId] = config.Level
        end
    end

    for activityId, config in pairs(ActivityConfig) do
        if XTool.IsNumberValid(config.TimeId) then
            DefaultActivityId = activityId
            break
        end
        DefaultActivityId = activityId
    end
    XNieRConfigs.InitAbilityConfig()
    XNieRConfigs.InitCharacterInformation()
    XNieRConfigs.InitSupportCfg()
    XNieRConfigs.InitNieREasterEggClientCfg()
end

function XNieRConfigs.GetDefaultActivityId()
    return DefaultActivityId
end

function XNieRConfigs.InitNieREasterEggClientCfg()
    NieREasterEggClientDic = {}
    for _, config in pairs(NieREasterEggClientConfig) do
        -- NieREasterEggClientDic[config.GroupId] = NieREasterEggClientDic[config.GroupId] or {}
        -- table.insert(NieREasterEggClientDic[config.GroupId], config)
        if not NieREasterEggClientDic[config.GroupId] or NieREasterEggClientDic[config.GroupId].Id > config.Id then
            NieREasterEggClientDic[config.GroupId] = config
        end
    end
end

function XNieRConfigs.InitCharacterInformation()
    NieRCharacterInforDic = {}
    for _, config in pairs(NieRCharacterInforConfig) do
        NieRCharacterInforDic[config.CharacterId] = NieRCharacterInforDic[config.CharacterId] or {}
        table.insert(NieRCharacterInforDic[config.CharacterId], config)
    end
end

function XNieRConfigs.InitAbilityConfig()
    AbilityIdToType = {}
    AbilityGroupDic = {}
    for _, config in pairs(AbilityGroupConfig) do
        AbilityGroupDic[config.AbilityGroupId] = AbilityGroupDic[config.AbilityGroupId] or {}
        if config.SkillId ~= 0 then
            if config.FashionId ~= 0 or config.WeaponId ~= 0 or #(config.WaferId) > 0 then
                XLog.ErrorTableDataNotFound("XNieRConfigs.InitAbilityConfig",
                SHARE_NIER_ABILITYGROUP, "Id", tostring(config.Id), "数据异常:每条数据仅允许配置一条生效属性")
            end
            AbilityIdToType[config.Id] = XNieRConfigs.AbilityType.Skill
        elseif config.FashionId ~= 0 then
            if config.SkillId ~= 0 or config.WeaponId ~= 0 or #(config.WaferId) > 0 then
                XLog.ErrorTableDataNotFound("XNieRConfigs.InitAbilityConfig",
                SHARE_NIER_ABILITYGROUP, "Id", tostring(config.Id), "数据异常:每条数据仅允许配置一条生效属性")
            end
            AbilityIdToType[config.Id] = XNieRConfigs.AbilityType.Fashion
        elseif config.WeaponId ~= 0 then
            if config.SkillId ~= 0 or config.FashionId ~= 0 or #(config.WaferId) > 0 then
                XLog.ErrorTableDataNotFound("XNieRConfigs.InitAbilityConfig",
                SHARE_NIER_ABILITYGROUP, "Id", tostring(config.Id), "数据异常:每条数据仅允许配置一条生效属性")
            end
            AbilityIdToType[config.Id] = XNieRConfigs.AbilityType.Weapon
        elseif #(config.WaferId) > 0 then
            if config.SkillId ~= 0 or config.FashionId ~= 0 or config.WeaponId ~= 0 then
                XLog.ErrorTableDataNotFound("XNieRConfigs.InitAbilityConfig",
                SHARE_NIER_ABILITYGROUP, "Id", tostring(config.Id), "数据异常:每条数据仅允许配置一条生效属性")
            elseif (#(config.WaferId) ~= 2 and #(config.WaferId) ~= 4) then
                XLog.ErrorTableDataNotFound("XNieRConfigs.InitAbilityConfig",
                SHARE_NIER_ABILITYGROUP, "Id", tostring(config.Id), "数据异常:意识数目应为2或4")
            end
            if (#(config.WaferId) == 4) then
                AbilityIdToType[config.Id] = XNieRConfigs.AbilityType.FourWafer
            else
                AbilityIdToType[config.Id] = XNieRConfigs.AbilityType.TwoWafer
            end

        end
        table.insert(AbilityGroupDic[config.AbilityGroupId], config)
    end
end

function XNieRConfigs.InitSupportCfg()
    NieRSupportLevelDic = {}
    NieRSupportMaxLevelDic = {}
    for _, cfg in pairs(NieRSupportLevelConfig) do
        NieRSupportLevelDic[cfg.SupportId] = NieRSupportLevelDic[cfg.SupportId] or {}
        NieRSupportLevelDic[cfg.SupportId][cfg.Level] = cfg
        if not NieRSupportMaxLevelDic[cfg.SupportId] or NieRSupportMaxLevelDic[cfg.SupportId] < cfg.Level then
            NieRSupportMaxLevelDic[cfg.SupportId] = cfg.Level
        end
    end

    NieRSupportSkillLevelDic = {}
    NieRSupportMaxSkillLevelDic = {}
    for _, cfg in pairs(NieRSupportSkillLevelConfig) do
        NieRSupportSkillLevelDic[cfg.SkillId] = NieRSupportSkillLevelDic[cfg.SkillId] or {}
        NieRSupportSkillLevelDic[cfg.SkillId][cfg.Level] = cfg
        if not NieRSupportMaxSkillLevelDic[cfg.SkillId] or NieRSupportMaxSkillLevelDic[cfg.SkillId] < cfg.Level then
            NieRSupportMaxSkillLevelDic[cfg.SkillId] = cfg.Level
        end
    end

    NieRSupportSkillLevelClientDic = {}
    for _, cfg in pairs(NierRSupportSkillConfigClient) do
        NieRSupportSkillLevelClientDic[cfg.SkillId] = NieRSupportSkillLevelClientDic[cfg.SkillId] or {}
        NieRSupportSkillLevelClientDic[cfg.SkillId][cfg.Level] = cfg
    end

end

function XNieRConfigs.GetNieRCharacterInforById(id)
    if not NieRCharacterInforConfig or not NieRCharacterInforConfig[id] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRCharacterInforById", "数据异常",
        CLIENT_NIER_CHARACTERINFOMATION, "id", tostring(id))
    end
    return NieRCharacterInforConfig[id]
end

function XNieRConfigs.GetNieRCharacterInforListById(characterId)
    if not NieRCharacterInforDic or not NieRCharacterInforDic[characterId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRCharacterInforListById", "数据异常",
        CLIENT_NIER_CHARACTERINFOMATION, "characterId", tostring(characterId))
    end
    return NieRCharacterInforDic[characterId]
end

function XNieRConfigs.GetActivityConfigById(activityId)
    if not ActivityConfig or not ActivityConfig[activityId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetActivityConfig", "数据异常",
        SHARE_NIER_ACTIVITY, "activityId", tostring(activityId))
    end
    return ActivityConfig[activityId] or {}
end

function XNieRConfigs.GetAllActivityConfig()
    if not ActivityConfig then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetActivityConfig", "数据异常",
        SHARE_NIER_ACTIVITY)
    end
    return ActivityConfig or {}
end

--根据Id获取章节配置
function XNieRConfigs.GetChapterConfigById(chapterId)
    if not ChapterConfig or not ChapterConfig[chapterId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetChapterConfigById", "数据异常",
        SHARE_NIER_CHAPTER, "chapterId", tostring(chapterId))
    end
    return ChapterConfig[chapterId] or {}
end

--获取章节配置
function XNieRConfigs.GetAllChapterConfig()
    if not ChapterConfig then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetChapterConfigById", "数据异常",
        SHARE_NIER_CHAPTER)
    end
    return ChapterConfig or {}
end

--根据Id获取角色配置
function XNieRConfigs.GetCharacterConfigById(characterId)
    if not CharacterConfig or not CharacterConfig[characterId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetCharacterConfigById", "数据异常",
        SHARE_NIER_CHARACTER, "characterId", tostring(characterId))
    end
    return CharacterConfig[characterId] or {}
end

--获取角色配置
function XNieRConfigs.GetAllCharacterConfig()
    if not CharacterConfig then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetCharacterConfigById", "数据异常",
        SHARE_NIER_CHARACTER)
    end
    return CharacterConfig or {}
end

--获取客户端配置
function XNieRConfigs.GetCharacterClientConfigById(characterId)
    if not NieRCharacterClient or not NieRCharacterClient[characterId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetCharacterClientConfigById", "数据异常",
        CLIENT_NIER_CHARACTERCLIENT, "characterId", tostring(characterId))
    end
    return NieRCharacterClient[characterId] or {}
end

--获取角色等级配置
function XNieRConfigs.GetCharacterLevelConfig(characterId, level)
    if not CharacterLevelDic or not CharacterLevelDic[characterId] or not CharacterLevelDic[characterId][level] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetCharacterLevelConfig", "数据异常",
        SHARE_NIER_CHARACTERLEVEL, "characterId = " .. tostring(characterId), "level = " .. tostring(level))
        return {}
    end
    return CharacterLevelDic[characterId][level]
end

--获取角色最大等级
function XNieRConfigs.GetCharacterMaxLevelById(characterId)
    if not CharacterMaxLevelDic or not CharacterMaxLevelDic[characterId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetCharacterMaxLevelById", "数据异常",
        SHARE_NIER_CHARACTERLEVEL, "characterId", tostring(characterId))
        return {}
    end
    return CharacterMaxLevelDic[characterId]
end

--根据Id获取能力配置
function XNieRConfigs.GetAbilityGroupConfigById(Id)
    if not AbilityGroupConfig or not AbilityGroupConfig[Id] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetAbilityGroupConfigById", "数据异常",
        SHARE_NIER_ABILITYGROUP, "Id", tostring(Id))
    end
    return AbilityGroupConfig[Id] or {}
end

--根据Id获取能力配置
function XNieRConfigs.GetAbilityGroupConfigByGroupId(abilityGroupId)
    if not AbilityGroupDic or not AbilityGroupDic[abilityGroupId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetAbilityGroupConfigByGroupId", "数据异常",
        SHARE_NIER_ABILITYGROUP, "abilityGroupId", tostring(abilityGroupId))
    end
    return AbilityGroupDic[abilityGroupId] or {}
end

--
function XNieRConfigs.GetAbilityTypeById(id)
    if not AbilityIdToType or not AbilityIdToType[id] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetAbilityTypeById", "AbilityType没有初始化或配置异常",
        SHARE_NIER_ABILITYGROUP, "id", tostring(id))
    end
    return AbilityIdToType[id] or 0
end

--根据Id获取复刷关配置
function XNieRConfigs.GetRepeatableStageConfigById(repeatableStageId)
    if not RepeatableStageConfig or not RepeatableStageConfig[repeatableStageId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetRepeatableStageConfigById", "数据异常",
        SHARE_NIER_REPSTAGE, "repeatableStageId", tostring(repeatableStageId))
    end
    return RepeatableStageConfig[repeatableStageId] or {}
end

--获取复刷关配置
function XNieRConfigs.GetRepeatableStageConfig()
    if not RepeatableStageConfig then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetRepeatableStageConfigById", "数据异常",
        SHARE_NIER_REPSTAGE)
    end
    return RepeatableStageConfig or {}
end

function XNieRConfigs.GetNieRShopById(shopId)
    if not NieRCharacterShopClient or not NieRCharacterShopClient[shopId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRShopById", "数据异常",
        CLIENT_NIER_SHOP, "shopId", tostring(shopId))
    end
    return NieRCharacterShopClient[shopId]
end

function XNieRConfigs.GetNieRRepeatableStageClient(stageId)
    if not NieRRepeatableStageClient or not NieRRepeatableStageClient[stageId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRRepeatableStageClient", "数据异常",
        CLIENT_NIER_SHOP, "stageId", tostring(stageId))
    end
    return NieRRepeatableStageClient[stageId]
end

--获取尼尔角色列表
function XNieRConfigs.GetCharacterList()
    return CharacterList
end

--获取辅助机配置
function XNieRConfigs.GetNieRSupportConfig(supportId)
    if not NieRSupportConfig or not NieRSupportConfig[supportId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRSupportConfig", "数据异常",
        SHARE_NIER_SUPPORT, "supportId", tostring(supportId))
    end
    return NieRSupportConfig[supportId]
end

--获取辅助机等级配置
function XNieRConfigs.GetNieRSupportLevelConfig(id)
    if not NieRSupportLevelConfig or not NieRSupportLevelConfig[id] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRSupportLevelConfig", "数据异常",
        SHARE_NIER_SUPPORTLEVEL, "id", tostring(id))
    end
    return NieRSupportLevelConfig[id]
end

--获取辅助机等级配置
function XNieRConfigs.GetNieRSupportLevelCfgBuyIdAndLevel(supportId, level)
    if not NieRSupportLevelDic or not NieRSupportLevelDic[supportId] or not NieRSupportLevelDic[supportId][level] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRSupportLevelCfgBuyIdAndLevel",
        SHARE_NIER_SUPPORTLEVEL, "supportId = " .. tostring(supportId), "level = " .. tostring(level))
    end
    return NieRSupportLevelDic[supportId][level]
end

--获取辅助机最大等级
function XNieRConfigs.GetNieRSupportMaxLevelById(supportId)
    if not NieRSupportMaxLevelDic or not NieRSupportMaxLevelDic[supportId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRSupportMaxLevelById", "数据异常",
        SHARE_NIER_SUPPORTLEVEL, "supportId", tostring(supportId))
    end
    return NieRSupportMaxLevelDic[supportId]
end

--获取所有辅助机技能
function XNieRConfigs.GetAllNieRSupportSkillLevelConfig()
    if not NieRSupportSkillLevelConfig then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRSupportSkillLevelConfig", "数据异常",
        SHARE_NIER_SUPPORTSKILLLEVEL)
    end
    return NieRSupportSkillLevelConfig
end

--获取辅助机技能配置
function XNieRConfigs.GetNieRSupportSkillLevelConfig(skillId)
    if not NieRSupportSkillLevelConfig or not NieRSupportSkillLevelConfig[skillId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRSupportSkillLevelConfig", "数据异常",
        SHARE_NIER_SUPPORTSKILLLEVEL, "skillId", tostring(skillId))
    end
    return NieRSupportSkillLevelConfig[skillId]
end

--根据id和等级获取辅助机技能配置
function XNieRConfigs.GetNieRSupportSkillLevelCfgBuyIdAndLevel(skillId, level)
    if not NieRSupportSkillLevelDic or not NieRSupportSkillLevelDic[skillId] or not NieRSupportSkillLevelDic[skillId][level] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRSupportSkillLevelCfgBuyIdAndLevel", "数据异常",
        SHARE_NIER_SUPPORTSKILLLEVEL, "skillId =" .. tostring(skillId), "level =" .. tostring(level))
    end
    return NieRSupportSkillLevelDic[skillId][level]
end

--获取辅助机技能最大等级
function XNieRConfigs.GetNieRSupportMaxSkillLevelById(skillId)
    if not NieRSupportMaxSkillLevelDic or not NieRSupportMaxSkillLevelDic[skillId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRSupportMaxSkillLevelById", "数据异常",
        SHARE_NIER_SUPPORTSKILLLEVEL, "skillId", tostring(skillId))
    end
    return NieRSupportMaxSkillLevelDic[skillId]
end

--获取辅助机客户端配置
function XNieRConfigs.GetNieRSupportClientConfig(id)
    if not NierRSupportConfigClient or not NierRSupportConfigClient[id] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRSupportClientConfig", "数据异常",
        CLIENT_NIER_SUPPORTCLIENT, "id", tostring(id))
    end
    return NierRSupportConfigClient[id]
end

--根据Id和lv获取辅助机技能客户端配置
function XNieRConfigs.GetNieRSupportSkillClientConfig(id, level)
    if not NieRSupportSkillLevelClientDic or not NieRSupportSkillLevelClientDic[id] or not NieRSupportSkillLevelClientDic[id][level] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRSupportSkillClientConfig", "数据异常",
        CLIENT_NIER_SUPPORTSKILLCLIENT, "id = " .. tostring(id), "level = " .. tostring(level))
    end
    return NieRSupportSkillLevelClientDic[id][level]
end

--根据groupId获取尼尔任务
function XNieRConfigs.GetNieRTaskGroupByGroupId(groupId)
    if not NieRTaskConfig or not NieRTaskConfig[groupId] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieRTaskGroupByGroupId", "数据异常",
        CLIENT_NIER_TASK, "groupId = ", tostring(groupId))
    end
    return NieRTaskConfig[groupId]
end

--获取彩蛋关播放剧情
function XNieRConfigs.GetNieREasterEggComConfig()
    if not NieREasterEggConfigCom or not NieREasterEggConfigCom[1] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieREasterEggComConfig", "数据异常",
        SHARE_NIER_EASTEREGGCOM, "Id = ", tostring(1))
    end
    return NieREasterEggConfigCom[1]
end

--获取彩蛋关死亡剧情
function XNieRConfigs.GetNieREasterEggClientConfigById(id)
    if not NieREasterEggClientConfig or not NieREasterEggClientConfig[id] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieREasterEggClientConfigById", "数据异常",
        CLIENT_NIER_EASTEREGGCLIENT, "Id = ", tostring(id))
    end
    return NieREasterEggClientConfig[id]
end

--获取彩蛋关死亡剧情
function XNieRConfigs.GetNieREasterEggClientConfigByGroupId(id)
    if not NieREasterEggClientDic or not NieREasterEggClientDic[id] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieREasterEggClientConfigByGroupId", "数据异常",
        CLIENT_NIER_EASTEREGGCLIENT, "Id = ", tostring(id))
    end
    return NieREasterEggClientDic[id]
end

function XNieRConfigs.GetNieREasterEggInitMessageConfig()
    local list = {}
    for _, config in pairs(NieREasterEggInitMessageConfig) do
        table.insert(list, config)
    end
    local mgsCount = #list
    for i = 1, mgsCount / 2 do
        local index1 = math.random(1, mgsCount)
        local index2 = math.random(1, mgsCount)
        local config = list[index1]
        list[index1] = list[index2]
        list[index2] = config
    end
    return list
end

function XNieRConfigs.GetNieREasterEggLabelConfigById(id)
    if not NieREasterEggLabelConfig or not NieREasterEggLabelConfig[id] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieREasterEggLabelConfigs", "数据异常",
        SHARE_NIER_EASTEREGGLABLE, "Id = ", tostring(id))
    end
    return NieREasterEggLabelConfig[id]
end

function XNieRConfigs.GetNieREasterEggLabelConfigs()
    if not NieREasterEggLabelConfig then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieREasterEggLabelConfigs", "数据异常",
        SHARE_NIER_EASTEREGGLABLE)
    end
    local list = {}
    for _, config in pairs(NieREasterEggLabelConfig) do
        table.insert(list, config)
    end
    return list
end

function XNieRConfigs.GetNieREasterEggMessageConfigById(id)
    if not NieREasterEggMessageConfig or not NieREasterEggMessageConfig[id] then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieREasterEggMessageConfigs", "数据异常",
        SHARE_NIER_EASTEREGGLABLE, "Id = ", tostring(id))
    end
    return NieREasterEggMessageConfig[id]
end

function XNieRConfigs.GetNieREasterEggMessageConfigs()
    if not NieREasterEggMessageConfig then
        XLog.ErrorTableDataNotFound("XNieRConfigs.GetNieREasterEggMessageConfigs", "数据异常",
        SHARE_NIER_EASTEREGGLABLE)
    end
    local list = {}
    for _, config in pairs(NieREasterEggMessageConfig) do
        table.insert(list, config)
    end
    return list
end