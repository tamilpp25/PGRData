---@class XCharacterModel : XModel
local XCharacterModel = XClass(XModel, "XCharacterModel")

-- character相关表的读取方式全部为normal
-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local CharacterTableKey = 
{
    Character = {},
    CharacterDetail = { DirPath = XConfigUtil.DirectoryType.Client , TableDefindName = "XTableCharDetail" },
    CharacterCareer = { Identifier = "Type" },
    CharacterGraph = { DirPath = XConfigUtil.DirectoryType.Client, TableDefindName = "XTableGraph", CacheType = XConfigUtil.CacheType.Private },
    CharacterRecommend = { DirPath = XConfigUtil.DirectoryType.Client },
    CharacterTabId = { DirPath = XConfigUtil.DirectoryType.Client },
    CharacterLiberation = { DirPath = XConfigUtil.DirectoryType.Client },
    CharacterLiberationIcon = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "LiberationLv" },
    CharacterElement = { DirPath = XConfigUtil.DirectoryType.Client },
    CharacterFilterController = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "UiName", ReadFunc = XConfigUtil.ReadType.String },
    CharacterQualityIcon = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Quality" }, 
}

local CharacterEnhanceSkillTableKey = 
{
    EnhanceSkill = { Identifier = "CharacterId", TableDefindName = "XTableCharacterSkill" },
    EnhanceSkillGroup = { TableDefindName = "XTableCharacterSkillGroup" },
    EnhanceSkillLevelEffect = { TableDefindName = "XTableCharacterSkillLevelEffect" },
    EnhanceSkillPos = { Identifier = "CharacterId", TableDefindName = "XTableCharacterPos" },
    EnhanceSkillType = { TableDefindName = "XTableCharacterSkillType" },
    -- EnhanceSkillTypePlus = { TableDefindName = "XTableCharacterSkillTypePlus" },
    EnhanceSkillUpgrade = {},
    EnhanceSkillEntry = { DirPath = XConfigUtil.DirectoryType.Client, TableDefindName = "XTableCharacterSkillEntry" },
    EnhanceSkillTypeInfo = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Type", TableDefindName = "XTableCharacterSkillTypeInfo" },
    EnhanceSkillUpgradeDes = { DirPath = XConfigUtil.DirectoryType.Client },
}

local CharacterGradeTableKey = 
{
    CharacterGrade = {},
}

local CharacterQualityTableKey = 
{
    CharacterQualityFragment = {},
    CharacterQuality = {},
    CharacterSkillQualityApart = { DirPath = XConfigUtil.DirectoryType.Client },
    CharacterSkillQualityBigEffectBall = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Quality", CacheType = XConfigUtil.CacheType.Private },
}

local CharacterSkillTableKey = 
{
    CharacterSkill = { Identifier = "CharacterId" },
    CharacterSkillGroup = {},
    -- CharacterSkillPos = {},
    CharacterSkillUpgrade = { CacheType = XConfigUtil.CacheType.Preload },
    CharacterSkillUpgradeDes = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Preload },
    CharacterSkillUpgradeDetail = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "RefId", },
    CharacterSkillExchangeDes = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "SkillLevelId", },
    CharacterSkillLevelEffect = { CacheType = XConfigUtil.CacheType.Preload },
    CharacterSkillType = {},
    CharacterSkillTypePlus = {},
    CharacterSkillPool = {},
    CharacterSkillEntry = { DirPath = XConfigUtil.DirectoryType.Client }, -- (可以将引用ui改为XUiNode后拆分，但是父级引用太多且不是XUiNode，可以后续考虑)
    CharacterSkillTeach = { DirPath = XConfigUtil.DirectoryType.Client },
    CharacterSkillGate = { DirPath = XConfigUtil.DirectoryType.Client },
    CharacterSkillTypeInfo = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Type" },
    CharacterGeneralSkill  = { DirPath = XConfigUtil.DirectoryType.Client },
}

function XCharacterModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    --定义TableKey
    self._ConfigUtil:InitConfigByTableKey("Character", CharacterTableKey, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey("Character/EnhanceSkill", CharacterEnhanceSkillTableKey, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey("Character/Grade", CharacterGradeTableKey, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey("Character/Quality", CharacterQualityTableKey, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey("Character/Skill", CharacterSkillTableKey, XConfigUtil.CacheType.Normal)

    -- 体验包保留角色
    self.IncludeCharacterIds = {
        [1021001] = true, -- 露西亚
        [1031001] = true, -- 丽芙
        [1051001] = true, -- 七实
        [1511003] = true, -- 卡穆
    }
    -- 基本职业类型索引
    self.Career2CareerType = {
        [5] = 3, -- 增幅型 -> 辅助型
    }

    self.IsHideFunc = CS.XRemoteConfig.IsHideFunc
    self.CharacterTemplatesCount = 1
    self.ItemIdToCharacterIdDic = {}
    self.LevelUpTemplates = {}
    self.CharBorderTemplates = {}               -- 边界属性
    self.CharQualityTemplates = {}              -- CharacterQuality.tab表的字典  [charId] = { [QualityA = value1, QualityB = value2 ....]}
    self.CharQualityFragmentTemplates = {}      -- 品质对应碎片
    self.EnhanceSkillLevelEffectDic = {}        -- 角色补强技能等级效果字典
    self.EnhanceSkillGradeDic = {}              -- 角色补强技能升级字典
    self.EnhanceSkillMaxLevelDic = {}           -- 角色补强技能最大等级字典
    self.EnhanceSkillGradeDescDic = {}          -- 角色补强技能升级描述字典
    self.CharGradeTemplates = {}                -- 角色阶级配置字典， k = charId = { grade1 = config1, grade2 = config2 ... }
    self.CharSkillQualityApartDic = {}          -- 角色升阶技能拆分字典
    self.CharSkillGroupDic = {}                 -- 角色技能组配置
    self.CharSkillIdToGroupDic = {}             -- 角色技能Id,技能组字典
    self.CharacterSkillDictTemplates = {}       -- 角色技能配置字典
    self.CharMaxLiberationSkillIdDic = {}       -- 角色终阶解放技能Id字典
    self.CharSkillIdToCharacterIdDic = {}       -- SkillId映射CharacterId字典
    self.CharSkillPoolSkillIdDic = {}           -- 角色技能共鸣池SkillId映射技能信息字典
    self.CharPoolIdToSkillInfoDic = {}          -- 角色技能共鸣池PoolId映射技能信息字典
    self.CharSkillLevelDict = {}                -- 角色技能Id，等级Id的属性表Map
    self.SubSkillMinMaxLevelDicGrade = {}       -- 副技能最小最大等级配置(from TABLE_CHARACTER_SKILL_GRADE)
    self.SubSkillMinMaxLevelDicLevel = {}       -- 副技能最小最大等级配置(from TABLE_CHARACTER_SKILL_LEVEL)
    self.CharSkillLevelEffectDict = {}
    self.CharLiberationTemplates = {}           -- 角色解放配置
    self.CharacterTabToVoteGroupMap = {}        -- 角色标签转投票组表
    self.TempWholeDic = {}                      -- 临时存放的字典，只记录不会变化的数据，重登不需要清除

    self:InitOwnCharacter()
    self:InitNpcTemplates()
    self:InitCharLevelConfig()
    self:InitCharacterRelatedData()
    -- self:InitEnhanceSkillLevelEffectDic()
    -- self:InitEnhanceSkillUpgradeRelated()
    -- self:InitEnhanceSkillGradeDescDic()
    self:InitCharQualityConfig()
    self:IniCharQualityFragmentConfig()
    self:InitCharGradeConfig()
    self:InitCharSkillQualityApart()
    self:InitSkillGroupDic()
    self:InitCharSkillIdToCharacterIdDic()
    self:InitCharacterSkillPoolConfig()
    self:InitSubSkillMinMaxLevelDicByCharacterSkillUpgrade()
    self:InitCharSkillLevelDict()
    self:InitCharLiberationConfig()
    self:InitRecommendConfig()
end

--region 基础读表
---@return XTableCharacterElement[]
function XCharacterModel:GetCharacterElement()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.CharacterElement)
end

function XCharacterModel:GetCharacterFilterController()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.CharacterFilterController)
end

function XCharacterModel:GetCharacterQualityIcon()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.CharacterQualityIcon)
end

function XCharacterModel:GetCharacterQualityIconByQuality(quality)
    local config = self._ConfigUtil:GetByTableKey(CharacterTableKey.CharacterQualityIcon)[quality]
    if not config then
        XLog.Error("Can not found quality in CharacterQualityIcon.tab", quality)
    end
    return config
end

function XCharacterModel:GetEnhanceSkill()
    return self._ConfigUtil:GetByTableKey(CharacterEnhanceSkillTableKey.EnhanceSkill)
end

function XCharacterModel:GetEnhanceSkillGroup()
    return self._ConfigUtil:GetByTableKey(CharacterEnhanceSkillTableKey.EnhanceSkillGroup)
end

function XCharacterModel:GetEnhanceSkillLevelEffect()
    return self._ConfigUtil:GetByTableKey(CharacterEnhanceSkillTableKey.EnhanceSkillLevelEffect)
end

function XCharacterModel:GetEnhanceSkillPos()
    return self._ConfigUtil:GetByTableKey(CharacterEnhanceSkillTableKey.EnhanceSkillPos)
end

function XCharacterModel:GetEnhanceSkillType()
    return self._ConfigUtil:GetByTableKey(CharacterEnhanceSkillTableKey.EnhanceSkillType)
end

function XCharacterModel:GetEnhanceSkillUpgrade()
    return self._ConfigUtil:GetByTableKey(CharacterEnhanceSkillTableKey.EnhanceSkillUpgrade)
end

function XCharacterModel:GetEnhanceSkillEntry()
    return self._ConfigUtil:GetByTableKey(CharacterEnhanceSkillTableKey.EnhanceSkillEntry)
end

function XCharacterModel:GetEnhanceSkillTypeInfo()
    return self._ConfigUtil:GetByTableKey(CharacterEnhanceSkillTableKey.EnhanceSkillTypeInfo)
end

function XCharacterModel:GetEnhanceSkillUpgradeDes()
    return self._ConfigUtil:GetByTableKey(CharacterEnhanceSkillTableKey.EnhanceSkillUpgradeDes)
end

function XCharacterModel:GetCharacter()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.Character)
end

