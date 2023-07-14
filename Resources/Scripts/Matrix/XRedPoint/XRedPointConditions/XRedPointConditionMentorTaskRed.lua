----------------------------------------------------------------
local XRedPointConditionMentorTaskRed = {}

local Events = nil
function XRedPointConditionMentorTaskRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_MENTOR_STUDENT_TASKCOUNT_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_MENTOR_STUDENT_WEEKLYTASK_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_MENTOR_TEACHER_STUDENTWEEKLYTASK_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_MAINUI_ENABLE),
        XRedPointEventElement.New(XEventId.EVENT_MENTOR_GETREWARD),
        XRedPointEventElement.New(XEventId.EVENT_MENTOR_INTASKUI),
        XRedPointEventElement.New(XEventId.EVENT_MENTOR_TEACHERORSTUDENT_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_MENTOR_GRADUATE_STUDENT),
        XRedPointEventElement.New(XEventId.EVENT_MENTOR_LOSE_STUDENT),
    }
    return Events
end

function XRedPointConditionMentorTaskRed.Check()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    if mentorData:IsTeacher() then
        local teacherCheck = XDataCenter.MentorSystemManager.CheckTeacherCanGetStudentWeeklyReward()
        
        return XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.MentorSystem) and teacherCheck
    elseif mentorData:IsStudent() then
        local IsSystemTaskNotEmpty = mentorData:CheckStudentSystemTaskIsEnmtyByIndex(XMentorSystemConfigs.MySelfIndex)
        local studentCheck = XDataCenter.MentorSystemManager.CheckStudentCanGetTask() or
        XDataCenter.MentorSystemManager.CheckStudentCanGetWeeklyReward() or
        XDataCenter.MentorSystemManager.CheckStudentCanGetTeacherGift()
        
        return XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.MentorSystem) and IsSystemTaskNotEmpty and studentCheck
    else
        return false
    end
end

return XRedPointConditionMentorTaskRed