-- 红点条件检测器
--默认
local XRedPointConditionAssign = {}

local Events = nil
function XRedPointConditionAssign.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENET_ASSIGN_CAN_REWARD),
    }
    return Events
end
--检测
function XRedPointConditionAssign.Check()
    return XDataCenter.FubenAssignManager.IsRedPoint()
end

return XRedPointConditionAssign