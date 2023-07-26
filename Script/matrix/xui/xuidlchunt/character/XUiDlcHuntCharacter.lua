local XViewModelDlcHuntCharacter = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntCharacter")
local XUiDlcHuntCharacterGrid = require("XUi/XUiDlcHunt/Character/XUiDlcHuntCharacterGrid")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiDlcHuntCharacterInfo = require("XUi/XUiDlcHunt/Character/XUiDlcHuntCharacterInfo")
local XUiDlcHuntCharacterInfoSkill = require("XUi/XUiDlcHunt/Character/XUiDlcHuntCharacterInfoSkill")

---@class XUiDlcHuntCharacter:XLuaUi
local XUiDlcHuntCharacter = XLuaUiManager.Register(XLuaUi, "UiDlcHuntCharacter")

function XUiDlcHuntCharacter:Ctor()
    ---@type XViewModelDlcHuntCharacter
    self._ViewModel = XViewModelDlcHuntCharacter.New()
end

function XUiDlcHuntCharacter:OnAwake()
    -- uiDlcHunt hide panelAsset
    self.PanelAsset.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.PanelTeamBtn, self.OnClickFight)
    XUiHelper.RegisterClickEvent(self, self.BtnDlcDetails, self.OnClickSkill)
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBack)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)

    --self.BtnHelp
    self.PanelOwnedInfo.gameObject:SetActiveEx(true)
    self.PanelOwnedInfo2.gameObject:SetActiveEx(false)

    ---@type XDynamicTableNormal
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCharacterList)
    self.DynamicTable:SetProxy(XUiDlcHuntCharacterGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridCharacterNew.gameObject:SetActiveEx(false)

    self.Root = self.Ui.UiModelGo.transform
    local model1 = self.Root:FindTransform("PanelModelCase1")
    local model2 = self.Root:FindTransform("PanelModelCase2")
    local model3 = self.Root:FindTransform("PanelModelCase3")
    self._UiEffectHuanren = self.Root:FindTransform("ImgEffect")
    self._UiEffectHuanren.gameObject:SetActiveEx(false)
    ---@type XUiPanelRoleModel
    self._UiModel1 = XUiPanelRoleModel.New(model1)
    
    model2.gameObject:SetActiveEx(false)
    model3.gameObject:SetActiveEx(false)

    self:SetActiveCameraNormal()
end

function XUiDlcHuntCharacter:OnStart(viewModel)
    if viewModel then
        self._ViewModel = viewModel
    end

    ---@type XUiDlcHuntCharacterInfo
    self._UiInfo = XUiDlcHuntCharacterInfo.New(self.PanelOwnedInfo, self._ViewModel)

    ---@type XUiDlcHuntCharacterInfoSkill
    self._UiSkill = XUiDlcHuntCharacterInfoSkill.New(self.PanelOwnedInfo2, self._ViewModel)

    self._ViewModel:OnStart()
end

function XUiDlcHuntCharacter:OnEnable()
    self:Update()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_SELECT_CHARACTER_UPDATE, self.OnFightCharacterUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE, self.UpdateCharacterInfo, self)
end

function XUiDlcHuntCharacter:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_SELECT_CHARACTER_UPDATE, self.OnFightCharacterUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_CHIP_GROUP_UPDATE, self.UpdateCharacterInfo, self)
end

function XUiDlcHuntCharacter:OnDestroy()
    self._ViewModel:OnDestroy()
end

function XUiDlcHuntCharacter:Update()
    local dataProvider = self._ViewModel:GetDataProvider()
    self.DynamicTable:SetDataSource(dataProvider)
    local selectedIndex = self._ViewModel:GetSelectedIndex()
    self.DynamicTable:ReloadDataASync(selectedIndex)
    self:UpdateFightBtn()
    self:UpdateCharacter(false)
end

