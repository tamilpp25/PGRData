local XUiPurchasePay = XClass(nil, "XUiPurchasePay")
local TextManager = CS.XTextManager
local Next = _G.next
local XUiPurchasePayListItem = require("XUi/XUiPurchase/XUiPurchasePayListItem")
local TabExConfig

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

function XUiPurchasePay:Ctor(ui, uiRoot, tab)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.Tab = tab
    TabExConfig = XPurchaseConfigs.TabExConfig
    XTool.InitUiObject(self)
    self:Init()
end

function XUiPurchasePay:OnUpdate()
    if self.CurUitype then
        self:OnRefresh(self.CurUitype)
    end
end

-- 更新数据
function XUiPurchasePay:OnRefresh(uiType)
    self.CurUitype = uiType
    self.CurState = false
    self.PanelPurchase.gameObject:SetActive(false)
    local data = XDataCenter.PurchaseManager.GetDatasByUiType(uiType) or {}
    self.GameObject:SetActive(true)
    self.Len = #data or 0
    if Next(data) then
        table.sort(data, XUiPurchasePay.SortFun)
    end
    self.ListData = data
    --XLog.Warning("XUiPurchasePay:OnRefresh",data)
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

function XUiPurchasePay:OnUpdate()
    if self.CurUitype then
        self:OnRefresh(self.CurUitype)
    end
end

function XUiPurchasePay:HidePanel()
    self.GameObject:SetActive(false)
    self.CurState = false
    XEventManager.RemoveEventListener(XEventId.EVENT_PURCAHSE_BUYUSERIYUAN, self.OnUpdate, self)
    self.PanelPurchase.gameObject:SetActive(false)
end

function XUiPurchasePay:ShowPanel()
    XEventManager.AddEventListener(XEventId.EVENT_PURCAHSE_BUYUSERIYUAN, self.OnUpdate, self)
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
    if not XDataCenter.PayManager.CheckCanBuy(self.SelectId) then
        return
    end
    
    local key
    if self.PayKeySuffix == nil then
        if self.BuyKey then
            XDataCenter.PayManager.Pay(self.BuyKey)
            return
        end
        XLog.Error("配置出错，检查PurcahseItem表中PayKeySuffix,或者是否是购买虹卡")
        return
    end

    if Platform == RuntimePlatform.Android then
        key = string.format("%s%s", XPayConfigs.GetPlatformConfig(1), self.PayKeySuffix)
    else
        key = string.format("%s%s", XPayConfigs.GetPlatformConfig(2), self.PayKeySuffix)
    end
    XDataCenter.PayManager.Pay(key, 1, { self.SelectId }, self.SelectId)
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
        if self.CurItemIndex == index then
            grid:OnSelectState(self.CurState)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
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
        if data.PayKeySuffix then
            price = self:GetPayAmount(data)
            name = TextManager.GetText("PurchaseBuyHeiKaName")
            self.BuyKey = data.Key
            self.PayKeySuffix = data.PayKeySuffix
            self.SelectId = data.Id
            self.TxtTips.text = TextManager.GetText("PusrchaseBuyTips", price, name)
        else
            self.BuyKey = data.Key
            self.TxtTips.text = TextManager.GetText("PusrchaseBuyTips",price,name)
        end
        
        

        
        CS.XAudioManager.PlaySound(1011)
    end
end

function XUiPurchasePay:GetPayAmount(data)
    local key
    if Platform == RuntimePlatform.Android then
        key = string.format("%s%d", XPayConfigs.GetPlatformConfig(1), data.PayKeySuffix)
    else
        key = string.format("%s%d", XPayConfigs.GetPlatformConfig(2), data.PayKeySuffix)
    end

    local payConfig = XPayConfigs.GetPayTemplate(key)
    return payConfig and payConfig.Amount or 0
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