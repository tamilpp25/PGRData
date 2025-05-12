--装备详细子页面
local XUiSimulatedCombatEquipDetailChild = XLuaUiManager.Register(XLuaUi, "UiSimulatedCombatEquipDetailChild")
local CsXTextManager = CS.XTextManager
local MAX_AWARENESS_ATTR_COUNT = 2 --不包括共鸣属性，最大有2条

function XUiSimulatedCombatEquipDetailChild:OnAwake()
    self.BtnSuitSkill.gameObject:SetActiveEx(false)
    self.BtnResonanceSkill.gameObject:SetActiveEx(false)
    self.BtnLaJi.gameObject:SetActiveEx(false)
    self.BtnUnLaJi.gameObject:SetActiveEx(false)
end

function XUiSimulatedCombatEquipDetailChild:OnStart(equipId, breakthrough, level)
    self.TemplateId = equipId
    self.BreakThrough = breakthrough
    self.Level = level
    self:InitClassifyPanel()
    self:InitEquipInfo()
end

function XUiSimulatedCombatEquipDetailChild:OnEnable()
    self:UpdateEquipAttr()
    self:UpdateEquipLevel()
    self:UpdateEquipBreakThrough()
    self:UpdateEquipLock()
    self:UpdateEquipSkillDes()
end

function XUiSimulatedCombatEquipDetailChild:InitClassifyPanel()
    if XMVCA.XEquip:IsClassifyEqualByTemplateId(self.TemplateId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
        self.TxtTitle.text = CsXTextManager.GetText("WeaponDetailTitle")
        self.PanelPainter.gameObject:SetActive(false)
    else
        self.TxtPainter.text = XMVCA.XEquip:GetEquipPainterName(self.TemplateId, self.BreakThrough)
        self.PanelPainter.gameObject:SetActive(true)
        self.TxtTitle.text = CsXTextManager.GetText("AwarenessDetailTitle")
    end
end

function XUiSimulatedCombatEquipDetailChild:UpdateEquipSkillDes()
    if XMVCA.XEquip:IsClassifyEqualByTemplateId(self.TemplateId, XEnumConst.EQUIP.CLASSIFY.WEAPON) then
        local weaponSkillInfo = XMVCA.XEquip:GetEquipWeaponSkillInfo(self.TemplateId)
        local noWeaponSkill = not weaponSkillInfo.Name and not weaponSkillInfo.Description
        self.TxtSkillName.text = weaponSkillInfo.Name
        self.TxtSkillDes.text = weaponSkillInfo.Description
        self.PanelAwarenessSkillDes.gameObject:SetActive(false)
        self.PanelNoAwarenessSkill.gameObject:SetActive(false)
        self.PanelWeaponSkillDes.gameObject:SetActive(not noWeaponSkill)
        self.PanelNoWeaponSkill.gameObject:SetActive(noWeaponSkill)
    elseif XMVCA.XEquip:IsClassifyEqualByTemplateId(self.TemplateId, XEnumConst.EQUIP.CLASSIFY.AWARENESS) then
        local suitId = XMVCA.XEquip:GetEquipSuitId(self.TemplateId)
        local skillDesList = XMVCA.XEquip:GetEquipSuitSkillDescription(suitId)
        local noSuitSkill = true
        for i = 1, XEnumConst.EQUIP.OLD_MAX_SUIT_SKILL_COUNT do
            if skillDesList[i * 2] then
                self["TxtSkillDes" .. i].text = skillDesList[i * 2]
                self["TxtSkillDes" .. i].gameObject:SetActive(true)
                noSuitSkill = false
            else
                self["TxtSkillDes" .. i].gameObject:SetActive(false)
            end
        end
        self.PanelNoAwarenessSkill.gameObject:SetActive(noSuitSkill)
        self.PanelAwarenessSkillDes.gameObject:SetActive(not noSuitSkill)
        self.PanelWeaponSkillDes.gameObject:SetActive(false)
        self.PanelNoWeaponSkill.gameObject:SetActive(false)
    end
end

function XUiSimulatedCombatEquipDetailChild:UpdateEquipLock()
    self.BtnUnlock.gameObject:SetActive(false)
    self.BtnLock.gameObject:SetActive(false)
end

function XUiSimulatedCombatEquipDetailChild:UpdateEquipLevel()
    local levelLimit = XMVCA.XEquip:GetEquipBreakthroughCfg(self.TemplateId, self.BreakThrough).LevelLimit
    self.TxtLevel.text = CsXTextManager.GetText("EquipLevelText", self.Level, levelLimit)
end

function XUiSimulatedCombatEquipDetailChild:UpdateEquipBreakThrough()
    self:SetUiSprite(self.ImgBreakThrough, XMVCA.XEquip:GetEquipBreakThroughIcon(self.BreakThrough))
end

function XUiSimulatedCombatEquipDetailChild:InitEquipInfo()
    local star = XMVCA.XEquip:GetEquipStar(self.TemplateId)
    for i = 1, XEnumConst.EQUIP.MAX_STAR_COUNT do
        if i <= star then
            self["ImgStar" .. i].gameObject:SetActive(true)
        else
            self["ImgStar" .. i].gameObject:SetActive(false)
        end
    end

    self.TxtEquipName.text = XMVCA.XEquip:GetEquipName(self.TemplateId)

    local equipSite = XMVCA.XEquip:GetEquipSite(self.TemplateId)
    if equipSite ~= XEnumConst.EQUIP.EQUIP_SITE.WEAPON then
        self.RImgIcon:SetRawImage(XMVCA.XEquip:GetEquipIconPath(self.TemplateId, self.BreakThrough))
        self.TxtPos.text = "0" .. equipSite
        self.PanelPos.gameObject:SetActive(true)
        self.RImgType.gameObject:SetActive(false)
    else
        self.RImgType:SetRawImage(XMVCA.XEquip:GetWeaponTypeIconPath(self.TemplateId))
        self.RImgType.gameObject:SetActive(true)
        self.PanelPos.gameObject:SetActive(false)
    end
    self.PanelSpecialCharacter.gameObject:SetActive(false)
end

function XUiSimulatedCombatEquipDetailChild:UpdateEquipAttr()
    local attrMap = XMVCA.XEquip:ConstructTemplateEquipAttrMap(self.TemplateId, self.BreakThrough, self.Level)
    local attrCount = 1
    for _, attrInfo in pairs(attrMap) do
        if attrCount > MAX_AWARENESS_ATTR_COUNT then break end
        self["TxtName" .. attrCount].text = attrInfo.Name
        self["TxtAttr" .. attrCount].text = attrInfo.Value
        self["PanelAttr" .. attrCount].gameObject:SetActive(true)
        attrCount = attrCount + 1
    end
    for i = attrCount, MAX_AWARENESS_ATTR_COUNT do
        self["PanelAttr" .. i].gameObject:SetActive(false)
    end
end