function XCharacterModel:GetCharacterDetail()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.CharacterDetail)
end

function XCharacterModel:GetCharacterCareer()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.CharacterCareer)
end

function XCharacterModel:GetCharacterGraph()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.CharacterGraph)
end

function XCharacterModel:GetCharacterRecommend()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.CharacterRecommend)
end

function XCharacterModel:GetCharacterTabId()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.CharacterTabId)
end

function XCharacterModel:GetCharacterLiberation()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.CharacterLiberation)
end

function XCharacterModel:GetCharacterLiberationIcon()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.CharacterLiberationIcon)
end

function XCharacterModel:GetCharacterSkillQualityApart()
    return self._ConfigUtil:GetByTableKey(CharacterQualityTableKey.CharacterSkillQualityApart)
end

function XCharacterModel:GetCharacterSkillQualityBigEffectBall()
    return self._ConfigUtil:GetByTableKey(CharacterQualityTableKey.CharacterSkillQualityBigEffectBall)
end

function XCharacterModel:GetCharacterQualityFragment()
    return self._ConfigUtil:GetByTableKey(CharacterQualityTableKey.CharacterQualityFragment)
end

function XCharacterModel:GetCharacterQuality()
    return self._ConfigUtil:GetByTableKey(CharacterQualityTableKey.CharacterQuality)
end

function XCharacterModel:GetCharacterSkill()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkill)
end

function XCharacterModel:GetCharacterSkillGroup()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillGroup)
end

function XCharacterModel:GetCharacterSkillUpgrade()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillUpgrade)
end

function XCharacterModel:GetCharacterSkillUpgradeDes()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillUpgradeDes)
end

function XCharacterModel:GetCharacterSkillUpgradeDetail()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillUpgradeDetail)
end

function XCharacterModel:GetCharacterSkillExchangeDes()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillExchangeDes)
end

function XCharacterModel:GetCharacterSkillLevelEffect()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillLevelEffect)
end

