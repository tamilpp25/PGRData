
----------------------------------------------------------------
--主线跑团所有区域红点检测
local XRedPointTRPGAreaReward = {}

function XRedPointTRPGAreaReward.Check()
    return XDataCenter.TRPGManager.CheckAllAreaReward()
end

return XRedPointTRPGAreaReward