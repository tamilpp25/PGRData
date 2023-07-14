local tonumber = tonumber
local tableInsert = table.insert
local tableSort = table.sort
local ipairs = ipairs
local pairs = pairs
local CSXTextManagerGetText = CS.XTextManager.GetText

local TABLE_MONSTER_PATH = "Share/Pokemon/Monster/PokemonMonster.tab"
local TABLE_MONSTER_SKILL_PATH = "Share/Pokemon/Monster/PokemonMonsterSkill.tab"
local TABLE_MONSTER_LEVEL_PATH = "Share/Pokemon/Monster/LevelTemplate/"
local TABLE_MONSTER_STAR_PATH = "Share/Pokemon/Monster/StarTemplate/"
local TABLE_MONSTER_CAREER_PATH = "Client/Pokemon/PokemonMonsterCareer.tab"
local TABLE_CHAPTER_CONFIG_PATH = "Client/Pokemon/PokemonChapterLocalConfig.tab"
local TABLE_STAGE_TEMPLATE_PATH = "Client/Pokemon/PokemonStageTemplate.tab"
local TABLE_STAGE_PATH = "Share/Pokemon/PokemonStage.tab"
local TABLE_Chapter_PATH = "Share/Pokemon/PokemonChapter.tab"
local TABLE_STAGE_MONSTER_PATH = "Client/Pokemon/PokemonStageMonster.tab"
local TABLE_POKEMON_ACTIVITY_PATH = "Share/Pokemon/PokemonActivity.tab"
local TABLE_POKEMON_INIT_PATH = "Share/Pokemon/PokemonInit.tab"

local MonsterTemplate = {}
local MonsterLevelTemplate = {}
local MonsterStarTemplate = {}
local MonsterSkillTemplate = {}
local MonsterCareerTemplate = {}
local ItemIdCheckDic = {}--记录所有配置物品Id
local StageTemplate = {}
local StageUITemplate = {}
local StageRawTemplate = {}
local StageMonsterTemplate = {}
local PokemonActivityCfgs = {}
local PokemonInitCfgs = {}
local NpcIdToMonsterIdDic = {}
local FightStageIdToStageIdDic = {}
local Chapters = {}
local ChapterConfig = {}

local DefaultActivityId = 1

XPokemonConfigs = XPokemonConfigs or {}
XPokemonConfigs.PokemonNewRoleClickedPrefix = "POKEMON_NEW_ROLE_CLICKED"

local InitMonsterConfig = function()
    MonsterTemplate = XTableManager.ReadByIntKey(TABLE_MONSTER_PATH, XTable.XTablePokemonMonster, "Id")

    for monsterId, config in pairs(MonsterTemplate) do
        local npcId = config.NpcId
        if npcId > 0 then
            NpcIdToMonsterIdDic[npcId] = monsterId
        end
    end
end

local InitMonsterLevelConfigs = function()
    local paths = CS.XTableManager.GetPaths(TABLE_MONSTER_LEVEL_PATH)
    XTool.LoopCollection(paths, function(path)
        local key = XTool.GetFileNameWithoutExtension(path)
        local template = XTableManager.ReadByIntKey(path, XTable.XTablePokemonMonsterLevel, "Level")

        for _, config in pairs(template) do
            local itemId = config.CostItemId
            if itemId and itemId > 0 then
                ItemIdCheckDic[itemId] = itemId
            end
        end

        MonsterLevelTemplate[tonumber(key)] = template
    end)
end

local InitMonsterStarConfigs = function()
    local paths = CS.XTableManager.GetPaths(TABLE_MONSTER_STAR_PATH)
    XTool.LoopCollection(paths, function(path)
        local key = XTool.GetFileNameWithoutExtension(path)
        local template = XTableManager.ReadByIntKey(path, XTable.XTablePokemonMonsterStar, "Star")

        for _, config in pairs(template) do
            local itemId = config.CostItemId
            if itemId and itemId > 0 then
                ItemIdCheckDic[itemId] = itemId
            end
        end

        MonsterStarTemplate[tonumber(key)] = template
    end)
