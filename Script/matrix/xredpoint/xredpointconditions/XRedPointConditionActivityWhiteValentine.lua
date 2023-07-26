--白情活动
local XRedPointConditionActivityWhiteValentine = {}

function XRedPointConditionActivityWhiteValentine.Check()
    local sectionId = XFestivalActivityConfig.ActivityId.WhiteValentine
    if XRedPointConditionActivityFestival.Check(sectionId) then
        return true
    end
    return false
end

return XRedPointConditionActivityWhiteValentine