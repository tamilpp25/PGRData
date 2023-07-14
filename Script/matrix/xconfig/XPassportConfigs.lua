local tableInsert = table.insert
local tableSort = table.sort
local ipairs = ipairs
local pairs = pairs
local stringGsub = string.gsub
local CSXTextManagerGetText = CS.XTextManager.GetText

local TABLE_PASSPORT_ACTIVITY_PATH = "Share/Passport/PassportActivity.tab"
local TABLE_PASSPORT_LEVEL_PATH = "Share/Passport/PassportLevel.tab"
local TABLE_PASSPORT_REWARD_PATH = "Share/Passport/PassportReward.tab"
local TABLE_PASSPORT_TYPE_INFO_PATH = "Share/Passport/PassportTypeInfo.tab"
local TABLE_PASSPORT_TASK_GROUP_PATH = "Share/Passport/PassportTaskGroup.tab"
local TABLE_PASSPORT_BUY_FASHION_SHOW_PATH = "Client/Passport/PassportBuyFashionShow.tab"
local TABLE_PASSPORT_BUY_REWARD_SHOW_PATH = "Client/Passport/PassportBuyRewardShow.tab"
local PassportActivityConfigs = {}
local PassportLevelConfigs = {}
local PassportRewardConfigs = {}
local PassportTypeInfoConfigs = {}
local PassportTaskGroupConfigs = {}
local PassportBuyFashionShowConfigs = {}
local PassportBuyRewardShowConfigs = {}

local PassportActivityIdToLevelIdList = {}
local PassportRewardIdDic = {}
local PassportActivityIdToTypeInfoIdList = {}
local PassportActivityAndLevelToLevelIdDic = {}
local PassportIdToPassportRewardIdList = {}
local PassportIdToBuyRewardShowIdList = {}

local DefaultActivityId = 1

XPassportConfigs = XPassportConfigs or {}

--任务类型
XPassportConfigs.TaskType = {
    Activity = 0,   --活动任务（前端自定义）
    Daily = 1,  --每日任务
    Weekly = 2, --每周任务
}

local InitPassportActivityId = function()
    for activityId, config in pairs(PassportActivityConfigs) do
        if XTool.IsNumberValid(config.TimeId) then
            DefaultActivityId = activityId
            break
        end
        DefaultActivityId = activityId
    end
end

local InitPassportActivityIdToLevelIdList = function()
    for _, v in pairs(PassportLevelConfigs) do
        if not PassportActivityIdToLevelIdList[v.ActivityId] then
            PassportActivityIdToLevelIdList[v.ActivityId] = {}
        end
        tableInsert(PassportActivityIdToLevelIdList[v.ActivityId], v.Id)
    end

    for _, idList in pairs(PassportActivityIdToLevelIdList) do
        tableSort(idList, function(a, b)
            return a < b
        end)
    end
end

local InitPassportRewardIdDic = function()
    for _, v in pairs(PassportRewardConfigs) do
        if not PassportRewardIdDic[v.PassportId] then
            PassportRewardIdDic[v.PassportId] = {}
        end
        PassportRewardIdDic[v.PassportId][v.Level] = v.Id
    end
end

local InitPassportIdToPassportRewardIdList = function()
    for _, v in pairs(PassportRewardConfigs) do
        if not PassportIdToPassportRewardIdList[v.PassportId] then
            PassportIdToPassportRewardIdList[v.PassportId] = {}
        end
        tableInsert(PassportIdToPassportRewardIdList[v.PassportId], v.Id)
    end

    for _, idList in pairs(PassportIdToPassportRewardIdList) do
        tableSort(idList, function(a, b)
            local levelA = XPassportConfigs.GetPassportRewardLevel(a)
            local levelB = XPassportConfigs.GetPassportRewardLevel(b)
            if levelA ~= levelB then
                return levelA < levelB
            end
            return a < b
        end)
    end
end

