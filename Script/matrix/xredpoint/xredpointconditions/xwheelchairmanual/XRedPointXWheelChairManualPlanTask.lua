--- 阶段任务蓝点
local XRedPointXWheelChairManualPlanTask = {}


function XRedPointXWheelChairManualPlanTask:Check()
    if not XMVCA.XWheelchairManual:GetIsOpen(nil, true) then
        return false
    end

    -- 新开启蓝点
    if XMVCA.XWheelchairManual:CheckSubActivityIsNew(XEnumConst.WheelchairManual.ReddotKey.StepTaskNew) then
        return true
    end
    
    -- 待领取奖励蓝点
    if XMVCA.XWheelchairManual:CheckCurActivityAnyPlanCanGetTaskReward() then
        return true
    end
    
    return false
end

return XRedPointXWheelChairManualPlanTask