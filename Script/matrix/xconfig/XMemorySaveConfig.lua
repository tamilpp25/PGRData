local CSXTextManagerGetText = CS.XTextManager.GetText

XMemorySaveConfig = XMemorySaveConfig or {}

--region 玩法总功能表
local TABLE_ACTIVITY_PATH = "Share/Fuben/MemorySave/MemorySaveActivity.tab"
local ActivityConfig = {}

local function InitActivityConfig()
    ActivityConfig = XTableManager.ReadByIntKey(TABLE_ACTIVITY_PATH, XTable.XTableMemorySaveActivity, "Id")
end

local function GetActivityConfig(activityId)
    local config = ActivityConfig[activityId]
    if not config then
        XLog.Error("XMemorySaveConfig GetActivityConfig Error:配置不存在，activityId = "..activityId..",path = "..TABLE_ACTIVITY_PATH)
        return
    end
    return config
end

local function GetActivityTimeId(activityId)
    local config = GetActivityConfig(activityId)
    return config.TimeId
end

function XMemorySaveConfig.GetDefaultActivityId()
    local defaultActId = 0
    for actId, config in pairs(ActivityConfig) do
        defaultActId = actId
        if XTool.IsNumberValid(config.TimeId) and XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
            break
        end
    end
    return defaultActId
end

-- 活动开始
function XMemorySaveConfig.GetActivityStartTime(activityId)
    return XFunctionManager.GetStartTimeByTimeId(GetActivityTimeId(activityId))
end

-- 活动结束
function XMemorySaveConfig.GetActivityEndTime(activityId)
    return XFunctionManager.GetEndTimeByTimeId(GetActivityTimeId(activityId))
end

function XMemorySaveConfig.GetActivityChapterIds(activityId)
    local chapterIds = {}
    local config = GetActivityConfig(activityId)
    for _, chapterId in ipairs(config.ChapterIds) do
        if XTool.IsNumberValid(chapterId) then
            table.insert(chapterIds, chapterId)
        end
    end
    return chapterIds
end

function XMemorySaveConfig.GetActivityName(activityId)
    local config = GetActivityConfig(activityId)
    return config.ActivityName
end

function XMemorySaveConfig.GetActivityBanner(activityId)
    local config = GetActivityConfig(activityId)
    return config.ActivityBanner
end

--endregion

--region 章节关卡表
local TABLE_CHAPTER_PATH = "Share/Fuben/MemorySave/MemorySaveChapter.tab"
local ChapterConfig = {}


local function InitChapterConfig()
    ChapterConfig = XTableManager.ReadByIntKey(TABLE_CHAPTER_PATH, XTable.XTableMemorySaveChapter, "Id")
end

local function GetChapterConfig(chapterId)
    local config = ChapterConfig[chapterId]
    if not config then
        XLog.Error("XMemorySaveConfig GetChapterConfig Error:配置不存在，chapterId = "..chapterId..",path = "..TABLE_CHAPTER_PATH)
        return
    end
    return config
end

local function GetChapterTimeId(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.TimeId
end

-- 该章节是否开启
function XMemorySaveConfig.IsChapterOpen(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return false
    end
    local nowTime = XTime.GetServerNowTimestamp()
    local sTime = XMemorySaveConfig.GetChapterStartTime(chapterId)
    local eTime = XMemorySaveConfig.GetChapterEndTime(chapterId)
    return nowTime >= sTime and nowTime < eTime
end

function XMemorySaveConfig.GetChapterOpenTime(chapterId)
    if not XTool.IsNumberValid(chapterId) then
        return false
    end
    local sTime = XMemorySaveConfig.GetChapterStartTime(chapterId)
    return XTime.TimestampToLocalDateTimeString(sTime, "yyyy-MM-dd HH:mm")
end

function XMemorySaveConfig.GetChapterStartTime(chapterId)
    return XFunctionManager.GetStartTimeByTimeId(GetChapterTimeId(chapterId))
end

function XMemorySaveConfig.GetChapterEndTime(chapterId)
    return XFunctionManager.GetEndTimeByTimeId(GetChapterTimeId(chapterId))
end

function XMemorySaveConfig.GetChapterBannerBg(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.ChapterBg
end

function XMemorySaveConfig.GetChapterBtnBg(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.BtnChapterBg
end

function XMemorySaveConfig.GetChapterName(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.ChapterName
end

function XMemorySaveConfig.GetChapterBtnName(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.ChapterBtnName
end

function XMemorySaveConfig.GetStageBg(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.StageBg
end

function XMemorySaveConfig.GetChapterStageIds(chapterId)
    local stageIds = {}
    local config = GetChapterConfig(chapterId)
    for _, stageId in ipairs(config.StageIds) do
        if XTool.IsNumberValid(stageId) then
            table.insert(stageIds, stageId)
        end
    end
    return stageIds
end

function XMemorySaveConfig.GetStageShortName(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.StageShortName
end

function XMemorySaveConfig.GetStageLinePrefab(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.StageLinePrefab
end

function XMemorySaveConfig.GetChapterBtnIcon(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.BtnChapterIcon
end

function XMemorySaveConfig.GetChapterRewardIds(chapterId)
    local config = GetChapterConfig(chapterId)
    local rewardIds = {}
    for _, rewardId in ipairs(config.RewardIds) do
        if XTool.IsNumberValid(rewardId) then
            table.insert(rewardIds, rewardId)
        end
    end
    return rewardIds
end

-- 根据章节id与对应的下标获取对应的奖励条件
function XMemorySaveConfig.GetChapterRequirePass(chapterId, index)
    local config = GetChapterConfig(chapterId)
    return config.RequirePass[index]
end
--endregion
function XMemorySaveConfig.Init()
    InitActivityConfig()
    InitChapterConfig()
end