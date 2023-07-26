local XRedPointConditionMaverick2 = {}

function XRedPointConditionMaverick2.Check()
    if not XDataCenter.Maverick2Manager.IsOpen() then
        return false
    end
    
    if XDataCenter.Maverick2Manager.CheckTaskCanReward() then
        return true
    end

    if XDataCenter.Maverick2Manager.IsShowShopRed() then
        return true
    end
    
    return false
end

return XRedPointConditionMaverick2