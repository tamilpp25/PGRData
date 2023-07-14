local PanelUsingWords = CS.XTextManager.GetText("EquipGridUsingWords")
local PanelInPrefabWords = CS.XTextManager.GetText("EquipGridInPrefabWords")
local PanelSelectedWords = CS.XTextManager.GetText("MentorGiftIsSelectedText")
local XUiGridEquip = XClass(nil, "XUiGridEquip")

function XUiGridEquip:Ctor(ui, clickCb, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.ClickCb = clickCb
    self:InitAutoScript()
    self:SetSelected(false)

    XEventManager.AddEventListener(XEventId.EVENT_EQUIP_PUTON_NOTYFY, self.UpdateUsing, self)
    XEventManager.AddEventListener(XEventId.EVENT_EQUIP_TAKEOFF_NOTYFY, self.UpdateUsing, self)
    XEventManager.AddEventListener(XEventId.EVENT_EQUIP_LOCK_STATUS_CHANGE_NOTYFY, self.UpdateIsLock, self)
    XEventManager.AddEventListener(XEventId.EVENT_EQUIP_RECYCLE_STATUS_CHANGE_NOTYFY, self.UpdateIsRecycle, self)
    XEventManager.AddEventListener(XEventId.EVENT_EQUIP_BREAKTHROUGH_NOTYFY, self.UpdateBreakthrough, self)
end

function XUiGridEquip:InitRootUi(rootUi)
    self.RootUi = rootUi
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
        self.RootUi:SetUiSprite(self.ImgQuality, XDataCenter.EquipManager.GetEquipQualityPath(templateId))
    end

    --装备专用的竖条品质色
    if self.ImgEquipQuality then
        self.RootUi:SetUiSprite(self.ImgEquipQuality, XDataCenter.EquipManager.GetEquipBgPath(templateId))
    end

    if self.TxtName then
        self.TxtName.text = XDataCenter.EquipManager.GetEquipName(templateId)
    end

    if self.TxtLevel then
        self.TxtLevel.text = equip.Level
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
                local icon = XEquipConfig.GetEquipResoanceIconPath(XDataCenter.EquipManager.IsEquipPosAwaken(equipId, i))
                self.RootUi:SetUiSprite(obj, icon)
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
        self.RootUi:SetUiSprite(self.ImgBreakthrough, icon)
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
    CsXUiHelper.RegisterClickEvent(self.BtnClick, function() self:OnBtnClickClick() end)
end

function XUiGridEquip:OnBtnClickClick()
    if self.ClickCb then
        self.ClickCb(self.EquipId, self)
    end
end

return XUiGridEquip