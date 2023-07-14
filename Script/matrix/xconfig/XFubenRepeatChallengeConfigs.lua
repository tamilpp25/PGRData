local TABLE_ACTIVITY_PATH = "Share/Fuben/RepeatChallenge/RepeatChallengeActivity.tab"
local TABLE_CHAPTER_PATH = "Share/Fuben/RepeatChallenge/RepeatChallengeChapter.tab"
local TABLE_STAGE_PATH = "Share/Fuben/RepeatChallenge/RepeatChallengeStage.tab"
local TABLE_LEVEL_PATH = "Share/Fuben/RepeatChallenge/RepeatChallengeLevel.tab"
local TABLE_REWARD_PATH = "Share/Fuben/RepeatChallenge/RepeatChallengeReward.tab"

local pairs = pairs

local RepeatChallengeActivityTemplates = {}
local RepeatChallengeChapterTemplates = {}
local RepeatChallengeStageTemplates = {}
local RepeatChallengeLevelTemplates = {}
local RepeatChallengeRewardTemplates = {}

local DefaultActivityId = 0
local StageIdToChapterIdDic = {}

XFubenRepeatChallengeConfigs = XFubenRepeatChallengeConfigs or {}

function XFubenRepeatChallengeConfigs.Init()
    RepeatChallengeActivityTemplates = XTableManager.ReadByIntKey(TABLE_ACTIVITY_PATH, XTable.XTableRepeatChallengeActivity, "Id")
    RepeatChallengeChapterTemplates = XTableManager.ReadByIntKey(TABLE_CHAPTER_PATH, XTable.XTableRepeatChallengeChapter, "Id")
    RepeatChallengeStageTemplates = XTableManager.ReadByIntKey(TABLE_STAGE_PATH, XTable.XTableRepeatChallengeStage, "Id")
    RepeatChallengeLevelTemplates = XTableManager.ReadByIntKey(TABLE_LEVEL_PATH, XTable.XTableRepeatChallengeLevel, "Id")
    RepeatChallengeRewardTemplates = XTableManager.ReadByIntKey(TABLE_REWARD_PATH, XTable.XTableRepeatChallengeReward, "Id")

    for activityId, config in pairs(RepeatChallengeActivityTemplates) do
        if XTool.IsNumberValid(config.ActivityTimeId) then
	    if DefaultActivityId == 0 or DefaultActivityId < activityId then
                DefaultActivityId = activityId
	    end
        end
        DefaultActivityId = activityId--若全部过期，取最后一行配置作为默认下次开启的活动ID
    end
    for chapterId, chapterCfg in pairs(RepeatChallengeChapterTemplates) do
        for _, stageId in pairs(chapterCfg.StageId) do
            StageIdToChapterIdDic[stageId] = chapterId
        end
    end
end

function XFubenRepeatChallengeConfigs.GetChapterCfgs()
    return RepeatChallengeChapterTemplates
end

function XFubenRepeatChallengeConfigs.GetChapterCfgPath()
    return TABLE_CHAPTER_PATH
end

function XFubenRepeatChallengeConfigs.GetChapterCfg(chapterId)
    local chapterCfg = RepeatChallengeChapterTemplates[chapterId]
    if not chapterCfg then
        XLog.ErrorTableDataNotFound("XFubenRepeatChallengeConfigs.GetChapterCfg",
        "RepeatChallengeChapter", TABLE_CHAPTER_PATH, "chapterId", tostring(chapterId))
        return
    end
    return chapterCfg
end

function XFubenRepeatChallengeConfigs.GetActivityConfig(activityId)
    local activityCfg = RepeatChallengeActivityTemplates[activityId]
    if not activityCfg then
        XLog.ErrorTableDataNotFound("XFubenRepeatChallengeConfigs.GetActivityConfig",
        "RepeatChallengeActivity", TABLE_ACTIVITY_PATH, "activityId", tostring(activityId))
        return
    end
    return activityCfg
end

function XFubenRepeatChallengeConfigs.GetLevelConfigs()
    return RepeatChallengeLevelTemplates
end

function XFubenRepeatChallengeConfigs.GetMaxLevel()
    return #RepeatChallengeLevelTemplates
end

function XFubenRepeatChallengeConfigs.GetLevelConfig(level)
    local activityCfg = RepeatChallengeLevelTemplates[level]
    if not activityCfg then
        XLog.ErrorTableDataNotFound("XFubenRepeatChallengeConfigs.GetLevelConfig", "RepeatChallengeLevel", TABLE_LEVEL_PATH, "level", tostring(level))
        return
    end
    return activityCfg
end

function XFubenRepeatChallengeConfigs.GetStageConfig(stageId)
    local activityCfg = RepeatChallengeStageTemplates[stageId]
    if not activityCfg then
        XLog.ErrorTableDataNotFound("XFubenRepeatChallengeConfigs.GetStageConfig",
        "RepeatChallengeStage", TABLE_STAGE_PATH, "stageId", tostring(stageId))
        return
    end
    return activityCfg
end

function XFubenRepeatChallengeConfigs.GetChapterRewardConfig(chapterId)
    local activityCfg = RepeatChallengeRewardTemplates[chapterId]
    if not activityCfg then
        XLog.ErrorTableDataNotFound("XFubenRepeatChallengeConfigs.GetChapterRewardConfig",
        "RepeatChallengeReward", TABLE_REWARD_PATH, "chapterId", tostring(chapterId))
        return
    end
    return activityCfg
end

function XFubenRepeatChallengeConfigs.GetDefaultActivityId()
    return DefaultActivityId
end

function XFubenRepeatChallengeConfigs.GetChapterIdByStageId(stageId)
    return StageIdToChapterIdDic[stageId]
end