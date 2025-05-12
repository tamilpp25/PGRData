local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiDlcHuntPersonalSupportGrid = require("XUi/XUiDlcHunt/Room/XUiDlcHuntPersonalSupportGrid")
local XViewModelDlcHuntChipAssistantToMyself = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntChipAssistantToMyself")

---@class XUiDlcHuntChipHelp:XLuaUi
local XUiDlcHuntChipHelp = XLuaUiManager.Register(XLuaUi, "UiDlcHuntChipHelp")

function XUiDlcHuntChipHelp:Ctor()
    ---@type XViewModelDlcHuntChipAssistantToMyself
    self._ViewModel = XViewModelDlcHuntChipAssistantToMyself.New()
end

function XUiDlcHuntChipHelp:OnAwake()
    self:BindExitBtns()
    -- uiDlcHunt hide panelAsset
    self.PanelAsset.gameObject:SetActiveEx(false)
    self:BindHelpBtn(self.BtnHelp, XDlcHuntConfigs.GetHelpKey())
    self:RegisterClickEvent(self.BtnSure, self.OnClickSure)
    self:RegisterClickEvent(self.BtnRefresh, self.OnClickRefresh)
    self.PanelBagItem.gameObject:SetActiveEx(false)

    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiDlcHuntPersonalSupportGrid)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcHuntChipHelp:OnStart()
    XDataCenter.DlcRoomManager.BeginSelectRequest(XDlcHuntConfigs.RoomSelect.Chip)
    self:UpdateDataWithoutRefresh()
    self:UpdateSelected()
    self:UpdateAssist()
end

function XUiDlcHuntChipHelp:OnEnable()
    local isGuide = XDataCenter.GuideManager.CheckIsInGuide()
    XDataCenter.DlcHuntChipManager.RequestAssistantChip2Myself(isGuide)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_LIST_UPDATE, self.UpdateDataWithoutRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_UPDATE, self.UpdateSelected, self)
    if isGuide then
        self:UpdateDataWithoutRefresh()
        self:UpdateSelected()
    end
end

function XUiDlcHuntChipHelp:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_LIST_UPDATE, self.UpdateDataWithoutRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_UPDATE, self.UpdateSelected, self)
end

function XUiDlcHuntChipHelp:OnDestroy()
    if not self._ViewModel:IsRequestSelect() then
        XDataCenter.DlcRoomManager.EndSelectRequest()
    end
end

function XUiDlcHuntChipHelp:UpdateDataProvider(isRefresh)
    self.DynamicTable:SetDataSource(self._ViewModel:GetDataProvider(isRefresh))
    self.DynamicTable:ReloadDataASync(1)
    self.PanelEmpty.gameObject:SetActiveEx(#self.DynamicTable.DataSource == 0)
end

function XUiDlcHuntChipHelp:UpdateDataWithoutRefresh()
    self:UpdateDataProvider(false)
end

function XUiDlcHuntChipHelp:UpdateDataWithRefresh()
    self:UpdateDataProvider(true)
end

function XUiDlcHuntChipHelp:OnClickRefresh()
    self:UpdateDataWithRefresh()
end

---@param grid XUiDlcHuntPersonalSupportGrid
function XUiDlcHuntChipHelp:OnDynamicTableEvent(event, index, grid)
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

function XUiDlcHuntChipHelp:OnClickSure()
    if self._ViewModel:RequestSetAssistantChip() then
        self:Close()
    end
end

function XUiDlcHuntChipHelp:UpdateSelected()
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:UpdateSelected()
    end
    self:UpdateSureBtnVisible()
end

function XUiDlcHuntChipHelp:UpdateSureBtnVisible()
    self.BtnSure.gameObject:SetActiveEx(self._ViewModel:IsShowBtnSure())
end

function XUiDlcHuntChipHelp:UpdateAssist()
    if self.TxtTips then
        self.TxtTips.gameObject:SetActiveEx(XDataCenter.DlcHuntManager.IsGainAssistPointMax())
    end
end

return XUiDlcHuntChipHelp