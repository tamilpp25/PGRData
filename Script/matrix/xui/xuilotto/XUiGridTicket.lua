local XUiGridTicket = XClass(nil, "XUiGridTicket")

function XUiGridTicket:Ctor(ui, data, buyCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.TicketData = data
    self.BuyCb = buyCb
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self:ShowPanel()
end

function XUiGridTicket:SetButtonCallBack()
    if self.BtnBuy then
        self.BtnBuy.CallBack = function()
            self:OnBtnBuyClick()
        end
    end
    if self.ImgBtn then
        self.ImgBtn.CallBack = function()
            self:OnImgBtnClick()
        end
    end
end

function XUiGridTicket:ShowPanel()
    if self.Sale then
        self.Sale.gameObject:SetActiveEx(self.TicketData.Sale)
    end
    
    if self.SaleText then
        self.SaleText.text = self.TicketData.Sale
    end
    
    if self.CostNum then
        self.CostNum.text = self.TicketData.ItemCount
    end
    
    if self.CurNum then
        self.CurNum.text = XDataCenter.ItemManager.GetItem(self.TicketData.ItemId).Count
    end
    
    if self.CardImg then
        local goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.TicketData.ItemId)
        local icon = self.TicketData.ItemImg or goods.BigIcon or goods.Icon
        self.CardImg:SetRawImage(icon)
    end
end

function XUiGridTicket:OnBtnBuyClick()
    -- 检查物品数量是够足够，不够弹出购买
    local itemId = self.TicketData.ItemId
    local currentCount = XDataCenter.ItemManager.GetCount(itemId)
    local needCount = self.TicketData.ItemCount
    if currentCount < needCount then
        if itemId == XDataCenter.ItemManager.ItemId.FreeGem or itemId == XDataCenter.ItemManager.ItemId.PaidGem then
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
        elseif itemId == XDataCenter.ItemManager.ItemId.HongKa then
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
        elseif XItemConfigs.GetBuyAssetTemplateById(itemId) then
            XLuaUiManager.Open("UiBuyAsset", itemId, function()
                if self.CurNum then
                    self.CurNum.text = XDataCenter.ItemManager.GetItem(self.TicketData.ItemId).Count
                end
            end, nil, needCount - currentCount)
        else
            XUiManager.TipError(XUiHelper.GetText("AssetsBuyConsumeNotEnough", XDataCenter.ItemManager.GetItemName(itemId)))
        end
        return
    end
    if self.BuyCb then
        self.BuyCb() 
    end
end

function XUiGridTicket:OnImgBtnClick()
    local data = XDataCenter.ItemManager.GetItem(self.TicketData.ItemId)
    XLuaUiManager.Open("UiTip", data)
end

return XUiGridTicket