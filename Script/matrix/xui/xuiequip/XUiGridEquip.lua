local PanelUsingWords = CS.XTextManager.GetText("EquipGridUsingWords")
local PanelInPrefabWords = CS.XTextManager.GetText("EquipGridInPrefabWords")
local PanelSelectedWords = CS.XTextManager.GetText("MentorGiftIsSelectedText")
local XUiGridEquip = XClass(XUiNode, "XUiGridEquip")

function XUiGridEquip:OnStart(clickCb)
    self.ClickCb = clickCb

    self:InitAutoScript()
    self:SetSelected(false)
end

function XUiGridEquip:InitRootUi(rootUi)
    self.Parent = rootUi
end

function XUiGridEquip:Refresh(equipId,idList)
    self.EquipId = equipId
    local equip = XDataCenter.EquipManager.GetEquip(equipId)
    if not equip then
        return
    end

    local templateId = equip.TemplateId

    if self.RImgIcon and self.RImgIcon:Exist() then
        self.RImgIcon:SetRawImage(XDataCenter.EquipManager.GetEquipIconBagPath(templateId, equip.Breakthrough), nil, true)
    end

    --通用的横条品质色
    if self.ImgQuality then
        local qualityPath = equip:GetEquipQualityPath()
        self.Parent:SetUiSprite(self.ImgQuality, qualityPath)

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
        local bgPath = equip:GetEquipBgPath()
        self.Parent:SetUiSprite(self.ImgEquipQuality, bgPath)

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
    local equipSite = XDataCenter.EquipManager.GetEquipSite(equipId)
    local isActiveAwarenessOcuupy = XTool.IsNumberValid(equipSite) and XDataCenter.FubenAwarenessManager.GetChapterDataBySiteNum(equipSite):IsOccupy()
    if self.ImgFrame then
        self.ImgFrame.gameObject:SetActiveEx(isActiveAwarenessOcuupy)
    end

    if self.PanelSite and self.TxtSite then
        local equipSite = XDataCenter.EquipManager.GetEquipSite(equipId)
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
            if XDataCenter.EquipManager.CheckEquipPosResonanced(equipId, i) then
                -- 公约驻守+超频激活橙色标签
                local awaken = XDataCenter.EquipManager.IsEquipPosAwaken(equipId, i)
                local icon = XEquipConfig.GetEquipResoanceIconPath(awaken)
                local bindCharId = XDataCenter.EquipManager.GetResonanceBindCharacterId(equipId, i)
                local characterId = XDataCenter.EquipManager.GetEquipWearingCharacterId(equipId)
                if isActiveAwarenessOcuupy and awaken and bindCharId == characterId then
                    icon = CS.XGame.ClientConfig:GetString("AwarenessOcuupyActiveResonanced")
                end
                self.Parent:SetUiSprite(obj, icon)
                obj.gameObject:SetActiveEx(true)
            else
                obj.gameObject:SetActiveEx(false)
            end
        end
    end

    self:UpdateIsLock(equipId)
    self:UpdateIsRecycle(equipId)
    self:UpdateUsing(equipId,idList)
    self:UpdateBreakthrough(equipId)
end

function XUiGridEquip:SetSelected(status)
    if XTool.UObjIsNil(self.ImgSelect) then
        return
    end
    self.ImgSelect.gameObject:SetActiveEx(status)
end

function XUiGridEquip:IsSelected()
    return not XTool.UObjIsNil(self.ImgSelect) and self.ImgSelect.gameObject.activeSelf
end

