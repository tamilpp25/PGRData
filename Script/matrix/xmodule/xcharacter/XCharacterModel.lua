---@class XCharacterModel : XModel
local XCharacterModel = XClass(XModel, "XCharacterModel")

-- character相关表的读取方式全部为normal
-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local CharacterTableKey = 
{
    Character = {CacheType = XConfigUtil.CacheType.Normal},
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
    -- CharacterSkillUpgradeDes = { DirPath = XConfigUtil.DirectoryType.Client },
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
    self._ConfigUtil:InitConfigByTableKey("Character", CharacterTableKey, true)
    self._ConfigUtil:InitConfigByTableKey("Character/Quality", CharacterQualityTableKey, true)
    self._ConfigUtil:InitConfigByTableKey("Character/Skill", CharacterSkillTableKey, true)
    -- self._ConfigUtil:InitConfigByTableKey("Character/Grade", CharacterGradeTableKey)

    self.OwnCharacters = {}               -- 已拥有角色数据
    setmetatable(self.OwnCharacters, {
        __index = function(_, k, v)
            if XCharacterConfigs.IsCharacterCanShow(k) then
                return v
            end
        end,

        __pairs = function(t)
            return function(t, k)
                local nk, nv = next(t, k)
                if nk then
                    if XCharacterConfigs.IsCharacterCanShow(nk) then
                        return nk, nv
                    else
                        return nk, nil
                    end
                end
            end, t, nil
        end
    })
end

-- 基础读表
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

function XCharacterModel:GetCharacterSkillUpgradeDes()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillUpgradeDes)
end

function XCharacterModel:GetCharacterSkillExchangeDes()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillExchangeDes)
end

function XCharacterModel:GetCharacterSkillGate()
    return self._ConfigUtil:GetByTableKey(CharacterSkillTableKey.CharacterSkillGate)
end

function XCharacterModel:ClearPrivate()
    --这里执行内部数据清理
end

function XCharacterModel:ResetAll()
    --这里执行重登数据清理
    for k, xChar in pairs(self.OwnCharacters) do
        xChar:RemoveEventListeners()
    end
    self.OwnCharacters = {}               -- 已拥有角色数据
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

----------config start----------


----------config end----------


return XCharacterModel