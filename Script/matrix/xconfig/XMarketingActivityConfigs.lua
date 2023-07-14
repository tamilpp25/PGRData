XMarketingActivityConfigs = XMarketingActivityConfigs or {}

local TABLE_MARKETING = "Client/MarketingActivity/MarketingActivity.tab"
local TABLE_PICCOMPOSITION = "Client/MarketingActivity/PicComposition.tab"
local TABLE_COMPOSITIONCHARACTER = "Client/MarketingActivity/CompositionCharacter.tab"

local TABLE_PRODUCTCOMMENTACTIVITY = "Share/ProductComment/ProductCommentActivity.tab"
local TABLE_PRODUCTCOMMENTRANKREWARD = "Share/ProductComment/ProductCommentRankReward.tab"
local TABLE_PRODUCTCOMMENTSCHEDULEREWARD = "Share/ProductComment/ProductCommentScheduleReward.tab"

local TABLE_WINDOWSINLAY = "Client/MarketingActivity/WindowsInlay.tab"

local tableSort = table.sort

local MarketingActivities = {}
local PicCompositions = {}
local PicCompositionActivityInfos = {}
local CompositionCharacters = {}
local PicCompositionRankRewardInfos = {}
local PicCompositionScheduleRewardInfos = {}

local WindowsInlayActivities = {}


XMarketingActivityConfigs.CompositionType = {
    Examining = 0,
    Examined = 1,
    UnExamine = 2,
    Memo = 3,
}

XMarketingActivityConfigs.SortType = {
    Hot = 1,
    Time = 2,
}

XMarketingActivityConfigs.GetType = {
    Before = 1,
    After = 2,
}

XMarketingActivityConfigs.TimeType = {
    In = 0,
    Before = 1,
    After = 2,
    Out = 3,
}

XMarketingActivityConfigs.TimeDataType = {
    BeginTime = 0,
    EndTime = 1,
    UploadBeginTime = 2,
    UploadEndTime = 3,
}

XMarketingActivityConfigs.SeverId = {
    SparkServer = "1000",
    BeaconServer = "1001",
}

XMarketingActivityConfigs.ActivityType = {
    WindowsInlay = 1,
}

XMarketingActivityConfigs.WebType = {
    Normal = 0,
    Vote = 1,
}


function XMarketingActivityConfigs.Init()
    MarketingActivities = XTableManager.ReadByIntKey(TABLE_MARKETING, XTable.XTableMarketingActivity, "Id")
    PicCompositions = XTableManager.ReadByIntKey(TABLE_PICCOMPOSITION, XTable.XTablePicComposition, "Id")
    CompositionCharacters = XTableManager.ReadByIntKey(TABLE_COMPOSITIONCHARACTER, XTable.XTableCompositionCharacter, "Id")
    PicCompositionActivityInfos = XTableManager.ReadByIntKey(TABLE_PRODUCTCOMMENTACTIVITY, XTable.XTableProductCommentActivity, "Id")
    PicCompositionRankRewardInfos = XTableManager.ReadByIntKey(TABLE_PRODUCTCOMMENTRANKREWARD, XTable.XTableProductCommentRankReward, "Id")
    PicCompositionScheduleRewardInfos = XTableManager.ReadByIntKey(TABLE_PRODUCTCOMMENTSCHEDULEREWARD, XTable.XTableProductCommentScheduleReward, "Id")
    WindowsInlayActivities = XTableManager.ReadByIntKey(TABLE_WINDOWSINLAY, XTable.XTableWindowsInlay, "Id")
end
------------------------------看图作文相关---------------------------------->>>
function XMarketingActivityConfigs.GetMarketingActivityConfig()
    return MarketingActivities
end

function XMarketingActivityConfigs.GetPicCompositionConfigs()
    return PicCompositions[1]
end

function XMarketingActivityConfigs.GetCompositionCharacterConfigs()
    return CompositionCharacters
end

function XMarketingActivityConfigs.GetCompositionCharacterConfigById(id)
    return CompositionCharacters[id]
end

function XMarketingActivityConfigs.GetPicCompositionActivityInfoConfigs()
    return PicCompositionActivityInfos
end

function XMarketingActivityConfigs.GetPicCompositionRankRewardInfoConfigs()
    return PicCompositionRankRewardInfos
end

function XMarketingActivityConfigs.GetPicCompositionScheduleRewardInfoConfigs()
    return PicCompositionScheduleRewardInfos
end

function XMarketingActivityConfigs.GetPicCompositionScheduleRewardTotal()
    local count = 0
    for _, _ in pairs(PicCompositionScheduleRewardInfos or {}) do
        count = count + 1
    end
    return count
end

function XMarketingActivityConfigs.SortByPriority(list)
    tableSort(list, function(a, b)
            if a.Priority == b.Priority then
                return a.Id > b.Id
            else
                return a.Priority > b.Priority
            end
        end)
    return list
end

function XMarketingActivityConfigs.GetCountUnitChange(count)
    local newCount = count
    if count >= 1000 then
        newCount = count / 1000
    else
        return math.floor(newCount)
    end
    local a, b = math.modf(newCount)
    return b >= 0.05 and string.format("%.1fk", newCount) or string.format("%dk", a)
end
------------------------------看图作文相关----------------------------------<<<
------------------------------内嵌浏览器相关---------------------------------->>>
function XMarketingActivityConfigs.GetWindowsInlayActivityConfig()
    return WindowsInlayActivities
end
------------------------------内嵌浏览器相关----------------------------------<<<