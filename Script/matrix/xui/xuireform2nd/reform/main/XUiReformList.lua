local XUiReformListTabButton = require("XUi/XUiReform2nd/Reform/Main/XUiReformListTabButton")
local XUiReformListGrid = require("XUi/XUiReform2nd/Reform/Main/XUiReformListGrid")
local XUiReformListPanelMob = require("XUi/XUiReform2nd/Reform/Mob/XUiReformListPanelMob")
local XUiReformListPanelStage = require("XUi/XUiReform2nd/Reform/Stage/XUiReformListPanelStage")
local XUiReformTool = require("XUi/XUiReform2nd/XUiReformTool")
local XUiReformListEnvironment = require("XUi/XUiReform2nd/Reform/Environment/XUiReformListEnvironment")
local XUiReformListEnvironmentBtn = require("XUi/XUiReform2nd/Reform/Environment/XUiReformListEnvironmentBtn")

---@field _Control XReformControl
---@class XUiReformList:XLuaUi
local XUiReformList = XLuaUiManager.Register(XLuaUi, "UiReformList")

function XUiReformList:Ctor()
    ---@type XViewModelReform2ndList
    self._ViewModel = self._Control:GetViewModelList()

    ---@type XUiReformListTabButton[]
    self._ButtonGroup = {}

    ---@type XUiReformListPanelMob
    self._PanelMob = false

    ---@type XUiReformListPanelStage
    self._PanelStage = false

    ---@type XUiReformListEnvironment
    self._PanelEnvironment = false

    ---@type XUiReformListEnvironmentBtn
    self._CurrentEnvironment = false

    self._Index = 0

    ---@type XUiReformListGrid
    self._GridList = {}

    self._TimerTween = false
end

function XUiReformList:OnAwake()
    self._PanelMob = XUiReformListPanelMob.New(self.PanelReform, self)

    self._PanelStage = XUiReformListPanelStage.New(self.PanelFubenReform, self._ViewModel)

    self._PanelEnvironment = XUiReformListEnvironment.New(self.PanelEnvironment, self)

    self._PanelMob:Close()
    self._PanelStage:Hide()

    local ItemId = XDataCenter.ItemManager.ItemId
    XUiPanelAsset.New(self, self.PanelAsset, ItemId.FreeGem, ItemId.ActionPoint, ItemId.Coin)

    local helpKey1, helpKey2 = self._Control:GetHelpKey()
    self:BindHelpBtn(self.BtnHelp, helpKey1)
    --self:BindHelpBtn(self.BtnHelpChapter, helpKey2)
    self.BtnHelpChapter.gameObject:SetActiveEx(false)
    self:BindExitBtns()
    self:RegisterClickEvent(self.BtnHelpChapter, self.OnClickStageDetail)
    self:RegisterClickEvent(self.BtnPreview, self.OnClickReset)
    self.BtnSave.CallBack = function()
        self:OnClickSave()
    end
    self:RegisterClickEvent(self.BtnCloseReform, self.OnClickCloseChildUi)

    self.ReformGroup.gameObject:SetActiveEx(false)
    self.GirdEnemy.gameObject:SetActiveEx(false)
    self.BtnCloseReform.gameObject:SetActiveEx(false)

    self:RegisterClickEvent(self.BtnEnvironment, self.OnClickEnvironment)
    self._CurrentEnvironment = XUiReformListEnvironmentBtn.New(self.BtnEnvironment, self)
end

function XUiReformList:OnStart(stage)
    self._ViewModel:SetStage(stage)
    self:Update()
    self:UpdateTextExtraStar()
end

function XUiReformList:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_UPDATE_MOB, self.Update, self)
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_SELECT_MOB_GROUP, self.OnMobGroupSelected, self)
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_SELECT_MOB, self.OnMobSelected, self)
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_SELECT_AFFIX, self.OnAffixSelected, self)
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_CLOSE_DETAIL, self.OnClickCloseChildUi, self)
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_SELECT_ENVIRONMENT, self.UpdateEnvironment, self)
    --self._PanelMob:OnEnable()
