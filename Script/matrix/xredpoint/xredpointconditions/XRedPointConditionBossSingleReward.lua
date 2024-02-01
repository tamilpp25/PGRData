----------------------------------------------------------------
-- 单机Boss检查奖励领取
local XRedPointConditionBossSingleReward = {}

function XRedPointConditionBossSingleReward.Check()
    return XMVCA.XFubenBossSingle:CheckRewardRedHint()
end

return XRedPointConditionBossSingleReward