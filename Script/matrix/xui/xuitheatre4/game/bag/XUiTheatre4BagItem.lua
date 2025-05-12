local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTheatre4PropCard = require("XUi/XUiTheatre4/Common/XUiGridTheatre4PropCard")
---@class XUiTheatre4BagItem : XUiNode
---@field private _Control XTheatre4Control
local XUiTheatre4BagItem = XClass(XUiNode, "XUiTheatre4BagItem")

function XUiTheatre4BagItem:OnStart()
    self.GridPropCard.gameObject:SetActiveEx(false)
    self.PanelNone.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

---@param itemDataList { UId:number, ItemId:number }[]
---@param uid number 藏品唯一Id
function XUiTheatre4BagItem:Refresh(itemDataList, uid)
    self.ItemDataList = itemDataList
    self.UId = uid
    self:RefreshNum()
    self:RefreshAffixInfo()
    self:SetupDynamicTable()
end

-- 刷新藏品数量和上限
function XUiTheatre4BagItem:RefreshNum()
    local count, limit = self._Control:GetItemCountAndLimit()
    self.TxtNum.text = count
    self.TxtTotal.text = string.format("/%s", limit)
end

-- 刷新词缀信息
function XUiTheatre4BagItem:RefreshAffixInfo()
    local affix = self._Control:GetAffix()
    local icon = self._Control:GetAffixIcon(affix)
    if icon then
        self.ImgStartEffect:SetSprite(icon)
    end
    self.TxtName.text = self._Control:GetAffixName(affix)
    self.TxtDetail.text = self._Control:GetAffixDesc(affix)
end

function XUiTheatre4BagItem:InitDynamicTable()
    self.PanelListProp.gameObject:SetActiveEx(true)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelListProp)
    self.DynamicTable:SetProxy(XUiGridTheatre4PropCard, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiTheatre4BagItem:SetupDynamicTable()
    self.DataList = self:GetItemList()
    if XTool.IsTableEmpty(self.DataList) then
        self.PanelNone.gameObject:SetActiveEx(true)
        return
    end
    local index = self:GetDefaultSelectIndex()

    self._IsRefreshing = true
    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync(index)
end

-- 获取道具列表
function XUiTheatre4BagItem:GetItemList()
    local itemList = {}
    local type = XEnumConst.Theatre4.AssetType.Item
    for i, v in pairs(self.ItemDataList) do
        itemList[i] = { UId = v.UId, Id = v.ItemId, Type = type }
    end
    return itemList
end

-- 获取默认选中的Index
function XUiTheatre4BagItem:GetDefaultSelectIndex()
    if not XTool.IsNumberValid(self.UId) then
        return 1
    end
    for i, v in pairs(self.ItemDataList) do
        if v.UId == self.UId then
            return i
        end
    end
    return 1
end

---@param grid XUiGridTheatre4PropCard
function XUiTheatre4BagItem:OnDynamicTableEvent(event, index, grid)
    if grid == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetAlpha(0)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self._IsRefreshing then
            grid:SetAlpha(0)
        end
        grid:Refresh(self.DataList[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlayPropAnimation()
        self._IsRefreshing = false
    end
end

function XUiTheatre4BagItem:PlayPropAnimation()
    local grids = self.DynamicTable:GetGrids()
    if XTool.IsTableEmpty(grids) then
        return
    end
    local startIndex = self.DynamicTable:GetStartIndex()
    XLuaUiManager.SetMask(true, "XUiTheatre4BagItem")
    RunAsyn(function()
        for i = startIndex, table.nums(grids) + startIndex - 1 do
            local grid = grids[i]
            if grid then
                grid:PlayPropCardAnimation()
                asynWaitSecond(0.04)
            end
        end
        XLuaUiManager.SetMask(false, "XUiTheatre4BagItem")
    end)
end

return XUiTheatre4BagItem
