local XRedPointConditionMoeWarDrawRed = {}
local Events = nil
local itemId = CS.XGame.ClientConfig:GetInt("MoeWarGachaItem")
local showCount = CS.XGame.ClientConfig:GetInt("MoeWarGachaItemNum")
function XRedPointConditionMoeWarDrawRed.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX..itemId),
            }
    return Events
end

function XRedPointConditionMoeWarDrawRed.Check()
    local itemCount = XDataCenter.ItemManager.GetCount(itemId)
    return itemCount >= showCount
end

return XRedPointConditionMoeWarDrawRed