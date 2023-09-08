local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiGridFubenInfestorExploreMember = XClass(nil, "XUiGridFubenInfestorExploreMember")

function XUiGridFubenInfestorExploreMember:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    if self.BtnClick then
        self.BtnClick.CallBack = function() clickCb() end
    end
    self:SetSelect(false)
end

function XUiGridFubenInfestorExploreMember:Refresh(characterId, isCaptain, isFirstFight)
    if not characterId then return end

    if self.TxtName then
        self.TxtName.text = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
    end

    if self.RImgHead then
        local icon = XDataCenter.CharacterManager.GetCharBigHeadIcon(characterId)
        self.RImgHead:SetRawImage(icon)
    end

    if self.RImgHalf then
        local halfIcon = XDataCenter.CharacterManager.GetCharHalfBodyImage(characterId)
        self.RImgHalf:SetRawImage(halfIcon)
    end

    if self.RImgHeadSmall then
        local smallIcon = XDataCenter.CharacterManager.GetCharRoundnessHeadIcon(characterId)
        self.RImgHeadSmall:SetRawImage(smallIcon)
    end

    if self.ImgLeader then
        self.ImgLeader.gameObject:SetActiveEx(isCaptain)
    end

    if self.ImgFirstRole then
        self.ImgFirstRole.gameObject:SetActiveEx(isFirstFight)
    end

    local hpPercent = XDataCenter.FubenInfestorExploreManager.GetCharacterHpPrecent(characterId)
    if self.TxtHpPercent then
        self.TxtHpPercent.text = CSXTextManagerGetText("InfestorExploreCharacterHpPercent", hpPercent)
    end
    if self.TxtHp then
        self.TxtHp.text = CSXTextManagerGetText("InfestorExploreCharacterHpPercent", hpPercent)
    end
    if self.ImgHpProgress then
        self.ImgHpProgress.fillAmount = hpPercent * 0.01
    end
end

function XUiGridFubenInfestorExploreMember:SetSelect(value)
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(value)
    end
end

return XUiGridFubenInfestorExploreMember