-- 端午节活动
local XRedPointConditionActivityDragonBoatFestival = {}

function XRedPointConditionActivityDragonBoatFestival.Check()
    local sectionId = XFestivalActivityConfig.ActivityId.DragonBoatFestival
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_ACTIVITY_FESTIVAL, sectionId) then
        return true
    end
    return false
end

return XRedPointConditionActivityDragonBoatFestival