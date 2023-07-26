local tableInsert = table.insert
local tableSort = table.sort
local ipairs = ipairs
local pairs = pairs

local TABLE_LIV_WARM_ACTIVITY_CLIENT_PATH = "Client/MiniActivity/LivWarmActivity/LivWarmActivityLocal.tab"
local TABLE_LIV_WARM_ACTIVITY_HEAD_CLIENT_PATH = "Client/MiniActivity/LivWarmActivity/LivWarmActivityHead.tab"
local TABLE_LIV_WARM_ACTIVITY_STAGE_CLIENT_PATH = "Client/MiniActivity/LivWarmActivity/LivWarmActivityStageLocal.tab"
local TABLE_LIV_WARM_ACTIVITY_PATH = "Share/MiniActivity/LivWarmActivity/LivWarmActivity.tab"
local TABLE_LIV_WARM_ACTIVITY_STAGE_PATH = "Share/MiniActivity/LivWarmActivity/LivWarmActivityStage.tab"
local LivWarmActivityClientConfigs = {}
local LivWarmActivityHeadClientConfigs = {}
local LivWarmActivityStageClientConfigs = {}
local LivWarmActivityConfigs = {}
local LivWarmActivityStageConfigs = {}

local LivWarmStageIdToHeadIdList = {}
local LivWarmActivityIdToStageIdList = {}

local DefaultActivityId = 1

XLivWarmActivityConfigs = XLivWarmActivityConfigs or {}

--图标类型
XLivWarmActivityConfigs.HeadType = {
    NotClict = -1,   --不可点击
    Blank = 0,      --可点击的空白图标
    Head1 = 1,      --可点击的图标
    Head2 = 2,
    Head3 = 3
}

local InitLivWarmStageIdToHeadIdList = function()
    for _, v in pairs(LivWarmActivityHeadClientConfigs) do
        if not LivWarmStageIdToHeadIdList[v.StageId] then
            LivWarmStageIdToHeadIdList[v.StageId] = {}
        end
        tableInsert(LivWarmStageIdToHeadIdList[v.StageId], v.Id)
    end
end

local InitLivWarmActivityIdToStageIdList = function()
    for _, v in pairs(LivWarmActivityStageConfigs) do
        if not LivWarmActivityIdToStageIdList[v.ActivityId] then
            LivWarmActivityIdToStageIdList[v.ActivityId] = {}
        end
        tableInsert(LivWarmActivityIdToStageIdList[v.ActivityId], v.Id)
    end

    for _, v in pairs(LivWarmActivityIdToStageIdList) do
        tableSort(v, function(a, b)
            return a < b
        end)
    end
end

function XLivWarmActivityConfigs.Init()
    LivWarmActivityClientConfigs = XTableManager.ReadByIntKey(TABLE_LIV_WARM_ACTIVITY_CLIENT_PATH, XTable.XTableLivWarmActivityLocal, "Id")
    LivWarmActivityHeadClientConfigs = XTableManager.ReadByIntKey(TABLE_LIV_WARM_ACTIVITY_HEAD_CLIENT_PATH, XTable.XTableLivWarmActivityHead, "Id")
    LivWarmActivityStageClientConfigs = XTableManager.ReadByIntKey(TABLE_LIV_WARM_ACTIVITY_STAGE_CLIENT_PATH, XTable.XTableLivWarmActivityStageLocal, "Id")
    LivWarmActivityConfigs = XTableManager.ReadByIntKey(TABLE_LIV_WARM_ACTIVITY_PATH, XTable.XTableLivWarmActivity, "Id")
    LivWarmActivityStageConfigs = XTableManager.ReadByIntKey(TABLE_LIV_WARM_ACTIVITY_STAGE_PATH, XTable.XTableLivWarmActivityStage, "Id")

    InitLivWarmStageIdToHeadIdList()
    InitLivWarmActivityIdToStageIdList()
end

-----------------LivWarmActivityConfigs begin-----------------------
local GetLivWarmActivityConfig = function(id)
    local config = LivWarmActivityConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XLivWarmActivityConfigs.GetLivWarmActivityConfig", "LivWarmActivityConfigs", TABLE_LIV_WARM_ACTIVITY_PATH, "Id", id)
        return
    end
    return config
end

function XLivWarmActivityConfigs.SetDefaultActivityId(activityId)
    DefaultActivityId = activityId
end

function XLivWarmActivityConfigs.GetDefaultActivityId()
    return DefaultActivityId
end

function XLivWarmActivityConfigs.GetLivWarmActivityTimeId()
    local activityId = XLivWarmActivityConfigs.GetDefaultActivityId()
    local config = GetLivWarmActivityConfig(activityId)
    return config.TimeId
end

function XLivWarmActivityConfigs.GetLivWarmActivityItemId()
    local activityId = XLivWarmActivityConfigs.GetDefaultActivityId()
    local config = GetLivWarmActivityConfig(activityId)
    return config.ItemId
end

function XLivWarmActivityConfigs.GetLivWarmActivityUseItemCount()
    local activityId = XLivWarmActivityConfigs.GetDefaultActivityId()
    local config = GetLivWarmActivityConfig(activityId)
    return config.UseItemCount
end
-----------------LivWarmActivityConfigs end-------------------------

-----------------LivWarmActivityStageConfigs begin-----------------------
local GetLivWarmActivityStageConfig = function(id)
    local config = LivWarmActivityStageConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XLivWarmActivityStageConfigs.GetLivWarmActivityStageConfig", "LivWarmActivityStageConfigs", TABLE_LIV_WARM_ACTIVITY_STAGE_PATH, "Id", id)
        return
    end
    return config
