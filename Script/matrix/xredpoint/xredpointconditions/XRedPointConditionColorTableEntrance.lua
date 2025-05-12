local XRedPointConditionColorTableEntrance = {}

function XRedPointConditionColorTableEntrance.Check()
    -- 任务
    if XDataCenter.ColorTableManager.CheckTaskCanReward() then 
        return true
    end

    -- 进度奖励
    if XDataCenter.ColorTableManager.CheckProgressRed() then 
        return true
    end

    return false
end

return XRedPointConditionColorTableEntrance