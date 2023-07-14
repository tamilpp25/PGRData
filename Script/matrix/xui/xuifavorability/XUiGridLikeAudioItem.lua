XUiGridLikeAudioItem = XClass(nil, "XUiGridLikeAudioItem")
local alphaSinScale = 10

function XUiGridLikeAudioItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridLikeAudioItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridLikeAudioItem:OnRefresh(audioData)
    self.AudioData = audioData
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isUnlock = XDataCenter.FavorabilityManager.IsVoiceUnlock(characterId, self.AudioData.Id)
    local canUnlock = XDataCenter.FavorabilityManager.CanVoiceUnlock(characterId, self.AudioData.Id)

    self.CurrentState = XFavorabilityConfigs.InfoState.Normal
    if not isUnlock then
        if canUnlock then
            self.CurrentState = XFavorabilityConfigs.InfoState.Available
        else
            self.CurrentState = XFavorabilityConfigs.InfoState.Lock
        end
    end

    if canUnlock then
        self:UpdatePlayStatus()
    else
        self:HidePlayStatus()
    end

    self:UpdateNormalStatus(self.CurrentState == XFavorabilityConfigs.InfoState.Normal or self.CurrentState == XFavorabilityConfigs.InfoState.Available)
    self:UpdateAvailableStatus(self.CurrentState == XFavorabilityConfigs.InfoState.Available)
    self:UpdateLockStatus(self.CurrentState == XFavorabilityConfigs.InfoState.Lock)

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
        local currentCharacterId = self.UiRoot:GetCurrFavorabilityCharacter()
        self.TxtTitle.text = self.AudioData.Name
        self.ImgIcon:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(currentCharacterId))

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
        self.TxtLockTitle.text = self.AudioData.Name
        self.TxtLock.text = self.AudioData.ConditionDescript
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
    return self.AudioData.Id
end

return XUiGridLikeAudioItem