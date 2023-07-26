--2021白色情人节活动偶遇红点
local XRedPointConditionWhite2021Encounter = {}
local Events = nil
function XRedPointConditionWhite2021Encounter.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_WHITEVALENTINE_CHARA_CHANGE),
        XRedPointEventElement.New(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. XDataCenter.WhiteValentineManager.GetGameController():GetCoinItemId())
    }
    return Events
end

function XRedPointConditionWhite2021Encounter.Check()
    local GameController = XDataCenter.WhiteValentineManager.GetGameController()
    return GameController:CheckCanEncounter()
end

return XRedPointConditionWhite2021Encounter