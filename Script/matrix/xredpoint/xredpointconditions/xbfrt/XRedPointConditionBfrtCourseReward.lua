---@class XRedPointConditionBfrtCourseReward
local XRedPointConditionBfrtCourseReward = {}

local Events = nil
function XRedPointConditionBfrtCourseReward.GetSubEvents()
    Events = Events or
        {
            XRedPointEventElement.New(XEventId.EVENT_BFRT_COURSE_REWARD_RECV)
        }
    return Events
end

function XRedPointConditionBfrtCourseReward.Check()
    return XDataCenter.BfrtManager.CheckAnyCourseRewardRecv()
end

return XRedPointConditionBfrtCourseReward