local XUiPanelOnLineLoadingDetail = require("XUi/XUiOnlineLoading/XUiPanelOnLineLoadingDetail")
local XUiOnLineLoading = require("XUi/XUiOnlineLoading/XUiOnLineLoading")

---@class XUiOnLineLoadingCute
local XUiOnLineLoadingCute = XLuaUiManager.Register(XUiOnLineLoading, "UiOnLineLoadingCute")

function XUiOnLineLoadingCute:OnAwake()
    self:InitAutoScript()
    local XUiPanelOnLineLoadingDetailCute = require("XUi/XUiSpecialTrainBreakthrough/XUiPanelOnLineLoadingDetailCute")
    self.XUiPanelOnLineLoadingDetail = XUiPanelOnLineLoadingDetailCute.New(self.PanelOnLineLoadingDetail, self)
end

return XUiOnLineLoadingCute
