----------------------------------------------------------------
--光辉同行 入口红点

local XRedPointConditionBrilliantWalk = {}
local Events = nil
local SubCondition = nil
function XRedPointConditionBrilliantWalk.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_BRILLIANT_WALK_ON_PLUGIN_UNLOCK_STATE),
    }
    return Events
end

function XRedPointConditionBrilliantWalk.Check()
    local result = XDataCenter.BrilliantWalkManager.CheckBrilliantWalkRed()
    return result
end

return XRedPointConditionBrilliantWalk