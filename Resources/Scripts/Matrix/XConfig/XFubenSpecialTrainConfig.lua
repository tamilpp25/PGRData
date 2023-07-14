XFubenSpecialTrainConfig = XFubenSpecialTrainConfig or {}

local TABLE_SPECIALTRAIN_ACTIVITY = "Share/Fuben/SpecialTrain/Activity.tab"
local TABLE_SPECIALTRAIN_CHAPTER = "Share/Fuben/SpecialTrain/Chapter.tab"
local TABLE_SPECIALTRAIN_STARREWARD = "Share/Fuben/SpecialTrain/StarReward.tab"
local TABLE_SPECIALTRAIN_STAGE = "Share/Fuben/SpecialTrain/SpecialTrainStage.tab"
local TABLE_SPECIALTRAIN_POINTREWARD = "Share/Fuben/SpecialTrain/PointReward.tab"
--local TABLE_SUMMER_EPISODE_MAP_CONFIG = "Client/Fuben/SpecialTrain/SummerEpisodeMapConfig.tab"

local StarRewardConfig
local ChapterConfig
local ActivityConfig
local SpecialTrainStageConfig
local SpecialPointRewardConfig
local SummerEpisodeMapConfig --夏活特训关 关卡选择界面的背景图片配置

XFubenSpecialTrainConfig.StageType = {
    None = -1,
    Normal = 0,
    Broadsword = 1,
    Alive = 2
}



function XFubenSpecialTrainConfig.Init()
    StarRewardConfig = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_STARREWARD, XTable.XTableSpecialTrainStarReward, "Id")
    ChapterConfig = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_CHAPTER, XTable.XTableSpecialTrainChapter, "Id")
    ActivityConfig = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_ACTIVITY, XTable.XTableSpecialTrainActivity, "Id")
    SpecialTrainStageConfig = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_STAGE, XTable.XTableSpecialTrainStage, "Id")
    SpecialPointRewardConfig = XTableManager.ReadByIntKey(TABLE_SPECIALTRAIN_POINTREWARD, XTable.XTableSpecialTrainPointReward, "Id")
    --SummerEpisodeMapConfig = XTableManager.ReadByIntKey(TABLE_SUMMER_EPISODE_MAP_CONFIG, XTable.XTableSummerEpisodeMapConfig, "Id")
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

function XFubenSpecialTrainConfig.GetSummerEpisodeMapBg(stageId)
    local config = SummerEpisodeMapConfig[stageId]
    if not config then
        XLog.Error("XFubenSpecialTrainConfig.GetSummerEpisodeMapBg ,配置不存在 stageId:", stageId)
        return
    end
    return config.Bg
end

function XFubenSpecialTrainConfig.GetSummerEpisodePictureList()
    local list = {}
    for _,config in pairs(SummerEpisodeMapConfig) do
        table.insert(list,config.Picture)
    end
    return list
end