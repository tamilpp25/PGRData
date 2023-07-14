local XViewModelDlcHuntChipDetail = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntChipDetail")
local XUiDlcHuntChipDetailInfo = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipDetailInfo")
local XUiDlcHuntChipDetailStrengthen = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipDetailStrengthen")
local XUiDlcHuntChipDetailBreakthrough = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipDetailBreakthrough")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local TAB = XDlcHuntChipConfigs.UI_DETAIL_TAB

---@class XUiDlcHuntChipDetail:XLuaUi
local XUiDlcHuntChipDetail = XLuaUiManager.Register(XLuaUi, "UiDlcHuntChipDetails")

function XUiDlcHuntChipDetail:Ctor()
    ---@type XViewModelDlcHuntChipDetail
    self._ViewModel = XViewModelDlcHuntChipDetail.New()
end

function XUiDlcHuntChipDetail:OnAwake()
    self:BindExitBtns()
    self.Tags:Init({ self.BtnDlcTab1, self.BtnDlcTab2, self.BtnDlcTab3 }, function(index)
        self:OnTabSelected(index)
        self:PlayAnimation("QieHuan")
    end)

    ---@type XUiDlcHuntChipDetailInfo
    self._UiInfo = XUiDlcHuntChipDetailInfo.New(self.PanelDetails, self._ViewModel)

    ---@type XUiDlcHuntChipDetailStrengthen
    self._UiStrengthen = XUiDlcHuntChipDetailStrengthen.New(self.PanelIntensify, self._ViewModel)

    ---@type XUiDlcHuntChipDetailBreakthrough
    self._UiBreakthrough = XUiDlcHuntChipDetailBreakthrough.New(self.PanelBreach, self._ViewModel)

    self:InitSceneRoot()

    if self.BtnRemoving then
        self:RegisterClickEvent(self.BtnRemoving, self.OnClickRemove)
    end

    local helpBtn = XUiHelper.TryGetComponent(self.BtnBack.transform.parent, "BtnHelp", "Button")
    self:BindHelpBtn(helpBtn, XDlcHuntConfigs.HELP_KEY.CHIP_STRENGTHEN)
end

function XUiDlcHuntChipDetail:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_DETAIL_SELECTED_UPDATE, self.UpdateStrengthenSelected, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_UPDATE, self.OnChipUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_BREAKTHROUGH_SELECT_COST_UPDATE, self.UpdateBreakthroughSelectCost, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_UP_SUCCESS, self.PlayLevelUpEffect, self)
    self.EffectRefresh.gameObject:SetActiveEx(false)
end

function XUiDlcHuntChipDetail:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_DETAIL_SELECTED_UPDATE, self.UpdateStrengthenSelected, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_UPDATE, self.OnChipUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_BREAKTHROUGH_SELECT_COST_UPDATE, self.UpdateBreakthroughSelectCost, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_UP_SUCCESS, self.PlayLevelUpEffect, self)
end

---@param chip XDlcHuntChip
function XUiDlcHuntChipDetail:OnStart(chip)
    self._ViewModel:SetChip(chip)
    self:UpdateTabGroup()
    self.Tags:SelectIndex(1)
    local modelId = chip:GetModel()
    self.RoleModelPanel:UpdateRoleModel(modelId, self.RoleModelPanel, self.Name, function(model)
        if chip:IsSubChip() then
            local animator = self.RoleModelPanel:GetAnimator()
            if animator then
                animator:SetBool("UiActionBegin", true)
            end
        end
        local root = self.UiModelGo.transform
        local panelModel = root:FindTransform("PanelModel")
        local panelChip = panelModel:FindTransform("PanelChip")
        local modelCenter = panelChip:FindTransform("Center")
        XModelManager.DragRotateWeapon(self.PanelDrag, model, modelId, self.GameObject, true, modelCenter)
    end, nil, true)
    self.RoleModelPanel:LoadEffect(chip:GetEffect())
