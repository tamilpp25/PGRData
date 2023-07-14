local XRedPointConditionTurntableTask = {}
local Events = nil

function XRedPointConditionTurntableTask.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_TASK_FINISH_FAIL),
                XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
                XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
            }
    return Events
end

function XRedPointConditionTurntableTask.Check()
    ---@type XTurntableAgency
    local agency = XMVCA:GetAgency(ModuleId.XTurntable)
    return agency:IsTaskRewardGain()
end

return XRedPointConditionTurntableTask