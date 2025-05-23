local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
local XUiPanelItemList = XClass(nil, "XUiPanelItemList")

function XUiPanelItemList:Ctor(ui, parent,rootUi, uiParams, refreshCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Ui = ui
    self.Parent = parent
	self.RootUi = rootUi or parent
    self.UiParams = uiParams
    self.RefreshCb = refreshCb
    self.GoodsList = {}
    self.GoodsContainer = {}
    self.GoodsOrder = {}
    self:SetCountUpdateListener()
    self:Init()
end

function XUiPanelItemList:SetCountUpdateListener()
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.FreeGem, function() self:RefreshGoodsPrice() end, self.Ui)
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.Coin,function() self:RefreshGoodsPrice() end, self.Ui)
end

function XUiPanelItemList:RefreshGoodsPrice()
    for _,v in pairs(self.DynamicTable:GetGrids()) do
        v:RefreshPrice()
    end
end

function XUiPanelItemList:Init()
    XTool.InitUiObject(self)
    self.DynamicTable = XDynamicTableNormal.New(self.Transform)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelItemList:HidePanel()
    if not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(false)
    end
end

function XUiPanelItemList:ShowPanel(id)
    self.GameObject:SetActive(true)
    self.GoodsList = XShopManager.GetShopGoodsList(id)

    self:ShowGoods()
    self.DynamicTable:SetDataSource(self.GoodsList)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelItemList:ShowScreenPanel(shopId,groupId,selectTag,isKeepOrder)
    local shopShowTypeCfg = XShopConfigs.GetShopShowTypeTemplateById(shopId)
    if not shopShowTypeCfg or shopShowTypeCfg.ShowType == XShopConfigs.ShowType.Normal then
        self.GameObject:SetActive(true)
        self.GoodsList = XShopManager.GetScreenGoodsListByTag(shopId,groupId,selectTag)
        if isKeepOrder then
            self:SortByOldGoodsOrder()
        else
            self:SaveGoodsOrder()
        end
        self:ShowGoods()
        self.DynamicTable:SetDataSource(self.GoodsList)
        self.DynamicTable:ReloadDataASync()
    else
        self.GameObject:SetActive(false)
    end
end


--动态列表事件
function XUiPanelItemList:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.Parent,self.RootUi, self.UiParams)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.GoodsList[index]
        grid:UpdateData(data, self.UiParams, self.Parent:GetCurShopId())
        if self.RefreshCb then
            self.RefreshCb(grid, index)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

--初始化列表
function XUiPanelItemList:ShowGoods()
    --商品数量显示
    if not self.GoodsList or #self.GoodsList <= 0 then
        if self.TxtDesc then
            self.TxtDesc.gameObject:SetActive(true)
        end
        if self.TxtHint then
            self.TxtHint.text = CS.XTextManager.GetText("ShopNoGoodsDesc")
        end
    else
        if self.TxtDesc then
            self.TxtDesc.gameObject:SetActive(false)
        end
        if self.TxtHint then
            self.TxtHint.text = ""
        end
    end

    --self:UpdateGoods()
end

--更新商品信息
function XUiPanelItemList:UpdateGoods(goodsId)
    for k, v in pairs(self.GoodsList) do
        if v.Id == goodsId then
            local grid = self.DynamicTable:GetGridByIndex(k)
            grid:UpdateData(v)
        end
    end
end

function XUiPanelItemList:SaveGoodsOrder()
    self.GoodsOrder = {}
    XShopManager.SaveGoodsOrder(self.GoodsList, self.GoodsOrder)
end

function XUiPanelItemList:SortByOldGoodsOrder()
    self.GoodsList = XShopManager.SortByOldGoodsOrder(self.GoodsList, self.GoodsOrder)
end

return XUiPanelItemList