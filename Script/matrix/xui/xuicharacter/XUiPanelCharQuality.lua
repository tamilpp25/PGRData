XUiPanelCharQuality = XClass(nil, "XUiPanelCharQuality")

local INTERAL = 100
local LOOP_NUM = 20
local CharSkillQualityNorIcon = CS.XGame.ClientConfig:GetString("CharSkillQualityNor")
local CharSkillQualitySelectIcon = CS.XGame.ClientConfig:GetString("CharSkillQualitySelect")
local CharSkillQualityOnIcon = CS.XGame.ClientConfig:GetString("CharSkillQualityOn")
local CharNormalQualityNorIcon = CS.XGame.ClientConfig:GetString("CharNormalQualityNor")
local CharNormalQualitySelectIcon = CS.XGame.ClientConfig:GetString("CharNormalQualitySelect")
local CharNormalQualityOnIcon = CS.XGame.ClientConfig:GetString("CharNormalQualityOn")

function XUiPanelCharQuality:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self:InitAutoScript()
    self:InitIcon()
    self.CharQualityUpgrade = XUiPanelQualityUpgrade.New(self.PanelQualityUpgrade, self)
    self.ChangeTime = 0.01
    self.ShowIndex = 0
    self.IsShow = true
    self.FxUiKeJinHua = CS.XGame.ClientConfig:GetString("FxUiKeJinHua")
    self.FxUiJihuo = CS.XGame.ClientConfig:GetString("FxUiJihuo")

    self.ImgClick = {
        [1] = self.ImgClick1,
        [2] = self.ImgClick2,
        [3] = self.ImgClick3,
        [4] = self.ImgClick4,
        [5] = self.ImgClick5,
        [6] = self.ImgClick6,
        [7] = self.ImgClick7,
        [8] = self.ImgClick8,
        [9] = self.ImgClick9,
        [10] = self.ImgClick10
    }

    self.TxtWaferName = {
        [1] = self.TxtWaferName1,
        [2] = self.TxtWaferName2,
        [3] = self.TxtWaferName3,
        [4] = self.TxtWaferName4,
        [5] = self.TxtWaferName5,
        [6] = self.TxtWaferName6,
        [7] = self.TxtWaferName7,
        [8] = self.TxtWaferName8,
        [9] = self.TxtWaferName9,
        [10] = self.TxtWaferName10
    }

    self.PanelHint = {
        [1] = self.PanelHint1,
        [2] = self.PanelHint2,
        [3] = self.PanelHint3,
        [4] = self.PanelHint4,
        [5] = self.PanelHint5,
        [6] = self.PanelHint6,
        [7] = self.PanelHint7,
        [8] = self.PanelHint8,
        [9] = self.PanelHint9,
        [10] = self.PanelHint10,
    }

    self.PanelSkillHint = {
        [1] = self.PanelSkillHint1,
        [2] = self.PanelSkillHint2,
        [3] = self.PanelSkillHint3,
        [4] = self.PanelSkillHint4,
        [5] = self.PanelSkillHint5,
        [6] = self.PanelSkillHint6,
        [7] = self.PanelSkillHint7,
        [8] = self.PanelSkillHint8,
        [9] = self.PanelSkillHint9,
        [10] = self.PanelSkillHint10,
    }
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelCharQuality:InitAutoScript()
    XTool.InitUiObject(self)
    self:InitUi()
    self:AutoAddListener()
end

