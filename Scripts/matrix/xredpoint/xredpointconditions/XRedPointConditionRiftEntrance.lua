local XRedPointConditionRiftEntrance = {}

function XRedPointConditionRiftEntrance.Check()
    -- 任务
    if XDataCenter.RiftManager.CheckTaskCanReward() then 
        return true
    end

    return false
end

return XRedPointConditionRiftEntrance