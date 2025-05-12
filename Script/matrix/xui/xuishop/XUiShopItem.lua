local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiShopItem = XLuaUiManager.Register(XLuaUi, "UiShopItem")
local MAX_COUNT = CS.XGame.Config:GetInt("ShopBuyGoodsCountLimit")
local ColorRed = CS.XGame.ClientConfig:GetString("ShopCanNotBuyColor")
local ColorBlack = CS.XGame.ClientConfig:GetString("ShopCanBuyColor")
local Interval = 100
local SpeedBaseNumber = 150
local CountBaseNumber = 100
function XUiShopItem:OnStart(parent, data, cb, shopCanBuyColor, proxy)
    if data then
        self.Data = data
    else
        return
    end
    if cb then
        self.CallBack = cb
    end
    self.Parent = parent
    self.ShopCanBuyColor = shopCanBuyColor or ColorBlack
    self.Proxy = proxy

    self:AutoAddListener()
    self:SetSelectTextData()
    self.Grid = XUiGridCommon.New(self, self.GridBuyCommon)
    self.Price = {}
    table.insert(self.Price, self.PanelCostItem1)
    table.insert(self.Price, self.PanelCostItem2)
    table.insert(self.Price, self.PanelCostItem3)

    self.WgtBtnAddSelect = self.BtnAddSelect.gameObject:GetComponent("XUiPointer")
    self.WgtBtnMinusSelect = self.BtnMinusSelect.gameObject:GetComponent("XUiPointer")

    XUiButtonLongClick.New(self.WgtBtnAddSelect, Interval, self, nil, self.BtnAddSelectLongClickCallback, nil, true)
    XUiButtonLongClick.New(self.WgtBtnMinusSelect, Interval, self, nil, self.BtnMinusSelectLongClickCallback, nil, true)

    self:InitPanel()
end

function XUiShopItem:OnEnable()

end

function XUiShopItem:OnDisable()

end

function XUiShopItem:InitPanel()

    self.MinCount = 1
    self.Count = 1
    self.Consumes = {}
    self.BuyConsumes = {}

    XTool.LoopMap(self.Data.ConsumeList, function(_, consume)
        local buyitem = {}
        buyitem.Id = consume.Id
        buyitem.Count = consume.Count
        table.insert(self.Consumes, buyitem)
        local consumes = {}
        consumes.Id = consume.Id
        consumes.Count = 0
        table.insert(self.BuyConsumes, consumes)
    end)

    self:RefreshCommon()
    self:RefreshPrice()
    self:GetSalesInfo()
    self:GetMaxCount()
    self:RefreshConsumes()
    self:SetCanBuyCount()
    self:JudgeBuy()
    self:HaveItem()
    self:SetCanAddOrMinusBtn()
    self.TxtSelect.text = self.Count
end

function XUiShopItem:AutoAddListener()

    self.BtnMax.CallBack = function()
        self:OnBtnMaxClick()
    end

    self.BtnUse.CallBack = function()
        self:OnBtnUseClick()
    end

    self.BtnAddSelect.CallBack = function()
        self:OnBtnAddSelectClick()
    end

    self.BtnMinusSelect.CallBack = function()
        self:OnBtnMinusSelectClick()
    end

    self.TxtSelect.onValueChanged:AddListener(function()
        self:OnSelectTextChange()
    end)

    self.TxtSelect.onEndEdit:AddListener(function()
        self:OnSelectTextInputEnd()
    end)

    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnBlockClick()
    end
end

function XUiShopItem:SetSelectTextData()
    self.TxtSelect.characterLimit = 4
    self.TxtSelect.contentType = CS.UnityEngine.UI.InputField.ContentType.IntegerNumber
end

-- auto
function XUiShopItem:OnBtnBlockClick()
    self:Close()
end

function XUiShopItem:RemoveUI()
    XLuaUiManager.Remove(self.Name)
end

function XUiShopItem:OnBtnAddSelectClick()
    if self.Count + 1 > self.MaxCount then
        XMVCA.XEquip:ShowBoxOverLimitText()
        return
    end
    self.Count = self.Count + 1
    self:RefreshConsumes()
    self:JudgeBuy()
    self.TxtSelect.text = self.Count
    self:SetCanAddOrMinusBtn()
end

