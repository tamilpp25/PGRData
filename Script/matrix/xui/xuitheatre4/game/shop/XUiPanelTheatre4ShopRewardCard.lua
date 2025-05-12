local XUiGridTheatre4Prop = require("XUi/XUiTheatre4/Common/XUiGridTheatre4Prop")
---@class XUiPanelTheatre4ShopRewardCard : XUiNode
---@field private _Control XTheatre4Control
---@field Parent XUiTheatre4Shop
---@field BtnYes XUiComponent.XUiButton
---@field TxtDescribe XUiComponent.XUiRichTextCustomRender
local XUiPanelTheatre4ShopRewardCard = XClass(XUiNode, "XUiPanelTheatre4ShopRewardCard")

function XUiPanelTheatre4ShopRewardCard:OnStart()
    self._Control:RegisterClickEvent(self, self.BtnYes, self.OnBtnYesClick)
    self.ImgSelect.gameObject:SetActiveEx(false)
    self.PanelDifficulty.gameObject:SetActiveEx(false)
    self.ImgBox.gameObject:SetActiveEx(false)
    self.BtnYes.gameObject:SetActiveEx(false)
end

---@param shopGoodsData XTheatre4ShopGoods
function XUiPanelTheatre4ShopRewardCard:Update(shopGoodsData, index)
    self.ShopGoodsData = shopGoodsData
    self.ConfigId = shopGoodsData:GetGoodsId()
    self.Index = index
    self.GoodsType = self._Control:GetGoodsType(self.ConfigId)
    self.GoodsId = self._Control:GetGoodsId(self.ConfigId)
    self.GoodsNum = self._Control:GetGoodsNum(self.ConfigId)
    self:RefreshGoodsInfo()
    self:RefreshBtn()
end

-- 获取商品的价格
function XUiPanelTheatre4ShopRewardCard:GetGoodsPrice()
    -- 免费
    if self.ShopGoodsData:GetIsFree() then
        return 0
    end
    local goodsPrice = self._Control:GetGoodsPrice(self.ConfigId) -- 原价
    return self.Parent:GetDiscountPrice(goodsPrice)
end

-- 商品是否已售完 库存为0
function XUiPanelTheatre4ShopRewardCard:IsSoldOut()
    local stock = self.ShopGoodsData:GetStock()
    return stock <= 0
end

-- 刷新商品信息
function XUiPanelTheatre4ShopRewardCard:RefreshGoodsInfo()
    -- 图片
    if not self.PanelGridProp then
        ---@type XUiGridTheatre4Prop
        self.PanelGridProp = XUiGridTheatre4Prop.New(self.GridProp, self)
    end
    self.PanelGridProp:Open()
    self.PanelGridProp:Refresh({ Id = self.GoodsId, Type = self.GoodsType, Count = self.GoodsNum })
    -- 名称
    self.TxtTitle.text = self._Control.AssetSubControl:GetAssetName(self.GoodsType, self.GoodsId)
    -- 描述
    self.TxtDescribe.requestImage = function(key, img)
        if key == "Img1" then
            local descIcon = self._Control:GetItemDescIcon(self.GoodsId)
            if descIcon then
                img:SetSprite(descIcon)
            end
        end
    end
    ---@type XUiComponent.XUiRichTextCustomRender
    self.TxtDescribe.text = self._Control.AssetSubControl:GetAssetDesc(self.GoodsType, self.GoodsId)
    self.TxtDescribe:ForcePopulateIcons()
end

-- 刷新按钮
function XUiPanelTheatre4ShopRewardCard:RefreshBtn()
    -- 价格
    local goodsPrice = self:GetGoodsPrice()
    -- 检查是否有足够的金币
    local isEnough = self._Control.AssetSubControl:CheckAssetEnough(XEnumConst.Theatre4.AssetType.Gold, nil, goodsPrice, true)
    self.BtnYes:SetDisable(not isEnough or self:IsSoldOut())
end

function XUiPanelTheatre4ShopRewardCard:OnBtnYesClick()
    if self:IsSoldOut() then
        self._Control:ShowRightTipPopup(XUiHelper.GetText("Theatre4ShopStockNotEnough"))
        return
    end
    -- 价格
    local goodsPrice = self:GetGoodsPrice()
    -- 检查是否有足够的金币
    if not self._Control.AssetSubControl:CheckAssetEnough(XEnumConst.Theatre4.AssetType.Gold, nil, goodsPrice) then
        return
    end
    -- 商品是藏品箱和藏品时需要检查藏品是否已达上限
    if self.GoodsType == XEnumConst.Theatre4.AssetType.Item or self.GoodsType == XEnumConst.Theatre4.AssetType.ItemBox then
        if self.GoodsType == XEnumConst.Theatre4.AssetType.Item then
            local itemCount = self._Control.AssetSubControl:GetAssetCount(self.GoodsType, self.GoodsId) or 0
            local countLimit = self._Control:GetItemCountLimit(self.GoodsId) or 0

            if itemCount >= countLimit then
                self._Control:ShowRightTipPopup(self._Control:GetClientConfig("ItemRepeatLimitTips"))
                return
            end
        end
        if self._Control:CheckItemMaxLimit() then
            local title = XUiHelper.GetText("Theatre4PopupCommonTitle")
            local content = XUiHelper.GetText("Theatre4ShopBuyLimitContent")
            self._Control:ShowCommonPopup(title, content, function()
                -- 购买商品
                self.Parent:BuyGoods(self.Index)
            end)
            return
        end
    end
    -- 购买商品
    self.Parent:BuyGoods(self.Index)
end

return XUiPanelTheatre4ShopRewardCard
