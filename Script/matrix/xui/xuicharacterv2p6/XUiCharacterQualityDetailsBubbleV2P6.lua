local XUiCharacterQualityDetailsBubbleV2P6 = XLuaUiManager.Register(XLuaUi, "UiCharacterQualityDetailsBubbleV2P6")

function XUiCharacterQualityDetailsBubbleV2P6:OnAwake()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    self:InitButton()
end

function XUiCharacterQualityDetailsBubbleV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnSkill, self.OpenSkillInfo)
end

function XUiCharacterQualityDetailsBubbleV2P6:OnStart(seleStar, seleQuality, characterId)
    self.CharacterId = characterId
    local character = self.CharacterAgency:GetCharacter(characterId)

    -- 阶段x 文本
    self.TxtTitle.text = XUiHelper.GetText("CharacterQualityStar", seleStar)
    local isActive = character.Star >= seleStar
    self.TxtStateOn.gameObject:SetActiveEx(isActive)
    self.TxtStateOff.gameObject:SetActiveEx(not isActive)

    -- 属性加成文本
    local attribs = XMVCA.XCharacter:GetCharCurStarAttribsV2P6(character.Id, seleQuality, seleStar)
    for k, v in pairs(attribs or {}) do
        local value = FixToDouble(v)
        if value > 0 then
            self.TxtAttribute.text = XAttribManager.GetAttribNameByIndex(k) .. "+" .. string.format("%.2f", value)
            break
        end
    end

    -- 技能文本
    local data = XCharacterConfigs.GetCharSkillQualityApartDicByQuality(characterId, seleQuality)
    if XTool.IsTableEmpty(data) then
        self.BtnSkill.gameObject:SetActiveEx(false)
        return
    end

    local curApartIds = data[seleStar]
    if not curApartIds then
        self.BtnSkill.gameObject:SetActiveEx(false)
        return
    end

    local curApartId = curApartIds[1]
    self.SkillApartId = curApartId
    local skillName = XCharacterConfigs.GetCharSkillQualityApartName(curApartId)
    self.BtnSkill.gameObject:SetActiveEx(true)
    self.BtnSkill:SetNameByGroup(0, skillName)
end

function XUiCharacterQualityDetailsBubbleV2P6:OpenSkillInfo()
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
                XLuaUiManager.PopThenOpen("UiSkillDetailsParentV2P6", characterId, XCharacterConfigs.SkillDetailsType.Normal, pos, gridIndex)
                self.QualityToSkill = true
                return
            end
        end
    end
end

return XUiCharacterQualityDetailsBubbleV2P6
