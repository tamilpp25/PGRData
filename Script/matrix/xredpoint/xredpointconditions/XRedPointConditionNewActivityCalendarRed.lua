local XRedPointConditionNewActivityCalendarRed = {}
local Evnets = nil

function XRedPointConditionNewActivityCalendarRed.GetSubEvents()
    Evnets = Evnets or {
        XRedPointEventElement.New(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE),
    }
    return Evnets
end

function XRedPointConditionNewActivityCalendarRed.Check()
    if not XDataCenter.NewActivityCalendarManager.GetIsOpen(true) then
        return false
    end
    if XDataCenter.NewActivityCalendarManager.CheckActivityCalendarRadPoint() then
        return true
    end
    return false
end

return XRedPointConditionNewActivityCalendarRed