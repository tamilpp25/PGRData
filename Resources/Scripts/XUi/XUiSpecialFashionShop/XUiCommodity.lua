local XUiCommodity = XClass(nil,"XUiCommodity")

local BuyCount = 1

function XUiCommodity:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent

    XTool.InitUiObject(self)
    self:InitComponent()
    self:AddListener()
end

function XUiCommodity:Refresh(data)
    if not data then
        self.GameObject:SetActiveEx(false)
    else
        self.Data = data
        self:RefreshSellOut()
        self:RefreshCondition()
        self:RefreshIcon()
        self:RefreshOnSales()
        self:RefreshPrice()
        self:RefreshBuyCount()
        self:RefreshGift()

        self:RefreshTimer(self.Data.Id, self.Data.SelloutTime)

        self.GameObject:SetActiveEx(true)
    end
end

function XUiCommodity:InitComponent()
    self.PanelPrice = {
        self.PanelPrice1
    }
    self.TxtOldPrice = {
        self.TxtOldPrice1
    }
    self.TxtNewPrice = {
        self.TxtNewPrice1
    }
    self.RImgPrice = {
        self.RImgPrice1
    }
end

function XUiCommodity:RefreshCondition()
    if not self.BtnCondition then return end
    self.BtnCondition.gameObject:SetActiveEx(false)
    self.ConditionDesc = nil
    local conditionIds = self.Data.ConditionIds
    if not conditionIds or #conditionIds <= 0 then return end

    for _, id in pairs(conditionIds) do
        local ret, desc = XConditionManager.CheckCondition(id)
        if not ret then
            self.BtnCondition.gameObject:SetActiveEx(true)
            self.ImgSellOut.gameObject:SetActiveEx(false)
            self.ConditionDesc = desc
            self.ConditionText.text = desc
            return
        end
    end
end

function XUiCommodity:RefreshSellOut()
    if not self.ImgSellOut then
        return
    end
    self.IsSellOut = false
    if self.Data.BuyTimesLimit <= 0 then
        self.ImgSellOut.gameObject:SetActiveEx(false)
    else
        if self.Data.TotalBuyTimes >= self.Data.BuyTimesLimit then
            self.ImgSellOut.gameObject:SetActiveEx(true)
            self.IsSellOut = true
        else
            self.ImgSellOut.gameObject:SetActiveEx(false)
        end
    end
end

function XUiCommodity:RefreshIcon()
    if type(self.Data.RewardGoods) == "number" then
        self.TemplateId = self.Data.RewardGoods
    else
        self.TemplateId = (self.Data.RewardGoods.TemplateId and self.Data.RewardGoods.TemplateId > 0) and
                self.Data.RewardGoods.TemplateId or
                self.Data.RewardGoods.Id
    end

    self.IsWeaponFashion = XDataCenter.ItemManager.IsWeaponFashion(self.TemplateId)
    self.Id = self.IsWeaponFashion and XDataCenter.ItemManager.GetWeaponFashionId(self.TemplateId) or self.TemplateId

    self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.Id)
    if self.GoodsShowParams.Name then
        if self.GoodsShowParams.RewardType == XArrangeConfigs.Types.Character then
            self.TxtName.text = self.GoodsShowParams.TradeName
        else
            self.TxtName.text = self.GoodsShowParams.Name
        end
    end

    local characterIcon = self.IsWeaponFashion and self.GoodsShowParams.ShopIcon or self.GoodsShowParams.CharacterIcon
    if characterIcon then
        self.RImgIcon:SetRawImage(characterIcon)
    end
end

function XUiCommodity:RefreshOnSales()
    self.OnSales = {}
    self.OnSalesLongTest = {}
    XTool.LoopMap(self.Data.OnSales, function(k, sales)
        self.OnSales[k] = sales
        table.insert(self.OnSalesLongTest, sales)
    end)

    self.Sales = 100

    if #self.OnSalesLongTest ~= 0 then
        local sortedKeys = {}
        for k, _ in pairs(self.OnSales) do
            table.insert(sortedKeys, k)
        end
        table.sort(sortedKeys)

        for i = 1, #sortedKeys do
            if self.Data.TotalBuyTimes >= sortedKeys[i] - 1 then
                self.Sales = self.OnSales[sortedKeys[i]]
            end
        end
    end
    self:RefreshPanelSale()
