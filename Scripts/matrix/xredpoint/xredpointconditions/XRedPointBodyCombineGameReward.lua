
--===========================================================================
 ---@desc 接头霸王任务奖励红点检测
--===========================================================================
local XRedPointBodyCombineGameReward = {}


function XRedPointBodyCombineGameReward.Check()
    return XDataCenter.BodyCombineGameManager.CheckRewardRedPoint()
end 

return XRedPointBodyCombineGameReward