end


local InitStageConfigs = function()
    StageRawTemplate = XTableManager.ReadByIntKey(TABLE_STAGE_PATH, XTable.XTablePokemonStage, "Id")
    local sortTemplate = {}
    for _, stage in pairs(StageRawTemplate) do
        local activityId = stage.ActivityId

        if activityId then
            sortTemplate[activityId] = sortTemplate[activityId] or {}
            --if sortTemplate[activityId] then
            --    tableInsert(sortTemplate[activityId], v)
            --else
            --    sortTemplate[activityId] = {}
            --    tableInsert(sortTemplate[activityId], v)
            --end
            sortTemplate[activityId][stage.ChapterId] = sortTemplate[activityId][stage.ChapterId] or {}
            tableInsert(sortTemplate[activityId][stage.ChapterId],stage)
        end
    end

    for k, v in pairs(sortTemplate) do
        for _,chapter in pairs(v) do
            tableSort(chapter, function(a, b) return a.Id < b.Id end)
        end
    end
    for activityId,activityStages in pairs(sortTemplate) do
        StageTemplate[activityId] = {}
        FightStageIdToStageIdDic[activityId] = {}
        local sortKey = {}
        for chapterId,chapterStages in pairs(activityStages) do
            tableInsert(sortKey,chapterId)
        end
        tableSort(sortKey)
        for i = 1,#sortKey do
            local index = 1
            StageTemplate[activityId][sortKey[i]] = activityStages[sortKey[i]]
            for _,stage in pairs(activityStages[sortKey[i]]) do
                local fightStageId = stage.StageId
                if fightStageId and fightStageId > 0 then
                    FightStageIdToStageIdDic[activityId][fightStageId] = index
                end
                index = index + 1
            end
        end
    end
end

local InitActivityConfig = function()
    PokemonActivityCfgs = XTableManager.ReadByIntKey(TABLE_POKEMON_ACTIVITY_PATH, XTable.XTablePokemonActivity, "Id")
    for activityId, config in pairs(PokemonActivityCfgs) do
        if XTool.IsNumberValid(config.ActivityTimeId) then
            DefaultActivityId = activityId
            break
        end
        DefaultActivityId = activityId
    end
end

function XPokemonConfigs.Init()
    MonsterCareerTemplate = XTableManager.ReadByIntKey(TABLE_MONSTER_CAREER_PATH, XTable.XTablePokemonMonsterCareer, "Career")
    MonsterSkillTemplate = XTableManager.ReadByIntKey(TABLE_MONSTER_SKILL_PATH, XTable.XTablePokemonMonsterSkill, "Id")
    StageMonsterTemplate = XTableManager.ReadByIntKey(TABLE_STAGE_MONSTER_PATH, XTable.XTablePokemonStageMonster, "Id")
    PokemonInitCfgs = XTableManager.ReadByIntKey(TABLE_POKEMON_INIT_PATH, XTable.XTablePokemonInit, "Id")
    ChapterConfig = XTableManager.ReadByIntKey(TABLE_CHAPTER_CONFIG_PATH,XTable.XTablePokemonChapterLocalConfig,"Id")
    Chapters = XTableManager.ReadByIntKey(TABLE_Chapter_PATH,XTable.XTablePokemonChapter,"Id")
    StageUITemplate = XTableManager.ReadByIntKey(TABLE_STAGE_TEMPLATE_PATH,XTable.XTablePokemonStageTemplate,"Id")
    InitActivityConfig()
    InitMonsterConfig()
    InitMonsterLevelConfigs()
    InitMonsterStarConfigs()
    InitStageConfigs()
end

-----------------怪物相关 begin--------------------
--怪物类型
XPokemonConfigs.MonsterType = {
    Default = -1,
    Member = 0, --小队成员
    Boss = 1, --团队核心
}

XPokemonConfigs.MonsterCareer = {
    Shooter = 4,    --射手
    Shield = 1,     --盾卫
    Knight = 2,     --骑士
    Assassin = 3,   --刺客
}

