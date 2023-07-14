-- 当距离活动结束还剩72小时，玩家有抽奖券，且转盘还有奖励
local XRedPointConditionTurntableTimes = {}
local Events = nil

function XRedPointConditionTurntableTimes.GetSubEvents()
    ---@type XTurntableAgency
    local agency = XMVCA:GetAgency(ModuleId.XTurntable)
    local itemId = agency:GetCostItem()

    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_TURNTABLE_ITEM_UPDATE),
                XRedPointEventElement.New(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. itemId),
            }
    return Events
end

function XRedPointConditionTurntableTimes.Check()
    ---@type XTurntableAgency
    local agency = XMVCA:GetAgency(ModuleId.XTurntable)
    return agency:IsHasTimesInTheRemaining72Hours()
end

return XRedPointConditionTurntableTimes