---@class XUiTheatre4TipsCommon : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4TipsCommon = XLuaUiManager.Register(XLuaUi, "UiTheatre4TipsCommon")
local TIP_MSG_SHOW_TIME = 2000

function XUiTheatre4TipsCommon:Refresh(content)
    self.TxtDes.text = XUiHelper.ConvertLineBreakSymbol(content)
    self:PlayAnimation("AnimShow")
    self:StopTimer()
    self.Timer = XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:Close()
    end, TIP_MSG_SHOW_TIME)
end

function XUiTheatre4TipsCommon:OnDisable()
    self:StopTimer()
end

function XUiTheatre4TipsCommon:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiTheatre4TipsCommon