--怪物 begin--
local GetMonsterConfig = function(monsterId)
    local config = MonsterTemplate[monsterId]
    if not config then
    XLog.Error("XPokemonConfigs GetMonsterConfig error:配置不存在, monsterId: " .. monsterId .. ", 配置路径: " .. TABLE_MONSTER_PATH)
    return
    end
    return config
end

function XPokemonConfigs.CheckMonsterType(monsterId, monsterType)
    if not monsterId or monsterId == 0 then return false end
    local config = GetMonsterConfig(monsterId)
    return config.Type == monsterType
end

function XPokemonConfigs.CheckMonsterCareer(monsterId, careerType)
    if not monsterId or monsterId == 0 then return false end
    local config = GetMonsterConfig(monsterId)
    return config.Career == careerType
end

function XPokemonConfigs.GetMonsterHeadIcon(monsterId)
    local config = GetMonsterConfig(monsterId)
    return config.HeadIcon
end

function XPokemonConfigs.GetMonsterModelId(monsterId)
    local config = GetMonsterConfig(monsterId)
    return config.ModelId
end

function XPokemonConfigs.GetMonsterName(monsterId)
    local config = GetMonsterConfig(monsterId)
    return config.Name
end

function XPokemonConfigs.GetMonsterLevelTemplateId(monsterId)
    local config = GetMonsterConfig(monsterId)
    return config.LevelTemplateId
end

function XPokemonConfigs.GetMonsterStarTemplateId(monsterId)
    local config = GetMonsterConfig(monsterId)
    return config.StarTemplateId
end

function XPokemonConfigs.GetMonsterNpcId(monsterId)
    local config = GetMonsterConfig(monsterId)
    return config.NpcId
end

function XPokemonConfigs.GetMonsterEnergyCost(monsterId)
    local config = GetMonsterConfig(monsterId)
    return config.EnergyCost
end

function XPokemonConfigs.GetMonsterAbilityRate(monsterId)
    local config = GetMonsterConfig(monsterId)
    return config.AbilityRateMonster, config.AbilityRateHp, config.AbilityRateAttack
end

function XPokemonConfigs.GetMonsterSkillIds(monsterId)
    local skillIds = {}
    local config = GetMonsterConfig(monsterId)
    for _, skillId in ipairs(config.SkillIds) do
        tableInsert(skillIds, skillId)
    end
    return skillIds
end

function XPokemonConfigs.GetMonsterRatingIcon(monsterId)
    local config = GetMonsterConfig(monsterId)
    return config.RatingIcon or ""
end

--怪物 end--
--怪物职业 begin--
function XPokemonConfigs.GetMonsterCareer(monsterId)
    local config = GetMonsterConfig(monsterId)
    return config.Career
end

function XPokemonConfigs.GetMonsterCareerName(monsterId)
    local career = XPokemonConfigs.GetMonsterCareer(monsterId)
    return XPokemonConfigs.GetCareerName(career)
end

function XPokemonConfigs.GetMonsterCareerIcon(monsterId)
    local career = XPokemonConfigs.GetMonsterCareer(monsterId)
    return XPokemonConfigs.GetCareerIcon(career)
end

--本职业是否克制比较职业
function XPokemonConfigs.IsMonsterCareerUp(monsterId, compareCareer)
    local career = XPokemonConfigs.GetMonsterCareer(monsterId)
    local restraintCareer = XPokemonConfigs.GetMonsterCareerRestraintCareer(career)
    return compareCareer and restraintCareer == compareCareer or false
end

--本职业是否被比较职业克制
function XPokemonConfigs.IsMonsterCareerDown(monsterId, compareCareer)
    local career = XPokemonConfigs.GetMonsterCareer(monsterId)
    local restraintCareer = XPokemonConfigs.GetMonsterCareerRestraintCareer(compareCareer)
    return restraintCareer and restraintCareer == career or false
