local XUiRiftPluginShopItem = require("XUi/XUiRift/XUiRiftPluginShopItem")
local XUiRiftPluginShopGrid = require("XUi/XUiRift/Grid/XUiRiftPluginShopGrid")

local XUiRiftPluginShop = XLuaUiManager.Register(XLuaUi, "UiRiftPluginShop")

local ScreenAll = CS.XTextManager.GetText("ScreenAll")

function XUiRiftPluginShop:OnAwake()
    self.SelectTag = nil
    self:AddListener()
    self:InitDropDown()
    self:InitDynamicTable()
    self:InitAssets()
    self:InitTimes()
    self.ShopItemPanel = XUiRiftPluginShopItem.New(self.PanelShopItem, self)

    self.GridShop.gameObject:SetActiveEx(false)
    self.PanelShopItem.gameObject:SetActiveEx(false)
end

function XUiRiftPluginShop:OnStart()
    self.SelectTag = ScreenAll
end

function XUiRiftPluginShop:OnEnable()
    self.Super.OnEnable(self)
    self:UpdateAssets()
    self:UpdateShop()
end

function XUiRiftPluginShop:AddListener()
    self.BtnBack.CallBack = function()
        self:Close()
    end
end

function XUiRiftPluginShop:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiRiftPluginShopGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiRiftPluginShop:InitAssets()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelActivityAsset)
    XDataCenter.ItemManager.AddCountUpdateListener(
        {XDataCenter.ItemManager.ItemId.RiftGold},
        handler(self, self.UpdateAssets),
        self.AssetActivityPanel
    )
end

function XUiRiftPluginShop:UpdateAssets()
    self.AssetActivityPanel:Refresh({XDataCenter.ItemManager.ItemId.RiftGold})
end

function XUiRiftPluginShop:UpdateShop()
    local shopGoods = XDataCenter.RiftManager.FilterPluginShopGoodList(self.SelectTag)
    self.ShopGoods = shopGoods
    self.DynamicTable:SetDataSource(shopGoods)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiRiftPluginShop:InitDropDown()
    self.SelectTag = ScreenAll
    self.TagList = XDataCenter.RiftManager.GetPluginShopTagList()

    local Dropdown = CS.UnityEngine.UI.Dropdown
    self.DropFilter:ClearOptions()
    self.DropFilter.captionText.text = ScreenAll
    for _, tag in pairs(self.TagList) do
        local op = Dropdown.OptionData()
        op.text = tag
        self.DropFilter.options:Add(op)
    end
    self.DropFilter.value = 0

    self.DropFilter.onValueChanged:AddListener(function()
        self.SelectTag = self.DropFilter.captionText.text
        self:UpdateShop()
    end)
end

function XUiRiftPluginShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopGoods[index]
        grid:Refresh(data)
    end
end

function XUiRiftPluginShop:OnClickGridBuy(goodData)
    self.ShopItemPanel:Refresh(goodData)
end

function XUiRiftPluginShop:RefreshBuy()
    self:UpdateShop()
end

function XUiRiftPluginShop:InitTimes()
    self:SetAutoCloseInfo(XDataCenter.RiftManager.GetActivityEndTime(), function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end
