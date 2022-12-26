-- 猜拳小游戏配置表
XFingerGuessingConfig = {}

--    ===================表地址
local SHARE_TABLE_PATH = "Share/MiniActivity/FingerGuessingGame/"
local CLIENT_TABLE_PATH = "Client/MiniActivity/FingerGuessingGame/"
local TABLE_ACTIVITY = SHARE_TABLE_PATH .. "FingerGuessingActivity.tab"
local TABLE_STAGE = SHARE_TABLE_PATH .. "FingerGuessingStage.tab"
local TABLE_ROUND = SHARE_TABLE_PATH .. "FingerGuessingStageRound.tab"
local TABLE_FINGER = SHARE_TABLE_PATH .. "FingerGuessingFinger.tab"
--    ===================原表数据
local FingerGuessingActivityConfig = {}
local FingerGuessingStageConfig = {}
local FingerGuessingRoundConfig = {}
local FingerGuessingFingerConfig = {}
--    ===================构建字典
local Stage2RoundDic = {}

local CreateStage2RoundDic = function()
    for _, roundConfig in pairs(FingerGuessingRoundConfig) do
        local stageId = roundConfig.StageId
        if not Stage2RoundDic[stageId] then Stage2RoundDic[stageId] = {} end
        Stage2RoundDic[stageId][roundConfig.Round] = roundConfig
    end
end
--================
--初始化Config
--================
function XFingerGuessingConfig.Init()
    FingerGuessingActivityConfig = XTableManager.ReadByIntKey(TABLE_ACTIVITY, XTable.XTableFingerGuessingActivity, "Id")
    FingerGuessingStageConfig = XTableManager.ReadByIntKey(TABLE_STAGE, XTable.XTableFingerGuessingStage, "Id")
    FingerGuessingRoundConfig = XTableManager.ReadByIntKey(TABLE_ROUND, XTable.XTableFingerGuessingStageRound, "Id")
    FingerGuessingFingerConfig = XTableManager.ReadByIntKey(TABLE_FINGER, XTable.XTableFingerGuessingFinger, "Id")
    CreateStage2RoundDic()
end
--================
--获取所有活动配置
--================
function XFingerGuessingConfig.GetAllActivityConfig()
    return FingerGuessingActivityConfig
end
--================
--获取最后的活动配置
--================
function XFingerGuessingConfig.GetLastestActivityConfig()
    local id = 0
    for configId, _ in pairs(FingerGuessingActivityConfig) do
        if configId > id then
            id = configId
        end
    end
    return FingerGuessingActivityConfig[id]
end
--================
--根据活动Id获取活动配置
--@param activityId:活动Id
--================
function XFingerGuessingConfig.GetActivityConfigById(activityId)
    local config = FingerGuessingActivityConfig[activityId]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XFingerGuessingConfig.GetActivityConfigById",
            "猜拳小游戏基础配置",
            TABLE_ACTIVITY,
            "Id",
            tostring(activityId))
        return nil
    end
    return config
end
--================
--获取所有关卡配置
--================
function XFingerGuessingConfig.GetAllStageConfig()
    return FingerGuessingStageConfig
end
--================
--根据关卡Id获取关卡配置
--@param stageId:关卡Id
--================
function XFingerGuessingConfig.GetStageConfigById(stageId)
    local config = FingerGuessingStageConfig[stageId]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XFingerGuessingConfig.GetStageConfigById",
            "猜拳小游戏关卡配置",
            TABLE_STAGE,
            "Id",
            tostring(stageId))
        return nil
    end
    return config
end
--================
--获取所有小局配置
--================
function XFingerGuessingConfig.GetAllRoundConfig()
    return FingerGuessingRoundConfig
end
--================
--根据小局Id获取小局配置
--@param roundId:小局Id
--================
function XFingerGuessingConfig.GetRoundConfigById(roundId)
    local config = FingerGuessingRoundConfig[roundId]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XFingerGuessingConfig.GetRoundConfigById",
            "猜拳小游戏小局配置",
            TABLE_ROUND,
            "Id",
            tostring(roundId))
        return nil
    end
    return config
end
--================
--获取所有出拳配置
--================
function XFingerGuessingConfig.GetAllFingerConfig()
    return FingerGuessingFingerConfig
end
--================
--根据关卡Id获取该关卡的所有小局配置
--@param stageId:关卡Id
--================
function XFingerGuessingConfig.GetRoundConfigByStageId(stageId)
    local configs = Stage2RoundDic[stageId]
    if not configs then
        XLog.ErrorTableDataNotFound(
            "XFingerGuessingConfig.GetRoundConfigByStageId",
            "猜拳小游戏小局配置",
            TABLE_ROUND,
            "StageId",
            tostring(stageId))
        return {}
    end
    return configs
end
--================
--根据出拳ID获取出拳配置
--@param fingerId:出拳ID
--================
function XFingerGuessingConfig.GetFingerConfigById(fingerId)
    local config = FingerGuessingFingerConfig[fingerId]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XFingerGuessingConfig.GetFingerConfigById",
            "猜拳小游戏出拳配置",
            TABLE_FINGER,
            "Id",
            tostring(fingerId))
        return nil
    end
    return config
end