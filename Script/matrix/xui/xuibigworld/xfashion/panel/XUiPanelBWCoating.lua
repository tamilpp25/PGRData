local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridBWFashion = require("XUi/XUiBigWorld/XFashion/Grid/XUiGridBWFashion")

---@class XUiPanelBWCoating : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldCoating
---@field _Control 
local XUiPanelBWCoating = XClass(XUiNode, "XUiPanelBWCoating")

function XUiPanelBWCoating:OnStart(type)
    self._Type = type
    self:InitCb()
    self:InitView()
end

function XUiPanelBWCoating:InitCb()
end

function XUiPanelBWCoating:InitView()
    self._DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetProxy(XUiGridBWFashion, self.Parent, self._Type)
end

function XUiPanelBWCoating:RefreshView(characterId, dataList, defaultSelect)
    self:Open()
    self._CharId = characterId
    self._DataList = dataList
    self._LastSelect = defaultSelect or self._LastSelect or dataList[1]
    
    self._DynamicTable:SetDataSource(self._DataList)
    self._DynamicTable:ReloadDataSync()
end

function XUiPanelBWCoating:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._CharId, self._DataList[index], self._LastSelect)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnTouchGrid(index, grid)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local temp
        local grids = self._DynamicTable:GetGrids()
        for _, g in pairs(grids) do
            if g:IsSelect() then
                temp = g
                break
            end
        end
        self._LastGrid = temp
    end
end

function XUiPanelBWCoating:OnTouchGrid(index, grid)
    if self._LastGrid == grid then
        return
    end
    if self._LastGrid then
        self._LastGrid:SetSelect(false)
    end
    local select = self._DataList[index]
    self._LastSelect = select
    self._LastGrid = grid
    grid:SetSelect(true)
    self.Parent:OnSelectItem(self._Type, select)
end

return XUiPanelBWCoating