end

function XUiReformList:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_UPDATE_MOB, self.Update, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_SELECT_MOB_GROUP, self.OnMobGroupSelected, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_SELECT_MOB, self.OnMobSelected, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_SELECT_AFFIX, self.OnAffixSelected, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_CLOSE_DETAIL, self.OnClickCloseChildUi, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_SELECT_ENVIRONMENT, self.UpdateEnvironment, self)
    self._PanelMob:Close()
end

function XUiReformList:OnDestroy()
    if self._TimerTween then
        XScheduleManager.UnSchedule(self._TimerTween)
        self._TimerTween = false
    end
end

function XUiReformList:Update(playEffectQieHuan)
    local viewModel = self._ViewModel
    viewModel:Update()
    local data = viewModel.Data

    self.Text.text = data.StageName

    self.TxtCost.text = data.TxtPressure
    self.TextPressure.text = data.Pressure2NextStar

    if self.TxtCostEffect then
        if data.IsPlayPressureEffect then
            self.TxtCostEffect.gameObject:SetActive(false)
            self.TxtCostEffect.gameObject:SetActive(true)
        else
            self.TxtCostEffect.gameObject:SetActive(false)
        end
    end
    XUiReformTool.UpdateStar(self, data.StarAmount, data.StarAmountMax, data.IsMatchExtraStar)

    if self.Nor then
        self.Nor.gameObject:SetActiveEx(data.IsMatchExtraStar)
    end
    if self.NorEffect then
        self.NorEffect.gameObject:SetActive(data.IsMatchExtraStar)
    end
    if self.Dis then
        self.Dis.gameObject:SetActiveEx(not data.IsMatchExtraStar)
    end

    local buttonGroupData = data.BtnGroup
    for i = 1, #buttonGroupData do
        local buttonData = buttonGroupData[i]
        local button = self._ButtonGroup[i]
        if not button then
            local uiButton = CS.UnityEngine.GameObject.Instantiate(self.ReformGroup.gameObject, self.ReformGroup.parent)
            button = XUiReformListTabButton.New(uiButton, viewModel)
            self._ButtonGroup[i] = button
        end
        button:SetData(buttonData)
        button.GameObject:SetActiveEx(true)
    end
    for i = #buttonGroupData + 1, #self._ButtonGroup do
        local button = self._ButtonGroup[i]
        button.GameObject:SetActiveEx(false)
    end

    self:UpdateDynamicItem(self._GridList, data.MobData, self.GirdEnemy, XUiReformListGrid)

    if data.IsEnableBtnEnter then
        self.BtnSave:SetDisable(false, true)
        --self.BtnSave:SetButtonState(CS.UiButtonState.Normal)
    else
        self.BtnSave:SetDisable(true, false)
        --self.BtnSave:SetButtonState(CS.UiButtonState.Disable)
    end

    if playEffectQieHuan then
        self:PlayAnimation("QieHuan")
    end

    self:UpdateEnvironment()
end

---@param grid XUiReformListGrid
--function XUiReformList:OnDynamicTableEvent(event, index, grid)
--    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
--        grid:SetViewModel(self._ViewModel)
--
--    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
--        local data = self.DynamicTable:GetData(index)
--        grid:Update(data)
--
--    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
--
--    end
--end

function XUiReformList:OnClickReset()
    local content = XUiHelper.GetText("ReformReset")
    XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, function()
        self._ViewModel:RequestResetReformData()
    end)
end

function XUiReformList:OnClickSave()
    if self._ViewModel.Data.IsDisableFightChapter5 then
        XUiManager.TipText("ReformChapter5")
        return
    end
    self._ViewModel:RequestSaveReformData()
end

function XUiReformList:OnMobGroupSelected()
    self._PanelMob:Show()
    self._PanelMob:Update()
    self.BtnCloseReform.gameObject:SetActiveEx(true)
    self:Update()
    self:Scroll2CurrentMobGroup()
