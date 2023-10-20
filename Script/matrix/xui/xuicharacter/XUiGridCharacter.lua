XUiGridCharacter = XClass(nil, "XUiGridCharacter")

function XUiGridCharacter:Ctor(ui, rootUi, character, clickCallback)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Character = character
    self.ClickCallback = clickCallback
    self.RectTransform = ui:GetComponent("RectTransform")

    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag

    self:InitAutoScript()
    XTool.InitUiObject(self)

    if self.PanelStaminaBar then
        self.PanelStaminaBar.gameObject:SetActiveEx(false)
    end
    if self.PanelTeamBuff then
        self.PanelTeamBuff.gameObject:SetActiveEx(false)
    end
    self:SetSelect(false)
    self:SetInTeam(false)
    self:UpdateGrid()
end

function XUiGridCharacter:Init(rootUi)
    self.RootUi = rootUi
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridCharacter:InitAutoScript()
    self:AutoInitUi()
    self.SpecialSoundMap = {}
    self:AutoAddListener()
end

function XUiGridCharacter:AutoInitUi()
    self.BtnCharacter = XUiHelper.TryGetComponent(self.Transform, "BtnCharacter", "Button")
    self.PanelSelected = XUiHelper.TryGetComponent(self.Transform, "PanelSelected", nil)
    self.ImgSelected = XUiHelper.TryGetComponent(self.Transform, "PanelSelected/ImgSelected", "Image")
    self.PanelLevel = XUiHelper.TryGetComponent(self.Transform, "PanelLevel", nil)
    self.TxtLevel = XUiHelper.TryGetComponent(self.Transform, "PanelLevel/TxtLevel", "Text")
    self.TxtGradeLevel = XUiHelper.TryGetComponent(self.Transform, "TxtGradeLevel", "Text")
    self.PanelGrade = XUiHelper.TryGetComponent(self.Transform, "PanelGrade", nil)
    self.RImgGrade = XUiHelper.TryGetComponent(self.Transform, "PanelGrade/RImgGrade", "RawImage")
    self.RImgQuality = XUiHelper.TryGetComponent(self.Transform, "RImgQuality", "RawImage")
    self.ImgLock = XUiHelper.TryGetComponent(self.Transform, "ImgLock", "Image")
    self.ImgLimited = XUiHelper.TryGetComponent(self.Transform, "ImgLimited", "Image")
    self.PanelHead = XUiHelper.TryGetComponent(self.Transform, "PanelHead", nil)
    self.RImgHeadIcon = XUiHelper.TryGetComponent(self.Transform, "PanelHead/RImgHeadIcon", "RawImage")
    self.ImgHeadIconBg = XUiHelper.TryGetComponent(self.Transform, "PanelHead/ImgHeadIconBg", "Image")
    self.PanelFragment = XUiHelper.TryGetComponent(self.Transform, "PanelFragment", nil)
    self.TxtCurCount = XUiHelper.TryGetComponent(self.Transform, "PanelFragment/TxtCurCount", "Text")
    self.TxtNeedCount = XUiHelper.TryGetComponent(self.Transform, "PanelFragment/TxtNeedCount", "Text")
    self.ImgInTeam = XUiHelper.TryGetComponent(self.Transform, "ImgInTeam", "Image")
    self.TxtInTeam = XUiHelper.TryGetComponent(self.Transform, "ImgInTeam/TxtInTeam", "Text")
    self.ImgRedPoint = XUiHelper.TryGetComponent(self.Transform, "ImgRedPoint", "Image")
    self.ImgStaminaExpFill = XUiHelper.TryGetComponent(self.Transform, "PanelStaminaBar/ImgStaminaExpFill", "Image")
    self.PanelStaminaBar = XUiHelper.TryGetComponent(self.Transform, "PanelStaminaBar", nil)
    self.PanelFight = XUiHelper.TryGetComponent(self.Transform, "PanelFight", nil)
    self.TxtFight = XUiHelper.TryGetComponent(self.Transform, "PanelFight/TxtFight", "Text")
    self.RogueLikeUp = XUiHelper.TryGetComponent(self.Transform, "PanelRogueLikeTheme", nil)
end

function XUiGridCharacter:AutoAddListener()
    self.AutoCreateListeners = {}
    XUiHelper.RegisterClickEvent(self, self.BtnCharacter, self.OnBtnCharacterClick)
end
-- auto
function XUiGridCharacter:OnBtnCharacterClick()
    if self.ClickCallback then
        local characterId = 0
        if self.Character.IsRobot then
            local robotTemplate = XRobotManager.GetRobotTemplate(self.Character.Id)
            characterId = robotTemplate.CharacterId
        else
            characterId = self.Character.Id
        end
        if XMVCA.XCharacter:IsCharacterForeShow(characterId) then
            self.ClickCallback(self.Character)
        else
            XUiManager.TipMsg(CS.XTextManager.GetText("ComingSoon"), XUiManager.UiTipType.Tip)
        end
    end