end

function XUiCommodity:RefreshPanelSale()
    local hideSales = false
    if self.TxtSaleRate then
        if self.Data.Tags == XShopManager.ShopTags.DisCount then
            if self.Sales < 100 then
                self.TxtSaleRate.text = self.Sales / 10 .. CS.XTextManager.GetText("Snap")
            else
                hideSales = true
            end
        end
        if self.Data.Tags == XShopManager.ShopTags.TimeLimit then
            self.TxtSaleRate.text = CS.XTextManager.GetText("TimeLimit")
        end
        if self.Data.Tags == XShopManager.ShopTags.Recommend then
            self.TxtSaleRate.text = CS.XTextManager.GetText("Recommend")
        end
        if self.Data.Tags == XShopManager.ShopTags.HotSale then
            self.TxtSaleRate.text = CS.XTextManager.GetText("HotSell")
        end

        if self.Data.Tags == XShopManager.ShopTags.Not or hideSales then
            self.TxtSaleRate.gameObject:SetActiveEx(false)
            self.TxtSaleRate.gameObject.transform.parent.gameObject:SetActiveEx(false)
        else
            self.TxtSaleRate.gameObject:SetActiveEx(true)
            self.TxtSaleRate.gameObject.transform.parent.gameObject:SetActiveEx(true)
        end
    end
end

function XUiCommodity:RefreshPrice()
    local panelCount = #self.PanelPrice
    for i = 1, panelCount do
        self.PanelPrice[i].gameObject:SetActiveEx(false)
    end

    local index = 1
    for _, count in pairs(self.Data.ConsumeList) do
        if index > panelCount then
            return
        end

        local txtOldPrice = self.TxtOldPrice[index]
        if txtOldPrice then
            if self.Sales == 100 then
                txtOldPrice.gameObject:SetActiveEx(false)
            else
                txtOldPrice.text = count.Count
                txtOldPrice.gameObject:SetActiveEx(true)
            end
        end

        local rImgPrice = self.RImgPrice[index]
        if rImgPrice then
            self.ItemIcon = XDataCenter.ItemManager.GetItemIcon(count.Id)
            if self.ItemIcon ~= nil then
                rImgPrice:SetRawImage(self.ItemIcon)
            end
        end

        local txtNewPrice = self.TxtNewPrice[index]
        if txtNewPrice then
            self.NeedCount = math.floor(count.Count * self.Sales / 100)
            txtNewPrice.text = self.NeedCount
            local itemCount = XDataCenter.ItemManager.GetCount(count.Id)
            if itemCount < self.NeedCount then
                txtNewPrice.color = CS.UnityEngine.Color(1, 0, 0)
            else
                txtNewPrice.color = CS.UnityEngine.Color(0, 0, 0)
            end
        end

        self.PanelPrice[index].gameObject:SetActiveEx(true)
        index = index + 1
    end
end

function XUiCommodity:RefreshBuyCount()
    if not self.ImgLimitLable then
        return
    end

    if not self.TxtLimitLable then
        return
    end

    if self.Data.BuyTimesLimit <= 0 then
        self.TxtLimitLable.gameObject:SetActiveEx(false)
        self.ImgLimitLable.gameObject:SetActiveEx(false)
    else
        local buynumber = self.Data.BuyTimesLimit - self.Data.TotalBuyTimes
        local limitLabel =  XShopConfigs.GetBuyLimitLabel(self.Data.AutoResetClockId)
        local text = string.format(limitLabel, buynumber)

        self.TxtLimitLable.text = text
        self.TxtLimitLable.gameObject:SetActiveEx(true)
        self.ImgLimitLable.gameObject:SetActiveEx(true)
    end
end