function XCharacterModel:GetCharacterSkillType()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillType)
end

function XCharacterModel:GetCharacterSkillTypePlus()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillTypePlus)
end

function XCharacterModel:GetCharacterSkillPool()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillPool)
end

function XCharacterModel:GetCharacterSkillEntry()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillEntry)
end

function XCharacterModel:GetCharacterSkillTeach()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillTeach)
end

function XCharacterModel:GetCharacterSkillGate()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillGate)
end

function XCharacterModel:GetCharacterSkillTypeInfo()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillTypeInfo)
end

function XCharacterModel:GetCharacterGeneralSkill()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterGeneralSkill)
end

function XCharacterModel:GetCharacterGrade()
    return self._ConfigUtil:GetByTableKey(CharacterGradeTableKey.CharacterGrade)
end

function XCharacterModel:InitNpcTemplates()
    self.NpcTemplates = XTableManager.ReadByIntKey("Share/Fight/Npc/Npc", XTable.XTableNpc, "Id")
end
--endregion 基础读表结束

-- 获取自定义数据 开始
-- 获取自定义数据 结束

-- 初始化相关数据 开始
function XCharacterModel:InitOwnCharacter()
    self.OwnCharacters = {}               -- 已拥有角色数据
    setmetatable(self.OwnCharacters, {
        __index = function(_, k, v)
            if XMVCA.XCharacter:IsCharacterCanShow(k) then
                return v
            end
        end,

        __pairs = function(t)
            return function(t, k)
                local nk, nv = next(t, k)
                if nk then
                    if XMVCA.XCharacter:IsCharacterCanShow(nk) then
                        return nk, nv
                    else
                        return nk, nil
                    end
                end
            end, t, nil
        end
    })
end

-- 角色等级边界数据
function XCharacterModel:InitCharLevelConfig()
    local TABLE_LEVEL_UP_TEMPLATE_PATH = "Share/Character/LevelUpTemplate/"
    local paths = CS.XTableManager.GetPaths(TABLE_LEVEL_UP_TEMPLATE_PATH)
    XTool.LoopCollection(paths, function(path)
        local key = tonumber(XTool.GetFileNameWithoutExtension(path))
        self.LevelUpTemplates[key] = XTableManager.ReadByIntKey(path, XTable.XTableEquipLevelUp, "Level")
    end)
end

-- 初始化character.tab的相关数据
function XCharacterModel:InitCharacterRelatedData()
    self.CharacterTemplatesCount = 0

    local allCharConfig = self:GetCharacter()
    for charId, v in pairs(allCharConfig) do
        local levelTemplate = self.LevelUpTemplates[v.LevelUpTemplateId]
        if not self.CharBorderTemplates[charId] then
            self.CharBorderTemplates[charId] = {}
        end
        self.CharBorderTemplates[charId].MinLevel = 1
        self.CharBorderTemplates[charId].MaxLevel = #levelTemplate

        self.ItemIdToCharacterIdDic[v.ItemId] = charId
        self.CharacterTemplatesCount = self.CharacterTemplatesCount + 1
    end
end

function XCharacterModel:InitEnhanceSkillLevelEffectDic()
    local levelEffectConfig = self:GetEnhanceSkillLevelEffect()
    for _,cfg in pairs(levelEffectConfig or {}) do
        self.EnhanceSkillLevelEffectDic[cfg.SkillId] = self.EnhanceSkillLevelEffectDic[cfg.SkillId] or {}
        self.EnhanceSkillLevelEffectDic[cfg.SkillId][cfg.Level] = cfg
    end
end

function XCharacterModel:GetEnhanceSkillLevelEffectDic()
    if XTool.IsTableEmpty(self.EnhanceSkillLevelEffectDic) then
        self:InitEnhanceSkillLevelEffectDic()
    end
    
    return self.EnhanceSkillLevelEffectDic
end

