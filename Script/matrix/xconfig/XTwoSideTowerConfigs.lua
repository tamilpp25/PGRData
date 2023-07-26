XTwoSideTowerConfigs = XTwoSideTowerConfigs or {}
local ACTIVITY_CONFIG_PATH = "Share/Fuben/TwoSideTower/TwoSideTowerActivity.tab"
local CHAPTER_CONFIG_PATH = "Share/Fuben/TwoSideTower/TwoSideTowerChapter.tab"
local FEATURE_CONFIG_PATH = "Share/Fuben/TwoSideTower/TwoSideTowerFeature.tab"
local POINT_CONFIG_PATH = "Share/Fuben/TwoSideTower/TwoSideTowerPoint.tab"
local STAGE_CONFIG_PATH = "Share/Fuben/TwoSideTower/TwoSideTowerStage.tab"
local CLIENT_CONFIG_PATH = "Client/Fuben/TwoSideTower/TwoSideTowerClientConfig.tab"
local ActivityConfig = {}
local ChapterConfig = {}
local FeatureConfig = {}
local PointConfig = {}
local StageConfig = {}
local ClientConfig = {}

XTwoSideTowerConfigs.TaskId = 71

XTwoSideTowerConfigs.Direction = {
    Positive = 1,
    Negative = 2
}

-- 未确定特性的id
XTwoSideTowerConfigs.UnknowFeatureId = 0

function XTwoSideTowerConfigs.Init()
    ActivityConfig = XTableManager.ReadByIntKey(ACTIVITY_CONFIG_PATH, XTable.XTableTwoSideTowerActivity, "Id")
    ChapterConfig = XTableManager.ReadByIntKey(CHAPTER_CONFIG_PATH, XTable.XTableTwoSideTowerChapter, "Id")
    FeatureConfig = XTableManager.ReadByIntKey(FEATURE_CONFIG_PATH, XTable.XTableTwoSideTowerFeature, "Id")
    PointConfig = XTableManager.ReadByIntKey(POINT_CONFIG_PATH, XTable.XTableTwoSideTowerPoint, "Id")
    StageConfig = XTableManager.ReadByIntKey(STAGE_CONFIG_PATH,XTable.XTableTwoSideTowerStage,"Id")
    ClientConfig = XTableManager.ReadByStringKey(CLIENT_CONFIG_PATH, XTable.XTableTwoSideTowerClientConfig,"Key")
end

function XTwoSideTowerConfigs.GetActivityCfg(id)
    if not ActivityConfig[id] then
        XLog.ErrorTableDataNotFound("XTwoSideTowerConfigs.GetActivityCfg", "activityCfg", ACTIVITY_CONFIG_PATH, "Id", id)
        return
    end
    return ActivityConfig[id]
end

function XTwoSideTowerConfigs.GetChapterCfg(id)
    if not ChapterConfig[id] then
        XLog.ErrorTableDataNotFound("XTwoSideTowerConfigs.GetChapterCfg", "ChapterCfg", CHAPTER_CONFIG_PATH, "Id", id)
        return
    end
    return ChapterConfig[id]
end

function XTwoSideTowerConfigs.GetFeatureCfg(id)
    if not FeatureConfig[id] then
        XLog.ErrorTableDataNotFound("XTwoSideTowerConfigs.GetFeatureCfg", "FeatureCfg", FEATURE_CONFIG_PATH, "Id", id)
        return
    end
    return FeatureConfig[id]
end

function XTwoSideTowerConfigs.GetPointCfg(id)
    if not PointConfig[id] then
        XLog.ErrorTableDataNotFound("XTwoSideTowerConfigs.GetPointCfg", "PointCfg", POINT_CONFIG_PATH, "Id", id)
        return
    end
    return PointConfig[id]
end

function XTwoSideTowerConfigs.GetStageCfg(id)
    if not StageConfig[id] then
        XLog.ErrorTableDataNotFound("XTwoSideTowerConfigs.GetStageCfg", "StageCfg", STAGE_CONFIG_PATH, "Id", id)
        return
    end
    return StageConfig[id]
end

function XTwoSideTowerConfigs.GetStageCfgs()
    return StageConfig
end

function XTwoSideTowerConfigs.GetScoreLevelIcon(lv)
    local params = ClientConfig["ScoreLevelIcons"].Params
    local icon = params[lv]
    if not icon then
        XLog.ErrorTableDataNotFound("XTwoSideTowerConfigs.GetScoreLevelIcon", "ClientConfig ScoreLevelIcons", CLIENT_CONFIG_PATH, "lv", lv)
        return
    end
    return icon
end

function XTwoSideTowerConfigs.GetUnknowFeatureIcon()
    local params = ClientConfig["UnknowFeatureIcon"].Params
    return params[1]
end

function XTwoSideTowerConfigs.GetOverviewTabName()
    local params = ClientConfig["OverviewTabName"].Params
    return params[1]
end
