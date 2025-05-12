--- 入口转移蓝点
local XRedPointXWheelChairManualEntranceChange = {}

function XRedPointXWheelChairManualEntranceChange.Check(ignoreOpenCheck)
    if not ignoreOpenCheck then
        if not XMVCA.XWheelchairManual:GetIsOpen(nil, true) then
            return false
        end
    end

    local ischanged = XMVCA.XWheelchairManual:CheckCurActivityEntranceChanged()

    if ischanged then
        return XMVCA.XWheelchairManual:CheckLocalReddotShow(XEnumConst.WheelchairManual.ReddotKey.EntranceChangedNew)    
    end
    
    return false 
end

return XRedPointXWheelChairManualEntranceChange