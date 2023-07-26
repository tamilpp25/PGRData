local XRedPointConditionPokerGuessingRed = {}
local Events = nil

function XRedPointConditionPokerGuessingRed.GetSubEvents()
end

function XRedPointConditionPokerGuessingRed.Check()
    return XDataCenter.PokerGuessingManager.CheckBannerRedPoint()
end

return XRedPointConditionPokerGuessingRed