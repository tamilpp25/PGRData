local XRedPointConditionCourseBanner = {}

function XRedPointConditionCourseBanner.Check()
    return XRedPointConditionCourseExamTog.Check() or XRedPointConditionCourseLessonTog.Check()
end

return XRedPointConditionCourseBanner