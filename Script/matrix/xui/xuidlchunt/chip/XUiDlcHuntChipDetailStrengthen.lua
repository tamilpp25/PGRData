local XUiPanelExpBar = require("XUi/XUiSettleWinMainLine/XUiPanelExpBar")
local XUiDlcHuntChipDetailAttrCompare = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipDetailAttrCompare")
--local XUiDlcHuntChipDetailGrid = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipDetailGrid")
local XUiDlcHuntChipDetailGrid = require("XUi/XUiDlcHunt/Bag/XUiDlcHuntBagGridChip")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")

---@class XUiDlcHuntChipDetailStrengthen
local XUiDlcHuntChipDetailStrengthen = XClass(nil, "XUiDlcHuntChipDetailStrengthen")

function XUiDlcHuntChipDetailStrengthen:Ctor(ui, viewModel)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XViewModelDlcHuntChipDetail
    self._ViewModel = viewModel
    self:Init()
    self._UiAttrList = {}
end

function XUiDlcHuntChipDetailStrengthen:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnDlcBlue, self.OnClickAutoSelect)
    XUiHelper.RegisterClickEvent(self, self.BtnDlcYellow, self.OnClickStrengthen)

    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelIconDes)
    self.DynamicTable:SetProxy(XUiDlcHuntChipDetailGrid)
    self.DynamicTable:SetDelegate(self)

    self.ExpBar = XUiPanelExpBar.New(self.PanelExpBar)
end

function XUiDlcHuntChipDetailStrengthen:Update()
    self:UpdateItems()
    self:UpdateAttr()
end

function XUiDlcHuntChipDetailStrengthen:UpdateAttr()
    local data = self._ViewModel:GetData()
    self.TxtCurLv.text = data.CurLevel
    self.TxtExp.text = string.format("%s/%s", data.ExpVirtual, data.ExpMax)
    self.TxtPreExp.text = data.ExpSelectedChips
    self.ExpBar:PreviewExpBar(data.ExpReal, data.ExpMax, data.ExpVirtual)

    -- Attr
    local attrTable = data.AttrTableLevelUp
    XUiDlcHuntUtil.UpdateDynamicItem(self._UiAttrList, attrTable, self.GridPartnerPich, XUiDlcHuntChipDetailAttrCompare)
end

function XUiDlcHuntChipDetailStrengthen:UpdateItems()
    local dataSource = self._ViewModel:GetChips4LevelUp()
    self.DynamicTable:SetDataSource(dataSource)
    self.DynamicTable:ReloadDataSync(1)
    self.PanelNoIcon.gameObject:SetActiveEx(#self.DynamicTable.DataSource == 0)
    self.GridIconChip.gameObject:SetActiveEx(false)
end

---@param grid XUiDlcHuntBagGridChip
function XUiDlcHuntChipDetailStrengthen:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetViewModel(self._ViewModel)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
        
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
    end
end

function XUiDlcHuntChipDetailStrengthen:OnClickAutoSelect()
    self._ViewModel:AutoSelectChips4LevelUp()
    self:UpdateSelected()
    self:UpdateAttr()
end

function XUiDlcHuntChipDetailStrengthen:OnClickStrengthen()
    self._ViewModel:RequestLevelUp()
end

function XUiDlcHuntChipDetailStrengthen:UpdateSelected()
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:UpdateSelected()
    end
end

return XUiDlcHuntChipDetailStrengthen