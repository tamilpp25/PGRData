--虚像地平线装备详细子页面
local XUiExpeditionEquipDetailChild = XLuaUiManager.Register(XLuaUi, "UiExpeditionEquipDetailChild")
local CsXTextManager = CS.XTextManager
local MAX_AWARENESS_ATTR_COUNT = 2 --不包括共鸣属性，最大有2条

function XUiExpeditionEquipDetailChild:OnAwake()
    self.BtnSuitSkill.gameObject:SetActiveEx(false)
    self.BtnResonanceSkill.gameObject:SetActiveEx(false)
    self.BtnLaJi.gameObject:SetActiveEx(false)
    self.BtnUnLaJi.gameObject:SetActiveEx(false)
end

function XUiExpeditionEquipDetailChild:OnStart(equipId, breakthrough, level)
    self.TemplateId = equipId
    self.BreakThrough = breakthrough
    self.Level = level
    self:InitClassifyPanel()
    self:InitEquipInfo()
end

function XUiExpeditionEquipDetailChild:OnEnable()
    self:UpdateEquipAttr()
    self:UpdateEquipLevel()
    self:UpdateEquipBreakThrough()
    self:UpdateEquipLock()
    self:UpdateEquipSkillDes()
end

function XUiExpeditionEquipDetailChild:InitClassifyPanel()
    if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Weapon) then
        self.TxtTitle.text = CsXTextManager.GetText("WeaponDetailTitle")
        self.PanelPainter.gameObject:SetActive(false)
    else
        self.TxtPainter.text = XDataCenter.EquipManager.GetEquipPainterName(self.TemplateId, self.BreakThrough)
        self.PanelPainter.gameObject:SetActive(true)
        self.TxtTitle.text = CsXTextManager.GetText("AwarenessDetailTitle")
    end
end

function XUiExpeditionEquipDetailChild:UpdateEquipSkillDes()
    if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Weapon) then
        local weaponSkillInfo = XDataCenter.EquipManager.GetOriginWeaponSkillInfo(self.TemplateId)
        local noWeaponSkill = not weaponSkillInfo.Name and not weaponSkillInfo.Description
        self.TxtSkillName.text = weaponSkillInfo.Name
        self.TxtSkillDes.text = weaponSkillInfo.Description
        self.PanelAwarenessSkillDes.gameObject:SetActive(false)
        self.PanelNoAwarenessSkill.gameObject:SetActive(false)
        self.PanelWeaponSkillDes.gameObject:SetActive(not noWeaponSkill)
        self.PanelNoWeaponSkill.gameObject:SetActive(noWeaponSkill)
    elseif XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Awareness) then
        local suitId = XDataCenter.EquipManager.GetSuitIdByTemplateId(self.TemplateId)
        local skillDesList = XDataCenter.EquipManager.GetSuitSkillDesList(suitId)
        local noSuitSkill = true
        for i = 1, XEquipConfig.MAX_SUIT_SKILL_COUNT do
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

function XUiExpeditionEquipDetailChild:UpdateEquipLock()
    self.BtnUnlock.gameObject:SetActive(false)
    self.BtnLock.gameObject:SetActive(false)
end

function XUiExpeditionEquipDetailChild:UpdateEquipLevel()
    local levelLimit = XEquipConfig.GetEquipBreakthroughCfg(self.TemplateId, self.BreakThrough).LevelLimit
    self.TxtLevel.text = CsXTextManager.GetText("EquipLevelText", self.Level, levelLimit)
end

function XUiExpeditionEquipDetailChild:UpdateEquipBreakThrough()
    self:SetUiSprite(self.ImgBreakThrough, XEquipConfig.GetEquipBreakThroughIcon(self.BreakThrough))
end

function XUiExpeditionEquipDetailChild:InitEquipInfo()
    local star = XDataCenter.EquipManager.GetEquipStar(self.TemplateId)
    for i = 1, XEquipConfig.MAX_STAR_COUNT do
        if i <= star then
            self["ImgStar" .. i].gameObject:SetActive(true)
        else
            self["ImgStar" .. i].gameObject:SetActive(false)
        end
    end

    self.TxtEquipName.text = XDataCenter.EquipManager.GetEquipName(self.TemplateId)

    local equipSite = XDataCenter.EquipManager.GetEquipSiteByTemplateId(self.TemplateId)
    if equipSite ~= XEquipConfig.EquipSite.Weapon then
        self.RImgIcon:SetRawImage(XDataCenter.EquipManager.GetEquipIconBagPath(self.TemplateId, self.BreakThrough))
        self.TxtPos.text = "0" .. equipSite
        self.PanelPos.gameObject:SetActive(true)
        self.RImgType.gameObject:SetActive(false)
    else
        self.RImgType:SetRawImage(XEquipConfig.GetWeaponTypeIconPath(self.TemplateId))
        self.RImgType.gameObject:SetActive(true)
        self.PanelPos.gameObject:SetActive(false)
    end
    self.PanelSpecialCharacter.gameObject:SetActive(false)
end

function XUiExpeditionEquipDetailChild:UpdateEquipAttr()
    local attrMap = XDataCenter.EquipManager.ConstructTemplateEquipAttrMap(self.TemplateId, self.BreakThrough, self.Level)
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