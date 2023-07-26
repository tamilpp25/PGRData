local XUiEpicFashionGachaBuyTicket = XLuaUiManager.Register(XLuaUi, "UiEpicFashionGachaBuyTicket")
local PanelDic = {}
local BuyCountMax = 10
local BuyAmount = nil
-- 用于cd购买
local TargetCanBuyTimestamp = nil
local CDTime = 1

function XUiEpicFashionGachaBuyTicket:OnAwake()
    self.TargetCardPanel = {}
    XTool.InitUiObjectByUi(self.TargetCardPanel, self.TargetCard)
    self:InitItemCardPanel(1) -- 初始化两个Card
    self:InitItemCardPanel(2)
    self:InitButton()
end

function XUiEpicFashionGachaBuyTicket:InitItemCardPanel(index)
    local panel = {}
    PanelDic[index] = panel
    XTool.InitUiObjectByUi(panel, self["Card"..index])
    self:RegisterClickEvent(panel.ImgBtn, function () self:OnImgBtnClick(index) end)
    self:RegisterClickEvent(panel.BtnBuy, function () self:OnBtnBuyClick(index) end)
end

function XUiEpicFashionGachaBuyTicket:InitButton()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnMax, self.OnBtnMaxClick)
    self:RegisterClickEvent(self.BtnAddSelect, self.OnBtnAddSelectClick)
    self:RegisterClickEvent(self.BtnMinusSelect, self.OnBtnMinusSelectClick)
    self:RegisterClickEvent(self.TargetCardPanel.ImgBtn, function ()
        local data = XDataCenter.ItemManager.GetItem(self.TargetItemData.ItemId)
        XLuaUiManager.Open("UiTip", data)
    end)
    self.TxtSelect.onValueChanged:AddListener(function() self:OnSelectTextChange() end)
end

--- func desc
---@param itemData1 {ItemId, CostNum, Sale}
---@param itemData2 any
---@param targetItemData any {ItemId, CostNum, Sale}
---@param closeCb any
function XUiEpicFashionGachaBuyTicket:OnStart(gachaCfg, itemData1, itemData2, targetItemData, forceBuyCount, closeCb)
    self.GachaCfg = gachaCfg
    self.ItemData1 = itemData1
    self.ItemData2 = itemData2
    self.TargetItemData = targetItemData
    self.ForceBuyCount = forceBuyCount
    self.CloseCb = closeCb
    self.GachaBuyTicketRuleConfig = XGachaConfigs.GetGachaItemExchangeCfgById(self.GachaCfg.ExchangeId)
    BuyCountMax = self.GachaBuyTicketRuleConfig.BuyCountMax
    BuyAmount = nil
end

function XUiEpicFashionGachaBuyTicket:OnEnable()
    self:Refresh()
    if self.ForceBuyCount then -- 如果没有货币 强制设为10
        self:OnSelfSetBuyCount(self.ForceBuyCount)
    end
end

function XUiEpicFashionGachaBuyTicket:Refresh()
    self:RefreshUiShow()
    self:RefreshBuyAmount(tonumber(self.TxtSelect.text))
end

function XUiEpicFashionGachaBuyTicket:RefreshUiShow()
    for index, panel in pairs(PanelDic) do
        local currItemData = self["ItemData"..index]
        panel.Sale.gameObject:SetActiveEx(currItemData.Sale)
        panel.SaleText.text = currItemData.Sale
        local curCost = currItemData.CostNum * (BuyAmount or 1)
        panel.CostNum.text = curCost
        local curCount = XDataCenter.ItemManager.GetItem(currItemData.ItemId).Count
        if curCount < curCost then -- 不足显示红色
            curCount =  CS.XTextManager.GetText("RedText", curCount)
        end
        panel.CurNum.text = curCount
        local goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(currItemData.ItemId)
        local icon = currItemData.ItemImg or goods.BigIcon or goods.Icon
        panel.CardImg:SetRawImage(icon)
    end

    local goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.TargetItemData.ItemId)
    local icon = goods.BigIcon or goods.Icon
    self.TargetCardPanel.CardImg:SetRawImage(icon)
    -- self.TargetCardPanel.CostNum.text = self.TargetItemData.CostNum
end

function XUiEpicFashionGachaBuyTicket:RefreshBuyAmount(count)
    BuyAmount = count
end

