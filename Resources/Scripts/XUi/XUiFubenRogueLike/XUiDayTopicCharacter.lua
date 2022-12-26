local XUiDayTopicCharacter = XClass(nil, "XUiDayTopicCharacter")

function XUiDayTopicCharacter:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
end

function XUiDayTopicCharacter:SetTopicInfo(characterInfo)
    self.RImgHead:SetRawImage(XDataCenter.CharacterManager.GetCharRoundnessHeadIcon(characterInfo.Id))
    self.TxtName.text = XCharacterConfigs.GetCharacterFullNameStr(characterInfo.Id)
    if self.IconUp then
        self.IconUp.gameObject:SetActiveEx(XDataCenter.FubenRogueLikeManager.IsTeamEffectCharacter(characterInfo.Id))
    end
    if self.TxtBlood then
        self.TxtBlood.text = string.format("%s%%", tostring(characterInfo.HpLeft))
    end
    if self.Slider then
        self.Slider.value = characterInfo.HpLeft * 1.0 / 100
    end
end

function XUiDayTopicCharacter:SetTopicInfoById(charId)
    self.RImgHead:SetRawImage(XDataCenter.CharacterManager.GetCharRoundnessHeadIcon(charId))
    self.TxtName.text = XCharacterConfigs.GetCharacterFullNameStr(charId)
    if self.IconUp then
        self.IconUp.gameObject:SetActiveEx(true)
    end
end

return XUiDayTopicCharacter