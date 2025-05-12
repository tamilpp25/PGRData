local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiReformListGrid = require("XUi/XUiReform2nd/Reform/Main/XUiReformListGrid")
local XUiReformTool = require("XUi/XUiReform2nd/XUiReformTool")
local XUiReformListEnvironmentBtn = require("XUi/XUiReform2nd/Reform/Environment/XUiReformListEnvironmentBtn")
local XUiReformListPanelMobGridAffix = require("XUi/XUiReform2nd/Reform/Mob/XUiReformListPanelMobGridAffix")
local XUiReformListHead = require("XUi/XUiReform2nd/Reform/Main/XUiReformListHead")

---@field _Control XReformControl
---@class XUiReformList:XLuaUi
local XUiReformList = XLuaUiManager.Register(XLuaUi, "UiReformList")

function XUiReformList:Ctor()
    ---@type XViewModelReform2ndList
    self._ViewModel = self._Control:GetViewModelList()

    ---@type XUiReformListEnvironmentBtn
    self._CurrentEnvironment = false

    ---@type XUiReformListGrid
    self._GridList = {}

    self._GridNoList = {}

    ---@type XUiReformListHead
    self._GridHeadList = {}

    self._PlayAnimationList = true
end

function XUiReformList:OnAwake()
    self:BindExitBtns()
    self.DynamicTableNormal = XUiHelper.DynamicTableNormal(self, self.ListAffix, XUiReformListPanelMobGridAffix)

    local ItemId = XDataCenter.ItemManager.ItemId
    XUiPanelAsset.New(self, self.PanelAsset, ItemId.FreeGem, ItemId.ActionPoint, ItemId.Coin)

    local helpKey1, helpKey2 = self._Control:GetHelpKey()
    self:BindHelpBtn(self.BtnHelp, helpKey1)
    self:RegisterClickEvent(self.BtnPreview, self.OnClickReset)
    self.BtnSave.CallBack = function()
        self:OnClickSave()
    end

    self.GridEnemy.gameObject:SetActiveEx(false)
    if self.GridNo then
        self.GridNo.gameObject:SetActiveEx(false)
    end

    self:RegisterClickEvent(self.BtnEnvironment, self.OnClickEnvironment)
    self._CurrentEnvironment = XUiReformListEnvironmentBtn.New(self.BtnEnvironment, self)

    -- v3.5 移除困难难度, ui认为, 这与主界面的功能重复
    ---@type UnityEngine.UI.Toggle
    --local toggle = self.ToggleHard
    --toggle.onValueChanged:AddListener(function(isOn)
    --    self:OnClickToggleHard(isOn)
    --end)

    self:RegisterClickEvent(self.ButtonRecommend, self.OnClickRecommend)

    ---@type UnityEngine.UI.Toggle
    local toggleFullDesc = self.ToggleDesc
    toggleFullDesc.onValueChanged:AddListener(function(isOn)
        self:OnClickToggleFullDesc(isOn)
    end)
    toggleFullDesc.isOn = self._ViewModel.DataMob.IsFullDesc
end

function XUiReformList:OnStart(stage)
    self._ViewModel:SetStage(stage)
    -----@type UnityEngine.UI.Toggle
    --local toggle = self.ToggleHard
    --toggle.isOn = self._ViewModel:IsSelectToggleHard()
    self:Update()
    self:CheckUiEnvironmentAutoOpen(stage)
    self:UpdateHead()
    self:UpdateBgForDifficulty()
end

function XUiReformList:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_UPDATE_MOB, self.Update, self)
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_SELECT_MOB_GROUP, self.OnMobGroupSelected, self)
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_SELECT_MOB, self.OnMobSelected, self)
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_SELECT_AFFIX, self.OnAffixSelected, self)
    XEventManager.AddEventListener(XEventId.EVENT_REFORM_SELECT_ENVIRONMENT, self.UpdateEnvironment, self)
end

function XUiReformList:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_UPDATE_MOB, self.Update, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_SELECT_MOB_GROUP, self.OnMobGroupSelected, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_SELECT_MOB, self.OnMobSelected, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_SELECT_AFFIX, self.OnAffixSelected, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_REFORM_SELECT_ENVIRONMENT, self.UpdateEnvironment, self)
end

