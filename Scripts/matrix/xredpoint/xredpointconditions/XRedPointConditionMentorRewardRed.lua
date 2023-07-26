----------------------------------------------------------------
local XRedPointConditionMentorRewardRed = {}

local Events = nil
function XRedPointConditionMentorRewardRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_PLAYER_LEVEL_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_MENTOR_GRADUATE_STUDENT),
        XRedPointEventElement.New(XEventId.EVENT_MAINUI_ENABLE),
        XRedPointEventElement.New(XEventId.EVENT_FINISH_TASK),
        XRedPointEventElement.New(XEventId.EVENT_MENTOR_GETREWARD),
        XRedPointEventElement.New(XEventId.EVENT_MENTOR_TEACHERORSTUDENT_CHANGE),
    }
    return Events
end

function XRedPointConditionMentorRewardRed.Check()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    if mentorData:IsTeacher() then
        local teacherCheck = XDataCenter.MentorSystemManager.CheckTeacherCanGetStudentTaskReward() or
        XDataCenter.MentorSystemManager.CheckTeacherCanGetGraduateReward()
        
        return XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.MentorSystem) and teacherCheck
    elseif mentorData:IsStudent() then
        local studentCheck = XDataCenter.TaskManager.GetIsRewardFor(XDataCenter.TaskManager.TaskType.MentorShipGrow) or
        XDataCenter.TaskManager.GetIsRewardFor(XDataCenter.TaskManager.TaskType.MentorShipGraduate)
        
        return XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.MentorSystem) and studentCheck
    else
        return false 
    end
end

return XRedPointConditionMentorRewardRed