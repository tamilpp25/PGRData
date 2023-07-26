--肉鸽2.0商店二次确认弹窗
local XUiBiancaTheatreShopTips = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreShopTips")

function XUiBiancaTheatreShopTips:OnAwake()
    self:AutoAddListener()
end

--shopItem：XAShopNode的XAShopItem
function XUiBiancaTheatreShopTips:OnStart(shopItem, sureCb)
    self.SureCb = sureCb
    --商品名
    self.TxtName.text = shopItem:GetName()
    --品质颜色
    local quality = shopItem:GetQuality()
    local color = XBiancaTheatreConfigs.GetQualityTextColor(quality)
    if color then
        self.TxtName.color = color
    end
    --商品描述
    self.TxtDescription.text = shopItem:GetDesc()
    --商品图标
    self.RImgIcon:SetRawImage(shopItem:GetItemIcon())
    --招募券品质标签
    self.Tag.gameObject:SetActiveEx(shopItem:IsShowTag())
    --价格
    self.ImgCoin:SetRawImage(XEntityHelper.GetItemIcon(XBiancaTheatreConfigs.TheatreInnerCoin))
    self.TextCoin.text = shopItem:GetDiscountPrice()
end

function XUiBiancaTheatreShopTips:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnCancel, self.Close)
    self:RegisterClickEvent(self.BtnSure, self.OnBtnSureClick)
end

function XUiBiancaTheatreShopTips:OnBtnSureClick()
    if self.SureCb then
        self.SureCb()
    end
    self:Close()
end

return XUiBiancaTheatreShopTips
