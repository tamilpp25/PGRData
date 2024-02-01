local XUiGridLikeAudioItem = XClass(XUiNode, "XUiGridLikeAudioItem")
local alphaSinScale = 10

function XUiGridLikeAudioItem:OnRefresh(audioData)
    self.AudioData = audioData
    local characterId = self.Parent:GetCurrFavorabilityCharacter()
    local isUnlock = self._Control:IsVoiceUnlock(characterId, self.AudioData.config.Id)
    local canUnlock = self._Control:CanVoiceUnlock(characterId, self.AudioData.config.Id)

    self.CurrentState = XEnumConst.Favorability.InfoState.Normal
    if not isUnlock then
        if canUnlock then
            self.CurrentState = XEnumConst.Favorability.InfoState.Available
        else
            self.CurrentState = XEnumConst.Favorability.InfoState.Lock
        end
    end

    if canUnlock then
        self:UpdatePlayStatus()
    else
        self:HidePlayStatus()
    end

    self:UpdateNormalStatus(self.CurrentState == XEnumConst.Favorability.InfoState.Normal or self.CurrentState == XEnumConst.Favorability.InfoState.Available)
    self:UpdateAvailableStatus(self.CurrentState == XEnumConst.Favorability.InfoState.Available)
    self:UpdateLockStatus(self.CurrentState == XEnumConst.Favorability.InfoState.Lock)

    self.ImgCurProgress.fillAmount = 0

end

function XUiGridLikeAudioItem:HidePlayStatus()
    self.IconPlay.gameObject:SetActiveEx(false)
    self.IconPause.gameObject:SetActiveEx(false)
    self.IconMicro.gameObject:SetActiveEx(false)
end

function XUiGridLikeAudioItem:UpdatePlayStatus()
    local isPlay = self.AudioData.IsPlay or false
    self.IconPlay.gameObject:SetActiveEx(not isPlay)
    self.IconPause.gameObject:SetActiveEx(isPlay)
    self.IconMicro.gameObject:SetActiveEx(isPlay)
    self.IconMicroCanvasGroup.alpha = 0
end

function XUiGridLikeAudioItem:UpdateNormalStatus(isNormal)
    self.AudioNor.gameObject:SetActiveEx(isNormal)
    if isNormal and self.AudioData then
        local currentCharacterId = self.Parent:GetCurrFavorabilityCharacter()
        self.TxtTitle.text = self.AudioData.config.Name
        --2.7
        --self.ImgIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(currentCharacterId))

    end
end

function XUiGridLikeAudioItem:UpdateAvailableStatus(isAvailable)
    self.ImgRedDot.gameObject:SetActiveEx(isAvailable)
end

function XUiGridLikeAudioItem:HideRedDot()
    self.ImgRedDot.gameObject:SetActiveEx(false)
end

function XUiGridLikeAudioItem:UpdateLockStatus(isLock)
    self.AudioLock.gameObject:SetActiveEx(isLock)
    if isLock and self.AudioData then
        self.TxtLockTitle.text = self.AudioData.config.Name
        self.TxtLock.text = XUiHelper.ConvertSpaceToLineBreak(self.AudioData.config.ConditionDescript)
    end
end

function XUiGridLikeAudioItem:UpdateProgress(progress)
    progress = (progress >= 1) and 1 or progress
    self.ImgCurProgress.fillAmount = progress
end

function XUiGridLikeAudioItem:UpdateMicroAlpha(count)
    local alpha = math.sin(count / alphaSinScale)

    self.IconMicroCanvasGroup.alpha = alpha
end

function XUiGridLikeAudioItem:GetAudioDataId()
    if not self.AudioData then return 0 end
    return self.AudioData.config.Id
end

return XUiGridLikeAudioItem