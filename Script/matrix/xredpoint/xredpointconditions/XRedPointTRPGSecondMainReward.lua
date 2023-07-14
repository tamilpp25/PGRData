
----------------------------------------------------------------
--主线跑团常规主线红点检测
local XRedPointTRPGSecondMainReward = {}

function XRedPointTRPGSecondMainReward.Check()
    return XDataCenter.TRPGManager.IsSecondMainReward()
end

return XRedPointTRPGSecondMainReward