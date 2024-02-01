local XRedPointKotodamaMain = {}
local SubCondition = nil

function XRedPointKotodamaMain.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_KOTODAMA_NEW_SPEECH,
        XRedPointConditions.Types.CONDITION_KOTODAMA_NEW_UNLOCK_STAGE,
        XRedPointConditions.Types.CONDITION_KOTODAMA_REWARD,
    }

    return SubCondition
end


function XRedPointKotodamaMain.Check()
    return XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_KOTODAMA_NEW_SPEECH)
            or XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_KOTODAMA_NEW_UNLOCK_STAGE)
            or XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_KOTODAMA_REWARD)

end

return XRedPointKotodamaMain