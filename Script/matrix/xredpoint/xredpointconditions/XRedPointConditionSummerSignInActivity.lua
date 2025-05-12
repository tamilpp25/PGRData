local XRedPointConditionSummerSignInActivity = {}
local Evnets = nil

function XRedPointConditionSummerSignInActivity.GetSubEvents()
    Evnets = Evnets or {
        XRedPointEventElement.New(XEventId.EVENT_SUMMER_SIGNIN_UPDATE),
    }
    return Evnets
end

function XRedPointConditionSummerSignInActivity.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.SummerSignIn) then
        return false
    end
    -- 有签到次数
    if not XDataCenter.SummerSignInManager.CheckSurplusTimes() then
        return true
    end
    
    return false
end

return XRedPointConditionSummerSignInActivity