
--===========================================================================
 ---@desc 接头霸王-有新关卡可解锁
--===========================================================================

local XRedPointBodyCombineGameUnlockedStage = {}


function XRedPointBodyCombineGameUnlockedStage.Check(stageId)
    return XDataCenter.BodyCombineGameManager.CheckUnlockedStage(stageId)
end 

return XRedPointBodyCombineGameUnlockedStage