---@field _Control XArrangementGameControl
---@class XUiArrangementGamePopupStart : XLuaUi
local XUiArrangementGamePopupStart = XLuaUiManager.Register(XLuaUi, "UiArrangementGamePopupStart")

function XUiArrangementGamePopupStart:OnAwake()
    self:InitButton()
end

function XUiArrangementGamePopupStart:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
end

return XUiArrangementGamePopupStart
