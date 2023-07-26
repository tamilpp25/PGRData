----------------------------------------------------------------
--光辉同行 任务奖励未领取红点

local XRedPointConditionBrilliantWalkTask = {}
local Events = nil
local SubCondition = nil
function XRedPointConditionBrilliantWalkTask.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
    }
    return Events
end

function XRedPointConditionBrilliantWalkTask.Check()
    local result = XDataCenter.BrilliantWalkManager.CheckBrilliantWalkTaskRed()
    return result
end

return XRedPointConditionBrilliantWalkTask