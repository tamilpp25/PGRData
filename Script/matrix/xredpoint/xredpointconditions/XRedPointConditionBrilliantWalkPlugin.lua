----------------------------------------------------------------
--光辉同行 有新的插件解锁 未确认

local XRedPointConditionBrilliantWalkPlugin = {}
local Events = nil
local SubCondition = nil
function XRedPointConditionBrilliantWalkPlugin.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_BRILLIANT_WALK_ON_PLUGIN_UNLOCK_STATE),
    }
    return Events
end

function XRedPointConditionBrilliantWalkPlugin.Check()
    local result = XDataCenter.BrilliantWalkManager.CheckBrilliantWalkPluginRed()
    return result
end

return XRedPointConditionBrilliantWalkPlugin