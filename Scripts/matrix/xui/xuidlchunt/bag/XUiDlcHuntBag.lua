local XViewModelDlcHuntBag = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntBag")
local XUiDlcHuntBagGrid = require("XUi/XUiDlcHunt/Bag/XUiDlcHuntBagGrid")
local XUiDlcHuntBagDecompose = require("XUi/XUiDlcHunt/Bag/XUiDlcHuntBagDecompose")

---@class XUiDlcHuntBag:XLuaUi
local XUiDlcHuntBag = XLuaUiManager.Register(XLuaUi, "UiDlcHuntBag")

function XUiDlcHuntBag:Ctor()
    ---@type XViewModelDlcHuntBag
    self._ViewModel = XViewModelDlcHuntBag.New()
end

function XUiDlcHuntBag:OnAwake()
    self:BindExitBtns()
    self:BindHelpBtn(self.BtnHelp, XDlcHuntConfigs.GetHelpKey())

    self.TabBtnGroup:Init({ self.BtnTog0, self.BtnTog1, self.BtnTog2 }, function(index)
        self:OnTabSelected(index)
        self:PlayAnimation("QieHuan")
    end)
    -- uiDlcHunt hide panelAsset
    self.PanelAsset.gameObject:SetActiveEx(false)

    --self.TxtCapacityDes = false
    --self.PanelTag = false
    --self.PanelBagItem = false
    --self.PanelSort = false
    --self.ImgCantDecomposion = false    

    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiDlcHuntBagGrid)
    self.DynamicTable:SetDelegate(self)
    self.PanelBagItem.gameObject:SetActiveEx(false)

    XUiHelper.RegisterClickEvent(self, self.BtnOrder, self.OnBtnSortOrder)
    local buttonGroupSort = {
        self.BtnTogSortStar, self.BtnTogSortBreakthrough, self.BtnTogSortLevel, self.BtnTogSortProceed
    }
    self._SortBtnGroup = XUiTabBtnGroup.New(buttonGroupSort, function(index)
        self:OnBtnFilterGroup(index)
    end)

    XUiHelper.RegisterClickEvent(self, self.BtnDecomposion, function()
        self:OnBtnDecompose()
    end)

    ---@type XUiDlcHuntBagDecompose
    self._UiDecompose = XUiDlcHuntBagDecompose.New(self.PanelSidePopUp, self._ViewModel)
    self.PanelSidePopUp.gameObject:SetActiveEx(self._ViewModel:IsVisibleDecompose())
end

function XUiDlcHuntBag:UpdateBtnDecompose()
    self.BtnDecomposion.gameObject:SetActiveEx(self._ViewModel:IsShowBtnDecompose())
end

function XUiDlcHuntBag:OnStart()
    self.TabBtnGroup:SelectIndex(1)
    self._SortBtnGroup:SelectIndex(1)
end

function XUiDlcHuntBag:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_DECOMPOSE_SELECT_UPDATE, self.UpdateSelected, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_DECOMPOSE_UPDATE, self.UpdateDecompose, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_UPDATE, self.UpdateChips, self)
    self:UpdateChips()
end

function XUiDlcHuntBag:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_DECOMPOSE_SELECT_UPDATE, self.UpdateSelected, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_DECOMPOSE_UPDATE, self.UpdateDecompose, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_UPDATE, self.UpdateChips, self)
end

function XUiDlcHuntBag:OnTabSelected(index)
    self._ViewModel:SetTabIndex(index)
    self:UpdateData()
    self:UpdateAmount()
    self:UpdateBtnOrder()
    self:UpdateBtnFilterGroup()
    self:UpdateBtnDecompose()
    self.PanelSort.gameObject:SetActiveEx(self._ViewModel:IsShowPanelSort())
    if index == XDlcHuntConfigs.TAB_BAG.OTHERS then
        self.TxtCapacityDes.gameObject:SetActiveEx(false)
        self.TxtCapacityDesItem.gameObject:SetActiveEx(true)
    elseif index == XDlcHuntConfigs.TAB_BAG.SUB_CHIP
            or index == XDlcHuntConfigs.TAB_BAG.MAIN_CHIP
    then
        self.TxtCapacityDes.gameObject:SetActiveEx(true)
        self.TxtCapacityDesItem.gameObject:SetActiveEx(false)
    end
end

function XUiDlcHuntBag:UpdateData()
    self.DynamicTable:SetDataSource(self._ViewModel:GetAllItem())
    self.DynamicTable:ReloadDataASync()
    self.PanelEmpty.gameObject:SetActiveEx(#self.DynamicTable.DataSource == 0)
end

function XUiDlcHuntBag:UpdateAmount()
    local amount, capacity = self._ViewModel:GetAmount()
    self.TxtMaxCapacity.text = "/" .. capacity
    self.TxtNowCapacity.text = amount
end

---@param grid XUiDlcHuntBagGrid
function XUiDlcHuntBag:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetViewModel(self._ViewModel)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
    end
end

function XUiDlcHuntBag:OnBtnSortOrder()
    self._ViewModel:SetFilterOrderInverse()
    self:UpdateBtnOrder()
    self:UpdateData()
    self:PlayAnimation("QieHuan")
end

function XUiDlcHuntBag:OnBtnFilterGroup(index)
    self._ViewModel:SetFilterType(index)
    self:UpdateData()
    self:PlayAnimation("QieHuan")
end

function XUiDlcHuntBag:OnBtnDecompose()
    self._ViewModel:SetVisibleDecomposeInverse()
    self.PanelSidePopUp.gameObject:SetActiveEx(self._ViewModel:IsVisibleDecompose())
end

function XUiDlcHuntBag:UpdateDecomposeSelected()
    self.DynamicTable:ReloadDataASync()
end

function XUiDlcHuntBag:UpdateSelected(updateItem)
    if updateItem then
        self:UpdateData()
        return
    end
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:UpdateSelected()
    end
end

function XUiDlcHuntBag:UpdateBtnOrder()
    if self._ViewModel:IsAscend() then
        self.ImgDescend.gameObject:SetActiveEx(false)
        self.ImgAscend.gameObject:SetActiveEx(true)
    else
        self.ImgDescend.gameObject:SetActiveEx(true)
        self.ImgAscend.gameObject:SetActiveEx(false)
    end
end

function XUiDlcHuntBag:UpdateBtnFilterGroup()
    local index = self._ViewModel:GetFilterType()
    self._SortBtnGroup:SelectIndex(index, false)
end

function XUiDlcHuntBag:UpdateDecompose()
    self._UiDecompose:UpdateAmount()
end

function XUiDlcHuntBag:UpdateChips()
    self._ViewModel:ClearInvalidSelected()
    self:UpdateData()
    self:UpdateDecompose()
    self:UpdateAmount()
end

return XUiDlcHuntBag
