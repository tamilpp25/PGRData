local XUiGridGeneralSkillObtain = XClass(XUiNode, "XUiGridGeneralSkillObtain")

function XUiGridGeneralSkillObtain:Refresh(generalSkillId, characterId)
    local config = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[generalSkillId]
    self.Btn:SetNameByGroup(0, config.Name)
    self.Btn:SetRawImage(config.Icon)
end

return XUiGridGeneralSkillObtain