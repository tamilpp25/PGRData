local pairs = pairs
local table = table
local tableSort = table.sort
local tableInsert = table.insert

XCharacterConfigs = XCharacterConfigs or {}

-- 推荐类型
XCharacterConfigs.CharacterType = {
    Normal = 1, --构造体
    Isomer = 2, --异构体/感染体
    Robot = 3, --试玩角色
    Sp = 4, --Sp角色
}

--角色解放等级
XCharacterConfigs.GrowUpLevel = {
    New = 1, -- 新兵
    Lower = 2, -- 低级
    Middle = 3, -- 中级
    Higher = 4, -- 终阶
    Super = 5, -- 超级
    End = 5,
}

-- 推荐类型
XCharacterConfigs.RecommendType = {
    Character = 1, --推荐角色
    Equip = 2, --推荐装备
}

XCharacterConfigs.XUiCharacter_Camera = {
    MAIN = 0,
    LEVEL = 1,
    GRADE = 2,
    QULITY = 3,
    SKILL = 4,
    EXCHANGE = 5,
    ENHANCESKILL = 6,
}

XCharacterConfigs.SkillUnLockType = {
    Enhance = 1,
    Sp = 2,
}

XCharacterConfigs.SkillDetailsType = {
    Normal = 1,
    Enhance = 2,
}

-- 信号球颜色
XCharacterConfigs.CharacterLiberateBallColorType = {
    Red = 1,
    Yellow = 2,
    Blue = 3,
}

-- 基本职业类型索引
local Career2CareerType = {
    [5] = 3, -- 增幅型 -> 辅助型
}

--角色终阶解放技能ID约定配置
XCharacterConfigs.MAX_LEBERATION_SKILL_POS_INDEX = 13

XCharacterConfigs.MAX_SHOW_SKILL_POS = 4--展示用技能组数量

local TABLE_LEVEL_UP_TEMPLATE_PATH = "Share/Character/LevelUpTemplate/"
local TABLE_CHARACTER_QUALITY_FRAGMENT_PATH = "Share/Character/Quality/CharacterQualityFragment.tab"
--v1.28-升阶拆分：角色升级技能配置
local TABLE_CHARACTER_QUALITY_SKILL_PATH = "Client/Character/Quality/CharacterSkillQualityApart.tab"
local TABLE_CHARACTER_QUALITY_PATH = "Share/Character/Quality/CharacterQuality.tab"
local TABLE_CHARACTER_GRADE_PATH = "Share/Character/Grade/CharacterGrade.tab"
local TABLE_CHARACTER_CAREER_PATH = "Share/Character/CharacterCareer.tab"
local TABLE_CHARACTER_SKILL = "Share/Character/Skill/CharacterSkill.tab"
local TABLE_CHARACTER_SKILL_GROUP = "Share/Character/Skill/CharacterSkillGroup.tab"
local TABLE_CHARACTER_DETAIL = "Client/Character/CharacterDetail.tab"
local TABLE_CHARACTER_SKILL_TEACH = "Client/Character/Skill/CharacterSkillTeach.tab"
local TABLE_CHARACTER_ELEMENT_CONFIG = "Client/Character/CharacterElement.tab"
local TABLE_CHARACTER_SKILL_POS = "Share/Character/Skill/CharacterSkillPos.tab"
local TABLE_CHARACTER_SKILL_GRADE = "Share/Character/Skill/CharacterSkillUpgrade.tab"
local TABLE_CHARACTER_SKILL_GRADE_DES = "Client/Character/Skill/CharacterSkillUpgradeDes.tab"
local TABLE_CHARACTER_SKILL_GATE = "Client/Character/Skill/CharacterSkillGate.tab"
local TABLE_CHARACTER_SKILL_LEVEL = "Share/Character/Skill/CharacterSkillLevelEffect.tab"
local TABLE_CHARACTER_SKILL_TYPE_INFO = "Client/Character/Skill/CharacterSkillTypeInfo.tab"
local TABLE_CHARACTER_SKILL_TYPE = "Share/Character/Skill/CharacterSkillType.tab"
local TABLE_CHARACTER_SKILL_TYPE_PLUS = "Share/Character/Skill/CharacterSkillTypePlus.tab"
local TABLE_CHARACTER_GRAPH_INFO = "Client/Character/CharacterGraph.tab"
local TABLE_CHARACTER_SKILL_POOL = "Share/Character/Skill/CharacterSkillPool.tab"
local TABLE_CHARACTER_DETAIL_PARNER = "Client/Character/CharacterRecommend.tab"
local TABLE_CHARACTER_DETAIL_EQUIP = "Share/Equip/EquipGuide/EquipRecommend.tab"
local TABLE_CHARACTER_RECOMMEND_TAB_CONFIG = "Client/Character/CharacterTabId.tab"
local TABLE_CHARACTER_QUALITY_ICON_PATH = "Client/Character/CharacterQualityIcon.tab"
local TABLE_NPC_PATH = "Share/Fight/Npc/Npc"
local TABLE_CHARACTER_LIBERATION_PATH = "Client/Character/CharacterLiberation.tab"
local TABLE_CHARACTER_SKILL_ENTRY = "Client/Character/Skill/CharacterSkillEntry.tab"

local TABLE_CHARACTER_ENHANCESKILL_ENTRY = "Client/Character/EnhanceSkill/EnhanceSkillEntry.tab"
local TABLE_CHARACTER_ENHANCESKILL_GRADE_DES = "Client/Character/EnhanceSkill/EnhanceSkillUpgradeDes.tab"
local TABLE_CHARACTER_ENHANCESKILL_TYPE_INFO = "Client/Character/EnhanceSkill/EnhanceSkillTypeInfo.tab"
local TABLE_CHARACTER_ENHANCESKILL = "Share/Character/EnhanceSkill/EnhanceSkill.tab"
local TABLE_CHARACTER_ENHANCESKILL_POS = "Share/Character/EnhanceSkill/EnhanceSkillPos.tab"
local TABLE_CHARACTER_ENHANCESKILL_GROUP = "Share/Character/EnhanceSkill/EnhanceSkillGroup.tab"
local TABLE_CHARACTER_ENHANCESKILL_LEVEL = "Share/Character/EnhanceSkill/EnhanceSkillLevelEffect.tab"
local TABLE_CHARACTER_ENHANCESKILL_TYPE = "Share/Character/EnhanceSkill/EnhanceSkillType.tab"
local TABLE_CHARACTER_ENHANCESKILL_GRADE = "Share/Character/EnhanceSkill/EnhanceSkillUpgrade.tab"

