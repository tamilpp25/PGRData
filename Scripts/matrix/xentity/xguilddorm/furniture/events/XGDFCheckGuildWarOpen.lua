local XGDFBaseEvent = require("XEntity/XGuildDorm/Furniture/Events/XGDFBaseEvent")
---@class XGDFCheckGuildWarOpen : XGDFBaseEvent
local XGDFCheckGuildWarOpen = XClass(XGDFBaseEvent, "XGDFCheckGuildWarOpen")

function XGDFCheckGuildWarOpen:Init()
    self:StartEntryBtnListener()
end

function XGDFCheckGuildWarOpen:CheckOnce()
    self:Trigger(XDataCenter.GuildWarManager.CheckRoundIsInTime())
end

function XGDFCheckGuildWarOpen:StartEntryBtnListener()
    if self.EntryBtnTimeId then return end
    self.EntryBtnTimeId = XScheduleManager.ScheduleForever(
        function()
            CheckOnce()
        end,1000
    )
end

function XGDFCheckGuildWarOpen:Dispose()
    if not self.EntryBtnTimeId then return end
    XScheduleManager.UnSchedule(self.EntryBtnTimeId)
    self.EntryBtnTimeId = nil
end

return XGDFCheckGuildWarOpen