local InitPassportActivityIdToTypeInfoIdList = function()
    for _, v in pairs(PassportTypeInfoConfigs) do
        if not PassportActivityIdToTypeInfoIdList[v.ActivityId] then
            PassportActivityIdToTypeInfoIdList[v.ActivityId] = {}
        end
        tableInsert(PassportActivityIdToTypeInfoIdList[v.ActivityId], v.Id)
    end

    for _, idList in pairs(PassportActivityIdToTypeInfoIdList) do
        tableSort(idList, function(a, b)
            return a < b
        end)
    end
end

local InitPassportActivityAndLevelToLevelIdDic = function()
    for _, v in pairs(PassportLevelConfigs) do
        if not PassportActivityAndLevelToLevelIdDic[v.ActivityId] then
            PassportActivityAndLevelToLevelIdDic[v.ActivityId] = {}
        end
        PassportActivityAndLevelToLevelIdDic[v.ActivityId][v.Level] = v.Id
    end
end

local InitPassportIdToBuyRewardShowIdList = function()
    for _, v in pairs(PassportBuyRewardShowConfigs) do
        if not PassportIdToBuyRewardShowIdList[v.PassportId] then
            PassportIdToBuyRewardShowIdList[v.PassportId] = {}
        end
        if XTool.IsNumberValid(v.Id) then
            tableInsert(PassportIdToBuyRewardShowIdList[v.PassportId], v.Id)
        end
    end
    
    for _, idList in pairs(PassportIdToBuyRewardShowIdList) do
        tableSort(idList, function(a, b)
            local levelA = XPassportConfigs.GetPassportBuyRewardShowLevel(a)
            local levelB = XPassportConfigs.GetPassportBuyRewardShowLevel(b)
            if levelA ~= levelB then
                return levelA > levelB
            end
            return a < b
        end)
    end
end

function XPassportConfigs.Init()
    PassportActivityConfigs = XTableManager.ReadByIntKey(TABLE_PASSPORT_ACTIVITY_PATH, XTable.XTablePassportActivity, "Id")
    PassportLevelConfigs = XTableManager.ReadByIntKey(TABLE_PASSPORT_LEVEL_PATH, XTable.XTablePassportLevel, "Id")
    PassportRewardConfigs = XTableManager.ReadByIntKey(TABLE_PASSPORT_REWARD_PATH, XTable.XTablePassportReward, "Id")
    PassportTypeInfoConfigs = XTableManager.ReadByIntKey(TABLE_PASSPORT_TYPE_INFO_PATH, XTable.XTablePassportTypeInfo, "Id")
    PassportTaskGroupConfigs = XTableManager.ReadByIntKey(TABLE_PASSPORT_TASK_GROUP_PATH, XTable.XTablePassportTaskGroup, "Id")
    PassportBuyFashionShowConfigs = XTableManager.ReadByIntKey(TABLE_PASSPORT_BUY_FASHION_SHOW_PATH, XTable.XTablePassportBuyFashionShow, "PassportId")
    PassportBuyRewardShowConfigs = XTableManager.ReadByIntKey(TABLE_PASSPORT_BUY_REWARD_SHOW_PATH, XTable.XTablePassportBuyRewardShow, "Id")

    InitPassportActivityId()
    InitPassportActivityIdToLevelIdList()
    InitPassportRewardIdDic()
    InitPassportIdToPassportRewardIdList()
    InitPassportActivityIdToTypeInfoIdList()
    InitPassportActivityAndLevelToLevelIdDic()
    InitPassportIdToBuyRewardShowIdList()
end

-----------------PassportActivity 活动相关 begin-----------------------
local GetPassportActivityConfig = function(id)
    local config = PassportActivityConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XPassportConfigs.GetPassportActivityConfig", "PassportActivityConfigs", TABLE_PASSPORT_ACTIVITY_PATH, "Id", id)
        return
    end
    return config
end

function XPassportConfigs.SetDefaultActivityId(activityId)
    DefaultActivityId = activityId
end

function XPassportConfigs.GetDefaultActivityId()
    return DefaultActivityId
