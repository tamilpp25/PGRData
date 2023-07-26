local XUiDlcHuntAttrDialogMagicGrid = require("XUi/XUiDlcHunt/Attr/XUiDlcHuntAttrDialogMagicGrid")

---@class XUiDlcHuntAttrDialogMagic
local XUiDlcHuntAttrDialogMagic = XClass(nil, "XUiDlcHuntAttrDialogMagic")

function XUiDlcHuntAttrDialogMagic:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:Init()
end

function XUiDlcHuntAttrDialogMagic:Init()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelAttribute)
    self.DynamicTable:SetProxy(XUiDlcHuntAttrDialogMagicGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridRecord.gameObject:SetActiveEx(false)
end

---@param chipGroup XDlcHuntChipGroup
function XUiDlcHuntAttrDialogMagic:Update(chipGroup)
    local magicList = chipGroup:GetMagicDesc()
    self.DynamicTable:SetDataSource(magicList)
    self.DynamicTable:ReloadDataSync(1)
    self.TxtTitle2.text = XUiHelper.GetText("DlcHuntChipGroupPower", chipGroup:GetFightingPower())
    self.PanelNo.gameObject:SetActiveEx(#magicList == 0)
end

---@param grid XUiDlcHuntBagGrid
function XUiDlcHuntAttrDialogMagic:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
    end
end

return XUiDlcHuntAttrDialogMagic