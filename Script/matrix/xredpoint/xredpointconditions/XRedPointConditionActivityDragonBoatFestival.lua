-- 端午节活动
local XRedPointConditionActivityDragonBoatFestival = {}

function XRedPointConditionActivityDragonBoatFestival.Check()
    local sectionId = XFestivalActivityConfig.ActivityId.DragonBoatFestival
    if XRedPointConditionActivityFestival.Check(sectionId) then
        return true
    end
    return false
end

return XRedPointConditionActivityDragonBoatFestival