local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiDlcHuntPersonalChoiceGrid = require("XUi/XUiDlcHunt/Room/XUiDlcHuntPersonalChoiceGrid")
local XViewModelDlcHuntChipAssistant = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntChipAssistant")

---@class XUiDlcHuntPersonalChoice:XLuaUi
local XUiDlcHuntPersonalChoice = XLuaUiManager.Register(XLuaUi, "UiDlcHuntPersonalChoice")

function XUiDlcHuntPersonalChoice:Ctor()
    ---@type XViewModelDlcHuntChipAssistant
    self._ViewModel = XViewModelDlcHuntChipAssistant.New()
end

function XUiDlcHuntPersonalChoice:OnAwake()
    self:BindExitBtns()
    -- uiDlcHunt hide panelAsset
    self.PanelAsset.gameObject:SetActiveEx(false)
    self:BindHelpBtn(self.BtnHelp, XDlcHuntConfigs.GetHelpKey())
    self:RegisterClickEvent(self.BtnSure, self.OnClickSure)
    self.PanelBagItem.gameObject:SetActiveEx(false)

    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiDlcHuntPersonalChoiceGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcHuntPersonalChoice:OnStart()
    self:Update()
end

function XUiDlcHuntPersonalChoice:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_LIST_UPDATE, self.UpdateData, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_UPDATE, self.UpdateSelected, self)
end

function XUiDlcHuntPersonalChoice:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_LIST_UPDATE, self.UpdateData, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_UPDATE, self.UpdateSelected, self)
end

function XUiDlcHuntPersonalChoice:Update()
    self:UpdateData()
    self:UpdateSureBtnVisible()
end

function XUiDlcHuntPersonalChoice:UpdateData()
    local chipList = XDataCenter.DlcHuntChipManager.GetChipList2AssistantOthers()
    self.DynamicTable:SetDataSource(chipList)
    self.DynamicTable:ReloadDataASync(1)
    self.PanelEmpty.gameObject:SetActiveEx(#self.DynamicTable.DataSource == 0)
end

---@param grid XUiDlcHuntPersonalSupportGrid
function XUiDlcHuntPersonalChoice:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetViewModel(self._ViewModel)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClick()
        self:UpdateSelected()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
    end
end

function XUiDlcHuntPersonalChoice:OnClickSure()
    self._ViewModel:RequestSetAssistantChip()
    self:Close()
end

function XUiDlcHuntPersonalChoice:UpdateSelected()
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:UpdateSelected()
    end
    self:UpdateSureBtnVisible()
end

function XUiDlcHuntPersonalChoice:UpdateSureBtnVisible()
    self.BtnSure.gameObject:SetActiveEx(self._ViewModel:IsShowBtnSure())
end

return XUiDlcHuntPersonalChoice