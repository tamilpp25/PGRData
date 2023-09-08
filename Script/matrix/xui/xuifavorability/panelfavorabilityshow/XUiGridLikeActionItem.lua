local XUiGridLikeActionItem = XClass(XUiNode, "XUiGridLikeActionItem")

local alphaSinScale = 10

function XUiGridLikeActionItem:OnRefresh(actionData)
    self.ActionData = actionData
    local characterId = self.Parent:GetCurrFavorabilityCharacter()
    local isUnlock = self._Control:IsActionUnlock(characterId, self.ActionData.config.Id)
    local canUnlock = self._Control:CanActionUnlock(characterId, self.ActionData.config.Id)

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

function XUiGridLikeActionItem:UpdatePlayStatus()
    local isPlay = self.ActionData.IsPlay or false
    self.IconPlay.gameObject:SetActiveEx(not isPlay)
    self.IconPause.gameObject:SetActiveEx(isPlay)
    self.IconAction.gameObject:SetActiveEx(isPlay)
    self.IconActionCanvasGroup.alpha = 0
end

function XUiGridLikeActionItem:HidePlayStatus()
    self.IconPlay.gameObject:SetActiveEx(false)
    self.IconPause.gameObject:SetActiveEx(false)
    self.IconAction.gameObject:SetActiveEx(false)
end

function XUiGridLikeActionItem:UpdateNormalStatus(isNormal)
    self.ActionNor.gameObject:SetActiveEx(isNormal)
    if isNormal and self.ActionData then
        local currentCharacterId = self.Parent:GetCurrFavorabilityCharacter()
        self.TxtTitle.text = self.ActionData.config.Name
        self.RawImage:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(currentCharacterId))
    end
end

function XUiGridLikeActionItem:UpdateAvailableStatus(isAvailable)
    self.ImgRedDot.gameObject:SetActiveEx(isAvailable)
end

function XUiGridLikeActionItem:HideRedDot()
    self.ImgRedDot.gameObject:SetActiveEx(false)
end

function XUiGridLikeActionItem:UpdateLockStatus(isLock)
    self.ActionLock.gameObject:SetActiveEx(isLock)
    if isLock and self.ActionData then
        self.TxtLockTitle.text = self.ActionData.config.Name
        self.TxtLock.text = XUiHelper.ConvertSpaceToLineBreak(self.ActionData.config.ConditionDescript)
    end
end

function XUiGridLikeActionItem:UpdateProgress(progress)
    progress = (progress >= 1) and 1 or progress
    self.ImgCurProgress.fillAmount = progress
end

function XUiGridLikeActionItem:UpdateActionAlpha(count)
    local alpha = math.sin(count / alphaSinScale)
    self.IconActionCanvasGroup.alpha = alpha
end

function XUiGridLikeActionItem:GetActionDataId()
    if not self.ActionData then return 0 end
    return self.ActionData.config.Id
end

return XUiGridLikeActionItem