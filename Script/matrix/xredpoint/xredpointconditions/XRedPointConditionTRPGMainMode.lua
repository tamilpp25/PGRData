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
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TRPG_TRUTH_ROAD_REWARD) then
        return true
    end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TRPG_COLLECTION_MEMOIR) then
        return true
    end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TRPG_AREA_REWARD) then
        return true
    end
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TRPG_WORLD_BOSS_REWARD) then
        return true
    end
    return false
end

return XRedPointConditionTRPGMainMode