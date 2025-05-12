--- BP手册蓝点
local XRedPointXWheelChairManualBP = {}


function XRedPointXWheelChairManualBP:Check()
    if not XMVCA.XWheelchairManual:GetIsOpen(nil, true) then
        return false
    end

    -- 新开启蓝点
    if XMVCA.XWheelchairManual:CheckSubActivityIsNew(XEnumConst.WheelchairManual.ReddotKey.BPRewardNew) then
        return true
    end
    
    -- 待领取奖励蓝点
    if XMVCA.XWheelchairManual:CheckManualAnyRewardCanGet() then
        return true
    end
    
    return false
end

return XRedPointXWheelChairManualBP