-- 配置相关
local LevelUpTemplates = {}                 -- 升级模板
local CharQualityTemplates = {}             -- 角色品质配置
local CharQualityFragmentTemplates = {}     -- 品质对应碎片
local CharQualityIconTemplates = {}         -- 角色品质图标
local CharSkillQualityApart = {}            -- 角色升阶技能拆分
local CharSkillQualityApartDic = {}         -- 角色升阶技能拆分字典
local CharGradeTemplates = {}               -- 角色改造配置
local CharacterCareerTemplates = {}             -- npc类型图标配置
local SubSkillMinMaxLevelDicGrade = {}     -- 副技能最小最大等级配置(from TABLE_CHARACTER_SKILL_GRADE)
local SubSkillMinMaxLevelDicLevel = {}     -- 副技能最小最大等级配置(from TABLE_CHARACTER_SKILL_LEVEL)
local CharDetailTemplates = {}              -- 角色详细
local CharTeachSkill = {}                   -- 角色技能教学
local CharElementTemplates = {}             -- 角色元素配置
local SkillGradeConfig = {}                 -- 角色技能升级表
local SkillGradeDesConfig = {}              -- 角色技能升级描述表
local SkillGateConfig = {}                  -- 角色技能模块配置表
local SkillPosConfig = {}                   -- 角色技能大组显示配置
local CharGraphTemplates = {}               -- 角色六位图配置
local CharSkillLevelDict = {}               -- 角色技能Id，等级Id的属性表Map
local CharSkillLevelDesDict = {}            -- 角色技能Id，等级Id的属性表Map
local CharSkillLevelEffectDict = {}         -- 角色技能Id, 等级Id的升级表Map
local CharSkillPoolSkillIdDic = {}          -- 角色技能共鸣池SkillId映射技能信息字典
local SkillTypeInfoConfig = {}              -- 角色技能分类名字
local CharacterSkillType = {}               -- 角色技能Id分类
local SkillTypePlusConfig = {}              -- 角色技能分类加成
local CharPoolIdToSkillInfoDic = {}         -- 角色技能共鸣池PoolId映射技能信息字典
local CharSkillIdToCharacterIdDic = {}      -- SkillId映射CharacterId字典
local CharLiberationTemplates = {}          -- 角色解放配置
local NpcTemplates = {}                     -- npc配置表
local CharMaxLiberationSkillIdDic = {}      -- 角色终阶解放技能Id字典
local CharSkillGroupDic = {}                -- 角色技能组配置
local CharSkillIdToGroupDic = {}            -- 角色技能Id,技能组字典
local CharSkillTemplates = {}               -- 角色子技能配置
local CharacterSkillDictTemplates = {}      -- 角色技能组配置
local CharacterSkillEntryConfig = {}        -- 角色技能词条表

local EnhanceSkillConfig = {}               -- 角色补强技能配置
local EnhanceSkillGroupConfig = {}          -- 角色补强技能组配置
local EnhanceSkillEntryConfig = {}          -- 角色补强技能技能词条表
local EnhanceSkillGradeConfig = {}          -- 角色补强技能升级表
local EnhanceSkillGradeDescConfig = {}       -- 角色补强技能升级描述表
local EnhanceSkillTypeInfoConfig = {}       -- 角色补强技能分类名字
local EnhanceSkillPosConfig = {}            -- 角色补强技能大组显示配置
local EnhanceSkillLevelEffectConfig = {}    -- 角色补强技能等级效果配置
local EnhanceSkillTypeConfig = {}           -- 角色补强技能Id分类

local EnhanceSkillGradeDic = {}          -- 角色补强技能升级字典
local EnhanceSkillGradeDescDic = {}       -- 角色补强技能升级描述字典
local EnhanceSkillLevelEffectDic = {}    -- 角色补强技能等级效果字典
local EnhanceSkillMaxLevelDic = {}       -- 角色补强技能最大等级字典

local CharacterRecommendTemplates   --角色推荐表
local EquipRecommendTemplates       --装备推荐表
local CharacterTabToVoteGroupMap    --角色标签转投票组表
local CharSkillGroupTemplates       --技能组表

-- 体验包保留角色
local IncludeCharacterIds = {
    [1021001] = true, -- 露西亚
    [1031001] = true, -- 丽芙
    [1051001] = true, -- 七实
    [1511003] = true, -- 卡穆
}
local IsHideFunc = CS.XRemoteConfig.IsHideFunc
local IsIncludeCharacter = function(characterId)
    return not IsHideFunc or IncludeCharacterIds[characterId]
end

local InitCharQualityConfig = function()
    -- 角色品质对应配置
    local tab = XTableManager.ReadByIntKey(TABLE_CHARACTER_QUALITY_PATH, XTable.XTableCharacterQuality, "Id")
    for _, config in pairs(tab) do
        if not CharQualityTemplates[config.CharacterId] then
            CharQualityTemplates[config.CharacterId] = {}
        end
        CharQualityTemplates[config.CharacterId][config.Quality] = config
    end

    CharQualityIconTemplates = XTableManager.ReadByIntKey(TABLE_CHARACTER_QUALITY_ICON_PATH, XTable.XTableCharacterQualityIcon, "Quality")
end

local IniCharQualityFragmentConfig = function()
    local templates = XTableManager.ReadByIntKey(TABLE_CHARACTER_QUALITY_FRAGMENT_PATH, XTable.XTableCharacterQualityFragment, "Id")
    for _, config in pairs(templates) do
        local characterType = config.Type
        local characterTypeConfig = CharQualityFragmentTemplates[characterType] or {}
        CharQualityFragmentTemplates[characterType] = characterTypeConfig

        local quality = config.Quality
        characterTypeConfig[quality] = config
    end
end

-- 角色升阶技能拆分
local InitCharSkillQualityApart = function ()
    CharSkillQualityApart = XTableManager.ReadByIntKey(TABLE_CHARACTER_QUALITY_SKILL_PATH, XTable.XTableCharacterSkillQualityApart, "Id")
    for _, config in pairs(CharSkillQualityApart) do
        if not CharSkillQualityApartDic[config.CharacterId] then
            CharSkillQualityApartDic[config.CharacterId] = {}
        end
        if not CharSkillQualityApartDic[config.CharacterId][config.Quality] then
            CharSkillQualityApartDic[config.CharacterId][config.Quality] = {}
        end
        if not CharSkillQualityApartDic[config.CharacterId][config.Quality][config.Phase] then
            CharSkillQualityApartDic[config.CharacterId][config.Quality][config.Phase] = {}
        end 
        table.insert(CharSkillQualityApartDic[config.CharacterId][config.Quality][config.Phase], config.Id)
    end
end

local InitCharLiberationConfig = function()
    local tab = XTableManager.ReadByIntKey(TABLE_CHARACTER_LIBERATION_PATH, XTable.XTableCharacterLiberation, "Id")
    for _, config in pairs(tab) do
        if not CharLiberationTemplates[config.CharacterId] then
            CharLiberationTemplates[config.CharacterId] = {}
        end
        CharLiberationTemplates[config.CharacterId][config.GrowUpLevel] = config
    end
end

local InitCharGradeConfig = function()
    -- 角色改造数据
    local tab = XTableManager.ReadByIntKey(TABLE_CHARACTER_GRADE_PATH, XTable.XTableCharacterGrade, "Id")
    for _, config in pairs(tab) do
        if not CharGradeTemplates[config.CharacterId] then
            CharGradeTemplates[config.CharacterId] = {}
        end

        CharGradeTemplates[config.CharacterId][config.Grade] = config
    end
end

local InitCharLevelConfig = function()
    local paths = CS.XTableManager.GetPaths(TABLE_LEVEL_UP_TEMPLATE_PATH)
    XTool.LoopCollection(paths, function(path)
        local key = tonumber(XTool.GetFileNameWithoutExtension(path))
        LevelUpTemplates[key] = XTableManager.ReadByIntKey(path, XTable.XTableEquipLevelUp, "Level")
    end)
end

