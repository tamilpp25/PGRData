local tonumber = tonumber
local tableInsert = table.insert
local tableSort = table.sort
local ipairs = ipairs
local pairs = pairs
local CSXTextManagerGetText = CS.XTextManager.GetText

XKillZoneConfigs = XKillZoneConfigs or {}

XKillZoneConfigs.ItemIdCoinB = 62412 --货币B

-----------------活动相关 begin-----------------
local TABLE_ACITIVTY_PATH = "Share/Fuben/KillZone/KillZoneActivity.tab"

local ActivityConfig = {}

local function InitActivityConfig()
    ActivityConfig = XTableManager.ReadByIntKey(TABLE_ACITIVTY_PATH, XTable.XTableKillZoneActivity, "Id")
end

local function GetActivityConfig(activityId)
    local config = ActivityConfig[activityId]
    if not config then
        XLog.Error("XKillZoneConfigs GetActivityConfig error:配置不存在, activityId:" .. activityId .. ",path: " .. TABLE_ACITIVTY_PATH)
        return
    end
    return config
end

local function GetActivityTimeId(activityId)
    local config = GetActivityConfig(activityId)
    return config.OpenTimeId
end

function XKillZoneConfigs.GetDefaultActivityId()
    local defaultActivityId = 0
    for activityId, config in pairs(ActivityConfig) do
        defaultActivityId = activityId
        if XTool.IsNumberValid(config.ActivityTimeId)
        and XFunctionManager.CheckInTimeByTimeId(config.ActivityTimeId) then
            break
        end
    end
    return defaultActivityId
end

function XKillZoneConfigs.GetActivityStartTime(activityId)
    local config = GetActivityConfig(activityId)
    return XFunctionManager.GetStartTimeByTimeId(GetActivityTimeId(activityId))
end

function XKillZoneConfigs.GetActivityEndTime(activityId)
    return XFunctionManager.GetEndTimeByTimeId(GetActivityTimeId(activityId))
end

function XKillZoneConfigs.GetActivityBg(activityId)
    local config = GetActivityConfig(activityId)
    return config.ActivityBg or ""
end

function XKillZoneConfigs.GetActivityName(activityId)
    local config = GetActivityConfig(activityId)
    return config.Name or ""
end

function XKillZoneConfigs.GetActivityResetPluginSpend(activityId)
    local config = GetActivityConfig(activityId)
    return config.ResetPluginSpend or 0
end

function XKillZoneConfigs.GetActivityChapterIds(activityId)
    local chapterIds = {}
    local config = GetActivityConfig(activityId)
    for _, chapterId in pairs(config.ChapterId) do
        if XTool.IsNumberValid(chapterId) then
            tableInsert(chapterIds, chapterId)
        end
    end
    return chapterIds
end
-----------------活动相关 end-------------------
-----------------章节相关 begin-------------------
local TABLE_CHAPTER_PATH = "Share/Fuben/KillZone/KillZoneChapter.tab"

local ChapterConfig = {}

XKillZoneConfigs.Difficult = {
    Normal = 1,
    Hard = 2,
}

local function InitChapterConfig()
    ChapterConfig = XTableManager.ReadByIntKey(TABLE_CHAPTER_PATH, XTable.XTableKillZoneChapter, "Id")
end

local function GetChapterConfig(chapterId)
    local config = ChapterConfig[chapterId]
    if not config then
        XLog.Error("XKillZoneConfigs GetChapterConfig error:配置不存在, chapterId:" .. chapterId .. ",path: " .. TABLE_CHAPTER_PATH)
        return
    end
    return config
end

function XKillZoneConfigs.GetChapterConfigPath()
    return TABLE_CHAPTER_PATH
end

