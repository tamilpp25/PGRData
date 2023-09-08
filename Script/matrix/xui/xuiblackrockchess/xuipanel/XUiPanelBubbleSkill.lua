

local XUiPanelBubbleSkill = XClass(XUiNode, "XUiPanelBubbleSkill")

function XUiPanelBubbleSkill:OnStart()
    self.BtnClose.CallBack = function() 
        self:Close()
    end
end

function XUiPanelBubbleSkill:RefreshView(id, showType)
    if showType == XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON_SKILL then
        self:ShowWeaponSkill(id)
    elseif showType == XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.CHARACTER then
        self:ShowCharacterSkill(id)
    elseif showType == XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON then
        self:ShowWeapon(id)
    end
end

function XUiPanelBubbleSkill:ShowWeaponSkill(skillId)
    self.TxtName.text = self._Control:GetWeaponSkillName(skillId)
    self.TxtDetail.text = self._Control:GetWeaponSkillDesc(skillId)
    self.RImgLegend:SetRawImage(self._Control:GetWeaponSkillMapIcon(skillId))
    local cost
    if self._Control:GetAgency():IsInFight() then
        cost = self._Control:GetWeaponSkillCost(skillId)
    else
        cost = self._Control:GetWeaponSkillCost(skillId, true)
    end
    self.PanelEnergyNum.gameObject:SetActiveEx(cost > 0)
    self.TxtNum.text = cost
    --self.Weapon.gameObject:SetActiveEx(true)
    --self.Character.gameObject:SetActiveEx(false)
end

function XUiPanelBubbleSkill:ShowWeapon(buffId)
    local buff = self._Control:GetBuffConfig(buffId)
    self.TxtCharacterName.text = buff.Name
    self.TxtCharacterDetail.text = buff.Desc
    --self.Weapon.gameObject:SetActiveEx(false)
    --self.Character.gameObject:SetActiveEx(true)
end

function XUiPanelBubbleSkill:ShowCharacterSkill(weaponId)
    self.TxtName.text = self._Control:GetWeaponName(weaponId)
    self.TxtDetail.text = self._Control:GetWeaponDesc(weaponId)
    self.RImgLegend:SetRawImage(self._Control:GetWeaponMapIcon(weaponId))
    --self.Weapon.gameObject:SetActiveEx(true)
    --self.Character.gameObject:SetActiveEx(false)
    self.PanelEnergyNum.gameObject:SetActiveEx(false)
end

return XUiPanelBubbleSkill