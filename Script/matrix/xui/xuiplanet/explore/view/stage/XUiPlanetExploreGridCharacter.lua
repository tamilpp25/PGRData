---@class XUiPlanetExploreGridCharacter
local XUiPlanetExploreGridCharacter = XClass(nil, "XUiPlanetExploreGridCharacter")

function XUiPlanetExploreGridCharacter:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self._Click = false
    self._Character = false
    self:InitUiObj()
    self:Init()
end

function XUiPlanetExploreGridCharacter:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, function()
        if self._Click then
            self._Click(self._Character)
        end
    end)
end

---@param character XPlanetCharacter
function XUiPlanetExploreGridCharacter:Update(character, isTalent)
    self._Character = character
    local imageHead = self.RImgRole or self.RImgHead
    imageHead:SetRawImage(character:GetIcon())
    imageHead.gameObject:SetActiveEx(true)

    if self.NameGroup then
        self.NameGroup:SetNameByGroup(0, character:GetName())
    end
    if self.TxtName then
        self.TxtName.text = character:GetName()
    end
    if self.PanelLock then
        self.PanelLock.gameObject:SetActiveEx(not character:IsUnlock())
    end
    if self.PanelUnlock then
        self.PanelUnlock.gameObject:SetActiveEx(character:IsUnlock())
    end
    if self.PanelCaptain or self.PanelTag then
        local team = XDataCenter.PlanetExploreManager.GetTeam()
        local isStageCaptain = character and team:IsCaptain(character)
        local isCaptain = (isTalent and character:IsTalentTeamLeader()) or (not isTalent and isStageCaptain)
        local isInTeam = (isTalent and character:IsInTalentTeam()) or (not isTalent and character:IsInTeam())
        if self.PanelCaptain then
            self.PanelCaptain.gameObject:SetActiveEx(isCaptain)
        end
        if self.PanelTag then
            self.PanelTag.gameObject:SetActiveEx(isInTeam and not isCaptain)
        end
    end
end

function XUiPlanetExploreGridCharacter:RegisterClick(func)
    self._Click = func
end

function XUiPlanetExploreGridCharacter:UpdateSelected(character, isShowSelectEffect)
    self:RefreshRedPoint()
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(character == self._Character and self._Character)
    end
    self:ShowSelectEffect(isShowSelectEffect)
end

function XUiPlanetExploreGridCharacter:RefreshRedPoint()
    if self.Red then
        local isShowRed = self._Character and XDataCenter.PlanetManager.CheckOneCharacterUnlockRed(self._Character:GetCharacterId())
        self.Red.gameObject:SetActiveEx(isShowRed)
    end
end

function XUiPlanetExploreGridCharacter:SetEmpty()
    local imageHead = self.RImgRole or self.RImgHead
    imageHead.gameObject:SetActiveEx(false)
    if self.PanelCaptain then
        self.PanelCaptain.gameObject:SetActiveEx(false)
    end
    if self.PanelTag then
        self.PanelTag.gameObject:SetActiveEx(false)
    end
    self._Character = false
end

function XUiPlanetExploreGridCharacter:ShowShinyEffect(active)
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(active)
    end
end

function XUiPlanetExploreGridCharacter:ShowSelectEffect(active)
    if self.SelectEffect then
        self.SelectEffect.gameObject:SetActiveEx(active)
    end
end

function XUiPlanetExploreGridCharacter:InitUiObj()
    if not self.Effect then
        self.Effect = XUiHelper.TryGetComponent(self.Transform, "PanelNormal/ImgBg/Effect")
    end
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
    if not self.SelectEffect then
        self.SelectEffect = XUiHelper.TryGetComponent(self.Transform, "ImgSelect/Effect")
    end
    if self.SelectEffect then
        self.SelectEffect.gameObject:SetActiveEx(false)
    end
end

return XUiPlanetExploreGridCharacter