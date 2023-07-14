local XPanelCharacterUnOwnedInfoV2P6 = XClass(XUiNode, "XPanelCharacterUnOwnedInfoV2P6")
local XUiCharacterPanelRoleSkillV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiCharacterPanelRoleSkillV2P6")

function XPanelCharacterUnOwnedInfoV2P6:OnStart()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag

    self.RoleSkillPanel = XUiCharacterPanelRoleSkillV2P6.New(self.PanelRoleSkill, self)

    self:InitButton()
end

function XPanelCharacterUnOwnedInfoV2P6:RefreshUiShow()
    local characterId = self.Parent.CurCharacter.Id
    self.CharacterId = characterId
    
    -- 机体名
    local charConfig = XCharacterConfigs.GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName

    -- 职业
    local career = self.CharacterAgency:GetCharacterCareer(characterId)
    local careerIcon = XCharacterConfigs.GetNpcTypeIcon(career)
    self.BtnType:SetRawImage(careerIcon)

    local showUniframe = XCharacterConfigs.IsIsomer(characterId)
    self.BtnUniframeTip.gameObject:SetActiveEx(showUniframe)

    -- 品质
    self.ImgQuality:SetRawImage(XCharacterConfigs.GetCharacterQualityIcon(self.CharacterAgency:GetCharacterQuality(characterId)))

    -- 元素
    local detailConfig = XCharacterConfigs.GetCharDetailTemplate(characterId)
    local elementList = detailConfig.ObtainElementList
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList[i] then
            rImg.gameObject:SetActiveEx(true)
            local elementConfig = XCharacterConfigs.GetCharElement(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.gameObject:SetActiveEx(false)
        end
    end

    -- 碎片   
    local bornQuality = XCharacterConfigs.GetCharMinQuality(characterId)
    local characterType = XCharacterConfigs.GetCharacterType(characterId)
    local curFragment = self.CharacterAgency:GetCharUnlockFragment(characterId)
    local needFragment = XCharacterConfigs.GetComposeCount(characterType, bornQuality)
    self.TxtOwnFragmentNumber.text = curFragment
    self.TxtNeedFragmentNumber.text = "/"..needFragment
    self.ImgFill.fillAmount = curFragment/needFragment
    local isEnoughtFrament = curFragment >= needFragment
    self.BtnUnlock.gameObject:SetActiveEx(isEnoughtFrament)
    self.BtnGet.gameObject:SetActiveEx(not isEnoughtFrament)

    local fragmentItemId = XCharacterConfigs.GetCharacterTemplate(characterId).ItemId
    local fragmentIcon = XDataCenter.ItemManager.GetItemIcon(fragmentItemId)
    self.Icon:SetRawImage(fragmentIcon)
    -- 描述
    self.TxtFiles.text = XCharacterConfigs.GetCharacterIntro(characterId)

    -- 技能预览
    self.RoleSkillPanel:Refresh(characterId)
end

function XPanelCharacterUnOwnedInfoV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnUniframeTip, self.OnBtnUniframeTipClick)
    XUiHelper.RegisterClickEvent(self, self.BtnType, self.OnBtnCareerTipsClick)
    XUiHelper.RegisterClickEvent(self, self.BtnElementDetail, self.OnBtnElementDetailClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSkillFold, self.OnBtnSkillFoldClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSkillUnFold, self.OnBtnSkillUnFoldClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGet, self.OnBtnGetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnUnlock, self.OnBtnUnlockClick)
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnUniframeTipClick()
    XLuaUiManager.Open("UiCharacterUniframeBubbleV2P6")
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterCareerTipsV2P6", self.CharacterId)
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterElementDetail", self.CharacterId)
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnSkillFoldClick()
    self.BtnSkillFold.gameObject:SetActiveEx(false)
    self.PanelUnownedInfo.gameObject:SetActiveEx(false)
    self.PanelRoleSkill.gameObject:SetActiveEx(true)
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnSkillUnFoldClick()
    self.BtnSkillFold.gameObject:SetActiveEx(true)
    self.PanelUnownedInfo.gameObject:SetActiveEx(true)
    self.PanelRoleSkill.gameObject:SetActiveEx(false)
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnUnlockClick()
    local characterId = self.CharacterId
    XLuaUiManager.Open("UiUnlockShow", characterId, function()
        local title = CSXTextManagerGetText("CharacterUnlockNewCharacter")
        local content = XCharacterConfigs.GetCharacterFullNameStr(characterId)
        XUiManager.PopupLeftTip(title, content)
        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiCharacter_UnlockEnd)
    end)
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnGetClick()
    local unionFightData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
    if unionFightData and unionFightData.Id then
        return
    end

    local useItemId = XCharacterConfigs.GetCharacterTemplate(self.CharacterId).ItemId
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(useItemId))
end

return XPanelCharacterUnOwnedInfoV2P6