end
--怪物职业 end--
--怪物等级 begin--
local GetMonsterLevelTemplate = function(monsterId)
    local templateId = XPokemonConfigs.GetMonsterLevelTemplateId(monsterId)
    local template = MonsterLevelTemplate[templateId]
    if not template then
        XLog.Error("XPokemonConfigs GetMonsterLevelTemplate error:配置不存在, templateId: " .. templateId .. ", 配置路径: " .. TABLE_MONSTER_LEVEL_PATH)
        return
    end
    return template
end

local GetMonsterLevelConfig = function(monsterId, level)
    local template = GetMonsterLevelTemplate(monsterId)
    local config = template[level]
    if not config then
        XLog.Error("XPokemonConfigs GetMonsterLevelConfig error:配置不存在, monsterId: " .. monsterId .. ", level: " .. level .. ", 配置路径: " .. TABLE_MONSTER_LEVEL_PATH)
        return
    end
    return config
end

function XPokemonConfigs.GetMonsterLevelCostItemInfo(monsterId, level)
    local config = GetMonsterLevelConfig(monsterId, level)
    return config.CostItemId, config.CostItemCount
end
--怪物等级 end--
--怪物星级 begin--
local GetMonsterStarTemplate = function(monsterId)
    local templateId = XPokemonConfigs.GetMonsterStarTemplateId(monsterId)
    local template = MonsterStarTemplate[templateId]
    if not template then
        XLog.Error("XPokemonConfigs GetMonsterStarTemplate error:配置不存在, templateId: " .. templateId .. ", 配置路径: " .. TABLE_MONSTER_STAR_PATH)
        return
    end
    return template
end

local GetMonsterStarConfig = function(monsterId, star)
    local template = GetMonsterStarTemplate(monsterId)
    local config = template[star]
    if not config then
        XLog.Error("XPokemonConfigs GetMonsterStarConfig error:配置不存在, monsterId: " .. monsterId .. ", star: " .. star .. ", 配置路径: " .. TABLE_MONSTER_STAR_PATH)
        return
    end
    return config
end

function XPokemonConfigs.GetMonsterStarCostItemInfo(monsterId, star)
    local config = GetMonsterStarConfig(monsterId, star)
    return config.CostItemId, config.CostItemCount
end

function XPokemonConfigs.GetMonsterStarMaxLevel(monsterId, star)
    local config = GetMonsterStarConfig(monsterId, star)
    return config.MaxLevel
end

function XPokemonConfigs.GetMonsterStarMaxStar(monsterId)
    local template = GetMonsterStarTemplate(monsterId)
    return #template
end
--怪物星级 end--
--怪物技能 begin--
local GetMonsterSkillConfig = function(skillId)
    local config = MonsterSkillTemplate[skillId]
    if not config then
        XLog.Error("XPokemonConfigs GetMonsterSkillConfig error:配置不存在, skillId: " .. skillId .. ", 配置路径: " .. TABLE_MONSTER_SKILL_PATH)
        return
    end
    return config
end

function XPokemonConfigs.GetMonsterSkillName(skillId)
    local config = GetMonsterSkillConfig(skillId)
    return config.Name
end

function XPokemonConfigs.GetMonsterSkillDescription(skillId)
    local config = GetMonsterSkillConfig(skillId)
    return config.Description
end

function XPokemonConfigs.GetMonsterSkillUnlockStar(skillId)
    local config = GetMonsterSkillConfig(skillId)
    return config.UnlockStar
end

function XPokemonConfigs.GetMonsterSkillIcon(skillId)
    local config = GetMonsterSkillConfig(skillId)
    return config.Icon
end

function XPokemonConfigs.GetMonsterSkillGroupId(skillId)
    local config = GetMonsterSkillConfig(skillId)
    return config.Position
end
--怪物技能 end--
--战中设置 begin--
function XPokemonConfigs.GetMonsterIdByNpcId(npcId)
    return NpcIdToMonsterIdDic[npcId] or 0
