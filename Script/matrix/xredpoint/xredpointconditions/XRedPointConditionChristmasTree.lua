----------------------------------------------------------------
--圣诞小游戏相关红点
local XRedPointConditionChristmasTree = {}
local SubCondition = nil
function XRedPointConditionChristmasTree.GetSubConditions()
    SubCondition =  SubCondition or
        {
            XRedPointConditions.Types.CONDITION_CHRISTMAS_TREE_ORNAMENT_READ,
            XRedPointConditions.Types.CONDITION_CHRISTMAS_TREE_ORNAMENT_ACTIVE,
            XRedPointConditions.Types.CONDITION_CHRISTMAS_TREE_AWARD,
        }
    return SubCondition
end

function XRedPointConditionChristmasTree.Check()
    if XRedPointConditionChristmasTreeOrnamentActive.Check() then
        return true
    end

    if XRedPointConditionChristmasTreeAward.Check() then
        return true
    end
    
    if XRedPointConditionChristmasTreeOrnamentRead.Check() then
        return true
    end
    
    return false
end

return XRedPointConditionChristmasTree