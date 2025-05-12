local XRedPointConditionSCIsChallenge = {}

function XRedPointConditionSCIsChallenge.Check()
    local sameColorGameManager = XDataCenter.SameColorActivityManager
    if not sameColorGameManager.GetIsOpen() then
        return false
    end
    if sameColorGameManager.IsShowChallengable() then
        return true
    end
    return false
end

return XRedPointConditionSCIsChallenge