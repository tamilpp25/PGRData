local XRedPointConditionReformBaseStageOpen = {}

function XRedPointConditionReformBaseStageOpen.GetEvents()
    if XRedPointConditionReformBaseStageOpen.Events == nil then
        XRedPointConditionReformBaseStageOpen.Events = {}
    end
    return XRedPointConditionReformBaseStageOpen.Events
end

function XRedPointConditionReformBaseStageOpen.Check(baseStageId)
    return XDataCenter.ReformActivityManager.CheckBaseStageIsShowRedDot(baseStageId)
end

return XRedPointConditionReformBaseStageOpen