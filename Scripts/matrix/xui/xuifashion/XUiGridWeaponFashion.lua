local CSUnityEngineColor = CS.UnityEngine.Color

local XUiGridWeaponFashion = XClass(nil, "XUiGridWeaponFashion")

function XUiGridWeaponFashion:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:SetSelect(false)
end

function XUiGridWeaponFashion:PlayAnimation()
    if XTool.UObjIsNil(self.GridFashionTimeline) then return end

    XScheduleManager.ScheduleOnce(function()
        if self.GridFashionTimeline.gameObject.activeInHierarchy then
            self.GridFashionTimeline:PlayTimelineAnimation()
        end
    end, 40)
end

function XUiGridWeaponFashion:CheckAnimationFinish()
    if not self.ImgSelected then
        return
    end

    local canvasGroup = self.ImgSelected:GetComponent("CanvasGroup")
    if canvasGroup and canvasGroup.alpha ~= 1 then
        self:PlayAnimation()
    end
end

function XUiGridWeaponFashion:SetSelect(isSelect)
    if self.ImgSelected then
        self.ImgSelected.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridWeaponFashion:Refresh(fashionId, characterId)
    self.CharacterId = characterId
    self.FashionId = fashionId

    self:CheckAnimationFinish()

    local icon
    if XWeaponFashionConfigs.IsDefaultId(fashionId) then
        local templateId
        if not XDataCenter.CharacterManager.IsOwnCharacter(characterId) then
            templateId = XCharacterConfigs.GetCharacterDefaultEquipId(characterId)
        else
            local equipId = XDataCenter.EquipManager.GetCharacterWearingWeaponId(characterId)
            templateId = XDataCenter.EquipManager.GetEquipTemplateId(equipId)
        end
        icon = XDataCenter.EquipManager.GetEquipIconPath(templateId)
        self.ImgTagDefault.gameObject:SetActiveEx(true)
    else
        icon = XWeaponFashionConfigs.GetFashionIcon(fashionId)
        self.ImgTagDefault.gameObject:SetActiveEx(false)
    end
    self.RImgIcon:SetRawImage(icon)

    local weaponFashion = XDataCenter.WeaponFashionManager.GetWeaponFashion(fashionId)
    if weaponFashion and weaponFashion:IsTimeLimit() then
        local leftTime = weaponFashion:GetLeftTime()
        self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.ImgTagTime.gameObject:SetActiveEx(true)
    else
        self.ImgTagTime.gameObject:SetActiveEx(false)
    end

    self:UpdateStatus()
end

function XUiGridWeaponFashion:UpdateStatus()
    local status = XDataCenter.WeaponFashionManager.GetFashionStatus(self.FashionId, self.CharacterId)
    local fashionStatus = XDataCenter.WeaponFashionManager.FashionStatus

    if status == fashionStatus.UnOwned then -- 未获得
        self.ImgLock.gameObject:SetActiveEx(true)
        self.ImgUse.gameObject:SetActiveEx(false)
        self.RImgIcon.color = CSUnityEngineColor(1, 1, 1, 0.6)
    elseif status == fashionStatus.Dressed then --已穿戴
        self.ImgLock.gameObject:SetActiveEx(false)
        self.ImgUse.gameObject:SetActiveEx(true)
        self.RImgIcon.color = CSUnityEngineColor(1, 1, 1, 1)
    elseif status == fashionStatus.UnLock then --已解锁
        self.ImgLock.gameObject:SetActiveEx(false)
        self.ImgUse.gameObject:SetActiveEx(false)
        self.RImgIcon.color = CSUnityEngineColor(1, 1, 1, 1)
    end
end

return XUiGridWeaponFashion