function XUiReformList:Update(playEffectQieHuan)
    local viewModel = self._ViewModel
    viewModel:Update()
    local data = viewModel.Data

    self.TxtCost.text = data.TxtPressure
    if data.PressureIsFull then
        self.TextPressureMax.gameObject:SetActiveEx(true)
        self.TextPressure.gameObject:SetActiveEx(false)
    else
        self.TextPressureMax.gameObject:SetActiveEx(false)
        self.TextPressure.gameObject:SetActiveEx(true)
        self.TextPressureValue.text = data.Pressure2NextStar
    end
    XUiReformTool.UpdateStar(self, data.StarAmount, data.StarAmountMax, data.IsMatchExtraStar)
    self:UpdateMob()

    if data.IsEnableBtnEnter then
        self.BtnSave:SetDisable(false, true)
    else
        self.BtnSave:SetDisable(true, false)
    end

    --if playEffectQieHuan then
    --    self:PlayAnimation("QieHuan")
    --end

    self:UpdateEnvironment()
    --self:UpdateToggle()
    self:UpdateAffix()
end

function XUiReformList:OnClickReset()
    local content = XUiHelper.GetText("ReformReset")
    XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, function()
        self._ViewModel:RequestResetReformData()
    end)
end

function XUiReformList:OnClickSave()
    self._ViewModel:RequestSaveSelectedMobGroup()
    self._ViewModel:RequestSaveReformData()
end

function XUiReformList:OnMobGroupSelected()
    self:Update()
end

function XUiReformList:OnMobSelected()
    self:Update()
end

function XUiReformList:OnAffixSelected()
    self._ViewModel:SetUpdate4Affix(true)
    self:Update()
end

function XUiReformList:OnClickEnvironment()
    self._Control:OpenUiEnvironment()
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

--function XUiReformList:UpdateToggleHard()
--    ---@type UnityEngine.UI.Toggle
--    local toggle = self.ToggleHard
--    if self._ViewModel:IsShowToggleHard() then
--        toggle.gameObject:SetActiveEx(true)
--    else
--        toggle.gameObject:SetActiveEx(false)
--    end
--    self:UpdateBgForDifficulty()
--end

--function XUiReformList:OnClickToggleHard(isOn)
--    self._ViewModel:OnClickToggleHard(isOn)
--    self:Update(false)
--    if isOn then
--        self._Control:SetNotJustUnlockToggleHard()
--    end
--end

function XUiReformList:OnClickRecommend()
    self._ViewModel:OnClickRecommend()
    self:Update(false)
end

--function XUiReformList:UpdateRedPointToggleHard()
--    if not self.Red then
--        return
--    end
--    local isOn = self.TogHell
--    if not isOn then
--        local isShowRedPoint = self._Control:IsChapterJustUnlockToggleHard()
--        isShowRedPoint = isShowRedPoint and self._ViewModel:IsShowToggleHard()
--        self.Red.gameObject:SetActiveEx(isShowRedPoint)
--    else
--        self.Red.gameObject:SetActiveEx(false)
--    end
--end

function XUiReformList:UpdateEffect()
    if self._ViewModel:IsSelectToggleHard() then
        self.Effect1.gameObject:SetActiveEx(false)
        self.Effect2.gameObject:SetActiveEx(true)
    else
        self.Effect1.gameObject:SetActiveEx(true)
        self.Effect2.gameObject:SetActiveEx(false)
    end
end

--function XUiReformList:UpdateToggle()
--    self:UpdateToggleHard()
--    self:UpdateRedPointToggleHard()
--    self:UpdateEffect()
--end

function XUiReformList:CheckUiEnvironmentAutoOpen(stage)
    self._Control:CheckUiEnvironmentAutoOpen(stage)
end

-- 背景
function XUiReformList:UpdateBgForDifficulty()
    if self._ViewModel:IsSelectToggleHard() then
        self.BgCommonBai.gameObject:SetActiveEx(false)
        self.BgCommonHard.gameObject:SetActiveEx(true)
        self:PlayAnimation("Red")
        self:StopAnimation("Green")
    else
        self.BgCommonBai.gameObject:SetActiveEx(true)
        self.BgCommonHard.gameObject:SetActiveEx(false)
        self:StopAnimation("Red")
        self:PlayAnimation("Green")
    end
