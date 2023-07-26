local XUiGridEquipOther = XClass(nil, "XUiGridEquipOther")

function XUiGridEquipOther:Ctor(ui, rootUi, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = clickCb
    self:InitAutoScript()
end

function XUiGridEquipOther:Refresh(equip, awarenessSetPositions, characterId)
    local templateId = equip.TemplateId

    if self.RImgIcon and self.RImgIcon:Exist() then
        self.RImgIcon:SetRawImage(XDataCenter.EquipManager.GetEquipIconBagPath(templateId, equip.Breakthrough), nil, true)
    end

    --通用的横条品质色
    if self.ImgQuality then
        self.RootUi.Parent:SetUiSprite(self.ImgQuality, equip:GetEquipQualityPath())

        if self.ImgQualityEffect then
            local effectPath = equip:GetEquipQualityEffectPath()
            self.ImgQualityEffect.gameObject:SetActiveEx(effectPath ~= nil)
            if effectPath then
                self.ImgQualityEffect.gameObject:LoadUiEffect(effectPath)
            end
        end
    end

    --装备专用的竖条品质色
    if self.ImgEquipQuality then
        self.RootUi.Parent:SetUiSprite(self.ImgEquipQuality, equip:GetEquipBgPath())

        if self.ImgEquipQualityEffect then
            local effectPath = equip:GetEquipBgEffectPath()
            self.ImgEquipQualityEffect.gameObject:SetActiveEx(effectPath ~= nil)
            if effectPath then
                self.ImgEquipQualityEffect.gameObject:LoadUiEffect(effectPath)
            end
        end
    end

    if self.TxtName then
        self.TxtName.text = XDataCenter.EquipManager.GetEquipName(templateId)
    end

    if self.TxtLevel then
        self.TxtLevel.text = equip.Level
    end

    -- 公约驻守激活橙色边框
    local equipSite = XDataCenter.EquipManager.GetEquipSiteByEquipData(equip)
    local chapterId = XDataCenter.FubenAwarenessManager.GetChapterIdList()[equipSite]
    local isChapterIdInOccupyList = nil
    if awarenessSetPositions then
        isChapterIdInOccupyList = table.contains(awarenessSetPositions, chapterId)
    end
    local isActiveAwarenessOcuupy = isChapterIdInOccupyList
    if self.ImgFrame then
        self.ImgFrame.gameObject:SetActiveEx(isActiveAwarenessOcuupy)
    end

    if self.PanelSite and self.TxtSite then
        local equipSite = XDataCenter.EquipManager.GetEquipSiteByEquipData(equip)
        if equipSite and equipSite ~= XEquipConfig.EquipSite.Weapon then
            self.TxtSite.text = "0" .. equipSite
            self.PanelSite.gameObject:SetActiveEx(true)
        else
            self.PanelSite.gameObject:SetActiveEx(false)
        end
    end

    for i = 1, XEquipConfig.MAX_STAR_COUNT do
        if self["ImgGirdStar" .. i] then
            if i <= XDataCenter.EquipManager.GetEquipStar(templateId) then
                self["ImgGirdStar" .. i].transform.parent.gameObject:SetActiveEx(true)
            else
                self["ImgGirdStar" .. i].transform.parent.gameObject:SetActiveEx(false)
            end
        end
    end

    for i = 1, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
        local obj = self["ImgResonance" .. i]
        if obj then
            local resonanceInfo = equip.ResonanceInfo
            if resonanceInfo and resonanceInfo[i] then
                local icon = XEquipConfig.GetEquipResoanceIconPath(equip:IsEquipPosAwaken(i))

                local awaken = equip.AwakeSlotList and equip.AwakeSlotList[i] and true or false
                local bindCharId = resonanceInfo[i].CharacterId

                if isActiveAwarenessOcuupy and awaken and XTool.IsNumberValid(characterId) and bindCharId == characterId then
                    icon = CS.XGame.ClientConfig:GetString("AwarenessOcuupyActiveResonanced")
                end

                self.RootUi.Parent:SetUiSprite(obj, icon)
                obj.gameObject:SetActiveEx(true)
            else
                obj.gameObject:SetActiveEx(false)
            end
        end
    end

    self:UpdateBreakthrough(equip)

end

function XUiGridEquipOther:UpdateBreakthrough(equip)
    if XTool.UObjIsNil(self.ImgBreakthrough) then
        return
    end

    local icon
    if equip.Breakthrough ~= 0 then
        icon = XEquipConfig.GetEquipBreakThroughSmallIcon(equip.Breakthrough)
    end

    if icon then
        self.RootUi.Parent:SetUiSprite(self.ImgBreakthrough, icon)
        self.ImgBreakthrough.gameObject:SetActiveEx(true)
    else
        self.ImgBreakthrough.gameObject:SetActiveEx(false)
    end
end

function XUiGridEquipOther:InitAutoScript()
    XTool.InitUiObject(self)
    CsXUiHelper.RegisterClickEvent(self.BtnClick,function() self:OnBtnClickClick() end)

    --v2.5 品质特效
    if self.ImgQuality then
        self.ImgQualityEffect = XUiHelper.TryGetComponent(self.ImgQuality.transform, "ImgQualityEffect")
    end
    if self.ImgEquipQuality then
        self.ImgEquipQualityEffect = XUiHelper.TryGetComponent(self.ImgEquipQuality.transform, "ImgEquipQualityEffect")
    end
end

function XUiGridEquipOther:OnBtnClickClick()
    if self.ClickCb then
        self.ClickCb()
    end
end

return XUiGridEquipOther