local XRedPointConditionAreaWarCanBuy = {}
local Events = nil

function XRedPointConditionAreaWarCanBuy.GetSubEvents()
    Events =
        Events or
        {
            XRedPointEventElement.New(
                XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.ItemManager.ItemId.AreaWarCoin
            )
        }
    return Events
end

function XRedPointConditionAreaWarCanBuy.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.AreaWar) then
        return false
    end
    if not XDataCenter.AreaWarManager.IsOpen() then
        return false
    end
    return XDataCenter.AreaWarManager.CheckCoinReach()
end

return XRedPointConditionAreaWarCanBuy
