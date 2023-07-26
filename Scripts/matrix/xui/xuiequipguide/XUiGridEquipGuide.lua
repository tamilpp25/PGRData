

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
    local template = XEquipConfig.GetEquipSuitCfg(id)
    self.TxtName.text = template.Name
    self.RImgIcon:SetRawImage(template.IconPath)
    self.TxtDescribe.text = template.Description
    self.TxtSuitNumber.text = XUiHelper.GetText("ReformAwarenessSuitText", number)
    local templateId = XEquipConfig.GetEquipTemplateIdsBySuitId(id)[1]
    self.ImgQuality:SetSprite(XDataCenter.EquipManager.GetEquipQualityPath(templateId))
end

function XUiGridEquipGuide:RefreshWeapon(id)
    --名称
    if self.TxtName then
        self.TxtName.text = XDataCenter.EquipManager.GetEquipName(id)
    end
    --图标
    self.RImgIcon:SetRawImage(XDataCenter.EquipManager.GetEquipIconPath(id))
    --星级图标
    self.ImgQuality:SetSprite(XDataCenter.EquipManager.GetEquipQualityPath(id))
    --描述
    if self.TxtDescribe then
        local skillId = XEquipConfig.GetEquipCfg(id).WeaponSkillId
        self.TxtDescribe.text = XEquipConfig.GetWeaponSkillInfo(skillId).Account 
    end
end

function XUiGridEquipGuide:RefreshEquip(data)
    local exist = data:IsExist()
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
        self.TxtLevel.gameObject:SetActiveEx(exist)
        self.TxtLevel.text = data:GetProperty("_Level")
    end
    --灰色遮罩
    if self.ImgMedalIconlock then
        self.ImgMedalIconlock.gameObject:SetActiveEx(not exist)
    end
    --突破
    if self.ImgBreakthrough then
        local isValidBreak = XTool.IsNumberValid(data:GetProperty("_Breakthrough")) and true or false
        self.ImgBreakthrough.gameObject:SetActiveEx(isValidBreak)
        if isValidBreak then
            self.ImgBreakthrough:SetSprite(data:GetProperty("_BreakthroughIcon"))
        end
    end
    --意识位置
    local type = data:GetProperty("_EquipType")
    if self.TxtSite then
        self.PanelSite.gameObject:SetActiveEx(type == XArrangeConfigs.Types.Wafer)
        self.TxtSite.text = string.format("0%d", data:GetProperty("_Site"))
    end
    --超频次数
    local resonances = data:GetProperty("_Resonances")
    local isResonance = XTool.IsNumberValid(resonances)
    local equipId = data:GetProperty("_Id")
    if self.PanelResonance then
        self.PanelResonance.gameObject:SetActiveEx(isResonance)
        if isResonance then
            for i = 1, XEquipConfig.MAX_RESONANCE_SKILL_COUNT do
                local bResonance = resonances >= i
                self["ImgResonance"..i].gameObject:SetActiveEx(bResonance)
                if bResonance then
                    self["ImgResonance"..i]:SetSprite(XEquipConfig.GetEquipResoanceIconPath(XDataCenter.EquipManager.IsEquipPosAwaken(equipId, i)))
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