end

function XPassportConfigs.GetPassportActivityTimeId()
    local activityId = XPassportConfigs.GetDefaultActivityId()
    local config = GetPassportActivityConfig(activityId)
    return config.TimeId
end

function XPassportConfigs.GetPassportDailyTaskGroup()
    local activityId = XPassportConfigs.GetDefaultActivityId()
    local config = GetPassportActivityConfig(activityId)
    return config.DailyTaskGroup
end

function XPassportConfigs.GetPassportWeekTaskGroup()
    local activityId = XPassportConfigs.GetDefaultActivityId()
    local config = GetPassportActivityConfig(activityId)
    return config.WeekTaskGroup
end

function XPassportConfigs.GetPassportBuyPassPortEarlyEndTime()
    local activityId = XPassportConfigs.GetDefaultActivityId()
    local config = GetPassportActivityConfig(activityId)
    return config.BuyPassPortEarlyEndTime -- 英文服采用国服逻辑
    -- return config.ClientBuyPassPortEarlyEndTime -- 由于日服客户端有独立的限制时间（客户端独立判断显示）
end

function XPassportConfigs.GetPassportBPTask()
    local activityId = XPassportConfigs.GetDefaultActivityId()
    local config = GetPassportActivityConfig(activityId)
    return config and config.BPTask or {}
end

function XPassportConfigs.GetPassportBPTaskTotalCount()
    local taskList = XPassportConfigs.GetPassportBPTask()
    return #taskList
end
-----------------PassportActivity 活动相关 end-------------------------

-----------------PassportLevel 等级 begin-----------------------
local GetPassportLevelConfig = function(id)
    local config = PassportLevelConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XPassportConfigs.GetPassportLevelConfig", "PassportLevelConfigs", TABLE_PASSPORT_LEVEL_PATH, "Id", id)
        return
    end
    return config
end

function XPassportConfigs.GetPassportLevelIdList(activityId)
    return PassportActivityIdToLevelIdList[activityId] or {}
end

function XPassportConfigs.GetPassportLevel(id)
    local config = GetPassportLevelConfig(id)
    return config.Level
end

function XPassportConfigs.GetPassportLevelTotalExp(id)
    local config = GetPassportLevelConfig(id)
    return config.TotalExp
end

function XPassportConfigs.GetPassportLevelCostItemId(id)
    local config = GetPassportLevelConfig(id)
    return config.CostItemId
end

function XPassportConfigs.GetPassportLevelCostItemCount(id)
    local config = GetPassportLevelConfig(id)
    return config.CostItemCount
end

function XPassportConfigs.GetPassportMaxLevel()
    local activityId = XPassportConfigs.GetDefaultActivityId()
    local levelIdList = XPassportConfigs.GetPassportLevelIdList(activityId)
    local maxLevel = 0
    local levelCfg
    for _, levelId in ipairs(levelIdList) do
        levelCfg = XPassportConfigs.GetPassportLevel(levelId)
        if levelCfg > maxLevel then
            maxLevel = levelCfg
        end
    end
    return maxLevel
end

function XPassportConfigs.GetPassportLevelId(level)
    local activityId = XPassportConfigs.GetDefaultActivityId()
    return PassportActivityAndLevelToLevelIdDic[activityId] and PassportActivityAndLevelToLevelIdDic[activityId][level]
end

function XPassportConfigs.GetPassportLevelTotalExpByLevel(level)
    local id = XPassportConfigs.GetPassportLevelId(level)
    local config = GetPassportLevelConfig(id)
    return config.TotalExp
end

function XPassportConfigs.IsPassportTargetLevel(id)
    local config = GetPassportLevelConfig(id)
    return XTool.IsNumberValid(config.IsTargetLevel)
end

