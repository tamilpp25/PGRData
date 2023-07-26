local XRedPointConditionAreaWarHangUpReward = {}
local Events = nil

function XRedPointConditionAreaWarHangUpReward.GetSubEvents()
    Events =
        Events or
        {
            XRedPointEventElement.New(XEventId.EVENT_AREA_WAR_HANG_UP_REWARD_REMIND_CHANGE),
            XRedPointEventElement.New(XEventId.EVENT_AREA_WAR_HANG_UP_REWARD_COUNT_CHANGE)
        }
    return Events
end

function XRedPointConditionAreaWarHangUpReward.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.AreaWar) then
        return false
    end
    if not XDataCenter.AreaWarManager.IsOpen() then
        return false
    end
    return XDataCenter.AreaWarManager.HasHangUpRewardRemind() or XDataCenter.AreaWarManager.HasHangUpRewardToGet()
end

return XRedPointConditionAreaWarHangUpReward
