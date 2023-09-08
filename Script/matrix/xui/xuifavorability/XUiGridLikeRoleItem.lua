local XUiGridLikeRoleItem = XClass(XUiNode, "XUiGridLikeRoleItem")

-- [刷新界面]
function XUiGridLikeRoleItem:OnRefresh(data)
    self.CharacterData = data
    self.TrustExp = self._Control:GetTrustExpById(data.Id)
    self.RImgHeadIcon:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(data.Id))
    
    --2.7是助理就显示
    if self.ImgAssist then
        self.ImgAssist.gameObject:SetActiveEx(data.IsAssistant and not data.MainAssistant)
    end
    if self.ImgAssistMain then
        self.ImgAssistMain.gameObject:SetActiveEx(data.MainAssistant)
    end
    
    local isOwn = XDataCenter.CharacterManager.IsOwnCharacter(data.Id)
    self.ImgLock.gameObject:SetActiveEx(not isOwn)
    self.RImgAIxin.gameObject:SetActiveEx(isOwn)

    if not isOwn then
        self.TxtDisplayLevel.text = ""
        self.ImgRedPoint.gameObject:SetActiveEx(false)
    else
        local trustLv = data.TrustLv or 1
        self.TxtLevel.text = trustLv
        self.TxtDisplayLevel.text = self._Control:GetWordsWithColor(trustLv, self.TrustExp[trustLv].Name)
        self.Parent:SetUiSprite(self.RImgAIxin, self._Control:GetTrustLevelIconByLevel(data.TrustLv))

        self.ImgRedPoint.gameObject:SetActiveEx(self:IsRed())
    end
    self:OnSelect()
end

-- [修改选中状态]
function XUiGridLikeRoleItem:OnSelect()
    local isSelect = self.CharacterData and self.CharacterData.Selected or false
    self.ImgSelected.gameObject:SetActiveEx(isSelect)
end

-- [是否有红点]
function XUiGridLikeRoleItem:IsRed()
    if self.CharacterData then
        local characterId = self.CharacterData.Id
        local isOwn = XMVCA.XCharacter:IsOwnCharacter(characterId)
        if not isOwn then return false end

        local rumorReddot = XMVCA.XFavorability:HasRumorsToBeUnlock(characterId)
        local dataReddot = XMVCA.XFavorability:HasDataToBeUnlock(characterId)
        local audioReddot = XMVCA.XFavorability:HasAudioToBeUnlock(characterId)
        local actionReddot = XMVCA.XFavorability:HasActionToBeUnlock(characterId)

        local check = XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FavorabilityFile)
        local documentReddot = (not check) and (rumorReddot or dataReddot or audioReddot or actionReddot)

        local storyReddot = XMVCA.XFavorability:HasStroyToBeUnlock(characterId)
        local plotReddot = (not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.FavorabilityStory)) and storyReddot

        return documentReddot or plotReddot
    end
    return false
end


return XUiGridLikeRoleItem