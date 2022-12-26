local ChildPanel = require("XUi/XUiSuperTower/Common/XUiSTChildPanel")
--=======================
--超级爬塔商店按钮面板
--=======================
local XUiSTBagShopBtnPanel = XClass(ChildPanel, "XUiSTBagShopBtnPanel")

function XUiSTBagShopBtnPanel:InitPanel()
    self:InitButton()
end

function XUiSTBagShopBtnPanel:InitButton()
    local script = require("XUi/XUiSuperTower/Bag/XUiSTBagButton")
    self.Button = script.New(self.BtnShop, function() self:OnClick() end, XDataCenter.SuperTowerManager.FunctionName.Shop)
end

function XUiSTBagShopBtnPanel:OnClick()
    XLuaUiManager.Open("UiSuperTowerShop")
end

return XUiSTBagShopBtnPanel