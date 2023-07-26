
local XUiGrid3DBase = require("XUi/XUiRestaurant/XUiGrid/XUiGrid3DBase")

---@class XUiGrid3DHandBook : XUiGrid3DBase
local XUiGrid3DHandBook = XClass(XUiGrid3DBase, "XUiGrid3DHandBook")

function XUiGrid3DHandBook:InitUi()
    self.BtnClick = self.Transform:GetComponent("XUiButton")
end

function XUiGrid3DHandBook:InitCb()
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
end

function XUiGrid3DHandBook:OnBtnClick()
    XRestaurantConfigs.Burying(XRestaurantConfigs.BuryingButton.BtnStatistics, "UiRestaurantMain")
    XDataCenter.RestaurantManager.OpenMenu()
end

function XUiGrid3DHandBook:RefreshRedPoint()
    self.BtnClick:ShowReddot(XDataCenter.RestaurantManager.CheckMenuRedPoint())
end

return XUiGrid3DHandBook