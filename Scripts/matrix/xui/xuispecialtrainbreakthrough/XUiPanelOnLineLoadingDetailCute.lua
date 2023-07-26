local XUiPanelOnLineLoadingDetail = require("XUi/XUiOnlineLoading/XUiPanelOnLineLoadingDetail")

---@class XUiPanelOnLineLoadingDetailCute
local XUiPanelOnLineLoadingDetailCute = XClass(XUiPanelOnLineLoadingDetail, "UiPanelOnLineLoadingDetailCute")

function XUiPanelOnLineLoadingDetail:CreateDetailItem(...)
    return require("XUi/XUiSpecialTrainBreakthrough/XUiPanelOnLineLoadingDetailItemCute").New(...)
end

return XUiPanelOnLineLoadingDetailCute