function XUiShopItem:OnBtnMinusSelectClick()
    if self.Count - 1 < self.MinCount then
        return
    end
    self.Count = self.Count - 1
    self:RefreshConsumes()
    self:JudgeBuy()
    self.TxtSelect.text = self.Count
    self:SetCanAddOrMinusBtn()
end

function XUiShopItem:BtnAddSelectLongClickCallback(time)
    if self.Count + 1 > self.MaxCount then
        XMVCA.XEquip:ShowBoxOverLimitText()
        return
    end

    local delta = math.max(0, math.floor(time / SpeedBaseNumber))
    self.Count = self.Count + delta
    if self.MaxCount and self.Count >= self.MaxCount then
        self.Count = self.MaxCount
    end

    self:RefreshConsumes()
    self:JudgeBuy()
    self.TxtSelect.text = self.Count
    self:SetCanAddOrMinusBtn()
end

function XUiShopItem:BtnMinusSelectLongClickCallback(time)
    if self.Count - 1 < self.MinCount then
        return
    end
    local delta = math.max(0, math.floor(time / SpeedBaseNumber))
    self.Count = self.Count - delta
    if self.Count <= 0 then
        self.Count = 0
    end
    self:RefreshConsumes()
    self:JudgeBuy()
    self.TxtSelect.text = self.Count
    self:SetCanAddOrMinusBtn()
end

function XUiShopItem:OnBtnMaxClick()
    self.Count = math.min(self.MaxCount, self.CanBuyCount)
    self:RefreshConsumes()
    self:JudgeBuy()
    self.TxtSelect.text = self.Count
    self:SetCanAddOrMinusBtn()
end

function XUiShopItem:OnSelectTextChange()
    if self.TxtSelect.text == nil or self.TxtSelect.text == "" then
        return
    end
    if self.TxtSelect.text == "0" then
        self.TxtSelect.text = 1
    end
    local tmp = tonumber(self.TxtSelect.text)
    local tmpMax = math.max(math.min(MAX_COUNT, self.MaxCount), 1)
    if tmp > tmpMax then
        tmp = tmpMax
        self.TxtSelect.text = tmp
    end
    self.Count = tmp
    self:RefreshConsumes()
    self:JudgeBuy()
end

function XUiShopItem:OnSelectTextInputEnd()
    if self.TxtSelect.text == nil or self.TxtSelect.text == "" then
        self.TxtSelect.text = 1
        local tmp = tonumber(self.TxtSelect.text)
        self.Count = tmp
        self:RefreshConsumes()
        self:JudgeBuy()
    end
end

function XUiShopItem:SetCanAddOrMinusBtn()
    self.BtnMinusSelect.interactable = self.Count > self.MinCount
    self.BtnAddSelect.interactable = self.MaxCount > self.Count

    if self.BtnMax then
        self.BtnMax:SetDisable(self.MaxCount <= 1)
    end

    if self.PanelTxt then
        self.PanelTxt.gameObject:SetActiveEx(self.MaxCount < MAX_COUNT)
    end

    if self.TxtCanBuy then
        self.TxtCanBuy.text = self.MaxCount
    end
end

function XUiShopItem:OnBtnUseClick()
    if self.HaveNotBuyCount then
        if not XMVCA.XEquip:ShowBoxOverLimitText() then
            XUiManager.TipText("ShopHaveNotBuyCount")
        end
        return
    end

    local doFunCountinueTip = function ()
        for k, v in pairs(self.NotEnough or {}) do
            if v.ItemId == XDataCenter.ItemManager.ItemId.PaidGem then
                local result = XDataCenter.ItemManager.CheckItemCountById(v.ItemId, v.UseItemCount)
                if not result then
                    XUiManager.TipText("ShopItemPaidGemNotEnough")
                    XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
                    return
                end
            elseif v.ItemId == XDataCenter.ItemManager.ItemId.HongKa then
                local result = XDataCenter.ItemManager.CheckItemCountById(v.ItemId, v.UseItemCount)
                if not result then
                    XUiManager.TipText("ShopItemHongKaNotEnough")
                    XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
                    return
                end
            else
                if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(v.ItemId,
                v.UseItemCount,
                1,
                function()
                    self:OnBtnUseClick()
                end,
                "BuyNeedItemInsufficient") then
                    return
                end
                self.NotEnough[k] = nil
            end
        end

        local func = function()
            XShopManager.BuyShop(self.Parent:GetCurShopId(), self.Data.Id, self.Count, function()
                if self.CallBack then
                    self.CallBack(self.Count)
                end
                XUiManager.TipText("BuySuccess")
                self.Parent:RefreshBuy()
                self:RemoveUI()
            end)
        end

        -- v1.31 【商店优化】大额消费二次确认弹窗
        for _, consumeItem in pairs(self.BuyConsumes or {}) do
            if XShopManager.IsNeedSecondConfirm(consumeItem.Id, consumeItem.Count, self.Count) then
                XShopManager.OpenBuySecondConfirm(consumeItem.Id, consumeItem.Count, self.Count, self.Data.RewardGoods.TemplateId, nil, function ()
                    self:CheckBuyItemTypeOfWeaponFashion(func)
                end)
                return
            end
        end

        self:CheckBuyItemTypeOfWeaponFashion(func)
    end

    -- 黑卡消费提醒
    if self.Proxy and self.Proxy.CheckPaidGemTip and self.Proxy.CheckPaidGemTip(self) then
        local titile = CS.XTextManager.GetText("TipTitle")
        local content = CS.XTextManager.GetText("CheckPaidGemTip")
        XLuaUiManager.Open("UiDialog", titile, content, XUiManager.DialogType.Normal, nil, doFunCountinueTip)
    else
        doFunCountinueTip()
    end
