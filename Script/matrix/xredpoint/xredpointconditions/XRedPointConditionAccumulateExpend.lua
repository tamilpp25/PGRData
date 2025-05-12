local XRedPointConditionAccumulateExpend = {}

function XRedPointConditionAccumulateExpend.Check()
    local result = 0
    
    if XMVCA.XAccumulateExpend:CheckIsFirstOpen() then
        result = result + 1
    end
    if XMVCA.XAccumulateExpend:CheckHasReward() then
        result = result + 1
    end

    return result
end

return XRedPointConditionAccumulateExpend