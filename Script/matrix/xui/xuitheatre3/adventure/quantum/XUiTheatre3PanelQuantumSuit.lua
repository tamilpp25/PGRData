---@class XUiTheatre3PanelQuantumSuitNumberLabel
---@field EquipId number
---@field Mask UnityEngine.Transform
---@field TxtIndex UnityEngine.UI.Text

---@class XUiTheatre3PanelQuantumSuitTraitLabel
---@field Index number
---@field TxtTitle UnityEngine.UI.Text
---@field TxtInformation UnityEngine.UI.Text

---@class XUiTheatre3PanelQuantumSuit : XUiNode
---@field Select UnityEngine.Transform
---@field PanelTag UnityEngine.Transform
---@field PanelNum UnityEngine.Transform
---@field PanelAffix UnityEngine.Transform
---@field ImgHead UnityEngine.UI.RawImage
---@field ImgType1 UnityEngine.UI.RawImage
---@field ImgType2 UnityEngine.UI.RawImage
---@field ImgBubbleBg UnityEngine.UI.RawImage
---@field TxtTitle UnityEngine.UI.Text
---@field TxtSuitDetails UnityEngine.UI.Text
---@field TxtStory UnityEngine.UI.Text
---@field BtnYes1 XUiComponent.XUiButton
---@field BtnDetail XUiComponent.XUiButton
---@field BtnSuit XUiComponent.XUiButton
---@field Parent XUiTheatre3QuantumChoose
---@field _Control XTheatre3Control
local XUiTheatre3PanelQuantumSuit = XClass(XUiNode, "XUiTheatre3PanelQuantumSuit")

function XUiTheatre3PanelQuantumSuit:OnStart(suitId, index, isQuantum)
    self._Index = index
    self._IsQuantum = isQuantum
    self._Pool = {}
    ---@type XUiComponent.XUiButton
    self.BtnYes = XUiHelper.TryGetComponent(self.Transform, "BubbleQuantumSet/ImgBubbleBg/BtnTongBlue", "XUiButton")
    if self.BtnYes1 then
        self.BtnYes1.gameObject:SetActiveEx(false)
    end
    self:_InitSuitInfo(suitId)
    self:_InitEquipLabel(suitId)
    self:_InitBuffTip()
    
    self:AddBtnListener()
end

function XUiTheatre3PanelQuantumSuit:OnEnable()
    self:Refresh()
end

function XUiTheatre3PanelQuantumSuit:Refresh()
    if not self._SuitConfig then
        return
    end
    self:_UpdateSuitInfo()
    self:_UpdateEquipLabel()
    self:_UpdateBuffTip()
end

function XUiTheatre3PanelQuantumSuit:RefreshBySuitId(suitId)
    self:_InitSuitInfo(suitId)
    self:_InitEquipLabel(suitId)
    self:_InitBuffTip()
    self:Refresh()
end

--region Ui - SuitInfo
function XUiTheatre3PanelQuantumSuit:_InitSuitInfo(suitId)
    if not XTool.IsNumberValid(suitId) then
        return
    end
    self._SuitConfig = self._Control:GetSuitById(suitId)
end

function XUiTheatre3PanelQuantumSuit:_UpdateSuitInfo()
    local headIcon = self._SuitConfig.Icon
    if not string.IsNilOrEmpty(headIcon) then
        self.ImgHead:SetRawImage(headIcon)
    end
    self.TxtTitle.text = self._SuitConfig.SuitName
    self.TxtStory.text = self._SuitConfig.RecommendDesc
    self.PanelRecommend.gameObject:SetActiveEx(not string.IsNilOrEmpty(self._SuitConfig.RecommendDesc) and not self._IsSelect)
    self.ImgType1.gameObject:SetActiveEx(self._SuitConfig.UseType ~= XEnumConst.THEATRE3.SuitUseType.Backend)
    self.ImgType2.gameObject:SetActiveEx(self._SuitConfig.UseType == XEnumConst.THEATRE3.SuitUseType.Backend)
end

function XUiTheatre3PanelQuantumSuit:UpdateSuitDesc(isDetail)
    if not self._SuitConfig then
        return
    end
    if self._IsQuantum then
        self.TxtSuitDetails.text = self._Control:GetAdventureQuantumSuitDesc(self._SuitConfig.Id, isDetail)
    else
        self.TxtSuitDetails.text = self._Control:GetAdventureSuitDesc(self._SuitConfig.Id, isDetail)
    end
end
--endregion

--region Ui - EquipLabel
function XUiTheatre3PanelQuantumSuit:_InitEquipLabel(suitId)
    ---@type XUiTheatre3PanelQuantumSuitNumberLabel[]
    self._NumberLabelList = {}
    if not XTool.IsNumberValid(suitId) then
        return
    end
    local equips = self._Control:GetAllSuitEquip(suitId)
    for i, equipConfig in ipairs(equips) do
        ---@type XUiTheatre3PanelQuantumSuitNumberLabel
        local numberLabel = {}
        local go = self._Pool[i]
        if not go then
            go = i == 1 and self.PanelNum or XUiHelper.Instantiate(self.PanelNum, self.PanelNum.parent)
            self._Pool[i] = go
        end
        go.gameObject:SetActiveEx(true)
        XTool.InitUiObjectByUi(numberLabel, go)
        numberLabel.EquipId = equipConfig.Id
        numberLabel.TxtIndex.text = "0" .. i
        numberLabel.Mask.gameObject:SetActiveEx(true)
        self._NumberLabelList[i] = numberLabel
    end
    for i = #equips + 1, #self._Pool do
        self._Pool[i].gameObject:SetActiveEx(false)
    end
