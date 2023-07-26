local XRedPointTransfinite = {}

function XRedPointTransfinite.Check()
    if XDataCenter.TransfiniteManager.IsRewardCanReceive() then
        return true
    end
    return false
end

return XRedPointTransfinite