local XRedPointConditionExpeditionRecruit = {}
local Events = nil
--虚像地平线入口处红点（早期的类名改得不好，这里沿用）
function XRedPointConditionExpeditionRecruit.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_EXPEDITION_RECRUITTIME_REFRESH)
    }
    return Events
end

function XRedPointConditionExpeditionRecruit.Check()
    return XRedPointConditionExpeditionRecruit.CanGetReward() --or XDataCenter.ExpeditionManager.CheckRecruitRedPoint()
end

function XRedPointConditionExpeditionRecruit.CanGetReward()
    if XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.Expedition) then
        return false
    end
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Expedition) then
        return false
    end
    if XDataCenter.ExpeditionManager.GetIsActivityEnd() then
        return false
    end
    if not XDataCenter.ExpeditionManager.GetIsChapterClear() then -- 未全通关是显示红点
        return true
    end
    if XDataCenter.ExpeditionManager.CheckExpeditionTaskRedPoint() then
        return true
    end
    return false
end

return XRedPointConditionExpeditionRecruit