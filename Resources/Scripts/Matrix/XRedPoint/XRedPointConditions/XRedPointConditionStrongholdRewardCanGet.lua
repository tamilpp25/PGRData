local Events = nil

local XRedPointConditionStrongholdRewardCanGet = {}

function XRedPointConditionStrongholdRewardCanGet.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_STRONGHOLD_FINISH_REWARDS_CHANGE),
    }
    return Events
end

function XRedPointConditionStrongholdRewardCanGet.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Stronghold) then
        return false
    end

    return XDataCenter.StrongholdManager.IsAnyRewardCanGet()
end

return XRedPointConditionStrongholdRewardCanGet