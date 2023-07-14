local XViewModelDlcHuntChipBatch = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntChipBatch")
local XUiDlcHuntChipBatchGrid = require("XUi/XUiDlcHunt/ChipMain/XUiDlcHuntChipBatchGrid")
local XUiDlcHuntBagGridChip = require("XUi/XUiDlcHunt/Bag/XUiDlcHuntBagGridChip")
local XUiDlcHuntChipGridAttr = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipGridAttr")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")
local XUiDlcHuntChipBatchMagic = require("XUi/XUiDlcHunt/ChipMain/XUiDlcHuntChipBatchMagic")

---@class XUiDlcHuntChipBatch:XLuaUi
local XUiDlcHuntChipBatch = XLuaUiManager.Register(XLuaUi, "UiDlcHuntChipBatch")

function XUiDlcHuntChipBatch:Ctor()
    ---@type XViewModelDlcHuntChipBatch
    self._ViewModel = XViewModelDlcHuntChipBatch.New()
    self._UiAttrList = {}
end

function XUiDlcHuntChipBatch:OnAwake()
    self:BindExitBtns()
    local helpBtn = XUiHelper.TryGetComponent(self.BtnBack.transform.parent, "BtnHelp", "Button")
    self:BindHelpBtn(helpBtn, XDlcHuntConfigs.HELP_KEY.CHIP_GROUP)

    self.DrdSort:AddOptions(XDlcHuntConfigs.GetSortTextGroup())
    self.DrdSort.onValueChanged:AddListener(function(index)
        self._ViewModel:GetViewModelChild():SetFilterTypeByIndex(index)
        self:UpdateData()
        self:PlayAnimationListChange()
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnOrder, self.OnBtnSortOrder)
    XUiHelper.RegisterClickEvent(self, self.BtnDlcExisting, self.OnClickUndress)
    XUiHelper.RegisterClickEvent(self, self.BtnDlcBlue, self.OnClickClearSelect)
    XUiHelper.RegisterClickEvent(self, self.BtnDlcYellow, self.OnClickEquip)
    self.PanelTabBtns:Init({ self.BtnMain, self.BtnSub }, function(index)
        self:OnTabSelected(index)
    end)

    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiDlcHuntChipBatchGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridEquip.gameObject:SetActiveEx(false)

    ---@type XUiDlcHuntBagGridChip
    self.ChipGridRight = XUiDlcHuntBagGridChip.New(self.GridIconChipRight)
    ---@type XUiDlcHuntChipBatchMagic
    self.Magic1 = XUiDlcHuntChipBatchMagic.New(self.PanelSkillDes1)
    ---@type XUiDlcHuntChipBatchMagic
    self.Magic2 = XUiDlcHuntChipBatchMagic.New(self.PanelSkillDes2)
end

function XUiDlcHuntChipBatch:OnStart(chipGroup)
    self._ViewModel:SetChipGroup(chipGroup)
    self.PanelTabBtns:SelectIndex(1, false)
    self:Update()
end

function XUiDlcHuntChipBatch:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE, self.Update, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_ALL_CHIP_TAKE_OFF, self.OnTakeOffAllChip, self)
end

function XUiDlcHuntChipBatch:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE, self.Update, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_ALL_CHIP_TAKE_OFF, self.OnTakeOffAllChip, self)
end

function XUiDlcHuntChipBatch:Update()
    self:UpdateData()
    self:UpdateBtnOrder()
    self:UpdateAmount()
    self:UpdateSelectedChip()
end

function XUiDlcHuntChipBatch:UpdateBtnOrder()
    if self._ViewModel:IsAscend() then
        self.ImgDescend.gameObject:SetActiveEx(false)
        self.ImgAscend.gameObject:SetActiveEx(true)
    else
        self.ImgDescend.gameObject:SetActiveEx(true)
        self.ImgAscend.gameObject:SetActiveEx(false)
    end
end

function XUiDlcHuntChipBatch:OnBtnSortOrder()
    self._ViewModel:SetFilterOrderInverse()
    self:UpdateBtnOrder()
    self:UpdateData()
    self:PlayAnimationListChange()
end

---@param grid XUiDlcHuntBagGrid
function XUiDlcHuntChipBatch:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetViewModel(self._ViewModel)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        ---@type XUiDlcHuntChipBatchGrid
        local chip = self.DynamicTable:GetData(index)
        self._ViewModel:GetViewModelChild():SetChipSelectedInverse(chip)
        self._ViewModel:GetViewModelChild():SetChipMarked(chip)
        self:UpdateSelected()

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
    end
