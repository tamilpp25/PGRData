local XPanelCharacterUnOwnedInfoV2P6 = XClass(XUiNode, "XPanelCharacterUnOwnedInfoV2P6")
local XUiCharacterPanelRoleSkillV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiCharacterPanelRoleSkillV2P6")

function XPanelCharacterUnOwnedInfoV2P6:OnStart()
    self.IsFoldState = false
    self.RoleSkillPanel = XUiCharacterPanelRoleSkillV2P6.New(self.PanelRoleSkill, self)

    self:InitButton()
end

function XPanelCharacterUnOwnedInfoV2P6:RefreshUiShow()
    local characterId = self.Parent.CurCharacter.Id
    self.CharacterId = characterId
    
    -- 机体名
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName

    -- 职业
    local career = XMVCA.XCharacter:GetCharacterCareer(characterId)
    local careerIcon = XCharacterConfigs.GetNpcTypeIcon(career)
    self.BtnType:SetRawImage(careerIcon)

    local showUniframe = XCharacterConfigs.IsIsomer(characterId)
    self.BtnUniframeTip.gameObject:SetActiveEx(showUniframe)

    -- 品质
    self.ImgQuality:SetRawImage(XCharacterConfigs.GetCharacterQualityIcon(XMVCA.XCharacter:GetCharacterQuality(characterId)))

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
    local bornQuality = XMVCA.XCharacter:GetCharMinQuality(characterId)
    local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
    local curFragment = XMVCA.XCharacter:GetCharUnlockFragment(characterId)
    local needFragment = XCharacterConfigs.GetComposeCount(characterType, bornQuality)
    self.TxtOwnFragmentNumber.text = curFragment
    self.TxtNeedFragmentNumber.text = "/"..needFragment
    self.ImgFill.fillAmount = curFragment/needFragment
    local isEnoughtFrament = curFragment >= needFragment
    self.BtnUnlock.gameObject:SetActiveEx(isEnoughtFrament)
    self.BtnGet.gameObject:SetActiveEx(not isEnoughtFrament)

    local fragmentItemId = XMVCA.XCharacter:GetCharacterTemplate(characterId).ItemId
    local fragmentIcon = XDataCenter.ItemManager.GetItemIcon(fragmentItemId)
    self.Icon:SetRawImage(fragmentIcon)
    -- 描述
    self.TxtFiles.text = XMVCA.XCharacter:GetCharacterIntro(characterId)

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

    self.XGoInputHandler:AddDragUpListener(function ()
        self:OnDragUp()
    end)
    self.XGoInputHandler:AddDragDownListener(function ()
        self:OnDragDown()
    end)
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

-- 描述折叠
function XPanelCharacterUnOwnedInfoV2P6:OnBtnSkillFoldClick()
    if self.RoleSkillPanel:IsNodeShow() then
        return
    end
    
    self.Parent:PlayAnimation("PanelRoleSkillEnable")
    self.BtnSkillFold.gameObject:SetActiveEx(false)
    self.PanelUnownedInfo.gameObject:SetActiveEx(false)
    self.RoleSkillPanel:Open()
    local characterId = self.Parent.CurCharacter.Id
    self.RoleSkillPanel:Refresh(characterId)
end

-- 描述展开
function XPanelCharacterUnOwnedInfoV2P6:OnBtnSkillUnFoldClick()
    if not self.RoleSkillPanel:IsNodeShow() then
        return
    end

    self.Parent:PlayAnimation("PanelUnOwnedEnable")
    self.BtnSkillFold.gameObject:SetActiveEx(true)
    self.PanelUnownedInfo.gameObject:SetActiveEx(true)
    self.RoleSkillPanel:Close()
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnUnlockClick()
    local characterId = self.CharacterId
    if not XMVCA.XCharacter:CheckIsFragment(characterId) then
        return
    end

    XLuaUiManager.Open("UiUnlockShow", characterId, function()
        if not XMVCA.XCharacter:CheckIsFragment(characterId) then
            return
        end
        
        XMVCA.XCharacter:ExchangeCharacter(characterId, function()
            local title = CSXTextManagerGetText("CharacterUnlockNewCharacter")
            local content = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
            XUiManager.PopupLeftTip(title, content)
            CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiCharacter_UnlockEnd)
        end)
    end)
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnGetClick()
    local unionFightData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
    if unionFightData and unionFightData.Id then
        return
    end

    local useItemId = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId).ItemId
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(useItemId))
end

function XPanelCharacterUnOwnedInfoV2P6:OnDragUp()
    self:OnBtnSkillFoldClick()
end

function XPanelCharacterUnOwnedInfoV2P6:OnDragDown()
    self:OnBtnSkillUnFoldClick()
end

return XPanelCharacterUnOwnedInfoV2P6
