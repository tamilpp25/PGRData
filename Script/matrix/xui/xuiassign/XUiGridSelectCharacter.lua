local XUiGridSelectCharacter = XClass(nil, "XUiGridSelectCharacter")

function XUiGridSelectCharacter:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
end

function XUiGridSelectCharacter:Refresh(character, chapterData)
    self.Character = character 
    local characterId = character.Id
    
    self.TxtLevel.text = character.Level
    self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(XDataCenter.CharacterManager.GetCharacterQuality(characterId)))
    self.RImgHeadIcon:SetRawImage(XDataCenter.CharacterManager.GetCharSmallHeadIcon(characterId))
    self.RImgGrade:SetRawImage(XCharacterConfigs.GetCharGradeIcon(characterId, self.Character.Grade or XDataCenter.CharacterManager.GetCharacterGrade(characterId)))
    self.PanelCurrOccupy.gameObject:SetActiveEx(chapterData:GetCharacterId() == characterId)
    local chapterId = XDataCenter.FubenAssignManager.GetCharacterOccupyChapterId(characterId)
    self.PanelOtherOccupy.gameObject:SetActiveEx(XTool.IsNumberValid(chapterId) and chapterId ~= chapterData:GetId())
    self.PanelLock.gameObject:SetActiveEx(not chapterData:IsCharConditionMatch(characterId))
    self.PanelCurrOccupy:Find("Text"):GetComponent("Text").text = CS.XTextManager.GetText("AssignOccupyThisMember")
    self.PanelOtherOccupy:Find("Text"):GetComponent("Text").text = CS.XTextManager.GetText("AssignOccupyOtherMember")
    -- 独域图标
    if self.PanelUniframe then
        local isUniframe = XMVCA.XCharacter:GetIsIsomer(characterId)
        self.PanelUniframe.gameObject:SetActiveEx(isUniframe)
    end
end

function XUiGridSelectCharacter:SetSelect(value)
    if self.PanelSelected then
        self.PanelSelected.gameObject:SetActiveEx(value)
    end

    if value and self.RootUi and self.RootUi.OnGridSelected then
        self.RootUi:OnGridSelected(self.Character)
    end
end

return XUiGridSelectCharacter