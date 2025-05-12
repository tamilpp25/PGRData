


local XUiGridHud = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHud")
---@class XUiGridDialogHud : XUiGridHud
---@field
local XUiGridDialogHud = XClass(XUiGridHud, "XUiGridDialogHud")

local DURATION = 2 

function XUiGridDialogHud:OnDisable()
    self:StopTimer()
end

function XUiGridDialogHud:BindTarget(target, offset, text)
    XUiGridHud.BindTarget(self, target, offset)
    self.Text = text
end

function XUiGridDialogHud:RefreshView()
    self.TxtDesc.text = self.Text
    self:StartTimer()
end

function XUiGridDialogHud:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self.Timer = XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        
        self:Close()
    end, DURATION * XScheduleManager.SECOND)
end

function XUiGridDialogHud:StopTimer()
    if not self.Timer then
        return
    end
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
end

return XUiGridDialogHud