-- 初始化EnhanceSkillUpgrade.tab的相关字典
function XCharacterModel:InitEnhanceSkillUpgradeRelated()
    local gradeConfig = self:GetEnhanceSkillUpgrade()
    for _,cfg in pairs(gradeConfig or {}) do
        self.EnhanceSkillGradeDic[cfg.SkillId] = self.EnhanceSkillGradeDic[cfg.SkillId] or {}
        self.EnhanceSkillGradeDic[cfg.SkillId][cfg.Level] = cfg
        
        self.EnhanceSkillMaxLevelDic[cfg.SkillId] = self.EnhanceSkillMaxLevelDic[cfg.SkillId] or 0
        if cfg.Level > self.EnhanceSkillMaxLevelDic[cfg.SkillId] then
            self.EnhanceSkillMaxLevelDic[cfg.SkillId] = cfg.Level
        end
    end
end

function XCharacterModel:GetEnhanceSkillGradeDic()
    if XTool.IsTableEmpty(self.EnhanceSkillGradeDic) then
        self:InitEnhanceSkillUpgradeRelated()
    end

    return self.EnhanceSkillGradeDic
end

function XCharacterModel:GetEnhanceSkillMaxLevelDic()
    if XTool.IsTableEmpty(self.EnhanceSkillMaxLevelDic) then
        self:InitEnhanceSkillUpgradeRelated()
    end

    return self.EnhanceSkillMaxLevelDic
end

-- 初始化EnhanceSkillUpgradeDes.tab的相关字典
function XCharacterModel:InitEnhanceSkillGradeDescDic()
    local gradeDesConfig = self:GetEnhanceSkillUpgradeDes()
    for _, cfg in pairs(gradeDesConfig or {}) do
        self.EnhanceSkillGradeDescDic[cfg.SkillId] = self.EnhanceSkillGradeDescDic[cfg.SkillId] or {}
        self.EnhanceSkillGradeDescDic[cfg.SkillId][cfg.Level] = cfg
    end
end

function XCharacterModel:GetEnhanceSkillGradeDescDic()
    if XTool.IsTableEmpty(self.EnhanceSkillGradeDescDic) then
        self:InitEnhanceSkillGradeDescDic()
    end

    return self.EnhanceSkillGradeDescDic
end

-- 下面依赖的检测函数
function XCharacterModel:CompareQuality(templateId, quality)
    local template = self.CharBorderTemplates[templateId]
    if not template then
        return
    end

    if not template.MinQuality or template.MinQuality > quality then
        template.MinQuality = quality
    end

    if not template.MaxQuality or template.MaxQuality < quality then
        template.MaxQuality = quality
    end
end

-- 下面依赖的检测函数
function XCharacterModel:CompareGrade(templateId, grade)
    local template = self.CharBorderTemplates[templateId]
    if not template then
        return
    end

    if not template.MinGrade or template.MinGrade > grade then
        template.MinGrade = grade
    end

    if not template.MaxGrade or template.MaxGrade < grade then
        template.MaxGrade = grade
    end
end

function XCharacterModel:InitCharQualityConfig()
    -- 角色品质对应配置
    local tab = self:GetCharacterQuality()
    for _, config in pairs(tab) do
        if not self.CharQualityTemplates[config.CharacterId] then
            self.CharQualityTemplates[config.CharacterId] = {}
        end
        self.CharQualityTemplates[config.CharacterId][config.Quality] = config
        self:CompareQuality(config.CharacterId, config.Quality)
    end
    -- CharQualityIconTemplates = XTableManager.ReadByIntKey(TABLE_CHARACTER_QUALITY_ICON_PATH, XTable.XTableCharacterQualityIcon, "Quality")
end

function XCharacterModel:IniCharQualityFragmentConfig()
    local templates = self:GetCharacterQualityFragment()
    for _, config in pairs(templates) do
        local characterType = config.Type
        local characterTypeConfig = self.CharQualityFragmentTemplates[characterType] or {}
        self.CharQualityFragmentTemplates[characterType] = characterTypeConfig

        local quality = config.Quality
        characterTypeConfig[quality] = config
    end
end

function XCharacterModel:GetCharQualityFragmentConfig(characterType, quality)
    local characterTypeConfig = self.CharQualityFragmentTemplates[characterType]
    if not characterTypeConfig then
        XLog.Error("GetCharQualityFragmentConfig  CharacterQualityFragment.tab error:配置不存在, characterType: ", characterType)
        return
    end

    local config = characterTypeConfig[quality]
    if not config then
        XLog.Error("GetCharQualityFragmentConfig CharacterQualityFragment.tab error:配置不存在, quality: " , quality)
        return
    end

    return config
