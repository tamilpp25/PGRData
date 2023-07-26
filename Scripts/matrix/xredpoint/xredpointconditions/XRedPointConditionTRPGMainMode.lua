local XRedPointConditionTRPGMainMode = {}
local SubCondition = nil

function XRedPointConditionTRPGMainMode.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_TRPG_TRUTH_ROAD_REWARD,
        XRedPointConditions.Types.CONDITION_TRPG_COLLECTION_MEMOIR,
        XRedPointConditions.Types.CONDITION_TRPG_AREA_REWARD,
        XRedPointConditions.CONDITION_TRPG_WORLD_BOSS_REWARD,
    }
    return SubCondition
end

function XRedPointConditionTRPGMainMode.Check()
    if XRedPointTRPGTruthRoadReward.Check() then
        return true
    end
    if XRedPointTRPGCollectionMemoir.Check() then
        return true
    end
    if XRedPointTRPGAreaReward.Check() then
        return true
    end
    if XRedPointTRPGWorldBossReward.Check() then
        return true
    end
    return false
end

return XRedPointConditionTRPGMainMode