end

function XUiGridCharacter:UpdateStamina(curStamina, maxStamina)
    if self.PanelStaminaBar then
        self.PanelStaminaBar.gameObject:SetActiveEx(true)
    end
    self.ImgStaminaExpFill.fillAmount = curStamina / maxStamina
end

function XUiGridCharacter:UpdateStaminaByPercent(percent)
    if self.PanelStaminaBar then
        self.PanelStaminaBar.gameObject:SetActiveEx(true)
    end
    self.ImgStaminaExpFill.fillAmount = percent * 0.01
end

function XUiGridCharacter:UpdateGrid(character, selectCharacterId)
    if character then
        self.Character = character
    end
    if not self.Character then return end

    if not self.Character.Id then
        return
    end

    self:SetSelect(selectCharacterId == self.Character.Id)

    self:UpdataBaseInfo()
    if self.Character.IsRobot then
        self:UpdateRobotGrid()
    else
        self:UpdateNormalGrid()
    end
end

function XUiGridCharacter:UpdataBaseInfo()
    -- 独域
    if self.PanelUniframe then
        self.PanelUniframe.gameObject:SetActiveEx(self.CharacterAgency:GetIsIsomer(self.Character.Id))
    end

    -- 初始品质
    if self.PanelInitQuality then
        self.PanelInitQuality.gameObject:SetActiveEx(true)
        local initQuality = self.CharacterAgency:GetCharacterInitialQuality(self.Character.Id)
        local icon = self.CharacterAgency:GetModelCharacterQualityIcon(initQuality).IconCharacterInit
        self.ImgInitQuality:SetSprite(icon)
    end
end

function XUiGridCharacter:UpdateRobotGrid()
    local robotId = self.Character.Id
    local robotTemplate = XRobotManager.GetRobotTemplate(robotId)
    local level = robotTemplate.CharacterLevel
    local quality = XMVCA.XCharacter:GetCharacterQualityIcon(robotTemplate.CharacterQuality)
    local head = self.CharacterAgency:GetCharSmallHeadIcon(robotTemplate.CharacterId, true)
    local grade = XCharacterConfigs.GetCharGradeIcon(robotTemplate.CharacterId, robotTemplate.CharacterGrade)
    local ability = self.Character.Ability or XRobotManager.GetRobotAbility(robotId)

    if self.PanelLevel then
        self.PanelLevel.gameObject:SetActiveEx(true)
        self.TxtLevel.text = level
    end

    if self.PanelGrade then
        self.PanelGrade.gameObject:SetActiveEx(true)
        self.RImgGrade:SetRawImage(grade)
    end

    if self.RImgQuality then
        self.RImgQuality.gameObject:SetActiveEx(true)
        self.RImgQuality:SetRawImage(quality)
    end

    if self.PanelHead then
        self.PanelHead.gameObject:SetActiveEx(true)
        self.RImgHeadIcon:SetRawImage(head)
    end

    if self.PanelFight then
        self.PanelFight.gameObject:SetActiveEx(true)
        self.TxtFight.text = math.floor(ability)
    end

    if self.PanelCharElement then
        local detailConfig = XCharacterConfigs.GetCharDetailTemplate(robotTemplate.CharacterId)
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
    end

    if self.PanelTry then
        self.PanelTry.gameObject:SetActiveEx(not self.Character.HideTryTag)
    end

    if self.PanelCurrentLocation then
        self.PanelCurrentLocation.gameObject:SetActiveEx(false)
    end

    self:CheckSameRoleTag()
end

function XUiGridCharacter:UpdateNormalGrid()
    local isOwn = self.CharacterAgency:IsOwnCharacter(self.Character.Id)
    XRedPointManager.CheckOnce(self.OnCheckCharacterRedPoint, self, { XRedPointConditions.Types.CONDITION_CHARACTER }, self.Character.Id)

    if self.PanelLevel then
        self.PanelLevel.gameObject:SetActiveEx(isOwn)
    end

    if self.PanelGrade then
        self.PanelGrade.gameObject:SetActiveEx(isOwn)
    end

    if self.RImgQuality then
        self.RImgQuality.gameObject:SetActiveEx(isOwn)
    end

    if self.ImgLock then
        self.ImgLock.gameObject:SetActiveEx(not isOwn)
    end

    if self.PanelFragment then
        self.PanelFragment.gameObject:SetActiveEx(not isOwn)
    end

    if self.PanelFight then
        self.TxtFight.text = math.floor(self.Character.Ability)
    end

    if self.PanelCharElement then
        local detailConfig = XCharacterConfigs.GetCharDetailTemplate(self.Character.Id)
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
    end

    if isOwn then
        self:UpdateOwnInfo()
    else
        self:UpdateUnOwnInfo()
    end

    if self.PanelTry then
        self.PanelTry.gameObject:SetActiveEx(false)
    end

    if self.PanelCurrentLocation then
        self.PanelCurrentLocation.gameObject:SetActiveEx(false)
    end

    self:CheckSameRoleTag()
