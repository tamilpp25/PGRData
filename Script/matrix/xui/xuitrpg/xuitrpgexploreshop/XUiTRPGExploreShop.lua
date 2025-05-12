local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiTRPGExploreShopRewardGrid = require("XUi/XUiTRPG/XUiTRPGExploreShop/XUiTRPGExploreShopRewardGrid")

--商店
local XUiTRPGExploreShop = XLuaUiManager.Register(XLuaUi, "UiTRPGExploreShop")

function XUiTRPGExploreShop:OnAwake()
    self.GridReward.gameObject:SetActiveEx(false)
    self:InitCb()
    self:AutoAddListener()
    self:InitDynamicTable()

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.TRPGMoney, function()
        self.AssetActivityPanel:Refresh({XDataCenter.ItemManager.ItemId.TRPGMoney})
    end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh({XDataCenter.ItemManager.ItemId.TRPGMoney})
end

function XUiTRPGExploreShop:OnStart(shopId, secondAreaId, thirdAreaId)
    self.ShopId = shopId

    local secondAreaName = XTRPGConfigs.GetSecondAreaName(secondAreaId)
    local thirdAreaName = XTRPGConfigs.GetThirdAreaName(thirdAreaId)
    self.TxtName.text = secondAreaName .. "-" .. thirdAreaName .. "-" .. CSXTextManagerGetText("ShopTitle")
end

function XUiTRPGExploreShop:OnEnable()
    XDataCenter.TRPGManager.CheckActivityEnd()
    self:Refresh()
end

function XUiTRPGExploreShop:InitCb()
    self.RefreshCb = function() self:Refresh() end
end

function XUiTRPGExploreShop:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelpCourse, "TRPGMainLine")
end

function XUiTRPGExploreShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewRewardList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiTRPGExploreShopRewardGrid, self)
end

function XUiTRPGExploreShop:Refresh()
    self.ShopItemIdList = XDataCenter.TRPGManager.GetShopItemIdList(self.ShopId)
    self.DynamicTable:SetDataSource(self.ShopItemIdList)
    self.DynamicTable:ReloadDataSync()
end

function XUiTRPGExploreShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local shopItemId = self.ShopItemIdList[index]
        grid:Refresh(self.ShopId, shopItemId, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local shopItemId = self.ShopItemIdList[index]
        local canBuyCount = XDataCenter.TRPGManager.GetShopItemCanBuyCount(self.ShopId, shopItemId)
        local itemId = XTRPGConfigs.GetItemIdByShopItemId(shopItemId)
        local isItemMax = XDataCenter.TRPGManager.IsItemMaxCount(itemId)
        if isItemMax then
            XUiManager.TipText("TRPGItemMaxNumCantBuy")
        elseif canBuyCount > 0 then
            XLuaUiManager.Open("UiTRPGShopItem", self.ShopId, shopItemId, self.RefreshCb)
        else
            local resetType = XTRPGConfigs.GetItemResetType(shopItemId)
            local tipKey = resetType == XTRPGConfigs.ShopItemResetType.Reset and "TRPGShopItemOversell" or "TRPGShopItemForeverOversell"
            XUiManager.TipText(tipKey)
        end
    end
end

function XUiTRPGExploreShop:OnBtnBackClick()
    self:Close()
end

function XUiTRPGExploreShop:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTRPGExploreShop:OnGetEvents()
    return {XEventId.EVENT_TRPG_SHOP_INFO_CHANGE, XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE}
end

function XUiTRPGExploreShop:OnNotify(evt, ...)
    if evt == XEventId.EVENT_TRPG_SHOP_INFO_CHANGE then
        self:Refresh()
    elseif evt == XEventId.EVENT_ACTIVITY_MAINLINE_STATE_CHANGE then
        XDataCenter.TRPGManager.OnActivityMainLineStateChange(...)
    end
end