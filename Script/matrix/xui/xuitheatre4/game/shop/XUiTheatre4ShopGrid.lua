---@class XUiTheatre4ShopGrid : XUiNode
---@field _Control XTheatre4Control
---@field Parent XUiTheatre4Shop
local XUiTheatre4ShopGrid = XClass(XUiNode, "XUiTheatre4ShopGrid")

function XUiTheatre4ShopGrid:OnStart()
    self.ImgQuality = {
        [XEnumConst.Theatre4.ItemQuality.White] = self.ImgQualityWhite,
        [XEnumConst.Theatre4.ItemQuality.Green] = self.ImgQualityGreen,
        [XEnumConst.Theatre4.ItemQuality.Blue] = self.ImgQualityBlue,
        [XEnumConst.Theatre4.ItemQuality.Purple] = self.ImgQualityPurple,
        [XEnumConst.Theatre4.ItemQuality.Yellow] = self.ImgQualityYellow,
        [XEnumConst.Theatre4.ItemQuality.Gold] = self.ImgQualityGold,
        [XEnumConst.Theatre4.ItemQuality.Red] = self.ImgQualityRed,
    }
    self.Lock.gameObject:SetActiveEx(false)
    self.ImgHave.gameObject:SetActiveEx(false)
    self.ImgAdd.gameObject:SetActiveEx(false)
    self.ItemGrid.gameObject:SetActiveEx(false)
    self.ImgDiscount.gameObject:SetActiveEx(false)
    self.PanelCount.gameObject:SetActiveEx(false)
end

---@param shopGoodsData XTheatre4ShopGoods
function XUiTheatre4ShopGrid:Refresh(shopGoodsData)
    self.ShopGoodsData = shopGoodsData
    self.ConfigId = shopGoodsData:GetGoodsId()
    self.GoodsType = self._Control:GetGoodsType(self.ConfigId)
    self.GoodsId = self._Control:GetGoodsId(self.ConfigId)
    self.GoodsNum = self._Control:GetGoodsNum(self.ConfigId)
    self:RefreshPrice()
    self:RefreshGoodsInfo()
    self:RefreshDiscount()
end

-- 获取商品的价格
function XUiTheatre4ShopGrid:GetGoodsPrice()
    -- 免费
    if self.ShopGoodsData:GetIsFree() then
        return 0
    end
    local goodsPrice = self._Control:GetGoodsPrice(self.ConfigId) -- 原价
    return self.Parent:GetDiscountPrice(goodsPrice)
end

-- 商品是否已售完 库存为0
function XUiTheatre4ShopGrid:IsSoldOut()
    local stock = self.ShopGoodsData:GetStock()
    return stock <= 0
end

-- 刷新价格
function XUiTheatre4ShopGrid:RefreshPrice()
    local goldIcon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold)
    if goldIcon then
        self.RImgCostIcon:SetRawImage(goldIcon)
    end
    -- 价格
    local goodsPrice = self:GetGoodsPrice()
    self.TxtCostCount.text = string.format("X%d", goodsPrice)
    -- 金币是否满足
    local isEnough = self._Control.AssetSubControl:CheckAssetEnough(XEnumConst.Theatre4.AssetType.Gold, nil, goodsPrice, true)
    -- 刷新消耗文本颜色
    local index = isEnough and 1 or 2
    local color = self._Control:GetClientConfig("ShopItemCostColor", index)
    if not string.IsNilOrEmpty(color) then
        self.TxtCostCount.color = XUiHelper.Hexcolor2Color(color)
    end
end

-- 刷新商品信息
function XUiTheatre4ShopGrid:RefreshGoodsInfo()
    self.ItemGrid.gameObject:SetActiveEx(true)
    -- 图片
    local icon = self._Control.AssetSubControl:GetAssetIcon(self.GoodsType, self.GoodsId)
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
    -- 品质图标
    self:RefreshQuality()
    -- 名称
    self.TxtName.text = self._Control.AssetSubControl:GetAssetName(self.GoodsType, self.GoodsId)
    -- 已售完
    self.ImgHave.gameObject:SetActiveEx(self:IsSoldOut())
    if XTool.IsNumberValid(self.GoodsNum) then
        self.PanelTxt.gameObject:SetActiveEx(true)
        self.TxtCount.text = self.GoodsNum
    else
        self.PanelTxt.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre4ShopGrid:RefreshQuality()
    local quality = self._Control.AssetSubControl:GetAssetQuality(self.GoodsType, self.GoodsId)

    for k, v in pairs(self.ImgQuality) do
        v.gameObject:SetActiveEx(k == quality)
    end
end

-- 刷新折扣
function XUiTheatre4ShopGrid:RefreshDiscount()
    local discount = self.Parent.GridData:GetGridShopDiscount()
    self.ImgDiscount.gameObject:SetActiveEx(discount ~= 1)
    if discount ~= 1 then
        self.TxtDiscount.text = XUiHelper.GetText("Theatre4BuyAssetDiscountText", discount * 10)
    end
end

-- 设置选择
function XUiTheatre4ShopGrid:SetSelect(isSelect)
    if self.Select then
        self.Select.gameObject:SetActiveEx(isSelect)
    end
end

return XUiTheatre4ShopGrid
