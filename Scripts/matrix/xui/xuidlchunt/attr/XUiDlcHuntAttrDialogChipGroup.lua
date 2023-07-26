local XUiDlcHuntAttrDialogChipGroupAttrGrid = require("XUi/XUiDlcHunt/Attr/XUiDlcHuntAttrDialogChipGroupAttrGrid")

---@class XUiDlcHuntAttrDialogChipGroup
local XUiDlcHuntAttrDialogChipGroup = XClass(nil, "XUiDlcHuntAttrDialogChipGroup")

function XUiDlcHuntAttrDialogChipGroup:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:Init()
end

function XUiDlcHuntAttrDialogChipGroup:Init()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelAttribute)
    self.DynamicTable:SetProxy(XUiDlcHuntAttrDialogChipGroupAttrGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridRecord.gameObject:SetActiveEx(false)
end

---@param chipGroup XDlcHuntChipGroup
function XUiDlcHuntAttrDialogChipGroup:Update(chipGroup)
    local attrTable = chipGroup:GetAttrTable4Display()
    self.DynamicTable:SetDataSource(attrTable)
    self.DynamicTable:ReloadDataSync(1)
    self.TxtTitle2.text = XUiHelper.GetText("DlcHuntChipGroupPower", chipGroup:GetFightingPower())
end

---@param grid XUiDlcHuntBagGrid
function XUiDlcHuntAttrDialogChipGroup:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
    end
end

return XUiDlcHuntAttrDialogChipGroup