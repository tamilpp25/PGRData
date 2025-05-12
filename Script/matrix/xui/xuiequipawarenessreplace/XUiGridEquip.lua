local PanelUsingWords = CS.XTextManager.GetText("EquipGridUsingWords")
local PanelInPrefabWords = CS.XTextManager.GetText("EquipGridInPrefabWords")
local PanelSelectedWords = CS.XTextManager.GetText("MentorGiftIsSelectedText")
local XUiGridEquip = XClass(nil, "XUiGridEquip")

-- 事件注册后没有移除，请使用Lua\Matrix\XUi\XUiEquip\XUiGridEquip.lua
function XUiGridEquip:Ctor(ui, rootUi, clickCb, isNeedEvent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = rootUi
    self.ClickCb = clickCb
    self.IsNeedEvent = isNeedEvent
    self:InitAutoScript()
    self:SetSelected(false)

    if self.IsNeedEvent then
        XEventManager.AddEventListener(XEventId.EVENT_EQUIP_PUTON_NOTYFY, self.UpdateUsing, self)
        XEventManager.AddEventListener(XEventId.EVENT_EQUIP_TAKEOFF_NOTYFY, self.UpdateUsing, self)
        XEventManager.AddEventListener(XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY, self.UpdateIsLock, self)
        XEventManager.AddEventListener(XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY, self.UpdateIsRecycle, self)
        XEventManager.AddEventListener(XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY, self.UpdateBreakthrough, self)
    end
end

function XUiGridEquip:OnRelease()
    if self.IsNeedEvent then
        XEventManager.RemoveEventListener(XEventId.EVENT_EQUIP_PUTON_NOTYFY, self.UpdateUsing, self)
        XEventManager.RemoveEventListener(XEventId.EVENT_EQUIP_TAKEOFF_NOTYFY, self.UpdateUsing, self)
        XEventManager.RemoveEventListener(XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY, self.UpdateIsLock, self)
        XEventManager.RemoveEventListener(XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY, self.UpdateIsRecycle, self)
        XEventManager.RemoveEventListener(XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY, self.UpdateBreakthrough, self)
    end
end

function XUiGridEquip:InitRootUi(rootUi)
    self.Parent = rootUi
end

function XUiGridEquip:Refresh(equipId,idList)
    self.EquipId = equipId
    local equip = XMVCA.XEquip:GetEquip(equipId)
    if not equip then
        return
    end

    local templateId = equip.TemplateId

    if self.RImgIcon and self.RImgIcon:Exist() then
        self.RImgIcon:SetRawImage(XMVCA.XEquip:GetEquipIconPath(templateId, equip.Breakthrough), nil, true)
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
        self.TxtName.text = XMVCA.XEquip:GetEquipName(templateId)
    end

    if self.TxtLevel then
        self.TxtLevel.text = equip.Level
    end

    -- 公约驻守激活橙色边框
    local equipSite = XMVCA.XEquip:GetEquipSiteByEquipId(equipId)
    local isActiveAwarenessOcuupy = XTool.IsNumberValid(equipSite) and XDataCenter.FubenAwarenessManager.GetChapterDataBySiteNum(equipSite):IsOccupy()
    if self.ImgFrame then
        self.ImgFrame.gameObject:SetActiveEx(isActiveAwarenessOcuupy)
    end

    if self.PanelSite and self.TxtSite then
        local equipSite = XMVCA.XEquip:GetEquipSiteByEquipId(equipId)
        if equipSite and equipSite ~= XEnumConst.EQUIP.EQUIP_SITE.WEAPON then
            self.TxtSite.text = "0" .. equipSite
            self.PanelSite.gameObject:SetActiveEx(true)
        else
            self.PanelSite.gameObject:SetActiveEx(false)
        end
    end

    for i = 1, XEnumConst.EQUIP.MAX_STAR_COUNT do
        if self["ImgGirdStar" .. i] then
            if i <= XMVCA.XEquip:GetEquipStar(templateId) then
                self["ImgGirdStar" .. i].transform.parent.gameObject:SetActiveEx(true)
            else
                self["ImgGirdStar" .. i].transform.parent.gameObject:SetActiveEx(false)
            end
        end
    end

    for i = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
        local obj = self["ImgResonance" .. i]
        if obj then
            if XMVCA.XEquip:CheckEquipPosResonanced(equipId, i) then
                -- 公约驻守+超频激活橙色标签
                local awaken = XMVCA.XEquip:IsEquipPosAwaken(equipId, i)
                local icon = XMVCA.XEquip:GetResoanceIconPath(awaken)
                local bindCharId = XMVCA.XEquip:GetResonanceBindCharacterId(equipId, i)
                local characterId = XMVCA.XEquip:GetEquipWearingCharacterId(equipId)
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
    if XMVCA.XEquip:IsWearing(equipId) then
        if not XTool.UObjIsNil(self.TxtUsingOrInSuitPrefab) then
            self.TxtUsingOrInSuitPrefab.text = PanelUsingWords
        end
        self.PanelUsing.gameObject:SetActiveEx(true)
        if not XTool.UObjIsNil(self.PanelDefault) then self.PanelDefault.gameObject:SetActiveEx(false) end
        if not XTool.UObjIsNil(self.RImgRole) then
            local characterId = XMVCA.XEquip:GetEquipWearingCharacterId(equipId)
            local icon = XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(characterId)
            self.RImgRole:SetRawImage(icon)
        end
    elseif XMVCA.XEquip:IsInSuitPrefab(equipId)
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
    self.ImgLock.gameObject:SetActiveEx(XMVCA.XEquip:IsLock(self.EquipId))
end

function XUiGridEquip:UpdateIsRecycle(equipId)
    if equipId ~= self.EquipId then
        return
    end
    if XTool.UObjIsNil(self.ImgLaJi) then
        return
    end
    self.ImgLaJi.gameObject:SetActiveEx(XMVCA.XEquip:IsRecycle(self.EquipId))
end

function XUiGridEquip:UpdateBreakthrough(equipId)
    if equipId ~= self.EquipId then
        return
    end
    if XTool.UObjIsNil(self.ImgBreakthrough) then
        return
    end

    local icon = XMVCA.XEquip:GetEquipBreakThroughSmallIconByEquipId(self.EquipId)
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