local TABLE_BOSS_ACTIVITY_PATH = "Share/Fuben/BossActivity/BossActivity.tab"
local TABLE_BOSS_SECTION_PATH = "Share/Fuben/BossActivity/BossSection.tab"
local TABLE_BOSS_CHALLENGE_PATH = "Share/Fuben/BossActivity/BossChallenge.tab"
local TABLE_BOSS_CHALLENGE_RES_PATH = "Client/Fuben/BossActivity/BossChallengeRes.tab"
local TABLE_BOSS_STARREWARD_PATH = "Share/Fuben/BossActivity/BossStarReward.tab"

local pairs = pairs

local BossActivityTemplates = {}
local BossSectionTemplates = {}
local BossChallengeTemplates = {}
local BossChallengeResTemplates = {}
local BossStarRewardTemplates = {}

local DefaultActivityId = 0
local ChallengeIdToOrderIdDic = {}
local StageIdToChallengeIdDic = {}

XFubenActivityBossSingleConfigs = XFubenActivityBossSingleConfigs or {}

function XFubenActivityBossSingleConfigs.Init()
    BossActivityTemplates = XTableManager.ReadByIntKey(TABLE_BOSS_ACTIVITY_PATH, XTable.XTableBossActivity, "Id")
    BossSectionTemplates = XTableManager.ReadByIntKey(TABLE_BOSS_SECTION_PATH, XTable.XTableBossSection, "Id")
    BossChallengeTemplates = XTableManager.ReadByIntKey(TABLE_BOSS_CHALLENGE_PATH, XTable.XTableBossChallenge, "Id")
    BossChallengeResTemplates = XTableManager.ReadByIntKey(TABLE_BOSS_CHALLENGE_RES_PATH, XTable.XTableBossChallengeRes, "Id")
    BossStarRewardTemplates = XTableManager.ReadByIntKey(TABLE_BOSS_STARREWARD_PATH, XTable.XTableBossStarReward, "Id")

    for activityId, config in pairs(BossActivityTemplates) do
        if XTool.IsNumberValid(config.ActivityTimeId) then
            DefaultActivityId = activityId
            break
        end
        DefaultActivityId = activityId--若全部过期，取最后一行配置作为默认下次开启的活动ID
    end

    for _, sectionCfg in pairs(BossSectionTemplates) do
        for index, challengeId in ipairs(sectionCfg.ChallengeId) do
            ChallengeIdToOrderIdDic[challengeId] = index
        end
    end

    for challengeId, challengeCfg in pairs(BossChallengeTemplates) do
        StageIdToChallengeIdDic[challengeCfg.StageId] = challengeId
    end
end

function XFubenActivityBossSingleConfigs.GetSectionCfgs()
    return BossSectionTemplates
end

function XFubenActivityBossSingleConfigs.GetSectionCfg(sectionId)
    local sectionCfg = BossSectionTemplates[sectionId]
    if not sectionCfg then
        XLog.ErrorTableDataNotFound("XFubenActivityBossSingleConfigs.GetSectionCfg",
        "BossSection", TABLE_BOSS_SECTION_PATH, "sectionId", tostring(sectionId))
        return
    end
    return sectionCfg
end

function XFubenActivityBossSingleConfigs.GetStageId(challengeId)
    local challengeCfg = BossChallengeTemplates[challengeId]
    if not challengeCfg then
        XLog.ErrorTableDataNotFound("XFubenActivityBossSingleConfigs.GetStageId",
        "BossChallenge", TABLE_BOSS_CHALLENGE_PATH, "challengeId", tostring(challengeId))
        return
    end
    return challengeCfg.StageId
end

function XFubenActivityBossSingleConfigs.GetChanllengeIdByStageId(stageId)
    return StageIdToChallengeIdDic[stageId]
end

