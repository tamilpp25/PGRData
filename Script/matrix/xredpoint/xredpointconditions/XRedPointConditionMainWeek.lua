local XRedPointConditionMainWeek = {}

function XRedPointConditionMainWeek.Check()
    local isShowRedPoint = XDataCenter.ActivityCalendarManager.CheckNewActivityUnlock() or
            XDataCenter.ActivityCalendarManager.CheckActivityReadyEnd()

    if isShowRedPoint and XDataCenter.ActivityCalendarManager.CheckWeekIsClick() then
        return false
    end

    return isShowRedPoint
end

return XRedPointConditionMainWeek