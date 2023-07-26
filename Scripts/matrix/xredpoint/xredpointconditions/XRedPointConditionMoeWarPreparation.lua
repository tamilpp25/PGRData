local XRedPointConditionMoeWarPreparation = {}
local SubConditions = nil

function XRedPointConditionMoeWarPreparation.GetSubConditions()
    SubConditions = SubConditions or
    {
        XRedPointConditions.Types.CONDITION_MOEWAR_PREPARATION_REWARD,
        XRedPointConditions.Types.CONDITION_MOEWAR_PREPARATION_OPEN_STAGE,
    }
    return SubConditions
end

function XRedPointConditionMoeWarPreparation.Check()
    local preparationActivityId = XMoeWarConfig.GetPreparationActivityIdInTime()
    if not preparationActivityId then
        return false
    end

    if XRedPointConditionMoeWarPreparationReward.Check() then
        return true
    end

    if XRedPointConditionMoeWarPreparationOpenStage.Check() then
        return true
    end

    return false
end

return XRedPointConditionMoeWarPreparation