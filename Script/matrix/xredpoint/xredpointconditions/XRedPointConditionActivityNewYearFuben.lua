----------------------------------------------------------------
local XRedPointConditionActivityNewYearFuben = {}

-- if 未完成 return true
function XRedPointConditionActivityNewYearFuben.Check()
    local sectionId = XFestivalActivityConfig.ActivityId.NewYearFuben
    if XRedPointConditionActivityFestival.Check(sectionId) then
        return true
    end
    return false
end

return XRedPointConditionActivityNewYearFuben
