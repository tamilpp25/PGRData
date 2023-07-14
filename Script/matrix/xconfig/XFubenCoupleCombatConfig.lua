XFubenCoupleCombatConfig = XFubenCoupleCombatConfig or {}

local TABLE_COUPLE_ACTIVITY = "Share/Fuben/CoupleCombat/CoupleCombatActivity.tab"
local TABLE_COUPLE_BUFF = "Share/Fuben/CoupleCombat/CoupleCombatFeature.tab"
local TABLE_COUPLE_CHAPTER = "Share/Fuben/CoupleCombat/CoupleCombatChapter.tab"
local TABLE_COUPLE_STAGE = "Share/Fuben/CoupleCombat/CoupleCombatStage.tab"
local TABLE_COUPLE_CHARACTER_CAREER_SKILL = "Share/Fuben/CoupleCombat/CoupleCombatCharacterCareerSkill.tab"
local TABLE_COUPLE_CHARACTER = "Share/Fuben/CoupleCombat/CoupleCombatCharacter.tab"
local TABLE_COUPLE_CHARACTER_CAREER_SKILL_GROUP = "Client/Fuben/CoupleCombat/CoupleCombatCharacterCareerSkillGroup.tab"

local CoupleCombatActivity = {}
local CoupleCombatFeature = {}
local CoupleCombatChapter = {}
local CoupleCombatStage = {}
local CoupleCombatCharacterCareerSkill = {}
local CoupleCombatCharacter = {}
local CoupleCombatCharacterCareerSkillGroup = {}

local ChapterIdList = {}
local StageIdList = {}
local StageIdToChapterIdMap = {}
local SkillGroupTypeToSkillIdsMap = {}

XFubenCoupleCombatConfig.ChapterType = {
    Normal = 1, --普通难度
    Hard = 2,  --困难难度
}

local InitChapterIdList = function()
    for id in pairs(CoupleCombatChapter) do
        table.insert(ChapterIdList, id)
    end
    table.sort(ChapterIdList, function(a, b)
        return a < b
    end)
end

local InitStageIdList = function()
    for id in pairs(CoupleCombatStage) do
        table.insert(StageIdList, id)
    end
    table.sort(StageIdList, function(a, b)
        return a < b
    end)
end

local InitStageIdToChapterIdMap = function()
    for chapterId, v in pairs(CoupleCombatChapter) do
        for _, stageId in ipairs(v.StageIds) do
            StageIdToChapterIdMap[stageId] = chapterId
        end
    end
end

local InitSkillGroupTypeToSkillIdsMap = function()
    for k, v in pairs(CoupleCombatCharacterCareerSkill) do
        if not SkillGroupTypeToSkillIdsMap[v.Type] then
            SkillGroupTypeToSkillIdsMap[v.Type] = {}
        end
        table.insert(SkillGroupTypeToSkillIdsMap[v.Type], v.Id)
    end
end

function XFubenCoupleCombatConfig.Init()
    CoupleCombatActivity = XTableManager.ReadByIntKey(TABLE_COUPLE_ACTIVITY, XTable.XTableCoupleCombatActivity, "Id")
    CoupleCombatFeature = XTableManager.ReadByIntKey(TABLE_COUPLE_BUFF, XTable.XTableCoupleCombatFeature, "Id")
    CoupleCombatChapter = XTableManager.ReadAllByIntKey(TABLE_COUPLE_CHAPTER, XTable.XTableCoupleCombatChapter, "Id")
    CoupleCombatStage = XTableManager.ReadAllByIntKey(TABLE_COUPLE_STAGE, XTable.XTableCoupleCombatStage, "Id")
    CoupleCombatCharacterCareerSkill = XTableManager.ReadByIntKey(TABLE_COUPLE_CHARACTER_CAREER_SKILL, XTable.XTableCoupleCombatCharacterCareerSkill, "Id")
    CoupleCombatCharacter = XTableManager.ReadByIntKey(TABLE_COUPLE_CHARACTER, XTable.XTableCoupleCombatCharacter, "CharacterId")
    CoupleCombatCharacterCareerSkillGroup = XTableManager.ReadByIntKey(TABLE_COUPLE_CHARACTER_CAREER_SKILL_GROUP, XTable.XTableCoupleCombatCharacterCareerSkillGroup, "Type")

    InitChapterIdList()
    InitStageIdList()
    InitStageIdToChapterIdMap()
    InitSkillGroupTypeToSkillIdsMap()