end
--战中设置 end--
-----------------怪物相关 end--------------------
-----------------职业相关 begin--------------------
local GetCareerConfig = function(career)
    local config = MonsterCareerTemplate[career]
    if not config then
        XLog.Error("XPokemonConfigs GetCareerConfig error:配置不存在, career: " .. career .. ", 配置路径: " .. TABLE_MONSTER_CAREER_PATH)
        return
    end
    return config
end

XPokemonConfigs.DefaultAllCareer = -1 --代表全部职业
function XPokemonConfigs.GetAllCareers()
    local careers = {}
    for career in pairs(MonsterCareerTemplate) do
        tableInsert(careers, career)
    end
    tableInsert(careers, XPokemonConfigs.DefaultAllCareer)
    return careers
end

function XPokemonConfigs.GetCareerName(career)
    if career == XPokemonConfigs.DefaultAllCareer then
        return CsXTextManagerGetText("PokemonMonsterAllCareer")
    end

    local config = GetCareerConfig(career)
    return config.Name
end

local DefaultIconPath = CS.XGame.ClientConfig:GetString("PokemonAllCareerIcon")
function XPokemonConfigs.GetCareerIcon(career)
    if career == XPokemonConfigs.DefaultAllCareer then
        return DefaultIconPath
    end

    local config = GetCareerConfig(career)
    return config.Icon
end

--获取克制职业
function XPokemonConfigs.GetMonsterCareerRestraintCareer(career)
    if not career then return end
    local config = GetCareerConfig(career)
    return config.RestraintCareer
end

--获取被克制职业
function XPokemonConfigs.GetMonsterCareerRecommendCareer(career)
    if not career then return end
    for paramCareer in pairs(MonsterCareerTemplate) do
        local restraintCareer = XPokemonConfigs.GetMonsterCareerRestraintCareer(paramCareer)
        if restraintCareer == career then
            return paramCareer
        end
    end
end
-----------------职业相关 end--------------------
-----------------章节相关 begin------------------
local GetChapterLocalConfig = function(chapterId)
    local config = ChapterConfig[chapterId]
    if not config then
        XLog.Error("XPokemonConfigs.GetChapterLocalConfig 章节配置不存在, chapterId:",chapterId)
        return
    end
    return config
end

local GetChapter = function(chapterId)
    local config = Chapters[chapterId]
    if not config then
        XLog.Error("XPokemonConfigs.GetChapter 章节配置不存在, chapterId:",chapterId)
        return
    end
    return config
end

function XPokemonConfigs.GetChapterName(chapterId)
    local config = GetChapterLocalConfig(chapterId)
    return config.Name
end

function XPokemonConfigs.GetChapterBackground(chapterId)
    local config = GetChapterLocalConfig(chapterId)
    return config.Background
end

function XPokemonConfigs.GetChapterDesc(chapterId)
    local config = GetChapterLocalConfig(chapterId)
    return config.Desc
end

function XPokemonConfigs.GetChapterTitleImage(chapterId)
    local config = GetChapterLocalConfig(chapterId)
    return config.ChapterTitleImage
end

function XPokemonConfigs.GetChapterScrollBg(chapterId)
    local config = GetChapterLocalConfig(chapterId)
    return config.ChapterScrollBg
end

function XPokemonConfigs.GetChapterPerPageStageCount(chapterId)
    local config = GetChapterLocalConfig(chapterId)
    return config.PerPageStageCount
end

function XPokemonConfigs.GetChapters(activityId)
    local chapters = {}
    for _,chapter in pairs(Chapters) do
        if chapter.ActivityId == activityId then
            tableInsert(chapters,chapter)
        end
    end
    return chapters
end

function XPokemonConfigs.GetChapterTimeId(chapterId)
    local config = GetChapter(chapterId)
    return config.TimeId
end

function XPokemonConfigs.GetChapterOpenCondition(chapterId)
    local config = GetChapter(chapterId)
    return config.OpenCondition
end

function XPokemonConfigs.GetChapterType(chapter)
    local config = GetChapter(chapter)
    return config.ChapterType
end

