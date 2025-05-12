
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
    XMVCA.XRestaurant:Burying(XMVCA.XRestaurant.BuryingButton.BtnStatistics, "UiRestaurantMain")
    self._Control:OpenMenu()
end

function XUiGrid3DHandBook:RefreshRedPoint()
    self.BtnClick:ShowReddot(self._Control:CheckMenuRedPoint())
end

return XUiGrid3DHandBook