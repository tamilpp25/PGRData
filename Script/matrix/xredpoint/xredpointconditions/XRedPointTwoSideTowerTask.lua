
local XRedPointTwoSideTowerTask = {}
local Events = nil

function XRedPointTwoSideTowerTask.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC)
    }
    return Events
end

function XRedPointTwoSideTowerTask.Check()
    ---@type XTwoSideTowerAgency
    local twoSideTowerAgency = XMVCA:GetAgency(ModuleId.XTwoSideTower)
    return twoSideTowerAgency:CheckTaskFinish()
end

return XRedPointTwoSideTowerTask