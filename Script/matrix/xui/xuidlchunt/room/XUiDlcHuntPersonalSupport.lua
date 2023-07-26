local XViewModelDlcHuntChipDetail = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntChipDetail")
local XUiDlcHuntChipDetailInfo = require("XUi/XUiDlcHunt/Chip/XUiDlcHuntChipDetailInfo")
local XUiDlcHuntBagGridChip = require("XUi/XUiDlcHunt/Bag/XUiDlcHuntBagGridChip")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

---@class XUiDlcHuntPersonalSupport:XLuaUi
local XUiDlcHuntPersonalSupport = XLuaUiManager.Register(XLuaUi, "UiDlcHuntPersonalSupport")

function XUiDlcHuntPersonalSupport:Ctor()
    ---@type XDlcHuntCharacter
    self._Character = false
    ---@type XUiDlcHuntBagGridChip
    self._UiChipGrid1 = false
    ---@type XUiDlcHuntBagGridChip
    self._UiChipGrid2 = false

    ---@type XViewModelDlcHuntChipDetail
    self._ViewModel = XViewModelDlcHuntChipDetail.New()

    self._IsFirstOnEnable = true
end

function XUiDlcHuntPersonalSupport:OnAwake()
    self:BindExitBtns()
    self._UiChipGrid1 = XUiDlcHuntBagGridChip.New(self.GridChipNormal)
    self._UiChipGrid2 = XUiDlcHuntBagGridChip.New(self.GridChipPress)
    self:RegisterClickEvent(self.PanelSz, self.OnClickSelectChip)
    self:RegisterClickEvent(self.BtnRemoving, self.OnClickSelectChip)

    ---@type XUiDlcHuntChipDetailInfo
    self._UiInfo = XUiDlcHuntChipDetailInfo.New(self.PanelDetails, self._ViewModel)
    self:InitSceneRoot()
end

function XUiDlcHuntPersonalSupport:InitSceneRoot()
    local root = self.UiModelGo.transform
    local panelModel = root:FindTransform("PanelModel")
    local panelChip = panelModel:FindTransform("PanelChip")
    ---@type XUiPanelRoleModel
    self.RoleModelPanel = XUiPanelRoleModel.New(panelChip, self.Name, nil, true, false, true)
end

function XUiDlcHuntPersonalSupport:OnStart(character)
    self._Character = character
end

function XUiDlcHuntPersonalSupport:OnEnable()
    local root = self.UiModelGo.transform
    self.EffectRefresh = root:FindTransform("EffectRefresh")
    self.EffectRefresh.gameObject:SetActiveEx(false)
    self.Effect.gameObject:SetActiveEx(false)
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_UPDATE, self.Update, self)
end

function XUiDlcHuntPersonalSupport:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_ASSISTANT_UPDATE, self.Update, self)
end

function XUiDlcHuntPersonalSupport:Update()
    local chip = XDataCenter.DlcHuntChipManager.GetAssistantChip2Others()
    if not chip or chip:IsEmpty() then
        self.ImageNormal.gameObject:SetActiveEx(true)
        self.ImagePress.gameObject:SetActiveEx(true)
        self._UiChipGrid1.GameObject:SetActiveEx(false)
        self._UiChipGrid2.GameObject:SetActiveEx(false)
        self.PanelTs.gameObject:SetActiveEx(true)
        self.PanelDetails.gameObject:SetActiveEx(false)
        self.RoleModelPanel:HideRoleModel()
        return
    end
    local modelId = chip:GetModel()
    self.RoleModelPanel:UpdateRoleModel(modelId, self.RoleModelPanel, self.Name, function(model)
        local rootGo = self.RoleModelPanel.GameObject
        local root = self.UiModelGo.transform
        local panelModel = root:FindTransform("PanelModel")
        local panelChip = panelModel:FindTransform("PanelChip")
        local modelCenter = panelChip:FindTransform("Center")
        XModelManager.AutoRotateWeapon(rootGo, model, modelId, self.GameObject, true, modelCenter)
    end)
    self.RoleModelPanel:ShowRoleModel()
    self.RoleModelPanel:LoadEffect(chip:GetEffect())

    if self._IsFirstOnEnable then
        self._IsFirstOnEnable = false
    else
        local oldChip = self._ViewModel:GetChip()
        if not oldChip or not oldChip:Equals(chip) then
            self.EffectRefresh.gameObject:SetActiveEx(true)
            self.Effect.gameObject:SetActiveEx(true)
        end
    end

    self._ViewModel:SetChip(chip)
    self._ViewModel:UpdateTabDetail()
    self._UiInfo:Update()
    self.ImageNormal.gameObject:SetActiveEx(false)
    self.ImagePress.gameObject:SetActiveEx(false)
    self._UiChipGrid1.GameObject:SetActiveEx(true)
    self._UiChipGrid2.GameObject:SetActiveEx(true)
    self.PanelTs.gameObject:SetActiveEx(false)
    self.PanelDetails.gameObject:SetActiveEx(true)
    self._UiChipGrid1:Update(chip)
    self._UiChipGrid2:Update(chip)
end

function XUiDlcHuntPersonalSupport:OnClickSelectChip()
    XLuaUiManager.Open("UiDlcHuntPersonalChoice")
end 