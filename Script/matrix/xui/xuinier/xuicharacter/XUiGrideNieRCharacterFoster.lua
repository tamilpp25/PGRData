local XUiGrideNieRCharacterFoster = XClass(nil, "XUiGrideNieRCharacterFoster")

function XUiGrideNieRCharacterFoster:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
    self.BtnCondition.CallBack = function() self:OnBtnConditionClick() end
end

function XUiGrideNieRCharacterFoster:Init(rootUi)
   self.RootUi = rootUi
end

function XUiGrideNieRCharacterFoster:ResetData(data, index)
    self.Index = index
    local characterData = self.RootUi.CharacterData
    local config = XNieRConfigs.GetAbilityGroupConfigById(data.ConfigId)

    local isActive = XConditionManager.CheckCondition(config.Condition)
    self.TxtName.text = config.TitleStr
    self.TxtNameAc.text = config.TitleStr
    if data.Type == XNieRConfigs.AbilityType.Skill then
        local skillId = config.SkillId
        local skillLevel = config.SkillLevel
        self:CreateSkill(skillId, skillLevel, isActive)
    elseif data.Type == XNieRConfigs.AbilityType.Fashion then
        local fashionId = config.FashionId
        self:CreateFashion(fashionId, isActive)
    elseif data.Type == XNieRConfigs.AbilityType.Weapon then
        local equipId = config.WeaponId
        local equipBreakthrough = characterData:GetNieRWeaponBreakThrough()
        local equipLevel = characterData:GetNieRWeaponLevel()
        self:CreateEquip(equipId, equipLevel, equipBreakthrough, isActive)
    elseif data.Type == XNieRConfigs.AbilityType.FourWafer then
        local equipId = config.WaferId[1]
        local equipBreakthrough = characterData:GetNieRWaferBreakThroughById(equipId)
        local equipLevel = characterData:GetNieRWaferLevel(equipId)
        self:CreateEquip(equipId, equipLevel, equipBreakthrough, isActive)
    elseif data.Type == XNieRConfigs.AbilityType.TwoWafer then
        local equipId = config.WaferId[1]
        local equipBreakthrough = characterData:GetNieRWaferBreakThroughById(equipId)
        local equipLevel = characterData:GetNieRWaferLevel(equipId)
        self:CreateEquip(equipId, equipLevel, equipBreakthrough, isActive)
    end
end

function XUiGrideNieRCharacterFoster:CreateSkill(skillId, skillLevel, isActive)
    if not isActive then
        self.GridCommon.gameObject:SetActiveEx(true)
        self.GridCommonAc.gameObject:SetActiveEx(false)
        self.LevelTitle.gameObject:SetActiveEx(true)
        self.RImgIcon.gameObject:SetActiveEx(true)
        self.ImgQuality.gameObject:SetActiveEx(false)
        self.PanelSite.gameObject:SetActiveEx(false) 
        -- self.ItemBg.gameObject:SetActiveEx(false) 
        local skillInfo = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(skillId, skillLevel)
        self.RImgIcon:SetRawImage(skillInfo.Icon)
        
        self.LevelLable.text = skillLevel
    else
        self.GridCommon.gameObject:SetActiveEx(false)
        self.GridCommonAc.gameObject:SetActiveEx(true)
        self.LevelTitleAc.gameObject:SetActiveEx(true)
        self.RImgIconAc.gameObject:SetActiveEx(true)
        self.ImgQualityAc.gameObject:SetActiveEx(false)
        self.PanelSiteAc.gameObject:SetActiveEx(false) 
        -- self.ItemBg.gameObject:SetActiveEx(false) 
        local skillInfo = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(skillId, skillLevel)
        self.RImgIconAc:SetRawImage(skillInfo.Icon)
        
        self.LevelLableAc.text = skillLevel
    end
    
end


