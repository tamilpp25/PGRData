local XUiTheatre3EquipmentCell = require("XUi/XUiTheatre3/Equip/XUiTheatre3EquipmentCell")

local EffectType = { Equip = 1, Suit = 2 }
local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("3F3F3FFF"),
    [false] = XUiHelper.Hexcolor2Color("9A9C9DFF"),
}

---@class XUiTheatre3EquipmentTip : XUiNode 装备Tip子UI
---@field Parent XUiTheatre3EquipmentChoose
---@field _Control XTheatre3Control
---@field _Equipment XUiTheatre3EquipmentCell
local XUiTheatre3EquipmentTip = XClass(XUiNode, "XUiTheatre3EquipmentTip")

function XUiTheatre3EquipmentTip:OnStart()
    self._Pool = {}
    self._Attrs = {}
    self:InitBtnDetail()
    self:ShowCurEquipTag(false)
    self:ShowDontGainTag(false)
    self:AddBtnListener()
end

function XUiTheatre3EquipmentTip:InitBtnDetail()
    if not self.BtnDetail then
        self.BtnDetail = XUiHelper.TryGetComponent(self.Transform, "PanelEquipment/PanelBase/BtnDetail", "XUiButton")
    end
end

function XUiTheatre3EquipmentTip:SetIsAdventureDesc(isAdventureDesc)
    self._IsAdventureDesc = isAdventureDesc
end

function XUiTheatre3EquipmentTip:SetBtnDetailCallBack(cb)
    if self.BtnDetail then
        self.BtnDetail.gameObject:SetActiveEx(true)
        self.BtnDetail.CallBack = cb
    end
end

function XUiTheatre3EquipmentTip:SetSelectCallBack(cb)
    -- 选中回调
    self._SelectCb = cb
end

function XUiTheatre3EquipmentTip:DoSelectCallBack()
    if self._SelectCb then
        self._SelectCb(self._EquipConfig.Id)
    end
end

function XUiTheatre3EquipmentTip:ShowEquipTip(equipId, btnTxt, callBack, isDetailTxt, isQuantum)
    if isDetailTxt == nil then
        isDetailTxt = true
    end
    self._IsQuantum = isQuantum
    self._EquipConfig = self._Control:GetEquipById(equipId)
    if not self._Equipment then
        self._Equipment = XUiTheatre3EquipmentCell.New(self.UiEquipment, self.Parent, equipId)
    else
        self._Equipment:ShowEquip(equipId)
    end
    self.TxtTitle.text = self._EquipConfig.EquipName
    self.TxtBaseBuff1.text = self._EquipConfig.BaseAttDesc[1]
    self.TxtBaseBuff2.text = self._EquipConfig.BaseAttDesc[2]
    self:SetSuitInfo(self._EquipConfig.SuitId)
    self:ShowButton(btnTxt, callBack)
    self:CheckTxtClick()
    self:ShowDetailOrSimpleTxt(isDetailTxt, self._IsQuantum)
end

---显示详细版/简略版描述
function XUiTheatre3EquipmentTip:ShowDetailOrSimpleTxt(isDetailTxt, isQuantum)
    local desc
    if self._EquipConfig then
        if isQuantum then
            desc = isDetailTxt and self._EquipConfig.QubitEffectDesc or self._EquipConfig.QubitSampleEffectDesc or self._EquipConfig.SimpleEffectDesc
        else
            desc = isDetailTxt and self._EquipConfig.EffectDesc or self._EquipConfig.SimpleEffectDesc
        end
        desc = XUiHelper.FormatText(desc, self._IsAdventureDesc and self._Control:GetEquipEffectGroupDesc(self._EquipConfig.Id) or "")
        self.TxtDetails.text = XUiHelper.ReplaceUnicodeSpace(XUiHelper.ReplaceTextNewLine(desc))
    end
    if self._SuitConfig then
        if isQuantum then
            desc = isDetailTxt and self._SuitConfig.QubitDesc or self._SuitConfig.QubitSampleEffectDesc or self._SuitConfig.SimpleEffectDesc
        else
            desc = isDetailTxt and self._SuitConfig.Desc or self._SuitConfig.SimpleEffectDesc
        end
        desc = XUiHelper.FormatText(desc, self._IsAdventureDesc and self._Control:GetSuitEffectGroupDesc(self._SuitConfig.Id) or "")
        self.TxtSuitDetails.text = XUiHelper.ReplaceUnicodeSpace(XUiHelper.ReplaceTextNewLine(desc))
    end
end

function XUiTheatre3EquipmentTip:SetLockTip(isLock)
    self._IsLock = isLock
end

function XUiTheatre3EquipmentTip:SetSuitInfo(suitId)
    self._SuitConfig = self._Control:GetSuitById(suitId)
    if self._Control:IsAdventureALine() then
        self.TxtSuitDetails.color = CONDITION_COLOR[self._Control:IsSuitComplete(suitId)]
    else
        if not self._Control:IsSuitComplete(suitId) then
            self.TxtSuitDetails.color = CONDITION_COLOR[false]
        end
    end
    self.TxtStory.text = self._SuitConfig.RecommendDesc
    self.PanelTag.gameObject:SetActiveEx(self._Control:IsWearSuit(suitId))
    self:ShowEquipWearState(suitId)
