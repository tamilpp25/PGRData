local XPanelCharacterLevelV2P6 = XClass(XUiNode, "XPanelCharacterLevelV2P6")

function XPanelCharacterLevelV2P6:OnStart()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    self.SelectLevelItems = XUiPanelSelectLevelItems.New(self.PanelSelectLevelItems, self.Parent, self)

    self:InitButton()
end

function XPanelCharacterLevelV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnLevelUpButton, self.OnBtnLevelUpButtonClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGetMore, self.OnBtnGetMoreClick)
end

function XPanelCharacterLevelV2P6:RefreshUiShow()
    self.CharacterId = self.Parent.ParentUi.CurCharacter.Id

    -- self.LeveInfoQiehuan:PlayTimelineAnimation()
    self.PanelLeveInfo.gameObject:SetActive(true)
    self:HideSelectLevelItems()
    self:UpdatePanel()
    self:CheckMaxLevel()
end

function XPanelCharacterLevelV2P6:HideSelectLevelItems()
    if self.GameObject.activeSelf then
        self.SelectLevelItemsDisable:PlayTimelineAnimation()
    end
    self.SelectLevelItems:HidePanel()
end

function XPanelCharacterLevelV2P6:CheckMaxLevel()
    local isMaxLevel = self.CharacterAgency:IsMaxLevel(self.CharacterId)
    self.BtnLevelUpButton.gameObject:SetActive(not isMaxLevel)
    self.ImgMaxLevel.gameObject:SetActive(isMaxLevel)
end

function XPanelCharacterLevelV2P6:UpdatePanel()
    local characterId = self.CharacterId
    local character = self.CharacterAgency:GetCharacter(characterId)
    local nextLeveExp = XMVCA.XCharacter:GetNextLevelExp(characterId, character.Level)
    local isMaxLevel = self.CharacterAgency:IsMaxLevel(characterId)
    self.TxtCurLevel.text = character.Level
    self.TxtMaxLevel.text = "/" .. XMVCA.XCharacter:GetCharMaxLevel(characterId)
    local exp = isMaxLevel and nextLeveExp or character.Exp
    self.TxtExp.text = exp .. "/" .. nextLeveExp
    self.ImgFill.fillAmount = exp / nextLeveExp
    self.TxtAttack.text = FixToInt(character.Attribs[XNpcAttribType.AttackNormal])
    self.TxtLife.text = FixToInt(character.Attribs[XNpcAttribType.Life])
    self.TxtDefense.text = FixToInt(character.Attribs[XNpcAttribType.DefenseNormal])
    self.TxtCrit.text = FixToInt(character.Attribs[XNpcAttribType.Crit])
end

function XPanelCharacterLevelV2P6:OnBtnLevelUpButtonClick()
    self.SelectLevelItems:ShowPanel(self.CharacterId)
    self.SelectLevelItemsEnable:PlayTimelineAnimation()
    self.PanelLeveInfo.gameObject:SetActive(false)

    self.Parent.ParentUi:SetBackTrigger(function ()
        self.Parent.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.Train)
        self:RefreshUiShow()
    end)

    self.Parent.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.LvUseItem)
    self.Parent.ParentUi:ReturnModelToInitRotation()
end

function XPanelCharacterLevelV2P6:OnBtnGetMoreClick()
    local skipIdString = CS.XGame.ClientConfig:GetString("PanelCharacterLevelSkipIds")
    local skipIds = string.ToIntArray(skipIdString, '|')
    XLuaUiManager.Open("UiEquipStrengthenSkip", skipIds)
end

return XPanelCharacterLevelV2P6