function XKillZoneConfigs.GetChapterDiff(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.Diff
end

function XKillZoneConfigs.GetChapterName(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.Name or ""
end

function XKillZoneConfigs.GetChapterBg(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.Bg or ""
end

function XKillZoneConfigs.GetChapterTimeId(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.OpenTimeId
end

function XKillZoneConfigs.GetChapterDailyStageId(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.DailyStageId or 0
end

function XKillZoneConfigs.GetChapterStageIds(chapterId)
    local stageIds = {}
    local config = GetChapterConfig(chapterId)
    for _, stageId in pairs(config.StageId) do
        if XTool.IsNumberValid(stageId) then
            tableInsert(stageIds, stageId)
        end
    end
    return stageIds
end

function XKillZoneConfigs.GetChapterIdsByDiff(activityId, diff)
    local diffChapterIds = {}
    local chapterIds = XKillZoneConfigs.GetActivityChapterIds(activityId)
    for _, chapterId in pairs(chapterIds) do
        if diff == XKillZoneConfigs.GetChapterDiff(chapterId) then
            tableInsert(diffChapterIds, chapterId)
        end
    end
    return diffChapterIds
end

function XKillZoneConfigs.GetTotalStageIdsByDiff(activityId, diff)
    local totalStageIds = {}

    local chapterIds = XKillZoneConfigs.GetChapterIdsByDiff(activityId, diff)
    for _, chapterId in pairs(chapterIds) do
        local stageIds = XKillZoneConfigs.GetChapterStageIds(chapterId)
        for _, stageId in pairs(stageIds) do
            tableInsert(totalStageIds, stageId)
        end
    end

    return totalStageIds
end

function XKillZoneConfigs.GetChapterPreStageId(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.PreStageId
end

function XKillZoneConfigs.GetChapterIdByStageId(stageId)
    if not XTool.IsNumberValid(stageId) then return 0 end
    for chapterId, config in pairs(ChapterConfig) do
        for _, innerStageId in pairs(config.StageId) do
            if innerStageId == stageId then
                return chapterId
            end
        end
    end
    return 0
end

function XKillZoneConfigs.GetAllDailyStageId(activityId, diff)
    local dailyStageIds = {}
    local chapterIds = XKillZoneConfigs.GetChapterIdsByDiff(activityId, diff)
    for _, chapterId in pairs(chapterIds) do
        local stageId = XKillZoneConfigs.GetChapterDailyStageId(chapterId)
        if XTool.IsNumberValid(stageId) then
            tableInsert(dailyStageIds, stageId)
        end
    end
    return dailyStageIds
end
-----------------章节相关 end-------------------
-----------------关卡相关 begin-------------------
local TABLE_STAGE_PATH = "Share/Fuben/KillZone/KillZoneStage.tab"
local TABLE_STAGE_BUFF_PATH = "Client/Fuben/KillZone/KillZoneBuff.tab"

local StageConfig = {}
local StageBuffConfig = {}

XKillZoneConfigs.MaxFarmRewardCount = 3 --复刷奖励最大领取次数

local function InitStageConfig()
    StageConfig = XTableManager.ReadAllByIntKey(TABLE_STAGE_PATH, XTable.XTableKillZoneStage, "Id")
    StageBuffConfig = XTableManager.ReadAllByIntKey(TABLE_STAGE_BUFF_PATH, XTable.XTableKillZoneBuff, "Id")
end

local function GetStageConfig(stageId)
    local config = StageConfig[stageId]
    if not config then
        XLog.Error("XKillZoneConfigs GetStageConfig error:配置不存在, stageId:" .. stageId .. ",path: " .. TABLE_STAGE_PATH)
        return
    end
    return config
end

local function GetStageBuffConfig(buffId)
    local config = StageBuffConfig[buffId]
    if not config then
        XLog.Error("XKillZoneConfigs GetStageBuffConfig error:配置不存在, stageId:" .. buffId .. ",path: " .. TABLE_STAGE_BUFF_PATH)
        return
    end
    return config
end

function XKillZoneConfigs.GetAllStageIds()
    local stageIds = {}
    for stageId in pairs(StageConfig) do
        tableInsert(stageIds, stageId)
    end
    return stageIds
end

function XKillZoneConfigs.GetStageName(stageId)
    local config = GetStageConfig(stageId)
    return config.Name or ""
end

function XKillZoneConfigs.GetStageOrder(stageId)
    local config = GetStageConfig(stageId)
    return config.Order or ""
end

function XKillZoneConfigs.GetStageBg(stageId)
    local config = GetStageConfig(stageId)
    return config.Bg or ""
end

function XKillZoneConfigs.GetStageFarmReward(stageId)
    local config = GetStageConfig(stageId)
    return config.FarmReward
end

function XKillZoneConfigs.GetStageMaxStar(stageId)
    local config = GetStageConfig(stageId)
    return config.MaxStar
end

function XKillZoneConfigs.GetStagePreStageId(stageId)
    local config = GetStageConfig(stageId)
    return config.PreStageId
end

function XKillZoneConfigs.GetStageRobotIds(stageId)
    local robotIds = {}
    local config = GetStageConfig(stageId)
    for _, robotId in pairs(config.TestRobot) do
        if XTool.IsNumberValid(robotId) then
            tableInsert(robotIds, robotId)
        end
    end
    return robotIds
end

--获取通关条件描述
function XKillZoneConfigs.GetStagePassDesc(stageId)
    local config = GetStageConfig(stageId)
    return config.StarDesc[1] or ""
end

--获取星级条件描述
function XKillZoneConfigs.GetStageStarDescList(stageId)
    local descList = {}
    local config = GetStageConfig(stageId)
    for index, desc in ipairs(config.StarDesc) do
        if index > 1 then
            tableInsert(descList, desc)
        end
    end
    return descList
end

function XKillZoneConfigs.GetStageBuffIds(stageId)
    local buffIds = {}
    local config = GetStageConfig(stageId)
    for _, buffId in ipairs(config.FightEventIds) do
        if XTool.IsNumberValid(buffId) and XKillZoneConfigs.CheckBuffConfig(buffId) then
            tableInsert(buffIds, buffId)
        end
    end
    return buffIds
end

local function GetBuffConfig(buffId)
    local config = StageBuffConfig[buffId]
    if not config then
        XLog.Error("XKillZoneConfigs GetBuffConfig error:配置不存在, buffId:" .. buffId .. ",path: " .. TABLE_STAGE_BUFF_PATH)
        return
    end
    return config
end

function XKillZoneConfigs.GetBuffName(buffId)
    local config = GetBuffConfig(buffId)
    return config.Name
end

function XKillZoneConfigs.GetBuffDesc(buffId)
    local config = GetBuffConfig(buffId)
    return config.Desc
end

function XKillZoneConfigs.GetBuffIcon(buffId)
    local config = GetBuffConfig(buffId)
    return config.Icon
end

function XKillZoneConfigs.CheckBuffConfig(buffId)
    local config = StageBuffConfig[buffId]
    return config and true or false
end
-----------------关卡相关 end-------------------
-----------------星级奖励 begin-------------------
local TABLE_STAR_REWARD_PATH = "Share/Fuben/KillZone/KillZoneDiffStarReward.tab"

local StarRewardConfig = {}

local function InitStarRewardConfig()
    StarRewardConfig = XTableManager.ReadByIntKey(TABLE_STAR_REWARD_PATH, XTable.XTableKillZoneStarReward, "Id")
end

local function GetStarRewardConfig(starRewardId)
    local config = StarRewardConfig[starRewardId]
    if not config then
        XLog.Error("XKillZoneConfigs GetStarRewardConfig error:配置不存在, starRewardId:" .. starRewardId .. ",path: " .. TABLE_STAR_REWARD_PATH)
        return
    end
    return config
end

function XKillZoneConfigs.GetStarRewardDiff(starRewardId)
    local config = GetStarRewardConfig(starRewardId)
    return config.Diff
end

function XKillZoneConfigs.GetStarRewardStar(starRewardId)
    local config = GetStarRewardConfig(starRewardId)
    return config.Star
end

function XKillZoneConfigs.GetStarRewardGoodsId(starRewardId)
    local config = GetStarRewardConfig(starRewardId)
    return config.RewardId
end

function XKillZoneConfigs.GetStarRewardTitleByDiff(diff)
    if diff == XKillZoneConfigs.Difficult.Normal then
        return CsXTextManagerGetText("KillZoneTotalStarDescNormal")
    elseif diff == XKillZoneConfigs.Difficult.Hard then
        return CsXTextManagerGetText("KillZoneTotalStarDescHard")
    else
        return ""
    end
end

function XKillZoneConfigs.GetAllStarRewardIdsByDiff(diff)
    local ids = {}
    for starRewardId in pairs(StarRewardConfig) do
        if XTool.IsNumberValid(starRewardId)
        and XKillZoneConfigs.GetStarRewardDiff(starRewardId) == diff
        then
            tableInsert(ids, starRewardId)
        end
    end
    tableSort(ids, function(a, b)
        return a < b
    end)
    return ids
end
-----------------星级奖励 end-------------------
-----------------每日星级奖励 begin-------------------
local TABLE_DAILY_STAR_REWARD_PATH = "Share/Fuben/KillZone/KillZoneDailyStarReward.tab"

local DailyStarRewardConfig = {}

local function InitDailyStarRewardConfig()
    DailyStarRewardConfig = XTableManager.ReadByIntKey(TABLE_DAILY_STAR_REWARD_PATH, XTable.XTableKillZoneDailyStarReward, "Id")
end

local function GetDailyStarRewardConfig(id)
    local config = DailyStarRewardConfig[id]
    if not config then
        XLog.Error("XKillZoneConfigs GetDailyStarRewardConfig error:配置不存在, id:" .. id .. ",path: " .. TABLE_DAILY_STAR_REWARD_PATH)
        return
    end
    return config
end

function XKillZoneConfigs.GetDailyStarRewardConfigPath()
    return TABLE_DAILY_STAR_REWARD_PATH
end

function XKillZoneConfigs.GetDailyStarRewardStar(id)
    local config = GetDailyStarRewardConfig(id)
    return config.Star
end

function XKillZoneConfigs.GetDailyStarRewardGoodsId(id)
    local config = GetDailyStarRewardConfig(id)
    return config.RewardId
end

function XKillZoneConfigs.GetAllDailyStarRewardIds(activityId)
    local ids = {}
    for id, config in pairs(DailyStarRewardConfig) do
        if XTool.IsNumberValid(id)
        and config.ActivityId == activityId
        then
            tableInsert(ids, id)
        end
    end
    tableSort(ids, function(a, b)
        return a < b
    end)
    return ids
end
-----------------每日星级奖励 end-------------------
-----------------插件相关 begin-------------------
local TABLE_PLUGIN_PATH = "Share/Fuben/KillZone/KillZonePlugin.tab"
local TABLE_PLUGIN_SLOT_PATH = "Share/Fuben/KillZone/KillZonePluginSlot.tab"
local TABLE_PLUGIN_LEVEL_PATH = "Share/Fuben/KillZone/KillZonePluginLevel.tab"
local TABLE_PLUGIN_GROUP_PATH = "Client/Fuben/KillZone/KillZonePluginGroup.tab"

local PluginConfig = {}
local PluginSlotConfig = {}
local PluginLevelConfig = {}
local PluginGroupConfig = {}
local PluginIdGroupDic = {}--由GroupId索引的PluginId分组Dic

local function InitPluginConfig()
    PluginConfig = XTableManager.ReadByIntKey(TABLE_PLUGIN_PATH, XTable.XTableKillZonePlugin, "Id")
    PluginSlotConfig = XTableManager.ReadByIntKey(TABLE_PLUGIN_SLOT_PATH, XTable.XTableKillZonePluginSlot, "Id")
    PluginLevelConfig = XTableManager.ReadByIntKey(TABLE_PLUGIN_LEVEL_PATH, XTable.XTableKillZonePluginLevel, "Id")
    PluginGroupConfig = XTableManager.ReadByIntKey(TABLE_PLUGIN_GROUP_PATH, XTable.XTableKillZonePluginGroup, "Id")

    for pluginId, config in pairs(PluginConfig) do
        local groupId = config.GroupId
        if XTool.IsNumberValid(groupId)
        and XTool.IsNumberValid(pluginId) then
            local group = PluginIdGroupDic[groupId]
            if not group then
                group = {}
                PluginIdGroupDic[groupId] = group
            end
            tableInsert(group, pluginId)
        end
    end
end

local function GetPluginConfig(pluginId)
    local config = PluginConfig[pluginId]
    if not config then
        XLog.Error("XKillZoneConfigs GetPluginConfig error:配置不存在, pluginId:" .. pluginId .. ",path: " .. TABLE_PLUGIN_PATH)
        return
    end
    return config
end

local function GetPluginSlotConfig(slot)
    local config = PluginSlotConfig[slot]
    if not config then
        XLog.Error("XKillZoneConfigs GetPluginSlotConfig error:配置不存在, slot:" .. slot .. ",path: " .. TABLE_PLUGIN_SLOT_PATH)
        return
    end
    return config
end

local function GetPluginGroupConfig(groupId)
    local config = PluginGroupConfig[groupId]
    if not config then
        XLog.Error("XKillZoneConfigs GetPluginGroupConfig error:配置不存在, groupId:" .. groupId .. ",path: " .. TABLE_PLUGIN_GROUP_PATH)
        return
    end
    return config
end

local function GetPluginLevelIdConfig(levelId)
    local config = PluginLevelConfig[levelId]
    if not config then
        XLog.Error("XKillZoneConfigs GetPluginLevelIdConfig error:配置不存在, levelId:" .. levelId .. ",path: " .. TABLE_PLUGIN_LEVEL_PATH)
        return
    end
    return config
end

local function GetPluginLevelConfig(pluginId, level)
    local pluginConfig = GetPluginConfig(pluginId)
    local levelId = pluginConfig.LevelId[level]
    if not XTool.IsNumberValid(levelId) then
        XLog.Error("XKillZoneConfigs GetPluginLevelConfig error:levelId不存在, pluginId:" .. pluginId .. ",level: " .. level .. ",path: " .. TABLE_PLUGIN_PATH)
        return
    end
    return GetPluginLevelIdConfig(levelId)
end

--插件槽位最大数量
function XKillZoneConfigs.GetMaxPluginSlotNum()
    return #PluginSlotConfig
end

function XKillZoneConfigs.GetAllPluginIds()
    local pluginIds = {}
    for pluginId in pairs(PluginConfig) do
        if XTool.IsNumberValid(pluginId) then
            tableInsert(pluginIds, pluginId)
        end
    end
    return pluginIds
end

function XKillZoneConfigs.GetPluginGroupIds()
    local groupIds = {}
    for groupId in pairs(PluginIdGroupDic) do
        if XTool.IsNumberValid(groupId) then
            tableInsert(groupIds, groupId)
        end
    end
    return groupIds
end

function XKillZoneConfigs.GetPluginIdsByGroupId(groupId)
    return PluginIdGroupDic[groupId] and PluginIdGroupDic[groupId] or {}
end

function XKillZoneConfigs.GetPluginIcon(pluginId)
    local config = GetPluginConfig(pluginId)
    return config.Icon or ""
end

function XKillZoneConfigs.GetPluginName(pluginId)
    local config = GetPluginConfig(pluginId)
    return config.Name or ""
end

function XKillZoneConfigs.GetPluginMaxLevel(pluginId)
    local config = GetPluginConfig(pluginId)
    for level = #config.LevelId, 1, -1 do
        local levelId = config.LevelId[level]
        if XTool.IsNumberValid(levelId) then
            return level
        end
    end
    return 1
end

function XKillZoneConfigs.GetPluginSlotConditionId(slot)
    local config = GetPluginSlotConfig(slot)
    return config.UnlockCondition or 0
end

function XKillZoneConfigs.GetPluginSlotConditionDesc(slot)
    local conditionId = XKillZoneConfigs.GetPluginSlotConditionId(slot)
    return XTool.IsNumberValid(conditionId) and XConditionManager.GetConditionDescById(conditionId) or ""
end

function XKillZoneConfigs.GetPluginGroupName(groupId)
    local config = GetPluginGroupConfig(groupId)
    return config.Name or ""
end

--获取插件解锁消耗
function XKillZoneConfigs.GetPluginUnlockCost(pluginId)
    local config = GetPluginLevelConfig(pluginId, 1)
    return XKillZoneConfigs.ItemIdCoinB, config.UnlockSpend
end

--获取插件升级消耗
function XKillZoneConfigs.GetPluginLevelUpCost(pluginId, level)
    local config = GetPluginLevelConfig(pluginId, level)
    return XKillZoneConfigs.ItemIdCoinB, config.UnlockSpend
end

--获取插件列表重置消耗
function XKillZoneConfigs.GetPluginsResetCost(pluginIds, activityId)
    local costCount = XKillZoneConfigs.GetActivityResetPluginSpend(activityId)
    return XDataCenter.ItemManager.ItemId.Coin, #pluginIds * costCount
end

--获取插件升级总消耗（startLevel~targetLevel）
function XKillZoneConfigs.GetPluginLevelUpCostTotal(pluginId, startLevel, targetLevel)
    local totalCost = 0
    startLevel = startLevel or 1
    targetLevel = targetLevel or XKillZoneConfigs.GetPluginMaxLevel(pluginId)
    for level = startLevel, targetLevel do
        local _, cost = XKillZoneConfigs.GetPluginLevelUpCost(pluginId, level)
        totalCost = totalCost + cost
    end
    return XKillZoneConfigs.ItemIdCoinB, totalCost
end

--获取插件等级对应技能描述
function XKillZoneConfigs.GetPluginLevelSkillDesc(pluginId, level)
    local config = GetPluginLevelConfig(pluginId, level)
    return config.SkillDesc or ""
end

--获取插件等级对应技能描述列表
function XKillZoneConfigs.GetPluginLevelSkillDescList(pluginId)
    local descList = {}
    local config = GetPluginConfig(pluginId)
    for level, levelId in ipairs(config.LevelId) do
        if XTool.IsNumberValid(levelId) then
            tableInsert(descList, XKillZoneConfigs.GetPluginLevelSkillDesc(pluginId, level))
        end
    end
    return descList
end
-----------------插件相关 end-------------------
function XKillZoneConfigs.Init()
    InitActivityConfig()
    InitChapterConfig()
    InitStageConfig()
    InitStarRewardConfig()
    InitDailyStarRewardConfig()
    InitPluginConfig()
end