local Object = CS.UnityEngine.Object
local XUiPurchaseHK = XClass(nil, "XUiPurchaseHK")
local TextManager = CS.XTextManager
local TabConfig = {
    Exchange = 1,
    Shop = 2
}
local XUiPurchaseHKShop = require("XUi/XUiPurchase/XUiPurchaseHKShop")
local XUiPurchaseHKExchange = require("XUi/XUiPurchase/XUiPurchaseHKExchange")

function XUiPurchaseHK:Ctor(ui)
    self.CurState = false
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:Init()
end

-- 更新数据
function XUiPurchaseHK:OnRefresh()
    --测试
    local data = {}
    if not data then
        return
    end

    self.Data = data
    self:TabSkip(TabConfig.Exchange)
    self.TabGroup:SelectIndex(TabConfig.Exchange)
end

function XUiPurchaseHK:Init()
    local tabBtns = {}
    local tabText = { TextManager.GetText("PurchaseYKExChangeTab"), TextManager.GetText("PurchaseYKShopTab") }
    self.TabGroup = self.PanelHkdhTabGroup:GetComponent("XUiButtonGroup")
    for k, v in pairs(tabText) do
        local btn = Object.Instantiate(self.BtnHkTab)
        btn.gameObject:SetActive(true)
        btn.transform:SetParent(self.PanelHkdhTabGroup.transform, false)
        local btncs = btn:GetComponent("XUiButton")
        btncs:SetName(v)
        tabBtns[k] = btncs
    end
    self.TabGroup:Init(tabBtns, function(tab) self:TabSkip(tab) end)

    self.TabEnterSkip = {}
    self.TabEnterSkip[TabConfig.Exchange] = function() self:OpenExchange() end
    self.TabEnterSkip[TabConfig.Shop] = function() self:OpenHKShop() end

    self.UiTabs = {}
    self.UiTabs[TabConfig.Exchange] = XUiPurchaseHKExchange.New(self.PanelDh)
    self.UiTabs[TabConfig.Shop] = XUiPurchaseHKShop.New(self.PanelHksd)
end

function XUiPurchaseHK:TabSkip(tab)
    if tab == self.CurTab then
        return
    end

    self.CurTab = tab

    if self.TabEnterSkip[tab] then
        self.TabEnterSkip[tab]()
    end
end

-- 黑卡商店
function XUiPurchaseHK:OpenHKShop()
    local data = XDataCenter.PurchaseManager.GetHKShopData()
    -- if data then
        -- return
    -- end

    self.PanelDh.gameObject:SetActive(false)
    self.PanelHksd.gameObject:SetActive(true)
    self.UiTabs[TabConfig.Shop]:OnRefresh(data)
end

-- 兑换
function XUiPurchaseHK:OpenExchange()
    local data = XDataCenter.PurchaseManager.GetHKDHData()
    -- if not data then
        -- return
    -- end

    self.PanelDh.gameObject:SetActive(true)
    self.PanelHksd.gameObject:SetActive(false)
    self.UiTabs[TabConfig.Exchange]:OnRefresh(data)
end

return XUiPurchaseHK