---@param grid XUiDlcHuntCharacterGrid
function XUiDlcHuntCharacter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:SetViewModel(self._ViewModel)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self._ViewModel:SetCharacter(self.DynamicTable:GetData(index))
        self:UpdateSelected()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
    end
end

function XUiDlcHuntCharacter:UpdateSelected()
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        grid:UpdateSelected()
    end
    self:UpdateCharacter()
    self:UpdateFightBtn()
end

function XUiDlcHuntCharacter:UpdateCharacter(playEffect)
    local dataModel = self._ViewModel:GetDataModel()
    if dataModel then
        self._UiModel1:UpdateDlcModel(dataModel)
        self._UiModel1:ShowRoleModel()
        if playEffect ~= false then
            self._UiEffectHuanren.gameObject:SetActiveEx(false)
            self._UiEffectHuanren.gameObject:SetActiveEx(true)
        end
    else
        self._UiModel1:HideRoleModel()
    end
    self:UpdateCharacterInfo()
end

function XUiDlcHuntCharacter:UpdateCharacterInfo()
    self._UiInfo:Update()
end

function XUiDlcHuntCharacter:OnClickFight()
    self._ViewModel:RequestFight()
end

function XUiDlcHuntCharacter:OnFightCharacterUpdate()
    self:UpdateSelected()
    self:UpdateFightBtn()
end

function XUiDlcHuntCharacter:UpdateFightBtn()
    self.PanelTeamBtn.gameObject:SetActiveEx(not self._ViewModel:IsCharacterFighting())
end

function XUiDlcHuntCharacter:OnClickSkill()
    self:ShowSkill()
end

function XUiDlcHuntCharacter:ShowSkill()
    self._UiSkill.GameObject:SetActiveEx(true)
    self._UiInfo.GameObject:SetActiveEx(false)
    self._UiSkill:Update()
    self.SViewCharacterList.gameObject:SetActiveEx(false)
    self.PanelTeamBtn.gameObject:SetActiveEx(false)
    self.PanelTitle.gameObject:SetActiveEx(true)
    self.Text.text = self._ViewModel:GetCharacterName()
    self.TxtEn.text = self._ViewModel:GetCharacterNameEn()
    self:SetActiveCameraDetail(true)
end

function XUiDlcHuntCharacter:ShowInfo()
    self._UiSkill.GameObject:SetActiveEx(false)
    self._UiInfo.GameObject:SetActiveEx(true)
    self._UiInfo:Update()
    self.SViewCharacterList.gameObject:SetActiveEx(true)
    self:UpdateFightBtn()
    self.PanelTitle.gameObject:SetActiveEx(false)
    self:SetActiveCameraDetail(false)
end

function XUiDlcHuntCharacter:OnBtnBack()
    if self._UiSkill.GameObject.activeInHierarchy then
        self:ShowInfo()
        return
    end
    self:Close()
end

function XUiDlcHuntCharacter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiDlcHuntCharacter:SetActiveCameraNormal()
    local uiFarRootObj = self.UiModel.UiFarRoot
    local uiCameraFar = uiFarRootObj:FindTransform("FarCameraCharacter")
    uiCameraFar.gameObject:SetActiveEx(true)
    local uiNearRootObj = self.UiModel.UiNearRoot
    local uiCameraNear = uiNearRootObj:FindTransform("NearCameraCharacter")
    uiCameraNear.gameObject:SetActiveEx(true)
end

function XUiDlcHuntCharacter:SetActiveCameraDetail(value)
    local uiFarRootObj = self.UiModel.UiFarRoot
    local uiCameraFar = uiFarRootObj:FindTransform("FarCameraCharacter2")
    uiCameraFar.gameObject:SetActiveEx(value)
    local uiNearRootObj = self.UiModel.UiNearRoot
    local uiCameraNear = uiNearRootObj:FindTransform("NearCameraCharacter2")
    uiCameraNear.gameObject:SetActiveEx(value)
end

return XUiDlcHuntCharacter