--===========================================================================
--v1.28【角色】升阶拆分 - 初始化Ui对象
--===========================================================================
function XUiPanelCharQuality:InitUi()
    --星节点区域
    for i = 1, XEnumConst.CHARACTER.MAX_QUALITY_STAR do
        --Bg
        self["ImgLine" .. i] = self.Bg.transform:Find("ImgLine"..i):GetComponent("Image")
        --PanelWaferIcon-星节点
        self["ImgWaferColour"..i] = self.PanelWaferIcon.transform:Find("WaferIcon"..i.."/ImgWaferColour"..i):GetComponent("Image")
        self["ImgSelect"..i] = self.PanelWaferIcon.transform:Find("WaferIcon"..i.."/ImgSelect"..i):GetComponent("Image")
        self["ImgWaferon"..i] = self.PanelWaferIcon.transform:Find("WaferIcon"..i.."/ImgWaferon"..i):GetComponent("Image")
        self["TxtWaferName"..i] = self.PanelWaferIcon.transform:Find("WaferIcon"..i.."/TxtWaferName"..i):GetComponent("Text")
        self["ImgClick"..i] = self.PanelWaferIcon.transform:Find("WaferIcon"..i.."/ImgClick"..i)
        self["PanelHint"..i] = self.PanelWaferIcon.transform:Find("WaferIcon"..i.."/PanelHint"..i)
        self["PanelSkillHint"..i] = self.PanelWaferIcon.transform:Find("WaferIcon"..i.."/PanelSkillHint"..i)
    end
    --WaferCircuit-芯片中心区域
    self.RImgQuality = self.PanelRImgQuality.transform:Find("Icon/RImgQuality"):GetComponent("RawImage")            --当前阶级图标
    self.RImgQualityBg = self.PanelRImgQuality.transform:Find("Icon/RImgQuality (1)"):GetComponent("RawImage")      --当前阶级图标背景
    self.RImgQualityPhaseText = self.PanelRImgQuality.transform:Find("Txt/Text"):GetComponent("Text")               --当前阶级数文本
    self.RImgQualityTxtSkill = self.PanelRImgQuality.transform:Find("TxtSkill")
    self.RImgQualitySkillText = self.PanelRImgQuality.transform:Find("TxtSkill/Text"):GetComponent("Text")          --当前阶级属性加成文本
    self.RImgQualityTxtAttri = self.PanelRImgQuality.transform:Find("TxtWaferName")
    self.RImgQualityAttriText = self.PanelRImgQuality.transform:Find("TxtWaferName/Text"):GetComponent("Text")      --当前阶级技能加成文本
    self.RImgQualityMax = self.WaferCircuit.transform:Find("RImgQualityMax"):GetComponent("RawImage")
    --BtnAdvanced-进化按钮区域
    self.RImgQualityBefore = self.BtnAdvanced.transform:Find("RImgQualityBefore"):GetComponent("RawImage")
    self.RImgQualityAfter = self.BtnAdvanced.transform:Find("RImgQualityAfter"):GetComponent("RawImage")
    self.PanelCountMoney = self.BtnAdvanced.transform:Find("PanelCountMoney")
    self.TxtConditionCountMoney = self.BtnAdvanced.transform:Find("PanelCountMoney/TxtConditionCountMoney"):GetComponent("Text")
    self.BtnMoneyTip = self.BtnAdvanced.transform:Find("PanelCountMoney/BtnMoneyTip"):GetComponent("Button")
    --PanelCondition--激活按钮区域
    self.ImgPromoteQulityMax = self.PanelCondition.transform:Find("ImgPromoteQulityMax"):GetComponent("Image")
    self.TxtConditionCountMoneyA = self.PanelCondition.transform:Find("ImgPromoteQulityMax/TxtConditionCountMoney"):GetComponent("Text")
    self.PanelCountIten = self.PanelCondition.transform:Find("PanelCountIten")
    self.RImgIconSuipian = self.PanelCondition.transform:Find("PanelCountIten/RImgIconSuipian"):GetComponent("RawImage")
    self.TxtConditionCountItem = self.PanelCondition.transform:Find("PanelCountIten/TxtConditionCountItem"):GetComponent("Text")
    self.BtnItemTip = self.PanelCondition.transform:Find("PanelCountIten/BtnItemTip"):GetComponent("Button")
end

function XUiPanelCharQuality:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelCharQuality:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelCharQuality:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelCharQuality:AutoAddListener()
    self:RegisterClickEvent(self.BtnPreview, self.OnBtnPreviewClick)
    self:RegisterClickEvent(self.BtnAdvanced, self.OnBtnAdvancedClick)
    self:RegisterClickEvent(self.BtnMoneyTip, self.OnBtnMoneyTipClick)
    self:RegisterClickEvent(self.BtnItemTip, self.OnBtnItemTipClick)
    self:RegisterClickEvent(self.BtnActive, self.OnBtnActiveClick)
end
-- auto
function XUiPanelCharQuality:OnBtnPreviewClick()
    local characterId = self.CharacterId
    self.Parent:OpenQualityPreview(characterId)
end