function XUiCommodity:RefreshGift()
    if self.Data.GiftRewardId and self.Data.GiftRewardId ~= 0 then
        self.ImgTabLb.gameObject:SetActiveEx(true)
        self.GiftRewardId = self.Data.GiftRewardId
    else
        self.GiftRewardId = 0
        self.ImgTabLb.gameObject:SetActiveEx(false)
    end
end

function XUiCommodity:OnRecycle()
    if self.Data then
        self:RemoveTimer(self.Data.Id)
    end
end

---------------------------------------------------计时器---------------------------------------------------------

function XUiCommodity:RemoveTimer(funId)
    self.Parent:RemoveTimerFun(funId)
end

function XUiCommodity:RefreshTimer(funId, time)
    if not self.ImgLeftTime then
        return
    end

    if not self.TxtLeftTime then
        return
    end

    if time <= 0 then
        self.TxtLeftTime.gameObject:SetActiveEx(false)
        self.ImgLeftTime.gameObject:SetActiveEx(false)
        return
    end

    self.TxtLeftTime.gameObject:SetActiveEx(true)
    --self.ImgLeftTime.gameObject:SetActiveEx(true)暂时关闭
    self.ImgLeftTime.gameObject:SetActiveEx(false)
    
    local leftTime = XShopManager.GetLeftTime(time)

    local func = function()
        leftTime = leftTime > 0 and leftTime or 0
        local dataTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.SHOP)
        if self.TxtLeftTime then
            self.TxtLeftTime.text = CS.XTextManager.GetText("TimeSoldOut", dataTime)
        end
        if leftTime <= 0 then
            self:RemoveTimer(funId)
            if self.ImgSellOut then
                self.ImgSellOut.gameObject:SetActiveEx(true)
                self.IsSellOut = true
            end
        end
    end

    func()
    self.Parent:RegisterTimerFun(funId, function()
        leftTime = leftTime - 1
        func()
    end)
end

---------------------------------------------------添加监听函数---------------------------------------------------------

function XUiCommodity:AddListener()
    self.BtnCondition.CallBack = function()
        self:OnBtnConditionClick()
    end
    self.BtnBuy.CallBack = function()
        self:OnBtnBuyClick()
    end
end

function XUiCommodity:OnBtnConditionClick()
    if self.ConditionDesc then
        XUiManager.TipError(self.ConditionDesc)
    end
end

function XUiCommodity:OnBtnBuyClick()
    if self.IsSellOut then
        XUiManager.TipText("ShopItemSellOut")
        return
    end
    if self.IsShopOnSaleLock then
        XUiManager.TipError(self.ShopOnSaleLockDecs)
        return
    end
    local buyData = {}
    buyData.IsHave = false
    buyData.ItemIcon = self.ItemIcon
    buyData.ItemCount = self.NeedCount

    buyData.GiftRewardId = self.GiftRewardId
    buyData.BuyCallBack = function()
        for _, consume in pairs(self.Data.ConsumeList) do
            if consume.Id == XDataCenter.ItemManager.ItemId.HongKa then
                local result = XDataCenter.ItemManager.CheckItemCountById(consume.Id, self.NeedCount)
                if not result then
                    XUiManager.TipText("ShopItemHongKaNotEnough")
                    XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
                    return
                end
            elseif consume.Id == XDataCenter.ItemManager.ItemId.PaidGem then
                local result = XDataCenter.ItemManager.CheckItemCountById(consume.Id, self.NeedCount)
                if not result then
                    XUiManager.TipText("ShopItemPaidGemNotEnough")
                    XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
                    return
                end
            end
        end

        XShopManager.BuyShop(self.Parent:GetCurShopId(), self.Data.Id, BuyCount, function ()
            local text = CS.XTextManager.GetText("BuySuccess")
            XUiManager.TipMsg(text, nil, function()
                if buyData.GiftRewardId and buyData.GiftRewardId ~= 0 then
                    local rewardGoodList = XRewardManager.GetRewardList(buyData.GiftRewardId)
                    XUiManager.OpenUiObtain(rewardGoodList)
                end
            end)

            self.Parent:RefreshBuy()
        end)
    end

    XLuaUiManager.Open("UiFashionDetail", self.Id, self.IsWeaponFashion, buyData)
end

return XUiCommodity