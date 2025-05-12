local XRedPointConditionNewActivityCalendarRed = {}
local Evnets = nil

function XRedPointConditionNewActivityCalendarRed.GetSubEvents()
    Evnets = Evnets or {
        XRedPointEventElement.New(XEventId.EVENT_NEW_ACTIVITY_CALENDAR_UPDATE),
    }
    return Evnets
end

function XRedPointConditionNewActivityCalendarRed.Check()
    ---@type XNewActivityCalendarAgency
    local calendarAgency = XMVCA:GetAgency(ModuleId.XNewActivityCalendar)
    if not calendarAgency:GetIsOpen(true) then
        return false
    end
    if calendarAgency:CheckActivityCalendarRadPoint() then
        return true
    end
    return false
end

return XRedPointConditionNewActivityCalendarRed