local XRedPointGachaCanLiverTimelimitDraw = {}


function XRedPointGachaCanLiverTimelimitDraw:Check()
    if not XMVCA.XGachaCanLiver:GetIsOpen() then
        return false
    end

    -- 如果限时卡池关了，则不显示蓝点
    if XMVCA.XGachaCanLiver:CheckTimeLimitDrawIsOutTime() then
        return false
    end
    
    -- 是否未首次进入过限时卡池
    if XMVCA.XGachaCanLiver:CheckReddotShowByKey(XEnumConst.GachaCanLiver.ReddotKey.TimelimitDrawNoEnter) then
        return true
    end
    
    -- 是否解锁后未首次进入过限时卡池
    if XMVCA.XGachaCanLiver:CheckTimeLimitDrawIsUnlock(nil, true) then
        if XMVCA.XGachaCanLiver:CheckReddotShowByKey(XEnumConst.GachaCanLiver.ReddotKey.TimelimitDrawNoEnterAfterUnLock) then
            return true
        end
    end

    return false
end

return XRedPointGachaCanLiverTimelimitDraw