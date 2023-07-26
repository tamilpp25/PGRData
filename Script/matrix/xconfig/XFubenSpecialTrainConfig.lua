XFubenSpecialTrainConfig = XFubenSpecialTrainConfig or {}

local TABLE_SPECIALTRAIN_ACTIVITY = "Share/Fuben/SpecialTrain/Activity.tab"
local TABLE_SPECIALTRAIN_CHAPTER = "Share/Fuben/SpecialTrain/Chapter.tab"
local TABLE_SPECIALTRAIN_STARREWARD = "Share/Fuben/SpecialTrain/StarReward.tab"
local TABLE_SPECIALTRAIN_STAGE = "Share/Fuben/SpecialTrain/SpecialTrainStage.tab"
local TABLE_SPECIALTRAIN_POINTREWARD = "Share/Fuben/SpecialTrain/PointReward.tab"
local TABLE_SPECIALTRAIN_RANK_TIER = "Share/Fuben/SpecialTrain/RankTier.tab"
local TABLE_SPECIALTRAIN_RANK_SCORE_GOODS = "Share/Fuben/SpecialTrain/RankScoreGoods.tab"
local TABLE_SPECIALTRAIN_ALBUM_CONFIG = "Client/Fuben/SpecialTrain/SpecialTrainAlbumConfig.tab"
local TABLE_SPECIALTRAIN_RANDOM_STAGE = "Client/Fuben/SpecialTrain/SpecialTrainRandomStage.tab" 
local TABLE_SPECIALTRAIN_STAGEICONEFFECT = "Client/Fuben/SpecialTrain/SpecialTrainStageIconEffect.tab"
local TABLE_YUANXIAO_SKILL = "Share/Fuben/SpecialTrain/SpecialTrainRhythmRankSkill.tab"
local TABLE_SPECIALTRAIN_DAILY_SWITCH_TASK = "Share/Fuben/SpecialTrain/SpecialTrainDailySwitchTask.tab"

local StarRewardConfig
local ChapterConfig
local ActivityConfig
local SpecialTrainStageConfig
local SpecialPointRewardConfig
local SpecialRankTierConfig
local SpecialRankScoreGoodsConfig
local SpecialTrainAlbumConfig
local SpecialTrainRandomStage
local SpecialTrainStageIconEffect
local YuanXiaoSkillConfig
local SpecialTrainDailySwitchTaskConfig

XFubenSpecialTrainConfig.StageType = {
    None = -1,
    Normal = 0,
    Broadsword = 1,
    Alive = 2,
    Music = 3,
    Photo = 4,
    Snow = 5,
    Rhythm = 6, --元宵
    --Breakthrough = 7, --超卡列特训关 1.0
    Breakthrough = 8, --超卡列特训关 2.0
}

XFubenSpecialTrainConfig.Type = {
    Normal = 1,
    Photo = 2,
    Music = 3,
    Snow = 4,
    Rhythm = 5, --元宵
    --Breakthrough = 6, --超卡列特训关 1.0
    Breakthrough = 7, --超卡列特训关 2.0
}

XFubenSpecialTrainConfig.SpecialTrainMusicTaskId = {
    DailyId = 83,
    ChallengeId = 84
}

