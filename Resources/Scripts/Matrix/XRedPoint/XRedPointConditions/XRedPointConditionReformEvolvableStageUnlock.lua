local XRedPointConditionReformEvolvableStageUnlock = {}

function XRedPointConditionReformEvolvableStageUnlock.GetEvents()
    if XRedPointConditionReformEvolvableStageUnlock.Events == nil then
        XRedPointConditionReformEvolvableStageUnlock.Events = { }
    end
    return XRedPointConditionReformEvolvableStageUnlock.Events
end

function XRedPointConditionReformEvolvableStageUnlock.Check(args)
    args = args or {}
    return XDataCenter.ReformActivityManager.CheckEvolvableDiffIsShowRedDot(args.BaseStageId, args.EvolvableDiffIndex)
end

return XRedPointConditionReformEvolvableStageUnlock