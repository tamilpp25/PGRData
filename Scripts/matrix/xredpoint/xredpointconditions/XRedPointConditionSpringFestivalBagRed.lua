
local XRedPointConditionSpringFestivalBagRed = {}
local Events = nil

function XRedPointConditionSpringFestivalBagRed.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_SPRING_FESTIVAL_GIFT_BAG_RED),
            }
    return Events
end

function XRedPointConditionSpringFestivalBagRed.Check()
    return XDataCenter.SpringFestivalActivityManager.CheckHasUnReceiveGift()
end

return XRedPointConditionSpringFestivalBagRed