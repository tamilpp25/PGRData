---@class XCharacterModel : XModel
local XCharacterModel = XClass(XModel, "XCharacterModel")

-- character相关表的读取方式全部为normal
-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local CharacterTableKey = 
{
    Character = {},
    LevelUpTemplate = {},
    CharacterCareer = {},
    CharacterGraph = { DirPath = XConfigUtil.DirectoryType.Client },
    CharacterRecommend = { DirPath = XConfigUtil.DirectoryType.Client },
    CharacterTabId = { DirPath = XConfigUtil.DirectoryType.Client },
    CharacterLiberation = { DirPath = XConfigUtil.DirectoryType.Client },
    CharacterLiberationIcon = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "LiberationLv",},
    CharacterElement = { DirPath = XConfigUtil.DirectoryType.Client },
    CharacterFilterController = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "UiName", ReadFunc = XConfigUtil.ReadType.String},
    CharacterQualityIcon = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Quality",}, 
}

local CharacterQualityTableKey = 
{
    -- CharacterQualityFragment = {},
    CharacterQuality = {},
    CharacterSkillQualityApart = { DirPath = XConfigUtil.DirectoryType.Client },
    CharacterSkillQualityBigEffectBall = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Quality", },
}

local CharacterSkillTableKey = 
{
    -- CharacterSkill = {},
    -- CharacterSkillGroup = {},
    -- CharacterSkillPos = {},
    -- CharacterSkillUpgrade = {},
    CharacterSkillUpgradeDes = { DirPath = XConfigUtil.DirectoryType.Client , CacheType = XConfigUtil.CacheType.Preload},
    CharacterSkillUpgradeDetail = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "RefId", },
    CharacterSkillExchangeDes = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "SkillLevelId", },
    -- CharacterSkillLevelEffect = {},
    -- CharacterSkillType = {},
    -- CharacterSkillTypePlus = {},
    -- CharacterSkillPool = {},
    -- CharacterSkillEntry = {},
    -- CharacterSkillTeach = { DirPath = XConfigUtil.DirectoryType.Client },
    CharacterSkillGate = { DirPath = XConfigUtil.DirectoryType.Client },
    -- CharacterSkillTypeInfo = { DirPath = XConfigUtil.DirectoryType.Client },
}

local CharacterGradeTableKey = 
{
    CharacterGrade = {},
}

function XCharacterModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析

    --定义TableKey
    self._ConfigUtil:InitConfigByTableKey("Character", CharacterTableKey, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey("Character/Quality", CharacterQualityTableKey, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey("Character/Skill", CharacterSkillTableKey, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey("Character/Grade", CharacterGradeTableKey, XConfigUtil.CacheType.Normal)

    -- 体验包保留角色
    self.IncludeCharacterIds = {
        [1021001] = true, -- 露西亚
        [1031001] = true, -- 丽芙
        [1051001] = true, -- 七实
        [1511003] = true, -- 卡穆
    }
    self.IsHideFunc = CS.XRemoteConfig.IsHideFunc
    self.CharacterTemplatesCount = 1
    self.ItemIdToCharacterIdDic = {}
    self.LevelUpTemplates = {}
    self.CharBorderTemplates = {} -- 边界属性

    self:InitOwnCharacter()
    self:InitCharLevelConfig()
    self:InitCharacterRelatedData()
    self:InitCharQualityConfig() -- 后续移植再处理命名
    self:InitCharGradeConfig()
end

--region 基础读表
---@return XTableCharacterElement[]
function XCharacterModel:GetCharacterElement()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.CharacterElement)
end

function XCharacterModel:GetCharacterFilterController()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.CharacterFilterController)
end

function XCharacterModel:GetCharacterQualityIcon(quality)
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.CharacterQualityIcon)[quality]
end

function XCharacterModel:GetCharacter()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.Character)
end

function XCharacterModel:GetLevelUpTemplate()
    return self._ConfigUtil:GetByTableKey(CharacterTableKey.LevelUpTemplate)
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

function XCharacterModel:GetCharacterQuality()
    return self._ConfigUtil:GetByTableKey(CharacterQualityTableKey.CharacterQuality)
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

function XCharacterModel:GetCharacterSkillGate()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillGate)
end

function XCharacterModel:GetCharacterGrade()
    return self._ConfigUtil:GetByTableKey(CharacterGradeTableKey.CharacterGrade)
end
--endregion 基础读表结束

-- 初始化相关数据

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

function XCharacterModel:InitCharLevelConfig()
    local TABLE_LEVEL_UP_TEMPLATE_PATH = "Share/Character/LevelUpTemplate/"
    local paths = CS.XTableManager.GetPaths(TABLE_LEVEL_UP_TEMPLATE_PATH)
    XTool.LoopCollection(paths, function(path)
        local key = tonumber(XTool.GetFileNameWithoutExtension(path))
        self.LevelUpTemplates[key] = XTableManager.ReadByIntKey(path, XTable.XTableEquipLevelUp, "Level")
    end)
end

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
        -- if not CharQualityTemplates[config.CharacterId] then
        --     CharQualityTemplates[config.CharacterId] = {}
        -- end
        -- CharQualityTemplates[config.CharacterId][config.Quality] = config
        self:CompareQuality(config.CharacterId, config.Quality)
    end
    -- CharQualityIconTemplates = XTableManager.ReadByIntKey(TABLE_CHARACTER_QUALITY_ICON_PATH, XTable.XTableCharacterQualityIcon, "Quality")
end

function XCharacterModel:InitCharGradeConfig()
    -- 角色晋级数据
    local tab = self:GetCharacterGrade()
    for _, config in pairs(tab) do
        -- if not CharGradeTemplates[config.CharacterId] then
        --     CharGradeTemplates[config.CharacterId] = {}
        -- end
        -- CharGradeTemplates[config.CharacterId][config.Grade] = config
        self:CompareGrade(config.CharacterId, config.Grade)
    end
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