function XUiPanelCharQuality:OnBtnItemTipClick()
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(XMVCA.XCharacter:GetCharacterItemId(self.CharacterId)))
end

function XUiPanelCharQuality:OnBtnMoneyTipClick()
    local character = XDataCenter.CharacterManager.GetCharacter(self.CharacterId)
    local characterType = XMVCA.XCharacter:GetCharacterType(self.CharacterId)
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(XCharacterConfigs.GetPromoteItemId(characterType, character.Quality)))
end

function XUiPanelCharQuality:OnBtnActiveClick()
    self:UpdateStarCount()
end

function XUiPanelCharQuality:OnBtnAdvancedClick()
    local characterId = self.CharacterId
    local character = XDataCenter.CharacterManager.GetCharacter(characterId)
    self.CharQualityUpgrade:OldCharUpgradeInfo(character)
    if character.Star == XEnumConst.CHARACTER.MAX_QUALITY_STAR then
        XDataCenter.CharacterManager.PromoteQuality(character, function()
            CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiCharacter_QualityUp)
            self.QualityUpgradeEnable:PlayTimelineAnimation()
            self.CharQualityUpgrade:ShowLevelInfo(characterId)
            self:InitStarAttrInfo()
            self:RefreshPanel()
        end)
    end
end

function XUiPanelCharQuality:ShowPanel(characterId)
    self.IsShow = true
    self.GameObject:SetActive(true)
    self.QualityQiehuan:PlayTimelineAnimation()
    self.CharacterId = characterId or self.CharacterId
    self.CharQualityUpgrade:HideLevelInfo()
    self:InitStarAttrInfo()
    self:RefreshPanel()
end

function XUiPanelCharQuality:HidePanel()
    self.IsShow = false
    self.GameObject:SetActive(false)
end

function XUiPanelCharQuality:InitIcon()
    self.StarIcon = {}
    self.StarAttr = {}
    self.SelectIcon = {}
    self.Line = {}
    self.StarColour = {}
    for i = 1, XEnumConst.CHARACTER.MAX_QUALITY_STAR do
        self.StarColour[i] = self["ImgWaferColour" .. i]
        self.StarIcon[i] = self["ImgWaferon" .. i]
        self.StarAttr[i] = self["TxtWaferName" .. i]
        self.SelectIcon[i] = self["ImgSelect" .. i]
        self.Line[i] = self["ImgLine" .. i]
    end
end

function XUiPanelCharQuality:ClearAttrs()
    for i = 1, XEnumConst.CHARACTER.MAX_QUALITY_STAR do
        self.StarAttr[i].text = ""
    end
end

--===========================================================================
--v1.28【角色】升阶拆分 - 刷新星节点和芯片区域
--===========================================================================
function XUiPanelCharQuality:RefreshPanel()
    local character = XDataCenter.CharacterManager.GetCharacter(self.CharacterId)
    local maxStar = XEnumConst.CHARACTER.MAX_QUALITY_STAR
    local isMaxStar = character.Star == maxStar
    
    self:UpdateWaferCircuit(character)
    self:UpdateStar(character)

    local characterType = XMVCA.XCharacter:GetCharacterType(self.CharacterId)
    if isMaxStar then
        self:OpenAdvanced(characterType, character.Quality)
    else
        self:OpenWaferCircuit(characterType, character.Quality, character.Star)
    end
    -- 刷新Tab红点
    self.Parent:OnCheckRedPoint()
end