end

function XUiDlcHuntChipDetail:OnTabSelected(index)
    if index == TAB.DETAIL then
        self._UiInfo.GameObject:SetActiveEx(true)
        self._UiStrengthen.GameObject:SetActiveEx(false)
        self._UiBreakthrough.GameObject:SetActiveEx(false)

    elseif index == TAB.LEVEL_UP then
        if self._ViewModel:GetData().IsLockTabLevelUp then
            XUiManager.TipText("DlcHuntChipMaxLevel")
            self.Tags:SelectIndex(self._ViewModel:GetData().TabIndex, false)
            return
        end
        self._UiInfo.GameObject:SetActiveEx(false)
        self._UiStrengthen.GameObject:SetActiveEx(true)
        self._UiBreakthrough.GameObject:SetActiveEx(false)

    elseif index == TAB.BREAKTHROUGH then
        self._UiInfo.GameObject:SetActiveEx(false)
        self._UiStrengthen.GameObject:SetActiveEx(false)
        self._UiBreakthrough.GameObject:SetActiveEx(true)
    end
    self._ViewModel:SetTabIndex(index)
    self:UpdateByTab()
end

function XUiDlcHuntChipDetail:UpdateTabGroup()
    local data = self._ViewModel:GetData()
    if not data.IsShowTabs then
        self.BtnDlcTab1.gameObject:SetActiveEx(false)
        self.BtnDlcTab2.gameObject:SetActiveEx(false)
        self.BtnDlcTab3.gameObject:SetActiveEx(false)
        self.BtnRemoving.gameObject:SetActiveEx(false)
        return
    end
    self.BtnDlcTab2.gameObject:SetActiveEx(data.IsShowTabLevelUp)
    self.BtnDlcTab3.gameObject:SetActiveEx(data.IsShowTabBreakthrough)
end

function XUiDlcHuntChipDetail:UpdateByTab()
    self._ViewModel:UpdateByTabIndex()
    local data = self._ViewModel:GetData()
    local tabIndex = data.TabIndex
    if tabIndex == TAB.DETAIL then
        self._UiInfo:Update()
    elseif tabIndex == TAB.LEVEL_UP then
        self._UiStrengthen:Update()
    elseif tabIndex == TAB.BREAKTHROUGH then
        self._UiBreakthrough:Update()
    end
    self.BtnRemoving.gameObject:SetActiveEx(data.IsShowUndressBtn)
end

function XUiDlcHuntChipDetail:InitSceneRoot()
    local root = self.UiModelGo.transform
    local panelModel = root:FindTransform("PanelModel")
    local panelChip = panelModel:FindTransform("PanelChip")
    ---@type XUiPanelRoleModel
    self.RoleModelPanel = XUiPanelRoleModel.New(panelChip, self.Name, nil, true, false, true)
    self.EffectRefresh = root:FindTransform("EffectRefresh")
end

function XUiDlcHuntChipDetail:UpdateStrengthenSelected()
    self._UiStrengthen:UpdateAttr()
end

function XUiDlcHuntChipDetail:OnChipUpdate()
    local tabIndex, isChanged = self._ViewModel:GetTabIndexAfterUpdate()
    if isChanged then
        self:UpdateTabGroup()
        self.Tags:SelectIndex(tabIndex)
    else
        self:UpdateByTab()
    end
end

function XUiDlcHuntChipDetail:UpdateBreakthroughSelectCost()
    self._UiBreakthrough:UpdateCost()
end

function XUiDlcHuntChipDetail:PlayLevelUpEffect()
    self.EffectRefresh.gameObject:SetActiveEx(false)
    self.EffectRefresh.gameObject:SetActiveEx(true)
end

function XUiDlcHuntChipDetail:OnClickRemove()
    self._ViewModel:TakeOffChipFromAllGroup()
end

return XUiDlcHuntChipDetail