local XUiShopItem = require("XUi/XUiShop/XUiShopItem")
local XUiDlcShopTip = XLuaUiManager.Register(XUiShopItem, "UiDlcShopTip")

function XUiDlcShopTip:OnStart(parent, data, cb, shopCanBuyColor, proxy)
    shopCanBuyColor = "FFFFFFFF"
    XUiDlcShopTip.Super.OnStart(self, parent, data, cb, shopCanBuyColor, proxy)
end

return XUiDlcShopTip