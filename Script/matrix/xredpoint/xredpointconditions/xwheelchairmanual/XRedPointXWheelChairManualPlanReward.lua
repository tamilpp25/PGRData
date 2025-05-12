--- 阶段奖励蓝点
local XRedPointXWheelChairManualPlanReward = {}


function XRedPointXWheelChairManualPlanReward:Check()
    if not XMVCA.XWheelchairManual:GetIsOpen(nil, true) then
        return false
    end
    
    -- 新开启蓝点
    if XMVCA.XWheelchairManual:CheckSubActivityIsNew(XEnumConst.WheelchairManual.ReddotKey.StepRewardNew) then
        return true
    end
    
    -- 待领取奖励蓝点
    if XMVCA.XWheelchairManual:CheckCurActivityAnyPlanCanGetReward() then
        return true
    end
    
    return false
end

return XRedPointXWheelChairManualPlanReward