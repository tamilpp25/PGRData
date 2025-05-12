local XRedPointConditionCourseBanner = {}

function XRedPointConditionCourseBanner.Check()
    return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_COURSE_EXAM_TOG) or XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_COURSE_LESSON_TOG)
end

return XRedPointConditionCourseBanner