end

---@param config XTableTheatre3Equip
function XUiTheatre3EquipmentTip:InstantiateEffectGrid(config)
    local traitName = self._IsQuantum and config.QubitTraitName or config.TraitName
    local traitDesc = self._IsQuantum and config.QubitTraitDesc or config.TraitDesc
    for k, v in ipairs(traitName) do
        if not string.IsNilOrEmpty(v) then
            if not self._Attrs[k] then
                self._Attrs[k] = k == 1 and self.ImgBubbleBg or XUiHelper.Instantiate(self.ImgBubbleBg, self.PanelAffix)
            end
            self._Attrs[k].gameObject:SetActiveEx(true)
            self._Attrs[k]:GetObject("TxtTitle").text = v
            self._Attrs[k]:GetObject("TxtInformation").text = XUiHelper.ReplaceUnicodeSpace(XUiHelper.ConvertLineBreakSymbol(traitDesc[k]))
        end
    end
    for i = #traitName + 1, #self._Attrs do
        self._Attrs[i].gameObject:SetActiveEx(false)
    end
end

function XUiTheatre3EquipmentTip:ShowButton(btnTxt, callBack)
    if not callBack then
        self.BtnTongBlue.gameObject:SetActiveEx(false)
        return
    end
    self.BtnTongBlue.gameObject:SetActiveEx(true)
    self.BtnTongBlue.CallBack = callBack
    self.BtnTongBlue:SetNameByGroup(0, btnTxt)
end

function XUiTheatre3EquipmentTip:CheckTxtClick()
    if self._IsQuantum then
        self.BtnSuit.gameObject:SetActiveEx(self._SuitConfig and not XTool.IsTableEmpty(self._SuitConfig.QubitTraitName))
        self.BtnEquip.gameObject:SetActiveEx(self._EquipConfig and not XTool.IsTableEmpty(self._EquipConfig.QubitTraitName))
    else
        self.BtnSuit.gameObject:SetActiveEx(self._SuitConfig and not XTool.IsTableEmpty(self._SuitConfig.TraitName))
        self.BtnEquip.gameObject:SetActiveEx(self._EquipConfig and not XTool.IsTableEmpty(self._EquipConfig.TraitName))
    end
end

function XUiTheatre3EquipmentTip:ShowEquipWearState(suitId)
    local equips = self._Control:GetAllSuitEquip(suitId)
    for i, v in ipairs(equips) do
        local go = self._Pool[i]
        if not go then
            go = i == 1 and self.PanelNum or XUiHelper.Instantiate(self.PanelNum, self.PanelNow)
            self._Pool[i] = go
        end
        go.gameObject:SetActiveEx(true)
        local uiObject = {}
        XTool.InitUiObjectByUi(uiObject, go)
        uiObject.Mask.gameObject:SetActiveEx(not self._Control:IsWearEquip(v.Id))
        uiObject.TxtIndex.text = XTool.ConvertRomanNumberString(i)
    end
    for i = #equips + 1, #self._Pool do
        self._Pool[i].gameObject:SetActiveEx(false)
    end
end

---显示【未获得】标签
function XUiTheatre3EquipmentTip:ShowDontGainTag(isShow)
    if self.RImgType then
        self.RImgType.gameObject:SetActiveEx(isShow)
    end
end

---显示【当前装备】标签
function XUiTheatre3EquipmentTip:ShowCurEquipTag(isShow)
    if self.RImgCurrent then
        self.RImgCurrent.gameObject:SetActiveEx(isShow)
    end
end

---显示【可激活】标签
function XUiTheatre3EquipmentTip:ShowCanActiveTag(canActive)
    if self.PanelCanActive then
        self.PanelCanActive.gameObject:SetActiveEx(canActive)
    end
end

--region Ui - DetailPanel
function XUiTheatre3EquipmentTip:ShowSuitEffectDetail()
    if self._IsLock then
        return
    end
    if (not self._IsQuantum and XTool.IsTableEmpty(self._SuitConfig.TraitName))
            or (self._IsQuantum and XTool.IsTableEmpty(self._SuitConfig.QubitTraitName)) then
        self.PanelAffix.gameObject:SetActiveEx(false)
        return
    end
    if self._CurShowIndex == EffectType.Suit or not self.PanelAffix.gameObject.activeSelf then
        self.PanelAffix.gameObject:SetActiveEx(not self.PanelAffix.gameObject.activeSelf)
    end
    self._CurShowIndex = EffectType.Suit
    self:InstantiateEffectGrid(self._SuitConfig)
    self:DoSelectCallBack()
    self:UpdateBuffDetailPos()
end

