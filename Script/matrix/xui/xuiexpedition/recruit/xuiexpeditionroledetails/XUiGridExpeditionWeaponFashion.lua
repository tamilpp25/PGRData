local XUiGridExpeditionWeaponFashion = XClass(nil, "XUiGridExpeditionWeaponFashion")

function XUiGridExpeditionWeaponFashion:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
    self:SetSelect(false)
end

function XUiGridExpeditionWeaponFashion:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiGridExpeditionWeaponFashion:OnBtnClick()
    self.RootUi:OnChildBtnClick(self)
end

function XUiGridExpeditionWeaponFashion:Refresh(fashionId, characterId, robotId)
    self.FashionId = fashionId
    self.CharacterId = characterId

    local icon
    if XWeaponFashionConfigs.IsDefaultId(fashionId) then
        local robotConfig = XRobotManager.GetRobotTemplate(robotId)
        local templateId = robotConfig.WeaponId
        icon = XDataCenter.EquipManager.GetEquipIconPath(templateId)
    else
        icon = XWeaponFashionConfigs.GetFashionIcon(fashionId)
    end
    self.RImgIcon:SetRawImage(icon)

    local status = XDataCenter.WeaponFashionManager.GetFashionStatus(fashionId, characterId)
    local fashionStatus = XDataCenter.WeaponFashionManager.FashionStatus

    if status == fashionStatus.Dressed then
        self.ImgQuality.gameObject:SetActiveEx(true)
        self.RootUi:OnChildBtnClick(self)
    else
        self.ImgQuality.gameObject:SetActiveEx(false)
    end
end

function XUiGridExpeditionWeaponFashion:SetSelect(isSelect)
    if self.BgSelect then
        self.BgSelect.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridExpeditionWeaponFashion:CheckDressedState()
    local status = XDataCenter.WeaponFashionManager.GetFashionStatus(self.FashionId, self.CharacterId)
    return status == XDataCenter.WeaponFashionManager.FashionStatus.Dressed
end

return XUiGridExpeditionWeaponFashion