end

function XUiShopItem:HaveItem()
    local goodsType = XArrangeConfigs.GetType(self.Data.RewardGoods.TemplateId)
    if goodsType == XArrangeConfigs.Types.Furniture or
            goodsType == XArrangeConfigs.Types.GuildGoods then
        self.TxtOwnCount.gameObject:SetActiveEx(false)
    else
        local count = XGoodsCommonManager.GetGoodsCurrentCount(self.Data.RewardGoods.TemplateId)
        self.TxtOwnCount.text = CS.XTextManager.GetText("CurrentlyHas", count)
        self.TxtOwnCount.gameObject:SetActiveEx(true)
    end
end

function XUiShopItem:RefreshCommon()
    self.RImgType.gameObject:SetActiveEx(false)

    local rewardGoods = self.Data.RewardGoods
    self.Grid:Refresh(rewardGoods, nil, true)
    self.Grid:ShowCount(true)
end

function XUiShopItem:RefreshPrice()
    if #self.Consumes ~= 0 then
        self.PanelPrice.gameObject:SetActiveEx(true)
        for i = 1, #self.Price do
            if i <= #self.Consumes then
                self.Price[i].gameObject:SetActiveEx(true)
            else
                self.Price[i].gameObject:SetActiveEx(false)
            end
        end
    else
        self.PanelPrice.gameObject:SetActiveEx(false)
    end
end

function XUiShopItem:RefreshOnSales(buyCount)
    self.OnSales = {}
    XTool.LoopMap(self.Data.OnSales, function(k, sales)
        self.OnSales[k] = sales
    end)
    local sumbuy = buyCount + self.Data.TotalBuyTimes
    if #self.OnSales ~= 0 then
        local curLevel = 0
        for k, v in pairs(self.OnSales) do
            if sumbuy >= k and k > curLevel then
                self.Sales = v
                curLevel = k
            end
        end
    else
        self.Sales = 100
    end
end

function XUiShopItem:RefreshConsumes()
    for i = 1, #self.BuyConsumes do
        self.BuyConsumes[i].Count = 0
    end
    for k, v in pairs(self.Consumes) do
        self.BuyConsumes[k].Id = v.Id
        self.BuyConsumes[k].Count = math.floor(v.Count * self.Sales / CountBaseNumber) * self.Count
    end
    for i = 1, #self.Consumes do
        self["RImgCostIcon" .. i]:SetRawImage(XDataCenter.ItemManager.GetItemBigIcon(self.BuyConsumes[i].Id))
        self["TxtCostCount" .. i].text = math.floor(self.BuyConsumes[i].Count)
    end
end

function XUiShopItem:GetSalesInfo()
    self.OnSales = {}
    XTool.LoopMap(self.Data.OnSales, function(k, sales)
        self.OnSales[k] = sales
    end)
end