function XUiGridEquip:UpdateUsing(equipId,idList)
    if equipId ~= self.EquipId then return end
    if XTool.UObjIsNil(self.PanelUsing) then return end

    --v1.28 装备头像
    if XDataCenter.EquipManager.IsWearing(equipId) then
        if not XTool.UObjIsNil(self.TxtUsingOrInSuitPrefab) then
            self.TxtUsingOrInSuitPrefab.text = PanelUsingWords
        end
        self.PanelUsing.gameObject:SetActiveEx(true)
        if not XTool.UObjIsNil(self.PanelDefault) then self.PanelDefault.gameObject:SetActiveEx(false) end
        if not XTool.UObjIsNil(self.RImgRole) then
            local characterId = XDataCenter.EquipManager.GetEquipWearingCharacterId(equipId)
            local icon = XDataCenter.CharacterManager.GetCharBigRoundnessNotItemHeadIcon(characterId)
            self.RImgRole:SetRawImage(icon)
        end
    elseif XDataCenter.EquipManager.IsInSuitPrefab(equipId)
    and not XTool.UObjIsNil(self.TxtUsingOrInSuitPrefab) then
        if not XTool.UObjIsNil(self.TextInPrefab) then 
            self.PanelUsing.gameObject:SetActiveEx(false)
            self.PanelDefault.gameObject:SetActiveEx(true)
            self.TextInPrefab.text = PanelInPrefabWords
        else
            self.PanelUsing.gameObject:SetActiveEx(true)
            self.TxtUsingOrInSuitPrefab.text = PanelInPrefabWords
        end
    else
        self.PanelUsing.gameObject:SetActiveEx(false)
        if not XTool.UObjIsNil(self.PanelDefault) then self.PanelDefault.gameObject:SetActiveEx(false) end
    end
    
    if idList then
        for _,id in pairs(idList) do
            if equipId == id then
                if not XTool.UObjIsNil(self.TxtUsingOrInSuitPrefab) then
                    self.TxtUsingOrInSuitPrefab.text = PanelSelectedWords
                end
                self.PanelUsing.gameObject:SetActiveEx(true) 
            end
        end
    end
end

function XUiGridEquip:UpdateIsLock(equipId)
    if equipId ~= self.EquipId then
        return
    end
    if XTool.UObjIsNil(self.ImgLock) then
        return
    end
    self.ImgLock.gameObject:SetActiveEx(XDataCenter.EquipManager.IsLock(self.EquipId))
end

function XUiGridEquip:UpdateIsRecycle(equipId)
    if equipId ~= self.EquipId then
        return
    end
    if XTool.UObjIsNil(self.ImgLaJi) then
        return
    end
    self.ImgLaJi.gameObject:SetActiveEx(XDataCenter.EquipManager.IsRecycle(self.EquipId))
end

function XUiGridEquip:UpdateBreakthrough(equipId)
    if equipId ~= self.EquipId then
        return
    end
    if XTool.UObjIsNil(self.ImgBreakthrough) then
        return
    end

    local icon = XDataCenter.EquipManager.GetEquipBreakThroughSmallIcon(self.EquipId)
    if icon then
        self.Parent:SetUiSprite(self.ImgBreakthrough, icon)
        self.ImgBreakthrough.gameObject:SetActiveEx(true)
    else
        self.ImgBreakthrough.gameObject:SetActiveEx(false)
    end
end

function XUiGridEquip:InitAutoScript()
    XTool.InitUiObject(self)
    if not XTool.UObjIsNil(self.PanelUsing) then
        local textGo = self.PanelUsing:Find("TextUsing")
        self.TxtUsingOrInSuitPrefab = textGo and textGo:GetComponent("Text")
        --v1.28 装备头像
        self.RImgRole = self.PanelUsing.transform:Find("RImgRole"):GetComponent("RawImage")
        self.PanelDefault = self.GameObject.transform:Find("GridEquipRectangle/PanelDefault") or nil
        self.TextInPrefab = not XTool.UObjIsNil(self.PanelDefault) and self.PanelDefault.transform:Find("TextUsing"):GetComponent("Text") or nil
    end
    if self.BtnClick and self.ClickCb then
        CsXUiHelper.RegisterClickEvent(self.BtnClick, function() self:OnBtnClickClick() end)
    end

    --v2.5 品质特效
    if self.ImgQuality then
        self.ImgQualityEffect = XUiHelper.TryGetComponent(self.ImgQuality.transform, "ImgQualityEffect")
    end
    if self.ImgEquipQuality then
        self.ImgEquipQualityEffect = XUiHelper.TryGetComponent(self.ImgEquipQuality.transform, "ImgEquipQualityEffect")
    end
end

function XUiGridEquip:OnBtnClickClick()
    if self.ClickCb then
        self.ClickCb(self.EquipId, self)
    end
end

return XUiGridEquip