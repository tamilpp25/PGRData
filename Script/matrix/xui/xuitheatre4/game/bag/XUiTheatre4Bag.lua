local XUiTheatre4BagItem = require("XUi/XUiTheatre4/Game/Bag/XUiTheatre4BagItem")
local XUiTheatre4BagProp = require("XUi/XUiTheatre4/Game/Bag/XUiTheatre4BagProp")
local XUiTheatre4BagBuilding = require("XUi/XUiTheatre4/Game/Bag/XUiTheatre4BagBuilding")
---@class XUiTheatre4Bag : XLuaUi
---@field private _Control XTheatre4Control
local XUiTheatre4Bag = XLuaUiManager.Register(XLuaUi, "UiTheatre4Bag")

function XUiTheatre4Bag:OnAwake()
    self:RegisterUiEvents()
    self.PanelItem.gameObject:SetActiveEx(false)
    self.PanelProp.gameObject:SetActiveEx(false)
    self.PanelBuilding.gameObject:SetActiveEx(false)
end

---@param uid number 藏品唯一Id
function XUiTheatre4Bag:OnStart(uid)
    self.UId = uid
    self.PanelBagTab:Init({ self.BtnItem, self.BtnProp, self.BtnBuilding }, function(i) self:OnSwitchTab(i) end)
    self.OwnItemDataList = self._Control:GetCountLimitItemDataList();
    self.OwnPropDataList = self._Control:GetOwnPropDataList();
    self.OwnBuildingDataList = self._Control.MapSubControl:GetOwnBuildingDataList();
    self.CurSelectIndex = 0
end

function XUiTheatre4Bag:OnEnable()
    self:UpdateGold()
    self:UpdateOwnCount()
    self.PanelBagTab:SelectIndex(1)
end

-- 刷新金币
function XUiTheatre4Bag:UpdateGold()
    -- 金币图标
    local icon = self._Control.AssetSubControl:GetAssetIcon(XEnumConst.Theatre4.AssetType.Gold)
    if icon then
        self.RImgGold:SetRawImage(icon)
    end
    -- 金币数量
    self.TxtNum.text = self._Control.AssetSubControl:GetAssetCount(XEnumConst.Theatre4.AssetType.Gold)
end

function XUiTheatre4Bag:UpdateOwnCount()
    self.BtnItem:SetNameByGroup(1, table.nums(self.OwnItemDataList))
    self.BtnProp:SetNameByGroup(1, table.nums(self.OwnPropDataList))
    self.BtnBuilding:SetNameByGroup(1, table.nums(self.OwnBuildingDataList))
end

function XUiTheatre4Bag:OnSwitchTab(index)
    if self.CurSelectIndex == index then
        return
    end
    self.CurSelectIndex = index
    self:CloseAll()
    if index == 1 then
        self:OpenItem()
    elseif index == 2 then
        self:OpenProp()
    elseif index == 3 then
        self:OpenBuilding()
    end
end

-- 关闭所有
function XUiTheatre4Bag:CloseAll()
    self:CloseItem()
    self:CloseProp()
    self:CloseBuilding()
end

-- 打开道具
function XUiTheatre4Bag:OpenItem()
    if not self.PanelItemUi then
        ---@type XUiTheatre4BagItem
        self.PanelItemUi = XUiTheatre4BagItem.New(self.PanelItem, self)
    end
    self.PanelItemUi:Open()
    self.PanelItemUi:Refresh(self.OwnItemDataList, self.UId)
end

-- 关闭道具
function XUiTheatre4Bag:CloseItem()
    if self.PanelItemUi then
        self.PanelItemUi:Close()
    end
end

-- 打开物品
function XUiTheatre4Bag:OpenProp()
    if not self.PanelPropUi then
        ---@type XUiTheatre4BagProp
        self.PanelPropUi = XUiTheatre4BagProp.New(self.PanelProp, self)
    end
    self.PanelPropUi:Open()
    self.PanelPropUi:Refresh(self.OwnPropDataList)
end

-- 关闭物品
function XUiTheatre4Bag:CloseProp()
    if self.PanelPropUi then
        self.PanelPropUi:Close()
    end
end

-- 打开建筑
function XUiTheatre4Bag:OpenBuilding()
    if not self.PanelBuildingUi then
        ---@type XUiTheatre4BagBuilding
        self.PanelBuildingUi = XUiTheatre4BagBuilding.New(self.PanelBuilding, self)
    end
    self.PanelBuildingUi:Open()
    self.PanelBuildingUi:Refresh(self.OwnBuildingDataList)
end

-- 关闭建筑
function XUiTheatre4Bag:CloseBuilding()
    if self.PanelBuildingUi then
        self.PanelBuildingUi:Close()
    end
end

function XUiTheatre4Bag:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGold, self.OnBtnGoldClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCharacter, self.OnBtnCharacterClick)
end

function XUiTheatre4Bag:OnBtnBackClick()
    self:Close()
end

function XUiTheatre4Bag:OnBtnGoldClick()
    -- 打开金币详情
    XLuaUiManager.Open("UiTheatre4PopupItemDetail", nil, XEnumConst.Theatre4.AssetType.Gold)
end

function XUiTheatre4Bag:OnBtnCharacterClick()
    -- 打开角色面板
    self._Control:OpenCharacterPanel()
end

return XUiTheatre4Bag