local IntCharSubSkillConfig = function()
    SkillGradeConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_SKILL_GRADE, XTable.XTableCharacterSkillUpgrade, "Id")
    SkillGradeDesConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_SKILL_GRADE_DES, XTable.XTableCharacterSkillUpgradeDes, "Id")
    SkillPosConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_SKILL_POS, XTable.XTableCharacterPos, "CharacterId")
    local skillLevelConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_SKILL_LEVEL, XTable.XTableCharacterSkillLevelEffect, "Id")
    SkillTypeInfoConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_SKILL_TYPE_INFO, XTable.XTableCharacterSkillTypeInfo, "Type")
    SkillTypePlusConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_SKILL_TYPE_PLUS, XTable.XTableCharacterSkillTypePlus, "Id")
    CharacterSkillType = XTableManager.ReadByIntKey(TABLE_CHARACTER_SKILL_TYPE, XTable.XTableCharacterSkillType, "Id")
    CharSkillTemplates = XTableManager.ReadByIntKey(TABLE_CHARACTER_SKILL, XTable.XTableCharacterSkill, "CharacterId")
    SkillGateConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_SKILL_GATE, XTable.XTableCharacterSkillGate, "Id")
    
    for _, config in pairs(CharSkillTemplates) do
        local characterId = config.CharacterId

        local characterSkillConfig = CharacterSkillDictTemplates[characterId]
        if not characterSkillConfig then
            characterSkillConfig = {}
            CharacterSkillDictTemplates[characterId] = characterSkillConfig
        end

        local posList = config.Pos
        for index, skillGroupId in pairs(config.SkillGroupId) do
            local pos = posList[index]
            if not pos then
                XLog.Error("XCharacterConfigs IntCharSubSkillConfig Error: 角色技能配置初始化错误, 找不到对应位置的技能组Id配置, skillGroupId: " .. skillGroupId .. ", 配置路径: " .. TABLE_CHARACTER_SKILL)
                return
            end

            local posSkillConfig = characterSkillConfig[pos]
            if not posSkillConfig then
                posSkillConfig = {}
                characterSkillConfig[pos] = posSkillConfig
            end
            tableInsert(posSkillConfig, skillGroupId)

            CharSkillIdToCharacterIdDic[skillGroupId] = characterId

            if index == XCharacterConfigs.MAX_LEBERATION_SKILL_POS_INDEX then
                CharMaxLiberationSkillIdDic[characterId] = skillGroupId
            end
        end
    end

    CharSkillGroupTemplates = XTableManager.ReadByIntKey(TABLE_CHARACTER_SKILL_GROUP, XTable.XTableCharacterSkillGroup, "Id")
    for _, config in pairs(CharSkillGroupTemplates) do
        local skillGroupId = config.Id
        local skillIds = config.SkillId

        local skillIdConfig = CharSkillGroupDic[skillGroupId]
        if not skillIdConfig then
            skillIdConfig = {}
            CharSkillGroupDic[skillGroupId] = skillIdConfig
        end

        for index, skillId in pairs(skillIds) do
            if skillId > 0 then
                CharSkillIdToGroupDic[skillId] = {
                    Index = index,
                    GroupId = skillGroupId,
                }
                tableInsert(skillIdConfig, skillId)
            end
        end
    end

    for k, v in pairs(SkillGradeConfig) do
        if not CharSkillLevelDict[v.SkillId] then
            CharSkillLevelDict[v.SkillId] = {}
        end
        CharSkillLevelDict[v.SkillId][v.Level] = k
    end

    for k, v in pairs(SkillGradeDesConfig) do
        if not CharSkillLevelDesDict[v.SkillId] then
            CharSkillLevelDesDict[v.SkillId] = {}
        end
        CharSkillLevelDesDict[v.SkillId][v.Level] = k
    end

    SubSkillMinMaxLevelDicLevel = {}
    for _, v in pairs(skillLevelConfig) do
        if not CharSkillLevelEffectDict[v.SkillId] then
            CharSkillLevelEffectDict[v.SkillId] = {}
        end
        CharSkillLevelEffectDict[v.SkillId][v.Level] = v

        --初始化技能的最小，最大等级2
        SubSkillMinMaxLevelDicLevel[v.SkillId] = SubSkillMinMaxLevelDicLevel[v.SkillId] or {}
        if not SubSkillMinMaxLevelDicLevel[v.SkillId].Min
        or SubSkillMinMaxLevelDicLevel[v.SkillId].Min > v.Level then
            SubSkillMinMaxLevelDicLevel[v.SkillId].Min = v.Level
        end

        if not SubSkillMinMaxLevelDicLevel[v.SkillId].Max
        or SubSkillMinMaxLevelDicLevel[v.SkillId].Max < v.Level then
            SubSkillMinMaxLevelDicLevel[v.SkillId].Max = v.Level
        end
    end

    --初始化技能的最小，最大等级
    SubSkillMinMaxLevelDicGrade = {}
    for _, v in pairs(SkillGradeConfig) do
        local skillId = v.SkillId
        if not SubSkillMinMaxLevelDicGrade[skillId] then
            SubSkillMinMaxLevelDicGrade[skillId] = {}
            SubSkillMinMaxLevelDicGrade[skillId].Min = v.Level
            SubSkillMinMaxLevelDicGrade[skillId].Max = v.Level
        end

        if v.Level < SubSkillMinMaxLevelDicGrade[skillId].Min then
            SubSkillMinMaxLevelDicGrade[skillId].Min = v.Level
        end

        if v.Level > SubSkillMinMaxLevelDicGrade[skillId].Max then
            SubSkillMinMaxLevelDicGrade[skillId].Max = v.Level
        end
    end
end

local InitCharacterSkillPoolConfig = function()
    CharSkillPoolSkillIdDic = {}

    local skillPoolTemplate = XTableManager.ReadByIntKey(TABLE_CHARACTER_SKILL_POOL, XTable.XTableCharacterSkillPool, "Id")
    for _, v in pairs(skillPoolTemplate) do
        CharSkillPoolSkillIdDic[v.SkillId] = v
        CharPoolIdToSkillInfoDic[v.PoolId] = CharPoolIdToSkillInfoDic[v.PoolId] or {}

        tableInsert(CharPoolIdToSkillInfoDic[v.PoolId], v)
    end
end

local function voteNumSort(dataA, dataB)
    local voteA = XDataCenter.VoteManager.GetVote(dataA.Id).VoteNum
    local voteB = XDataCenter.VoteManager.GetVote(dataB.Id).VoteNum
    return voteA > voteB
end

local InitRecommendConfig = function(templates)
    CharacterTabToVoteGroupMap = {}
    for _, config in pairs(templates) do
        local typeMap = CharacterTabToVoteGroupMap[config.CharacterId]
        if not typeMap then
            typeMap = {}
            CharacterTabToVoteGroupMap[config.CharacterId] = typeMap
        end

        local tabMap = typeMap[config.RecommendType]
        if not tabMap then
            tabMap = {}
            typeMap[config.RecommendType] = tabMap
        end

        tabMap[config.TabId] = config
    end
end

-----------------------补强技能相关-----------------------
local function CreateEnhanceSkillGradeDic()
    EnhanceSkillGradeDic = {}
    local gradeConfig = XCharacterConfigs.GetEnhanceSkillGradeConfig()

    for _,cfg in pairs(gradeConfig or {}) do
        EnhanceSkillGradeDic[cfg.SkillId] = EnhanceSkillGradeDic[cfg.SkillId] or {}
        EnhanceSkillGradeDic[cfg.SkillId][cfg.Level] = cfg
    end
end

local function CreateEnhanceSkillGradeDescDic()
    EnhanceSkillGradeDescDic = {}
    local gradeDesConfig = XCharacterConfigs.GetEnhanceSkillGradeDescConfig()

    for _,cfg in pairs(gradeDesConfig or {}) do
        EnhanceSkillGradeDescDic[cfg.SkillId] = EnhanceSkillGradeDescDic[cfg.SkillId] or {}
        EnhanceSkillGradeDescDic[cfg.SkillId][cfg.Level] = cfg
    end
end

