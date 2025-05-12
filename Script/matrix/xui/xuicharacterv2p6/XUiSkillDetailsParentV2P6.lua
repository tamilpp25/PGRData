local XUiSkillDetailsParentV2P6 = XLuaUiManager.Register(XLuaUi, "UiSkillDetailsParentV2P6")

function XUiSkillDetailsParentV2P6:OnAwake()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag

    self.SkillGridIndex = 1

    self:InitEffect()
end

function XUiSkillDetailsParentV2P6:InitEffect()
    local root = self.UiModelGo
    self.EffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.EffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.EffectHuanren.gameObject:SetActiveEx(false)
    self.EffectHuanren1.gameObject:SetActiveEx(false)
end

function XUiSkillDetailsParentV2P6:SetSkillPos(pos)
    if not self.CharacterAgency:CheckIsShowEnhanceSkill(self.CharacterId) then
        return
    end

    if self.SkillGridIndex > XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS and pos <= XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS then
        -- 从跃升/独域技能切到普通技能
        local skills = XMVCA.XCharacter:GetCharacterSkills(self.CharacterId)
        if self.ChildUiSkillDetails then
            self.ChildUiSkillDetails:RefreshDataByChangePage(self.CharacterId, skills, pos)
        end
        self:OpenChildUi("UiSkillDetails", self.CharacterId, skills, pos)
    elseif self.SkillGridIndex <= XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS and pos > XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS then
        self:OpenChildUi("UiSkillDetailsForEnhanceV2P6", self.CharacterId)
        -- 从普通技能切到跃升/独域技能
    end

    self.SkillGridIndex = pos
end

function XUiSkillDetailsParentV2P6:OpenChildUi(uiName, ...)
    if uiName == self.CurChildUiName then
        return
    end

    self:OpenOneChildUi(uiName, ...)
    self.CurChildUiName = uiName
end

function XUiSkillDetailsParentV2P6:OnStart(characterId, type, pos, gridIndex)
    self.CharacterId = characterId
    if not type then
        return
    end

    if type == XEnumConst.CHARACTER.SkillDetailsType.Normal then
        local skills = XMVCA.XCharacter:GetCharacterSkills(characterId)
        self:OpenChildUi("UiSkillDetails", self.CharacterId, skills, pos, gridIndex)
        self:SetSkillPos(pos)
    else
        self:OpenChildUi("UiSkillDetailsForEnhanceV2P6", self.CharacterId, gridIndex)
        self:SetSkillPos(XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS + 1)
    end
end

function XUiSkillDetailsParentV2P6:OnDisable()
    XMVCA.XFavorability:StopCv()
end

return XUiSkillDetailsParentV2P6
