local XRedPointConditionNewCharIsChallengeable = {}

function XRedPointConditionNewCharIsChallengeable.Check()
    local config = XActivityBriefConfigs.GetActivityGroupConfig(XActivityBriefConfigs.ActivityGroupId.NewCharActivity)
    local skipList = XFunctionConfig.GetSkipList(config.SkipId)
    local actId = skipList.CustomParams[1]
    return XDataCenter.FubenNewCharActivityManager.IsChallengeable(actId)
end

return XRedPointConditionNewCharIsChallengeable