end

function XUiGridCharacter:UpdateRecommendTag(stageId)
    if self.PanelRecommend then
        local isStageRecomend = XFubenConfigs.IsStageRecommendCharacterType(stageId, self.Character.Id)
        self.PanelRecommend.gameObject:SetActiveEx(isStageRecomend)
    end
end

function XUiGridCharacter:UpdateUnOwnInfo()
    local characterId = self.Character.Id

    if self.TxtCurCount then
        self.TxtCurCount.text = self.CharacterAgency:GetCharUnlockFragment(characterId)
    end

    local bornQuality = XMVCA.XCharacter:GetCharMinQuality(characterId)

    if self.TxtNeedCount then
        local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
        self.TxtNeedCount.text = XCharacterConfigs.GetComposeCount(characterType, bornQuality)
    end

    if self.RImgHeadIcon then
        self.RImgHeadIcon:SetRawImage(self.CharacterAgency:GetCharSmallHeadIcon(characterId))
    end
end

function XUiGridCharacter:UpdateOwnInfo()
    if self.TxtLevel then
        self.TxtLevel.text = self.Character.Level
    end

    if self.TxtGradeLevel then
        self.TxtGradeLevel.text = XCharacterConfigs.GetCharGradeName(self.Character.Id, self.Character.Grade)
    end

    if self.RImgGrade then
        self.RImgGrade:SetRawImage(XCharacterConfigs.GetCharGradeIcon(self.Character.Id, self.Character.Grade))
    end

    if self.RImgQuality then
        self.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(self.Character.Quality))
    end

    if self.RImgHeadIcon then
        self.RImgHeadIcon:SetRawImage(self.CharacterAgency:GetCharSmallHeadIcon(self.Character.Id))
    end

    if self.TxtTradeName then
        self.TxtTradeName.text = XMVCA.XCharacter:GetCharacterTradeName(self.Character.Id)
    end
end

function XUiGridCharacter:SetTeamBuff(isShow)
    if not self.PanelTeamBuff then
        return
    end
    self.PanelTeamBuff.gameObject:SetActiveEx(isShow)
end

function XUiGridCharacter:OnCheckCharacterRedPoint(count)
    if self.ImgRedPoint then
        self.ImgRedPoint.gameObject:SetActiveEx(count >= 0)
    end
end

function XUiGridCharacter:SetSelect(isSelect)
    if self.ImgSelected then
        self.ImgSelected.gameObject:SetActiveEx(isSelect)
    end
end

function XUiGridCharacter:SetInTeam(isInTeam, inTeamText, pos)
    if self.ImgInTeam then
        if isInTeam then
            if inTeamText and self.TxtInTeam then
                self.TxtInTeam.text = inTeamText
            end
            self.ImgInTeam.gameObject:SetActiveEx(true)

            if self.PanelCurrentLocation then
                if XLuaUiManager.IsUiLoad("UiRoomTeamPrefab") and pos then
                    self.Image1.color = XDataCenter.TeamManager.GetTeamMemberColor(pos)
                    self.Image2.color = XDataCenter.TeamManager.GetTeamMemberColor(pos)
                    self.PanelCurrentLocation.gameObject:SetActiveEx(true)
                end
            end
        else
            self.ImgInTeam.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridCharacter:SetIsLock(isLock)
    if self.ImgLock then
        self.ImgLock.gameObject:SetActiveEx(isLock)
    end
end

function XUiGridCharacter:SetLimited(isLimited)
    if self.ImgLimited then
        self.ImgLimited.gameObject:SetActiveEx(isLimited)
    end
end

function XUiGridCharacter:SetArrowUp(isUp)
    if self.RogueLikeUp then
        self.RogueLikeUp.gameObject:SetActiveEx(isUp)
    end
end

function XUiGridCharacter:Reset()
    self.GameObject:SetActiveEx(false)
    self:SetSelect(false)
    self:SetInTeam(false)
end

function XUiGridCharacter:SetPosition(x, y)
    self.RectTransform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
end

function XUiGridCharacter:SetSameRoleTag(isShow, showText)
    if self.PanelSameRole then
        self.PanelSameRole.gameObject:SetActiveEx(isShow)
    end
    if self.TextSameRole and isShow then
        local characterId = self.Character.Id
        local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
        local characterTypeName = characterType == XCharacterConfigs.CharacterType.Isomer and CS.XTextManager.GetText("TypeIsomer") or CS.XTextManager.GetText("TypeCharacter")
        self.TextSameRole.text = showText or CS.XTextManager.GetText("TeamGridSameRole", characterTypeName)
    end
end

function XUiGridCharacter:CheckSameRoleTag()
    -- 样式与“编队中有相同构造体”提示相同，居中横幅
    if self.Character.ShowText then
        self.PanelSameRole.gameObject:SetActiveEx(true)
        self.TextSameRole.text = self.Character.ShowText
    else
        self:SetSameRoleTag(false)
    end
end