function XFubenSpecialTrainConfig.Init()
    StarRewardConfig = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_STARREWARD, XTable.XTableSpecialTrainStarReward, "Id")
    ChapterConfig = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_CHAPTER, XTable.XTableSpecialTrainChapter, "Id")
    ActivityConfig = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_ACTIVITY, XTable.XTableSpecialTrainActivity, "Id")
    SpecialTrainStageConfig = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_STAGE, XTable.XTableSpecialTrainStage, "Id")
    SpecialPointRewardConfig = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_POINTREWARD, XTable.XTableSpecialTrainPointReward, "Id")
    SpecialRankTierConfig = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_RANK_TIER, XTable.XTableSpecialTrainRankTier, "Id")
    SpecialRankScoreGoodsConfig = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_RANK_SCORE_GOODS, XTable.XTableSpecialRankScoreGoods, "Id")
    SpecialTrainAlbumConfig = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_ALBUM_CONFIG, XTable.XTableSpecialTrainAlbumConfig, "Id")
    SpecialTrainRandomStage = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_RANDOM_STAGE, XTable.XTableSpecialTrainRandomStage, "Id")
    SpecialTrainStageIconEffect = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_STAGEICONEFFECT, XTable.XTableSpecialTrainStageIconEffect, "StageId")
    
    YuanXiaoSkillConfig = XTableManager.ReadByIntKey(TABLE_YUANXIAO_SKILL, XTable.XTableSpecialTrainRhythmRankSkill, "Id")
    SpecialTrainDailySwitchTaskConfig = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_DAILY_SWITCH_TASK, XTable.XTableSpecialTrainDailySwitchTask, "Id")
end

--获取活动数据
function XFubenSpecialTrainConfig.GetActivityConfigById(id)
    local retConfig

    --默认返回活动配置最后一行
    if not id then
        for _, config in ipairs(ActivityConfig) do
            retConfig = config
        end
    else
        retConfig = ActivityConfig[id]
    end

    if not retConfig then
        XLog.ErrorTableDataNotFound("XFubenSpecialTrainConfig.GetActivityConfigById",
        "ActivityConfig", TABLE_SPECIALTRAIN_ACTIVITY, "Id", tostring(id))
        return
    end

    return retConfig
end

--获取章节数据
function XFubenSpecialTrainConfig.GetChapterConfigById(id)
    if not ChapterConfig or not ChapterConfig[id] then
        XLog.ErrorTableDataNotFound("XFubenSpecialTrainConfig.GetChapterConfigById",
        "ChapterConfig", TABLE_SPECIALTRAIN_CHAPTER, "Id", tostring(id))
        return
    end

    return ChapterConfig[id]
end

--获取章节关卡数据
function XFubenSpecialTrainConfig.GetSpecialTrainStageById(id, notWarning)
    if not SpecialTrainStageConfig or not SpecialTrainStageConfig[id] then
        if not notWarning then
            XLog.Error("XFubenSpecialTrainConfig.GetSpecialTrainStageById 获取配置失败, id:",id)
        end
        return
    end

    return SpecialTrainStageConfig[id]
end

--获取章节数据
function XFubenSpecialTrainConfig.GetChapterConfig()
    return ChapterConfig
end

--获取星星奖励数据
function XFubenSpecialTrainConfig.GetStarRewardConfigById(id)
    if not StarRewardConfig or not StarRewardConfig[id] then
        XLog.ErrorTableDataNotFound("XFubenSpecialTrainConfig.GetStarRewardConfigById",
        "StarRewardConfig", TABLE_SPECIALTRAIN_STARREWARD, "Id", tostring(id))
        return
    end

    return StarRewardConfig[id]
end

--检测是否是特训关联机
function XFubenSpecialTrainConfig.CheckIsSpecialTrainStage(stageId)
    local config = XFubenSpecialTrainConfig.GetSpecialTrainStageById(stageId)
    if not config then
        return false
    end

    if config.Type == XFubenSpecialTrainConfig.StageType.Broadsword then
        return true
    end

    if config.Type == XFubenSpecialTrainConfig.StageType.Alive then
        return true
    end
    
    return false
end

--检测是否是特训关大刀联机
function XFubenSpecialTrainConfig.CheckIsSpecialTrainBroadswordStage(stageId)
    local config = XFubenSpecialTrainConfig.GetSpecialTrainStageById(stageId)
    if not config then
        return false
    end

    if config.Type == XFubenSpecialTrainConfig.StageType.Broadsword then
        return true
    end

    return false
end

--检测是否是魔方2.0
function XFubenSpecialTrainConfig.CheckIsSpecialTrainBreakthroughStage(stageId)
    local config = XFubenSpecialTrainConfig.GetSpecialTrainStageById(stageId, true)
    if not config then
        return false
    end

    if config.Type == XFubenSpecialTrainConfig.StageType.Breakthrough then
        return true
    end

    return false
