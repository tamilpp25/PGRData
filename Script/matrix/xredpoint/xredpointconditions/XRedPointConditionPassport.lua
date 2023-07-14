
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

    --满级时入口不检查任务的红点
    local baseInfo = XDataCenter.PassportManager.GetPassportBaseInfo()
    local level = baseInfo:GetLevel()
    local maxLevel = XPassportConfigs.GetPassportMaxLevel()
    if level < maxLevel then
        if XRedPointConditionPassportTaskDaily.Check() then
            return true
        end

        if XRedPointConditionPassportTaskWeekly.Check() then
            return true
        end

        if XRedPointConditionPassportTaskActivity.Check() then
            return true
        end
    end

    return false
end

return XRedPointConditionPassport