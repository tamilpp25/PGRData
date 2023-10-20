----------------------------------------------------------------
local XRedPointConditionDormRed = {}
local SubCondition = nil
function XRedPointConditionDormRed.GetSubConditions()
    SubCondition =
        SubCondition or
        {
            XRedPointConditions.Types.CONDITION_DORM_TASK,
            XRedPointConditions.Types.CONDITION_DORM_WORK_RED,
            XRedPointConditions.Types.CONDITION_FURNITURE_CREATE,
            XRedPointConditions.Types.CONDITION_DORM_QUEST_TERMINAL,
        }
    return SubCondition
end


function XRedPointConditionDormRed.Check()
    local red = XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_DORM_WORK_RED)
    if red then
        return true
    end

    red = XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_FURNITURE_CREATE)
    if red then
        return true
    end
    red = XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_DORM_TASK, XDataCenter.TaskManager.TaskType.DormNormal)
        or XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_DORM_TASK, XDataCenter.TaskManager.TaskType.DormDaily)
    if red then
        return true
    end
    red = XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_DORM_QUEST_TERMINAL)
    if red then
        return true
    end
    return false
end

return XRedPointConditionDormRed