--返回下一个目标的等级
function XPassportConfigs.GetPassportTargetLevel(currLevel)
    local activityId = XPassportConfigs.GetDefaultActivityId()
    local levelIdList = XPassportConfigs.GetPassportLevelIdList(activityId)
    local lastLevelIdIndex = #levelIdList
    local levelCfg

    for i, levelId in ipairs(levelIdList) do
        levelCfg = XPassportConfigs.GetPassportLevel(levelId)
        if (levelCfg >= currLevel or i == lastLevelIdIndex) and XPassportConfigs.IsPassportTargetLevel(levelId) then
            return levelCfg
        end
    end
end

function XPassportConfigs.GetBuyLevelCostItemId()
    local activityId = XPassportConfigs.GetDefaultActivityId()
    local levelIdList = XPassportConfigs.GetPassportLevelIdList(activityId)
    for _, levelId in ipairs(levelIdList) do
        return XPassportConfigs.GetPassportLevelCostItemId(levelId)
    end
end
-----------------PassportLevel 等级 end-------------------------

-----------------PassportReward 奖励 begin-----------------------
local GetPassportRewardConfig = function(id)
    local config = PassportRewardConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XPassportConfigs.GetPassportRewardConfig", "PassportRewardConfigs", TABLE_PASSPORT_REWARD_PATH, "Id", id)
        return
    end
    return config
end

function XPassportConfigs.GetPassportRewardPassportId(id)
    local config = GetPassportRewardConfig(id)
    return config.PassportId
end

function XPassportConfigs.GetPassportRewardId(id)
    local config = GetPassportRewardConfig(id)
    return config.RewardId
end

function XPassportConfigs.GetPassportRewardData(passportRewardId)
    local rewardId = XPassportConfigs.GetPassportRewardId(passportRewardId)
    local rewards = XTool.IsNumberValid(rewardId) and XRewardManager.GetRewardList(rewardId)
    return rewards and rewards[1]
end

function XPassportConfigs.GetPassportRewardLevel(id)
    local config = GetPassportRewardConfig(id)
    return config.Level
end

function XPassportConfigs.GetPassportRewardIdList(passportId)
    return PassportIdToPassportRewardIdList[passportId]
end

--获得奖励表的id
function XPassportConfigs.GetRewardIdByPassportIdAndLevel(passportId, level)
    return PassportRewardIdDic[passportId] and PassportRewardIdDic[passportId][level]
end

--返回对应等级的已解锁的通行证奖励
function XPassportConfigs.GetUnLockPassportRewardIdListByLevel(level)
    local typeInfoIdList = XPassportConfigs.GetPassportActivityIdToTypeInfoIdList()
    local unLockPassportRewardIdList = {}
    local rewardId
    local passportRewardId

    for _, passportId in ipairs(typeInfoIdList) do
        if XDataCenter.PassportManager.GetPassportInfos(passportId) then
            passportRewardId = XPassportConfigs.GetRewardIdByPassportIdAndLevel(passportId, level)
            rewardId = XPassportConfigs.GetPassportRewardId(passportRewardId)
            if XTool.IsNumberValid(rewardId) then
                tableInsert(unLockPassportRewardIdList, passportRewardId)
            end
        end
    end
    return unLockPassportRewardIdList
end

function XPassportConfigs.IsPassportPrimeReward(id)
    local config = GetPassportRewardConfig(id)
    return config.IsPrimeReward
end
-----------------PassportReward 奖励 end-------------------------

-----------------PassportTypeInfo 通行证类型 begin-----------------------
local GetPassportTypeInfoConfig = function(id)
    local config = PassportTypeInfoConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XPassportConfigs.GetPassportTypeInfoConfig", "PassportTypeInfoConfigs", TABLE_PASSPORT_TYPE_INFO_PATH, "Id", id)
        return
    end
    return config
end

function XPassportConfigs.GetPassportTypeInfoRewardId(id)
    local config = GetPassportTypeInfoConfig(id)
    return config.RewardId
end

function XPassportConfigs.GetPassportTypeInfoName(id)
    local config = GetPassportTypeInfoConfig(id)
    return config.Name or ""
end

