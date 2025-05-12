local XUiGridFashionRandom = XClass(XUiNode, "XUiGridFashionRandom")

function XUiGridFashionRandom:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnWeaponRandom, self.OnBtnWeaponRandomClick)
end

function XUiGridFashionRandom:Refresh(fashionId, index)
    self.FashionId = fashionId
    self.Index = index
    local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
    self.Fashion:SetRawImage(template.Icon)

    local characterId = self.Parent.CharacterId
    local weaponFashionId = self.Parent.BindWeaponFashionDic[fashionId] or 0
    local icon = nil
    -- 武器的icon
    if XWeaponFashionConfigs.IsDefaultId(weaponFashionId) then
        local equipId = XMVCA.XEquip:GetCharacterWeaponId(characterId)
        local templateId = XMVCA.XEquip:GetEquipTemplateId(equipId)
        icon = XMVCA.XEquip:GetEquipBigIconPath(templateId)
    else
        icon = XWeaponFashionConfigs.GetFashionBigIcon(weaponFashionId)
    end
    self.Weapon:SetRawImage(icon)
    self.PanelWearing.gameObject:SetActiveEx(self.Parent.RandomFashionListReadyToRequset[fashionId])
    self:SetBtnWeaponRandomActive(self.FashionId == self.Parent.CurSelectFashionId)
end

function XUiGridFashionRandom:SetBtnWeaponRandomActive(flag)
    self.BtnWeaponRandom.gameObject:SetActiveEx(flag)
end

function XUiGridFashionRandom:OnBtnWeaponRandomClick()
    if self.FashionId ~= self.Parent.CurSelectFashionId then
        return
    end

    XLuaUiManager.Open("UiFashionWeaponRandomSelect", self.Parent.CharacterId, self.FashionId, self.Parent.BindWeaponFashionDic,function (curSelectWeaponFashionId)
        self.Parent:OnBindWeaponFashionChange(self.FashionId, curSelectWeaponFashionId, self.Index)
    end)
end

return XUiGridFashionRandom