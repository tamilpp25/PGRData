-- 拉人活动入口红点检测
local XRedPointConditionReCallReward = {}
local Events = nil

function XRedPointConditionReCallReward.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_RECALL_TASK_UPDATE)
    }
    return Events
end

function XRedPointConditionReCallReward.Check()
    local result = 0
    if XMVCA.XReCallActivity:CheckHasReward() then
        result = result + 1
    end
    return result
end

return XRedPointConditionReCallReward