end

--检测是否是元宵活动
function XFubenSpecialTrainConfig.CheckIsYuanXiaoStage(stageId)
    local config = XFubenSpecialTrainConfig.GetSpecialTrainStageById(stageId, true)
    if not config then
        return false
    end

    if config.Type == XFubenSpecialTrainConfig.StageType.Rhythm then
        return true
    end

    return false
end

-- 检测是否是冰雪感谢祭活动
function XFubenSpecialTrainConfig.CheckIsSnowGameStage(stageId)
    local config = XFubenSpecialTrainConfig.GetSpecialTrainStageById(stageId, true)
    if not config then
        return false
    end

    if config.Type == XFubenSpecialTrainConfig.StageType.Snow then
        return true
    end

    return false
end

function XFubenSpecialTrainConfig.GetSpecialPointRewardConfig(id)
    if not SpecialPointRewardConfig or not SpecialPointRewardConfig[id] then
        XLog.ErrorTableDataNotFound("XFubenSpecialTrainConfig.GetSpecialPointRewardConfig",
        "GetSpecialPointRewardConfig", TABLE_SPECIALTRAIN_POINTREWARD, "Id", tostring(id))
        return
    end
    return SpecialPointRewardConfig[id]
end

function XFubenSpecialTrainConfig.GetAlbumIdByStageId(stageId)
    local config = XFubenSpecialTrainConfig.GetSpecialTrainStageById(stageId)
    return config.AlbumId
end

function XFubenSpecialTrainConfig.GetHellStageId(stageId)
    local config = XFubenSpecialTrainConfig.GetSpecialTrainStageById(stageId)
    return config.HellStageId
end

function XFubenSpecialTrainConfig.GetHellStageTimeId(stageId)
    local config = XFubenSpecialTrainConfig.GetSpecialTrainStageById(stageId)
    local hellStageId = config.HellStageId
    if hellStageId and hellStageId ~= 0 and hellStageId ~= stageId then
        return XFubenSpecialTrainConfig.GetHellStageTimeId(hellStageId)
    end
    return config.TimeId
end

function XFubenSpecialTrainConfig.GetStageByStageType(stageType)
   local stageList = {}
    for _,v in pairs(SpecialTrainStageConfig) do
        if v.Type == stageType then
            table.insert(stageList,v.Id)
        end
    end
    return stageList
end

function XFubenSpecialTrainConfig.IsSpecialTrainStage(stageId, stageType)
    for _,stage in pairs(SpecialTrainStageConfig) do
        if (stage.Id == stageId or stage.HellStageId == stageId) and stage.Type == stageType then
            return true
        end
    end
    return false
end

function XFubenSpecialTrainConfig.GetStageIdByHellId(hellStageId)
    for _,v in pairs(SpecialTrainStageConfig) do
        if v.HellStageId == hellStageId then
            return v.Id
        end
    end
end

function XFubenSpecialTrainConfig.IsHellStageId(hellStageId)
    for _,v in pairs(SpecialTrainStageConfig) do
        if v.HellStageId == hellStageId then
            return true
        end
    end
    return false
end

function XFubenSpecialTrainConfig.GetSpecialTrainStage()
    return SpecialTrainStageConfig
end

function XFubenSpecialTrainConfig.GetSpecialTrainAlbum(id)
    if not SpecialTrainAlbumConfig[id] then
        XLog.Error("XFubenSpecialTrainConfig.GetSpecialTrainAlbum 获取配置失败,id:", id)
        return 
    end
    return SpecialTrainAlbumConfig[id]
end

local function GetSpecialRankTierConfig(id)
    local config = SpecialRankTierConfig[id]
    if not config then
        XLog.Error("XFubenSpecialTrainConfig GetSpecialRankTierConfig error:配置不存在, id:" ..
                id .. ",path: " .. TABLE_SPECIALTRAIN_RANK_TIER)
        return
    end
    
    return config
