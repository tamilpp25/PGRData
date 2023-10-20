local XUiGridQualitySkillV2P6 = XClass(XUiNode, "XUiGridQualitySkillV2P6")

function XUiGridQualitySkillV2P6:OnStart()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag

    XUiHelper.RegisterClickEvent(self, self.BtnSkillOff, self.OpenSkillInfo)
    XUiHelper.RegisterClickEvent(self, self.BtnSkillOn, self.OpenSkillInfo)
end

function XUiGridQualitySkillV2P6:Refresh(skillApartId, characterId)
    self.SkillApartId = skillApartId
    self.CharacterId = characterId
    local skillQuality = XCharacterConfigs.GetCharSkillQualityApartQuality(self.SkillApartId)
    local skillPhase = XCharacterConfigs.GetCharSkillQualityApartPhase(self.SkillApartId)
    local skillName = XCharacterConfigs.GetCharSkillQualityApartName(self.SkillApartId)
    local skillLevel = XCharacterConfigs.GetCharSkillQualityApartLevel(self.SkillApartId)
    local skillIntro = XCharacterConfigs.GetCharSkillQualityApartIntro(self.SkillApartId)
    local skillNameText = skillName .. "Lv" .. skillLevel
    
    self.BtnSkillOff:SetNameByGroup(0, skillNameText)
    self.BtnSkillOn:SetNameByGroup(0, skillNameText)
    
    local skillId = XCharacterConfigs.GetCharSkillQualityApartSkillId(skillApartId)
    local icon = self.CharacterAgency:GetSkillIconById(skillId)
    self.BtnSkillOff:SetRawImage(icon)
    self.BtnSkillOn:SetRawImage(icon)
    
    self.TxtLv.text = XCharacterConfigs.GetCharQualityDesc(skillQuality) .. (XTool.IsNumberValid(skillPhase) and skillPhase or "")
    self.TxtSkillDescribe.text = skillIntro
    self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(skillQuality))

    -- 当前节点是否激活
    local character = self.CharacterAgency:GetCharacter(characterId)
    local star = character.Star
    local charQuality = character.Quality
    local isActive = charQuality > skillQuality or (charQuality == skillQuality and star >= skillPhase)
    self.PanelQualityOff.gameObject:SetActiveEx(not isActive)
    self.PanelQualityOn.gameObject:SetActiveEx(isActive)
end

function XUiGridQualitySkillV2P6:OpenSkillInfo()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterSkill) then
        return
    end
    local characterId = self.CharacterId
    local skillId = XCharacterConfigs.GetCharSkillQualityApartSkillId(self.SkillApartId)

    local skillGroupId, index = XCharacterConfigs.GetSkillGroupIdAndIndex(skillId)
    local skillPosToGroupIdDic = XCharacterConfigs.GetChracterSkillPosToGroupIdDic(characterId)
    for pos, group in ipairs(skillPosToGroupIdDic) do
        for gridIndex, id in ipairs(group) do
            if id == skillGroupId then
                XLuaUiManager.Open("UiSkillDetailsParentV2P6", characterId, XCharacterConfigs.SkillDetailsType.Normal, pos, gridIndex)
                self.QualityToSkill = true
                return
            end
        end
    end
end

return XUiGridQualitySkillV2P6