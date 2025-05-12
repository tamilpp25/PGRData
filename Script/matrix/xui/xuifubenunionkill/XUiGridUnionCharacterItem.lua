local XUiGridUnionCharacterItem = XClass(nil, "XUiGridUnionCharacterItem")

function XUiGridUnionCharacterItem:Ctor(rootUi, ui, character, clickCallback)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ItemData = character
    -- 区分自己的和共享的角色
    self.Character = XMVCA.XCharacter:GetCharacter(self.ItemData.Id)
    self.ClickCallback = clickCallback
    self.RectTransform = ui:GetComponent("RectTransform")

    XTool.InitUiObject(self)

    self.BtnCharacter.CallBack = function() self:OnBtnCharacterClick() end

    self:SetSelect(false)
    self:SetInTeam(false)
    self:UpdateGrid()
end

function XUiGridUnionCharacterItem:OnBtnCharacterClick()
    if self.ClickCallback then
        if XMVCA.XCharacter:IsCharacterForeShow(self.ItemData.Id) then
            self.ClickCallback(self.ItemData)
        else
            XUiManager.TipMsg(CS.XTextManager.GetText("ComingSoon"), XUiManager.UiTipType.Tip)
        end
    end
end

function XUiGridUnionCharacterItem:UpdateOwnInfo(character)
    if self.TxtLevel then
        self.TxtLevel.text = character.Level
    end

    if self.RImgQuality then
        self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality))
    end

    if self.RImgHeadIcon then
        self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(character.Id))
    end

    if self.TxtTradeName then
        self.TxtTradeName.text = XMVCA.XCharacter:GetCharacterTradeName(character.Id)
    end
end

-- 废弃
function XUiGridUnionCharacterItem:UpdateUnOwnInfo()
    if self.RImgHeadIcon then
        self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(self.ItemData.Id))
    end
end

function XUiGridUnionCharacterItem:UpdateGrid(itemData)
    if itemData then
        self.ItemData = itemData
        -- 区分自己的和共享的角色
        self.Character = XMVCA.XCharacter:GetCharacter(self.ItemData.Id)
    end

    self.PanelLevel.gameObject:SetActive(true)
    self.RImgQuality.gameObject:SetActive(true)

    local characterId = self.ItemData.Id
    if self.ItemData.Flag == XFubenUnionKillConfigs.UnionKillCharType.Share then
        local shareNpcData = self.ItemData.OwnerInfo.ShareNpcData
        if self.PanelFight then
            self.TxtFight.text = math.floor(shareNpcData.Character.Ability)
        end
        self:UpdateOwnInfo(shareNpcData.Character)
        self:SetShareFlag(true)

        local playerInfo = self.ItemData.OwnerInfo
        if playerInfo then
            XUiPlayerHead.InitPortrait(playerInfo.HeadPortraitId, playerInfo.HeadFrameId, self.Head)
        end
    else
        if self.PanelFight then
            self.TxtFight.text = math.floor(self.Character.Ability)
        end
        self:UpdateOwnInfo(self.Character)
        self:SetShareFlag(false)
    end


    if self.PanelCharElement then
        local elementList = XMVCA.XCharacter:GetCharacterAllElement(characterId, true)
        for i = 1, 3 do
            local rImg = self["RImgCharElement" .. i]
            if elementList[i] then
                rImg.gameObject:SetActiveEx(true)
                local elementConfig = XMVCA.XCharacter:GetCharElement(elementList[i])
                rImg:SetRawImage(elementConfig.Icon)
            else
                rImg.gameObject:SetActiveEx(false)
            end
        end
    end

end

function XUiGridUnionCharacterItem:SetSelect(isSelect)
    if self.ImgSelected then
        self.ImgSelected.gameObject:SetActive(isSelect)
    end
end

function XUiGridUnionCharacterItem:SetInTeam(isInTeam, inTeamText)
    if self.ImgInTeam then
        if isInTeam then
            if inTeamText and self.TxtInTeam then
                self.TxtInTeam.text = inTeamText
            end
            self.ImgInTeam.gameObject:SetActiveEx(true)
        else
            self.ImgInTeam.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridUnionCharacterItem:SetIsLock(isLock)
    if self.ImgLock then
        self.ImgLock.gameObject:SetActiveEx(isLock)
    end
end

function XUiGridUnionCharacterItem:SetShareFlag(isShare)
    if self.PanelShareCard then
        self.PanelShareCard.gameObject:SetActiveEx(isShare)
    end
end

function XUiGridUnionCharacterItem:SetHasSameCard(hasSame)
    if self.TipSameCard then
        self.TipSameCard.gameObject:SetActiveEx(hasSame)
    end
end

function XUiGridUnionCharacterItem:Reset()
    self.GameObject:SetActive(false)
    self:SetSelect(false)
    self:SetInTeam(false)
end

function XUiGridUnionCharacterItem:SetPosition(x, y)
    self.RectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
end

return XUiGridUnionCharacterItem