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
    if self.BuyCb then
        self.BuyCb() 
    end
end

function XUiGridTicket:OnImgBtnClick()
    -- if self.TicketData.ItemId == 5 then -- 英文服有虹卡
    --     XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.LB, nil, 1)
    --     return
    -- end
    local data = XDataCenter.ItemManager.GetItem(self.TicketData.ItemId)
    XLuaUiManager.Open("UiTip", data)
end

return XUiGridTicket