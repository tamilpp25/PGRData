local XRedPointGachaCanLiverTask = {}


function XRedPointGachaCanLiverTask:Check()
    if not XMVCA.XGachaCanLiver:GetIsOpen() then
        return false
    end
    
    -- 如果不能再继续任务了，则不显示蓝点
    if XMVCA.XGachaCanLiver:CheckTaskFinishAchieveLimit() then
        return false
    end

    -- 是否未首次进入过任务
    if XMVCA.XGachaCanLiver:CheckReddotShowByKey(XEnumConst.GachaCanLiver.ReddotKey.TaskNoEnter) then
        return true
    end
    
    -- 是否有任意任务可领取奖励
    if XMVCA.XGachaCanLiver:CheckAnyTaskCanFinish() then
        return true
    end

    return false
end

return XRedPointGachaCanLiverTask