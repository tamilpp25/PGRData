local XPanelCharacterOwnedInfoV2P6 = XClass(XUiNode, "XPanelCharacterOwnedInfoV2P6")

function XPanelCharacterOwnedInfoV2P6:OnStart()
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
    XUiHelper.RegisterClickEvent(self, self.BtnGeneralSkill1, function ()
        self:OnBtnGeneralSkillClick(1)
    end)
    XUiHelper.RegisterClickEvent(self, self.BtnGeneralSkill2, function ()
        self:OnBtnGeneralSkillClick(2)
    end)

    self.XGoInputHandler:AddDragUpListener(function ()
        self:OnDragUp()
    end)
    self.XGoInputHandler:AddDragDownListener(function ()
        self:OnDragDown()
    end)
    self.XGoInputHandler:AddMidButtonScrollUpListener(function (v)
        self:OnScrollUp()
    end)
    self.XGoInputHandler:AddMidButtonScrollDownListener(function (v)
        self:OnScrollDown()
    end)
end

function XPanelCharacterOwnedInfoV2P6:InitPanelEquip()
    local onFoldCb = function ()
        self:UpdateAbility()
        self.PanelBaseEnable:PlayTimelineAnimation()
    end
    local onUnFoldCb = function ()
        self.PanelEquipEnable:PlayTimelineAnimation()
    end
    self.PanelEquips = XMVCA.XEquip:InitPanelEquipV2P6(self.PanelEquip, self, self.Parent)
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
    local characterId = self.Parent.CurCharacter.Id
    self.RedBtnFree = XRedPointManager.AddRedPointEvent(self.BtnFree, self.OnCheckExhibitionRedPoint, self, { XRedPointConditions.Types.CONDITION_EXHIBITION_NEW }, characterId)
    self.RedBtnTrain = XRedPointManager.AddRedPointEvent(self.BtnTrain, self.OnCheckTrainRedPoint, self, { XRedPointConditions.Types.CONDITION_CHARACTER_GRADE, 
    XRedPointConditions.Types.CONDITION_CHARACTER_NEW_ENHANCESKILL_TIPS, XRedPointConditions.Types.CONDITION_CHARACTER_EVO_SKILL_TIPS_RED }, characterId)
    self.RedBtnEvolution = XRedPointManager.AddRedPointEvent(self.BtnEvolution, self.OnCheckEvolutionRedPoint, self, { XRedPointConditions.Types.CONDITION_CHARACTER_QUALITY }, characterId)
end

function XPanelCharacterOwnedInfoV2P6:RefreshUiShow()
    local character = self.Parent.CurCharacter
    local characterId = self.Parent.CurCharacter.Id
    self.CharacterId = characterId

    self.PanelEquips:UpdateCharacter(characterId)
    
    -- 机体名
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName

    -- 职业
    local career = XMVCA.XCharacter:GetCharacterCareer(characterId)
    local careerIcon = XMVCA.XCharacter:GetNpcTypeIcon(career)
    self.BtnType:SetRawImage(careerIcon)

    local showUniframe = XMVCA.XCharacter:GetIsIsomer(characterId)
    self.BtnUniframeTip.gameObject:SetActiveEx(showUniframe)

    -- 品质
    self.ImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(XMVCA.XCharacter:GetCharacterQuality(characterId)))
    -- 初始品质
    local initQuality = XMVCA.XCharacter:GetCharacterInitialQuality(characterId)
    local initColor = XMVCA.XCharacter:GetModelCharacterQualityIcon(initQuality).InitColor
    self.QualityRail.color = XUiHelper.Hexcolor2Color(initColor)

    -- 元素
    local elementList = XMVCA.XCharacter:GetCharacterAllElement(characterId, true)
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList and elementList[i] then
            rImg.gameObject:SetActiveEx(true)
            local elementConfig = XMVCA.XCharacter:GetCharElement(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.gameObject:SetActiveEx(false)
        end
    end

    -- 机制
    local generalSkillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(characterId)
    for i = 1, self.ListGeneralSkillDetail.childCount, 1 do
        local id = generalSkillIds[i]
        self["BtnGeneralSkill"..i].gameObject:SetActiveEx(id)
        if id then
            local generalSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[id]
            self["BtnGeneralSkill"..i]:SetRawImage(generalSkillConfig.Icon)
        end
    end

    -- 战斗参数
    self:UpdateAbility()

    -- 等级
    local maxLevel = XMVCA.XCharacter:GetCharMaxLevel(characterId)
    local curLevel = character.Level or 1
    self.TxtCurLv.text = curLevel
    self.TxtMaxLv.text = "/"..maxLevel
    self.ImgLvProgressBar.fillAmount = curLevel/maxLevel

    -- 解放按钮
    local growUpLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(self.CharacterId, true)
    local configs = XMVCA.XCharacter:GetModelGetCharacterLiberationIcon()[growUpLevel]
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

    -- 愚人节显示处理
    -- self:AprilFoolShowHandle()

    -- 蓝点
    XRedPointManager.Check(self.RedBtnFree, characterId)
    XRedPointManager.Check(self.RedBtnTrain, characterId)
    XRedPointManager.Check(self.RedBtnEvolution, characterId)
end

-- 2024愚人节显示处理
function XPanelCharacterOwnedInfoV2P6:AprilFoolShowHandle()
    if not XMVCA.XAprilFoolDay:IsInRandomCharacterUiModelTime() then
        return
    end

    local characterId = self.Parent.CurCharacter.Id
    local isMainChar = XMVCA.XAprilFoolDay:IsMainCharacter(characterId)
    -- 如果是Main角色
    if isMainChar then
        local aprilFoolsDayMainShowLv = CS.XGame.ClientConfig:GetInt("AprilFoolsDayMainShowLv")
        local aprilFoolsDayMainShowScore = CS.XGame.ClientConfig:GetInt("AprilFoolsDayMainShowScore")
        
        local maxLevel = XMVCA.XCharacter:GetCharMaxLevel(characterId)
        self.TxtCurLv.text = aprilFoolsDayMainShowLv
        self.TxtMaxLv.text = "/"..maxLevel
        self.ImgLvProgressBar.fillAmount = aprilFoolsDayMainShowLv/maxLevel

        self.TxtFight.text = aprilFoolsDayMainShowScore
        return
    end

    -- 如果是Sub角色
    local isSubChar = XMVCA.XAprilFoolDay:IsSubCharacter(characterId)
    if isSubChar then
        local aprilFoolsDaySubShowLv = CS.XGame.ClientConfig:GetInt("AprilFoolsDaySubShowLv")
        local aprilFoolsDaySubShowScore = CS.XGame.ClientConfig:GetInt("AprilFoolsDaySubShowScore")

        local maxLevel = XMVCA.XCharacter:GetCharMaxLevel(characterId)
        self.TxtCurLv.text = aprilFoolsDaySubShowLv
        self.TxtMaxLv.text = "/"..maxLevel
        self.ImgLvProgressBar.fillAmount = aprilFoolsDaySubShowLv/maxLevel

        self.TxtFight.text = aprilFoolsDaySubShowScore
    end
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
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.CharacterId)
end

