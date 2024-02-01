local XUiGridFashionWeaponRandomSelect = XClass(XUiNode, "XUiGridFashionWeaponRandomSelect")

function XUiGridFashionWeaponRandomSelect:OnStart()
end

function XUiGridFashionWeaponRandomSelect:Refresh(weaponFashionId)
    local characterId = self.Parent.CharacterId
    local icon
    local isDefault = XWeaponFashionConfigs.IsDefaultId(weaponFashionId)
    if isDefault then
        local templateId
        if not XMVCA.XCharacter:IsOwnCharacter(characterId) then
            templateId = XMVCA.XCharacter:GetCharacterDefaultEquipId(characterId)
        else
            local equipId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
            templateId = XDataCenter.EquipManager.GetEquipTemplateId(equipId)
        end
        icon = XDataCenter.EquipManager.GetEquipBigIconPath(templateId)
    else
        icon = XWeaponFashionConfigs.GetFashionBigIcon(weaponFashionId)
    end
    local fashionName = XDataCenter.WeaponFashionManager.GetWeaponFashionName(weaponFashionId, characterId)
    self.TxtName.text = fashionName

    self.Weapon:SetRawImage(icon)
    self.PanelDefault.gameObject:SetActiveEx(isDefault)

    local isCurrent = self.Parent.CurBindList[self.Parent.CurSelectFashionId] == weaponFashionId
    self.PanelCurrent.gameObject:SetActiveEx(isCurrent)
end

return XUiGridFashionWeaponRandomSelect