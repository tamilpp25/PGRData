local XRedPointConditionRiftEntrance = {}

function XRedPointConditionRiftEntrance.Check()
    -- 任务
    if XMVCA.XRift:CheckTaskCanReward() then
        return true
    end

    return false
end

return XRedPointConditionRiftEntrance