end

-----------------CoupleCombatStage begin-----------------------
function XFubenCoupleCombatConfig.GetStageInfo(id)
    local template = CoupleCombatStage[id]
    if not template then
        XLog.ErrorTableDataNotFound("XFubenCoupleCombatConfig.GetStageInfo", "CoupleCombatStage", TABLE_COUPLE_STAGE, "id", tostring(id))
        return
    end
    return template
end

function XFubenCoupleCombatConfig.GetStageIdList()
    return StageIdList
end

function XFubenCoupleCombatConfig.GetStages()
    return CoupleCombatStage
end

function XFubenCoupleCombatConfig.GetStageFeatureList(id)
    local config = XFubenCoupleCombatConfig.GetStageInfo(id)
    return config.Feature
end

function XFubenCoupleCombatConfig.GetStageShowFightEventIds(id)
    local config = XFubenCoupleCombatConfig.GetStageInfo(id)
    return config.ShowFightEventIds
end

function XFubenCoupleCombatConfig.GetStageOpenDay(id)
    local config = XFubenCoupleCombatConfig.GetStageInfo(id)
    return config.OpenDay
end

function XFubenCoupleCombatConfig.GetStageGridBg(id)
    local config = XFubenCoupleCombatConfig.GetStageInfo(id)
    return config.GridBg
end

function XFubenCoupleCombatConfig.GetStageIndexText(id)
    local config = XFubenCoupleCombatConfig.GetStageInfo(id)
    return config.IndexText
end

function XFubenCoupleCombatConfig.GetStageIsLastOne(id)
    local config = XFubenCoupleCombatConfig.GetStageInfo(id)
    return config.IsLastOne
end
-----------------CoupleCombatStage end------------------------

-----------------CoupleCombatChapter begin-----------------------
local GetCoupleCombatChapterConfig = function(id)
    local config = CoupleCombatChapter[id]
    if not config then
        XLog.ErrorTableDataNotFound("XPassportConfigs.GetCoupleCombatChapterConfig", "CoupleCombatChapterConfigs", TABLE_COUPLE_CHAPTER, "Id", id)
        return
    end
    return config
end

function XFubenCoupleCombatConfig.GetChapterName(id)
    local config = GetCoupleCombatChapterConfig(id)
    return config.Name
end

function XFubenCoupleCombatConfig.GetChapterIcon(id)
    local config = GetCoupleCombatChapterConfig(id)
    return config.Icon
end

function XFubenCoupleCombatConfig.GetChapterTimeId(id)
    local config = GetCoupleCombatChapterConfig(id)
    return config.TimeId
end

function XFubenCoupleCombatConfig.GetChapterStageIds(id)
    local config = GetCoupleCombatChapterConfig(id)
    return config.StageIds
end

function XFubenCoupleCombatConfig.GetChapterRobotIds(id)
    local config = GetCoupleCombatChapterConfig(id)
    return config.RobotIds
end

function XFubenCoupleCombatConfig.GetChapterShowFightEventIds(id)
    local config = GetCoupleCombatChapterConfig(id)
    return config.ShowFightEventIds
end

function XFubenCoupleCombatConfig.GetChapterPrefabName(id)
    local config = GetCoupleCombatChapterConfig(id)
    return config.PrefabName
end

function XFubenCoupleCombatConfig.GetChapterUnlockChapterId(id)
    local config = GetCoupleCombatChapterConfig(id)
    return config.UnlockChapterId
end

function XFubenCoupleCombatConfig.GetChapterUnlockOccupyStageCount(id)
    local config = GetCoupleCombatChapterConfig(id)
    return config.UnlockOccupyStageCount
end

function XFubenCoupleCombatConfig.GetChapterLockDesc(id)
    local unlockChapterId = XFubenCoupleCombatConfig.GetChapterUnlockChapterId(id)
    local unlockOccupyStageCount = XFubenCoupleCombatConfig.GetChapterUnlockOccupyStageCount(id)
    local chapterName = XTool.IsNumberValid(unlockChapterId) and XFubenCoupleCombatConfig.GetChapterName(unlockChapterId) or ""
    return XUiHelper.ReadTextWithNewLine("CoupleCombatChapterLockDesc", chapterName, unlockOccupyStageCount)