local function CreateEnhanceSkillLevelEffectDic()
    EnhanceSkillLevelEffectDic = {}
    local levelEffectConfig = XCharacterConfigs.GetEnhanceSkillLevelEffectConfig()

    for _,cfg in pairs(levelEffectConfig or {}) do
        EnhanceSkillLevelEffectDic[cfg.SkillId] = EnhanceSkillLevelEffectDic[cfg.SkillId] or {}
        EnhanceSkillLevelEffectDic[cfg.SkillId][cfg.Level] = cfg
    end
end

local function CreateEnhanceSkillMaxLevelDic()
    EnhanceSkillMaxLevelDic = {}
    
    local skillGradeConfig = XCharacterConfigs.GetEnhanceSkillGradeConfig()

    for _,cfg in pairs(skillGradeConfig or {}) do
        EnhanceSkillMaxLevelDic[cfg.SkillId] = EnhanceSkillMaxLevelDic[cfg.SkillId] or 0
        if cfg.Level > EnhanceSkillMaxLevelDic[cfg.SkillId] then
            EnhanceSkillMaxLevelDic[cfg.SkillId] = cfg.Level
        end
    end
end

local IntEnhanceSkillConfig = function()
    EnhanceSkillConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_ENHANCESKILL, XTable.XTableCharacterSkill, "CharacterId")
    EnhanceSkillGroupConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_ENHANCESKILL_GROUP, XTable.XTableCharacterSkillGroup, "Id")
    EnhanceSkillEntryConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_ENHANCESKILL_ENTRY, XTable.XTableCharacterSkillEntry, "Id")
    EnhanceSkillGradeConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_ENHANCESKILL_GRADE, XTable.XTableEnhanceSkillUpgrade, "Id")
    EnhanceSkillGradeDescConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_ENHANCESKILL_GRADE_DES, XTable.XTableEnhanceSkillUpgradeDes, "Id")
    EnhanceSkillTypeInfoConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_ENHANCESKILL_TYPE_INFO, XTable.XTableCharacterSkillTypeInfo, "Type")
    EnhanceSkillPosConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_ENHANCESKILL_POS, XTable.XTableCharacterPos, "CharacterId")
    EnhanceSkillLevelEffectConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_ENHANCESKILL_LEVEL, XTable.XTableCharacterSkillLevelEffect, "Id")
    EnhanceSkillTypeConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_ENHANCESKILL_TYPE, XTable.XTableCharacterSkillType, "Id")

    CreateEnhanceSkillGradeDic()
    CreateEnhanceSkillGradeDescDic()
    CreateEnhanceSkillLevelEffectDic()
    CreateEnhanceSkillMaxLevelDic()
end
--------------------------------------------------------------------------------------------------------------------
function XCharacterConfigs.Init()
    CharDetailTemplates = XTableManager.ReadByIntKey(TABLE_CHARACTER_DETAIL, XTable.XTableCharDetail, "Id")
    CharTeachSkill = XTableManager.ReadByIntKey(TABLE_CHARACTER_SKILL_TEACH, XTable.XTableCharacterSkillTeach, "Id")
    CharElementTemplates = XTableManager.ReadByIntKey(TABLE_CHARACTER_ELEMENT_CONFIG, XTable.XTableCharacterElement, "Id")
    CharGraphTemplates = XTableManager.ReadByIntKey(TABLE_CHARACTER_GRAPH_INFO, XTable.XTableGraph, "Id")
    CharacterRecommendTemplates = XTableManager.ReadByIntKey(TABLE_CHARACTER_DETAIL_PARNER, XTable.XTableCharacterRecommend, "Id")
    EquipRecommendTemplates = XTableManager.ReadByIntKey(TABLE_CHARACTER_DETAIL_EQUIP, XTable.XTableEquipRecommend, "Id")
    NpcTemplates = XTableManager.ReadByIntKey(TABLE_NPC_PATH, XTable.XTableNpc, "Id")
    CharacterCareerTemplates = XTableManager.ReadByIntKey(TABLE_CHARACTER_CAREER_PATH, XTable.XTableNpcTypeIcon, "Type")
    CharacterSkillEntryConfig = XTableManager.ReadByIntKey(TABLE_CHARACTER_SKILL_ENTRY, XTable.XTableCharacterSkillEntry, "Id")
    
    local templates = XTableManager.ReadByIntKey(TABLE_CHARACTER_RECOMMEND_TAB_CONFIG, XTable.XTableCharacterTabId, "Id")
    InitRecommendConfig(templates)

    InitCharLevelConfig()
    InitCharQualityConfig()
    IniCharQualityFragmentConfig()
    InitCharSkillQualityApart()
    InitCharLiberationConfig()
    InitCharGradeConfig()
    IntCharSubSkillConfig()
    InitCharacterSkillPoolConfig()
    IntEnhanceSkillConfig()
end

local GetCharQualityFragmentConfig = function(characterType, quality)
    local characterTypeConfig = CharQualityFragmentTemplates[characterType]
    if not characterTypeConfig then
        XLog.Error("XCharacterConfigs GetCharQualityFragmentConfig error:配置不存在, : " .. characterType .. ", 配置路径: " .. TABLE_CHARACTER_QUALITY_FRAGMENT_PATH)
        return
    end

    local config = characterTypeConfig[quality]
    if not config then
        XLog.Error("XCharacterConfigs GetCharQualityFragmentConfig error:配置不存在, : " .. quality .. ", 配置路径: " .. TABLE_CHARACTER_QUALITY_FRAGMENT_PATH)
        return
    end

    return config
end

local function GetGroupSkillIds(skillGroupId)
    return CharSkillGroupDic[skillGroupId] or {}
end
XCharacterConfigs.GetGroupSkillIdsByGroupId = GetGroupSkillIds

function XCharacterConfigs.GetChracterSkillPosToGroupIdDic(characterId)
    local config = CharacterSkillDictTemplates[characterId]
    if not config then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetSkillGroupIds",
        "CharacterSkillDictTemplates", TABLE_CHARACTER_SKILL, "templateId", characterId)
        return
    end
    return config
end

function XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
    local skillInfo = CharSkillIdToGroupDic[skillId]
    if not skillInfo then return end
    return skillInfo.GroupId, skillInfo.Index
end

function XCharacterConfigs.GetGroupSkillIds(skillId)
    local skillGroupId = XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
    if not skillGroupId then return {} end
    return GetGroupSkillIds(skillGroupId)
end

function XCharacterConfigs.CanSkillSwith(skillId)
    return #XCharacterConfigs.GetGroupSkillIds(skillId) > 1
end

function XCharacterConfigs.GetGroupDefaultSkillId(skillGroupId)
    return GetGroupSkillIds(skillGroupId)[1] or 0
end

function XCharacterConfigs.GetCharacterSkills(templateId, clientLevel, selectSubSkill)
    local character = XMVCA.XCharacter:GetCharacter(templateId)
    return XMVCA.XCharacter:GetCharacterSkillsByCharacter(character, clientLevel, selectSubSkill)
end

function XCharacterConfigs.GetCharDetailParnerTemplate(templateId)
    local config = CharacterRecommendTemplates[templateId]
    if not config then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetCharDetailParnerTemplate",
        "CharacterRecommendTemplates", TABLE_CHARACTER_DETAIL_EQUIP, "templateId", tostring(templateId))
    end
    return config
end

function XCharacterConfigs.GetCharacterRecommendListByIds(ids)
    local list = {}
    for _, id in ipairs(ids) do
        local config = XCharacterConfigs.GetCharDetailParnerTemplate(id)
        if config then
            tableInsert(list, config)
        end
    end

    tableSort(list, voteNumSort)

    return list
end

