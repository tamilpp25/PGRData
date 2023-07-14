local XUiSuperTowerShop = XLuaUiManager.Register(XLuaUi, "UiSuperTowerShop")
local XUiGridSuperTowerShopItem = require("XUi/XUiSuperTower/Shop/XUiGridSuperTowerShopItem")
local SortShopItem = function(itemA, itemB)
    if not itemA.Sell and itemB.Sell then
        return true
    elseif itemA.Sell and not itemB.Sell then
        return false
    else
        return itemA.Index < itemB.Index
    end
end

function XUiSuperTowerShop:OnStart()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool)
    local itemIds = {}
    for i = 1, 3 do
        local itemId = XSuperTowerConfigs.GetClientBaseConfigByKey("CurrencyItemOther" .. i, true)
        if itemId and itemId ~= 0 then
            table.insert(itemIds, itemId)
        end
    end
    XDataCenter.ItemManager.AddCountUpdateListener(itemIds, function()
        self.AssetActivityPanel:Refresh(itemIds)
    end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh(itemIds)
    local shopManager = XDataCenter.SuperTowerManager.GetShopManager()
    local mallConfig = XSuperTowerConfigs.GetMallConfig(shopManager:GetMallId())
    XDataCenter.ItemManager.AddCountUpdateListener(mallConfig.ManualRefreshSpendItemId, function()
        self:RefreshSpendCount()
    end, self)
    if self.TxtBt and self.TxtBt2 then
        self.TxtBt.text = CSXTextManagerGetText("STShopTitle")
        self.TxtBt2.text = CSXTextManagerGetText("STShopTitle")
    end
    self:RegisterButtonEvent()
    self:RefreshTime()
    self:InitDynamicTable()
    self:SetActivityTimeLimit()
end

function XUiSuperTowerShop:OnEnable()
    XUiSuperTowerShop.Super.OnEnable(self)
    self:Refresh()
    self:StartTimer()
end

function XUiSuperTowerShop:OnDisable()
    XUiSuperTowerShop.Super.OnDisable(self)
    self:StopTimer()
end

function XUiSuperTowerShop:Refresh()
    self:SetupDynamicTable()
    self:RefreshPanel()
    self:RefreshSpendCount()
    if XLuaUiManager.IsUiShow("UiSuperTowerPluginDetails") then
        XLuaUiManager.Close("UiSuperTowerPluginDetails")
    end
end

function XUiSuperTowerShop:OnGetEvents()
    return {
        XEventId.EVENT_ST_SHOP_REFRESH
    }
end

function XUiSuperTowerShop:OnNotify(event, ...)
    if event == XEventId.EVENT_ST_SHOP_REFRESH then
        self:Refresh()
    end
end

function XUiSuperTowerShop:RegisterButtonEvent()
    self.BtnBack.CallBack = function()
        self:Close()
    end
    self.BtnRefresh.CallBack = function()
        self:OnClickBtnRefresh()
    end
end

function XUiSuperTowerShop:InitDynamicTable()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridSuperTowerShopItem)
end

function XUiSuperTowerShop:SetupDynamicTable()
    local shopManager = XDataCenter.SuperTowerManager.GetShopManager()
    self.DataList = shopManager:GetBuyList()
    table.sort(self.DataList, SortShopItem)
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiSuperTowerShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.DynamicTable.DataSource[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local shopInfo = self.DynamicTable.DataSource[index]
        if shopInfo.Sell then
            return
        end
        XLuaUiManager.Open("UiSuperTowerShopItem", shopInfo, function()
            shopInfo.Sell = true
            table.sort(self.DataList, SortShopItem)
            self:SetupDynamicTable()
            self:CheckPluginSyn()
        end)
    end
end

function XUiSuperTowerShop:OnClickBtnRefresh()
    local shopManager = XDataCenter.SuperTowerManager.GetShopManager()
    local freeRefreshCount = shopManager:GetRefreshCount()
    local mallConfig = XSuperTowerConfigs.GetMallConfig(shopManager:GetMallId())
    if freeRefreshCount >= mallConfig.FreeRefreshCount then
        local spendCount,spendItemCount = shopManager:GetSpendItemCountInfo()
        if spendItemCount < spendCount then
            XUiManager.TipText("STShopRefreshItemNotEnoughTips")
            return
        end
    end
    shopManager:RequestRefreshMall(function()
        self:Refresh()
    end)
end

function XUiSuperTowerShop:RefreshPanel()
    local shopManager = XDataCenter.SuperTowerManager.GetShopManager()
    local refreshCount = shopManager:GetRefreshCount()
    local mallConfig = XSuperTowerConfigs.GetMallConfig(shopManager:GetMallId())
    self.RImgCostItemIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(mallConfig.ManualRefreshSpendItemId))
    local remainCount = mallConfig.FreeRefreshCount - refreshCount
    self.BtnRefresh:SetName(CSXTextManagerGetText("STShopRefreshBtnText", remainCount, mallConfig.FreeRefreshCount))
    self.TxtCostItemCount.gameObject:SetActiveEx(remainCount == 0)
    self.TxtRefreshTime.gameObject:SetActiveEx(remainCount ~= mallConfig.FreeRefreshCount)
    self:RefreshTime()
end

function XUiSuperTowerShop:RefreshSpendCount()
    local shopManager = XDataCenter.SuperTowerManager.GetShopManager()
    local spendCount, spendItemCount = shopManager:GetSpendItemCountInfo()
    if spendItemCount < spendCount then
        self.TxtCostItemCount.text = CSXTextManagerGetText("STShopRefreshItemNotEnoughStyle", spendCount)
    else
        self.TxtCostItemCount.text = spendCount
    end
end

function XUiSuperTowerShop:RefreshTime()
    if XTool.UObjIsNil(self.TxtRefreshTime) then
        self:StopTimer()
        return
    end
    local shopManager = XDataCenter.SuperTowerManager.GetShopManager()
    local nextRefreshTime = shopManager:GetRefreshCd()
    local now = XTime.GetServerNowTimestamp()
    local offset = nextRefreshTime - now
    if offset < 0 then
        offset = 0
    end
    local text = CS.XTextManager.GetText("STShopRefreshTime", XUiHelper.GetTime(offset, XUiHelper.TimeFormatType.SHOP))
    self.TxtRefreshTime.text = string.gsub(text, "\\n", "\n")
end

function XUiSuperTowerShop:StartTimer()
    if self.Timer then
        self:StopTimer()
    end
    self.Timer = XScheduleManager.ScheduleForever(handler(self, self.RefreshTime), XScheduleManager.SECOND, 0)
end

function XUiSuperTowerShop:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiSuperTowerShop:CheckPluginSyn()
    local oldList, newList = XDataCenter.SuperTowerManager.GetBagManager():GetPluginSyn()
    if oldList and newList then
        XLuaUiManager.Open("UiSuperTowerPlugUp", oldList, newList, function() self:CheckPluginSyn() end)
    end
end

function XUiSuperTowerShop:SetActivityTimeLimit()
    -- 自动关闭
    local endTime = XDataCenter.SuperTowerManager.GetActivityEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
            if isClose then
                XDataCenter.SuperTowerManager.HandleActivityEndTime()
            end
        end)
end