end

-- 获取章节难度：1、普通 2、困难
function XFubenCoupleCombatConfig.GetChapterType(id)
    local config = GetCoupleCombatChapterConfig(id)
    return XTool.IsNumberValid(config.ChapterType) and config.ChapterType or XFubenCoupleCombatConfig.ChapterType.Normal
end

--检查试玩角色是否可用
function XFubenCoupleCombatConfig.CheckRobotIsUse(stageId, charId)
    if not XRobotManager.CheckIsRobotId(charId) then
        return true
    end

    local chapterId = XFubenCoupleCombatConfig.GetChapterIdByStageId(stageId)
    local robotIds = XFubenCoupleCombatConfig.GetChapterRobotIds(chapterId)
    for _, robotId in ipairs(robotIds) do
        if robotId == charId then
            return true
        end
    end
    return false
end

function XFubenCoupleCombatConfig.GetChapterIdByStageId(stageId)
    return StageIdToChapterIdMap[stageId]
end

function XFubenCoupleCombatConfig.GetChapterIdList()
    return ChapterIdList
end

function XFubenCoupleCombatConfig.GetChapterTemplates()
    return CoupleCombatChapter
end

function XFubenCoupleCombatConfig.GetChapterTemplate(id)
    return CoupleCombatChapter[id]
end
-----------------CoupleCombatChapter end-----------------------

-----------------CoupleCombatCharacterCareerSkill begin-----------------
local GetCoupleCombatCharacterCareerSkillConfig = function(id)
    local config = CoupleCombatCharacterCareerSkill[id]
    if not config then
        XLog.ErrorTableDataNotFound("XPassportConfigs.GetCoupleCombatCharacterCareerSkillConfig", "CoupleCombatCharacterCareerSkill", TABLE_COUPLE_CHARACTER_CAREER_SKILL, "Id", id)
        return
    end
    return config
end

function XFubenCoupleCombatConfig.GetCharacterCareerSkillType(id)
    local config = GetCoupleCombatCharacterCareerSkillConfig(id)
    return config.Type
end

function XFubenCoupleCombatConfig.GetCharacterCareerSkillName(id)
    local config = GetCoupleCombatCharacterCareerSkillConfig(id)
    return config.Name
end

function XFubenCoupleCombatConfig.GetCharacterCareerSkillEnName(id)
    local config = GetCoupleCombatCharacterCareerSkillConfig(id)
    return config.EnName
end

function XFubenCoupleCombatConfig.GetCharacterCareerSkillIcon(id)
    local config = GetCoupleCombatCharacterCareerSkillConfig(id)
    return config.Icon
end

--主动技能描述
function XFubenCoupleCombatConfig.GetCharacterCareerSkillDescription(id)
    local config = GetCoupleCombatCharacterCareerSkillConfig(id)
    local desc = config.Description or ""
    return string.gsub(desc, "\\n", "\n")
end

function XFubenCoupleCombatConfig.GetCharacterCareerSkillFightEventId(id)
    local config = GetCoupleCombatCharacterCareerSkillConfig(id)
    return config.FightEventId
end

function XFubenCoupleCombatConfig.GetCharacterCareerSkillCondition(id)
    local config = GetCoupleCombatCharacterCareerSkillConfig(id)
    return config.Condition
end

function XFubenCoupleCombatConfig.GetCharacterCareerSkillIconLv(id)
    local config = GetCoupleCombatCharacterCareerSkillConfig(id)
    return config.IconLv
end
-----------------CoupleCombatCharacterCareerSkill end-------------------

-----------------CoupleCombatCharacterCareerSkillGroup begin----------------
local GetCoupleCombatCharacterCareerSkillGroupConfig = function(type)
    local config = CoupleCombatCharacterCareerSkillGroup[type]
    if not config then
        XLog.ErrorTableDataNotFound("XPassportConfigs.GetCoupleCombatCharacterCareerSkillGroupConfig", "CoupleCombatCharacterCareerSkillGroup", TABLE_COUPLE_CHARACTER_CAREER_SKILL_GROUP, "Type", type)
        return
    end
    return config