--===========================================================================
--v1.28【角色】升阶拆分 - 更新芯片区域
--===========================================================================
function XUiPanelCharQuality:UpdateWaferCircuit(character)
    local isMaxQuality = XDataCenter.CharacterManager.IsMaxQuality(character)
    local qualityIcon = XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality)
    local isMaxStar = character.Star == XEnumConst.CHARACTER.MAX_QUALITY_STAR

    self.ImgPromoteQulityMax.gameObject:SetActive(isMaxQuality)
    self.RImgQuality.gameObject:SetActive(not isMaxQuality and not isMaxStar)
    self.RImgQualityMax.gameObject:SetActive(isMaxQuality)

    -- 阶段文本
    self.RImgQualityPhaseText.text = XUiHelper.GetText("CharacterQualityStar", character.Star + 1)
    
    if not isMaxQuality and not isMaxStar then
        -- 技能加成文本
        local skillText = XDataCenter.CharacterManager.GetCharQualitySkillName(character.Id, character.Quality, character.Star + 1)
        self.RImgQualitySkillText.text = skillText
        self.RImgQualityTxtSkill.gameObject:SetActive(not string.IsNilOrEmpty(skillText))
        -- 属性加成文本
        local attribs = XMVCA.XCharacter:GetCharStarAttribs(character.Id, character.Quality, character.Star)
        for k, v in pairs(attribs) do
            local value = FixToDouble(v)
            if value > 0 then
                self.RImgQualityTxtAttri.gameObject:SetActive(true)
                self.RImgQualityAttriText.text = XAttribManager.GetAttribNameByIndex(k) .. "+" .. string.format("%.2f", value)
                break
            end
        end
    end

    if isMaxQuality then
        self:ClearAttrs()
        self.RImgQualityMax:SetRawImage(XMVCA.XCharacter:GetCharQualityIcon(character.Quality))
        self.PanelRImgQuality.gameObject:SetActive(false)
        self.BtnAdvanced.gameObject:SetActive(false)
        self.PanelCondition.gameObject:SetActive(false)
        self.PanelWaferIcon.gameObject:SetActive(false)
        self.BtnHelp.gameObject:SetActive(false)
        return
    else
        self.RImgQuality:SetRawImage(qualityIcon)
        self.RImgQualityBg:SetRawImage(qualityIcon)
        self.PanelRImgQuality.gameObject:SetActive(true)
        self.PanelCondition.gameObject:SetActive(true)
        self.PanelWaferIcon.gameObject:SetActive(true)
        self.BtnHelp.gameObject:SetActive(true)
    end
end

--===========================================================================
--v1.28【角色】升阶拆分 - 更新星节点
--===========================================================================
function XUiPanelCharQuality:UpdateStar(character)
    -- 刷新星节点图标
    for i = 1, XEnumConst.CHARACTER.MAX_QUALITY_STAR do
        local isSkillStar = XCharacterConfigs.GetCharSkillQualityApartDicByStar(self.CharacterId, character.Quality, i)
        if #isSkillStar > 0 then
            self.StarColour[i]:SetSprite(CharSkillQualityNorIcon)
            self.SelectIcon[i]:SetSprite(CharSkillQualitySelectIcon)
            self.StarIcon[i]:SetSprite(CharSkillQualityOnIcon)
            --技能节点点击事件覆盖注册 - 跳转对应技能节点
            self:RegisterClickEvent(self.ImgClick[i], function ()
                local characterId = self.CharacterId
                self.Parent:OpenQualityPreview(characterId, i)
            end)
            self.ImgClick[i].gameObject:SetActive(true)
        else
            self.StarColour[i]:SetSprite(CharNormalQualityNorIcon)
            self.SelectIcon[i]:SetSprite(CharNormalQualitySelectIcon)
            self.StarIcon[i]:SetSprite(CharNormalQualityOnIcon)
            --技能节点点击事件隐藏
            self.ImgClick[i].gameObject:SetActive(false)
        end
    end

    -- 已经点亮星节点
    for i = 1, character.Star do
        self.StarIcon[i].gameObject:SetActive(true)
        self.Line[i].gameObject:SetActive(true)
        self.StarColour[i].gameObject:SetActive(false)
    end

    -- 未亮星节点
    for i = XEnumConst.CHARACTER.MAX_QUALITY_STAR, character.Star + 1, -1 do
        self.StarIcon[i].gameObject:SetActive(false)
        self.Line[i].gameObject:SetActive(false)
        self.StarColour[i].gameObject:SetActive(true)
    end

    -- 待点亮星节点
    self:UpdateStarAttrInfo(character.Star)

    -- 星节点特效
    for _, hint in pairs(self.PanelHint) do
        hint.gameObject:SetActiveEx(false)
    end
    for _, hint in pairs(self.PanelSkillHint) do
        if hint then 
            hint.gameObject:SetActiveEx(false) 
        end
    end
end

