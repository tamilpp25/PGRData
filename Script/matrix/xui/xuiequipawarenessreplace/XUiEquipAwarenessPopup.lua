local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")

local CSXTextManagerGetText = CS.XTextManager.GetText

local MAX_AWARENESS_ATTR_COUNT = 2

local SKILL_DES_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("188649ff"),
    [false] = XUiHelper.Hexcolor2Color("00000099")
}

local ATTR_COLOR = {
    BELOW = XUiHelper.Hexcolor2Color("d11e38ff"),
    EQUAL = XUiHelper.Hexcolor2Color("000000ff"),
    OVER = XUiHelper.Hexcolor2Color("188649ff")
}

local CUR_EQUIP_CLICK_POPUP_POS = {
    [XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.ONE] = CS.UnityEngine.Vector2(-230, 14),
    [XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.TWO] = CS.UnityEngine.Vector2(-681, 14),
    [XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.THREE] = CS.UnityEngine.Vector2(-681, 14),
    [XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.FOUR] = CS.UnityEngine.Vector2(-230, 14),
    [XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.FIVE] = CS.UnityEngine.Vector2(-681, 14),
    [XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.SIX] = CS.UnityEngine.Vector2(-681, 14)
}

local XUiEquipAwarenessPopup = XLuaUiManager.Register(XLuaUi, "UiEquipAwarenessPopup")

function XUiEquipAwarenessPopup:OnAwake()
    self:AutoAddListener()
end

function XUiEquipAwarenessPopup:OnStart(rootUi, HideStrengthenBtn, equipId, charaterId, hideAllBtns)

    self.RootUi = rootUi --子窗口在隐藏/显示时无法再次调到onstart
    self.InitEquipId = equipId
    self.InitCharacterId = charaterId
    self.HideStrengthenBtn = HideStrengthenBtn
    self.HideAllBtns = hideAllBtns
    self.PanelSelectRectTransform = self.PanelSelect:GetComponent("RectTransform")
end

function XUiEquipAwarenessPopup:OnEnable()
    self.EquipId = self.InitEquipId or self.RootUi.SelectEquipId
    self.CharacterId = self.InitCharacterId or self.RootUi.CharacterId

    self:Refresh()
    if self.RootUi.BtnClosePopup then
        self.RootUi.BtnClosePopup.gameObject:SetActiveEx(true)
    end
end

function XUiEquipAwarenessPopup:OnDisable()
    if self.RootUi.BtnClosePopup then
        self.RootUi.BtnClosePopup.gameObject:SetActiveEx(false)
    end
end

function XUiEquipAwarenessPopup:Refresh()
    local equipSite = XMVCA.XEquip:GetEquipSiteByEquipId(self.EquipId)
    self.UsingEquipId = XMVCA.XEquip:GetCharacterEquipId(self.CharacterId, equipSite)
    self.UsingAttrMap = XMVCA.XEquip:GetEquipAttrMap(self.UsingEquipId)

    self:UpdateSelectPanel()
    self:UpdateUsingPanel()
    self:UpdateUsingPanelBtn()
    self:UpdateLockStatues(self.EquipId)
    self:UpdateLockStatues(self.UsingEquipId)
    self:UpdateRecycleStatues(self.EquipId)
    self:UpdateRecycleStatues(self.UsingEquipId)
end

function XUiEquipAwarenessPopup:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_PUTON_NOTYFY,
        XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY,
        XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY,
        XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY,
        XEventId.EVENT_EQUIP_RECYCLE_NOTIFY
    }
end

function XUiEquipAwarenessPopup:OnNotify(evt, ...)
    local args = {...}

    if evt == XEventId.EVENT_EQUIP_PUTON_NOTYFY then
        local equipId = args[1]
        if equipId == self.EquipId then
            self:Close()
        end
    elseif evt == XEventId.EVENT_EQUIPLIST_TAKEOFF_NOTYFY or evt == XEventId.EVENT_EQUIP_RECYCLE_NOTIFY then
        local equipIds = args[1]
        for _, equipId in pairs(equipIds) do
            if equipId == self.EquipId then
                self:Close()
                return
            end
        end
    elseif evt == XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY then
        local equipId = args[1]
        if equipId ~= self.EquipId then
            return
        end
        self:UpdateLockStatues(equipId)
        self:UpdateRecycleStatues(equipId)
    elseif evt == XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY then
        local equipId = args[1]
        if equipId ~= self.EquipId then
            return
        end
        self:UpdateRecycleStatues(equipId)
    end
