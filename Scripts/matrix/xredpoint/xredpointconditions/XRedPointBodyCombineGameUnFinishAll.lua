--===========================================================================
 ---@desc 接头霸王-未完成所有关卡红点检测
--===========================================================================


local XRedPointBodyCombineGameUnFinishAll = {}

function XRedPointBodyCombineGameUnFinishAll.Check()
    return XDataCenter.BodyCombineGameManager.CheckIsFinishAll()
end 

return XRedPointBodyCombineGameUnFinishAll