
local XRedPointConditionRegression3All = {}
local SubConditions = nil

function XRedPointConditionRegression3All.GetSubConditions()
    SubConditions = SubConditions or {
        XRedPointConditions.Types.CONDITION_REGRESSION3_SIGN,
        XRedPointConditions.Types.CONDITION_REGRESSION3_PASSPORT,
        XRedPointConditions.Types.CONDITION_REGRESSION3_TASK,
        XRedPointConditions.Types.CONDITION_REGRESSION3_ACTIVITY,
        XRedPointConditions.Types.CONDITION_REGRESSION3_SHOP,
        XRedPointConditions.Types.CONDITION_REGRESSION3_MAIN,
    }
    return SubConditions
end 

function XRedPointConditionRegression3All.Check()
    if XDataCenter.Regression3rdManager.CheckTaskRedPoint() then
        return true
    end

    if XDataCenter.Regression3rdManager.CheckSignRedPoint() then
        return true
    end

    if XDataCenter.Regression3rdManager.CheckPassportRedPoint() then
        return true
    end

    if XDataCenter.Regression3rdManager.CheckNewContentRedPoint() then
        return true
    end

    if XDataCenter.Regression3rdManager.CheckShopRedPoint() then
         return true
    end

    if XDataCenter.Regression3rdManager.CheckMainRedPoint() then
        return true
    end
    
    return false
end

return XRedPointConditionRegression3All

