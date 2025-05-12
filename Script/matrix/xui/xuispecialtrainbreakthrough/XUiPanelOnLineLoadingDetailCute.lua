local XUiPanelOnLineLoadingDetailItem = require("XUi/XUiOnlineLoading/XUiPanelOnLineLoadingDetailItem")
local XUiPanelOnLineLoadingDetail = require("XUi/XUiOnlineLoading/XUiPanelOnLineLoadingDetail")

---@class XUiPanelOnLineLoadingDetailCute
local XUiPanelOnLineLoadingDetailCute = XClass(XUiPanelOnLineLoadingDetail, "UiPanelOnLineLoadingDetailCute")

function XUiPanelOnLineLoadingDetailCute:CreateDetailItem(...)
    return require("XUi/XUiSpecialTrainBreakthrough/XUiPanelOnLineLoadingDetailItemCute").New(...)
end

return XUiPanelOnLineLoadingDetailCute