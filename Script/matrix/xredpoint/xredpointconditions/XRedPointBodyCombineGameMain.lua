--===========================================================================
 ---@desc 接头霸王游戏总红点检查
--===========================================================================

local XRedPointBodyCombineGameMain = {}
local SubCondition = nil

function XRedPointBodyCombineGameMain.GetSubConditions()
    SubCondition = SubCondition or {
        XRedPointConditions.Types.CONDITION_BODYCOMBINEGAME_REWARD,
        XRedPointConditions.Types.CONDITION_BODYCOMBINEGAME_UNFINISHALL,
        XRedPointConditions.Types.CONDITION_BODYCOMBINEGAME_UNLOCKED_STAGE,
    }
    
    return SubCondition
end 


function XRedPointBodyCombineGameMain.Check()
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_BODYCOMBINEGAME_REWARD) then
        return true
    end

    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_BODYCOMBINEGAME_UNFINISHALL) then
        return true
    end

    local stageIds = XDataCenter.BodyCombineGameManager.GetCurActivityStageIds()
    for _, stageId in ipairs(stageIds) do
        if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_BODYCOMBINEGAME_UNLOCKED_STAGE, stageId) then
            return true
        end
    end

    return false
end 

return XRedPointBodyCombineGameMain