function XPassportConfigs.GetPassportTypeInfoCostItemId(id)
    local config = GetPassportTypeInfoConfig(id)
    return config.CostItemId
end

function XPassportConfigs.GetPassportTypeInfoCostItemCount(id)
    local config = GetPassportTypeInfoConfig(id)
    return config.CostItemCount
end

function XPassportConfigs.GetPassportTypeInfoRewardId(id)
    local config = GetPassportTypeInfoConfig(id)
    return config.RewardId
end

function XPassportConfigs.GetPassportTypeInfoBuyDesc(id)
    local config = GetPassportTypeInfoConfig(id)
    return config.BuyDesc or ""
end

function XPassportConfigs.GetPassportTypeInfoIcon(id)
    local config = GetPassportTypeInfoConfig(id)
    return config.Icon
end

function XPassportConfigs.GetPassportActivityIdToTypeInfoIdList()
    local activityId = XPassportConfigs.GetDefaultActivityId()
    return PassportActivityIdToTypeInfoIdList[activityId]
end

-- function XPassportConfigs.GetPassportTypeInfoIsFree(id)
--     local config = GetPassportTypeInfoConfig(id)
--     return config.IsFree
-- end

function XPassportConfigs.GetPassportTypeInfoPayKeySuffix(id)
    local config = GetPassportTypeInfoConfig(id)
    return config.PayKeySuffix
end
-----------------PassportTypeInfo 通行证类型 end-------------------------

-----------------PassportTaskGroup 任务 begin--------------------------
local GetPassportTaskGroupConfig = function(id)
    local config = PassportTaskGroupConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XPassportConfigs.GetPassportTaskGroupConfig", "PassportTaskGroupConfigs", TABLE_PASSPORT_TASK_GROUP_PATH, "Id", id)
        return
    end
    return config
end

function XPassportConfigs.GetPassportTaskGroupTaskIdList(id)
    local config = GetPassportTaskGroupConfig(id)
    return config.TaskId
end

function XPassportConfigs.GetPassportTaskGroupTimeId(id)
    local config = GetPassportTaskGroupConfig(id)
    return config.TimeId
end

function XPassportConfigs.GetPassportTaskGroupCurrOpenTaskIdList(type)
    for _, v in pairs(PassportTaskGroupConfigs) do
        if v.Type == type and XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
            return XPassportConfigs.GetPassportTaskGroupTaskIdList(v.Id)
        end
    end
    return {}
end

function XPassportConfigs.GetPassportTaskGroupIdByType(type)
    for _, v in pairs(PassportTaskGroupConfigs) do
        if v.Type == type and XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
            return v.Id
        end
    end
end

--获得总周数和当前第几周
function XPassportConfigs.GetPassportWeeklyTaskGroupCountAndCurrWeekly()
    local nowServerTime = XTime.GetServerNowTimestamp()
    local weekTaskGroup = XPassportConfigs.GetPassportWeekTaskGroup()
    local totalCount = 0
    local currWeekly = 0
    local startTime
    
    for _, v in pairs(PassportTaskGroupConfigs) do
        startTime = XFunctionManager.GetStartTimeByTimeId(v.TimeId)
        if v.Type == XPassportConfigs.TaskType.Weekly and v.Group == weekTaskGroup then
            if nowServerTime >= startTime then
                currWeekly = currWeekly + 1
            end
            totalCount = totalCount + 1
        end
    end

    currWeekly = XTool.IsNumberValid(currWeekly) and currWeekly or 1    --默认第1周
    return totalCount, currWeekly
end

-----------------PassportTaskGroup 任务 end----------------------------

-----------------PassportBuyFashionShowConfig 购买通行证界面展示的时装相关 start----------------------------
local GetPassportBuyFashionShowConfig = function(id)
    local config = PassportBuyFashionShowConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XPassportConfigs.GetPassportBuyFashionShowConfig", "PassportBuyFashionShowConfigs", TABLE_PASSPORT_BUY_FASHION_SHOW_PATH, "PassportId", id)
        return
    end
    return config