function XUiGrideNieRCharacterFoster:CreateFashion(fashionId, isActive)
    if not isActive then
        self.GridCommon.gameObject:SetActiveEx(true)
        self.GridCommonAc.gameObject:SetActiveEx(false)
        self.LevelTitle.gameObject:SetActiveEx(false)
        self.RImgIcon.gameObject:SetActiveEx(true)
        self.ImgQuality.gameObject:SetActiveEx(false)
        self.PanelSite.gameObject:SetActiveEx(false) 
        -- self.ItemBg.gameObject:SetActiveEx(false) 
        -- 图标
        local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
        self.RImgIcon:SetRawImage(template.Icon)
    else
        self.GridCommon.gameObject:SetActiveEx(false)
        self.GridCommonAc.gameObject:SetActiveEx(true)
        self.LevelTitleAc.gameObject:SetActiveEx(false)
        self.RImgIconAc.gameObject:SetActiveEx(true)
        self.ImgQualityAc.gameObject:SetActiveEx(false)
        self.PanelSiteAc.gameObject:SetActiveEx(false) 
        -- self.ItemBg.gameObject:SetActiveEx(false) 
        -- 图标
        local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
        self.RImgIconAc:SetRawImage(template.Icon)
    end
end

function XUiGrideNieRCharacterFoster:CreateEquip(euipId, level, breakthrough, isActive)
    if not isActive then
        self.GridCommon.gameObject:SetActiveEx(true)
        self.GridCommonAc.gameObject:SetActiveEx(false)
        self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(euipId)
        self.LevelTitle.gameObject:SetActiveEx(true)
        self.RImgIcon.gameObject:SetActiveEx(true)
        self.ImgQuality.gameObject:SetActiveEx(true)
        self.ItemBg.gameObject:SetActiveEx(true) 
        
        -- 图标
        local icon = self.GoodsShowParams.Icon    
        if icon and #icon > 0 then
            self.RImgIcon:SetRawImage(icon)
        end

        -- 品质底图
        local qualityIcon = self.GoodsShowParams.QualityIcon
        if qualityIcon then
            self.ImgQuality:SetSprite(qualityIcon)
        else
            local spriteName = XArrangeConfigs.GeQualityPath(self.GoodsShowParams.Quality)
            self.ImgQuality:SetSprite(spriteName)
        end

        local showSite = self.GoodsShowParams.Site ~= XEnumConst.EQUIP.EQUIP_SITE.WEAPON
        self.PanelSite.gameObject:SetActiveEx(showSite) 
        self.TxtSite.text = "0" .. self.GoodsShowParams.Site
        self.LevelLable.text = level 
    else
        self.GridCommon.gameObject:SetActiveEx(false)
        self.GridCommonAc.gameObject:SetActiveEx(true)
        self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(euipId)
        self.LevelTitleAc.gameObject:SetActiveEx(true)
        self.RImgIconAc.gameObject:SetActiveEx(true)
        self.ImgQualityAc.gameObject:SetActiveEx(true)
        self.ItemBgAc.gameObject:SetActiveEx(true) 
        
        -- 图标
        local icon = self.GoodsShowParams.Icon    
        if icon and #icon > 0 then
            self.RImgIconAc:SetRawImage(icon)
        end

        -- 品质底图
        local qualityIcon = self.GoodsShowParams.QualityIcon
        if qualityIcon then
            self.ImgQualityAc:SetSprite(qualityIcon)
        else
            local spriteName = XArrangeConfigs.GeQualityPath(self.GoodsShowParams.Quality)
            self.ImgQualityAc:SetSprite(spriteName)
        end

        local showSite = self.GoodsShowParams.Site ~= XEnumConst.EQUIP.EQUIP_SITE.WEAPON
        self.PanelSiteAc.gameObject:SetActiveEx(showSite) 
        self.TxtSiteAc.text = "0" .. self.GoodsShowParams.Site
        self.LevelLableAc.text = level 
    end
end

function XUiGrideNieRCharacterFoster:OnBtnConditionClick()
    self.RootUi:OnDynamicGridClick(self.Index)
end

return XUiGrideNieRCharacterFoster