---@class XUiGachaAlphaBuyTicket : XLuaUi
local XUiGachaAlphaBuyTicket = XLuaUiManager.Register(XLuaUi, "UiGachaAlphaBuyTicket")

function XUiGachaAlphaBuyTicket:OnAwake()
    self._TargetCardPanel = {}
    self._PanelDic = {}
    self._BuyCountMax = 10
    self._BuyAmount = nil
    -- 用于cd购买
    self._TargetCanBuyTimestamp = nil
    self._CDTime = 1

    XTool.InitUiObjectByUi(self._TargetCardPanel, self.TargetCard)
    self:InitItemCardPanel(1) -- 初始化两个Card
    self:InitItemCardPanel(2)
    self:InitButton()
end

---@param itemData1 table {ItemId, CostNum, Sale}
---@param itemData2 table
---@param targetItemData table {ItemId, CostNum, Sale}
---@param closeCb function
function XUiGachaAlphaBuyTicket:OnStart(gachaCfg, itemData1, itemData2, targetItemData, forceBuyCount, closeCb)
    self._GachaCfg = gachaCfg
    self._ItemData1 = itemData1
    self._ItemData2 = itemData2
    self._TargetItemData = targetItemData
    self._ForceBuyCount = forceBuyCount
    self._CloseCb = closeCb
    self._GachaBuyTicketRuleConfig = XGachaConfigs.GetGachaItemExchangeCfgById(self._GachaCfg.ExchangeId)
    self._BuyCountMax = self._GachaBuyTicketRuleConfig.BuyCountMax
    self._BuyAmount = nil

    local timeId = self._GachaCfg.TimeId
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiGachaAlphaBuyTicket:OnEnable()
    self:Refresh()
    if self._ForceBuyCount then
        -- 如果没有货币 强制设为10
        self:OnSelfSetBuyCount(self._ForceBuyCount)
    end
end

function XUiGachaAlphaBuyTicket:InitItemCardPanel(index)
    local panel = {}
    self._PanelDic[index] = panel
    XTool.InitUiObjectByUi(panel, self["Card" .. index])
    self:RegisterClickEvent(panel.ImgBtn, function()
        self:OnImgBtnClick(index)
    end)
    self:RegisterClickEvent(panel.BtnBuy, function()
        self:OnBtnBuyClick(index)
    end)
end

function XUiGachaAlphaBuyTicket:InitButton()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnMax, self.OnBtnMaxClick)
    self:RegisterClickEvent(self.BtnAddSelect, self.OnBtnAddSelectClick)
    self:RegisterClickEvent(self.BtnMinusSelect, self.OnBtnMinusSelectClick)
    self:RegisterClickEvent(self._TargetCardPanel.ImgBtn, function()
        local data = XDataCenter.ItemManager.GetItem(self._TargetItemData.ItemId)
        XLuaUiManager.Open("UiTip", data)
    end)
    self.TxtSelect.onValueChanged:AddListener(function()
        self:OnSelectTextChange()
    end)
end

function XUiGachaAlphaBuyTicket:Refresh()
    self:RefreshUiShow()
    self:RefreshBuyAmount(tonumber(self.TxtSelect.text))
end

function XUiGachaAlphaBuyTicket:GetItemData(index)
    return index == 1 and self._ItemData1 or self._ItemData2
end

function XUiGachaAlphaBuyTicket:RefreshUiShow()
    for index, panel in pairs(self._PanelDic) do
        local currItemData = self:GetItemData(index)
        panel.Sale.gameObject:SetActiveEx(currItemData.Sale)
        panel.SaleText.text = currItemData.Sale
        local curCost = currItemData.CostNum * (self._BuyAmount or 1)
        panel.CostNum.text = curCost
        local curCount = XDataCenter.ItemManager.GetItem(currItemData.ItemId).Count
        if curCount < curCost then
            -- 不足显示红色
            curCount = CS.XTextManager.GetText("RedText", curCount)
        end
        panel.CurNum.text = curCount
        local goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(currItemData.ItemId)
        local icon = currItemData.ItemImg or goods.BigIcon or goods.Icon
        panel.CardImg:SetRawImage(icon)
    end

    local goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self._TargetItemData.ItemId)
    local icon = goods.BigIcon or goods.Icon
    self._TargetCardPanel.CardImg:SetRawImage(icon)
end

function XUiGachaAlphaBuyTicket:RefreshBuyAmount(count)
    self._BuyAmount = count
end

function XUiGachaAlphaBuyTicket:CheckBuyAmountLimit(count)
    if type(count) ~= "number" then
        return 1
    end

    local leftCanBuy = self._GachaBuyTicketRuleConfig.TotalBuyCountMax - XDataCenter.GachaManager.GetCurExchangeItemCount(self._GachaCfg.Id)
    if count > leftCanBuy then
        if leftCanBuy <= 0 then
            leftCanBuy = 1
        end
        if leftCanBuy > self._BuyCountMax then
            return self._BuyCountMax
        end
        return leftCanBuy
    elseif count > self._BuyCountMax then
        return self._BuyCountMax
    elseif count < 1 then
        return 1
    end

    return false