end

function XFubenSpecialTrainConfig.GetCurrentRankId(activityId, curScore)
    local curRankId
    for _, rankTier in pairs(SpecialRankTierConfig) do
        if curScore >= rankTier.Score and rankTier.ActivityId == activityId then
            curRankId = rankTier.Id
        end
    end
    
    return curRankId
end

function XFubenSpecialTrainConfig.GetCurIdAndNextIdByScore(activityId, curScore)
    local curRankId = XFubenSpecialTrainConfig.GetCurrentRankId(activityId, curScore)
    local config = GetSpecialRankTierConfig(curRankId)
    local nextRankId = config.NextRankId
    local isHighestGrade = not XTool.IsNumberValid(nextRankId)

    return curRankId, isHighestGrade, nextRankId
end 

function XFubenSpecialTrainConfig.GetRankIconById(id)
    local config = GetSpecialRankTierConfig(id)
    return config.Icon
end

function XFubenSpecialTrainConfig.GetRankScoreById(id)
    local config = GetSpecialRankTierConfig(id)
    return config.Score
end

function XFubenSpecialTrainConfig.GetRankTierDescribeById(id)
    local config = GetSpecialRankTierConfig(id)
    return config.TierDescribe
end

function XFubenSpecialTrainConfig.GetRankTierNameById(id)
    local config = GetSpecialRankTierConfig(id)
    return config.TierName
end

function XFubenSpecialTrainConfig.GetRankAllId(activityId)
    local allId = {}
    for _, rankTier in pairs(SpecialRankTierConfig) do
        if rankTier.ActivityId == activityId then
            table.insert(allId, rankTier.Id)
        end
    end
    table.sort(allId, function(a, b)
        return a < b
    end)
    return allId
end 

--当前id是否是最低段位
function XFubenSpecialTrainConfig.CheckLowestGrade(id)
    local config = GetSpecialRankTierConfig(id)
    if XTool.IsNumberValid(config.LowestGrade) and config.LowestGrade == 1 then
        return true
    end
    return false
end

local function GetSpecialRankScoreGoodsConfig(id)
    local config = SpecialRankScoreGoodsConfig[id]
    if not config then
        XLog.Error("XFubenSpecialTrainConfig GetSpecialRankScoreGoodsConfig error:配置不存在, id:" ..
                id .. ",path: " .. TABLE_SPECIALTRAIN_RANK_SCORE_GOODS)
        return
    end

    return config
end

function XFubenSpecialTrainConfig.GetRankScoreGoodName(templateId)
    local config = GetSpecialRankScoreGoodsConfig(templateId)
    if config then
        return config.Name
    end
    return ""
end

function XFubenSpecialTrainConfig.GetRankScoreGoodIcon(templateId)
    local config = GetSpecialRankScoreGoodsConfig(templateId)
    if config then
        return config.Icon
    end
    return ""
end

function XFubenSpecialTrainConfig.GetRankScoreGoodQuality(templateId)
    local config = GetSpecialRankScoreGoodsConfig(templateId)
    if config then
        return config.Quality
    end
    return 0
end

function XFubenSpecialTrainConfig.GetRankScoreGoodDescription(templateId)
    local config = GetSpecialRankScoreGoodsConfig(templateId)
    if config then
        return config.Description
    end
    return ""
end

--region 随机关卡配置
local function GetSpecialTrainRandomStage(id)
    local config = SpecialTrainRandomStage[id]
    if not config then
        XLog.Error("XFubenSpecialTrainConfig GetSpecialTrainRandomStage error:配置不存在, id:" ..
                id .. ",path: " .. TABLE_SPECIALTRAIN_RANDOM_STAGE)
        return
    end

    return config
end

function XFubenSpecialTrainConfig.GetRandomStageNameById(id)
    local config = GetSpecialTrainRandomStage(id)
    if config then
        return config.Name
    end
    return ""
end

