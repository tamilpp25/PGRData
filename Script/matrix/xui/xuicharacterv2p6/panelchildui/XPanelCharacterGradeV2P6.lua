local XPanelCharacterGradeV2P6 = XClass(XUiNode, "XPanelCharacterGradeV2P6")

local Show_Part = {
    [1] = XNpcAttribType.Life,
    [2] = XNpcAttribType.AttackNormal,
    [3] = XNpcAttribType.DefenseNormal,
    [4] = XNpcAttribType.Crit,
}

local MAX_CONDITION_NUM = 2

function XPanelCharacterGradeV2P6:InitTable()
    self.Star = { self.ImgStar1, self.ImgStar2, self.ImgStar3, self.ImgStar4 }
    self.OnStar = { self.ImgOnStar1, self.ImgOnStar2, self.ImgOnStar3, self.ImgOnStar4 }
    self.Grading = {
        Recruit = 1, --新兵
        RecruitStar = 1, --新兵最大等级
        Picked = 2, --精锐
        PickedStar = 3, --精锐最大等级
        MainForce = 3, --主力
        MainForceStar = 6, --主力最大等级
        Ace = 3, --王牌
        AceStar = 9, --王牌最大等级
        TheChosen = 4, --天选
        TheChosenStar = 13, --天选最大等级
    }

    self.GradeStarCheck = {
        [self.Grading.RecruitStar] = true,
        [self.Grading.PickedStar] = true,
        [self.Grading.MainForceStar] = true,
        [self.Grading.AceStar] = true,
        [self.Grading.TheChosenStar] = true,
    }

    self.TxtAttrib = {
        [1] = self.TxtAttrib1,
        [2] = self.TxtAttrib2,
        [3] = self.TxtAttrib3,
        [4] = self.TxtAttrib4
    }

    self.TxtNormal = {
        [1] = self.TxtNormal1A,
        [2] = self.TxtNormal2A,
        [3] = self.TxtNormal3A,
        [4] = self.TxtNormal4A
    }

    self.TxtLevel = {
        [1] = self.TxtLevel1A,
        [2] = self.TxtLevel2A,
        [3] = self.TxtLevel3A,
        [4] = self.TxtLevel4A
    }

    self.PanelCondition = {
        [1] = self.PanelCondition1,
        [2] = self.PanelCondition2,
        [3] = self.PanelCondition3,
        [4] = self.PanelCondition4,
        [5] = self.PanelCondition5,
    }

    self.TxtOffSatisfy = {
        [1] = self.TxtOffSatisfy1,
        [2] = self.TxtOffSatisfy2,
        [3] = self.TxtOffSatisfy3,
        [4] = self.TxtOffSatisfy4,
        [5] = self.TxtOffSatisfy5,
    }

    self.TxtOnSatisfy = {
        [1] = self.TxtOnSatisfy1,
        [2] = self.TxtOnSatisfy2,
        [3] = self.TxtOnSatisfy3,
        [4] = self.TxtOnSatisfy4,
        [5] = self.TxtOnSatisfy5,
    }

    self.PanelOff = {
        [1] = self.PanelOff1,
        [2] = self.PanelOff2,
        [3] = self.PanelOff3,
        [4] = self.PanelOff4,
        [5] = self.PanelOff5,
    }

    self.PanelOn = {
        [1] = self.PanelOn1,
        [2] = self.PanelOn2,
        [3] = self.PanelOn3,
        [4] = self.PanelOn4,
        [5] = self.PanelOn5,
    }
end

function XPanelCharacterGradeV2P6:OnStart()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    self:InitButton()

    self.ConditionGrids = {}

	local XUiPanelGradeUpgrade = require("XUi/XUiCharacter/XUiPanelGradeUpgrade") --XUiPanelGradeUpgrade,
    self.CharGradeUpgradePanel = XUiPanelGradeUpgrade.New(self.PanelGradeUpgrade, self, self.Parent)
    self.CharGradeUpgradePanel.GameObject:SetActive(false)
    self.CanvasGroup = self.PanelGrades:GetComponent("CanvasGroup")
    self:InitTable()
