---@class XUiTheatre3QuantumChoose : XLuaUi
---@field PanelEquipment XUiButtonGroup
---@field _Control XTheatre3Control
local XUiTheatre3QuantumChoose = XLuaUiManager.Register(XLuaUi, "UiTheatre3QuantumChoose")

function XUiTheatre3QuantumChoose:OnAwake()
    self:AddBtnListener()
end

function XUiTheatre3QuantumChoose:OnStart(suitIdList)
    self:_InitSuit(suitIdList)
    self:_InitCharacterPanel()
    self:_InitBtn()
    self:_InitEffect()
    self:UpdateBoxRefreshBtn()
end

function XUiTheatre3QuantumChoose:OnEnable()
    self:UpdateSuit()
    self:UpdateBtn()
    self:RefreshEffect()
end

--region Ui - Suit
function XUiTheatre3QuantumChoose:_InitSuit(suitIdList)
    local XUiTheatre3PanelQuantumSuit = require("XUi/XUiTheatre3/Adventure/Quantum/XUiTheatre3PanelQuantumSuit")
    self._BeSelectSuitIdList = suitIdList
    self._CurSelectSuitIndex = 0
    ---@type XUiComponent.XUiButton[]
    self._ButtonList = {
        self.BtnEquipment1,
        self.BtnEquipment2,
        self.BtnEquipment3,
    }
    self.PanelEquipment:Init(self._ButtonList, function(tabIndex) self:OnSuitSelects(tabIndex) end)
    ---@type XUiTheatre3PanelQuantumSuit[]
    self._GridSuitList = {
        XUiTheatre3PanelQuantumSuit.New(self["BtnEquipment" .. 1], self, self._BeSelectSuitIdList[1], 1, true),
        XUiTheatre3PanelQuantumSuit.New(self["BtnEquipment" .. 2], self, self._BeSelectSuitIdList[2], 2, true),
        XUiTheatre3PanelQuantumSuit.New(self["BtnEquipment" .. 3], self, self._BeSelectSuitIdList[3], 3, true),
    }
    for i, grid in ipairs(self._GridSuitList) do
        if XTool.IsNumberValid(self._BeSelectSuitIdList[i]) then
            grid:Open()
        else
            grid:Close()
        end
    end
end

function XUiTheatre3QuantumChoose:OnSuitSelects(index)
    self._CurSelectSuitIndex = index
    for i, grid in ipairs(self._GridSuitList) do
        if XTool.IsNumberValid(self._BeSelectSuitIdList[i]) then
            grid:UpdateSelect(self._CurSelectSuitIndex == i)
        end
    end
end

function XUiTheatre3QuantumChoose:UpdateSuit()
    for i, grid in ipairs(self._GridSuitList) do
        if XTool.IsNumberValid(self._BeSelectSuitIdList[i]) then
            grid:UpdateSuitDesc(self._IsShowEquipDetail)
        end
    end
end
--endregion

--region Ui - CharacterPanel
function XUiTheatre3QuantumChoose:_InitCharacterPanel()
    local XUiTheatre3PanelSlotCharacter = require("XUi/XUiTheatre3/Adventure/Quantum/XUiTheatre3PanelSlotCharacter")
    ---@type XUiTheatre3PanelSlotCharacter
    self._PanelSlotCharacter = XUiTheatre3PanelSlotCharacter.New(self.BubbleCharacter, self)
    self._IsOpenPanelSlotCharacter = false
end

function XUiTheatre3QuantumChoose:OpenCharacterPanel()
    if not self._IsOpenPanelSlotCharacter then
        self._IsOpenPanelSlotCharacter = true
        self._PanelSlotCharacter:Open()
        self:PlayAnimation("BubbleCharacterEnable")
    end
    self._PanelSlotCharacter:Refresh(self._BeSelectSuitIdList[self._CurSelectSuitIndex])
end

function XUiTheatre3QuantumChoose:CloseCharacterPanel()
    if self._IsOpenPanelSlotCharacter then
        self._IsOpenPanelSlotCharacter = false
        self._PanelSlotCharacter:Close()
    end
end
--endregion

--region Ui - BuffDetail
function XUiTheatre3QuantumChoose:CloseBuffDetail()
    for _, grid in ipairs(self._GridSuitList) do
        grid:CloseBuffTip()
    end
end
--endregion

--region Ui - Btn
local CSUiButtonState = CS.UiButtonState
function XUiTheatre3QuantumChoose:_InitBtn()
    self._IsShowEquipDetail = self._Control:GetToggleValue("UiTheatre3EquipmentChooseSwitch")
    self.BtnDetail:SetButtonState(self._IsShowEquipDetail and CSUiButtonState.Select or CSUiButtonState.Normal)
end

function XUiTheatre3QuantumChoose:UpdateBtn()
    -- 套装数
    local count = self._Control:GetSlotCapcity(1) + self._Control:GetSlotCapcity(2) + self._Control:GetSlotCapcity(3)
    self.BtnSetBag:SetNameByGroup(1, XUiHelper.ReadTextWithNewLine("Theatre3EquipSuitNumNewLine", count))
