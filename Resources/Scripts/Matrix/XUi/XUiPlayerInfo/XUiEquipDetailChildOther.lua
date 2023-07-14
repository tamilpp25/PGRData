local CsXTextManager = CS.XTextManager

local MAX_AWARENESS_ATTR_COUNT = 2 --不包括共鸣属性，最大有2条
local XUiGridResonanceSkillOther = require("XUi/XUiPlayerInfo/XUiGridResonanceSkillOther")

local XUiEquipDetailChildOther = XLuaUiManager.Register(XLuaUi, "UiEquipDetailChildOther")

XUiEquipDetailChildOther.BtnTabIndex = {
    SuitSkill = 1,
    ResonanceSkill = 2,
}

function XUiEquipDetailChildOther:OnAwake()
    local tabGroupList = {
        self.BtnSuitSkill,
        self.BtnResonanceSkill,
    }
    self.TabGroupRight:Init(tabGroupList, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
end

function XUiEquipDetailChildOther:OnStart(equip, character)
    self.Equip = equip
    self.EquipId = equip.Id
    self.Character = character
    self.TemplateId = equip.TemplateId
    self.GridResonanceSkills = {}

    self:InitTabBtns()
    self:InitClassifyPanel()
    self:InitEquipInfo()
end

function XUiEquipDetailChildOther:OnEnable()
    self:UpdateEquipAttr()
    self:UpdateEquipLevel()
    self:UpdateEquipBreakThrough()
    self:UpdateEquipSkillDes()
    self:UpdateResonanceSkills()

    self.BtnLock.gameObject:SetActiveEx(false)
    self.BtnUnlock.gameObject:SetActiveEx(false)
    self.BtnLaJi.gameObject:SetActiveEx(false)
    self.BtnUnLaJi.gameObject:SetActiveEx(false)
end

function XUiEquipDetailChildOther:OnClickTabCallBack(tabIndex)
    if tabIndex == XUiEquipDetailChildOther.BtnTabIndex.SuitSkill then
        self.PanelSuitSkill.gameObject:SetActive(true)
        self.PanelResonanceSkill.gameObject:SetActive(false)
        self:UpdateEquipSkillDes()
        self:PlayAnimation("SuitSkill")
    elseif tabIndex == XUiEquipDetailChildOther.BtnTabIndex.ResonanceSkill then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipResonance) then
            return
        end
        self.PanelSuitSkill.gameObject:SetActive(false)
        self.PanelResonanceSkill.gameObject:SetActive(true)
        self:UpdateResonanceSkills()
        self:PlayAnimation("ResonanceSkill")
    end
end

function XUiEquipDetailChildOther:InitTabBtns()
    if not XDataCenter.EquipManager.CanResonanceByTemplateId(self.TemplateId) then
        self.BtnResonanceSkill.gameObject:SetActive(false)
        self.BtnSuitSkill.gameObject:SetActive(false)
        return
    end

    self.TabGroupRight:SelectIndex(XUiEquipDetailChildOther.BtnTabIndex.SuitSkill)
end

function XUiEquipDetailChildOther:InitClassifyPanel()
    if XDataCenter.EquipManager.IsClassifyEqualByTemplateId(self.TemplateId, XEquipConfig.Classify.Weapon) then
        self.TxtTitle.text = CsXTextManager.GetText("WeaponDetailTitle")
        self.PanelPainter.gameObject:SetActive(false)
    else
        local breakthroughTimes = not self.IsPreview and XDataCenter.EquipManager.GetBreakthroughTimes(self.EquipId) or 0
        self.TxtPainter.text = XDataCenter.EquipManager.GetEquipPainterName(self.TemplateId, breakthroughTimes)
        self.PanelPainter.gameObject:SetActive(true)
        self.TxtTitle.text = CsXTextManager.GetText("AwarenessDetailTitle")
    end
end

function XUiEquipDetailChildOther:UpdateEquipSkillDes()
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

function XUiEquipDetailChildOther:UpdateEquipLevel()
    local level, levelLimit

    level = self.Equip.Level
    levelLimit = XDataCenter.EquipManager.GetBreakthroughLevelLimitByEquipData(self.Equip)

    self.PanelMaxLevel.gameObject:SetActive((level >= levelLimit) and not XDataCenter.EquipManager.CanBreakThroughByEquipData(self.Equip))

    if level and levelLimit then
        self.TxtLevel.text = CsXTextManager.GetText("EquipLevelText", level, levelLimit)
    end
end

function XUiEquipDetailChildOther:UpdateEquipBreakThrough()
    self:SetUiSprite(self.ImgBreakThrough, XEquipConfig.GetEquipBreakThroughIcon(self.Equip.Breakthrough))
end

function XUiEquipDetailChildOther:InitEquipInfo()
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
        local breakthrough = 0

        breakthrough = self.Equip.Breakthrough
        self.RImgIcon:SetRawImage(XDataCenter.EquipManager.GetEquipIconBagPath(self.TemplateId, breakthrough))
        self.TxtPos.text = "0" .. equipSite
        self.PanelPos.gameObject:SetActive(true)
        self.RImgType.gameObject:SetActive(false)
    else
        self.RImgType:SetRawImage(XEquipConfig.GetWeaponTypeIconPath(self.TemplateId))
        self.RImgType.gameObject:SetActive(true)
        self.PanelPos.gameObject:SetActive(false)
    end

    local equipSpecialCharacterId = XDataCenter.EquipManager.GetEquipSpecialCharacterIdByTemplateId(self.TemplateId)
    if equipSpecialCharacterId then
        self.RImgHead:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(equipSpecialCharacterId))
        self.PanelSpecialCharacter.gameObject:SetActive(true)
    else
        self.PanelSpecialCharacter.gameObject:SetActive(false)
    end
end

function XUiEquipDetailChildOther:UpdateEquipAttr()
    local attrMap

    attrMap = XDataCenter.EquipManager.GetEquipAttrMapByEquipData(self.Equip)

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

function XUiEquipDetailChildOther:UpdateResonanceSkills()
    local count = 1
    local resonanceSkillNum = XDataCenter.EquipManager.GetResonanceSkillNumByTemplateId(self.TemplateId)
    for pos = 1, resonanceSkillNum do
        self["PanelSkill" .. pos].gameObject:SetActive(true)
        self["PanelEmptySkill" .. pos].gameObject:SetActive(true)
        count = count + 1
        self:UpdateResonanceSkill(pos)
    end
    for pos = count, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
        self["PanelSkill" .. pos].gameObject:SetActive(false)
    end
end

function XUiEquipDetailChildOther:UpdateResonanceSkill(pos)
    local grid = self.GridResonanceSkills[pos]

    if self.Equip.ResonanceInfo and self.Equip.ResonanceInfo[pos] then
        if not grid then
            local item = CS.UnityEngine.Object.Instantiate(self.GridResonanceSkill)
            grid = XUiGridResonanceSkillOther.New(item, self.Equip, pos, false, self.Character, function()
                XLuaUiManager.Open("UiEquipResonanceSkillDetailInfo", nil, pos, nil, nil, nil, true, true, self.Character, self.Equip)
            end)
            grid.Transform:SetParent(self["PanelSkill" .. pos], false)
            self.GridResonanceSkills[pos] = grid
        end

        grid:Refresh()
        grid.GameObject:SetActive(true)
        self["PanelEmptySkill" .. pos].gameObject:SetActive(false)
    else
        if grid then
            grid.GameObject:SetActive(false)
        end
    end
end