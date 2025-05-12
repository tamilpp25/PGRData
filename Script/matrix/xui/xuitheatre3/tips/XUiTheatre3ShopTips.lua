---@class XUiTheatre3ShopTips : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3ShopTips = XLuaUiManager.Register(XLuaUi, "UiTheatre3ShopTips")

function XUiTheatre3ShopTips:OnAwake()
    self:AddBtnListener()
end

---@param shopItem XTheatre3NodeShopItem
function XUiTheatre3ShopTips:OnStart(isMoneyShop, shopItem, closeCb, sureCb)
    self.CloseCb = closeCb
    self.SureCb = sureCb
    self.TemplateId = shopItem:GetEventStepTemplateId()
    self.Type = shopItem:GetEventStepType()
    if not XTool.IsNumberValid(self.TemplateId) then
        XLog.Error("XUiTheatre3ShopTips:Refresh错误: 参数templateId不能为空或0")
        return
    end
    
    -- 名称
    self.TxtName.text = self._Control:GetEventStepItemName(self.TemplateId, self.Type)
    -- 图标
    local icon = self._Control:GetEventStepItemIcon(self.TemplateId, self.Type)
    if not string.IsNilOrEmpty(icon) then
        self.RImgIcon:SetRawImage(icon)
    end
    -- 描述
    local desc = XUiHelper.FormatText(self._Control:GetEventStepItemDesc(self.TemplateId, self.Type), "")
    self.TxtDescription.text = XUiHelper.ConvertLineBreakSymbol(desc)
    -- 表现
    self.Tag.gameObject:SetActiveEx(false)

    self.TextCoin.text = isMoneyShop and string.format("+%s", math.abs(shopItem:GetOriginalPrice())) or shopItem:GetPrice()
    self.ImgCoin:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XEnumConst.THEATRE3.Theatre3InnerCoin))
    -- 消耗颜色
    local costItemId = XEnumConst.THEATRE3.Theatre3InnerCoin
    local canBuy = isMoneyShop or XDataCenter.ItemManager.GetCount(costItemId) >= shopItem:GetPrice()
    local colorCode = self._Control:GetClientConfig("ShopItemCostColor", canBuy and 1 or 2)
    if not string.IsNilOrEmpty(colorCode) then
        self.TextCoin.color = XUiHelper.Hexcolor2Color(colorCode)
    end
end

--region Ui - BtnListener
function XUiTheatre3ShopTips:AddBtnListener()
    self._Control:RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    self._Control:RegisterClickEvent(self, self.BtnCancel, self.OnBtnBackClick)
    self._Control:RegisterClickEvent(self, self.BtnTanchuangClose, self.OnBtnBackClick)
    self._Control:RegisterClickEvent(self, self.BtnSure, self.OnBtnSureClick)
end

function XUiTheatre3ShopTips:OnBtnBackClick()
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiTheatre3ShopTips:OnBtnSureClick()
    XLuaUiManager.CloseWithCallback(self.Name, self.SureCb)
end
--endregion

return XUiTheatre3ShopTips