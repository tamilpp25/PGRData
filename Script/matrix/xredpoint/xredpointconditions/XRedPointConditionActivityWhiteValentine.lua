--白情活动
local XRedPointConditionActivityWhiteValentine = {}

function XRedPointConditionActivityWhiteValentine.Check()
    local sectionId = XFestivalActivityConfig.ActivityId.WhiteValentine
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_ACTIVITY_FESTIVAL, sectionId) then
        return true
    end
    return false
end

return XRedPointConditionActivityWhiteValentine