-- 拉人活动入口红点检测
local XRedPointConditionReCallInvite = {}
local Events = nil

function XRedPointConditionReCallInvite.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_RECALL_OPEN_STATUS_UPDATE)
    }
    return Events
end
function XRedPointConditionReCallInvite.Check()
    local result = 0
    if XMVCA.XReCallActivity:CheckCanInvite() then
        result = result + 1
    end
    return result
end

return XRedPointConditionReCallInvite