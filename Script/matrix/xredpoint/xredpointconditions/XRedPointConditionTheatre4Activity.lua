local XRedPointConditionTheatre4Activity = {}

function XRedPointConditionTheatre4Activity.Check()
    return XMVCA.XTheatre4:CheckAllBattlePassRedDot()
end

return XRedPointConditionTheatre4Activity