function XCharacterConfigs.GetCharDetailEquipTemplate(templateId)
    local config = EquipRecommendTemplates[templateId]
    if not config then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetCharDetailEquipTemplate",
        "EquipRecommendTemplates", TABLE_CHARACTER_DETAIL_PARNER, "templateId", tostring(templateId))
    end
    return config
end

function XCharacterConfigs.GetEquipRecommendListByIds(ids)
    local list = {}
    for _, id in ipairs(ids) do
        local config = XCharacterConfigs.GetCharDetailEquipTemplate(id)
        if config then
            tableInsert(list, config)
        end
    end

    tableSort(list, voteNumSort)

    return list
end

function XCharacterConfigs.GetRecommendTabList(characterId, recommendType)
    local tabIdList = {}
    local typeMap = CharacterTabToVoteGroupMap[characterId]
    if typeMap then
        local tabMap = typeMap[recommendType]
        if tabMap then
            for tmpRecommendType, _ in pairs(tabMap) do
                tableInsert(tabIdList, tmpRecommendType)
            end
        end
    end

    if not next(tabIdList) then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetRecommendTabList",
        "CharacterTabToVoteGroupMap", TABLE_CHARACTER_RECOMMEND_TAB_CONFIG, "CharacterId", tostring(characterId))

        return nil
    end

    tableSort(tabIdList)
    return tabIdList
end

function XCharacterConfigs.GetRecommendTabTemplate(characterId, tabId, recommendType)
    local typeMap = CharacterTabToVoteGroupMap[characterId]
    if not typeMap then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetRecommendTabTemplate",
        "CharacterTabToVoteGroupMap", TABLE_CHARACTER_RECOMMEND_TAB_CONFIG, "characterId", tostring(characterId))
        return nil
    end

    local tabMap = typeMap[recommendType]
    if not tabMap then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetRecommendTabTemplate",
        "typeMap", TABLE_CHARACTER_RECOMMEND_TAB_CONFIG, "recommendType", tostring(recommendType))
        return nil
    end

    local config = tabMap[tabId]
    if not config then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetRecommendTabTemplate",
        "tabMap", TABLE_CHARACTER_RECOMMEND_TAB_CONFIG, "tabId", tostring(tabId))
        return nil
    end

    return config
end

function XCharacterConfigs.GetRecommendGroupId(characterId, tabId, recommendType)
    local typeMap = CharacterTabToVoteGroupMap[characterId]
    if not typeMap then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetRecommendGroupId",
        "CharacterTabToVoteGroupMap", TABLE_CHARACTER_RECOMMEND_TAB_CONFIG, "characterId", tostring(characterId))
        return
    end

    local tabMap = typeMap[recommendType]
    if not tabMap then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetRecommendGroupId",
        "typeMap", TABLE_CHARACTER_RECOMMEND_TAB_CONFIG, "recommendType", tostring(recommendType))
        return
    end

    local config = tabMap[tabId]
    if not config then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetRecommendGroupId", "tabMap", TABLE_CHARACTER_RECOMMEND_TAB_CONFIG, "tabId", tostring(tabId))
        return
    end

    return config.GroupId
end

function XCharacterConfigs.GetRecommendTabMap(characterId, recommendType)
    local typeMap = CharacterTabToVoteGroupMap[characterId]
    if not typeMap then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetRecommendTabMap",
        "CharacterTabToVoteGroupMap", TABLE_CHARACTER_RECOMMEND_TAB_CONFIG, "characterId", tostring(characterId))
        return
    end

    local tabMap = typeMap[recommendType]
    if not tabMap then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetRecommendTabMap",
        "typeMap", TABLE_CHARACTER_RECOMMEND_TAB_CONFIG, "recommendType", tostring(recommendType))
        return
    end

    return tabMap
end

function XCharacterConfigs.GetAllCharElments()
    return CharElementTemplates
end

---@return XTableCharacterElement
function XCharacterConfigs.GetCharElement(elementId)
    local template = CharElementTemplates[elementId]
    if template == nil then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetCharElement",
        "CharElementTemplates", TABLE_CHARACTER_ELEMENT_CONFIG, "elementId", tostring(elementId))
        return
    end
    return template
end

function XCharacterConfigs.GetAllCharacterCareerIds()
    local typeIds = {}
    for id, _ in pairs(CharacterCareerTemplates) do
        tableInsert(typeIds, id)
    end
    return typeIds
end

function XCharacterConfigs.GetNpcTypeTemplate(typeId)
    local config = CharacterCareerTemplates[typeId]
    if not config then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetNpcTypeTemplate",
        "CharacterCareerTemplates", TABLE_CHARACTER_CAREER_PATH, "typeId", tostring(typeId))
        return
    end

    return config
end

function XCharacterConfigs.GetCareerName(typeId)
    local config = XCharacterConfigs.GetNpcTypeTemplate(typeId)
    return config.Name
end

function XCharacterConfigs.GetCareerDes(typeId)
    local config = XCharacterConfigs.GetNpcTypeTemplate(typeId)
    return config.Des
end

function XCharacterConfigs.GetNpcTypeIcon(typeId)
    local config = XCharacterConfigs.GetNpcTypeTemplate(typeId)
    return config.Icon
end

function XCharacterConfigs.GetNpcTypeIconTranspose(typeId)
    local config = XCharacterConfigs.GetNpcTypeTemplate(typeId)
    return config.IconTranspose
end

function XCharacterConfigs.GetNpcTypeShowId(typeId)
    local config = XCharacterConfigs.GetNpcTypeTemplate(typeId)
    return config.ShowId
end

function XCharacterConfigs.GetNpcTypeSortId(typeId)
    local config = XCharacterConfigs.GetNpcTypeTemplate(typeId)
    return config.SortId
end
-- 卡牌信息begin --

function XCharacterConfigs.IsIsomer(templateId)
    if not XTool.IsNumberValid(templateId) then return false end
    return XMVCA.XCharacter:GetCharacterType(templateId) == XCharacterConfigs.CharacterType.Isomer
end


-- 卡牌信息end --
-- 升级相关begin --
function XCharacterConfigs.GetLevelUpTemplate(levelUpTemplateId)
    return LevelUpTemplates[levelUpTemplateId]
end

-- 升级相关end --

--===========================================================================
-- v1.28 品质升阶相关begin
--===========================================================================
function XCharacterConfigs.GetCharQualityIconGoods(quality)
    if not quality or quality < 1 then
        XLog.Error("XCharacterConfigs.GetCharQualityIconGoods函数参数不规范，参数是quality：" .. quality)
        return
    end

    local template = CharQualityIconTemplates[quality]
    if not template then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetCharQualityIconGoods",
        "CharQualityIconTemplates", TABLE_CHARACTER_QUALITY_ICON_PATH, "quality", tostring(quality))
        return
    end

    return template.IconGoods
end

function XCharacterConfigs.GetCharQualityDesc(quality)
    if not quality or quality < 1 then
        XLog.Error("XCharacterConfigs.GetCharQualityIcon函数参数不规范，参数是quality：" .. quality)
        return
    end

    local template = CharQualityIconTemplates[quality]
    if not template then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetCharQualityDesc",
        "CharQualityIconTemplates", TABLE_CHARACTER_QUALITY_ICON_PATH, "quality", tostring(quality))
        return
    end

    return template.Desc
end

function XCharacterConfigs.GetDecomposeCount(characterType, quality)
    local config = GetCharQualityFragmentConfig(characterType, quality)
    return config.DecomposeCount
end

function XCharacterConfigs.GetComposeCount(characterType, quality)
    local config = GetCharQualityFragmentConfig(characterType, quality)
    return config.ComposeCount
end