end

function XUiEquipAwarenessPopup:UpdateLockStatues(equipId)
    if self.HideAllBtns then
        self.BtnLockSelect.gameObject:SetActiveEx(false)
        self.BtnUnlockSelect.gameObject:SetActiveEx(false)
        self.BtnLockUsing.gameObject:SetActiveEx(false)
        self.BtnUnlockUsing.gameObject:SetActiveEx(false)
        return
    end

    if not equipId then
        return
    end

    if equipId == self.EquipId then
        local isLock = XMVCA.XEquip:IsLock(equipId)
        self.BtnLockSelect.gameObject:SetActiveEx(isLock)
        self.BtnUnlockSelect.gameObject:SetActiveEx(not isLock)
    end
end

function XUiEquipAwarenessPopup:UpdateRecycleStatues(equipId)
    if self.HideAllBtns then
        self.BtnLaJiSelect.gameObject:SetActiveEx(false)
        self.BtnUnlaJiSelect.gameObject:SetActiveEx(false)
        self.BtnLaJiUsing.gameObject:SetActiveEx(false)
        self.BtnUnlaJiUsing.gameObject:SetActiveEx(false)
        return
    end

    if not equipId then
        return
    end

    if equipId == self.EquipId then
        local isCanRecycle = XMVCA.XEquip:IsEquipCanRecycle(equipId)
        local isRecycle = XMVCA.XEquip:IsRecycle(equipId)
        self.BtnLaJiSelect.gameObject:SetActiveEx(isCanRecycle and isRecycle)
        self.BtnUnlaJiSelect.gameObject:SetActiveEx(isCanRecycle and not isRecycle)
    end
end

function XUiEquipAwarenessPopup:UpdateSelectPanel()
    if not self.SelectEquipGrid then
        self.SelectEquipGrid = XUiGridEquip.New(self.GridEquipSelect, self)
    end
    self.SelectEquipGrid:Refresh(self.EquipId)

    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    self.TxtNameA.text = XMVCA.XEquip:GetEquipName(equip.TemplateId)

    local attrCount = 1
    local attrMap = XMVCA.XEquip:GetEquipAttrMap(self.EquipId)
    for attrIndex, attrInfo in pairs(attrMap) do
        if attrCount > MAX_AWARENESS_ATTR_COUNT then
            break
        end

        local usingAttr = self.UsingAttrMap[attrIndex]
        local usingAttrValue = usingAttr and usingAttr.Value or 0
        local selectAttrValue = attrInfo.Value
        if selectAttrValue > usingAttrValue then
            self["TxtSelectAttrValue" .. attrCount].color = ATTR_COLOR.OVER
            self["ImgArrowUpSelect" .. attrCount].gameObject:SetActiveEx(true)
            self["ImgArrowDownSelect" .. attrCount].gameObject:SetActiveEx(false)
        elseif selectAttrValue == usingAttrValue then
            self["TxtSelectAttrValue" .. attrCount].color = ATTR_COLOR.EQUAL
            self["ImgArrowUpSelect" .. attrCount].gameObject:SetActiveEx(false)
            self["ImgArrowDownSelect" .. attrCount].gameObject:SetActiveEx(false)
        else
            self["TxtSelectAttrValue" .. attrCount].color = ATTR_COLOR.BELOW
            self["ImgArrowUpSelect" .. attrCount].gameObject:SetActiveEx(false)
            self["ImgArrowDownSelect" .. attrCount].gameObject:SetActiveEx(true)
        end
        self["TxtSelectAttrName" .. attrCount].text = attrInfo.Name
        self["TxtSelectAttrValue" .. attrCount].text = selectAttrValue
        self["PanelSelectAttr" .. attrCount].gameObject:SetActiveEx(true)

        attrCount = attrCount + 1
    end
    for i = attrCount, MAX_AWARENESS_ATTR_COUNT do
        self["PanelSelectAttr" .. i].gameObject:SetActiveEx(false)
    end

    --是否激活颜色不同
    local suitId = XMVCA.XEquip:GetEquipSuitIdByEquipId(equip.Id)
    local activeEquipsCount = XMVCA.XEquip:GetActiveSuitEquipsCount(self.CharacterId, suitId)
    local isOverrun = self:IsOverrun(suitId, self.CharacterId)
    local skillDesList = XMVCA.XEquip:GetSuitActiveSkillDesList(suitId, activeEquipsCount, isOverrun, isOverrun)
    for i = 1, XEnumConst.EQUIP.OLD_MAX_SUIT_SKILL_COUNT do
        local componentText = self["TxtSkillDesA" .. i]
        if not skillDesList[i] then
            componentText.gameObject:SetActiveEx(false)
        else
            local color = SKILL_DES_COLOR[skillDesList[i].IsActive]
            componentText.text = skillDesList[i].SkillDes
            componentText.gameObject:SetActiveEx(true)
            componentText.color = color
            self["TxtPosA" .. i].color = color
        end
    end

    --修正弹窗位置
    if self.RootUi.NeedFixPopUpPos and (not self.UsingEquipId or self.UsingEquipId == self.EquipId) then
        local equipSite = XMVCA.XEquip:GetEquipSiteByEquipId(self.EquipId)
        self.PanelSelectRectTransform.anchoredPosition = CUR_EQUIP_CLICK_POPUP_POS[equipSite]
    else
        self.PanelSelectRectTransform.anchoredPosition = CUR_EQUIP_CLICK_POPUP_POS[XEnumConst.EQUIP.EQUIP_SITE.AWARENESS.ONE]
    end

    self.BtnStrengthen.gameObject:SetActiveEx(not self.HideStrengthenBtn and not self.HideAllBtns)

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelContentA)
end

