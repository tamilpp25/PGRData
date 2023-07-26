XUiGridLikeActionItem = XClass(nil, "XUiGridLikeActionItem")

local alphaSinScale = 10

function XUiGridLikeActionItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridLikeActionItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridLikeActionItem:OnRefresh(actionData)
    self.ActionData = actionData
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isUnlock = XDataCenter.FavorabilityManager.IsActionUnlock(characterId, self.ActionData.Id)
    local canUnlock = XDataCenter.FavorabilityManager.CanActionUnlock(characterId, self.ActionData.Id)

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
        local currentCharacterId = self.UiRoot:GetCurrFavorabilityCharacter()
        self.TxtTitle.text = self.ActionData.Name
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
        self.TxtLockTitle.text = self.ActionData.Name
        self.TxtLock.text = XUiHelper.ConvertSpaceToLineBreak(self.ActionData.ConditionDescript)
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
    return self.ActionData.Id
end