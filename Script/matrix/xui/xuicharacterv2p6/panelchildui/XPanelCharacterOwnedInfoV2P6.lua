
local XPanelCharacterOwnedInfoV2P6 = XClass(XUiNode, "XPanelCharacterOwnedInfoV2P6")

function XPanelCharacterOwnedInfoV2P6:OnStart()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    ag = XMVCA:GetAgency(ModuleId.XEquip)
    ---@type XEquipAgency
    self.EquipAgency = ag

    self:InitButton()
    self:InitPanelEquip()
end

function XPanelCharacterOwnedInfoV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnType, self.OnBtnCareerTipsClick)
    XUiHelper.RegisterClickEvent(self, self.BtnElementDetail, self.OnBtnElementDetailClick)
    XUiHelper.RegisterClickEvent(self, self.BtnUniframeTip, self.OnBtnUniframeTipClick)
    XUiHelper.RegisterClickEvent(self, self.BtnFree, self.OnBtnFreeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTrain, self.OnBtnTrainClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEvolution, self.OnBtnEvolutionClick)
end

function XPanelCharacterOwnedInfoV2P6:InitPanelEquip()
    local onFoldCb = function ()
        self:UpdateAbility()
        self.PanelBaseEnable:PlayTimelineAnimation()
    end
    local onUnFoldCb = function ()
        self.PanelEquipEnable:PlayTimelineAnimation()
    end
    self.PanelEquips = self.EquipAgency:InitPanelEquipV2P6(self.PanelEquip, self.Parent)
    self.PanelEquips:InitData(onFoldCb, onUnFoldCb)
end

function XPanelCharacterOwnedInfoV2P6:OnDisable()
    if self.RedBtnFree then
        XRedPointManager.RemoveRedPointEvent(self.RedBtnFree)
    end
    if self.RedBtnTrain then
        XRedPointManager.RemoveRedPointEvent(self.RedBtnTrain)
    end
    if self.RedBtnEvolution then
        XRedPointManager.RemoveRedPointEvent(self.RedBtnEvolution)
    end
end

function XPanelCharacterOwnedInfoV2P6:OnEnable()
    -- 红点
    self.RedBtnFree = XRedPointManager.AddRedPointEvent(self.BtnFree, self.OnCheckExhibitionRedPoint, self, { XRedPointConditions.Types.CONDITION_EXHIBITION_NEW }, self.CharacterId)
    self.RedBtnTrain = XRedPointManager.AddRedPointEvent(self.BtnTrain, self.OnCheckTrainRedPoint, self, { XRedPointConditions.Types.CONDITION_CHARACTER_GRADE }, self.CharacterId)
    self.RedBtnEvolution = XRedPointManager.AddRedPointEvent(self.BtnEvolution, self.OnCheckEvolutionRedPoint, self, { XRedPointConditions.Types.CONDITION_CHARACTER_QUALITY }, self.CharacterId)
end

function XPanelCharacterOwnedInfoV2P6:RefreshUiShow()
    local character = self.Parent.CurCharacter
    local characterId = self.Parent.CurCharacter.Id
    self.CharacterId = characterId

    self.PanelEquips:UpdateCharacter(characterId)
    
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
    -- 初始品质
    local initQuality = self.CharacterAgency:GetCharacterInitialQuality(characterId)
    local initColor = self.CharacterAgency:GetModelCharacterQualityIcon(initQuality).InitColor
    self.QualityRail.color = XUiHelper.Hexcolor2Color(initColor)

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

    -- 战斗参数
    self:UpdateAbility()

    -- 等级
    local maxLevel= XCharacterConfigs.GetCharMaxLevel(characterId)
    local curLevel = character.Level or 1
    self.TxtCurLv.text = curLevel
    self.TxtMaxLv.text = "/"..maxLevel
    self.ImgLvProgressBar.fillAmount = curLevel/maxLevel

    -- 解放按钮
    local growUpLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(self.CharacterId, true)
    local configs = self.CharacterAgency:GetModelGetCharacterLiberationIcon()[growUpLevel]
    if not configs then
        return
    end

    local articalIcon = configs.ArticleIcon
    local color = configs.Color
    self.BtnFree:SetSprite(articalIcon)
    -- 解放图标
    local spriteImglist = self.BtnFree.ImageList
    for k, sprite in pairs(spriteImglist) do
        sprite.gameObject:SetActiveEx(articalIcon)
    end
    -- 解放图标颜色
    local colorImglist =  self.BtnFree.RawImageList
    for k, rawImg in pairs(colorImglist) do
        local finalColor = XUiHelper.Hexcolor2Color(color)
        rawImg.color = finalColor
    end

    -- 蓝点
    XRedPointManager.Check(self.RedBtnFree, characterId)
    XRedPointManager.Check(self.RedBtnTrain, characterId)
    XRedPointManager.Check(self.RedBtnEvolution, characterId)
end

function XPanelCharacterOwnedInfoV2P6:OnCheckExhibitionRedPoint(count)
    self.BtnFree:ShowReddot(count >= 0)
end

function XPanelCharacterOwnedInfoV2P6:OnCheckTrainRedPoint(count)
    self.BtnTrain:ShowReddot(count >= 0)
end

function XPanelCharacterOwnedInfoV2P6:OnCheckEvolutionRedPoint(count)
    self.BtnEvolution:ShowReddot(count >= 0)
end

function XPanelCharacterOwnedInfoV2P6:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterCareerTipsV2P6", self.CharacterId)
end

function XPanelCharacterOwnedInfoV2P6:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterElementDetail", self.CharacterId)
end

function XPanelCharacterOwnedInfoV2P6:OnBtnUniframeTipClick()
    XLuaUiManager.Open("UiCharacterUniframeBubbleV2P6")
end

function XPanelCharacterOwnedInfoV2P6:OnBtnFreeClick()
    XLuaUiManager.Open("UiExhibitionInfo", self.CharacterId)
end

function XPanelCharacterOwnedInfoV2P6:OnBtnTrainClick()
    self.Parent.ParentUi:OpenChildUi("UiCharacterPropertyV2P6")
end

function XPanelCharacterOwnedInfoV2P6:OnBtnEvolutionClick()
    self.Parent.ParentUi:OpenChildUi("UiCharacterQualitySystemV2P6")
end

-- 更新战斗力
function XPanelCharacterOwnedInfoV2P6:UpdateAbility()
    self.TxtFight.text = self.CharacterAgency:GetCharacterHaveRobotAbilityById(self.CharacterId)
end

return XPanelCharacterOwnedInfoV2P6