function XCharacterConfigs.GetStarUseCount(characterType, quality, star)
    if not quality or quality < 1 then
        XLog.Error("XCharacterConfigs.GetStarUseCount函数参数不规范，参数是quality：" .. quality)
        return
    end

    if not star or (star < 1 or star > XEnumConst.CHARACTER.MAX_QUALITY_STAR) then
        XLog.Error("XCharacterConfigs.GetStarUseCount函数参数不规范，参数是star：" .. star)
        return
    end

    local config = GetCharQualityFragmentConfig(characterType, quality)
    local starUseCount = config.StarUseCount
    return starUseCount[star] or 0
end

function XCharacterConfigs.GetPromoteUseCoin(characterType, quality)
    local config = GetCharQualityFragmentConfig(characterType, quality)
    return config.PromoteUseCoin
end

function XCharacterConfigs.GetPromoteItemId(characterType, quality)
    local config = GetCharQualityFragmentConfig(characterType, quality)
    return config.PromoteItemId
end

function XCharacterConfigs.GetCharGraphTemplate(graphId)
    local template = CharGraphTemplates[graphId]
    if not template then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetCharGraphTemplate",
        "CharGraphTemplates", TABLE_CHARACTER_GRAPH_INFO, "graphId", tostring(graphId))
        return
    end
    return template
end

--=======升阶拆分============================================================
--返回 某一角色所有技能升阶数据
function XCharacterConfigs.GetCharSkillQualityApartDicByCharacterId(characterId)
    if not characterId then
        XLog.Error("XCharacterConfigs.GetCharSkillQualityApartTemplateByCharacterId函数参数characterId不能为空")
        return
    end
    local config = CharSkillQualityApartDic[characterId]
    return config or {}
end

--返回 某一角色某一品质下所有技能升阶数据
function XCharacterConfigs.GetCharSkillQualityApartDicByQuality(characterId, quality)
    if not quality then
        XLog.Error("XCharacterConfigs.GetCharSkillQualityApartTemplateByQuality函数参数quality不能为空")
        return
    end
    local config = XCharacterConfigs.GetCharSkillQualityApartDicByCharacterId(characterId)
    return config[quality] or {}
end

--返回 某一角色某一品质某一星级的技能升阶数据
function XCharacterConfigs.GetCharSkillQualityApartDicByStar(characterId, quality, star)
    if not star then
        XLog.Error("XCharacterConfigs.GetCharSkillQualityApartTemplate函数参数star不能为空")
        return
    end
    local config = XCharacterConfigs.GetCharSkillQualityApartDicByQuality(characterId, quality)
    return config[star] or {}
end

function XCharacterConfigs.GetCharSkillQualityApartTemplate(Id)
    local config = CharSkillQualityApart[Id]
    return config
end

function XCharacterConfigs.GetCharSkillQualityApartQuality(Id)
    local config = CharSkillQualityApart[Id]
    return config.Quality
end

function XCharacterConfigs.GetCharSkillQualityApartPhase(Id)
    local config = CharSkillQualityApart[Id]
    return config.Phase
end

function XCharacterConfigs.GetCharSkillQualityApartLevel(Id)
    local config = CharSkillQualityApart[Id]
    return config.Level
end

function XCharacterConfigs.GetCharSkillQualityApartName(Id)
    local config = CharSkillQualityApart[Id]
    return config.Name
end

function XCharacterConfigs.GetCharSkillQualityApartIntro(Id)
    local config = CharSkillQualityApart[Id]
    return config.Intro
end

-- 升阶拆分获取跳转技能Id
function XCharacterConfigs.GetCharSkillQualityApartSkillId(Id)
    local config = CharSkillQualityApart[Id]
    return config.SkillId
end
--===========================================================================
-- v1.28 品质升阶相关end
--===========================================================================

-- 改造相关begin --
function XCharacterConfigs.GetQualityUpgradeItemId(templateId, grade)
    return CharGradeTemplates[templateId][grade].UseItemId
end

function XCharacterConfigs.GetCharGradeIcon(templateId, grade)
    return CharGradeTemplates[templateId][grade].GradeIcon
end

function XCharacterConfigs.GetGradeTemplates(templateId, grade)
    return CharGradeTemplates[templateId][grade]
end

function XCharacterConfigs.GetCharGradeName(templateId, grade)
    grade = grade or XMVCA.XCharacter:GetCharMinGrade(templateId)
    return CharGradeTemplates[templateId][grade].GradeName
end

function XCharacterConfigs.GetCharGradeUseMoney(templateId, grade)
    local consumeItem = {}
    consumeItem.Id = CharGradeTemplates[templateId][grade].UseItemKey
    consumeItem.Count = CharGradeTemplates[templateId][grade].UseItemCount
    return consumeItem
end

function XCharacterConfigs.GetCharGradeAttrId(templateId, grade)
    if not templateId or not grade then
        XLog.Error("XCharacterConfigs.GetCharGradeAttrId函数参数错误，templateId为空或者grade为空")
        return
    end

    local template = CharGradeTemplates[templateId]
    if not template then
        return
    end

    if template[grade] then
        if template[grade].AttrId and template[grade].AttrId > 0 then
            return template[grade].AttrId
        end
    end
end

function XCharacterConfigs.GetNeedPartsGrade(templateId, grade)
    return CharGradeTemplates[templateId][grade].PartsGrade
end

function XCharacterConfigs.GetSubSkillMinMaxLevel(subSkillId)
    return SubSkillMinMaxLevelDicGrade[subSkillId]
end

-- 副技能最小最大等级配置(from TABLE_CHARACTER_SKILL_GRADE)
function XCharacterConfigs.ClampSubSkillLevelByGrade(skillId, skillLevel)
    local fixSkillLevel = skillLevel
    if SubSkillMinMaxLevelDicGrade[skillId].Max < fixSkillLevel then
        fixSkillLevel = SubSkillMinMaxLevelDicGrade[skillId].Max
    elseif SubSkillMinMaxLevelDicGrade[skillId].Min > fixSkillLevel then
        fixSkillLevel = SubSkillMinMaxLevelDicGrade[skillId].Min
    end
    return fixSkillLevel
end

-- 副技能最小最大等级配置(from TABLE_CHARACTER_SKILL_LEVEL)
function XCharacterConfigs.ClampSubSkillLeveByLevel(skillId, skillLevel)
    local fixSkillLevel = skillLevel
    if SubSkillMinMaxLevelDicLevel[skillId].Max < fixSkillLevel then
        fixSkillLevel = SubSkillMinMaxLevelDicLevel[skillId].Max
    elseif SubSkillMinMaxLevelDicLevel[skillId].Min > fixSkillLevel then
        fixSkillLevel = SubSkillMinMaxLevelDicLevel[skillId].Min
    end
    return fixSkillLevel
end

function XCharacterConfigs.GetCharTeachById(charId)
    return CharTeachSkill[charId]
end

--战中设置
function XCharacterConfigs.GetCharTeachIconById(charId)
    local cfg = CharTeachSkill[charId]
    return cfg and cfg.TeachIcon or nil
end

--战中设置
function XCharacterConfigs.GetCharTeachDescriptionById(charId)
    local cfg = CharTeachSkill[charId]
    return cfg and cfg.Description or {}
end

-- 战中设置
function XCharacterConfigs.GetCharTeachHeadLineById(charId)
    local cfg = CharTeachSkill[charId]
    return cfg and cfg.HeadLine or {}
end

function XCharacterConfigs.GetCharTeachStageIdById(charId)
    local cfg = CharTeachSkill[charId]
    return cfg and cfg.StageId
end

function XCharacterConfigs.GetCharTeachWebUrlById(charId)
    local cfg = CharTeachSkill[charId]
    return cfg and cfg.WebUrl
end

