---@class XUiFpsGameAboutUs : XLuaUi 关于我们
---@field _Control XFpsGameControl
local XUiFpsGameAboutUs = XLuaUiManager.Register(XLuaUi, "UiFpsGameAboutUs")

function XUiFpsGameAboutUs:OnStart()
    XUiHelper.NewPanelTopControl(self, self.TopControlVariable)
end

return XUiFpsGameAboutUs