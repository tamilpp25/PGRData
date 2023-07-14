local XUiGridWaferSelect = require("XUi/XUiFubenDailyShop/XUiGridWaferSelect")

local XUiWaferSelect = XLuaUiManager.Register(XLuaUi, "UiWaferSelect")

function XUiWaferSelect:OnAwake()
    self:InitComponent()
    self:InitDynamicTable()
end

function XUiWaferSelect:OnStart(suitId, ShopItemList, suitShopItemDic, selectCallBack)
    if not suitId then
        return
    end

    self.CurSuitId = suitId
    self.ShopItemList = ShopItemList
    self.SuitShopItemDic = suitShopItemDic
    self.SelectCallBack = selectCallBack

    self.ShopPageList = {}
    for k, _ in pairs(suitShopItemDic) do
        table.insert(self.ShopPageList, k)
    end

    self:UpdateGridList()
end

function XUiWaferSelect:InitComponent()
    self.BtnConfirm.CallBack = function() self:OnBtnConfirmClick() end
    self.BtnClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnCancel.CallBack = function() self:OnBtnCloseClick() end
    self.BtnTanchuangClose.CallBack = function() self:OnBtnCloseClick() end

    self.GridSuitSimple.gameObject:SetActiveEx(false)
end

function XUiWaferSelect:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelSelectList.gameObject)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridWaferSelect)
end

function XUiWaferSelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local suitId = self.ShopPageList[index]
        self:UpdateGrid(grid, suitId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local suitId = self.ShopPageList[index]
        self:OnGridClick(suitId)
    end
end

function XUiWaferSelect:OnGridClick(suitId)
    self.CurSuitId = suitId
    for k, v in ipairs(self.ShopPageList) do
        local grid = self.DynamicTable:GetGridByIndex(k)
        if grid then
            self:UpdateGrid(grid, v)
        end
    end
end

function XUiWaferSelect:UpdateGrid(grid, suitId)
    if suitId then
        local isNew = self:CheckIsNew(suitId)
        local isSelected = self.CurSuitId == suitId
        if isSelected then
            if isNew then
                XShopManager.SetDailyShopSuitNotNew(suitId)
                isNew = false
            end

            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_DAILY_SHOP_CHECK_NEW, self.ShopItemList)
        end
        grid:Refresh(suitId, isSelected, isNew)
    end
end

function XUiWaferSelect:UpdateGridList()
    self.ImgEmpty.gameObject:SetActiveEx(not self.ShopPageList or #self.ShopPageList == 0)

    self.DynamicTable:SetDataSource(self.ShopPageList)
    self.DynamicTable:ReloadDataASync()
end

function XUiWaferSelect:CheckIsNew(suitId)
    local suitShopItemList = self.SuitShopItemDic[suitId]
    return XShopManager.CheckDailyShopSuitIsNew(suitId, suitShopItemList)
end

function XUiWaferSelect:OnBtnConfirmClick()
    if self.SelectCallBack then
        self.SelectCallBack(self.CurSuitId)
    end

    self:Close()
end

function XUiWaferSelect:OnBtnCloseClick()
    self:Close()
end

return XUiWaferSelect