local XRedPointConditionNewCharActTreasure = {}
local Events = nil

function XRedPointConditionNewCharActTreasure.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_FUBEN_NEWCHARACT_REWARD)
            }
    return Events
end

function XRedPointConditionNewCharActTreasure.Check(actId)
    return XDataCenter.FubenNewCharActivityManager.CheckTreasureReward(actId)
end

return XRedPointConditionNewCharActTreasure