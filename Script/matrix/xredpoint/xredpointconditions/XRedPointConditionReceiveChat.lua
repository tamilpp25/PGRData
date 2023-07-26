----------------------------------------------------------------
local XRedPointConditionReceiveChat = {}
local Events = nil

function XRedPointConditionReceiveChat.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_CHAT_RECEIVE_WORLD_MSG),
        XRedPointEventElement.New(XEventId.EVENT_GUILD_RECEIVE_CHAT),
        XRedPointEventElement.New(XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG),
        XRedPointEventElement.New(XEventId.EVENT_CHAT_RECEIVE_MENTOR_MSG),
    }
    return Events
end

function XRedPointConditionReceiveChat.Check()
    return true
end

return XRedPointConditionReceiveChat