function XCharacterConfigs.GetSubSkillAbility(subSkillId, level)
    local config = XCharacterConfigs.GetSkillLevelEffectTemplate(subSkillId, level)
    return config and config.Ability or 0
end

function XCharacterConfigs.GetResonanceSkillAbility(subSkillId, level)
    local config = XCharacterConfigs.GetSkillLevelEffectTemplate(subSkillId, level)
    return config and config.ResonanceAbility or 0
end

function XCharacterConfigs.GetPlusSkillAbility(subSkillId, level)
    local config = XCharacterConfigs.GetSkillLevelEffectTemplate(subSkillId, level)
    return config and config.PlusAbility or 0
end

function XCharacterConfigs.GetSkillLevelEffectTemplate(skillId, level)
    local subSkills = CharSkillLevelEffectDict[skillId]
    if (not subSkills) then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetSkillLevelEffectTemplate",
        "CharSkillLevelEffectDict", TABLE_CHARACTER_SKILL_LEVEL, "skillId", tostring(skillId))
        return
    end

    local config = subSkills[level]
    if not config then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetSkillLevelEffectTemplate",
        "CharSkillLevelEffectDict", TABLE_CHARACTER_SKILL_LEVEL, "skillId  : level", tostring(skillId) .. " : " .. tostring(level))
        return
    end

    return config
end

function XCharacterConfigs.GetSkillGradeConfig(subSkillId, subSkillLevel)
    local skillLevelDict = CharSkillLevelDict[subSkillId]
    if not skillLevelDict then
        return
    end

    local tabId = skillLevelDict[subSkillLevel]
    if not tabId then
        return
    end

    return SkillGradeConfig[tabId]
end

-- V1.29 返回详情描述的整合，原技能描述配置字段Intro字段配置表里已删除，该接口是为了兼容旧版Intro字段。
-- 技能描述请使用新字段BriefDes 简略 和SpecificDes 详情 两字段
-- GetCharacterSkillsByCharacter 接口的configDes信息里不包含Intro字段信息
function XCharacterConfigs.GetGradeDesConfigIntro(gradeDesConfig)
    local tempData = nil
    for index, specificDes in pairs(gradeDesConfig.SpecificDes or {}) do
        local title = gradeDesConfig.Title[index]
        tempData = tempData and tempData .. "\n" or ""
        title = title and title .. "\n" or ""
        tempData = string.format("%s%s%s", tempData, title, specificDes)
    end
    return XUiHelper.ConvertLineBreakSymbol(tempData)
end

function XCharacterConfigs.GetSkillGradeDesConfigWeaponSkillDes(subSkillId, subSkillLevel)
    local config = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(subSkillId, subSkillLevel)
    return config.WeaponSkillDes
end

--获取角色技能词条描述列表
function XCharacterConfigs.GetSkillGradeDesConfigEntryList(subSkillId, subSkillLevel)
    local entryList = {}
    local config = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(subSkillId, subSkillLevel)
    for _, entryId in ipairs(config.EntryId) do
        if XTool.IsNumberValid(entryId) then
            tableInsert(entryList, {
                Name = XCharacterConfigs.GetSkillEntryName(entryId),
                Desc = XCharacterConfigs.GetSkillEntryDesc(entryId),
            })
        end
    end
    return entryList
end
-------------角色详细相关------------------
function XCharacterConfigs.GetCharDetailTemplate(templateId)
    return CharDetailTemplates[templateId]
end

function XCharacterConfigs.GetCharDetailCareer(templateId)
    local config = XCharacterConfigs.GetCharDetailTemplate(templateId)
    return config and config.Career
end

function XCharacterConfigs.GetCharFullBodyImg(templateId)
    local config = XCharacterConfigs.GetCharDetailTemplate(templateId)
    return config and config.FullBodyImg
end

function XCharacterConfigs.GetCharDetailObtainElementList(templateId)
    local config = XCharacterConfigs.GetCharDetailTemplate(templateId)
    return config and config.ObtainElementList
end

function XCharacterConfigs.GetCharacterSkillPoolSkillInfo(skillId)
    if not CharSkillPoolSkillIdDic[skillId] then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetCharacterSkillPoolSkillInfo",
        "CharSkillPoolSkillIdDic", TABLE_CHARACTER_SKILL_POOL, "skillId", tostring(skillId))
    end

    return CharSkillPoolSkillIdDic[skillId]
end

function XCharacterConfigs.GetCharacterIdBySkillId(skillId)
    local skillGroupId = XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
    return CharSkillIdToCharacterIdDic[skillGroupId]
end

function XCharacterConfigs.GetCharacterSkillPoolSkillInfos(poolId, characterId)
    local skillInfos = {}

    if not CharPoolIdToSkillInfoDic[poolId] then return skillInfos end
    for _, skillInfo in pairs(CharPoolIdToSkillInfoDic[poolId]) do
        local skillId = skillInfo.SkillId
        local skillGroupId = XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
        if characterId and skillGroupId and CharSkillIdToCharacterIdDic[skillGroupId] == characterId then
            tableInsert(skillInfos, skillInfo)
        end
    end

    return skillInfos
end

function XCharacterConfigs.GetNpcTemplate(id)
    local template = NpcTemplates[id]
    if not template then
        XLog.ErrorTableDataNotFound("XCharacterConfigs.GetNpcTemplate", "NpcTemplates", TABLE_NPC_PATH, "id", tostring(id))
        return
    end

    return template
end

local function GetCharLiberationConfig(characterId, growUpLevel)
    local config = CharLiberationTemplates[tonumber(characterId)]
    if not config then
        return
    end

    config = config[growUpLevel]
    if not config then
        return
    end

    return config
end

function XCharacterConfigs.GetCharLiberationLevelModelId(characterId, growUpLevel)
    local config = GetCharLiberationConfig(characterId, growUpLevel)
    return config and config.ModelId
end

function XCharacterConfigs.GetCharLiberationLevelModelId(characterId, growUpLevel)
    local config = GetCharLiberationConfig(characterId, growUpLevel)
    return config and config.ModelId
end

function XCharacterConfigs.GetCharLiberationLevelEffectRootAndPath(characterId, growUpLevel)
    local config = GetCharLiberationConfig(characterId, growUpLevel)
    if not config then return end
    return config.EffectRootName, config.EffectPath
end

function XCharacterConfigs.GetCharLiberationLevelTitle(characterId, growUpLevel)
    local config = GetCharLiberationConfig(characterId, growUpLevel)
    return config and config.Title or ""
end

function XCharacterConfigs.GetCharLiberationLevelDesc(characterId, growUpLevel)
    local config = GetCharLiberationConfig(characterId, growUpLevel)
    return config and config.Desc or ""
end

function XCharacterConfigs.GetCharMaxLiberationSkillGroupId(characterId)
    return CharMaxLiberationSkillIdDic[characterId]
end

function XCharacterConfigs.GetSkillTypePlusTemplate(id)
    return SkillTypePlusConfig[id]
end

function XCharacterConfigs.GetSkillTypeName(id)
    local cfg = SkillTypeInfoConfig[id]
    return cfg and cfg.Name or ""
end

function XCharacterConfigs.GetSkillType(skillId)
    local cfg = CharacterSkillType[skillId]
    return cfg and cfg.Type or 0
end

