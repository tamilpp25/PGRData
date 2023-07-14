----------------------------------------------------------------
-- 月卡奖励领取
local XRedPointConditionGetCard = {}
local Events = nil
function XRedPointConditionGetCard.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_YK_UPDATE),
    }
    return Events
end

function XRedPointConditionGetCard.Check()
    local cardList = XSignInConfigs.GetSignCardConfigs()
    local isCanGotCard = false
    for _,v in pairs(cardList) do
        local uiType = v.Param[1]
        local id = v.Param[2]
        if uiType and id then
            isCanGotCard = not XDataCenter.PayManager.IsGotCard(uiType, id)
        end
        if isCanGotCard then
            return isCanGotCard
        end
    end
    return isCanGotCard
end

return XRedPointConditionGetCard