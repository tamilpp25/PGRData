
---@class XUiPanelBubbleSkill : XUiNode
---@field _Control XBlackRockChessControl
local XUiPanelBubbleSkill = XClass(XUiNode, "XUiPanelBubbleSkill")

function XUiPanelBubbleSkill:OnStart()
    self.BtnClose.CallBack = function() 
        self:Close()
    end
end

function XUiPanelBubbleSkill:RefreshView(roleId, id, showType)
    self.RoleId = roleId
    if showType == XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON_SKILL then
        self:ShowWeaponSkill(id)
    elseif showType == XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.CHARACTER_SKILL then
        self:ShowCharacterSkill(id)
    elseif showType == XEnumConst.BLACK_ROCK_CHESS.SKILL_TIP_TYPE.WEAPON then
        self:ShowWeapon(id)
    end
end

function XUiPanelBubbleSkill:ShowWeaponSkill(skillId)
    self.TxtName.text = self._Control:GetWeaponSkillName(skillId)
    self.TxtDetail.text = self._Control:GetWeaponSkillDesc(skillId)
    self.RImgLegend:SetRawImage(self._Control:GetWeaponSkillMapIcon(skillId))
    local cost = self._Control:GetWeaponSkillCost(self.RoleId, skillId)
    local cd = self._Control:GetWeaponSkillCd(self.RoleId, skillId, true)
    self.PanelEnergyNum.gameObject:SetActiveEx(cost > 0)
    self.TxtNum.text = cost
    self.PanelCd.gameObject:SetActiveEx(cd > 0)
    self.TxtCdNum.text = cd
    --self.Weapon.gameObject:SetActiveEx(true)
    --self.Character.gameObject:SetActiveEx(false)
end

function XUiPanelBubbleSkill:ShowWeapon(buffId)
    self.TxtName.text = self._Control:GetWeaponName(buffId)
    self.TxtDetail.text = self._Control:GetWeaponDesc(buffId)
    self.RImgLegend:SetRawImage(self._Control:GetWeaponMapIcon(buffId))
    --self.Weapon.gameObject:SetActiveEx(true)
    --self.Character.gameObject:SetActiveEx(false)
    self.PanelEnergyNum.gameObject:SetActiveEx(false)

    self.PanelCd.gameObject:SetActiveEx(false)
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