function XCharacterConfigs.GetSkillPlusList(characterId, charType, plusId)
    local skillTemplate = CharSkillTemplates[characterId]
    if not skillTemplate then
        return
    end

    local plusTemplate = XCharacterConfigs.GetSkillTypePlusTemplate(plusId)
    if not plusTemplate then
        return
    end

    local isValidType = false
    for _, type in pairs(plusTemplate.CharacterType) do
        if type == charType then
            isValidType = true
            break
        end
    end

    if not isValidType then
        return
    end

    local plusList = {}
    for _, skillGroupId in pairs(skillTemplate.SkillGroupId) do
        local skillIds = GetGroupSkillIds(skillGroupId)
        for _, skillId in pairs(skillIds) do
            local type = XCharacterConfigs.GetSkillType(skillId)
            if type ~= 0 then
                for _, skillType in pairs(plusTemplate.SkillType) do
                    if skillType == type then
                        tableInsert(plusList, skillId)
                        break
                    end
                end
            end
        end
    end

    return plusList
end

function XCharacterConfigs.GetCharacterElementPath()
    return TABLE_CHARACTER_ELEMENT_CONFIG
end

-- 获取NpcId对应的职业类型, 只能用于提示
function XCharacterConfigs.GetCharacterCareerType(npcId)
    local npcTemplate = XCharacterConfigs.GetNpcTemplate(npcId)
    local realType = Career2CareerType[npcTemplate.Type]
    return realType and realType or npcTemplate.Type
end

--技能词条 begin--
local function GetSkillEntryConfig(entryId)
    local config = CharacterSkillEntryConfig[entryId]
    if not config then
        XLog.Error("XCharacterConfigs GetSkillEntryConfig error:配置不存在, entryId: " .. entryId .. ", 配置路径: " .. TABLE_CHARACTER_SKILL_ENTRY)
        return
    end
    return config
end

function XCharacterConfigs.GetSkillEntryName(entryId)
    local config = GetSkillEntryConfig(entryId)
    return config.Name
end

function XCharacterConfigs.GetSkillEntryDesc(entryId)
    local config = GetSkillEntryConfig(entryId)
    return XUiHelper.ConvertLineBreakSymbol(config.Description)
end
--技能词条 end--
-----------------------补强技能相关-----------------------

function XCharacterConfigs.GetEnhanceSkillGradeBySkillIdAndLevel(skillId, level)
    if not EnhanceSkillGradeDic[skillId] then
        XLog.Error("skillId Is Not Exist In "..TABLE_CHARACTER_ENHANCESKILL_GRADE..":"..skillId)
        return
    end
    return EnhanceSkillGradeDic[skillId][level]
end

function XCharacterConfigs.GetEnhanceSkillGradeDescBySkillIdAndLevel(skillId, level)
    if not EnhanceSkillGradeDescDic[skillId] then
        XLog.Error("skillId Is Not Exist In "..TABLE_CHARACTER_ENHANCESKILL_GRADE_DES..":"..skillId)
        return
    end
    return EnhanceSkillGradeDescDic[skillId][level]
end

function XCharacterConfigs.GetEnhanceSkillLevelEffectBySkillIdAndLevel(skillId, level)
    if not EnhanceSkillLevelEffectDic[skillId] then
        XLog.Error("skillId Is Not Exist In "..TABLE_CHARACTER_ENHANCESKILL_LEVEL..":"..skillId)
        return
    end
    return EnhanceSkillLevelEffectDic[skillId][level]
end

function XCharacterConfigs.GetEnhanceSkillMaxLevelBySkillId(skillId)
    if not EnhanceSkillMaxLevelDic[skillId] then
        XLog.Error("skillId Is Not Exist In "..TABLE_CHARACTER_ENHANCESKILL_LEVEL..":"..skillId)
        return
    end
    return EnhanceSkillMaxLevelDic[skillId]
end

function XCharacterConfigs.GetEnhanceSkillConfig(CharacterId)
    local cfg
    if CharacterId then
        cfg = EnhanceSkillConfig[CharacterId]
    else
        cfg = EnhanceSkillConfig
    end
    if CharacterId and not cfg then
        XLog.Error("CharacterId Is Not Exist In "..TABLE_CHARACTER_ENHANCESKILL..":"..CharacterId)
    end
    return cfg
end

function XCharacterConfigs.GetEnhanceSkillGroupConfig(Id)
    local cfg
    if Id then
        cfg = EnhanceSkillGroupConfig[Id]
    else
        cfg = EnhanceSkillGroupConfig
    end
    if Id and not cfg then
        XLog.Error("Id Is Not Exist In "..TABLE_CHARACTER_ENHANCESKILL_GROUP..":"..Id)
    end
    return cfg
end

function XCharacterConfigs.GetEnhanceSkillEntryConfig(Id)
    local cfg
    if Id then
        cfg = EnhanceSkillEntryConfig[Id]
    else
        cfg = EnhanceSkillEntryConfig
    end
    if Id and not cfg then
        XLog.Error("Id Is Not Exist In "..TABLE_CHARACTER_ENHANCESKILL_ENTRY..":"..Id)
    end
    return cfg
end

function XCharacterConfigs.GetEnhanceSkillGradeConfig(Id)
    local cfg
    if Id then
        cfg = EnhanceSkillGradeConfig[Id]
    else
        cfg = EnhanceSkillGradeConfig
    end
    if Id and not cfg then
        XLog.Error("Id Is Not Exist In "..TABLE_CHARACTER_ENHANCESKILL_GRADE..":"..Id)
    end
    return cfg
end

function XCharacterConfigs.GetEnhanceSkillGradeDescConfig(Id)
    local cfg
    if Id then
        cfg = EnhanceSkillGradeDescConfig[Id]
    else
        cfg = EnhanceSkillGradeDescConfig
    end
    if Id and not cfg then
        XLog.Error("Id Is Not Exist In "..TABLE_CHARACTER_ENHANCESKILL_GRADE_DES..":"..Id)
    end
    return cfg
end

function XCharacterConfigs.GetEnhanceSkillTypeInfoConfig(Type)
    local cfg
    if Type then
        cfg = EnhanceSkillTypeInfoConfig[Type]
    else
        cfg = EnhanceSkillTypeInfoConfig
    end
    if Type and not cfg then
        XLog.Error("Type Is Not Exist In "..TABLE_CHARACTER_ENHANCESKILL_TYPE_INFO..":"..Type)
    end
    return cfg
end

function XCharacterConfigs.GetEnhanceSkillPosConfig(CharacterId)
    local cfg
    if CharacterId then
        cfg = EnhanceSkillPosConfig[CharacterId]
    else
        cfg = EnhanceSkillPosConfig
    end
    if CharacterId and not cfg then
        XLog.Error("CharacterId Is Not Exist In "..TABLE_CHARACTER_ENHANCESKILL_POS..":"..CharacterId)
    end
    return cfg
end

function XCharacterConfigs.GetEnhanceSkillLevelEffectConfig(Id)
    local cfg
    if Id then
        cfg = EnhanceSkillLevelEffectConfig[Id]
    else
        cfg = EnhanceSkillLevelEffectConfig
    end
    if Id and not cfg then
        XLog.Error("Id Is Not Exist In "..TABLE_CHARACTER_ENHANCESKILL_LEVEL..":"..Id)
    end
    return cfg
end

function XCharacterConfigs.GetEnhanceSkillTypeConfig(Id)
    local cfg
    if Id then
        cfg = EnhanceSkillTypeConfig[Id]
    else
        cfg = EnhanceSkillTypeConfig
    end
    if Id and not cfg then
        XLog.Error("Id Is Not Exist In "..TABLE_CHARACTER_ENHANCESKILL_TYPE..":"..Id)
    end
    return cfg
end

function XCharacterConfigs.GetCharSkillGroupTemplates()
    return CharSkillGroupTemplates
end

function XCharacterConfigs.GetCharSkillGroupTemplatesById(id)
    return CharSkillGroupTemplates[id]
end