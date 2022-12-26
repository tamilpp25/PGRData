local XRedPointConditionMoeWarPreparationReward = {}
local Events = nil
function XRedPointConditionMoeWarPreparationReward.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_MOE_WAR_PREPARATION_GEAR_REWARD),
    }
    return Events
end

function XRedPointConditionMoeWarPreparationReward.Check()
    local preparationActivityId = XMoeWarConfig.GetPreparationActivityIdInTime()
    if not preparationActivityId then
        return false
    end
    
    local gears = XMoeWarConfig.GetPreparationActivityPreparationGears(preparationActivityId)
    local haveCount = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.MoeWarPreparationItemId)
    local needCount
    local isCanReceive
    local isGetReward
    for i, gearId in ipairs(gears) do
        needCount = XMoeWarConfig.GetPreparationGearNeedCount(gearId)
        isCanReceive = haveCount >= needCount
        isGetReward = XDataCenter.MoeWarManager.IsPreparationGetRewardGears(gearId)
        if not isGetReward and isCanReceive then
            return true
        end
    end
    return false
end

return XRedPointConditionMoeWarPreparationReward