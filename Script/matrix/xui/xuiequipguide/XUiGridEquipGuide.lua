

local XUiGridEquipGuide = XClass(nil, "XUiGridEquipGuide")

function XUiGridEquipGuide:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
    self:InitCb()
end 

function XUiGridEquipGuide:InitCb()
    if self.BtnClick then
        CsXUiHelper.RegisterClickEvent(self.BtnClick, function() self:OnClickBtnClick() end)
    end
end

function XUiGridEquipGuide:SetClickCb(cb)
    self.ClickCb = cb
end


function XUiGridEquipGuide:Refresh(id, equipType, number)
    self.Id = id
    self.EquipType = equipType
    if equipType == XEquipGuideConfigs.EquipType.Suit then
        self:RefreshSuit(id, number)
    elseif equipType == XEquipGuideConfigs.EquipType.Weapon then
        self:RefreshWeapon(id)
    end
end 

function XUiGridEquipGuide:RefreshSuit(id, number)
    local template = XMVCA.XEquip:GetConfigEquipSuit(id)
    self.TxtName.text = template.Name
    self.RImgIcon:SetRawImage(template.IconPath)
    self.TxtDescribe.text = template.Description
    self.TxtSuitNumber.text = XUiHelper.GetText("ReformAwarenessSuitText", number)
    local templateId = XMVCA.XEquip:GetSuitEquipIds(id)[1]
    self.ImgQuality:SetSprite(XMVCA.XEquip:GetEquipQualityPath(templateId))
end

function XUiGridEquipGuide:RefreshWeapon(id)
    --名称
    if self.TxtName then
        self.TxtName.text = XMVCA.XEquip:GetEquipName(id)
    end
    --图标
    self.RImgIcon:SetRawImage(XMVCA.XEquip:GetEquipIconPath(id))
    --星级图标
    self.ImgQuality:SetSprite(XMVCA.XEquip:GetEquipQualityPath(id))
    --描述
    if self.TxtDescribe then
        local skillId = XMVCA.XEquip:GetConfigEquip(id).WeaponSkillId
        self.TxtDescribe.text = XMVCA.XEquip:GetConfigWeaponSkill(skillId).Account 
    end
end

function XUiGridEquipGuide:RefreshEquip(data)
    local equip = data:IsWearTemplateIdEquip() and data:GetWearEquip() or nil
    local bestEquip = data:GetBestOneEquip()

    --名称
    if self.TxtName then
        self.TxtName.text = data:GetProperty("_Name")
    end
    --图标
    self.RImgIcon:SetRawImage(data:GetProperty("_Icon"))
    --星级图标
    self.ImgQuality:SetSprite(data:GetProperty("_QualityIcon"))
    --描述
    if self.TxtDescribe then
        self.TxtDescribe.text = data:GetProperty("_EquipDesc")
    end
    --等级
    if self.TxtLevel then
        local levelTxt = ""
        if equip then
            levelTxt = tostring(equip.Level)
        elseif bestEquip then
            levelTxt = tostring(bestEquip.Level)
        end
        self.TxtLevel.text = levelTxt
    end
    --灰色遮罩
    if self.ImgMedalIconlock then
        local isMask = equip == nil and bestEquip == nil
        self.ImgMedalIconlock.gameObject:SetActiveEx(isMask)
    end
    --突破
    if self.ImgBreakthrough then
        self.ImgBreakthrough.gameObject:SetActiveEx(false)
        if equip ~= nil and equip.Breakthrough > 0 then
            local icon = XMVCA.XEquip:GetEquipBreakThroughSmallIcon(equip.Breakthrough)
            self.ImgBreakthrough:SetSprite(icon)
            self.ImgBreakthrough.gameObject:SetActiveEx(true)
        end
    end
    --意识位置
    local type = data:GetProperty("_EquipType")
    if self.TxtSite then
        self.PanelSite.gameObject:SetActiveEx(type == XArrangeConfigs.Types.Wafer)
        self.TxtSite.text = string.format("0%d", data:GetProperty("_Site"))
    end
    --超频次数
    local resonances = equip and equip:GetResonanceCount() or 0
    if self.PanelResonance then
        self.PanelResonance.gameObject:SetActiveEx(resonances > 0)
        if resonances > 0 then
            for i = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
                local bResonance = resonances >= i
                self["ImgResonance"..i].gameObject:SetActiveEx(bResonance)
                if bResonance then
                    local isAwaken = equip:IsEquipPosAwaken(i)
                    self["ImgResonance"..i]:SetSprite(XMVCA.XEquip:GetResoanceIconPath(isAwaken))
                end
            end
        end
    end
end

function XUiGridEquipGuide:OnClickBtnClick()
    if self.ClickCb then
        self.ClickCb()
    else
        XLuaUiManager.Open("UiEquipGuideItemInfo",  self.Id, self.EquipType)
    end
end

return XUiGridEquipGuide