-----------------章节相关 end--------------------
-----------------关卡相关 begin------------------
XPokemonConfigs.StageType = {
    Normal = 1, --普通关
    --Infinity = 2	--无尽关
    Skip = 2, --可跳关
}

XPokemonConfigs.ChapterType = {
    Normal = 1, --前四章不可跳关章节
    Skip = 2, --第五章可调关章节
}

XPokemonConfigs.TeamNum = 6 --关卡布阵队伍成员数量
XPokemonConfigs.PerPageCount = 4 --每页关卡数量

local GetStageConfig = function(stageId, activityId, chapterId)
    local stageDic = StageTemplate[activityId]
    if not stageDic then
        XLog.Error("XPokemonConfigs GetStageConfig error:该活动的关卡配置不存在, activityId:" .. activityId)
        return
    end
    local chapterStages = stageDic[chapterId]
    for index,stage in ipairs(chapterStages) do
        if index == stageId then
            return stage
        end
    end
end

function XPokemonConfigs.GetFightStageIds()
    local fightStageIds = {}
    for _, chapters in pairs(StageTemplate) do
        for _,chapterStages in pairs(chapters) do
            for _,stage in pairs(chapterStages) do
                if stage.StageId > 0 then
                    tableInsert(fightStageIds, stage.StageId)
                end
            end
        end
    end
    return fightStageIds
end

function XPokemonConfigs.GetRawConfigFightStageId(id)
    local template = StageRawTemplate[id]
    if not template then
        return
    end
    return template.StageId
end

function XPokemonConfigs.GetPokemonStageId(index,activityId,chapterId)
    local config = GetStageConfig(index, activityId, chapterId)
    return config.Id
end

function XPokemonConfigs.GetStageChapterIdByFightStageId(activityId,fightStageId)
    for _k,v in pairs(StageRawTemplate) do
        if v.ActivityId == activityId and v.StageId == fightStageId then
            return v.ChapterId
        end
    end
    return 0
end

function XPokemonConfigs.GetStageUnlockDesc(stageId, activityId, chapterId)
    local config = GetStageConfig(stageId, activityId, chapterId)
    return config.UnlockDesc
end

function XPokemonConfigs.GetStageFightStageId(stageId, activityId, chapterId)
    local config = GetStageConfig(stageId, activityId, chapterId)
    return config.StageId
end

function XPokemonConfigs.GetStageMonsterIds(stageId, activityId, chapterId)
    local stageMonsterIds = {}
    local config = GetStageConfig(stageId, activityId, chapterId)
    for index = 1, XPokemonConfigs.TeamNum do
        local stageMonsterId = config.StageMonsterId[index - 1]
        if stageMonsterId and stageMonsterId > 0 then
            stageMonsterIds[index] = stageMonsterId
        end
    end
    return stageMonsterIds
end

function XPokemonConfigs.GetStageIcon(stageId, activityId,chapterId)
    local fightStageId = XPokemonConfigs.GetStageFightStageId(stageId, activityId,chapterId)
    return XDataCenter.FubenManager.GetStageIcon(fightStageId)
end

function XPokemonConfigs.GetStageName(stageId, activityId,chapterId)
    local fightStageId = XPokemonConfigs.GetStageFightStageId(stageId, activityId,chapterId)
    return XDataCenter.FubenManager.GetStageName(fightStageId)
end

function XPokemonConfigs.GetStageBg(stageId, activityId,chapterId)
    local config = GetStageConfig(stageId, activityId,chapterId)
    return config.StageBg
end

function XPokemonConfigs.GetStageBossHeadIcon(stageId, activityId,chapterId)
    local config = GetStageConfig(stageId, activityId,chapterId)
    return config.BossHeadIcon
end

function XPokemonConfigs.IsBossStage(stageId, activityId,chapterId)
    local config = GetStageConfig(stageId, activityId,chapterId)
    return config.IsBossStage > 0
end

function XPokemonConfigs.IsInfinityStage(stageId, activityId,chapterId)
    --local config = GetStageConfig(stageId, activityId,chapterId)
    --return config.StageType == XPokemonConfigs.StageType.Infinity
    return false