end

function XUiDlcHuntChipBatch:UpdateData()
    self.DynamicTable:SetDataSource(self._ViewModel:GetViewModelChild():GetAllItem())
    self.DynamicTable:ReloadDataSync(1)
    self.PanelNoEquip.gameObject:SetActiveEx(#self.DynamicTable.DataSource == 0)
end

function XUiDlcHuntChipBatch:OnClickUndress()
    self._ViewModel:RequestTakeOff()
end

function XUiDlcHuntChipBatch:OnClickClearSelect()
    self._ViewModel:ClearSelectionOfAllTab()
    self:UpdateData()
    self:UpdateSelectedChip()
    self:UpdateAmount()
end

function XUiDlcHuntChipBatch:OnTabSelected(index)
    self._ViewModel:SetTabIndex(index)
    self:UpdateData()
    self:UpdateSelectedChip()
    self:UpdateAmount()
    self:PlayAnimationListChange()
end

function XUiDlcHuntChipBatch:UpdateSelectedChip()
    local isAnyChipMarked = self._ViewModel:GetViewModelChild():IsAnyChipMarked()
    self.PanelNo.gameObject:SetActiveEx(not isAnyChipMarked)
    self:UpdateDetail()
end

function XUiDlcHuntChipBatch:UpdateSelected()
    ---@type XUiDlcHuntChipBatchGrid[]
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:UpdateMarked()
        grid:UpdateDress()
        grid:UpdateSelected()
    end
    self:UpdateSelectedChip()
    self:UpdateAmount()
end

function XUiDlcHuntChipBatch:UpdateAmount()
    self.TxtNumberMain.text = XUiHelper.GetText("DlcHuntChipAmount", self._ViewModel:GetAmountMainChip())
    self.TxtNumberSub.text = XUiHelper.GetText("DlcHuntChipAmount", self._ViewModel:GetAmountSubChip())
    local amount, maxAmount = self._ViewModel:GetSelectedAmount()
    self.BtnDlcYellow:SetNameByGroup(1, XUiHelper.GetText("DlcHuntChipAmount", amount, maxAmount))
end

function XUiDlcHuntChipBatch:UpdateDetail()
    local chip = self._ViewModel:GetViewModelChild():GetChipMarked()
    if chip then
        self.ChipGridRight:Update(chip)
        self.TxtLevel.text = XUiHelper.GetText("DlcHuntChipLevel", chip:GetLevel(), chip:GetMaxLevel())
        self.TxtEquipName.text = chip:GetName()
        self.PanelMaxLevel.gameObject:SetActiveEx(chip:IsMaxLevel())
        self.PanelCommon.gameObject:SetActiveEx(true)
        self.GreatDetails.gameObject:SetActiveEx(true)
        -- Attr
        local attrTable = self._ViewModel:GetViewModelChild():GetMarkedChipAttr()
        XUiDlcHuntUtil.UpdateDynamicItem(self._UiAttrList, attrTable, self.PanelAttr1, XUiDlcHuntChipGridAttr)

        local magicDesc = chip:GetMagicDescIncludePreview()
        local magic = magicDesc[1]
        if magic then
            self.Magic1:Update(magic, magic.IsActive)
            self.Magic1.GameObject:SetActiveEx(true)
        else
            self.Magic1.GameObject:SetActiveEx(false)
        end
        local magic2 = magicDesc[2]
        if magic2 then
            self.Magic2:Update(magic2, magic2.IsActive)
            self.Magic2.GameObject:SetActiveEx(true)
        else
            self.Magic2.GameObject:SetActiveEx(false)
        end

        if self._ViewModel:GetViewModelChild():IsChipMarkedChanged() then
            self:PlayAnimationInfoChange()
        end
    else
        self.PanelCommon.gameObject:SetActiveEx(false)
        self.GreatDetails.gameObject:SetActiveEx(false)
    end
end

function XUiDlcHuntChipBatch:OnClickEquip()
    self._ViewModel:RequestWear()
    self:Close()
end

function XUiDlcHuntChipBatch:PlayAnimationListChange()
    self:PlayAnimation("QieHuan1")
end

function XUiDlcHuntChipBatch:PlayAnimationInfoChange()
    self:PlayAnimation("QieHUna2")
end

function XUiDlcHuntChipBatch:OnTakeOffAllChip()
    self._ViewModel:ClearSelectionOfAllTab()
    self:Update()
end

return XUiDlcHuntChipBatch