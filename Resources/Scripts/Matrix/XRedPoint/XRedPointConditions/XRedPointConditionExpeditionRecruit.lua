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
    if XDataCenter.ExpeditionManager.GetIsChapterClear(XDataCenter.ExpeditionManager.StageDifficulty.Normal) then
        if not XDataCenter.ExpeditionManager.GetIsReceivedReward(XDataCenter.ExpeditionManager.StageDifficulty.Normal) then
            return true
        end
    end
    if XDataCenter.ExpeditionManager.GetIsChapterClear(XDataCenter.ExpeditionManager.StageDifficulty.NightMare) then
        if not XDataCenter.ExpeditionManager.GetIsReceivedReward(XDataCenter.ExpeditionManager.StageDifficulty.NightMare) then
            return true
        end
    end
    return false
end

return XRedPointConditionExpeditionRecruit