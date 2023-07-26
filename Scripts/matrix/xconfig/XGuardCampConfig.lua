local CSXTextManagerGetText = CS.XTextManager.GetText
local tableInsert = table.insert
local stringGsub = string.gsub
local ParseToTimestamp = XTime.ParseToTimestamp

local TABLE_CAMP_PATH = "Share/GuardCamp/Camp.tab"
local TABLE_ACTIVITY_PATH = "Share/GuardCamp/Activity.tab"

local CampTemplate = {}
local ActivityTemplate = {}

local JoinMaxNum = 0    --参与人数配置最大数量

XGuardCampConfig = XGuardCampConfig or {}

XGuardCampConfig.ActivityState = {
    UnOpen = 1,         --活动未开启
    SupportOpen = 2,    --活动和应援开启
    SupportClose = 3,   --应援关闭，等待开奖
    DrawLottery = 4,    --开奖
    Close = 5,          --活动关闭
}
XGuardCampConfig.NotGuardId = 0

local InitJoinMaxNum = function()
    for _, v in pairs(ActivityTemplate) do
        local maxIndex = #v.JoinNum
        JoinMaxNum = v.JoinNum[maxIndex] or 0
    end
end

function XGuardCampConfig.Init()
    CampTemplate = XTableManager.ReadByIntKey(TABLE_CAMP_PATH, XTable.XTableGuardCamp, "Id")
    ActivityTemplate = XTableManager.ReadByIntKey(TABLE_ACTIVITY_PATH, XTable.XTableGuardCampActivity, "Id")
    InitJoinMaxNum()
end

local GetCampConfig = function(id)
    local config = CampTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetCampConfig error:配置不存在, roleId: " .. id .. ", 配置路径: " .. TABLE_CAMP_PATH)
        return
    end
    return config
end

function XGuardCampConfig.GetCampId(index)
    local activityId = XGuardCampConfig.GetActivityId()
    local campIdList = XGuardCampConfig.GetActivityCampIdList(activityId)
    return campIdList[index]
end

function XGuardCampConfig.GetCampName(id)
    local config = GetCampConfig(id)
    return config.Name
end

function XGuardCampConfig.GetCampRewardId(id)
    local config = GetCampConfig(id)
    return config.RewardId
end

local GetActivityConfig = function(id)
    local config = ActivityTemplate[id]
    if not config then
        XLog.Error("XTRPGConfigs GetActivityConfig error:配置不存在, roleId: " .. id .. ", 配置路径: " .. TABLE_ACTIVITY_PATH)
        return
    end
    return config
end

function XGuardCampConfig.GetActivityId()
    local serverTimestamp = XTime.GetServerNowTimestamp()
    local startTimestamp, endTimestamp
    local defaultActivityId
    for id in pairs(ActivityTemplate) do
        startTimestamp, endTimestamp = XGuardCampConfig.GetActivityTime(id)
        if endTimestamp > serverTimestamp then
            return id
        end
        defaultActivityId = id
    end
    return defaultActivityId
end

function XGuardCampConfig.GetActivityDrawLotteryTime(id)
    local drawLotteryTimeStr = XGuardCampConfig.GetActivityDrawLotteryTimeStr(id)
    return ParseToTimestamp(drawLotteryTimeStr)
end

function XGuardCampConfig.GetActivityShowDrawLotteryTime(id)
    local config = GetActivityConfig(id)
    return config.ShowDrawLotteryTime
end

function XGuardCampConfig.GetSupportOpenTimeStr(id)
    local config = GetActivityConfig(id)
    local timeId = config.SupportTimeId
    local startTimestamp = XFunctionManager.GetStartTimeByTimeId(timeId)
    return os.date("%Y/%m/%d %H:%M", startTimestamp)
end

function XGuardCampConfig.GetActivityCloseTimeStr(id)
    local config = GetActivityConfig(id)
    local timeId = config.OpenTimeId
    local startTimestamp = XFunctionManager.GetEndTimeByTimeId(timeId)
    return os.date("%Y/%m/%d %H:%M", startTimestamp)
end

function XGuardCampConfig.GetActivityTime(id)
    local config = GetActivityConfig(id)
    local timeId = config.OpenTimeId
    local startTimestamp, endTimestamp = XFunctionManager.GetTimeByTimeId(timeId)
    return startTimestamp, endTimestamp
end

function XGuardCampConfig.GetActivitySupportLastTime(id)
    local config = GetActivityConfig(id)
    local timeId = config.SupportTimeId
    local startTimestamp, endTimestamp = XFunctionManager.GetTimeByTimeId(timeId)
    return startTimestamp, endTimestamp
end

function XGuardCampConfig.GetActivitySupportItemId(id)
    local config = GetActivityConfig(id)
    return config.SupportItemId
end

function XGuardCampConfig.GetActivityRewardPondItemId(id)
    local config = GetActivityConfig(id)
    return config.RewardPondItemId
end

function XGuardCampConfig.GetActivitySelectCampNeedCount(id)
    local config = GetActivityConfig(id)
    return config.SelectCampNeedCount
end

function XGuardCampConfig.GetActivityPerSupportNum(id)
    local config = GetActivityConfig(id)
    return config.PerSupportNum
end

function XGuardCampConfig.GetActivityTotalSupportCount(id)
    local config = GetActivityConfig(id)
    return config.TotalSupportCount
end

function XGuardCampConfig.GetActivityCampIdList(id)
    local config = GetActivityConfig(id)
    return config.CampId
end

function XGuardCampConfig.GetActivityJoinNumList(id)
    local config = GetActivityConfig(id)
    return config.JoinNum
end

function XGuardCampConfig.GetActivityPondAddList(id)
    local config = GetActivityConfig(id)
    return config.PondAdd
end

function XGuardCampConfig.GetActivityJoinCampPurchasePackage(id)
    local config = GetActivityConfig(id)
    return config.JoinCampPurchasePackageUiType, config.JoinCampPurchasePackageId
end

function XGuardCampConfig.GetActivitySupportCampPurchasePackage(id)
    local config = GetActivityConfig(id)
    return config.SupportCampPurchasePackageUiType, config.SupportCampPurchasePackageId
end

function XGuardCampConfig.GetJoinMaxNum()
    return JoinMaxNum
end

function XGuardCampConfig.GetCaption(state)
    local caption = state == XGuardCampConfig.ActivityState.DrawLottery and CSXTextManagerGetText("GuardCampCardPoolDrawLotteryCaption") or CSXTextManagerGetText("GuardCampCardPoolCaption")
    return stringGsub(caption, "\\n", "\n")
end