end

function XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupName(type)
    local config = GetCoupleCombatCharacterCareerSkillGroupConfig(type)
    return config.Name
end

function XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupEnName(type)
    local config = GetCoupleCombatCharacterCareerSkillGroupConfig(type)
    return config.EnName
end

function XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupIcon(type)
    local config = GetCoupleCombatCharacterCareerSkillGroupConfig(type)
    return config.Icon
end

--被动技能描述
function XFubenCoupleCombatConfig.GetCharacterCareerSkillGroupDescription(type)
    local config = GetCoupleCombatCharacterCareerSkillGroupConfig(type)
    local desc = config.Description or ""
    return string.gsub(desc, "\\n", "\n")
end

function XFubenCoupleCombatConfig.GetCharacterCareerSkillIds(type)
    return SkillGroupTypeToSkillIdsMap[type] or {}
end

function XFubenCoupleCombatConfig.GetSkillGroupTypeToSkillIdsMap()
    return SkillGroupTypeToSkillIdsMap
end
-----------------CoupleCombatCharacterCareerSkillGroup end------------------

-----------------CoupleCombatCharacter begin-----------------
local GetCoupleCombatCharacterConfig = function(id)
    local config = CoupleCombatCharacter[id]
    if not config then
        XLog.ErrorTableDataNotFound("XPassportConfigs.GetCoupleCombatCharacterConfig", "CoupleCombatCharacter", TABLE_COUPLE_CHARACTER, "Id", id)
        return
    end
    return config
end

function XFubenCoupleCombatConfig.GetCharacterFeature(id)
    local characterId = XRobotManager.GetCharacterId(id)
    local config = XTool.IsNumberValid(characterId) and GetCoupleCombatCharacterConfig(characterId)
    return config and config.Feature or {}
end

function XFubenCoupleCombatConfig.GetCharacterName(id, index)
    local config = GetCoupleCombatCharacterConfig(id)
    return config.Name[index] or ""
end

function XFubenCoupleCombatConfig.GetCharacterIcon(id, index)
    local config = GetCoupleCombatCharacterConfig(id)
    return config.Icon[index]
end

function XFubenCoupleCombatConfig.GetCharacterDescription(id, index)
    local config = GetCoupleCombatCharacterConfig(id)
    return config.Description[index] or ""
end
-----------------CoupleCombatCharacter end-------------------

function XFubenCoupleCombatConfig.GetActTemplates()
    return CoupleCombatActivity
end

function XFubenCoupleCombatConfig.GetActivityTemplateById(id)
    return CoupleCombatActivity[id]
end

--返回角色特效与环境特效重合数量
function XFubenCoupleCombatConfig.GetFeatureMatchCount(stageId, robotId)
    local characterId = XRobotManager.GetCharacterId(robotId)
    local characterFeatureList = XFubenCoupleCombatConfig.GetCharacterFeature(characterId)
    local stageFeatureList = XFubenCoupleCombatConfig.GetStageFeatureList(stageId)

    local stageFeatureDic = {}
    for _, featureId in ipairs(stageFeatureList) do
        stageFeatureDic[featureId] = true
    end

    local matchCount = 0
    for _, featureId in ipairs(characterFeatureList) do
        if stageFeatureDic[featureId] then
            matchCount = matchCount + 1
        end
    end
    return matchCount
end

-----------------CoupleCombatFeature begin-----------------
local GetCoupleCombatFeatureConfig = function(id)
    local config = CoupleCombatFeature[id]
    if not config then
        XLog.ErrorTableDataNotFound("XPassportConfigs.GetCoupleCombatFeatureConfig", "CoupleCombatFeature", TABLE_COUPLE_BUFF, "Id", id)
        return
    end
    return config
end

function XFubenCoupleCombatConfig.GetFeatureName(id)
    local config = GetCoupleCombatFeatureConfig(id)
    return config.Name or ""
end

function XFubenCoupleCombatConfig.GetFeatureIcon(id)
    local config = GetCoupleCombatFeatureConfig(id)
    return config.Icon
end

function XFubenCoupleCombatConfig.GetFeatureDescription(id)
    local config = GetCoupleCombatFeatureConfig(id)
    return config.Description or ""
end
-----------------CoupleCombatFeature end-------------------