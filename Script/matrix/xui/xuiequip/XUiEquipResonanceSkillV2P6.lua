local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")
local CSInstantiate = CS.UnityEngine.Object.Instantiate
local Vector3Zero = CS.UnityEngine.Vector3.zero

local XUiEquipResonanceSkillV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceSkillV2P6")

function XUiEquipResonanceSkillV2P6:OnAwake()
    self:InstantiateCharGrid()
    self:InstantiateEquipGrid()
    self.GridResonanceSkills = {}
end

function XUiEquipResonanceSkillV2P6:OnStart(parent, characterId, forceShowBindCharacter)
    self.Parent = parent
    self.CharacterId = characterId
    self.ForceShowBindCharacter = forceShowBindCharacter
end

function XUiEquipResonanceSkillV2P6:OnEnable()
    self.EquipId = self.Parent.EquipId
    local equip = self._Control:GetEquip(self.EquipId)
    self.TemplateId = equip.TemplateId
    self.IsWeapon = equip:IsWeapon()
    self:UpdateView()
    self.BtnQuickResonance.gameObject:SetActiveEx(equip.CharacterId == self.CharacterId)
end

function XUiEquipResonanceSkillV2P6:InstantiateCharGrid()
    self.GridSkillChar1 = self.GridSkillChar:GetComponent("UiObject")
    self.GridSkillChar2 = CSInstantiate(self.GridSkillChar.gameObject, self.GridCharPos2):GetComponent("UiObject")
    self.GridSkillChar2.transform.localPosition = Vector3Zero
    self.GridSkillChar3 = CSInstantiate(self.GridSkillChar.gameObject, self.GridCharPos3):GetComponent("UiObject")
    self.GridSkillChar3.transform.localPosition = Vector3Zero

    local btnClick1 = self.GridSkillChar1:GetObject("BtnClick")
    local btnClick2 = self.GridSkillChar2:GetObject("BtnClick")
    local btnClick3 = self.GridSkillChar3:GetObject("BtnClick")
    local btnResonance1 = self.GridSkillChar1:GetObject("BtnResonance")
    local btnResonance2 = self.GridSkillChar2:GetObject("BtnResonance")
    local btnResonance3 = self.GridSkillChar3:GetObject("BtnResonance")
    self:RegisterClickEvent(btnClick1, function() self:OnBtnSkillItemClick(1) end)
    self:RegisterClickEvent(btnClick2, function() self:OnBtnSkillItemClick(2) end)
    self:RegisterClickEvent(btnClick3, function() self:OnBtnSkillItemClick(3) end)
    self:RegisterClickEvent(btnResonance1, function() self:OnBtnSkillItemClick(1) end)
    self:RegisterClickEvent(btnResonance2, function() self:OnBtnSkillItemClick(2) end)
    self:RegisterClickEvent(btnResonance3, function() self:OnBtnSkillItemClick(3) end)
    self:RegisterClickEvent(self.BtnQuickResonance, self.OnBtnQuickResonanceClick)
end

function XUiEquipResonanceSkillV2P6:InstantiateEquipGrid()
    self.GridSkillEquip1 = self.GridSkillEquip
    self.GridSkillEquip2 = CSInstantiate(self.GridSkillEquip.gameObject, self.GridEquipPos2):GetComponent("UiObject")
    self.GridSkillEquip2.transform.localPosition = Vector3Zero

    local btnClick1 = self.GridSkillEquip1:GetObject("BtnClick")
    local btnClick2 = self.GridSkillEquip2:GetObject("BtnClick")
    local btnResonance1 = self.GridSkillEquip1:GetObject("BtnResonance")
    local btnResonance2 = self.GridSkillEquip2:GetObject("BtnResonance")
    self:RegisterClickEvent(btnClick1, function() self:OnBtnSkillItemClick(1) end)
    self:RegisterClickEvent(btnClick2, function() self:OnBtnSkillItemClick(2) end)
    self:RegisterClickEvent(btnResonance1, function() self:OnBtnSkillItemClick(1) end)
    self:RegisterClickEvent(btnResonance2, function() self:OnBtnSkillItemClick(2) end)
end

function XUiEquipResonanceSkillV2P6:OnBtnSkillItemClick(pos)
    -- 5星武器只能共鸣一次
    local equip = XMVCA:GetAgency(ModuleId.XEquip):GetEquip(self.EquipId)
    local star = XMVCA:GetAgency(ModuleId.XEquip):GetEquipQuality(equip.TemplateId)
    if equip:IsWeapon() and equip:GetResonanceInfo(pos) and star == XEnumConst.EQUIP.FIVE_STAR then
        XUiManager.TipText("EquipResonance5StarWeaponRepeatTip")
        return
    end

    self.Parent:JumpToEquipResonanceSelect(pos)
end

function XUiEquipResonanceSkillV2P6:OnBtnQuickResonanceClick()
    XLuaUiManager.Open("UiEquipResonanceQuick", self.CharacterId)
end

function XUiEquipResonanceSkillV2P6:UpdateView()
    self.PanelCharSkill.gameObject:SetActiveEx(self.IsWeapon)
    self.PanelEquipSkill.gameObject:SetActiveEx(not self.IsWeapon)

    local DESC_LENGTH_LIMIT = 40
    local count = self.IsWeapon and XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT or XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT
    local gridName = self.IsWeapon and "GridSkillChar" or "GridSkillEquip"
    for pos = 1, count do
        local gridObj = self[gridName .. pos]
        local isEquip = XMVCA.XEquip:CheckEquipPosResonanced(self.EquipId, pos) ~= nil
        gridObj:GetObject("GridResonanceSkill").gameObject:SetActiveEx(isEquip)
        gridObj:GetObject("PanelAdd").gameObject:SetActiveEx(not isEquip)

        if isEquip then
            local skillGrid = self.GridResonanceSkills[pos]
            if not skillGrid then
                local item = gridObj:GetObject("GridResonanceSkill")
                skillGrid = XUiGridResonanceSkill.New(item, self.EquipId, pos, self.CharacterId, nil, nil, self.ForceShowBindCharacter, true)
                self.GridResonanceSkills[pos] = skillGrid
            end
            skillGrid:SetEquipIdAndPos(self.EquipId, pos)
            skillGrid:SetDescLengthLimit(DESC_LENGTH_LIMIT)
            skillGrid:Refresh()

            local effect = skillGrid.Transform:Find("Effect")
            local showEffect = self.Parent.ResonanceSuccessPos == pos
            effect.gameObject:SetActiveEx(showEffect)
            if showEffect then
                self.Parent:ClearResonanceSuccessPos()
            end
        end
    end 
end

return XUiEquipResonanceSkillV2P6