end

function XCharacterModel:InitCharGradeConfig()
    -- 角色晋级数据
    local tab = self:GetCharacterGrade()
    for _, config in pairs(tab) do
        if not self.CharGradeTemplates[config.CharacterId] then
            self.CharGradeTemplates[config.CharacterId] = {}
        end
        self.CharGradeTemplates[config.CharacterId][config.Grade] = config
        self:CompareGrade(config.CharacterId, config.Grade)
    end
end

function XCharacterModel:InitCharSkillQualityApart()
    local charSkillQualityApartConfig = self:GetCharacterSkillQualityApart() 
    for _, config in pairs(charSkillQualityApartConfig) do
        if not self.CharSkillQualityApartDic[config.CharacterId] then
            self.CharSkillQualityApartDic[config.CharacterId] = {}
        end
        if not self.CharSkillQualityApartDic[config.CharacterId][config.Quality] then
            self.CharSkillQualityApartDic[config.CharacterId][config.Quality] = {}
        end
        if not self.CharSkillQualityApartDic[config.CharacterId][config.Quality][config.Phase] then
            self.CharSkillQualityApartDic[config.CharacterId][config.Quality][config.Phase] = {}
        end 
        table.insert(self.CharSkillQualityApartDic[config.CharacterId][config.Quality][config.Phase], config.Id)
    end
end

function XCharacterModel:InitSkillGroupDic()
    local charSkillGroupTemplates = self:GetCharacterSkillGroup()
    for _, config in pairs(charSkillGroupTemplates) do
        local skillGroupId = config.Id
        local skillIds = config.SkillId

        local skillIdConfig = self.CharSkillGroupDic[skillGroupId]
        if not skillIdConfig then
            skillIdConfig = {}
            self.CharSkillGroupDic[skillGroupId] = skillIdConfig
        end

        for index, skillId in pairs(skillIds) do
            if skillId > 0 then
                self.CharSkillIdToGroupDic[skillId] = {
                    Index = index,
                    GroupId = skillGroupId,
                }
                table.insert(skillIdConfig, skillId)
            end
        end
    end
end

function XCharacterModel:InitCharSkillIdToCharacterIdDic()
    local CharSkillTemplates = self:GetCharacterSkill()
    for _, config in pairs(CharSkillTemplates) do
        local characterId = config.CharacterId

        local characterSkillConfig = self.CharacterSkillDictTemplates[characterId]
        if not characterSkillConfig then
            characterSkillConfig = {}
            self.CharacterSkillDictTemplates[characterId] = characterSkillConfig
        end

        local posList = config.Pos
        for index, skillGroupId in pairs(config.SkillGroupId) do
            local pos = posList[index]
            if not pos then
                XLog.Error("InitCharSkillIdToCharacterIdDic Error: 角色技能配置初始化错误, 找不到对应位置的技能组Id配置, skillGroupId: " .. skillGroupId .. ", 配置: CharacterSkill.tab" )
                return
            end

            local posSkillConfig = characterSkillConfig[pos]
            if not posSkillConfig then
                posSkillConfig = {}
                characterSkillConfig[pos] = posSkillConfig
            end
            table.insert(posSkillConfig, skillGroupId)

            self.CharSkillIdToCharacterIdDic[skillGroupId] = characterId

            if index == XEnumConst.CHARACTER.MAX_LEBERATION_SKILL_POS_INDEX then
                self.CharMaxLiberationSkillIdDic[characterId] = skillGroupId
            end
        end
    end
end

function XCharacterModel:InitCharacterSkillPoolConfig()
    local skillPoolTemplate = self:GetCharacterSkillPool()
    for _, v in pairs(skillPoolTemplate) do
        self.CharSkillPoolSkillIdDic[v.SkillId] = v
        self.CharPoolIdToSkillInfoDic[v.PoolId] = self.CharPoolIdToSkillInfoDic[v.PoolId] or {}

        table.insert(self.CharPoolIdToSkillInfoDic[v.PoolId], v)
    end
