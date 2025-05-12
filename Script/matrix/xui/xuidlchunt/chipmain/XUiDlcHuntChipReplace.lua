local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XViewModelDlcHuntChipSetting = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntChipSetting")
local XUiDlcHuntChipReplaceGrid = require("XUi/XUiDlcHunt/ChipMain/XUiDlcHuntChipReplaceGrid")
local XUiDlcHuntChipReplaceInfo = require("XUi/XUiDlcHunt/ChipMain/XUiDlcHuntChipReplaceInfo")

local UI_STATE_INFO_PANEL = {
    NO_EQUIP_AND_NO_SELECT = 1,
    EQUIP_AND_NO_SELECT = 2,
    NO_EQUIP_AND_SELECT = 3,
    EQUIP_AND_SELECT = 4,
    EQUIP_AND_SELECT_SAME = 5,
}

---@class XUiDlcHuntChipReplace:XLuaUi
local XUiDlcHuntChipReplace = XLuaUiManager.Register(XLuaUi, "UiDlcHuntChipReplace")

function XUiDlcHuntChipReplace:Ctor()
    self._UiStateInfoPanel = 0
    ---@type XViewModelDlcHuntChipSetting
    self._ViewModel = XViewModelDlcHuntChipSetting.New()
end

function XUiDlcHuntChipReplace:OnAwake()
    self:BindExitBtns()

    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiDlcHuntChipReplaceGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridEquip.gameObject:SetActiveEx(false)

    self._PlayAnimationEquip = function()
        self:PlayAnimationEquip()
    end

    ---@type XUiDlcHuntChipReplaceInfo
    self._UiRight01 = XUiDlcHuntChipReplaceInfo.New(self.Right01, self._ViewModel, true, self._PlayAnimationEquip)
    ---@type XUiDlcHuntChipReplaceInfo
    self._UiRight03 = XUiDlcHuntChipReplaceInfo.New(self.Right03, self._ViewModel, true, self._PlayAnimationEquip)
    ---@type XUiDlcHuntChipReplaceInfo
    self._UiRight02 = XUiDlcHuntChipReplaceInfo.New(self.Right02, self._ViewModel, false, self._PlayAnimationEquip)

    self:RegisterClickEvent(self.BtnOrder, self.OnBtnSortOrder)

    self.DrdSort:AddOptions(XDlcHuntConfigs.GetSortTextGroup())
    self.DrdSort.onValueChanged:AddListener(function(index)
        self._ViewModel:SetFilterTypeByIndex(index)
        self:UpdateItems()
        self:PlayAnimationListChange()
    end)
end

function XUiDlcHuntChipReplace:OnStart(chipGroup, pos)
    if not chipGroup and not pos then
        local allChipGroup = XDataCenter.DlcHuntChipManager.GetAllChipGroup()
        local chipGroupId
        chipGroupId, chipGroup = next(allChipGroup)
        pos = 1
    end
    self._ViewModel:SetChipGroup(chipGroup, pos)
    self:Update()
end

function XUiDlcHuntChipReplace:Update()
    self._UiRight01:Update()
    self._UiRight03:Update()
    self:UpdateItems()
    self:UpdateSelectedChip()
end

function XUiDlcHuntChipReplace:OnEnable()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE, self.Update, self)
end

function XUiDlcHuntChipReplace:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE, self.Update, self)
end

function XUiDlcHuntChipReplace:OnDestroy()
    self._UiRight01:RemovePlayAnimationEquip()
    self._UiRight02:RemovePlayAnimationEquip()
    self._UiRight03:RemovePlayAnimationEquip()
end

---@param grid XUiDlcHuntChipReplaceGrid
function XUiDlcHuntChipReplace:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetViewModel(self._ViewModel)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        ---@type XUiDlcHuntBagGridChip
        local chip = self.DynamicTable:GetData(index)
        self._ViewModel:SetChipSelected(chip)
        self:UpdateSelected()

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
    end
end

function XUiDlcHuntChipReplace:UpdateSelected()
    ---@type XUiDlcHuntChipReplaceGrid[]
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:UpdateSelected()
    end
    self:UpdateSelectedChip()
end

