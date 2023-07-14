local XUiPokemonSkillDetails = XLuaUiManager.Register(XLuaUi, "UiPokemonSkillDetails")

function XUiPokemonSkillDetails:OnAwake()
    self:AutoAddListener()
end

function XUiPokemonSkillDetails:OnStart(skillId)
    self.SkillId = skillId
end

function XUiPokemonSkillDetails:OnEnable()
    self:UpdateSkill()
end

function XUiPokemonSkillDetails:UpdateSkill()
    local skillId = self.SkillId

    local name = XPokemonConfigs.GetMonsterSkillName(skillId)
    self.TxtName.text = name

    local desc = XPokemonConfigs.GetMonsterSkillDescription(skillId)
    self.TxtWorldDesc.text = desc

    local icon = XPokemonConfigs.GetMonsterSkillIcon(skillId)
    self.RImgSkill:SetRawImage(icon)
end

function XUiPokemonSkillDetails:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function() self:OnClickBtnBack() end
end

function XUiPokemonSkillDetails:OnClickBtnBack()
    self:Close()
end