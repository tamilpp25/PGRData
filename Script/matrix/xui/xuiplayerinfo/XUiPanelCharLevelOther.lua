XUiPanelCharLevelOther = XClass(nil, "XUiPanelCharLevelOther")

function XUiPanelCharLevelOther:Ctor(ui, parent, character, equipList,assignChapterRecords)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self.Character = character
    self.EquipList = equipList
    self.AssignChapterRecords = assignChapterRecords

    XTool.InitUiObject(self)
end

function XUiPanelCharLevelOther:ShowPanel(character)
    self.GameObject:SetActive(true)
    self.PanelLeveInfo.gameObject:SetActive(true)

    self.PanelSelectLevelItems.gameObject:SetActiveEx(false)
    self.BtnLiberation.gameObject:SetActiveEx(false)
    self.ImgMaxLevel.gameObject:SetActiveEx(false)
    self.BtnLevelUpButton.gameObject:SetActiveEx(false)

    self.LeveInfoQiehuan:PlayTimelineAnimation()
    self:UpdatePanel(character)
end

function XUiPanelCharLevelOther:HidePanel()
    self.GameObject:SetActive(false)
end

function XUiPanelCharLevelOther:UpdatePanel(character)
    local characterId = character.Id
    local nextLeveExp = XMVCA.XCharacter:GetNextLevelExp(characterId, character.Level)

    self.TxtCurLevel.text = character.Level
    self.TxtMaxLevel.text = "/" .. XMVCA.XCharacter:GetCharMaxLevel(characterId)
    self.TxtExp.text = character.Exp .. "/" .. nextLeveExp
    self.ImgFill.fillAmount = character.Exp / nextLeveExp

    character.Attribs = XMVCA.XCharacter:GetCharacterAttribsOther(character, self.EquipList, self.AssignChapterRecords)

    self.TxtAttack.text = FixToInt(character.Attribs[XNpcAttribType.AttackNormal])
    self.TxtLife.text = FixToInt(character.Attribs[XNpcAttribType.Life])
    self.TxtDefense.text = FixToInt(character.Attribs[XNpcAttribType.DefenseNormal])
    self.TxtCrit.text = FixToInt(character.Attribs[XNpcAttribType.Crit])
end