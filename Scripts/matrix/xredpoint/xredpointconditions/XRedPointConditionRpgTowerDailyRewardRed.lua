-- 可领取每日任务时红点

local XRedPointConditionRpgTowerDailyRewardRed = {}
local Events = nil
function XRedPointConditionRpgTowerDailyRewardRed.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_RPGTOWER_REFRESH_DAILYREWARD)
    }
    return Events
end

function XRedPointConditionRpgTowerDailyRewardRed.Check()
    return XDataCenter.RpgTowerManager.GetCanReceiveSupply()
        and (XDataCenter.RpgTowerManager.GetCurrentLevel() < XDataCenter.RpgTowerManager.GetMaxLevel())
end

return XRedPointConditionRpgTowerDailyRewardRed