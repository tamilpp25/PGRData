local XUiGridAwarenessSelectCharacter = XClass(nil, "XUiGridAwarenessSelectCharacter")

function XUiGridAwarenessSelectCharacter:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
end

function XUiGridAwarenessSelectCharacter:Refresh(character, chapterData)
    self.Character = character 
    local characterId = character.Id
    
    self.TxtLevel.text = character.Level
    self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(XMVCA.XCharacter:GetCharacterQuality(characterId)))
    self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
    self.RImgGrade:SetRawImage(XMVCA.XCharacter:GetCharGradeIcon(characterId, self.Character.Grade or XMVCA.XCharacter:GetCharacterGrade(characterId)))
    self.PanelCurrOccupy.gameObject:SetActiveEx(chapterData:GetCharacterId() == characterId)
    local chapterId = XDataCenter.FubenAwarenessManager.GetCharacterOccupyChapterId(characterId)
    self.PanelOtherOccupy.gameObject:SetActiveEx(XTool.IsNumberValid(chapterId) and chapterId ~= chapterData:GetId())
    self.PanelLock.gameObject:SetActiveEx(not chapterData:IsCharConditionMatch(characterId))
    self.PanelCurrOccupy:Find("Text"):GetComponent("Text").text = CS.XTextManager.GetText("AwarenessOccupyThisMember")
    self.PanelOtherOccupy:Find("Text"):GetComponent("Text").text = CS.XTextManager.GetText("AwarenessOccupyOtherMember")
    -- 独域图标
    if self.PanelUniframe then
        local isUniframe = XMVCA.XCharacter:GetIsIsomer(characterId)
        self.PanelUniframe.gameObject:SetActiveEx(isUniframe)
    end
end

function XUiGridAwarenessSelectCharacter:SetSelect(value)
    if self.PanelSelected then
        self.PanelSelected.gameObject:SetActiveEx(value)
    end

    if value and self.RootUi and  self.RootUi.OnGridSelected then
        self.RootUi:OnGridSelected(self.Character)
    end
end

return XUiGridAwarenessSelectCharacter