local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiCharacterPanelRoleSkill = require("XUi/XUiCharacter/XUiCharacterPanelRoleSkill")

local XUiCharacterUnOwnedInfo = XLuaUiManager.Register(XLuaUi, "UiCharacterUnOwnedInfo")

function XUiCharacterUnOwnedInfo:OnAwake()
    self:AddListener()
    
    local onBackCb = handler(self, self.OnChangePanel)
    self.RoleSkillPanel = XUiCharacterPanelRoleSkill.New(self.PanelRoleSkill, onBackCb)
end

function XUiCharacterUnOwnedInfo:OnStart(characterId)
    self.CharacterId = characterId
end

function XUiCharacterUnOwnedInfo:OnEnable()
    self:UpdateView(self.CharacterId)
end

function XUiCharacterUnOwnedInfo:PreSetCharacterId(characterId)
    self.CharacterId = characterId
end

function XUiCharacterUnOwnedInfo:UpdateView(characterId)
    self.CharacterId = characterId

    local curFragment = XDataCenter.CharacterManager.GetCharUnlockFragment(characterId)
    local bornQuality = XMVCA.XCharacter:GetCharMinQuality(characterId)
    local bornGrade = XMVCA.XCharacter:GetCharMinGrade(characterId)
    local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
    local needFragment = XCharacterConfigs.GetComposeCount(characterType, bornQuality)
    local npcId = XMVCA.XCharacter:GetCharNpcId(characterId, bornQuality)
    local npc = CS.XNpcManager.GetNpcTemplate(npcId)

    self.TxtIntroduce.text = CSXTextManagerGetText("CharacterUnowenedIntroduce"
    , XMVCA.XCharacter:GetCharacterName(characterId)
    , XMVCA.XCharacter:GetCharacterTradeName(characterId)
    , XMVCA.XCharacter:GetCharacterIntro(characterId))
    self.TxtOwnFragmentNumber.text = curFragment .. ""
    self.TxtNeedFragmentNumber.text = "/" .. needFragment
    self.ImgFill.fillAmount = curFragment / needFragment

    local isCanUnlock = curFragment >= needFragment
    self.BtnUnlock:SetDisable(not isCanUnlock)

    self.RImgBornQuality:SetRawImage(XMVCA.XCharacter:GetCharQualityIcon(bornQuality))
    self.RImgBornGradeIcon:SetRawImage(XCharacterConfigs.GetCharGradeIcon(characterId, bornGrade))
    self.RImgUnownedTypeIcon:SetRawImage(XCharacterConfigs.GetNpcTypeIcon(npc.Type))

    self.RoleSkillPanel:Refresh(characterId)
end

function XUiCharacterUnOwnedInfo:AddListener()
    self:RegisterClickEvent(self.BtnGet, self.OnBtnGetClick)
    self:RegisterClickEvent(self.BtnUnlock, self.OnBtnUnlockClick)
    self.BtnOpenSkill.CallBack = function() 
        self:OnChangePanel("QieHuan", true)
    end
end

function XUiCharacterUnOwnedInfo:OnChangePanel(animName, isOpen)
    if not animName then return end

    local begin = function ()
        self.RoleSkillPanel:Open(isOpen)
    end

    self:PlayAnimationWithMask(animName, nil, begin)
end

function XUiCharacterUnOwnedInfo:OnBtnUnlockClick()
    local characterId = self.CharacterId
    local curFragment = XDataCenter.CharacterManager.GetCharUnlockFragment(characterId)
    local bornQuality = XMVCA.XCharacter:GetCharMinQuality(characterId)
    local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
    local needFragment = XCharacterConfigs.GetComposeCount(characterType, bornQuality)
    if curFragment >= needFragment then
        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiCharacter_UnlockBegin)
        XLuaUiManager.Open("UiUnlockShow", characterId, function()
            local title = CSXTextManagerGetText("CharacterUnlockNewCharacter")
            local content = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
            XUiManager.PopupLeftTip(title, content)
            CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiCharacter_UnlockEnd)
        end)
    end
end

function XUiCharacterUnOwnedInfo:OnBtnGetClick()
    --local unionFightData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
    --if unionFightData and unionFightData.Id then
    --    return
    --end

    local useItemId = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId).ItemId
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(useItemId))
end