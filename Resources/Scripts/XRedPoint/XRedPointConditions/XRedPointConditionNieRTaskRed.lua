local XRedPointConditionNieRTaskRed = {}
local Events = nil
function XRedPointConditionNieRTaskRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
    }
    return Events
end

function XRedPointConditionNieRTaskRed.Check(chapterId)
    local red = XDataCenter.NieRManager.CheckNieRTaskRed(chapterId)
    return red
end

return XRedPointConditionNieRTaskRed