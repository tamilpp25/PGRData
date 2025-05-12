--- 总蓝点，用于手册入口
local XRedPointXWheelChairManualGuide = {}


function XRedPointXWheelChairManualGuide:Check()
    if not XMVCA.XWheelchairManual:GetIsOpen(nil, true) then
        return false
    end

    -- 新开启蓝点
    if XMVCA.XWheelchairManual:CheckManualGuideHasAnyActivity() and XMVCA.XWheelchairManual:CheckSubActivityIsNew(XEnumConst.WheelchairManual.ReddotKey.GuideNew) then
        return true
    end
    
    -- 新解锁蓝点
    if XMVCA.XWheelchairManual:CheckCurActivityAnyGuideNewUnlock() then
        return true
    end
    
    return false
end

return XRedPointXWheelChairManualGuide