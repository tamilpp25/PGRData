XNewYearLuckConfigs = XNewYearLuckConfigs or {}

local NEW_YEAR_LUCK_LEVEL_PATH = "Share/MiniActivity/NewYearLuck/NewYearLuckLevel.tab"
local NEW_YEAR_LUCK_ACTIVITY_PATH = "Share/MiniActivity/NewYearLuck/NewYearLuckActivity.tab"

XNewYearLuckConfigs.TicketType = {
    Normal = 1,
    Special = 2
}

local NewYearLuckActivity = {}
local NewYearLuckLevel = {}

function XNewYearLuckConfigs.Init()
    NewYearLuckActivity = XTableManager.ReadByIntKey(NEW_YEAR_LUCK_ACTIVITY_PATH,XTable.XTableNewYearLuckActivity,"Id")
    NewYearLuckLevel = XTableManager.ReadByIntKey(NEW_YEAR_LUCK_LEVEL_PATH,XTable.XTableNewYearLuckLevel,"Id")
end

function XNewYearLuckConfigs.GetActivityConfig(activityId)
    if not NewYearLuckActivity[activityId] then
        XLog.ErrorTableDataNotFound("XNewYearLuckConfigs.GetActivityConfig","配置表项",NEW_YEAR_LUCK_ACTIVITY_PATH,"Id",tostring(activityId))
        return
    end
    return NewYearLuckActivity[activityId] 
end

function XNewYearLuckConfigs.GetLevelListByType(groupType, activityId)
    local list = {}
    for _, config in pairs(NewYearLuckLevel) do
        if config.GroupType == groupType and config.ActivityId == activityId then
            table.insert(list, config)
        end
    end
    return list
end
function XNewYearLuckConfigs.GetLevelConfig(id, activityId)
    for _, config in pairs(NewYearLuckLevel) do
        if config.Id == id and config.ActivityId == activityId then
            return config
        end
    end
end
function XNewYearLuckConfigs.GetLevelTypeById(id, activityId)
    local config = XNewYearLuckConfigs.GetLevelConfig(id,activityId)
    if config then
        return config.GroupType
    end
end

function XNewYearLuckConfigs.GetLevelLuckNumbersById(id, activityId)
    local config =  XNewYearLuckConfigs.GetLevelConfig(id,activityId)
    if config then
        return config.LuckNums
    end
end
