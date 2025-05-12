
----------------------------------------------------------------
local XRedPointConditionMainNotice = {}
local SubConditions = nil

function XRedPointConditionMainNotice.Check()
    -- XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_ACTIVITY_NEW_ACTIVITIES)
    return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_ACTIVITY_NEW_NOTICES) 
            or XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_ACTIVITY_NEW_ACTIVITY_NOTICES)
end

function XRedPointConditionMainNotice.GetSubConditions()
    return SubConditions or {
        --XRedPointConditions.Types.CONDITION_ACTIVITY_NEW_ACTIVITIES,
        XRedPointConditions.Types.CONDITION_ACTIVITY_NEW_NOTICES,
        XRedPointConditions.Types.CONDITION_ACTIVITY_NEW_ACTIVITY_NOTICES,
    }
end

return XRedPointConditionMainNotice