local XRedPointConditionStrongholdMineralLeft = {}

function XRedPointConditionStrongholdMineralLeft.Check()
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.Stronghold) then
        return false
    end

    return XDataCenter.StrongholdManager.HasMineralLeft()
end

return XRedPointConditionStrongholdMineralLeft