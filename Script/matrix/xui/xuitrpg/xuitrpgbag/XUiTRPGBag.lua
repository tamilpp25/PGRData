local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--背包
local XUiTRPGGridItem = require("XUi/XUiTRPG/XUiGridTRPGItem")
local XUiTRPGItemUsePanel = require("XUi/XUiTRPG/XUiTRPGBag/XUiTRPGItemUsePanel")

local XUiTRPGBag = XLuaUiManager.Register(XLuaUi, "UiTRPGBag")
local AllUseCharacterId = 0

function XUiTRPGBag:OnAwake()
    self:AutoAddListener()
    self:InitTabGroup()
    self.ItemUsePanel = XUiTRPGItemUsePanel.New(self.PanelPick, self, function() self:Refresh() end)
    self.ItemUsePanel:Close()

    self.GridTRPGSpecialItem.gameObject:SetActiveEx(false)

    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
    XDataCenter.ItemManager.AddCountUpdateListener(XDataCenter.ItemManager.ItemId.TRPGMoney, function()
        self.AssetActivityPanel:Refresh({XDataCenter.ItemManager.ItemId.TRPGMoney})
    end, self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh({XDataCenter.ItemManager.ItemId.TRPGMoney})
end

function XUiTRPGBag:OnStart()
    self:InitDynamicTable()
end

function XUiTRPGBag:OnEnable()
    self:Refresh()
end

function XUiTRPGBag:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiTRPGBag:InitTabGroup()
    self.CurGroupIndex = XTRPGConfigs.ItemType.Normal
    self.TabGroup = {}
    self.TabGroup[XTRPGConfigs.ItemType.Normal] = self.TabNor
    self.TabGroup[XTRPGConfigs.ItemType.Special] = self.TabSpec

    self.PanelTab:Init(self.TabGroup, function(groupIndex) self:TabGroupSkip(groupIndex) end)
    self.PanelTab:SelectIndex(self.CurGroupIndex)
end

function XUiTRPGBag:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiTRPGGridItem, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiTRPGBag:Refresh()
    self.Data = XDataCenter.TRPGManager.GetItemListByType(self.CurGroupIndex)
    self.TxtNone.gameObject:SetActiveEx(#self.Data == 0)
    self.DynamicTable:SetDataSource(self.Data)
    self.DynamicTable:ReloadDataSync()
end

function XUiTRPGBag:TabGroupSkip(groupIndex)
    if self.CurGroupIndex == groupIndex then
        return
    end
    self.CurGroupIndex = groupIndex
    self:Refresh()
end

function XUiTRPGBag:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local itemId = self.Data[index].Id
        grid:Refresh(itemId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local itemId = self.Data[index].Id
        if XTRPGConfigs.IsItemSelectCharacter(itemId) then
            self.ItemUsePanel:Open(itemId)
        else
            local itemData = {
                Data = XDataCenter.ItemManager.GetItem(itemId)
            }
            local isShowUse = XTRPGConfigs.IsItemShowUse(itemId)
            XLuaUiManager.Open("UiBagItemInfoPanel", itemData, function(itemId, selectCount)
                self:AllCharacterUseCallback(itemId, selectCount) 
            end, isShowUse)
        end
    end
end

function XUiTRPGBag:AllCharacterUseCallback(itemId, selectCount)
    local cb = function()
        self:Refresh()
    end
    XDataCenter.TRPGManager.RequestUseItemRequestSend(itemId, selectCount, AllUseCharacterId, cb)
end

function XUiTRPGBag:OnBtnBackClick()
    self:Close()
end

function XUiTRPGBag:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end