end

function XUiReformList:OnClickCloseChildUi()
    if self._PanelMob:IsNodeShow() then
        self._PanelMob:Close()
        self:RevertScroll()
    end
    self._PanelStage:Hide()
    self._PanelEnvironment:Close()
    self.BtnCloseReform.gameObject:SetActiveEx(false)
    self:Update()
end

function XUiReformList:OnMobSelected()
    self._PanelMob:Update()
    self:Update()
end

function XUiReformList:OnAffixSelected()
    --self._PanelMob:UpdateAffix()
    self._ViewModel:SetUpdate4Affix(true)
    self._PanelMob:Update()

    self:Update()
    --self._ViewModel:UpdateMobData()
    --local grids = self.DynamicTable:GetGrids()
    --for i, grid in pairs(grids) do
    --    local data = self.DynamicTable:GetData(i)
    --    grid:Update(data)
    --end
end

function XUiReformList:OnClickStageDetail()
    self._PanelStage:Show()
    self.BtnCloseReform.gameObject:SetActiveEx(true)
end

function XUiReformList:UpdateTextExtraStar()
    local textExtra1 = XUiHelper.TryGetComponent(self.Nor.transform, "Text", "Text")
    local textExtra2 = XUiHelper.TryGetComponent(self.Dis.transform, "Text", "Text")
    if textExtra1 and textExtra2 then
        local textExtraStar = self._ViewModel.Data.TextExtraStar
        textExtra1.text = textExtraStar
        textExtra2.text = textExtraStar
    end
end

function XUiReformList:OnClickEnvironment()
    self._PanelEnvironment:Open()
    self.BtnCloseReform.gameObject:SetActiveEx(true)
end

function XUiReformList:UpdateEnvironment()
    self._ViewModel:UpdateSelectedEnvironment()
    local data = self._ViewModel.DataEnvironment.DataSelectedEnvironment
    self._CurrentEnvironment:Update(data)
end

function XUiReformList:UpdateDynamicItem(gridArray, dataArray, uiObject, class)
    if #gridArray == 0 then
        uiObject.gameObject:SetActiveEx(false)
    end
    for i = 1, #dataArray do
        local grid = gridArray[i]
        if not grid then
            local uiObject = CS.UnityEngine.Object.Instantiate(uiObject, uiObject.transform.parent)
            grid = class.New(uiObject, self)
            gridArray[i] = grid
        end
        grid:Open()
        grid:Update(dataArray[i], i)
    end
    for i = #dataArray + 1, #gridArray do
        local grid = gridArray[i]
        grid:Close()
    end
end

function XUiReformList:Scroll2CurrentMobGroup()
    local mobIndex = self._ViewModel.GridIndex

    ---@type UnityEngine.UI.ScrollRect
    local scrollRect = self.PanelEnemyList
    scrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted

    ---@type UnityEngine.RectTransform
    local content = self.Content
    local position = content.anchoredPosition
    local startX = position.x

    ---@type UnityEngine.RectTransform
    local leftPanel = self.PanelReform

    ---@type UnityEngine.RectTransform
    local viewPort = self.Content.parent:GetComponent("RectTransform")

    ---@type UnityEngine.RectTransform
    local grid = self.GirdEnemy
    local endX = -mobIndex * grid.rect.width + viewPort.rect.width - leftPanel.rect.width
    endX = math.min(0, endX)

    local duration = 0.2

    if self._TimerTween then
        XScheduleManager.UnSchedule(self._TimerTween)
    end
    self._TimerTween = XUiHelper.Tween(duration, function(f)
        position.x = startX * (1 - f) + endX * f
        content.anchoredPosition = position
    end)
end

function XUiReformList:RevertScroll()
    ---@type UnityEngine.UI.ScrollRect
    local scrollRect = self.PanelEnemyList
    scrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
end

function XUiReformList:OnPanelMobClose()
    self:OnClickCloseChildUi()
    self:RevertScroll()
end

return XUiReformList