end

function XPanelCharacterGradeV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnWisdom, self.OnBtnWisdomClick)
end

function XPanelCharacterGradeV2P6:OnBtnWisdomClick()
    self:UpgradePart()
end

function XPanelCharacterGradeV2P6:RefreshUiShow()
    self.CharacterId = self.Parent.ParentUi.CurCharacter.Id

    self.GameObject:SetActive(true)
    self.IsShow = true
    self.PanelGrades.gameObject:SetActive(true)
    self.GradeQiehuan:PlayTimelineAnimation()
    self.PanelPartsItems.gameObject:SetActive(true)
    self.CharGradeUpgradePanel.GameObject:SetActive(false)
    self:UpdateGradeData()
    self.CanvasGroup.alpha = 1

    self:AddEventListener()
end

function XPanelCharacterGradeV2P6:HidePanel()
    self.IsShow = false
    self.CurPartPos = nil
    if (self.GridParts) then
        for _, grid in pairs(self.GridParts) do
            grid:SetSelect(false)
        end
    end
    self.GameObject:SetActive(false)
    self.PanelGrades.gameObject:SetActive(false)
end

-- 重新刷新级别数据
function XPanelCharacterGradeV2P6:UpdateGradeData()
    local character = self.CharacterAgency:GetCharacter(self.CharacterId)
    local isMaxGrade = self.CharacterAgency:IsMaxCharGrade(character)
    if isMaxGrade then
        self:UpdateAttribMax()
        self:UpdateGradeInfo()
    else
        self.PanelMaxLevelShow.gameObject:SetActive(false)
        -- self.PanelTitle.gameObject:SetActive(true)
        self.TextCondTitle.gameObject:SetActive(true)
        self.PanelConditions.gameObject:SetActive(true)
        self.BtnWisdom.gameObject:SetActive(true)
        self.PanelCosumeOn.gameObject:SetActive(true)
        self.PanelCosume.gameObject:SetActive(true)

        self:UpdateGradeInfo()
        self:UpdateAttribs()
        self:UpdateConditions()
        self:UpdateUseItemView()
    end
end

-- 刷新主面板信息
function XPanelCharacterGradeV2P6:UpdateGradeInfo()
    local characterId = self.CharacterId
    local character = self.CharacterAgency:GetCharacter(characterId)

    local charGradeTemplates = XMVCA.XCharacter:GetGradeTemplates(characterId, character.Grade)
    self.RImgIconTitle:SetRawImage(charGradeTemplates.GradeBigIcon)
    self:UpdateStarSprite(charGradeTemplates.NoStar, charGradeTemplates.Star)

    if character.Grade > self.Grading.TheChosenStar then
        self:UpdateStarInfo(self.Grading.TheChosen, character.Grade - self.Grading.AceStar)
        return
    end

    if character.Grade > self.Grading.AceStar then
        self:UpdateStarInfo(self.Grading.TheChosen, character.Grade - self.Grading.AceStar)
        return
    end

    if character.Grade > self.Grading.MainForceStar then
        self:UpdateStarInfo(self.Grading.Ace, character.Grade - self.Grading.MainForceStar)
        return
    end

    if character.Grade > self.Grading.PickedStar then
        self:UpdateStarInfo(self.Grading.MainForce, character.Grade - self.Grading.PickedStar)
        return
    end

    if character.Grade > self.Grading.RecruitStar then
        self:UpdateStarInfo(self.Grading.Picked, character.Grade - self.Grading.RecruitStar)
        return
    end

    if character.Grade <= self.Grading.RecruitStar then
        self:UpdateStarInfo(self.Grading.Recruit, character.Grade)
        return
    end
end

function XPanelCharacterGradeV2P6:UpdateStarSprite(starSprite, onStarSprite)
    for i = 1, #self.Star do
        self.Parent:SetUiSprite(self.Star[i], starSprite)
        self.Parent:SetUiSprite(self.OnStar[i], onStarSprite)
    end
end

