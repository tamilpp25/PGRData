XAccumulatedConsumeConfig = XAccumulatedConsumeConfig or {}

local SHARE_CONSUME_DRAW_ACTIVITY = "Share/MiniActivity/AccumulatedConsumeDraw/AccumulatedConsumeDrawActivity.tab"
local SHARE_CONSUME_DRAW_REWARD = "Share/MiniActivity/AccumulatedConsumeDraw/AccumulatedConsumeDrawReward.tab"

local CLIENT_CONSUME_DRAW_ACTIVITY_DETAIL = "Client/MiniActivity/AccumulatedConsumeDraw/AccumulatedConsumeDrawActivityDetail.tab"
local CLIENT_CONSUME_DRAW_EXCHANGE_ICON = "Client/MiniActivity/AccumulatedConsumeDraw/AccumulatedConsumeDrawExchangeIcon.tab"
local CLIENT_CONSUME_DRAW_PROB_SHOW = "Client/MiniActivity/AccumulatedConsumeDraw/AccumulatedConsumeDrawProbShow.tab"
local CLIENT_CONSUME_DRAW_RULE = "Client/MiniActivity/AccumulatedConsumeDraw/AccumulatedConsumeDrawRule.tab"
local CLIENT_CONSUME_DRAW_REWARD_TYPE = "Client/MiniActivity/AccumulatedConsumeDraw/AccumulatedConsumeDrawRewardType.tab"

local ConsumeDrawActivity = {}
local ConsumeDrawReward = {}

local ConsumeDrawActivityDetail = {}
local ConsumeDrawProbShow = {}
local ConsumeDrawRule = {}
local ConsumeDrawRewardType = {}

function XAccumulatedConsumeConfig.Init()
    ConsumeDrawActivity = XTableManager.ReadByIntKey(SHARE_CONSUME_DRAW_ACTIVITY, XTable.XTableAccumulatedConsumeDrawActivity, "Id")
    ConsumeDrawReward = XTableManager.ReadByIntKey(SHARE_CONSUME_DRAW_REWARD, XTable.XTableAccumulatedConsumeDrawReward, "ActId")

    ConsumeDrawActivityDetail = XTableManager.ReadByIntKey(CLIENT_CONSUME_DRAW_ACTIVITY_DETAIL, XTable.XTableAccumulatedConsumeDrawActivityDetail, "Id")
    ConsumeDrawProbShow = XTableManager.ReadByIntKey(CLIENT_CONSUME_DRAW_PROB_SHOW, XTable.XTableAccumulatedConsumeDrawProbShow, "Id")
    ConsumeDrawRule = XTableManager.ReadByIntKey(CLIENT_CONSUME_DRAW_RULE, XTable.XTableAccumulatedConsumeDrawRule, "DrawId")
    ConsumeDrawRewardType = XTableManager.ReadByIntKey(CLIENT_CONSUME_DRAW_REWARD_TYPE, XTable.XTableAccumulatedConsumeDrawRewardType, "RewardType")
    
    XConfigCenter.CreateGetPropertyByFunc(XAccumulatedConsumeConfig, "ConsumeDrawExchangeConfig", function()
        return XTableManager.ReadByStringKey(CLIENT_CONSUME_DRAW_EXCHANGE_ICON, XTable.XTableAccumulatedConsumeDrawExchangeIcon, "Key")
    end)
end

--region AccumulatedConsumeDrawActivity.tab

local function GetConsumeDrawActivity(id)
    local config = ConsumeDrawActivity[id]
    if not config then
        XLog.Error("XAccumulatedConsumeConfig GetConsumeDrawActivity error:配置不存在，Id:" .. id .. ",Path:" .. SHARE_CONSUME_DRAW_ACTIVITY)
        return
    end
    return config
end

function XAccumulatedConsumeConfig.GetDrawActivity(id)
    return GetConsumeDrawActivity(id)
end

--endregion

--region AccumulatedConsumeDrawReward.tab

local function GetConsumeDrawReward(actId)
    local config = ConsumeDrawReward[actId]
    if not config then
        XLog.Error("XAccumulatedConsumeConfig GetConsumeDrawReward error:配置不存在，ActId:" .. actId .. ",Path:" .. SHARE_CONSUME_DRAW_REWARD)
        return
    end
    return config
end

function XAccumulatedConsumeConfig.GetDrawReward(actId)
    return GetConsumeDrawReward(actId)
end

--endregion

--region AccumulatedConsumeDrawActivityDetail.tab

local function GetConsumeDrawActivityDetail(id)
    local config = ConsumeDrawActivityDetail[id]
    if not config then
        XLog.Error("XAccumulatedConsumeConfig GetConsumeDrawActivityDetail error:配置不存在，id:" .. id .. ",Path:" .. CLIENT_CONSUME_DRAW_ACTIVITY_DETAIL)
        return
    end
    return config
end

function XAccumulatedConsumeConfig.GetDrawActivityDetail(id)
    return GetConsumeDrawActivityDetail(id)
end

--endregion

--region AccumulatedConsumeDrawProbShow.tab

function XAccumulatedConsumeConfig.GetDrawProbShowByDrawId(drawId)
    local config = {}
    for _, pronShow in pairs(ConsumeDrawProbShow) do
        if pronShow.DrawId == drawId then
            table.insert(config, pronShow)
        end
    end
    table.sort(config, function(a, b)
        return a.Id < b.Id
    end)
    return config
end

--endregion

--region AccumulatedConsumeDrawRule.tab

local function GetConsumeDrawRule(drawId)
    local config = ConsumeDrawRule[drawId]
    if not config then
        XLog.Error("XAccumulatedConsumeConfig GetConsumeDrawRule error:配置不存在，drawId:" .. drawId .. ",Path:" .. CLIENT_CONSUME_DRAW_RULE)
        return
    end
    return config
end

function XAccumulatedConsumeConfig.GetDrawRule(drawId)
    return GetConsumeDrawRule(drawId)
end

--endregion

function XAccumulatedConsumeConfig.GetDrawRewardTypeConfig()
    return ConsumeDrawRewardType
end

function XAccumulatedConsumeConfig.GetDefaultActivityId()
    local defaultActivityId = 0
    for activityId, config in pairs(ConsumeDrawActivity) do
        defaultActivityId = activityId
        if XTool.IsNumberValid(config.TimeId) and XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
            break
        end
    end
    return defaultActivityId
end

function XAccumulatedConsumeConfig.GetConsumeSpecialIcons()
    return XAccumulatedConsumeConfig.GetConsumeDrawExchangeConfig("ConsumeIcons").Values
end

function XAccumulatedConsumeConfig.GetTargetIcon()
    return XAccumulatedConsumeConfig.GetConsumeDrawExchangeConfig("TargetIcon").Values[1]
end