-- 拉人活动入口红点检测
local XRedPointConditionReCallEntrance = {}

function XRedPointConditionReCallEntrance.Check()
    local result = 0
    if XMVCA.XReCallActivity:CheckIsFirstOpen() then
        result = result + 1
    end
    if XMVCA.XReCallActivity:CheckHasReward() then
        result = result + 1
    end
    if XMVCA.XReCallActivity:CheckCanInvite() then
        result = result + 1
    end
    return result
end

return XRedPointConditionReCallEntrance