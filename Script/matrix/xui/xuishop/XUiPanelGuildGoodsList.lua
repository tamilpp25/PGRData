
local XUiPanelGuildGoodsList = XClass(nil, "XUiPanelGuildGoodsList")
local XUiGridGuildGoodsShop = require("XUi/XUiShop/XUiGridGuildGoodsShop")

function XUiPanelGuildGoodsList:Ctor(ui, uiShop)
    XTool.InitUiObjectByUi(self, ui)
    self.UiShop = uiShop
    self.GoodsOrder = {}
    self.GoodsList = {}
    self:InitUi()
    self:InitCb()
end

function XUiPanelGuildGoodsList:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.Transform)
    self.DynamicTable:SetProxy(XUiGridGuildGoodsShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelGuildGoodsList:InitCb()
    
end

function XUiPanelGuildGoodsList:HidePanel()
    if not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(false)
    end
    
    XEventManager.RemoveEventListener(XEventId.EVENT_GUILD_GOODS_COIN_CHANGED, self.RefreshBuy, self)
end

function XUiPanelGuildGoodsList:ShowScreenPanel(shopId, groupId, selectTag, isKeepOrder)
    XEventManager.AddEventListener(XEventId.EVENT_GUILD_GOODS_COIN_CHANGED, self.RefreshBuy, self)
    local shopShowTypeCfg = XShopConfigs.GetShopShowTypeTemplateById(shopId)
    if shopShowTypeCfg and shopShowTypeCfg.ShowType == XShopConfigs.ShowType.GuildScene then
        self.GoodsList = XShopManager.GetScreenGoodsListByTag(shopId, groupId, selectTag)
        self.GameObject:SetActiveEx(true)
        if isKeepOrder then
            self:SortByOldGoodsOrder()
        else
            self:SaveGoodsOrder()
        end
        self:ShowGoods()
        self:SetupDynamicTable()
    else
        self:HidePanel()
    end
end

function XUiPanelGuildGoodsList:SetupDynamicTable()
    if not self.DynamicTable then
        return
    end
    self.DynamicTable:SetDataSource(self.GoodsList)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelGuildGoodsList:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.UiShop)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.GoodsList[index])
    end
end

function XUiPanelGuildGoodsList:SaveGoodsOrder()
    self.GoodsOrder = {}
    XShopManager.SaveGoodsOrder(self.GoodsList, self.GoodsOrder)
end

function XUiPanelGuildGoodsList:SortByOldGoodsOrder()
    self.GoodsList = XShopManager.SortByOldGoodsOrder(self.GoodsList, self.GoodsOrder)
end

function XUiPanelGuildGoodsList:ShowGoods()
    local empty = XTool.IsTableEmpty(self.GoodsList)
    self.TxtDesc.gameObject:SetActive(empty)
    self.TxtHint.text = empty and CS.XTextManager.GetText("ShopNoGoodsDesc") or ""
end

function XUiPanelGuildGoodsList:RefreshBuy()
    if self.UiShop then
        self.UiShop:RefreshBuy()
    end
end

return XUiPanelGuildGoodsList