end

function XCharacterModel:InitSubSkillMinMaxLevelDicByCharacterSkillUpgrade()
    local skillGradeConfig = self:GetCharacterSkillUpgrade()
    for k, v in pairs(skillGradeConfig) do
        if not self.CharSkillLevelDict[v.SkillId] then
            self.CharSkillLevelDict[v.SkillId] = {}
        end
        self.CharSkillLevelDict[v.SkillId][v.Level] = k
    end
    
    --初始化技能的最小，最大等级
    for _, v in pairs(skillGradeConfig) do
        local skillId = v.SkillId
        if not self.SubSkillMinMaxLevelDicGrade[skillId] then
            self.SubSkillMinMaxLevelDicGrade[skillId] = {}
            self.SubSkillMinMaxLevelDicGrade[skillId].Min = v.Level
            self.SubSkillMinMaxLevelDicGrade[skillId].Max = v.Level
        end
    
        if v.Level < self.SubSkillMinMaxLevelDicGrade[skillId].Min then
            self.SubSkillMinMaxLevelDicGrade[skillId].Min = v.Level
        end
    
        if v.Level > self.SubSkillMinMaxLevelDicGrade[skillId].Max then
            self.SubSkillMinMaxLevelDicGrade[skillId].Max = v.Level
        end
    end
end

function XCharacterModel:InitCharSkillLevelDict()
    local skillLevelConfig = self:GetCharacterSkillLevelEffect()
    for _, v in pairs(skillLevelConfig) do
        if not self.CharSkillLevelEffectDict[v.SkillId] then
            self.CharSkillLevelEffectDict[v.SkillId] = {}
        end
        self.CharSkillLevelEffectDict[v.SkillId][v.Level] = v

        --初始化技能的最小，最大等级2
        self.SubSkillMinMaxLevelDicLevel[v.SkillId] = self.SubSkillMinMaxLevelDicLevel[v.SkillId] or {}
        if not self.SubSkillMinMaxLevelDicLevel[v.SkillId].Min
        or self.SubSkillMinMaxLevelDicLevel[v.SkillId].Min > v.Level then
            self.SubSkillMinMaxLevelDicLevel[v.SkillId].Min = v.Level
        end

        if not self.SubSkillMinMaxLevelDicLevel[v.SkillId].Max
        or self.SubSkillMinMaxLevelDicLevel[v.SkillId].Max < v.Level then
            self.SubSkillMinMaxLevelDicLevel[v.SkillId].Max = v.Level
        end
    end
end

function XCharacterModel:InitCharLiberationConfig()
    local tab = self:GetCharacterLiberation()
    for _, config in pairs(tab) do
        if not self.CharLiberationTemplates[config.CharacterId] then
            self.CharLiberationTemplates[config.CharacterId] = {}
        end
        self.CharLiberationTemplates[config.CharacterId][config.GrowUpLevel] = config
    end
end

function XCharacterModel:GetCharLiberationConfig(characterId, growUpLevel)
    local config = self.CharLiberationTemplates[tonumber(characterId)]
    if not config then
        return
    end

    config = config[growUpLevel]
    if not config then
        return
    end

    return config
end


function XCharacterModel:InitRecommendConfig()
    local templates = self:GetCharacterTabId()
    for _, config in pairs(templates) do
        local typeMap = self.CharacterTabToVoteGroupMap[config.CharacterId]
        if not typeMap then
            typeMap = {}
            self.CharacterTabToVoteGroupMap[config.CharacterId] = typeMap
        end

        local tabMap = typeMap[config.RecommendType]
        if not tabMap then
            tabMap = {}
            typeMap[config.RecommendType] = tabMap
        end

        tabMap[config.TabId] = config
    end
end
-- 初始化相关数据 结束

function XCharacterModel:ClearPrivate()
    --这里执行内部数据清理
end

function XCharacterModel:ResetAll()
    --这里执行重登数据清理
    for k, xChar in pairs(self.OwnCharacters) do
        xChar:RemoveEventListeners()
    end

    self:InitOwnCharacter()
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

----------config start----------


----------config end----------


return XCharacterModel