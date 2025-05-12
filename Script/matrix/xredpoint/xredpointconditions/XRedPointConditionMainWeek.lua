local XRedPointConditionMainWeek = {}

function XRedPointConditionMainWeek.Check()
    if XDataCenter.ActivityCalendarManager.CheckActivityRedPoint() then
        return true
    end
    return false
end

return XRedPointConditionMainWeek