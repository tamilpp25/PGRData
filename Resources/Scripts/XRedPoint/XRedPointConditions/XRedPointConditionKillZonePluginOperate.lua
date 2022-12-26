local Events = nil

local XRedPointConditionKillZonePluginOperate = {}

function XRedPointConditionKillZonePluginOperate.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XKillZoneConfigs.ItemIdCoinA),
        XRedPointEventElement.New(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XKillZoneConfigs.ItemIdCoinB),
        XRedPointEventElement.New(XEventId.EVENT_KILLZONE_PLUGIN_OPERATE_CHANGE),
    }
    return Events
end

function XRedPointConditionKillZonePluginOperate.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.KillZone) then
        return false
    end

    if not XDataCenter.KillZoneManager.IsOpen() then
        return false
    end

    return XDataCenter.KillZoneManager.CheckPluginsCanOperateRedPoint()
end

return XRedPointConditionKillZonePluginOperate