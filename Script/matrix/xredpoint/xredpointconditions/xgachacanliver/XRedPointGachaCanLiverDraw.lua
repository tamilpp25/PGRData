local XRedPointGachaCanLiverDraw = {}


function XRedPointGachaCanLiverDraw:Check()
    if not XMVCA.XGachaCanLiver:GetIsOpen() then
        return false
    end

    -- 如果入口没有转移，那么不需要显示蓝点
    -- 目前转移条件是活动没关，但限时卡池关了
    if not XMVCA.XGachaCanLiver:CheckTimeLimitDrawIsOutTime() then
        return false
    end
    
    -- 满足入口转移条件，再来看是否未首次进入
    if XMVCA.XGachaCanLiver:CheckReddotShowByKey(XEnumConst.GachaCanLiver.ReddotKey.ResistenceDrawNoEnterAfterTLClsoed) then
        return true
    end

    return false
end

return XRedPointGachaCanLiverDraw