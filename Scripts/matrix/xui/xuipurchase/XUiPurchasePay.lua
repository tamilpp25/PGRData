local XUiPurchasePay = XClass(nil, "XUiPurchasePay")
local TextManager = CS.XTextManager
local Next = _G.next
local XUiPurchasePayListItem = require("XUi/XUiPurchase/XUiPurchasePayListItem")
local TabExConfig
local defaultPayButtonGroupIndex = 1

function XUiPurchasePay:Ctor(ui, uiRoot, tab)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.Tab = tab
    TabExConfig = XPurchaseConfigs.TabExConfig
    XTool.InitUiObject(self)
    
    -- v1.27 采购默认首位
    self.CurrentIndex = defaultPayButtonGroupIndex
    self:Init()
end

-- 更新数据
function XUiPurchasePay:OnRefresh(uiType)
    if XDataCenter.UiPcManager.IsPc() then
        XUiManager.TipText("PcRechargeCloseTip")
        XLuaUiManager.RunMain();
    end
    self.CurState = false
    self.PanelPurchase.gameObject:SetActive(false)
    
    local data = XDataCenter.PurchaseManager.GetDatasByUiType(uiType) or {}
    self.GameObject:SetActive(true)
    self.Len = #data or 0
    if Next(data) then
        table.sort(data, XUiPurchasePay.SortFun)
    end
    self.ListData = data
    self.DynamicTable:SetDataSource(data)
    self.DynamicTable:ReloadDataASync(1)
    if self.Tab == TabExConfig.Sample then
        self.UiRoot:PlayAnimation("PanelPurchaseBig")
    else
        self.UiRoot:PlayAnimation("PanelPurchaseSmall")
    end
end

function XUiPurchasePay.SortFun(a,b)
    return a.Amount < b.Amount
end

function XUiPurchasePay:HidePanel()
    self.GameObject:SetActive(false)
end

function XUiPurchasePay:ShowPanel()
    self.GameObject:SetActive(true)
end

function XUiPurchasePay:InitList()
    self.DynamicTable = XDynamicTableNormal.New(self.SviewRecharge)
    self.DynamicTable:SetProxy(XUiPurchasePayListItem)
    self.DynamicTable:SetDelegate(self)
end

function XUiPurchasePay:Init()
    self:InitList()
    self.BtnBuy.CallBack = function() self:OnBtnBuyClick() end
end

function XUiPurchasePay:OnBtnBuyClick()
    XDataCenter.PayManager.Pay(self.BuyKey)
end

function XUiPurchasePay:OnBuySuccessCB()
    self.BuyKey = nil
    XUiManager.TipText("PurchaseBuySuccessTips", XUiManager.UiTipType.Success)
end
-- [监听动态列表事件]
function XUiPurchasePay:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        grid:OnRefresh(data)
        -- v1.27 采购默认首位
        if index == self.CurrentIndex then
            self:SetListItemActive(index, grid)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:SetListItemActive(index, grid)
        self.CurrentIndex = index
    end
end

function XUiPurchasePay:SetListItemActive(index, grid)
    grid:OnClick()
    self:SetListItemState(index)
    if self.CurItemIndex ~= index or self.CurState == false then
        self.CurItemIndex = index
        self.CurState = true
        self.PanelPurchase.gameObject:SetActive(true)
    else
        self.CurState = false
        self.PanelPurchase.gameObject:SetActive(false)
    end

    local data = self.ListData[index] or {}
    local price = data.Amount or ""
    local name = data.Name or ""
    self.BuyKey = data.Key
    self.TxtTips.text = TextManager.GetText("PusrchaseBuyTips",price,name)
    CS.XAudioManager.PlaySound(1011)
end

function XUiPurchasePay:SetListItemState(index)
    for i = 1,self.Len do
        local item = self.DynamicTable:GetGridByIndex(i)
        if item and i ~= index then
            item:OnSelectState(false)
        end
    end
end

return XUiPurchasePay