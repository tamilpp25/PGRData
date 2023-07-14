local Next = _G.next
local XUiPurchaseHKExchange = require("XUi/XUiPurchase/XUiPurchaseHKExchange") 
local XUiPurchaseHKExchangeTop = XClass(XUiPurchaseHKExchange, "XUiPurchaseHKExchangeTop")
local defaultHKButtonGroupIndex = 1

function XUiPurchaseHKExchangeTop:Ctor(ui, uiRoot, notEnoughCb)
    self.IsShowBuyTipDataId = nil
    self.PanelPurchaseDh.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClicked)
    --v1.27 默认选项为1
    self.CurrentIndex = defaultHKButtonGroupIndex
end

function XUiPurchaseHKExchangeTop:OnRefresh(uiType)
    self.IsShowBuyTipDataId = nil
    self.PanelPurchaseDh.gameObject:SetActiveEx(false)
    XUiPurchaseHKExchangeTop.Super.OnRefresh(self, uiType)
end

-- [监听动态列表事件]
function XUiPurchaseHKExchangeTop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        grid:OnRefresh(data)
        if index == self.CurrentIndex then
            self:SetListItemActive(index, grid, data)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local data = self.ListData[index]
        self:SetListItemActive(index, grid, data)
        self.CurrentIndex = index
    end
end

function XUiPurchaseHKExchangeTop:SetListItemState(index)
    for i = 1, #self.ListData do
        local item = self.DynamicTable:GetGridByIndex(i)
        if item and i ~= index then
            item:SetSelectStatus(false)
        end
    end
end

function XUiPurchaseHKExchangeTop:SetListItemActive(index, grid, data)
    self.CurrentData = data
    self:RefreshBuyInfo(data)
    CS.XAudioManager.PlaySound(1011)
    -- 处理切换点击状态
    self:SetListItemState(index)
    if self.IsShowBuyTipDataId == nil then
        self.PanelPurchaseDh.gameObject:SetActiveEx(true)
        grid:SetSelectStatus(true)
        self.IsShowBuyTipDataId = data.Id
        return
    end
    if self.IsShowBuyTipDataId == data.Id then
        self.PanelPurchaseDh.gameObject:SetActiveEx(false)
        grid:SetSelectStatus(false)
        self.IsShowBuyTipDataId = nil
        return
    end
    self.PanelPurchaseDh.gameObject:SetActiveEx(true)
    grid:SetSelectStatus(true)
    self.IsShowBuyTipDataId = data.Id
end

function XUiPurchaseHKExchangeTop:RefreshBuyInfo(data)
    local getCount = 0 -- 获得的物品数量
    local getName = data.Name -- 获得的物品名称
    -- 直接获得的道具
    local rewardGoods = data.RewardGoodsList or {}
    -- 首充获得物品
    local firstRewardGoods = data.FirstRewardGoods or {}
    -- 额外获得
    local extraRewardGoods = data.ExtraRewardGoods or {}
    if rewardGoods[1] then
        getCount = rewardGoods[1].Count
        getName = XDataCenter.ItemManager.GetItemName(rewardGoods[1].TemplateId)
    end
    if Next(extraRewardGoods) ~= nil then
        getCount = getCount + extraRewardGoods.Count
    end
    if Next(firstRewardGoods) ~= nil then
        getCount = getCount + firstRewardGoods.Count
    end
    self.TxtTips.text = XUiHelper.GetText("ShopExchangeTip", data.ConsumeCount
        , XDataCenter.ItemManager.GetItemName(data.ConsumeId)
        , getName
        , getCount)
end

function XUiPurchaseHKExchangeTop:OnBtnBuyClicked()
    if self.CurrentData.ConsumeCount > XDataCenter.ItemManager.GetCount(self.CurrentData.ConsumeId) then
        XUiManager.TipText("PurchaseBuyHongKaCountTips")
        if self.NotEnoughCb then
            self.NotEnoughCb(XPurchaseConfigs.TabsConfig.Pay)
        end
        return
    end
    if self.CurrentData and self.CurrentData.Id then
        self:ReqBuy(self.CurrentData.Id)
    end
    -- self.HKExchangeUi:OnRefresh(self.CurrentData)
end


return XUiPurchaseHKExchangeTop