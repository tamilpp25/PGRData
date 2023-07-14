
local XRedPointConditionPassport = {}
local SubConditions = nil

local Events = nil

function XRedPointConditionPassport.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_AUTO_GET_TASK_REWARD_LIST),
    }
    return Events
end

function XRedPointConditionPassport.GetSubConditions()
    SubConditions = SubConditions or
    {
        XRedPointConditions.Types.CONDITION_PASSPORT_PANEL_REWARD_RED,
        XRedPointConditions.Types.CONDITION_PASSPORT_TASK_DAILY_RED,
        XRedPointConditions.Types.CONDITION_PASSPORT_TASK_WEEKLY_RED,
        XRedPointConditions.Types.CONDITION_PASSPORT_TASK_ACTIVITY_RED,
    }
    return SubConditions
end

function XRedPointConditionPassport.Check()
    if XDataCenter.PassportManager.IsActivityClose() then
        return false
    end

    if XRedPointConditionPassportPanelReward.Check() then
        return true
    end

    if XRedPointConditionPassportTaskDaily.Check() then
        return true
    end

    if XRedPointConditionPassportTaskWeekly.Check() then
        return true
    end

    if XRedPointConditionPassportTaskActivity.Check() then
        return true
    end

    return false
end

return XRedPointConditionPassport