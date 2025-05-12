local XUiRogueLikeCharItem = XClass(nil, "XUiRogueLikeCharItem")

function XUiRogueLikeCharItem:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
end

function XUiRogueLikeCharItem:UpdateCharacterInfos(charInfo)
    self.CharacterInfo = charInfo
    if not self.CharacterInfo then
        self:Reset()
        return
    end
    self.RImgRoleHead.gameObject:SetActiveEx(true)
    self.Locked.gameObject:SetActiveEx(true)
    self.RImgRoleHead:SetRawImage(XMVCA.XCharacter:GetCharRoundnessHeadIcon(self.CharacterInfo.Id))
    self.Slider.value = self.CharacterInfo.HpLeft * 1.0 / 100

    self:SetTxtBlood(string.format("%s%%", tostring(self.CharacterInfo.HpLeft)))
    self:SetIconUp(XDataCenter.FubenRogueLikeManager.IsTeamEffectCharacter(self.CharacterInfo.Id))

    if charInfo.EffectUp and self.PanelEffect then
        if self.PanelEffect.gameObject.activeSelf then
            self.PanelEffect.gameObject:SetActiveEx(false)
        end
        self.PanelEffect.gameObject:SetActiveEx(true)

        charInfo.EffectUp = false
    end
    self:CheckEffectNull()
end

function XUiRogueLikeCharItem:CheckEffectNull()
    if self.PanelEffectNull then
        local characters = XDataCenter.FubenRogueLikeManager.GetCharacterInfos()
        self.PanelEffectNull.gameObject:SetActiveEx(#characters <= 0)
    end
end

function XUiRogueLikeCharItem:StopFx()
    if self.PanelEffect then
        self.PanelEffect.gameObject:SetActiveEx(false)
    end
end

function XUiRogueLikeCharItem:Reset()
    self.RImgRoleHead.gameObject:SetActiveEx(false)
    self.Locked.gameObject:SetActiveEx(false)
    self.Slider.value = 0
    self:SetTxtBlood("")
    self:SetIconUp(false)
    self:CheckEffectNull()
end

function XUiRogueLikeCharItem:SetTxtBlood(blood)
    if self.TxtBlood then
        self.TxtBlood.text = blood
    end
end

function XUiRogueLikeCharItem:SetIconUp(isUp)
    if self.IconUp then
        self.IconUp.gameObject:SetActiveEx(isUp)
    end
end

return XUiRogueLikeCharItem