function XUiDlcHuntChipReplace:UpdateItems()
    local dataSource = self._ViewModel:GetAllItem()
    self.DynamicTable:SetDataSource(dataSource)
    local index = self._ViewModel:GetSelectedIndex(dataSource)
    self.DynamicTable:ReloadDataSync(index)
    self.PanelNoEquip.gameObject:SetActiveEx(#self.DynamicTable.DataSource == 0)
end

function XUiDlcHuntChipReplace:UpdateSelectedChip()
    self._UiRight01:Update()
    self._UiRight03:Update()

    if self._ViewModel:IsAnyChipSelected()
            and not self._ViewModel:IsChipSelectedAndToReplace() then
        self._UiRight02:Update()
    end

    local isAnyChipEquip = self._ViewModel:IsAnyChipEquip()
    local isAnyChipSelected = self._ViewModel:IsAnyChipSelected()
    local isChipSelectedAndToReplace = self._ViewModel:IsChipSelectedAndToReplace()

    if not isAnyChipEquip and isAnyChipSelected then
        -- 没装备芯片，选择其他芯片
        self:PlayAnimation("Right02Enable")
        self._UiRight01.GameObject:SetActiveEx(true)
        self._UiRight02.GameObject:SetActiveEx(false)
        self._UiRight03.GameObject:SetActiveEx(false)
        self._UiStateInfoPanel = UI_STATE_INFO_PANEL.NO_EQUIP_AND_SELECT

    elseif isChipSelectedAndToReplace then
        -- 有装备芯片，选择此芯片
        if self._UiStateInfoPanel == UI_STATE_INFO_PANEL.EQUIP_AND_SELECT then
            self:PlayAnimation("Right03Disable")
        end
        self._UiRight01.GameObject:SetActiveEx(true)
        self._UiRight02.GameObject:SetActiveEx(false)
        self._UiRight03.GameObject:SetActiveEx(false)
        self._UiStateInfoPanel = UI_STATE_INFO_PANEL.EQUIP_AND_SELECT_SAME

    elseif isAnyChipEquip and isAnyChipSelected then
        -- 有装备芯片，选择其他芯片
        self:PlayAnimation("Right03Enable")
        self._UiRight01.GameObject:SetActiveEx(false)
        self._UiRight02.GameObject:SetActiveEx(true)
        self._UiRight03.GameObject:SetActiveEx(true)
        self._UiStateInfoPanel = UI_STATE_INFO_PANEL.EQUIP_AND_SELECT

    elseif isAnyChipEquip and not isAnyChipSelected then
        -- 有装备芯片，无选择芯片
        self._UiRight01:Update()
        self._UiRight01.GameObject:SetActiveEx(true)
        self._UiRight02.GameObject:SetActiveEx(false)
        self._UiRight03.GameObject:SetActiveEx(false)
        self._UiStateInfoPanel = UI_STATE_INFO_PANEL.EQUIP_AND_NO_SELECT

    elseif not isAnyChipEquip and not isAnyChipSelected then
        -- 无装备芯片，无选择芯片
        self._UiRight01.GameObject:SetActiveEx(false)
        self._UiRight02.GameObject:SetActiveEx(false)
        self._UiRight03.GameObject:SetActiveEx(false)
        self._UiStateInfoPanel = UI_STATE_INFO_PANEL.NO_EQUIP_AND_NO_SELECT

    end
end

function XUiDlcHuntChipReplace:OnBtnSortOrder()
    self._ViewModel:SetFilterOrderInverse()
    self:UpdateBtnOrder()
    self:UpdateItems()
    self:PlayAnimationListChange()
end

function XUiDlcHuntChipReplace:UpdateBtnOrder()
    if self._ViewModel:IsAscend() then
        self.ImgDescend.gameObject:SetActiveEx(false)
        self.ImgAscend.gameObject:SetActiveEx(true)
    else
        self.ImgDescend.gameObject:SetActiveEx(true)
        self.ImgAscend.gameObject:SetActiveEx(false)
    end
end

function XUiDlcHuntChipReplace:PlayAnimationEquip()
    self:PlayAnimation("Right01Enable")
end

function XUiDlcHuntChipReplace:PlayAnimationListChange()
    self:PlayAnimation("QieHuan")
end

return XUiDlcHuntChipReplace