function XPanelCharacterOwnedInfoV2P6:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.CharacterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.Element)
end

function XPanelCharacterOwnedInfoV2P6:OnBtnUniframeTipClick()
    XLuaUiManager.Open("UiCharacterUniframeBubbleV2P6")
end

function XPanelCharacterOwnedInfoV2P6:OnBtnFreeClick()
    XLuaUiManager.Open("UiExhibitionInfo", self.CharacterId)
end

function XPanelCharacterOwnedInfoV2P6:OnBtnGeneralSkillClick(index)
    local activeGeneralSkillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(self.CharacterId)
    local curId = activeGeneralSkillIds[index]
    local realIndex = XMVCA.XCharacter:GetIndexInCharacterGeneralSkillIdsById(self.CharacterId, curId)

    XLuaUiManager.Open("UiCharacterAttributeDetail", self.CharacterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.GeneralSkill, realIndex)
end

function XPanelCharacterOwnedInfoV2P6:OnBtnTrainClick()
    XMVCA.XCharacter:BuryingUiCharacterAction(self.Parent.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnTrain, self.Parent.CurCharacter.Id)
    self.Parent.ParentUi:OpenChildUi("UiCharacterPropertyV2P6")
end

function XPanelCharacterOwnedInfoV2P6:OnBtnEvolutionClick()
    XMVCA.XCharacter:BuryingUiCharacterAction(self.Parent.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnEvolution, self.Parent.CurCharacter.Id)
    self.Parent.ParentUi:OpenChildUi("UiCharacterQualitySystemV2P6")
end

function XPanelCharacterOwnedInfoV2P6:OnDragUp()
    self.PanelEquips:DoUnFold()
    XMVCA.XCharacter:BuryingUiCharacterAction(self.Parent.Name, XGlobalVar.BtnUiCharacterSystemV2P6.DragUpPanelEquip, self.Parent.CurCharacter.Id)
end

function XPanelCharacterOwnedInfoV2P6:OnDragDown()
    self.PanelEquips:DoFold()
    XMVCA.XCharacter:BuryingUiCharacterAction(self.Parent.Name, XGlobalVar.BtnUiCharacterSystemV2P6.DragDownPanelEquip, self.Parent.CurCharacter.Id)
end

function XPanelCharacterOwnedInfoV2P6:OnScrollUp()
    self.PanelEquips:DoUnFold()
    XMVCA.XCharacter:BuryingUiCharacterAction(self.Parent.Name, XGlobalVar.BtnUiCharacterSystemV2P6.ScrollUpPanelEquip, self.Parent.CurCharacter.Id)
end

function XPanelCharacterOwnedInfoV2P6:OnScrollDown()
    self.PanelEquips:DoFold()
    XMVCA.XCharacter:BuryingUiCharacterAction(self.Parent.Name, XGlobalVar.BtnUiCharacterSystemV2P6.ScrollDownPanelEquip, self.Parent.CurCharacter.Id)
end

-- 更新战斗力
function XPanelCharacterOwnedInfoV2P6:UpdateAbility()
    self.TxtFight.text = XMVCA.XCharacter:GetCharacterHaveRobotAbilityById(self.CharacterId)
end

return XPanelCharacterOwnedInfoV2P6
