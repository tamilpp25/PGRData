--- 总蓝点，用于手册入口
local XRedPointXWheelChairManualTeaching = {}


function XRedPointXWheelChairManualTeaching:Check()
    if not XMVCA.XWheelchairManual:GetIsOpen(nil, true) then
        return false
    end

    -- 新开启蓝点
    if XMVCA.XWheelchairManual:CheckSubActivityIsNew(XEnumConst.WheelchairManual.ReddotKey.TeachingNew) then
        return true
    end
    
    -- 任务待领取奖励蓝点
    if XMVCA.XWheelchairManual:CheckCurActivityTeachingAnyTaskCanReward() then
        return true
    end
    
    -- 新关卡解锁蓝点
    if XMVCA.XWheelchairManual:CheckCurActivityTeachingAnyStageNewUnlock() then
        return true
    end
    
    return false
end

return XRedPointXWheelChairManualTeaching