end

function XPokemonConfigs.IsCanSkipStage(stageId, activityId, chapterId)
    local config = GetStageConfig(stageId, activityId,chapterId)
    return config.StageType == XPokemonConfigs.StageType.Skip
end

function XPokemonConfigs.GetStageCountByType(type, activityId,chapterId)
    local count = 0
    local configs = StageTemplate[activityId][chapterId]
    if not configs then
        XLog.Error("XPokemonConfigs.GetStageCountByType 该活动的关卡配置不存在:activityId:", activityId)
        return 0
    end
    for k, v in pairs(configs) do
        if v.StageType == type then
            count = count + 1
        end
    end
    return count
end

function XPokemonConfigs.GetStageCountByChapter(activityId, chapterId)
    local count = 0
    local configs = StageTemplate[activityId][chapterId]
    if not configs then
        XLog.Error("XPokemonConfigs.GetStageCountByChapter 该活动的关卡配置不存在:activityId:", activityId)
        return 0
    end
    for _ in pairs(configs) do
        count = count + 1
    end
    return count
end

function XPokemonConfigs.GetStageIdByFightStageId(activityId,fightStageId)
    return FightStageIdToStageIdDic[activityId][fightStageId] or 0
end

function XPokemonConfigs.GetShowAbility(stageId, activityId, pos,chapterId)
    local config = GetStageConfig(stageId, activityId,chapterId)
    return config.ShowAbility[pos - 1] or 0
end

--关卡怪物 begin--
local GetStageMonsterConfig = function(stageMonsterId)
    local config = StageMonsterTemplate[stageMonsterId]
    if not config then
        XLog.Error("XPokemonConfigs GetStageMonsterConfig error:配置不存在, stageMonsterId:" .. stageMonsterId)
        return
    end
    return config
end

function XPokemonConfigs.GetStageMonsterHeadIcon(stageMonsterId)
    local config = GetStageMonsterConfig(stageMonsterId)
    return config.HeadIcon
end

function XPokemonConfigs.GetStageMonsterLevel(stageMonsterId)
    local config = GetStageMonsterConfig(stageMonsterId)
    return config.Level
end

function XPokemonConfigs.GetStageMonsterAbility(stageMonsterId)
    local config = GetStageMonsterConfig(stageMonsterId)
    return config.Ability
end

function XPokemonConfigs.GetStageMonsterCareer(stageMonsterId)
    local config = GetStageMonsterConfig(stageMonsterId)
    return config.Career
end

function XPokemonConfigs.GetStageMonsterCareerName(stageMonsterId)
    local career = XPokemonConfigs.GetStageMonsterCareer(stageMonsterId)
    return XPokemonConfigs.GetCareerName(career)
end

function XPokemonConfigs.GetStageMonsterCareerIcon(stageMonsterId)
    local career = XPokemonConfigs.GetStageMonsterCareer(stageMonsterId)
    return XPokemonConfigs.GetCareerIcon(career)
end
--关卡怪物 end--
-----------------关卡相关 end--------------------
-----------------活动相关 begin-----------------
local function GetPokemonActivityCfgs(activityId)
    local config = PokemonActivityCfgs[activityId]
    if not config then
        XLog.Error("XPokemonConfigs GetPokemonActivityCfgs error:配置不存在, activityId:" .. activityId)
        return
    end
    return config
end

local function GetActivityTimeId(activityId)
    local config = GetPokemonActivityCfgs(activityId)
    return config.ActivityTimeId
end

function XPokemonConfigs.GetDefaultActivityId()
    return DefaultActivityId
end

function XPokemonConfigs.IsActivityInTime(activityId)
    return XFunctionManager.CheckInTimeByTimeId(GetActivityTimeId(activityId))
end

function XPokemonConfigs.HasActivityInTime()
    for k, v in pairs(PokemonActivityCfgs) do
        if XFunctionManager.CheckInTimeByTimeId(v.ActivityTimeId) then
            return true
        end
    end
    return false
end

