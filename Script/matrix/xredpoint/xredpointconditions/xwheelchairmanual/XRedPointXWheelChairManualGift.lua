--- 总蓝点，用于手册入口
local XRedPointXWheelChairManualGift = {}


function XRedPointXWheelChairManualGift:Check()
    if not XMVCA.XWheelchairManual:GetIsOpen(nil, true) then
        return false
    end

    -- 新开启蓝点
    if XMVCA.XWheelchairManual:CheckSubActivityIsNew(XEnumConst.WheelchairManual.ReddotKey.GiftNew) then
        return true
    end
    
    -- 判断是否有任意免费礼包可以领取
    if XMVCA.XWheelchairManual:CheckCurActivityAnyFreeGiftPackCanGet() then
        return true
    end
    
    -- 判断是否有新解锁
    if XMVCA.XWheelchairManual:CheckCurActivityAnyNewUnlockGiftPack() then
        return true
    end
    
    return false
end

return XRedPointXWheelChairManualGift