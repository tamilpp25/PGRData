local XGDFBaseEvent = require("XEntity/XGuildDorm/Furniture/Events/XGDFBaseEvent")
---@class XGDFTestEvent : XGDFBaseEvent
local XGDFTestEvent = XClass(XGDFBaseEvent, "XGDFTestEvent")
function XGDFTestEvent:Init()
    self:StartEntryBtnListener()
end

function XGDFTestEvent:CheckOnce()
    self:Trigger(XTime.GetServerNowTimestamp() % 2 == 0)
end

function XGDFTestEvent:StartEntryBtnListener()
    self.EntryBtnTimeId = XScheduleManager.ScheduleForever(
        function()
            self:CheckOnce()
        end,5000
    )
end

function XGDFTestEvent:Dispose()
    XScheduleManager.UnSchedule(self.EntryBtnTimeId)
end

return XGDFTestEvent