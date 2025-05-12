local XRedPointConditionRiftAttribute = {}
local Events = nil

function XRedPointConditionRiftAttribute.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX),
    }
    return Events
end

function XRedPointConditionRiftAttribute.Check()
    local isUnlock = XMVCA.XRift:IsFuncUnlock(XEnumConst.Rift.FuncUnlockId.Attribute)
    if not isUnlock then
        return false
    end
    
    return XMVCA.XRift:IsBuyAttrRed()
end

return XRedPointConditionRiftAttribute