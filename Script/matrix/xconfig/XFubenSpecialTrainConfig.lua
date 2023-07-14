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
local TABLE_SPECIAL_TRAIN_FASHION_CUTE = "Share/Fuben/SpecialTrain/SpecialTrainFashionCute.tab"
local TABLE_SPECIAL_TRAIN_DISPLAY_ACTION = "Client/Fuben/SpecialTrain/SpecialTrainDisplayAction.tab"
local CHARACTER_TAB = "Share/Fuben/StageCharacterNpcId.tab"

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
local SpecialTrainFashionCuteConfig
local SpecialTrainDisplayActionConfig
local CharacterTab

XFubenSpecialTrainConfig.StageType = {
    None = -1,
    Normal = 0,
    Broadsword = 1,
    Alive = 2,
    Music = 3,
    Photo = 4,
    Snow = 5,
    Rhythm = 6, --元宵
    Breakthrough = 7, --超卡列特训关
}

XFubenSpecialTrainConfig.Type = {
    Normal = 1,
    Photo = 2,
    Music = 3,
    Snow = 4,
    Rhythm = 5, --元宵
    Breakthrough = 6, --超卡列特训关
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
    SpecialTrainFashionCuteConfig = XTableManager.ReadByIntKey(TABLE_SPECIAL_TRAIN_FASHION_CUTE, XTable.XTableSpecialTrainFashionCute, "CharacterId")
    SpecialTrainDisplayActionConfig = XTableManager.ReadByStringKey(TABLE_SPECIAL_TRAIN_DISPLAY_ACTION, XTable.XTableSpecialTrainDisplayAction, "ModelName")
    CharacterTab = {}
    for stageType, cfg in pairs(XTableManager.ReadByIntKey(CHARACTER_TAB, XTable.XTableStageCharacterNpcId, "StageType"))do
        for i = 1, #cfg.NpcId do
            local npcId = cfg.NpcId[i]
            local characterId = cfg.CharacterId[i]
            if not CharacterTab[npcId] then
                CharacterTab[npcId] = characterId
            elseif CharacterTab[npcId] ~= characterId then
                XLog.Error("[XFubenSpecialTrainConfig] 配置表StageCharacterNpcId里有相同npcId，但是characterId不同的配置:" .. (characterId or "nil"))
            end
        end    
    end
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
function XFubenSpecialTrainConfig.GetSpecialTrainStageById(id)
    if not SpecialTrainStageConfig or not SpecialTrainStageConfig[id] then
        XLog.Error("XFubenSpecialTrainConfig.GetSpecialTrainStageById 获取配置失败, id:",id)
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
        XLog.Error("XFubenSpecialTrainConfig GetSpecialTrainStageIconEffect error:配置不存在, stageId:" ..
                stageId .. ",path: " .. TABLE_SPECIALTRAIN_STAGEICONEFFECT)
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
    return XFubenSpecialTrainConfig.IsBreakthroughStageType(XFubenConfigs.GetStageType(stageId))
end

function XFubenSpecialTrainConfig.IsBreakthroughStageType(stageType)
    return stageType == XDataCenter.FubenManager.StageType.SpecialTrainBreakthrough
end

function XFubenSpecialTrainConfig.GetChapterSeasonName(id)
    return XFubenSpecialTrainConfig.GetChapterConfigById(id).SeasonName
end
--endregion

--region Q版角色模型
local function GetCuteModelConfig(characterId)
    if not SpecialTrainFashionCuteConfig[characterId] then
        XLog.Error("[XFubenSpecialTrainConfig] Q版模型配置没有角色" .. (characterId or "nil"))
    end
    return SpecialTrainFashionCuteConfig[characterId] or {}
end
function XFubenSpecialTrainConfig.GetCuteModelModelName(characterId)
    return GetCuteModelConfig(characterId).ModelName or ""
end
function XFubenSpecialTrainConfig.GetCuteModelSmallHeadIcon(characterId)
    return GetCuteModelConfig(characterId).SmallHeadIcon or ""
end
function XFubenSpecialTrainConfig.GetCuteModelHalfBodyImage(characterId)
    return GetCuteModelConfig(characterId).HalfBodyImage or ""
end
function XFubenSpecialTrainConfig.GetModelRandomAction(modelName)
    return SpecialTrainDisplayActionConfig[modelName].Action
end
function XFubenSpecialTrainConfig.GetCharacterIdByNpcId(npcId)
    return CharacterTab[npcId]
end
--endregion