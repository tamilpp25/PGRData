---@class XUiTheatre3SuitTip : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3SuitTip = XLuaUiManager.Register(XLuaUi, "UiTheatre3SuitTip")

local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("3F3F3FFF"),
    [false] = XUiHelper.Hexcolor2Color("9A9C9DFF"),
}

function XUiTheatre3SuitTip:OnAwake()
    self:RegisterClickEvent(self.BtnEmpty, self.Close)
    self:RegisterClickEvent(self.BtnBuff, self.ShowSuitEffectDetail)
    self:RegisterClickEvent(self.BtnMask, self.OnClickTip)
end

function XUiTheatre3SuitTip:OnStart(param)
    self._Param = param
    self._Pool = {}
    self._Attrs = {}
    self:UpdateView()
end

function XUiTheatre3SuitTip:OnDestroy()
    if self._Param.closeCallBack then
        self._Param.closeCallBack()
    end
end

function XUiTheatre3SuitTip:UpdateView()
    if self._Param.btnCallBack then
        self:ShowSuitTip(self._Param.suitId, self._Param.btnTxt or "", handler(self, self.DoCallBack))
    else
        self:ShowSuitTip(self._Param.suitId)
    end
    if self._Param.DimObj and self._Param.Align then
        self.BubbleSet.gameObject:SetActiveEx(false)
        XScheduleManager.ScheduleOnce(function()
            self.BubbleSet.gameObject:SetActiveEx(true)
            self:SetPosition(self._Param.DimObj, self._Param.Align)
        end, 1)
    end
end

function XUiTheatre3SuitTip:ShowSuitEffectDetail()
    if XTool.IsTableEmpty(self._SuitConfig.TraitName) then
        self.PanelAffix.gameObject:SetActiveEx(false)
        return
    end
    self.PanelAffix.gameObject:SetActiveEx(not self.PanelAffix.gameObject.activeSelf)
    self:InstantiateEffectGrid(self._SuitConfig)
    self:UpdateBuffDetailPos()
end

---@param config XTableTheatre3EquipSuit
function XUiTheatre3SuitTip:InstantiateEffectGrid(config)
    for k, v in ipairs(config.TraitName) do
        if not string.IsNilOrEmpty(v) then
            if not self._Attrs[k] then
                self._Attrs[k] = k == 1 and self.ImgBubbleBg or XUiHelper.Instantiate(self.ImgBubbleBg, self.PanelAffix)
            end
            self._Attrs[k].gameObject:SetActiveEx(true)
            self._Attrs[k]:GetObject("TxtTitle").text = v
            self._Attrs[k]:GetObject("TxtInformation").text = XUiHelper.ReplaceUnicodeSpace(XUiHelper.ConvertLineBreakSymbol(config.TraitDesc[k]))
        end
    end
    for i = #config.TraitName + 1, #self._Attrs do
        self._Attrs[i].gameObject:SetActiveEx(false)
    end
end

function XUiTheatre3SuitTip:ShowSuitTip(suitId, btnTxt, callBack)
    self:SetSuitInfo(suitId)
    self:ShowButton(btnTxt, callBack)
    self:CheckTxtClick()
end

function XUiTheatre3SuitTip:SetSuitInfo(suitId)
    self._SuitConfig = self._Control:GetSuitById(suitId)
    self.TxtTitle.text = self._SuitConfig.SuitName
    self.TxtDetails.text = XUiHelper.ReplaceUnicodeSpace(XUiHelper.ReplaceTextNewLine(XUiHelper.FormatText(self._SuitConfig.Desc, self._SuitConfig.TraitName)))
    self.TxtDetails.color = CONDITION_COLOR[self._Control:IsSuitComplete(suitId)]
    self.PanelTag.gameObject:SetActiveEx(self._Control:IsWearSuit(suitId))
    self:ShowEquipWearState(suitId)
end

function XUiTheatre3SuitTip:ShowEquipWearState(suitId)
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

function XUiTheatre3SuitTip:ShowButton(btnTxt, callBack)
    if not callBack then
        self.BtnTongBlue.gameObject:SetActiveEx(false)
        return
    end
    self.BtnTongBlue.gameObject:SetActiveEx(true)
    self.BtnTongBlue.CallBack = callBack
    self.BtnTongBlue:SetNameByGroup(0, btnTxt)
end

function XUiTheatre3SuitTip:CheckTxtClick()
    self.BtnBuff.gameObject:SetActiveEx(self._SuitConfig and not XTool.IsTableEmpty(self._SuitConfig.TraitName))
end

function XUiTheatre3SuitTip:SetPosition(dimObj, alignment)
    local posX = 0
    local pos = self.BubbleSet.parent:InverseTransformPoint(dimObj.position)
    if alignment == XEnumConst.THEATRE3.TipAlign.Left then
        self.BubbleSet.pivot = Vector2(1, 1)
        posX = pos.x - dimObj.rect.width * dimObj.localScale.x * dimObj.pivot.x
    else
        self.BubbleSet.pivot = Vector2(0, 1)
        posX = pos.x + dimObj.rect.width * dimObj.localScale.x * (1 - dimObj.pivot.x)
    end
    local posY = pos.y + dimObj.rect.height * dimObj.localScale.y * (1 - dimObj.pivot.y)

    -- 超框
    local centerW = self.BubbleSet.parent.rect.width / 2
    local centerH = self.BubbleSet.parent.rect.height / 2
    local tipW = self.BubbleSet.rect.width
    local tipH = self.BubbleSet.rect.height
    local minW = tipW - centerW
    local maxW = centerW - tipW
    local minH = tipH - centerH
    local maxH = centerH
    posX = math.min(math.max(posX, minW), maxW)
    posY = math.min(math.max(posY, minH), maxH)

    self.BubbleSet.localPosition = Vector3(posX, posY, 0)
end

function XUiTheatre3SuitTip:DoCallBack()
    self:Close()
    self._Param.btnCallBack()
end

function XUiTheatre3SuitTip:UpdateBuffDetailPos()
    -- 左边超屏了就放到右边
    if not self.PanelAffixPosX or not self.PanelAffixPosY then
        local anchoredPosition = self.PanelAffix.anchoredPosition
        self.PanelAffixPosX = anchoredPosition.x
        self.PanelAffixPosY = anchoredPosition.y
    end

    local pos = self.Transform:InverseTransformPoint(self.PanelSuit.transform.position)
    if self.Transform.rect.width / 2 + pos.x < self.PanelAffix.rect.width then
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

function XUiTheatre3SuitTip:CloseEffectDetail()
    if self.PanelAffix.gameObject.activeSelf then
        self.PanelAffix.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre3SuitTip:OnClickTip()
    self:CloseEffectDetail()
end

return XUiTheatre3SuitTip