function XUiShopItem:GetMaxCount()
    self.Sales = 100
    local sortedKeys = {}
    for k, _ in pairs(self.OnSales) do
        table.insert(sortedKeys, k)
    end
    table.sort(sortedKeys)

    local leftSalesGoods = MAX_COUNT

    for i = 1, #sortedKeys do
        if self.Data.TotalBuyTimes >= sortedKeys[i] - 1 then
            self.Sales = self.OnSales[sortedKeys[i]]
        else
            leftSalesGoods = sortedKeys[i] - self.Data.TotalBuyTimes - 1
            break
        end
    end

    local leftShopTimes = XShopManager.GetShopLeftBuyTimes(self.Parent:GetCurShopId())
    if not leftShopTimes then
        leftShopTimes = MAX_COUNT
    end

    local leftGoodsTimes = MAX_COUNT
    if self.Data.BuyTimesLimit and self.Data.BuyTimesLimit > 0 then
        local buyCount = self.Data.TotalBuyTimes and self.Data.TotalBuyTimes or 0
        leftGoodsTimes = self.Data.BuyTimesLimit - buyCount
    end
    local tmpMaxCount = math.min(leftGoodsTimes, math.min(leftShopTimes, leftSalesGoods))
    self.MaxCount = tmpMaxCount
    self.MaxCount = XMVCA.XEquip:GetMaxCountOfBoxOverLimit(self.Data.RewardGoods.TemplateId, self.MaxCount, self.Data.RewardGoods.Count)

    if self.MaxCount < tmpMaxCount then
        self.BuyHintText.text = CS.XTextManager.GetText("MaxCanBuyText")
    else
        self.BuyHintText.text = CS.XTextManager.GetText("CanBuyText")
    end
end

function XUiShopItem:SetCanBuyCount()
    local canBuyCount = self.MaxCount
    for _, v in pairs(self.BuyConsumes) do
        local itemCount = self:GetCountProxy(v.Id)
        local buyCount = math.floor(itemCount / v.Count)
        canBuyCount = math.min(buyCount, canBuyCount)
    end
    canBuyCount = math.max(self.MinCount, canBuyCount)
    self.CanBuyCount = canBuyCount
end

function XUiShopItem:JudgeBuy()
    self.HaveNotBuyCount = self.Count > self.MaxCount or self.Count == 0
    if self.HaveNotBuyCount then
        return
    end

    local index = 1
    local enoughIndex = {}
    self.NotEnough = {}

    for _, v in pairs(self.BuyConsumes) do
        local itemCount = self:GetCountProxy(v.Id)
        if v.Count > itemCount then
            self:ChangeCostColor(false, index)
            if not self.NotEnough[index] then self.NotEnough[index] = {} end
            self.NotEnough[index].ItemId = v.Id
            self.NotEnough[index].UseItemCount = v.Count
        else
            table.insert(enoughIndex, index)
        end
        index = index + 1
    end

    for _, v in pairs(enoughIndex) do
        self:ChangeCostColor(true, v)
    end
end

function XUiShopItem:ChangeCostColor(bool, index)
    if bool then
        self["TxtCostCount" .. index].color = XUiHelper.Hexcolor2Color(self.ShopCanBuyColor)
    else
        self["TxtCostCount" .. index].color = XUiHelper.Hexcolor2Color(ColorRed)
    end
end

function XUiShopItem:CheckBuyItemTypeOfWeaponFashion(cb)
    local templateId = self.Data.RewardGoods.TemplateId
    if XDataCenter.ItemManager.IsWeaponFashion(templateId) then
        local fashionId = XDataCenter.ItemManager.GetWeaponFashionId(templateId)
        if XDataCenter.WeaponFashionManager.CheckHasFashion(fashionId) then
            if XDataCenter.ItemManager.IsWeaponFashionTimeLimit(templateId) then
                self:TipDialog(nil, cb, "BuyWeaponFashionIsTimeLimit")
            else
                self:TipDialog(nil, cb, "BuyWeaponFashionIsNotTimeLimit")
            end
            return
        end
    end
    cb()
end

function XUiShopItem:GetCountProxy(id)
    if self.Proxy and self.Proxy.GetCount then
        return self.Proxy.GetCount(id)
    end
    return XDataCenter.ItemManager.GetCount(id)
end

function XUiShopItem:TipDialog(cancelCb, confirmCb, TextKey)
    XLuaUiManager.Open("UiDialog", CS.XTextManager.GetText("TipTitle"), CS.XTextManager.GetText(TextKey), XUiManager.DialogType.Normal, cancelCb, confirmCb)
end

return XUiShopItem