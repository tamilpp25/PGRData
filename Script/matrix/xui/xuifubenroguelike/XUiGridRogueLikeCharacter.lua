local XUiGridRogueLikeCharacter = XClass(nil, "XUiGridRogueLikeCharacter")

function XUiGridRogueLikeCharacter:Ctor(rootUi, ui, clickCallback, templateId, templateType)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCallback = clickCallback
    self.RectTransform = ui:GetComponent("RectTransform")
    self.TemplateId = templateId
    self.TemplateType = templateType
    self.IsCharacterType = self.TemplateType == XFubenRogueLikeConfig.SelectCharacterType.Character

    if self.IsCharacterType then
        self.Template = XMVCA.XCharacter:GetCharacter(self.TemplateId)
    else
        self.Template = XRobotManager.GetRobotTemplate(self.TemplateId)
    end

    XTool.InitUiObject(self)

    self.BtnCharacter.CallBack = function() self:OnBtnCharacterClick() end
    if self.PanelStaminaBar then
        self.PanelStaminaBar.gameObject:SetActive(false)
    end
    self:SetSelect(false)
    self:SetInTeam(false)

    self:UpdateGrid(self.Template)
end


function XUiGridRogueLikeCharacter:OnBtnCharacterClick()
    if self.ClickCallback then

        if self.IsCharacterType then
            if XMVCA.XCharacter:IsCharacterForeShow(self.TemplateId) then
                self.ClickCallback(self.Template)
            else
                XUiManager.TipMsg(CS.XTextManager.GetText("ComingSoon"), XUiManager.UiTipType.Tip)
            end

        else
            self.ClickCallback(self.Template)
        end
    end
end

-- 做啥子用的？
function XUiGridRogueLikeCharacter:UpdateStamina(curStamina, maxStamina)
    if self.PanelStaminaBar then
        self.PanelStaminaBar.gameObject:SetActive(true)
    end
    self.ImgStaminaExpFill.fillAmount = curStamina / maxStamina
end

function XUiGridRogueLikeCharacter:UpdateGrid(template)
    if template then
        self.Template = template
    end

    if self.TxtLevel then
        local level = self.IsCharacterType and self.Template.Level or self.Template.CharacterLevel
        self.TxtLevel.text = level
    end

    if self.RImgGrade then
        if self.IsCharacterType then
            self.RImgGrade:SetRawImage(XMVCA.XCharacter:GetCharGradeIcon(self.TemplateId, self.Template.Grade))
        else
            self.RImgGrade:SetRawImage(XMVCA.XCharacter:GetCharGradeIcon(self.TemplateId, self.Template.CharacterGrade))
        end
    end

    if self.RImgQuality then
        local quality = self.IsCharacterType and self.Template.Quality or self.Template.CharacterQuality
        self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(quality))
    end

    if self.RImgHeadIcon then
        local characterId = self.IsCharacterType and self.Template.Id or self.Template.CharacterId
        self.RImgHeadIcon:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
    end

    if self.TxtTradeName then
        local characterId = self.IsCharacterType and self.Template.Id or self.Template.CharacterId
        self.TxtTradeName.text = XMVCA.XCharacter:GetCharacterTradeName(characterId)
    end

    if self.PanelFight then
        self.PanelFight.gameObject:SetActiveEx(self.IsCharacterType)
        local ability = self.IsCharacterType and math.floor(self.Template.Ability) or ""
        self.TxtFight.text = ability
    end

    if self.PanelCharElement then
        local characterId = self.IsCharacterType and self.Template.Id or self.Template.CharacterId
        local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(characterId)
        local elementList = detailConfig.ObtainElementList
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

function XUiGridRogueLikeCharacter:OnCheckCharacterRedPoint(count)
    if self.ImgRedPoint then
        self.ImgRedPoint.gameObject:SetActive(count >= 0)
    end
end

function XUiGridRogueLikeCharacter:SetSelect(isSelect)
    if self.ImgSelected then
        self.ImgSelected.gameObject:SetActive(isSelect)
    end
end

function XUiGridRogueLikeCharacter:SetInTeam(isInTeam, inTeamText)
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

function XUiGridRogueLikeCharacter:SetIsLock(isLock)
    if self.ImgLock then
        self.ImgLock.gameObject:SetActiveEx(isLock)
    end
end

function XUiGridRogueLikeCharacter:SetLimited(isLimited)
    if self.ImgLimited then
        self.ImgLimited.gameObject:SetActiveEx(isLimited)
    end
end

function XUiGridRogueLikeCharacter:SetArrowUp(isUp)
    if self.PanelRogueLikeTheme then
        self.PanelRogueLikeTheme.gameObject:SetActiveEx(isUp)
    end
end

function XUiGridRogueLikeCharacter:Reset()
    self.GameObject:SetActive(false)
    self:SetSelect(false)
    self:SetInTeam(false)
end

function XUiGridRogueLikeCharacter:SetPosition(x, y)
    self.RectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
end

return XUiGridRogueLikeCharacter