function XPokemonConfigs.GetInTimeActivityId()
    for k, v in pairs(PokemonActivityCfgs) do
        if XFunctionManager.CheckInTimeByTimeId(v.ActivityTimeId) then
            return v.Id
        end
    end
end

function XPokemonConfigs.GetActivityTaskTimeLimitId(activityId)
    local config = GetPokemonActivityCfgs(activityId)
    return config.TaskTimeLimitId
end

function XPokemonConfigs.GetActivityStartTime(activityId)
    return XFunctionManager.GetStartTimeByTimeId(GetActivityTimeId(activityId))
end

function XPokemonConfigs.GetActivityEndTime(activityId)
    return XFunctionManager.GetEndTimeByTimeId(GetActivityTimeId(activityId))
end

function XPokemonConfigs.GetActivityBg(activityId)
    local config = GetPokemonActivityCfgs(activityId)
    return config.Bg or ""
end

function XPokemonConfigs.GetActivityName(activityId)
    local config = GetPokemonActivityCfgs(activityId)
    return config.Name or ""
end


-----------------活动相关 end-------------------
-----------------杂项 begin--------------------
local function GetPokemonInitCfgs(id)
    local config = PokemonInitCfgs[id]
    if not config then
        XLog.Error("XPokemonConfigs GetPokemonInitCfgs error:配置不存在, id:" .. id)
        return
    end
    return config
end

function XPokemonConfigs.GetTimeSupplyInterval()
    local config = GetPokemonInitCfgs(1)
    return config.TimeSupplyAccuInterval
end

function XPokemonConfigs.GetTimeSupplyMaxCount()
    local config = GetPokemonInitCfgs(1)
    return config.TimeSupplyMaxCount
end

function XPokemonConfigs.GetToCheckItemIdEventIds()
    local eventIds = {}
    for itemId in pairs(ItemIdCheckDic) do
        tableInsert(eventIds, XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. itemId)
    end
    return eventIds
end

function XPokemonConfigs.GetDefaultStageTimes()
    local config = GetPokemonInitCfgs(1)
    return config.DefaultStageTimes
end

function XPokemonConfigs.GetEnterMovieId()
    local config = GetPokemonInitCfgs(1)
    return config.DramaId
end

function XPokemonConfigs.GetDefaultStageTimesRecoverInterval()
    local config = GetPokemonInitCfgs(1)
    return config.StageTimesRecoverInterval
end

function XPokemonConfigs.GetHelpId()
    local config = GetPokemonInitCfgs(1)
    return config.HelpId
end

function XPokemonConfigs.GetSkipMaxTime()
    local config = GetPokemonInitCfgs(1)
    return config.StageSkipTimesMax
end

function XPokemonConfigs.GetSkipItemId()
    local config = GetPokemonInitCfgs(1)
    return config.SkipItemId
end

-----------------杂项 end--------------------

-----------------关卡UI模板 Begin-------------------
--设置的对象类型
XPokemonConfigs.ObjType = {
    Stage = 1,          --关卡
    Line = 2,           --关卡上的线
}

local DefaultTemplate = {
    PosX = 0,
    PosY = 0,
    PosZ = 0,
    ScaleX = 1,
    ScaleY = 1,
    ScaleZ = 1,
}

function XPokemonConfigs.GetUiTemplate(chapterId, index, type)
    local result
    for _,template in pairs(StageUITemplate) do
        if chapterId == template.ChapterId and index == template.Index and type == template.Type then
            result = {
                PosX = template.PosX,
                PosY = template.PosY,
                PosZ = template.PosZ,
                ScaleX = template.ScaleX,
                ScaleY = template.ScaleY,
                ScaleZ = template.ScaleZ
            }
        end
    end
    return result or DefaultTemplate
end

function XPokemonConfigs.GetUiTemplateCountByChapter(chapterId)
    local count = 0
    for _, template in pairs(StageUITemplate) do
        if template.ChapterId == chapterId then
            count = count + 1
        end
    end
    return count
end

-----------------关卡UI模板 End  -------------------