function XUiEquipAwarenessPopup:UpdateUsingPanel()
    if not self.UsingEquipId or self.UsingEquipId == self.EquipId then
        self.PanelUsing.gameObject:SetActiveEx(false)
        return
    end

    if not self.UsingEquipGrid then
        self.UsingEquipGrid = XUiGridEquip.New(self.GridEquipUsing, self)
    end
    self.UsingEquipGrid:Refresh(self.UsingEquipId)

    local equip = XMVCA.XEquip:GetEquip(self.UsingEquipId)
    self.TxtName.text = XMVCA.XEquip:GetEquipName(equip.TemplateId)

    local attrCount = 1
    local attrMap = self.UsingAttrMap
    for _, attrInfo in pairs(attrMap) do
        if attrCount > MAX_AWARENESS_ATTR_COUNT then
            break
        end

        self["TxtUsingAttrName" .. attrCount].text = attrInfo.Name
        self["TxtUsingAttrValue" .. attrCount].text = attrInfo.Value
        self["PanelUsingAttr" .. attrCount].gameObject:SetActiveEx(true)

        attrCount = attrCount + 1
    end
    for i = attrCount, MAX_AWARENESS_ATTR_COUNT do
        self["PanelUsingAttr" .. i].gameObject:SetActiveEx(false)
    end

    --是否激活颜色不同
    local suitId = XMVCA.XEquip:GetEquipSuitIdByEquipId(equip.Id)
    local activeEquipsCount = XMVCA.XEquip:GetActiveSuitEquipsCount(self.CharacterId, suitId)
    local isOverrun = self:IsOverrun(suitId, self.CharacterId)
    local skillDesList = XMVCA.XEquip:GetSuitActiveSkillDesList(suitId, activeEquipsCount, isOverrun, isOverrun)

    for i = 1, XEnumConst.EQUIP.OLD_MAX_SUIT_SKILL_COUNT do
        local componentText = self["TxtSkillDes" .. i]
        if not skillDesList[i] then
            componentText.gameObject:SetActiveEx(false)
        else
            local color = SKILL_DES_COLOR[skillDesList[i].IsActive]
            componentText.text = skillDesList[i].SkillDes
            componentText.gameObject:SetActiveEx(true)
            componentText.color = color
            self["TxtPos" .. i].color = color
        end
    end

    --去掉穿戴中装备的锁按钮
    self.BtnLockUsing.gameObject:SetActiveEx(false)
    self.BtnUnlockUsing.gameObject:SetActiveEx(false)
    self.BtnLaJiUsing.gameObject:SetActiveEx(false)
    self.BtnUnlaJiUsing.gameObject:SetActiveEx(false)

    self.PanelUsing.gameObject:SetActiveEx(true)

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelContent)
end

function XUiEquipAwarenessPopup:UpdateUsingPanelBtn()
    if self.HideAllBtns then
        self.BtnPutOn.gameObject:SetActiveEx(false)
        self.BtnTakeOff.gameObject:SetActiveEx(false)
        return
    end

    if self.UsingEquipId and self.UsingEquipId == self.EquipId then
        self.BtnPutOn.gameObject:SetActiveEx(false)
        self.BtnTakeOff.gameObject:SetActiveEx(true)
    else
        self.BtnPutOn.gameObject:SetActiveEx(true)
        self.BtnTakeOff.gameObject:SetActiveEx(false)
    end
