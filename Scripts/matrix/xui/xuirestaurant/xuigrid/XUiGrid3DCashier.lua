
local XUiGrid3DBase = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DBase")

---@class XUiGrid3DCashier : XUiGrid3DBase
---@field BtnCashier XUiComponent.XUiButton
---@field RImgIcon UnityEngine.UI.RawImage
local XUiGrid3DCashier = XClass(XUiGrid3DBase, "XUiGrid3DCashier")

function XUiGrid3DCashier:InitUi()
    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XRestaurantConfigs.ItemId.RestaurantUpgradeCoin))
end

function XUiGrid3DCashier:InitCb()
    self.BtnCashier.CallBack = function() 
        self:OnBtnCashierClick()
    end
end

function XUiGrid3DCashier:OnRefresh(count)
    self.TxtCount.text = count
    self.BtnCashier:ShowReddot(XDataCenter.RestaurantManager.CheckCashierLimitRedPoint())
end

function XUiGrid3DCashier:OnBtnCashierClick()
    XLuaUiManager.Open("UiRestaurantCashierDesk")
end

return XUiGrid3DCashier