end

-- 如果想要在程序直接控制文本的购买数量 只能调用该接口
function XUiGachaAlphaBuyTicket:OnSelfSetBuyCount(count)
    local targetCount = count
    if self:CheckBuyAmountLimit(targetCount) then
        return
    end

    self.TxtSelect.text = targetCount
end

function XUiGachaAlphaBuyTicket:OnBtnMaxClick()
    local targetCount = self._BuyCountMax
    local res = self:CheckBuyAmountLimit(targetCount)
    if res then
        targetCount = res
    end

    self.TxtSelect.text = targetCount
end

function XUiGachaAlphaBuyTicket:OnBtnAddSelectClick()
    local count = tonumber(self.TxtSelect.text)
    local targetCount = count + 1
    if self:CheckBuyAmountLimit(targetCount) then
        return
    end

    self.TxtSelect.text = targetCount
end

function XUiGachaAlphaBuyTicket:OnBtnMinusSelectClick()
    local count = tonumber(self.TxtSelect.text)
    local targetCount = count - 1
    if self:CheckBuyAmountLimit(targetCount) then
        return
    end

    self.TxtSelect.text = targetCount
end

-- text改动的回调
function XUiGachaAlphaBuyTicket:OnSelectTextChange()
    local count = tonumber(self.TxtSelect.text)
    local isLimitNum = self:CheckBuyAmountLimit(count)
    if isLimitNum then
        -- 输入超了强行改回
        self.TxtSelect.text = isLimitNum
        count = isLimitNum
    end

    self:RefreshBuyAmount(count)
    self:RefreshUiShow()
end

function XUiGachaAlphaBuyTicket:OnImgBtnClick(index)
    local data = XDataCenter.ItemManager.GetItem(self:GetItemData(index).ItemId)
    XLuaUiManager.Open("UiTip", data)
end

function XUiGachaAlphaBuyTicket:OnBtnBuyClick(index)
    -- CD检测
    if not self:CheckBuyCD() then
        XUiManager.TipError(CS.XTextManager.GetText("BuySpeedLimit"))
        return
    end

    -- 购买上限检测
    if XDataCenter.GachaManager.GetCurExchangeItemCount(self._GachaCfg.Id) + self._BuyAmount > self._GachaBuyTicketRuleConfig.TotalBuyCountMax then
        XUiManager.TipError(CS.XTextManager.GetText("BuyItemCountLimit", XDataCenter.ItemManager.GetItemName(self._GachaCfg.ConsumeId)))
        self:Close()
        return
    end

    -- 检查物品数量是否足够，不够弹出购买
    local currItemData = self:GetItemData(index)
    local itemId = currItemData.ItemId
    local currentCount = XDataCenter.ItemManager.GetCount(itemId)
    local needCount = currItemData.CostNum * (self._BuyAmount or 1)
    if currentCount < needCount then
        if itemId == XDataCenter.ItemManager.ItemId.FreeGem or itemId == XDataCenter.ItemManager.ItemId.PaidGem then
            XUiManager.TipError(CS.XTextManager.GetText("MoeWarDailyVoteItemNotEnoughTip", XDataCenter.ItemManager.GetItemName(itemId)))
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
        elseif itemId == XDataCenter.ItemManager.ItemId.HongKa then
            XUiManager.TipError(CS.XTextManager.GetText("MoeWarDailyVoteItemNotEnoughTip", XDataCenter.ItemManager.GetItemName(itemId)))
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

    -- 购买协议
    XDataCenter.GachaManager.BuyTicket(self._GachaCfg.Id, self._BuyAmount, index - 1, function(rewardList)
        -- index-1 服务器下标0开始
        self:Refresh()
        -- 购买后再次检测上限，如果达到了上限则关掉界面
        if XDataCenter.GachaManager.GetCurExchangeItemCount(self._GachaCfg.Id) >= self._GachaBuyTicketRuleConfig.TotalBuyCountMax then
            XUiManager.TipError(CS.XTextManager.GetText("BuyItemCountLimit", XDataCenter.ItemManager.GetItemName(self._GachaCfg.ConsumeId)))
            self:Close()
        end
        XUiManager.OpenUiObtain(rewardList)
    end)
end

function XUiGachaAlphaBuyTicket:CheckBuyCD()
    local nowTime = XTime.GetServerNowTimestamp() -- 使用目标时间点做标记来替代计时器
    -- 第一次必定可以请求
    if not self._TargetCanBuyTimestamp then
        self._TargetCanBuyTimestamp = nowTime + self._CDTime
        return true
    end

    local leftTime = self._TargetCanBuyTimestamp - nowTime
    if leftTime >= 0 then
        return false
    end

    self._TargetCanBuyTimestamp = nowTime + self._CDTime
    return true
end

return XUiGachaAlphaBuyTicket