-- 刷新星星界面
function XPanelCharacterGradeV2P6:UpdateStarInfo(index, onIndex)
    for i = 1, #self.Star do
        self.Star[i].gameObject:SetActive(false)
        self.OnStar[i].gameObject:SetActive(false)
    end

    if onIndex > #self.Star then
        for i = 1, #self.Star do
            self.Star[i].gameObject:SetActive(false)
            self.OnStar[i].gameObject:SetActive(true)
        end
        return
    end

    for i = 1, index do
        self.Star[i].gameObject:SetActive(true)
    end

    for i = 1, onIndex do
        self.OnStar[i].gameObject:SetActive(true)
    end
end

function XPanelCharacterGradeV2P6:UpdateAttribs()
    local characterId = self.CharacterId
    local character = self.CharacterAgency:GetCharacter(characterId)

    local curGradeConfig = XMVCA.XCharacter:GetGradeTemplates(characterId, character.Grade)
    local nextGradeConfig = XMVCA.XCharacter:GetGradeTemplates(characterId, character.Grade + 1)
    local nextAttrib = XAttribManager.GetBaseAttribs(nextGradeConfig.AttrId)
    local curAttrib = XAttribManager.GetBaseAttribs(curGradeConfig.AttrId)

    for i = 1, 4 do
        local name = XAttribManager.GetAttribNameByIndex(Show_Part[i])
        local attribType = Show_Part[i]
        self.TxtAttrib[i].text = name
        self.TxtNormal[i].text = XMath.ToMinInt(FixToDouble(curAttrib[attribType]))
        self.TxtLevel[i].text = string.format("(%s)", XMath.ToMinInt(FixToDouble(nextAttrib[attribType])))
        self.TxtLevel[i].gameObject:SetActiveEx(true)
    end
end

function XPanelCharacterGradeV2P6:UpdateAttribMax()
    local characterId = self.CharacterId
    local character = self.CharacterAgency:GetCharacter(characterId)

    -- self.PanelTitle.gameObject:SetActive(false)
    self.TextCondTitle.gameObject:SetActive(false)
    self.PanelConditions.gameObject:SetActive(false)
    self.PanelMaxLevelShow.gameObject:SetActive(true)
    self.BtnWisdom.gameObject:SetActive(false)
    self.PanelCosumeOn.gameObject:SetActive(false)
    self.PanelCosume.gameObject:SetActive(false)

    local curGradeConfig = XMVCA.XCharacter:GetGradeTemplates(characterId, character.Grade)
    local curAttrib = XAttribManager.GetBaseAttribs(curGradeConfig.AttrId)
    for i = 1, 4 do
        local name = XAttribManager.GetAttribNameByIndex(Show_Part[i])
        local attribType = Show_Part[i]
        self.TxtAttrib[i].text = name
        self.TxtNormal[i].text = XMath.ToMinInt(FixToDouble(curAttrib[attribType]))
        -- self.TxtLevel[i].text = ""
        self.TxtLevel[i].gameObject:SetActiveEx(false)
    end
end

function XPanelCharacterGradeV2P6:UpdateConditions()
    local characterId = self.CharacterId
    local character = self.CharacterAgency:GetCharacter(characterId)

    local gradeTemplate = XMVCA.XCharacter:GetGradeTemplates(characterId, character.Grade)
    local conditions = gradeTemplate.ConditionId

    if not conditions then
        return
    end

    for i = 1, MAX_CONDITION_NUM do
        if conditions[i] then
            local config = XConditionManager.GetConditionTemplate(conditions[i])
            if config then
                self.PanelCondition[i].gameObject:SetActive(true)
                self.TxtOnSatisfy[i].text = config.Desc
                self.TxtOffSatisfy[i].text = config.Desc

                local isCompleted = XConditionManager.CheckCondition(conditions[i], characterId)
                self.PanelOn[i].gameObject:SetActive(isCompleted)
                self.PanelOff[i].gameObject:SetActive(not isCompleted)
            end
        else
            self.PanelCondition[i].gameObject:SetActive(false)
        end
    end