end
--endregion

--region Ui - Effect
function XUiTheatre3QuantumChoose:RefreshEffect()
    
end
--endregion

--region Ui - Effect
function XUiTheatre3QuantumChoose:_InitEffect()
    if not self.Effect then
        ---@type UnityEngine.Transform
        self.Effect = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/Effect")
    end
end

function XUiTheatre3QuantumChoose:RefreshEffect()
    if not self.Effect or self._Control:IsAdventureALine() then
        return
    end
    local quantumLevelCfg = self._Control:GetCfgQuantumLevelByValue(self._Control:GetAdventureQuantumValue(true) + self._Control:GetAdventureQuantumValue(false))
    --全屏特效
    if quantumLevelCfg and not string.IsNilOrEmpty(quantumLevelCfg.ScreenEffectUrl) then
        local screenEffectUrl = self._Control:GetClientConfig(quantumLevelCfg.ScreenEffectUrl, 2)
        self.Effect:LoadUiEffect(screenEffectUrl)
    end
end
--endregion

--region Ui - BtnListener
function XUiTheatre3QuantumChoose:AddBtnListener()
    self._Control:RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    self._Control:RegisterClickEvent(self, self.BtnSetBag, self.OnShowEquip)
    self._Control:RegisterClickEvent(self, self.BtnEmpty, self.OnBtnEmptyClick)
    self._Control:RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick)
    self._Control:RegisterClickEvent(self, self.BtnRefresh, self.OnClickBoxRefresh)
end

function XUiTheatre3QuantumChoose:OnBtnBackClick()
    self._Control:OpenQuantumTextTip(handler(self, self.Close),
            XUiHelper.ReadTextWithNewLineWithNotNumber("TipTitle"),
            XUiHelper.ReadTextWithNewLineWithNotNumber("Theatre3EquipBackTip"))
end

function XUiTheatre3QuantumChoose:OnShowEquip()
    self._Control:OpenShowEquipPanel()
end

function XUiTheatre3QuantumChoose:OnBtnEmptyClick()
    self:CloseBuffDetail()
end

function XUiTheatre3QuantumChoose:OnBtnDetailClick()
    self._IsShowEquipDetail = not self._IsShowEquipDetail
    self._Control:SaveToggleValue("UiTheatre3EquipmentChooseSwitch", self._IsShowEquipDetail)
    self:UpdateSuit()
end
--endregion

--region 装备箱刷新

function XUiTheatre3QuantumChoose:UpdateBoxRefreshBtn()
    local isRefreshTimesNone = false
    local freeTimes, _ = self._Control:GetFreeRefreshTimes()
    self._IsCanFreeRefresh = freeTimes > 0
    if self._IsCanFreeRefresh then
        -- 免费刷新
        self.BtnRefresh:SetRawImageVisible(false)
        self.BtnRefresh:SetNameByGroup(0, "")
        self.BtnRefresh:SetButtonState(CS.UiButtonState.Normal)
    else
        -- 付费刷新
        local payTimes, _ = self._Control:GetPayRefreshTimes()
        local isCanPayRefresh, costNum = self._Control:GetPayRefreshCost()
        self.BtnRefresh:SetRawImageVisible(true)
        self.BtnRefresh:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XEnumConst.THEATRE3.RefreshBoxCoin))
        self.BtnRefresh:SetNameByGroup(0, string.format("<color=%s>x%s</color>", isCanPayRefresh and "#FFFFFF" or "#FF0000", costNum))
        isRefreshTimesNone = payTimes <= 0
    end
    local payTimes, totalPayTimes = self._Control:GetTotalRefreshTimes()
    self.TxtTimes.text = XUiHelper.GetText("Theatre3RefreshTimes", payTimes, totalPayTimes)
    self.BtnRefresh:SetButtonState(isRefreshTimesNone and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiTheatre3QuantumChoose:UpdateEquips()
    local step = self._Control:GetAdventureLastStep(XEnumConst.THEATRE3.StepType.EquipReward)
    if step then
        self._BeSelectSuitIdList = step:GetEquipIds()
        for i = 1, 3 do
            local suitId = self._BeSelectSuitIdList[i]
            local grid = self._GridSuitList[i]
            if XTool.IsNumberValid(suitId) then
                grid:Open()
                grid:RefreshBySuitId(suitId)
                grid:UpdateSuitDesc(self._IsShowEquipDetail)
                grid:CloseBuffTip()
            else
                grid:Close()
            end
        end
    end
end

function XUiTheatre3QuantumChoose:OnClickBoxRefresh()
    if self._Control:CheckRefreshEquipBox() then
        self._Control:RefreshEquipBoxRequest(function()
            self:UpdateEquips()
            self:UpdateBoxRefreshBtn()
            if self._IsOpenPanelSlotCharacter then
                self._PanelSlotCharacter:Refresh(self._BeSelectSuitIdList[self._CurSelectSuitIndex])
            end
        end)
    end
end

--endregion

return XUiTheatre3QuantumChoose