function XFubenSpecialTrainConfig.GetRandomStageDescriptionById(id)
    local config = GetSpecialTrainRandomStage(id)
    if config then
        return config.Description
    end
    return ""
end

function XFubenSpecialTrainConfig.GetRandomStageIconById(id)
    local config = GetSpecialTrainRandomStage(id)
    if config then
        return config.Icon
    end
    return ""
end

function XFubenSpecialTrainConfig.GetRandomStageStoryIconById(id)
    local config = GetSpecialTrainRandomStage(id)
    if config then
        return config.StoryIcon
    end
    return ""
end

function XFubenSpecialTrainConfig.GetRandomStageIconEffectById(id)
    local config = GetSpecialTrainRandomStage(id)
    if config then
        return config.IconEffect
    end
    return ""
end

--endregion

--region SpecialTrainStageIconEffect.tab

local function GetSpecialTrainStageIconEffect(stageId)
    local config = SpecialTrainStageIconEffect[stageId]
    if not config then
        -- 元宵2023不需要特效
        --XLog.Error("XFubenSpecialTrainConfig GetSpecialTrainStageIconEffect error:配置不存在, stageId:" ..
        --        stageId .. ",path: " .. TABLE_SPECIALTRAIN_STAGEICONEFFECT)
        return
    end

    return config
end

function XFubenSpecialTrainConfig.GetIconEffectByStageId(stageId)
    local config = GetSpecialTrainStageIconEffect(stageId)
    if config then
        return config.IconEffect
    end
    return ""
end

--endregion

--region Breakthrough 卡列特训关
function XFubenSpecialTrainConfig.IsBreakthroughStage(stageId)
    return XFubenSpecialTrainConfig.CheckIsSpecialTrainBreakthroughStage(stageId)
end

function XFubenSpecialTrainConfig.IsBreakthroughStageType(stageType)
    return stageType == XDataCenter.FubenManager.StageType.SpecialTrainBreakthrough
end

function XFubenSpecialTrainConfig.GetChapterSeasonName(id)
    return XFubenSpecialTrainConfig.GetChapterConfigById(id).SeasonName
end

XFubenSpecialTrainConfig.AnimationPhase = {
    Phase1 = 1,
    Phase2 = 2,
    Phase3 = 3,
    Phase4 = 4,
    PhaseEnd = 5,
}
--endregion

function XFubenSpecialTrainConfig.GetAllYuanXiaoSkill()
    return YuanXiaoSkillConfig
end

function XFubenSpecialTrainConfig.GetYuanXiaoSkill(id)
    return YuanXiaoSkillConfig[id]
end

function XFubenSpecialTrainConfig.GetDailyTaskGroupId(activityId, dayId)
    if not XFubenSpecialTrainConfig._DailyTaskDic then
        XFubenSpecialTrainConfig._DailyTaskDic = {}
        for _, config in pairs(SpecialTrainDailySwitchTaskConfig) do
            XFubenSpecialTrainConfig._DailyTaskDic[config.ActivityId] = XFubenSpecialTrainConfig._DailyTaskDic[config.ActivityId] or {}
            XFubenSpecialTrainConfig._DailyTaskDic[config.ActivityId][config.DayId] = config
        end
    end
    local maxCount = #XFubenSpecialTrainConfig._DailyTaskDic[activityId]
    if dayId > maxCount then
        dayId = maxCount
    end
    local config = XFubenSpecialTrainConfig._DailyTaskDic[activityId][dayId]
    if not config then
        return 0
    end
    return config.DailyTaskGroupId or 0
end

function XFubenSpecialTrainConfig.GetSpecialTrainStageTimeId(stageId)
    if SpecialTrainStageConfig[stageId] then
        return SpecialTrainStageConfig[stageId].TimeId
    end
    return -1
end 

--获取关卡本地键名：是否是新解锁且未选择过
function XFubenSpecialTrainConfig.GetStageLocalKey(activityId,stageId)
    return tostring(XPlayer.Id)..tostring(activityId)..tostring(stageId)..'SummerEpisode_Use_State'
end 