end

function XPassportConfigs.GetPassportBuyFashionShowIcon(id)
    local config = GetPassportBuyFashionShowConfig(id)
    return config.Icon
end

function XPassportConfigs.GetPassportBuyFashionShowFashionId(id)
    local config = GetPassportBuyFashionShowConfig(id)
    return config.FashionId
end

function XPassportConfigs.IsPassportBuyFashionShowIsWeaponFahion(id)
    local config = GetPassportBuyFashionShowConfig(id)
    return XTool.IsNumberValid(config.IsWeaponFahion) and true or false
end
-----------------PassportBuyFashionShowConfig 购买通行证界面展示的时装相关 end------------------------------

-----------------PassportBuyRewardShowConfig 购买通行证界面展示的道具相关 start----------------------------
local GetPassportBuyRewardShowConfig = function(id)
    local config = PassportBuyRewardShowConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XPassportConfigs.GetPassportBuyRewardShowConfig", "PassportBuyRewardShowConfigs", TABLE_PASSPORT_BUY_REWARD_SHOW_PATH, "Id", id)
        return
    end
    return config
end

function XPassportConfigs.GetPassportBuyRewardShowLevel(id)
    local config = GetPassportBuyRewardShowConfig(id)
    return config.Level
end

function XPassportConfigs.GetPassportBuyRewardShowCount(id)
    local config = GetPassportBuyRewardShowConfig(id)
    return config.ShowCount
end

function XPassportConfigs.GetPassportBuyRewardShowRewardData(id, isNotCount)
    local config = GetPassportBuyRewardShowConfig(id)
    local rewardId = config.RewardId
    local rewards = isNotCount and XRewardManager.GetRewardListNotCount(rewardId) or XRewardManager.GetRewardList(rewardId)
    return rewards and rewards[1]
end

function XPassportConfigs.GetBuyRewardShowIdList(passportId)
    return PassportIdToBuyRewardShowIdList[passportId] or {}
end
-----------------PassportBuyRewardShowConfig 购买通行证界面展示的道具相关 end------------------------------

----------------- 无限区奖励 start----------------------------
local LevelIdListSeparate = {}
XPassportConfigs.XPassportRewardType = {
    None = 0,
    Normal = 1,
    Infinite = 2
}

-- 最大可购买等级 ！= 最大等级
function XPassportConfigs.GetPassportMaxBuyableLevel()
    local activityId = XPassportConfigs.GetDefaultActivityId()
    local levelIdList = XPassportConfigs.GetPassportLevelIdList(activityId)
    local maxLevel = 0
    for i = 1, #levelIdList do
        local id = levelIdList[i]
        if XPassportConfigs.IsInfReward(id) then
            break
        end
        local level = XPassportConfigs.GetPassportLevel(id)
        if level > maxLevel then
            maxLevel = level
        end
    end
    return maxLevel
end

function XPassportConfigs.GetPassportLevelIdListByRewardType(activityId, rewardType)
    LevelIdListSeparate[activityId] = LevelIdListSeparate[activityId] or {}
    local result = LevelIdListSeparate[activityId][rewardType]
    if result then
        return result
    end
    result = {}
    local levelIdList = XPassportConfigs.GetPassportLevelIdList(activityId)
    for i = 1, #levelIdList do
        local id = levelIdList[i]
        if rewardType == XPassportConfigs.GetRewardType(id) then
            result[#result + 1] = id
        end
    end
    LevelIdListSeparate[activityId][rewardType] = result
    return result
end

function XPassportConfigs.GetRewardType(id)
    return XPassportConfigs.IsInfReward(id) and XPassportConfigs.XPassportRewardType.Infinite or
        XPassportConfigs.XPassportRewardType.Normal
end

function XPassportConfigs.IsInfReward(id)
    local costItemId = XPassportConfigs.GetPassportLevelCostItemId(id)
    return not costItemId or costItemId == 0
end

----------------- 无限区奖励 end------------------------------
