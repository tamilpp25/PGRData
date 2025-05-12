local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPurchaseHKExchange = XClass(nil, "XUiPurchaseHKExchange")
local Next = _G.next
local XUiPurchaseHKExchangeListItem = require("XUi/XUiPurchase/XUiPurchaseHKExchangeListItem")
local XUiPurchaseHKExchangeTips = require("XUi/XUiPurchase/XUiPurchaseHKExchangeTips")

function XUiPurchaseHKExchange:Ctor(ui, uiRoot, notEnoughCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.NotEnoughCb = notEnoughCb
    XTool.InitUiObject(self)
    self:Init()
end

-- 更新数据
function XUiPurchaseHKExchange:OnRefresh(uiType)
    local data = XDataCenter.PurchaseManager.GetDatasByUiType(uiType)
    if not data then
        return
    end

    self.CurUiType = uiType
    self.GameObject:SetActive(true)
    if Next(data) ~= nil then
        table.sort(data, XUiPurchaseHKExchange.SortFun)
    end
    self.ListData = data
    self.DynamicTable:SetDataSource(data)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiPurchaseHKExchange.SortFun(a, b)
    return a.Priority < b.Priority
end

function XUiPurchaseHKExchange:OnUpdate()
    if self.CurUiType then
        self:OnRefresh(self.CurUiType)
    end
end

function XUiPurchaseHKExchange:HidePanel()
    self.GameObject:SetActive(false)
end

function XUiPurchaseHKExchange:ShowPanel()
    self.GameObject:SetActive(true)
end

function XUiPurchaseHKExchange:Init()
    self:InitExchangeList()
    self.HKExchangeUi = XUiPurchaseHKExchangeTips.New(self.PaneHkExChangeTips, self)
    self.UpdateCb = function() self:OnUpdate() end
end

function XUiPurchaseHKExchange:InitExchangeList()
    self.DynamicTable = XDynamicTableNormal.New(self.Transform, self)
    self.DynamicTable:SetProxy(XUiPurchaseHKExchangeListItem)
    self.DynamicTable:SetDelegate(self)
end

function XUiPurchaseHKExchange:ReqBuy(id)
    XDataCenter.PurchaseManager.PurchaseRequest(id, self.UpdateCb)
end

-- [监听动态列表事件]
function XUiPurchaseHKExchange:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiRoot, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        grid:OnRefresh(data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local data = self.ListData[index]
        self.HKExchangeUi:OnRefresh(data)
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, 1011)
    end
end

return XUiPurchaseHKExchange