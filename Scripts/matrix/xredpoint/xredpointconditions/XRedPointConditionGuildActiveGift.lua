
local XRedPointConditionGuildActiveGift = {}
local Events = nil
function XRedPointConditionGuildActiveGift.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_GUILD_GIFT_CONTRIBUTE_CHANGED),
    }
    return Events
end


function XRedPointConditionGuildActiveGift.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Guild) then
        return false
    end
    
    -- 礼包红点
    local giftGuildLevel = XDataCenter.GuildManager.GetGiftGuildLevel()
    local allGifts = XGuildConfig.GetGuildGiftByGuildLevel(giftGuildLevel)

    for _, v in pairs(allGifts or {}) do
        if XDataCenter.GuildManager.CanCollectGift(v.GiftLevel) then
            return true
        end
    end

    return false
end

return XRedPointConditionGuildActiveGift