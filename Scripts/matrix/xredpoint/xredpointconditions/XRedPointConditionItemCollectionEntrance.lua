
local XRedPointConditionItemCollectionEntrance = {}
local SubEvents

function XRedPointConditionItemCollectionEntrance:GetSubEvents()
    SubEvents = SubEvents or {
        XRedPointEventElement.New(XEventId.EVENT_ITEM_COLLECT_STATE_CHANGE)
    }
    
    return SubEvents
end

function XRedPointConditionItemCollectionEntrance.Check()
    return XDataCenter.ItemManager.CheckHasNewColletId()
end 

return XRedPointConditionItemCollectionEntrance