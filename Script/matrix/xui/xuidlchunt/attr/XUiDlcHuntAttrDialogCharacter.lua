local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiDlcHuntAttrDialogCharacterAttrGrid = require("XUi/XUiDlcHunt/Attr/XUiDlcHuntAttrDialogCharacterAttrGrid")

---@class XUiDlcHuntAttrDialogCharacter
local XUiDlcHuntAttrDialogCharacter = XClass(nil, "XUiDlcHuntAttrDialogCharacter")

function XUiDlcHuntAttrDialogCharacter:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:Init()
end

function XUiDlcHuntAttrDialogCharacter:Init()
    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelAttribute)
    self.DynamicTable:SetProxy(XUiDlcHuntAttrDialogCharacterAttrGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridRecord.gameObject:SetActiveEx(false)
end

---@param character XDlcHuntCharacter
function XUiDlcHuntAttrDialogCharacter:Update(character)
    local attrTable = character:GetAttrTable4Display()
    self.DynamicTable:SetDataSource(attrTable)
    self.DynamicTable:ReloadDataSync(1)
    self.TxtTitle2.text = XUiHelper.GetText("DlcHuntChipGroupPower", character:GetFightingPower())
end

---@param grid XUiDlcHuntBagGrid
function XUiDlcHuntAttrDialogCharacter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
    end
end

return XUiDlcHuntAttrDialogCharacter