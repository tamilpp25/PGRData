local XUiDlcHuntBagDecomposeGrid = require("XUi/XUiDlcHunt/Bag/XUiDlcHuntBagDecomposeGrid")

---@class XUiDlcHuntBagDecompose
local XUiDlcHuntBagDecompose = XClass(nil, "XUiDlcHuntBagDecompose")

function XUiDlcHuntBagDecompose:Ctor(ui, viewModel)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XViewModelDlcHuntBag
    self._ViewModel = viewModel
    self:Init()
end

function XUiDlcHuntBagDecompose:Init()
    self.GridCommonPopUp.gameObject:SetActiveEx(false)

    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTablePopUp)
    self.DynamicTable:SetProxy(XUiDlcHuntBagDecomposeGrid)
    self.DynamicTable:SetDelegate(self)

    XUiHelper.RegisterClickEvent(self, self.TogStar1PopUp, self.OnClickTogStar123)
    XUiHelper.RegisterClickEvent(self, self.TogStar2PopUp, self.OnClickTogStar4)
    XUiHelper.RegisterClickEvent(self, self.TogStar3PopUp, self.OnClickTogStar5)
    XUiHelper.RegisterClickEvent(self, self.BtnCha, self.OnClickClose)
    XUiHelper.RegisterClickEvent(self, self.BtnDecomposionPopUp, self.OnClickDecompose)
end

---@param grid XUiDlcHuntBagDecomposeGrid
function XUiDlcHuntBagDecompose:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
    end
end

function XUiDlcHuntBagDecompose:UpdateAmount()
    self._ViewModel:SendEventUpdateChipSelected()
    local amount = self._ViewModel:GetDecomposeAmount()
    self.TxtSelectNum.text = amount
    if amount == 0 then
        self.PanelSelectNum.gameObject:SetActiveEx(false)
        self.BtnDecomposionPopUp:SetButtonState(CS.UiButtonState.Disable)
    else
        self.PanelSelectNum.gameObject:SetActiveEx(true)
        self.BtnDecomposionPopUp:SetButtonState(CS.UiButtonState.Normal)
    end
    
    local items = self._ViewModel:GetDecomposeResult()
    self.DynamicTable:SetDataSource(items)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiDlcHuntBagDecompose:OnClickTogStar123()
    self._ViewModel:SetStarSelected(1, self.TogStar1PopUp.isOn)
    self._ViewModel:SetStarSelected(2, self.TogStar1PopUp.isOn)
    self._ViewModel:SetStarSelected(3, self.TogStar1PopUp.isOn)
    self._ViewModel:SendEventUpdateChipSelected()
    self:UpdateAmount()
end

function XUiDlcHuntBagDecompose:OnClickTogStar4()
    self._ViewModel:SetStarSelected(4, self.TogStar2PopUp.isOn)
    self._ViewModel:SendEventUpdateChipSelected()
    self:UpdateAmount()
end

function XUiDlcHuntBagDecompose:OnClickTogStar5()
    self._ViewModel:SetStarSelected(5, self.TogStar3PopUp.isOn)
    self._ViewModel:SendEventUpdateChipSelected()
    self:UpdateAmount()
end

function XUiDlcHuntBagDecompose:OnClickClose()
    self.TogStar1PopUp.isOn = false
    self.TogStar2PopUp.isOn = false
    self.TogStar3PopUp.isOn = false
    self.GameObject:SetActiveEx(false)
    self._ViewModel:ClearDecomposeSelected()
    self:UpdateAmount()
    self._ViewModel:SetVisibleDecomposeInverse()
    self._ViewModel:SendEventUpdateChipSelected()
end

function XUiDlcHuntBagDecompose:OnClickDecompose()
    self._ViewModel:DecomposeChips()
end

return XUiDlcHuntBagDecompose