end

--统一接口，供人物属性界面-刷新
function XPanelCharacterGradeV2P6:Refresh()
    self:UpdateUseItemView()
end

function XPanelCharacterGradeV2P6:UpdateUseItemView()
    local characterId = self.CharacterId
    if not characterId then return end
    local character = self.CharacterAgency:GetCharacter(characterId)

    local gradeConfig = XMVCA.XCharacter:GetGradeTemplates(characterId, character.Grade)
    local itemCode = gradeConfig.UseItemKey
    if not XTool.IsNumberValid(itemCode) then return end

    local icon = XDataCenter.ItemManager.GetItemIcon(itemCode)
    self.PanelCosume:FindTransform("Icon"):GetComponent("RawImage"):SetRawImage(icon)
    self.PanelCosumeOn:FindTransform("Icon"):GetComponent("RawImage"):SetRawImage(icon)

    local itemNum = gradeConfig.UseItemCount
    self.TxtCosume.text = itemNum
    self.TxtCosumeOn.text = itemNum

    local isCoinEnough = self.CharacterAgency:IsUseItemEnough(itemCode, itemNum)
    self.PanelCosumeOn.gameObject:SetActive(isCoinEnough)
    self.PanelCosume.gameObject:SetActive(not isCoinEnough)
end

function XPanelCharacterGradeV2P6:CloseBtn()
    self.BtnWisdom.gameObject:SetActive(false)
end

function XPanelCharacterGradeV2P6:UpgradePart()
    local characterId = self.CharacterId
    local character = self.CharacterAgency:GetCharacter(characterId)

    local isMaxGrade = self.CharacterAgency:IsMaxCharGrade(character)
    if isMaxGrade then
        return
    end

    local gradeConfig = XMVCA.XCharacter:GetGradeTemplates(characterId, character.Grade)
    local conditions = gradeConfig.ConditionId

    for i = 1, MAX_CONDITION_NUM do
        if conditions[i] then
            local isConditionEnough = XConditionManager.CheckCondition(conditions[i], characterId)
            if (not isConditionEnough) then
                XUiManager.TipText("CharacterPromotePartItemLimit")
                return
            end
        end
    end

    if not XDataCenter.ItemManager.DoNotEnoughBuyAsset(gradeConfig.UseItemKey,
    gradeConfig.UseItemCount,
    1,
    function()
        self:UpgradePart()
    end,
    "CharacterPromotePartCoinLimit") then
        return
    end

    self.CharGradeUpgradePanel:OldCharUpgradeInfo(character)
    self.CharacterAgency:PromoteGrade(characterId, function(oldGrade)
        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiCharacter_GradeUp)

        self:UpdateGradeData()
        self.GradeUpgradeEnable:PlayTimelineAnimation()
        if self.GradeStarCheck[oldGrade] then
            self.CharGradeUpgradePanel:ShowLevelInfo(characterId)
        else
            XUiManager.PopupLeftTip(CS.XTextManager.GetText("CharacterUpgradeComplete"))
        end

        self.Parent:RefreshTabBtns()
    end)
end

function XPanelCharacterGradeV2P6:AddEventListener()
    if not self.CharacterId then
        return
    end
    self:RemoveEventListener()

    local character = self.CharacterAgency:GetCharacter(self.CharacterId)
    local gradeConfig = XMVCA.XCharacter:GetGradeTemplates(self.CharacterId, character.Grade)
    local itemCode = gradeConfig.UseItemKey
    if not XTool.IsNumberValid(itemCode) then
        return
    end
    XDataCenter.ItemManager.AddCountUpdateListener(itemCode, function()
        self:UpdateUseItemView()
    end, self.TxtCosumeOn)
end

function XPanelCharacterGradeV2P6:RemoveEventListener()
    XDataCenter.ItemManager.RemoveCountUpdateListener(self.TxtCosumeOn)
end

function XPanelCharacterGradeV2P6:OnDestroy()
    self:RemoveEventListener()
end

return XPanelCharacterGradeV2P6
