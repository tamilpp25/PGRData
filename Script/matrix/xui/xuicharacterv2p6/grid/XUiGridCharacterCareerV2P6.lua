local XUiGridCharacterCareer = XClass(XUiNode, "XUiGridCharacterCareer")

function XUiGridCharacterCareer:OnStart()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
end

function XUiGridCharacterCareer:Refresh(careerId, characterId)
    local curCareerId = self.CharacterAgency:GetCharacterCareer(characterId)
    self.PanelCur.gameObject:SetActiveEx(curCareerId == careerId)

    local name = XCharacterConfigs.GetCareerName(careerId)
    self.TxtName.text = name

    local des = XCharacterConfigs.GetCareerDes(careerId)
    self.TxtContent.text = des

    local icon = XCharacterConfigs.GetNpcTypeIcon(careerId)
    self.RImgIcon:SetRawImage(icon)
end

return XUiGridCharacterCareer