end

function XUiEquipAwarenessPopup:AutoAddListener()
    self:RegisterClickEvent(self.BtnStrengthen, self.OnBtnStrengthenClick)
    self:RegisterClickEvent(self.BtnPutOn, self.OnBtnPutOnClick)
    self:RegisterClickEvent(self.BtnTakeOff, self.OnBtnTakeOffClick)
    self:RegisterClickEvent(self.BtnLockUsing, self.OnBtnLockUsingClick)
    self:RegisterClickEvent(self.BtnUnlockUsing, self.OnBtnUnlockUsingClick)
    self:RegisterClickEvent(self.BtnLockSelect, self.OnBtnLockSelectClick)
    self:RegisterClickEvent(self.BtnUnlockSelect, self.OnBtnUnlockSelectClick)
    self:RegisterClickEvent(self.BtnLaJiUsing, self.OnBtnLaJiUsingClick)
    self:RegisterClickEvent(self.BtnUnlaJiUsing, self.OnBtnUnlaJiUsingClick)
    self:RegisterClickEvent(self.BtnLaJiSelect, self.OnBtnLaJiSelectClick)
    self:RegisterClickEvent(self.BtnUnlaJiSelect, self.OnBtnUnlaJiSelectClick)
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiEquipAwarenessPopup:OnBtnLaJiSelectClick()
    XMVCA.XEquip:EquipUpdateRecycleRequest(self.EquipId, false)
end

function XUiEquipAwarenessPopup:OnBtnUnlaJiSelectClick()
    XMVCA.XEquip:EquipUpdateRecycleRequest(self.EquipId, true)
end

function XUiEquipAwarenessPopup:OnBtnLaJiUsingClick()
    XMVCA.XEquip:EquipUpdateRecycleRequest(self.UsingEquipId, false)
end

function XUiEquipAwarenessPopup:OnBtnUnlaJiUsingClick()
    XMVCA.XEquip:EquipUpdateRecycleRequest(self.UsingEquipId, true)
end

function XUiEquipAwarenessPopup:OnBtnUnlockSelectClick()
    XMVCA.XEquip:SetLock(self.EquipId, true)
end

function XUiEquipAwarenessPopup:OnBtnLockSelectClick()
    XMVCA.XEquip:SetLock(self.EquipId, false)
end

function XUiEquipAwarenessPopup:OnBtnLockUsingClick()
    XMVCA.XEquip:SetLock(self.UsingEquipId, false)
end

function XUiEquipAwarenessPopup:OnBtnUnlockUsingClick()
    XMVCA.XEquip:SetLock(self.UsingEquipId, true)
end

function XUiEquipAwarenessPopup:OnBtnStrengthenClick()
    XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipDetail(self.EquipId, nil, self.CharacterId)
    self:Close()
end

function XUiEquipAwarenessPopup:OnBtnPutOnClick()
    local characterId = self.CharacterId
    local equipId = self.EquipId

    local wearingCharacterId = XMVCA.XEquip:GetEquipWearingCharacterId(equipId)
    if wearingCharacterId and wearingCharacterId > 0 then
        local fullName = XMVCA.XCharacter:GetCharacterFullNameStr(wearingCharacterId)
        local content = string.gsub(CSXTextManagerGetText("EquipAwarenessReplaceTip", fullName), " ", "")
        XUiManager.DialogTip(
            CSXTextManagerGetText("TipTitle"),
            content,
            XUiManager.DialogType.Normal,
            function()
            end,
            function()
                XMVCA:GetAgency(ModuleId.XEquip):PutOn(characterId, equipId)
            end
        )
    else
        XMVCA:GetAgency(ModuleId.XEquip):PutOn(characterId, equipId)
    end
end

function XUiEquipAwarenessPopup:OnBtnTakeOffClick()
    XMVCA:GetAgency(ModuleId.XEquip):TakeOff({self.EquipId})
end

function XUiEquipAwarenessPopup:IsOverrun(suitId, characterId)
    if characterId then
        local usingWeaponId = XMVCA.XEquip:GetCharacterWeaponId(characterId)
        if usingWeaponId ~= 0 then
            local usingEquip = XMVCA.XEquip:GetEquip(usingWeaponId)
            local choseSuit = usingEquip:GetOverrunChoseSuit()
            return choseSuit == suitId
        end
    end

    return false
end
