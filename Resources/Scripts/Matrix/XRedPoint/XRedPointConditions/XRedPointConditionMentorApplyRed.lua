----------------------------------------------------------------
local XRedPointConditionMentorApplyRed = {}

local Events = nil
function XRedPointConditionMentorApplyRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_MENTOR_GET_APPLY),
        XRedPointEventElement.New(XEventId.EVENT_MENTOR_OPERATION_APPLY),
        XRedPointEventElement.New(XEventId.EVENT_MAINUI_ENABLE),
        XRedPointEventElement.New(XEventId.EVENT_MENTOR_TEACHERORSTUDENT_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_BLACK_DATA_CHANGE),
    }
    return Events
end

function XRedPointConditionMentorApplyRed.Check()
    local mentorData = XDataCenter.MentorSystemManager.GetMentorData()
    return XFunctionManager.JudgeOpen(XFunctionManager.FunctionName.MentorSystem) and mentorData:IsHasApply() and mentorData:IsCanDoApply(false)
end

return XRedPointConditionMentorApplyRed