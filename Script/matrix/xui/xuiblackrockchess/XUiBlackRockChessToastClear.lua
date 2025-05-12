---@class XUiBlackRockChessToastClear : XLuaUi
---@field _Control XBlackRockChessControl
local XUiBlackRockChessToastClear = XLuaUiManager.Register(XLuaUi, "UiBlackRockChessToastClear")

function XUiBlackRockChessToastClear:OnStart(title)
    local time = tonumber(self._Control:GetClientConfig("ToastShowTime"))
    local timerId = XScheduleManager.ScheduleOnce(handler(self, self.Close), time)
    self:_AddTimerId(timerId)
end

return XUiBlackRockChessToastClear