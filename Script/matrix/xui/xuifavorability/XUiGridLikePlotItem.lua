XUiGridLikePlotItem = XClass(nil, "XUiGridLikePlotItem")


function XUiGridLikePlotItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridLikePlotItem:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridLikePlotItem:OnRefresh(plotData)
    self.PlotData = plotData
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isUnlock = XDataCenter.FavorabilityManager.IsStoryUnlock(characterId, plotData.Id)
    local canUnlock = XDataCenter.FavorabilityManager.CanStoryUnlock(characterId, plotData.Id)

    self.CurrentState = XFavorabilityConfigs.InfoState.Normal
    if not isUnlock then
        if canUnlock then
            self.CurrentState = XFavorabilityConfigs.InfoState.Available
        else
            self.CurrentState = XFavorabilityConfigs.InfoState.Lock
        end
    end

    self:UpdateNormalStatus(self.CurrentState == XFavorabilityConfigs.InfoState.Normal or self.CurrentState == XFavorabilityConfigs.InfoState.Available)
    self:UpdateAvailableStatus(self.CurrentState == XFavorabilityConfigs.InfoState.Available)
    self:UpdateLockStatus(self.CurrentState == XFavorabilityConfigs.InfoState.Lock)
end


function XUiGridLikePlotItem:UpdateNormalStatus(isNoraml)
    self.PlotNor.gameObject:SetActive(isNoraml)

    if isNoraml and self.PlotData then
        self.TxtSerial.text = CS.XTextManager.GetText("FavorabilityStorySectionName", self.PlotData.SectionNumber)
        self.TxtTitle.text = self.PlotData.Name
        local currentCharacterId = self.UiRoot:GetCurrFavorabilityCharacter()
        self.ImgIcon:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(currentCharacterId))
    end
end

function XUiGridLikePlotItem:UpdateAvailableStatus(isAvailable)
    -- self.PlotUnlock.gameObject:SetActive(isAvailable)
    self.ImgRedDot.gameObject:SetActive(isAvailable)
end


function XUiGridLikePlotItem:HideRedDot()
    self.ImgRedDot.gameObject:SetActive(false)
end

function XUiGridLikePlotItem:UpdateLockStatus(isLock)
    self.PlotLock.gameObject:SetActive(isLock)

    if isLock and self.PlotData then
        self.TxtLockSerial.text = CS.XTextManager.GetText("FavorabilityStorySectionName", self.PlotData.SectionNumber)
        self.TxtLockTitle.text = self.PlotData.Name
        self.TxtTLock.text = self.PlotData.ConditionDescript
    end
end

return XUiGridLikePlotItem