function XUiTheatre3EquipmentTip:ShowEquipEffectDetail()
    if self._IsLock then
        return
    end
    if (not self._IsQuantum and XTool.IsTableEmpty(self._EquipConfig.TraitName))
            or (self._IsQuantum and XTool.IsTableEmpty(self._EquipConfig.QubitTraitName)) then
        self.PanelAffix.gameObject:SetActiveEx(false)
        return
    end
    if self._CurShowIndex == EffectType.Equip or not self.PanelAffix.gameObject.activeSelf then
        self.PanelAffix.gameObject:SetActiveEx(not self.PanelAffix.gameObject.activeSelf)
    end
    self._CurShowIndex = EffectType.Equip
    self:InstantiateEffectGrid(self._EquipConfig)
    self:DoSelectCallBack()
    self:UpdateBuffDetailPos()
end

function XUiTheatre3EquipmentTip:UpdateBuffDetailPos()
    -- 左边超屏了就放到右边
    if not self.PanelAffixPosX or not self.PanelAffixPosY then
        local anchoredPosition = self.PanelAffix.anchoredPosition
        self.PanelAffixPosX = anchoredPosition.x
        self.PanelAffixPosY = anchoredPosition.y
    end

    local pos = self.Parent.Transform:InverseTransformPoint(self.PanelEquipment.position)
    if self.Parent.Transform.rect.width / 2 + pos.x < self.PanelAffix.rect.width then
        self.PanelAffix.anchorMin = Vector2(1, 1)
        self.PanelAffix.anchorMax = Vector2(1, 1)
        self.PanelAffix.pivot = Vector2(0, 1)
        self.PanelAffix.anchoredPosition = Vector2(-self.PanelAffixPosX, self.PanelAffixPosY)
    else
        self.PanelAffix.anchorMin = Vector2(0, 1)
        self.PanelAffix.anchorMax = Vector2(0, 1)
        self.PanelAffix.pivot = Vector2(1, 1)
        self.PanelAffix.anchoredPosition = Vector2(self.PanelAffixPosX, self.PanelAffixPosY)
    end
end

function XUiTheatre3EquipmentTip:SetPosition(worldPos)
    local tipWidth = self.Transform.sizeDelta.x
    local tipHeight = self.Transform.sizeDelta.y
    local pos = self.Transform.parent.worldToLocalMatrix:MultiplyPoint(worldPos)
    pos.x = pos.x + tipWidth / 2
    if pos.x + tipWidth / 2 > self.Parent.Transform.rect.width / 2 then
        pos.x = self.Parent.Transform.rect.width / 2 - tipWidth / 2
    end
    if tipHeight - pos.y > self.Parent.Transform.rect.height / 2 then
        pos.y = tipHeight - self.Parent.Transform.rect.height / 2
    end
    self.Transform.localPosition = pos
end

function XUiTheatre3EquipmentTip:SetPositionByAlign(dimObj, alignment)
    local posX = 0
    local pos = self.Transform.parent:InverseTransformPoint(dimObj.position)

    -- 超框
    -- PS：Parent.Transform是UiTheatre3BubbleEquipment，而Transform.parent是SafeAreaContentPane，刚好能做异形屏适配
    local centerW = self.Transform.parent.rect.width / 2
    local centerH = self.Transform.parent.rect.height / 2
    local tipW = self.Transform.rect.width
    local tipH = self.Transform.rect.height
    local minW = tipW - centerW
    local maxW = centerW - tipW
    local minH = tipH - centerH
    local maxH = centerH

    if alignment == XEnumConst.THEATRE3.TipAlign.Left then
        self.Transform.pivot = Vector2(1, 1)
        posX = pos.x - dimObj.rect.width * dimObj.localScale.x * dimObj.pivot.x
        posX = math.max(posX, minW)
    else
        self.Transform.pivot = Vector2(0, 1)
        posX = pos.x + dimObj.rect.width * dimObj.localScale.x * (1 - dimObj.pivot.x)
        posX = math.min(posX, maxW)
    end
    local posY = pos.y + dimObj.rect.height * dimObj.localScale.y * (1 - dimObj.pivot.y)
    posY = math.min(math.max(posY, minH), maxH)

    self.Transform.localPosition = Vector3(posX, posY, 0)
end

function XUiTheatre3EquipmentTip:CloseEffectDetail()
    if self.PanelAffix.gameObject.activeSelf then
        self.PanelAffix.gameObject:SetActiveEx(false)
    end
end
--endregion

--region Ui - BtnListener
function XUiTheatre3EquipmentTip:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnSuit, self.ShowSuitEffectDetail)
    XUiHelper.RegisterClickEvent(self, self.BtnEquip, self.ShowEquipEffectDetail)
    XUiHelper.RegisterClickEvent(self, self.BtnMask, self.OnClickTip)
end

function XUiTheatre3EquipmentTip:OnClickTip()
    -- 点击Tip背景时：关闭属性详情展示，选中该Tip（装备选择）
    self:CloseEffectDetail()
    self:DoSelectCallBack()
end
--endregion

return XUiTheatre3EquipmentTip