function XUiPanelCharQuality:UpdateStarCount()
    local character = XDataCenter.CharacterManager.GetCharacter(self.CharacterId)
    self.CharQualityUpgrade:OldCharUpgradeInfo(character)
    local nextActiveStar = character.Star + 1
    local isSkillStar = XCharacterConfigs.GetCharSkillQualityApartDicByStar(self.CharacterId, character.Quality, nextActiveStar + 1)
    XDataCenter.CharacterManager.ActivateStar(character, function()
        self.StarAttr[nextActiveStar].gameObject:SetActive(false)
        self.SelectIcon[nextActiveStar].gameObject:SetActive(false)
        self:RefreshPanel()

        if not XTool.IsNumberValid(#isSkillStar) then
            local hint = self.PanelHint[nextActiveStar + 1]
            if hint then
                hint.gameObject:SetActiveEx(true)
            end
        else
            local hint = self.PanelSkillHint[nextActiveStar + 1]
            if hint then
                hint.gameObject:SetActiveEx(true)
            end
        end

        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiCharacter_QualityFragments)
    end)
end

function XUiPanelCharQuality:UpdateStarAttrInfo(star)
    local character = XDataCenter.CharacterManager.GetCharacter(self.CharacterId)
    if star < XEnumConst.CHARACTER.MAX_QUALITY_STAR then
        self.StarAttr[star + 1].gameObject:SetActive(false)
        self.StarColour[star + 1].gameObject:SetActive(false)
        self.SelectIcon[star + 1].gameObject:SetActive(true)

        if star ~= 0 then
            self.StarAttr[star].gameObject:SetActive(false)
            self.SelectIcon[star].gameObject:SetActive(false)
        end
    end
end

--===========================================================================
--v1.28【角色】升阶拆分 - 展示芯片区域和星节点
--===========================================================================
function XUiPanelCharQuality:OpenWaferCircuit(characterType, quality, star)
    self.PanelCountIten.gameObject:SetActive(true)
    self.PanelCountMoney.gameObject:SetActive(false)
    self.BtnActive.gameObject:SetActive(true)
    self.BtnAdvanced.gameObject:SetActive(false)
    self.WaferCircuit.gameObject:SetActive(true)
    self.BtnPreview.gameObject:SetActive(true)

    self.RImgIconSuipian:SetRawImage(XDataCenter.ItemManager.GetItemIcon(XMVCA.XCharacter:GetCharacterItemId(self.CharacterId)))

    local curItem = XDataCenter.ItemManager.GetItem(XMVCA.XCharacter:GetCharacterItemId(self.CharacterId))
    local itemCount = 0
    if curItem ~= nil then
        itemCount = curItem.Count
    end
    self.TxtConditionCountItem.text = itemCount .. "/" .. XCharacterConfigs.GetStarUseCount(characterType, quality, star + 1)
end

--===========================================================================
--v1.28【角色】升阶拆分 - 展示进化按钮并隐藏星节点
--===========================================================================
function XUiPanelCharQuality:OpenAdvanced(characterType, quality)
    self.PanelCountIten.gameObject:SetActive(false)
    self.PanelCountMoney.gameObject:SetActive(true)
    self.BtnActive.gameObject:SetActive(false)
    self.BtnAdvanced.gameObject:SetActive(true)
    self.PanelCondition.gameObject:SetActive(true)
    self.WaferCircuit.gameObject:SetActive(false)
    self.PanelWaferIcon.gameObject:SetActive(false)
    self.BtnPreview.gameObject:SetActive(false)
    self.BtnHelp.gameObject:SetActive(false)

    self.RImgQualityBefore:SetRawImage(XMVCA.XCharacter:GetCharQualityIcon(quality))
    self.RImgQualityAfter:SetRawImage(XMVCA.XCharacter:GetCharQualityIcon(quality + 1))

    local itemId = XCharacterConfigs.GetPromoteItemId(characterType, quality)
    local useCoin = XCharacterConfigs.GetPromoteUseCoin(characterType, quality)
    self.TxtConditionCountMoney.text = XDataCenter.ItemManager.GetItemName(itemId) .. useCoin
end

function XUiPanelCharQuality:InitStarAttrInfo()
    local character = XDataCenter.CharacterManager.GetCharacter(self.CharacterId)
    for i = 1, #self.StarAttr do
        self.StarAttr[i].gameObject:SetActive(false)
        self.SelectIcon[i].gameObject:SetActive(false)
    end
    local star = character.Star + 1
    if self.TxtWaferName[star] then
        self.TxtWaferName[star].gameObject:SetActive(true)
    end
end