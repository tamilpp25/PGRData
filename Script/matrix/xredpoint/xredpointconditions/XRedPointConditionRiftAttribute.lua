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
    local isUnlock = XDataCenter.RiftManager.IsFuncUnlock(XRiftConfig.FuncUnlockId.Attribute)
    if not isUnlock then
        return false
    end
    
    return XDataCenter.RiftManager.IsBuyAttrRed()
end

return XRedPointConditionRiftAttribute