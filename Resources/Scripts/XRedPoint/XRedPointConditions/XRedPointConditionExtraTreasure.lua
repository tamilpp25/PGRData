local XRedPointConditionExtraTreasure = {}
local Events = nil

function XRedPointConditionExtraTreasure.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_FUBEN_EXTRACHAPTER_REWARD)
            }
    return Events
end

function XRedPointConditionExtraTreasure.Check(chapterId)
    return XDataCenter.ExtraChapterManager.CheckTreasureReward(chapterId)
end
return XRedPointConditionExtraTreasure