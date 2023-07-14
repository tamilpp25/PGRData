local XUiPanelAccountSet = require("XUi/XUiSet/XUiPanelAccountSet");
local XUiPanelAccountSetPC = XClass(XUiPanelAccountSet, "XUiPanelAccountSetPC")

function XUiPanelAccountSetPC:AddListener()
    XUiHelper.RegisterClickEvent(self, self.KuroBind, self.OnKuroBind)
    XUiHelper.RegisterClickEvent(self, self.BackLogin, self.OnLogout)
end

function XUiPanelAccountSetPC:OnKuroBind()
    XHgSdkManager.OpenBindWindow()
end

return XUiPanelAccountSetPC