local XUiGridTheatre4BagProp = require("XUi/XUiTheatre4/Game/Bag/XUiGridTheatre4BagProp")
local XUiGridTheatre4BagPropCard = require("XUi/XUiTheatre4/Game/Bag/XUiGridTheatre4BagPropCard")
---@class XUiTheatre4BagProp : XUiNode
---@field _Control XTheatre4Control
local XUiTheatre4BagProp = XClass(XUiNode, "XUiTheatre4BagProp")

function XUiTheatre4BagProp:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    self.GridPropCard.gameObject:SetActiveEx(false)
    self.PanelProp.gameObject:SetActiveEx(false)
    self.PanelNone.gameObject:SetActiveEx(false)
    ---@type XUiGridTheatre4BagProp[]
    self.PanelPropList = {}
    ---@type XUiGridTheatre4BagPropCard
    self.GridPropCardUi = false
    -- 当前选择的道具
    ---@type XUiGridTheatre4Prop
    self.CurSelectPropGrid = false
end

function XUiTheatre4BagProp:OnDisable()
    self:ClosePropCard()
end

---@param propDataList { UId:number, ItemId:number }[]
function XUiTheatre4BagProp:Refresh(propDataList)
    self.PropDataList = propDataList
    self:RefreshNum()
    self:RefreshPropGridList()
end

-- 刷新道具数量和总数
function XUiTheatre4BagProp:RefreshNum()
    self.TxtNum.text = table.nums(self.PropDataList)
    local total = self._Control:GetItemIsPropCount()
    self.TxtNumTotal.text = string.format("/%s", total)
end

function XUiTheatre4BagProp:RefreshPropGridList()
    self.PropGridDataList = self:GetPropGridDataList()
    if XTool.IsTableEmpty(self.PropGridDataList) then
        self.PanelNone.gameObject:SetActiveEx(true)
        return
    end
    local index = 1
    self.PanelNone.gameObject:SetActiveEx(false)
    for itemType, propList in pairs(self.PropGridDataList) do
        local grid = self.PanelPropList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.PanelProp, self.PropContent)
            grid = XUiGridTheatre4BagProp.New(go, self)
            self.PanelPropList[index] = grid
        end
        grid:Open()
        grid:Refresh(itemType, propList)
        index = index + 1
    end
    for i = index, #self.PanelPropList do
        self.PanelPropList[i]:Close()
    end
end

---@param grid XUiGridTheatre4Prop
function XUiTheatre4BagProp:OnPropGridClick(grid)
    if not self.CurSelectPropGrid or self.CurSelectPropGrid:GetUId() ~= grid:GetUId() then
        if self.CurSelectPropGrid then
            self.CurSelectPropGrid:SetSelect(false)
        end
        self.CurSelectPropGrid = grid
        self.CurSelectPropGrid:SetSelect(true)
        self:OpenPropCard(grid:GetItemData())
    end
end

function XUiTheatre4BagProp:GetPropGridDataList()
    if XTool.IsTableEmpty(self.PropDataList) then
        return nil
    end
    local typeToPropDataList = {}
    local type = XEnumConst.Theatre4.AssetType.Item
    for i, v in pairs(self.PropDataList) do
        local itemType = self._Control:GetItemType(v.ItemId)
        typeToPropDataList[itemType] = typeToPropDataList[itemType] or {}
        typeToPropDataList[itemType][i] = { UId = v.UId, Id = v.ItemId, Type = type }
    end
    return typeToPropDataList
end

-- 打开道具卡片
function XUiTheatre4BagProp:OpenPropCard(data)
    if not self.GridPropCardUi then
        ---@type XUiGridTheatre4BagPropCard
        self.GridPropCardUi = XUiGridTheatre4BagPropCard.New(self.GridPropCard, self)
    end
    self.GridPropCardUi:Open()
    self.GridPropCardUi:Refresh(data)
    self.BtnClose.gameObject:SetActiveEx(true)
end

-- 关闭道具卡片
function XUiTheatre4BagProp:ClosePropCard()
    if self.CurSelectPropGrid then
        self.CurSelectPropGrid:SetSelect(false)
        self.CurSelectPropGrid = false
    end
    if self.GridPropCardUi then
        self.GridPropCardUi:Close()
    end
    self.BtnClose.gameObject:SetActiveEx(false)
end

function XUiTheatre4BagProp:OnBtnCloseClick()
    self:ClosePropCard()
end

return XUiTheatre4BagProp
