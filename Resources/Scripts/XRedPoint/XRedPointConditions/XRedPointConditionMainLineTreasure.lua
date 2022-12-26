local XRedPointConditionMainLineTreasure = {}
local Events = nil

function XRedPointConditionMainLineTreasure.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_FUBEN_CHAPTER_REWARD)
            }
    return Events
end

function XRedPointConditionMainLineTreasure.Check(chapterId)
    return XDataCenter.FubenMainLineManager.CheckTreasureReward(chapterId)
end

return XRedPointConditionMainLineTreasure