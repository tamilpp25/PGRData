local XUiUnlockShow = XLuaUiManager.Register(XLuaUi, "UiUnlockShow")

function XUiUnlockShow:OnAwake()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag

    self.ImgUnlockShowIcon.fillAmount = 0
end

function XUiUnlockShow:OnStart(characterId, closeCb)
    self.CharacterId = characterId
    self.CloseCb = closeCb
    self:UpdateUnLockPanelInfo()
end

function XUiUnlockShow:OnDestroy()
    if self.CloseCb then self.CloseCb() end
end

function XUiUnlockShow:UpdateUnLockPanelInfo()
    local characterId = self.CharacterId

    local bigIcon = self.CharacterAgency:GetCharSmallHeadIcon(characterId)
    self.RImgFashionIcon:SetRawImage(bigIcon)

    local fullName = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
    self.TxtUnlockFashionName.text = CS.XTextManager.GetText("CharUnlockTips", fullName)

    self:PlayAnimation("AniUnlockShowBegin", function()
        self:Close()
    end)
end