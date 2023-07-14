-- 翻牌小游戏入口红点
local XRedPointConditionInvertCardGameRed = {}
local SubCondition = nil
function XRedPointConditionInvertCardGameRed.GetSubConditions()
    SubCondition =  SubCondition or
    {
        XRedPointConditions.Types.CONDITION_INVERTCARDGAME_TOG,
    }
    return SubCondition
end

function XRedPointConditionInvertCardGameRed.Check()
    return XDataCenter.InvertCardGameManager.CheckAllGameRedPoint()
end

return XRedPointConditionInvertCardGameRed