end

function XUiTheatre3PanelQuantumSuit:_UpdateEquipLabel()
    local isEquip = false
    for _, label in ipairs(self._NumberLabelList) do
        if self._Control:IsWearEquip(label.EquipId) then
            isEquip = true
            label.Mask.gameObject:SetActiveEx(false)
        else
            label.Mask.gameObject:SetActiveEx(true)
        end
    end
    self.PanelTag.gameObject:SetActiveEx(isEquip)
end
--endregion

--region Ui - BuffTip
function XUiTheatre3PanelQuantumSuit:_InitBuffTip()
    self._IsNotHaveBuffTip = not self._SuitConfig 
            or (self._IsQuantum and XTool.IsTableEmpty(self._SuitConfig.QubitTraitName)) 
            or (not self._IsQuantum and XTool.IsTableEmpty(self._SuitConfig.TraitName))
    if not self._IsNotHaveBuffTip then
        local beTraitName = self._IsQuantum and self._SuitConfig.QubitTraitName or self._SuitConfig.TraitName
        ---@type XUiTheatre3PanelQuantumSuitTraitLabel[]
        self._TraitLabelList = {}
        for i, traitName in ipairs(beTraitName) do
            ---@type XUiTheatre3PanelQuantumSuitTraitLabel
            local traitLabel = {}
            XTool.InitUiObjectByUi(traitLabel, 
                    i == 1 and self.ImgBubbleBg.transform or XUiHelper.Instantiate(self.ImgBubbleBg.transform, self.ImgBubbleBg.transform.parent))
            traitLabel.Index = i
            traitLabel.TxtTitle.text = traitName
            if self._IsQuantum then
                traitLabel.TxtInformation.text = self._Control:GetAdventureQuantumTraitDesc(self._SuitConfig.Id, i)
            else
                traitLabel.TxtInformation.text = self._Control:GetAdventureTraitDesc(self._SuitConfig.Id, i)
            end
        end
    end
    self._IsOpenBuffTip = false
    self.BtnSuit.gameObject:SetActiveEx(not self._IsNotHaveBuffTip)
end

function XUiTheatre3PanelQuantumSuit:_UpdateBuffTip()
    -- 左边超屏了就放到右边
    local anchoredPosition = self.PanelAffix.anchoredPosition
    local panelAffixPosX = anchoredPosition.x
    local panelAffixPosY = anchoredPosition.y
    local pos = self.Parent.Transform:InverseTransformPoint(self.Transform.position)
    local offsetX = self.Parent.Transform.rect.width / 2 + pos.x - self.Transform.rect.width / 2

    if offsetX < self.PanelAffix.rect.width then
        self.PanelAffix.anchorMin = Vector2(1, 1)
        self.PanelAffix.anchorMax = Vector2(1, 1)
        self.PanelAffix.pivot = Vector2(0, 1)
        self.PanelAffix.anchoredPosition = Vector2(-panelAffixPosX, panelAffixPosY)
    else
        self.PanelAffix.anchorMin = Vector2(0, 1)
        self.PanelAffix.anchorMax = Vector2(0, 1)
        self.PanelAffix.pivot = Vector2(1, 1)
        self.PanelAffix.anchoredPosition = Vector2(panelAffixPosX, panelAffixPosY)
    end
    self.PanelAffix.gameObject:SetActiveEx(self._IsOpenBuffTip)
end

function XUiTheatre3PanelQuantumSuit:OpenBuffTip()
    if self._IsOpenBuffTip then
        return
    end
    self._IsOpenBuffTip = true
    self:_UpdateBuffTip()
end

function XUiTheatre3PanelQuantumSuit:CloseBuffTip()
    if not self._IsOpenBuffTip then
        return
    end
    self._IsOpenBuffTip = false
    self:_UpdateBuffTip()
end
--endregion

--region Ui - SelectState
function XUiTheatre3PanelQuantumSuit:UpdateSelect(isSelect, showRecommend)
    self._IsSelect = isSelect
    if self.Select then
        self.Select.gameObject:SetActiveEx(self._IsSelect)
    end
    if self.BtnYes then
        self.BtnYes.gameObject:SetActiveEx(self._IsSelect)
    end
    if self.PanelRecommend then
        self.PanelRecommend.gameObject:SetActiveEx(showRecommend or not self._IsSelect)
    end
    if not self._IsSelect then
        self:CloseBuffTip()
    end
end
--endregion

--region Ui - BtnListener
function XUiTheatre3PanelQuantumSuit:AddBtnListener()
    self._Control:RegisterClickEvent(self, self.BtnYes, self.OnBtnYesClick)
    self._Control:RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick)
    self._Control:RegisterClickEvent(self, self.BtnSuit, self.OnBtnBuffDetailClick)
end

function XUiTheatre3PanelQuantumSuit:OnBtnDetailClick()
    self._Control:OpenAdventureEquipDetail(self._NumberLabelList[1].EquipId, true, self._IsQuantum)
end

function XUiTheatre3PanelQuantumSuit:OnBtnYesClick()
    self._Control:RequestSelectEquip(self._SuitConfig.Id, self._Index, true)
end

function XUiTheatre3PanelQuantumSuit:OnBtnBuffDetailClick()
    if self._IsNotHaveBuffTip then
        return
    end
    self.Parent:OnSuitSelects(self._Index)
    if self._IsOpenBuffTip then
        self:CloseBuffTip()
    else
        self:OpenBuffTip()
    end
end
--endregion

return XUiTheatre3PanelQuantumSuit