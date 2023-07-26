local XRedPointConditionNewYearLuckRuleRed = {}

function XRedPointConditionNewYearLuckRuleRed.Check()
    return XDataCenter.NewYearLuckManager.IsFirstInActivity()
end

return XRedPointConditionNewYearLuckRuleRed