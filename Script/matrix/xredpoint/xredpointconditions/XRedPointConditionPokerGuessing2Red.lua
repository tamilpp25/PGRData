local XRedPointConditionPokerGuessing2Red = {}

function XRedPointConditionPokerGuessing2Red.GetSubEvents()
end

function XRedPointConditionPokerGuessing2Red.Check()
    return XMVCA.XPokerGuessing2:IsShowRedDot()
end

return XRedPointConditionPokerGuessing2Red