function XFubenActivityBossSingleConfigs.GetChallengeResCfg(challengeId)
    local challengeResCfg = BossChallengeResTemplates[challengeId]
    if not challengeResCfg then
        XLog.ErrorTableDataNotFound("XFubenActivityBossSingleConfigs.GetChallengeResCfg",
        "BossChallengeRes", TABLE_BOSS_CHALLENGE_RES_PATH, "challengeId", tostring(challengeId))
        return
    end
    return challengeResCfg
end

function XFubenActivityBossSingleConfigs.GetChallengeOrderId(challengeId)
    return ChallengeIdToOrderIdDic[challengeId] or 0
end

function XFubenActivityBossSingleConfigs.GetActivityConfig(activityId)
    local activityCfg = BossActivityTemplates[activityId]
    return activityCfg
end

function XFubenActivityBossSingleConfigs.GetDefaultActivityId()
    return DefaultActivityId
end

function XFubenActivityBossSingleConfigs.GetBossChallengeTemplates()
    return BossChallengeTemplates
end

function XFubenActivityBossSingleConfigs.GetStageAttention(stageId)
    if BossChallengeTemplates == nil then
        return
    end
    local challengeId = XFubenActivityBossSingleConfigs.GetChanllengeIdByStageId(stageId)
    if BossChallengeTemplates[challengeId].StageAttention ~= nil then
        return BossChallengeTemplates[challengeId].StageAttention
    end
    return nil
end

function XFubenActivityBossSingleConfigs.GetStageAttentionTitle(stageId)
    if BossChallengeTemplates == nil then
        return
    end
    local challengeId = XFubenActivityBossSingleConfigs.GetChanllengeIdByStageId(stageId)
    if BossChallengeTemplates[challengeId].StageAttention ~= nil then
        return BossChallengeTemplates[challengeId].StageAttentionTitle
    end
    return nil
end

function XFubenActivityBossSingleConfigs.GetChallengeCount(sectionId)
    return #BossSectionTemplates[sectionId].ChallengeId
end

function XFubenActivityBossSingleConfigs.GetBossSectionRewardIds(sectionId)
    return BossSectionTemplates[sectionId].StarRewardId
end

function XFubenActivityBossSingleConfigs.GetStarRewardCfg(Id)
    return BossStarRewardTemplates[Id]
end

function XFubenActivityBossSingleConfigs.GetStarRewardTemplates()
    return BossStarRewardTemplates
end

function XFubenActivityBossSingleConfigs.GetBossChallengeEffectPath(stageId)
    if BossChallengeTemplates == nil then
        return
    end
    local challengeId = XFubenActivityBossSingleConfigs.GetChanllengeIdByStageId(stageId)
    if BossChallengeTemplates[challengeId].EffectPath ~= nil then
        return BossChallengeTemplates[challengeId].EffectPath
    end
    return nil
end

function XFubenActivityBossSingleConfigs.GetLastBossActivityTemplates()
    return BossActivityTemplates[#BossActivityTemplates]
end

function XFubenActivityBossSingleConfigs.GetActivityBeginTime(activityId)
    local config = XFubenActivityBossSingleConfigs.GetActivityConfig(activityId)
    if not config then
        config = XFubenActivityBossSingleConfigs.GetLastBossActivityTemplates()
    end

    return config and XFunctionManager.GetStartTimeByTimeId(config.ActivityTimeId) or 0
end

function XFubenActivityBossSingleConfigs.GetActivityEndTime(activityId)
    local config = XFubenActivityBossSingleConfigs.GetActivityConfig(activityId)
    if not config then
        config = XFubenActivityBossSingleConfigs.GetLastBossActivityTemplates()
    end

    return config and XFunctionManager.GetEndTimeByTimeId(config.ActivityTimeId) or 0
end

function XFubenActivityBossSingleConfigs.GetFightEndTime(activityId)
    local config = XFubenActivityBossSingleConfigs.GetActivityConfig(activityId)
    if not config then
        config = XFubenActivityBossSingleConfigs.GetLastBossActivityTemplates()
    end

    return config and XFunctionManager.GetEndTimeByTimeId(config.FightTimeId) or 0
end