function XUiEpicFashionGachaBuyTicket:CheckBuyAmountLimit(count)
    if type(count) ~= "number" then
        return 1
    end

    local leftCanBuy = self.GachaBuyTicketRuleConfig.TotalBuyCountMax - XDataCenter.GachaManager.GetCurExchangeItemCount(self.GachaCfg.Id)
    if count > leftCanBuy then
        if leftCanBuy <= 0 then
            leftCanBuy = 1
        end
        return leftCanBuy
    elseif count > BuyCountMax then
        return BuyCountMax
    elseif count < 1 then
        return 1
    end

    return false
end

-- 如果想要在程序直接控制文本的购买数量 只能调用该接口
function XUiEpicFashionGachaBuyTicket:OnSelfSetBuyCount(count)
    local targetCount = count
    if self:CheckBuyAmountLimit(targetCount) then
        return
    end

    self.TxtSelect.text = targetCount
end

function XUiEpicFashionGachaBuyTicket:OnBtnMaxClick()
    local targetCount = BuyCountMax
    local res = self:CheckBuyAmountLimit(targetCount)
    if res then
        targetCount = res
    end

    self.TxtSelect.text = targetCount
end

function XUiEpicFashionGachaBuyTicket:OnBtnAddSelectClick()
    local count = tonumber(self.TxtSelect.text)
    local targetCount = count + 1
    if self:CheckBuyAmountLimit(targetCount) then
        return
    end

    self.TxtSelect.text = targetCount
end

function XUiEpicFashionGachaBuyTicket:OnBtnMinusSelectClick()
    local count = tonumber(self.TxtSelect.text)
    local targetCount = count - 1
    if self:CheckBuyAmountLimit(targetCount) then
        return
    end

    self.TxtSelect.text = targetCount
end

-- text改动的回调
function XUiEpicFashionGachaBuyTicket:OnSelectTextChange()
    local count = tonumber(self.TxtSelect.text)
    local isLimitNum = self:CheckBuyAmountLimit(count)
    if isLimitNum then -- 输入超了强行改回
        self.TxtSelect.text = isLimitNum
        count = isLimitNum
    end

    self:RefreshBuyAmount(count)
    self:RefreshUiShow()
end

function XUiEpicFashionGachaBuyTicket:OnImgBtnClick(index)
    local data = XDataCenter.ItemManager.GetItem(self["ItemData"..index].ItemId)
    XLuaUiManager.Open("UiTip", data)
end

function XUiEpicFashionGachaBuyTicket:OnBtnBuyClick(index)
    -- CD检测
    if not self:CheckBuyCD() then
        XUiManager.TipError(CS.XTextManager.GetText("BuySpeedLimit"))
        return
    end

    -- 购买上限检测
    if XDataCenter.GachaManager.GetCurExchangeItemCount(self.GachaCfg.Id) + BuyAmount > self.GachaBuyTicketRuleConfig.TotalBuyCountMax then 
        XUiManager.TipError(CS.XTextManager.GetText("BuyItemCountLimit", XDataCenter.ItemManager.GetItemName(self.GachaCfg.ConsumeId)))
        self:Close()
        return
    end

    -- 检查物品数量是否足够，不够弹出购买
    local currItemData = self["ItemData"..index]
    local itemId = currItemData.ItemId
    local currentCount = XDataCenter.ItemManager.GetCount(itemId)
    local needCount = currItemData.CostNum * (BuyAmount or 1)
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
    XDataCenter.GachaManager.BuyTicket(self.GachaCfg.Id, BuyAmount, index-1, function (rewardList) -- index-1 服务器下标0开始
        self:Refresh()
        -- 购买后再次检测上限，如果达到了上限则关掉界面
        if XDataCenter.GachaManager.GetCurExchangeItemCount(self.GachaCfg.Id) >= self.GachaBuyTicketRuleConfig.TotalBuyCountMax then 
            XUiManager.TipError(CS.XTextManager.GetText("BuyItemCountLimit", XDataCenter.ItemManager.GetItemName(self.GachaCfg.ConsumeId)))
            self:Close()
        end
        XUiManager.OpenUiObtain(rewardList)
    end)
end

function XUiEpicFashionGachaBuyTicket:CheckBuyCD()
    local nowTime = XTime.GetServerNowTimestamp() -- 使用目标时间点做标记来替代计时器
    -- 第一次必定可以请求
    if not TargetCanBuyTimestamp then
        TargetCanBuyTimestamp = nowTime + CDTime
        return true
    end
    
    local leftTime = TargetCanBuyTimestamp - nowTime
    if leftTime >= 0 then
        return false
    end

    TargetCanBuyTimestamp = nowTime + CDTime
    return true
end

function XUiEpicFashionGachaBuyTicket:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end