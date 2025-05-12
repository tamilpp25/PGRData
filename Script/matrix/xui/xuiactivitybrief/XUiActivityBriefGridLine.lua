local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
local XUiActivityBriefGridLine = XClass(nil, "XUiActivityBriefGridLine")
function XUiActivityBriefGridLine:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiActivityBriefGridLine:Init(parent, shopItemTextColor)
    self.Parent = parent
    self.ShopItemTextColor = shopItemTextColor
    self.XUiGridShop1 = XUiGridShop.New(self.GridShop1)
    self.XUiGridShop1:Init(parent)
    self.XUiGridShop2 = XUiGridShop.New(self.GridShop2)
    self.XUiGridShop2:Init(parent)
end

function XUiActivityBriefGridLine:Refresh(lineGoods)
    self.XUiGridShop1.GameObject:SetActiveEx(false)
    self.XUiGridShop2.GameObject:SetActiveEx(false)

    for i, good in ipairs(lineGoods) do
        local xUiGridShop = self["XUiGridShop" .. i]
        self.Parent:SetShopItemLock(xUiGridShop)
        self.Parent:SetShopItemBg(xUiGridShop)
        xUiGridShop:UpdateData(good, self.ShopItemTextColor)
        xUiGridShop:RefreshOnSaleTime(good.OnSaleTime)
        xUiGridShop.GameObject:SetActiveEx(true)
    end
end

function XUiActivityBriefGridLine:OnRecycle()
    self.XUiGridShop1:OnRecycle()
    self.XUiGridShop2:OnRecycle()
end

return XUiActivityBriefGridLine
