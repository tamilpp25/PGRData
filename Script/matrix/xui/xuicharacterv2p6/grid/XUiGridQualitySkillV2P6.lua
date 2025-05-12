local XUiGridQualitySkillV2P6 = XClass(XUiNode, "XUiGridQualitySkillV2P6")

function XUiGridQualitySkillV2P6:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnSkillOff, self.OpenSkillInfo)
    XUiHelper.RegisterClickEvent(self, self.BtnSkillOn, self.OpenSkillInfo)
end

function XUiGridQualitySkillV2P6:Refresh(skillApartId, characterId)
    self.SkillApartId = skillApartId
    self.CharacterId = characterId
    local skillQuality = XMVCA.XCharacter:GetCharSkillQualityApartQuality(self.SkillApartId)
    local skillPhase = XMVCA.XCharacter:GetCharSkillQualityApartPhase(self.SkillApartId)
    local skillName = XMVCA.XCharacter:GetCharSkillQualityApartName(self.SkillApartId)
    local skillLevel = XMVCA.XCharacter:GetCharSkillQualityApartLevel(self.SkillApartId)
    local skillIntro = XMVCA.XCharacter:GetCharSkillQualityApartIntro(self.SkillApartId)
    local skillNameText = skillName .. "Lv" .. skillLevel
    
    self.BtnSkillOff:SetNameByGroup(0, skillNameText)
    self.BtnSkillOn:SetNameByGroup(0, skillNameText)
    
    local skillId = XMVCA.XCharacter:GetCharSkillQualityApartSkillId(skillApartId)
    local icon = XMVCA.XCharacter:GetSkillIconById(skillId)
    self.BtnSkillOff:SetRawImage(icon)
    self.BtnSkillOn:SetRawImage(icon)
    
    self.TxtLv.text = XMVCA.XCharacter:GetCharQualityDesc(skillQuality) .. (XTool.IsNumberValid(skillPhase) and skillPhase or "")
    self.TxtSkillDescribe.text = skillIntro
    self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(skillQuality))

    -- 当前节点是否激活
    local character = XMVCA.XCharacter:GetCharacter(characterId)
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
    local skillId = XMVCA.XCharacter:GetCharSkillQualityApartSkillId(self.SkillApartId)

    local skillGroupId, index = XMVCA.XCharacter:GetSkillGroupIdAndIndex(skillId)
    local skillPosToGroupIdDic = XMVCA.XCharacter:GetChracterSkillPosToGroupIdDic(characterId)
    for pos, group in ipairs(skillPosToGroupIdDic) do
        for gridIndex, id in ipairs(group) do
            if id == skillGroupId then
                XLuaUiManager.Open("UiSkillDetailsParentV2P6", characterId, XEnumConst.CHARACTER.SkillDetailsType.Normal, pos, gridIndex)
                self.QualityToSkill = true
                return
            end
        end
    end
end

return XUiGridQualitySkillV2P6