end

function XUiReformList:UpdateAffix()
    self._ViewModel:UpdateMobAffix()
    local viewModel = self._ViewModel
    self.TxtAffixNum.text = viewModel.DataMob.TextAffixAmount

    local affixs = viewModel.DataMob.AffixList
    self.DynamicTableNormal:SetDataSource(affixs)
    self.DynamicTableNormal:ReloadDataSync()
    self.GridBuff.gameObject:SetActiveEx(false)
end

---@param grid XUiReformListPanelMobGridAffix
function XUiReformList:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetViewModel(self._ViewModel)
        grid:Update(self.DynamicTableNormal:GetData(index))

    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if self._PlayAnimationList then
            self._PlayAnimationList = false
            self:PlayListAnimation()
        end
    end
end

function XUiReformList:UpdateMob()
    local viewModel = self._ViewModel
    local data = viewModel.Data
    self:UpdateDynamicItem(self._GridList, data.MobData, self.GridEnemy, XUiReformListGrid)

    -- 如果动态刷新, 那这里的空格顺序就会出问题
    -- ui 最多显示6格
    if self.GridNo then
        local index = 0
        for i = #data.MobData + 1, 6 do
            index = index + 1
            local no = self._GridNoList[index]
            if not no then
                no = CS.UnityEngine.Object.Instantiate(self.GridNo, self.GridEnemy.transform.parent)
                self._GridNoList[index] = no
            end
            no.gameObject:SetActiveEx(true)
        end

        for i = index + 1, #self._GridNoList do
            local no = self._GridNoList[i]
            no.gameObject:SetActiveEx(false)
        end
    end


    -- update mob amount
    self.TxtEnemyNum.text = viewModel.DataMob.TextMobAmount
end

--可上阵角色
function XUiReformList:UpdateHead()
    local characterIds = XMVCA.XReform:GetCharacterCanSelect(self._ViewModel:GetCurrentStageId())
    if #characterIds > 0 then
        self:UpdateDynamicItem(self._GridHeadList, characterIds, self.HeadWhite, XUiReformListHead)
        local isHardMode = self._ViewModel:IsSelectToggleHard()
        for i = 1, #characterIds do
            local head = self._GridHeadList[i]
            head:Switch(isHardMode)
        end
        self.PanelTips.gameObject:SetActiveEx(true)
    else
        self.PanelTips.gameObject:SetActiveEx(false)
    end
end

function XUiReformList:UpdateBtnRecommend()
    self.ButtonRecommend.gameObject:SetActiveEx(self._ViewModel:HasRecommend())
end

function XUiReformList:OnClickToggleFullDesc(isOn)
    self._ViewModel:SetIsFullDesc(isOn)
end

function XUiReformList:PlayListAnimation()
    local gap = 0.1

    local isHardMode = self._ViewModel:IsSelectToggleHard()
    ---@type XUiReformListPanelMobGridAffix[]
    local grids = self.DynamicTableNormal:GetGrids()
    for index, grid in pairs(grids) do
        grid:Close()
        grid:Tween(index * gap, nil, function()
            grid:Open()
            if isHardMode then
                grid:PlayAnimation("Red")
                grid:StopAnimation("Green")
            else
                grid:StopAnimation("Red")
                grid:PlayAnimation("Green")
            end
        end)
    end

    for i = 1, #self._GridList do
        local grid = self._GridList[i]
        grid:Close()
        grid:Tween(i * gap, nil, function()
            grid:Open()
            if isHardMode then
                grid:PlayAnimation("Red")
                grid:StopAnimation("Green")
            else
                grid:StopAnimation("Red")
                grid:PlayAnimation("Green")
            end
        end)
    end

    local timeGridValid = #self._GridList * gap
    for i = 1, #self._GridNoList do
        local grid = self._GridNoList[i]
        grid.gameObject:SetActiveEx(false)
        self:Tween(i * gap + timeGridValid, nil, function()
            grid.gameObject:SetActiveEx(true)
        end)
    end
end

return XUiReformList
