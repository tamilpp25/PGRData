local XUiDlcHuntChipChoiceGrid = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipChoiceGrid")

---@class XUiDlcHuntChipChoice:XLuaUi
local XUiDlcHuntChipChoice = XLuaUiManager.Register(XLuaUi, "UiDlcHuntChipChoice")

function XUiDlcHuntChipChoice:Ctor()
    self._SelectAmount = 0
    self._TotalAmount = 1
    self._SelectedChipId = {}
    self._DataProvider = {}
    self._Callback = false
end

function XUiDlcHuntChipChoice:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnClickConfirm)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)

    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiDlcHuntChipChoiceGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridEquip.gameObject:SetActiveEx(false)
end

function XUiDlcHuntChipChoice:OnStart(dataProvider, selectedChipId, callback)
    self._Callback = callback
    self._SelectedChipId = XTool.Clone(selectedChipId)
    self._DataProvider = dataProvider
    self:UpdateData()
    self:UpdateSelectedAmount()
end

function XUiDlcHuntChipChoice:OnClickConfirm()
    if self._Callback then
        self._Callback(self._SelectedChipId)
    end
    self:Close()
end

function XUiDlcHuntChipChoice:GetItems()
    return self._DataProvider
end

function XUiDlcHuntChipChoice:UpdateData()
    self.DynamicTable:SetDataSource(self:GetItems())
    self.DynamicTable:ReloadDataASync(self._SelectedIndex)
    self.PanelNoEquip.gameObject:SetActiveEx(#self.DynamicTable.DataSource == 0)
end

function XUiDlcHuntChipChoice:UpdateSelectedAmount()
    local selectedAmount = 0
    local totalAmount = #self._SelectedChipId
    for i = 1, totalAmount do
        local chipUid = self._SelectedChipId[i]
        if chipUid and chipUid > 0 then
            selectedAmount = selectedAmount + 1
        end
    end
    self.TxtNumber.text = XUiHelper.GetText("DlcHuntChipSelect", selectedAmount, totalAmount)
end

---@param grid XUiDlcHuntChipChoiceGrid
function XUiDlcHuntChipChoice:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        --XUiHelper.RegisterClickEvent(grid, grid.BtnClick, function()
        --    
        --end)
        --
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        ---@type XDlcHuntChip
        local chip = grid:GetChip()
        local isSelected, selectedIndex = self:IsSelected(chip)
        if isSelected then
            self:SetUnselected(selectedIndex)
        else
            self:SetSelected(chip)
        end
        grid:UpdateSelected(self:IsSelected(chip))
        self:UpdateSelectedAmount()

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        ---@type XDlcHuntChip
        local chip = self.DynamicTable:GetData(index)
        grid:Update(chip, self:IsSelected(chip))

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
    end
end

function XUiDlcHuntChipChoice:IsSelected(chip)
    for i = 1, #self._SelectedChipId do
        if chip:GetUid() == self._SelectedChipId[i] then
            return true, i
        end
    end
    return false
end

---@param chip XDlcHuntChip
function XUiDlcHuntChipChoice:SetSelected(chip)
    for i = 1, #self._SelectedChipId do
        local uid = self._SelectedChipId[i]
        if not uid or uid == 0 then
            self._SelectedChipId[i] = chip:GetUid()
            return
        end
    end
end

function XUiDlcHuntChipChoice:SetUnselected(index)
    self._SelectedChipId[index] = false
end

return XUiDlcHuntChipChoice