end

function XLivWarmActivityConfigs.GetLivWarmStageIdList()
    local activityId = XLivWarmActivityConfigs.GetDefaultActivityId()
    return LivWarmActivityIdToStageIdList[activityId] or {}
end

function XLivWarmActivityConfigs.GetLivWarmActivityStageMaxItemCount(id)
    local config = GetLivWarmActivityStageConfig(id)
    return config.MaxItemCount
end

function XLivWarmActivityConfigs.GetLivWarmActivityStageRewardProgress(id)
    local config = GetLivWarmActivityStageConfig(id)
    return config.RewardProgress
end

function XLivWarmActivityConfigs.GetLivWarmActivityStageRewardProgressByIndex(id, index)
    local rewardProgressList = XLivWarmActivityConfigs.GetLivWarmActivityStageRewardProgress(id)
    return rewardProgressList and rewardProgressList[index]
end

function XLivWarmActivityConfigs.GetLivWarmActivityStageRewardId(id)
    local config = GetLivWarmActivityStageConfig(id)
    return config.RewardId
end

function XLivWarmActivityConfigs.GetLivWarmActivityStageDismisMaxCount(id)
    local config = GetLivWarmActivityStageConfig(id)
    return config.DismisMaxCount
end

function XLivWarmActivityConfigs.GetLivWarmActivityStageRequireStageId(id)
    local config = GetLivWarmActivityStageConfig(id)
    return config.RequireStageId
end
-----------------LivWarmActivityStageConfigs end-------------------------

-----------------LivWarmActivityClientConfigs begin-----------------------
local GetLivWarmActivityClientConfig = function(id)
    local config = LivWarmActivityClientConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XLivWarmActivityConfigs.GetLivWarmActivityClientConfig", "LivWarmActivityClientConfigs", TABLE_LIV_WARM_ACTIVITY_CLIENT_PATH, "Id", id)
        return
    end
    return config
end

function XLivWarmActivityConfigs.GetLivWarmActivityName()
    local activityId = XLivWarmActivityConfigs.GetDefaultActivityId()
    local config = GetLivWarmActivityConfig(activityId)
    return config.Name
end

function XLivWarmActivityConfigs.GetLivWarmActivityHelpId()
    local activityId = XLivWarmActivityConfigs.GetDefaultActivityId()
    local config = GetLivWarmActivityConfig(activityId)
    return config.HelpId
end

function XLivWarmActivityConfigs.GetLivWarmActivitySkipId()
    local activityId = XLivWarmActivityConfigs.GetDefaultActivityId()
    local config = GetLivWarmActivityConfig(activityId)
    return config.SkipId
end
-----------------LivWarmActivityClientConfigs end-----------------------

-----------------LivWarmActivityStageClientConfigs begin-----------------------
local GetLivWarmActivityStageClientConfig = function(id)
    local config = LivWarmActivityStageClientConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XLivWarmActivityStageClientConfigs.GetLivWarmActivityStageClientConfig", "LivWarmActivityStageClientConfigs", TABLE_LIV_WARM_ACTIVITY_STAGE_CLIENT_PATH, "Id", id)
        return
    end
    return config
end

function XLivWarmActivityConfigs.GetLivWarmActivityStageClientStageName(id)
    local config = GetLivWarmActivityStageClientConfig(id)
    return config.StageName
end

function XLivWarmActivityConfigs.GetLivWarmActivityStageClientRoleHead(id, headType)
    local config = GetLivWarmActivityStageClientConfig(id)
    return config.RoleHead[headType]
end

function XLivWarmActivityConfigs.GetLivWarmActivityStageClientStageEnName(id)
    local config = GetLivWarmActivityStageClientConfig(id)
    return config.StageEnName
end

function XLivWarmActivityConfigs.GetLivWarmActivityStageClientCgText(id)
    local config = GetLivWarmActivityStageClientConfig(id)
    return config.CgText
end

function XLivWarmActivityConfigs.GetLivWarmActivityStageClientCgPic(id)
    local config = GetLivWarmActivityStageClientConfig(id)
    return config.CgPic
end
-----------------LivWarmActivityStageClientConfigs end-------------------------

-----------------LivWarmActivityHeadClientConfigs begin-----------------------
local GetLivWarmActivityHeadClientConfig = function(id)
    local config = LivWarmActivityHeadClientConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XLivWarmActivityHeadClientConfigs.GetLivWarmActivityHeadClientConfig", "LivWarmActivityHeadClientConfigs", TABLE_LIV_WARM_ACTIVITY_HEAD_CLIENT_PATH, "Id", id)
        return
    end
    return config
end

function XLivWarmActivityConfigs.GetLivWarmActivityHeadColumnIndexes(id)
    local config = GetLivWarmActivityHeadClientConfig(id)
    return config.ColumnIndexes
end

function XLivWarmActivityConfigs.GetLivWarmActivityHeadStageId(id)
    local config = GetLivWarmActivityHeadClientConfig(id)
    return config.StageId
end

function XLivWarmActivityConfigs.GetLivWarmHeadIdList(stageId)
    return LivWarmStageIdToHeadIdList[stageId] or {}
end

function XLivWarmActivityConfigs.GetLivWarmActivityHeadType(headId, columnIndex)
    local columnIndexes = XLivWarmActivityConfigs.GetLivWarmActivityHeadColumnIndexes(headId)
    return columnIndexes[columnIndex]
end
-----------------LivWarmActivityHeadClientConfigs end-------------------------
