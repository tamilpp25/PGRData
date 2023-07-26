----------------------------------------------------------------
local XRedPointConditionActivitySClassGot = {}

function XRedPointConditionActivitySClassGot.Check()
    local signId = 53
    return XDataCenter.SignInManager.IsShowSignIn(signId, true)
end

return XRedPointConditionActivitySClassGot