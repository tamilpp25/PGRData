local XRedPointConditionNewYearDiviningNotGet = {}

function XRedPointConditionNewYearDiviningNotGet.Check()
    return XDataCenter.SignInManager.CheckTodayDiviningState()
end

return XRedPointConditionNewYearDiviningNotGet