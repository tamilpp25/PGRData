local XRedPointConditionDiceGameRed = {}
local Events = nil
function XRedPointConditionDiceGameRed.GetSubEvents()
    Events = Events or
            {
                XRedPointEventElement.New(XEventId.EVENT_MAINUI_ENABLE),
                XRedPointEventElement.New(XEventId.EVENT_DICEGAME_CONFIRM),
                XRedPointEventElement.New(XEventId.EVENT_DICEGAME_GET_REWARD),
            }
    return Events
end
function XRedPointConditionDiceGameRed.Check()
    return XDataCenter.DiceGameManager.CheckRedPoint()
end


return XRedPointConditionDiceGameRed