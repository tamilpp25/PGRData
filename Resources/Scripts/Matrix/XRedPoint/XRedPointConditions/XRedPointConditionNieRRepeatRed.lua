local tableInsert = table.insert
local XRedPointConditionNieRRepeatRed = {}
local Events = nil

function XRedPointConditionNieRRepeatRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_NIER_STAGE_REWARD),
        XRedPointEventElement.New(XEventId.EVENT_NIER_CHARACTER_UPDATE),
        XRedPointEventElement.New(XEventId.EVENT_NIER_REPEAT_CLICK),
        XRedPointEventElement.New(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA),
    }
    local nierConfigs = XNieRConfigs.GetAllActivityConfig()
    for _, cfg in pairs(nierConfigs) do
        local nierRepeatConsumId = cfg.RepeatableConsumeId
        if nierRepeatConsumId and nierRepeatConsumId ~= 0 then
            tableInsert(Events, XRedPointEventElement.New(XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. nierRepeatConsumId))
        end
    end
    

    return Events
end

function XRedPointConditionNieRRepeatRed.Check()
    local red = XDataCenter.NieRManager.CheckRepeatRed()
    return red
end

return XRedPointConditionNieRRepeatRed