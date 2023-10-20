XUiPanelCharQualityOther = XClass(nil, "XUiPanelCharQualityOther")

local CharSkillQualityNorIcon = CS.XGame.ClientConfig:GetString("CharSkillQualityNor")
local CharSkillQualitySelectIcon = CS.XGame.ClientConfig:GetString("CharSkillQualitySelect")
local CharSkillQualityOnIcon = CS.XGame.ClientConfig:GetString("CharSkillQualityOn")
local CharNormalQualityNorIcon = CS.XGame.ClientConfig:GetString("CharNormalQualityNor")
local CharNormalQualitySelectIcon = CS.XGame.ClientConfig:GetString("CharNormalQualitySelect")
local CharNormalQualityOnIcon = CS.XGame.ClientConfig:GetString("CharNormalQualityOn")

function XUiPanelCharQualityOther:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self:InitAutoScript()
    self:InitIcon()

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

function XUiPanelCharQualityOther:InitAutoScript()
    XTool.InitUiObject(self)
    self:AutoInitUi()
end

function XUiPanelCharQualityOther:AutoInitUi()
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

function XUiPanelCharQualityOther:InitIcon()
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

function XUiPanelCharQualityOther:ShowPanel(character)
    self.IsShow = true
    self.GameObject:SetActive(true)
    self.QualityQiehuan:PlayTimelineAnimation()
    self.CharacterId = character.Id or self.CharacterId
    self.Character = character
    self:RefreshPanel()
end

function XUiPanelCharQualityOther:HidePanel()
    self.IsShow = false
    self.GameObject:SetActive(false)
end

function XUiPanelCharQualityOther:RefreshPanel()
    local maxStar = XEnumConst.CHARACTER.MAX_QUALITY_STAR
    local isMaxStar = self.Character.Star == maxStar
    
    self:UpdateWaferCircuit(self.Character)
    self:UpdateStar(self.Character)
    --关闭所有交互
    self.BtnActive.gameObject:SetActive(false)
    self.BtnAdvanced.gameObject:SetActive(false)
    self.BtnPreview.gameObject:SetActive(false)
    self.BtnHelp.gameObject:SetActive(false)
    self.PanelCountIten.gameObject:SetActive(false)
    self.PanelCountMoney.gameObject:SetActive(false)
    self.WaferCircuit.gameObject:SetActive(true)
end


--===========================================================================
--v1.28【角色】升阶拆分 - 更新芯片区域
--===========================================================================
function XUiPanelCharQualityOther:UpdateWaferCircuit(character)
    local isMaxQuality = XDataCenter.CharacterManager.IsMaxQuality(character)
    local qualityIcon = XMVCA.XCharacter:GetCharacterQualityIcon(character.Quality)
    local isMaxStar = character.Star == XEnumConst.CHARACTER.MAX_QUALITY_STAR

    self.ImgPromoteQulityMax.gameObject:SetActive(isMaxQuality)
    self.RImgQuality.gameObject:SetActive(not isMaxQuality and not isMaxStar)
    self.RImgQualityMax.gameObject:SetActive(isMaxQuality)

    -- 阶段文本
    self.RImgQualityPhaseText.text = XUiHelper.GetText("CharacterQualityStar", character.Star)
    -- 不显示加成文本
    self.RImgQualityTxtSkill.gameObject:SetActive(false)
    self.RImgQualityTxtAttri.gameObject:SetActive(false)

    if isMaxQuality then
        self.RImgQualityMax:SetRawImage(XMVCA.XCharacter:GetCharQualityIcon(character.Quality))
        self.PanelRImgQuality.gameObject:SetActive(false)
        self.PanelCondition.gameObject:SetActive(false)
        self.PanelWaferIcon.gameObject:SetActive(false)
        return
    else
        self.RImgQuality:SetRawImage(qualityIcon)
        self.RImgQualityBg:SetRawImage(qualityIcon)
        self.PanelRImgQuality.gameObject:SetActive(true)
        self.PanelCondition.gameObject:SetActive(true)
        self.PanelWaferIcon.gameObject:SetActive(true)
    end
end

--===========================================================================
--v1.28【角色】升阶拆分 - 更新星节点
--===========================================================================
function XUiPanelCharQualityOther:UpdateStar(character)
    -- 刷新星节点图标
    for i = 1, XEnumConst.CHARACTER.MAX_QUALITY_STAR do
        local isSkillStar = XCharacterConfigs.GetCharSkillQualityApartDicByStar(self.CharacterId, character.Quality, i)
        if #isSkillStar > 0 then
            self.StarColour[i]:SetSprite(CharSkillQualityNorIcon)
            self.StarIcon[i]:SetSprite(CharSkillQualityOnIcon)
        else
            self.StarColour[i]:SetSprite(CharNormalQualityNorIcon)
            self.StarIcon[i]:SetSprite(CharNormalQualityOnIcon)
        end
    end

    -- 已经点亮星节点
    for i = 1, character.Star do
        self.StarIcon[i].gameObject:SetActive(true)
        self.Line[i].gameObject:SetActive(true)
        self.StarColour[i].gameObject:SetActive(false)
        self.SelectIcon[i].gameObject:SetActive(false)
    end

    -- 未亮星节点
    for i = XEnumConst.CHARACTER.MAX_QUALITY_STAR, character.Star + 1, -1 do
        self.StarIcon[i].gameObject:SetActive(false)
        self.Line[i].gameObject:SetActive(false)
        self.StarColour[i].gameObject:SetActive(true)
        self.SelectIcon[i].gameObject:SetActive(false)
    end

    -- 关闭星节点特效
    for _, hint in pairs(self.PanelHint) do
        hint.gameObject:SetActiveEx(false)
    end
    for _, hint in pairs(self.PanelSkillHint) do
        if hint then 
            hint.gameObject:SetActiveEx(false) 
        end
    end
end