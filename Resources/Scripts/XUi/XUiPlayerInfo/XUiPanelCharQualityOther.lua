XUiPanelCharQualityOther = XClass(nil, "XUiPanelCharQualityOther")

function XUiPanelCharQualityOther:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self:InitAutoScript()
    self:InitIcon()
end

function XUiPanelCharQualityOther:InitAutoScript()
    self:AutoInitUi()
    XTool.InitUiObject(self)
end

function XUiPanelCharQualityOther:AutoInitUi()
    self.PanelQualityUpgrade = self.Transform:Find("PanelQualityUpgrade")
    self.PanelWaferIcon = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon")

    self.ImgLine1 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/Bg/ImgLine1"):GetComponent("Image")
    self.ImgLine2 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/Bg/ImgLine2"):GetComponent("Image")
    self.ImgLine3 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/Bg/ImgLine3"):GetComponent("Image")
    self.ImgLine4 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/Bg/ImgLine4"):GetComponent("Image")
    self.ImgLine5 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/Bg/ImgLine5"):GetComponent("Image")
    self.ImgLine6 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/Bg/ImgLine6"):GetComponent("Image")
    self.ImgLine7 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/Bg/ImgLine7"):GetComponent("Image")
    self.ImgLine8 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/Bg/ImgLine8"):GetComponent("Image")
    self.ImgLine9 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/Bg/ImgLine9"):GetComponent("Image")
    self.ImgLine10 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/Bg/ImgLine10"):GetComponent("Image")

    self.ImgWaferColour1 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon1/ImgWaferColour1"):GetComponent("Image")
    self.ImgSelect1 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon1/ImgSelect1"):GetComponent("Image")
    self.ImgWaferon1 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon1/ImgWaferon1"):GetComponent("Image")
    self.TxtWaferName1 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon1/TxtWaferName1"):GetComponent("Text")
    self.PanelHint1 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon1/PanelHint1")

    self.ImgWaferColour2 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon2/ImgWaferColour2"):GetComponent("Image")
    self.ImgSelect2 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon2/ImgSelect2"):GetComponent("Image")
    self.ImgWaferon2 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon2/ImgWaferon2"):GetComponent("Image")
    self.TxtWaferName2 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon2/TxtWaferName2"):GetComponent("Text")
    self.PanelHint2 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon2/PanelHint2")

    self.ImgWaferColour3 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon3/ImgWaferColour3"):GetComponent("Image")
    self.ImgSelect3 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon3/ImgSelect3"):GetComponent("Image")
    self.ImgWaferon3 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon3/ImgWaferon3"):GetComponent("Image")
    self.TxtWaferName3 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon3/TxtWaferName3"):GetComponent("Text")
    self.PanelHint3 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon3/PanelHint3")

    self.ImgWaferColour4 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon4/ImgWaferColour4"):GetComponent("Image")
    self.ImgSelect4 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon4/ImgSelect4"):GetComponent("Image")
    self.ImgWaferon4 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon4/ImgWaferon4"):GetComponent("Image")
    self.TxtWaferName4 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon4/TxtWaferName4"):GetComponent("Text")
    self.PanelHint4 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon4/PanelHint4")

    self.ImgWaferColour5 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon5/ImgWaferColour5"):GetComponent("Image")
    self.ImgSelect5 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon5/ImgSelect5"):GetComponent("Image")
    self.ImgWaferon5 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon5/ImgWaferon5"):GetComponent("Image")
    self.TxtWaferName5 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon5/TxtWaferName5"):GetComponent("Text")
    self.PanelHint5 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon5/PanelHint5")

    self.ImgWaferColour6 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon6/ImgWaferColour6"):GetComponent("Image")
    self.ImgSelect6 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon6/ImgSelect6"):GetComponent("Image")
    self.ImgWaferon6 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon6/ImgWaferon6"):GetComponent("Image")
    self.TxtWaferName6 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon6/TxtWaferName6"):GetComponent("Text")
    self.PanelHint6 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon6/PanelHint6")

    self.ImgWaferColour7 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon7/ImgWaferColour7"):GetComponent("Image")
    self.ImgSelect7 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon7/ImgSelect7"):GetComponent("Image")
    self.ImgWaferon7 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon7/ImgWaferon7"):GetComponent("Image")
    self.TxtWaferName7 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon7/TxtWaferName7"):GetComponent("Text")
    self.PanelHint7 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon7/PanelHint7")

    self.ImgWaferColour8 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon8/ImgWaferColour8"):GetComponent("Image")
    self.ImgSelect8 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon8/ImgSelect8"):GetComponent("Image")
    self.ImgWaferon8 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon8/ImgWaferon8"):GetComponent("Image")
    self.TxtWaferName8 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon8/TxtWaferName8"):GetComponent("Text")
    self.PanelHint8 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon8/PanelHint8")

    self.ImgWaferColour9 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon9/ImgWaferColour9"):GetComponent("Image")
    self.ImgSelect9 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon9/ImgSelect9"):GetComponent("Image")
    self.ImgWaferon9 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon9/ImgWaferon9"):GetComponent("Image")
    self.TxtWaferName9 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon9/TxtWaferName9"):GetComponent("Text")
    self.PanelHint9 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon9/PanelHint9")

    self.ImgWaferColour10 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon10/ImgWaferColour10"):GetComponent("Image")
    self.ImgSelect10 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon10/ImgSelect10"):GetComponent("Image")
    self.ImgWaferon10 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon10/ImgWaferon10"):GetComponent("Image")
    self.TxtWaferName10 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon10/TxtWaferName10"):GetComponent("Text")
    self.PanelHint10 = self.Transform:Find("PanelQuality/PanelInfo/PanelItems/PanelWaferIcon/WaferIcon10/PanelHint10")

    self.RImgQuality = self.Transform:Find("PanelQuality/PanelInfo/WaferCircuit/RImgQuality"):GetComponent("RawImage")
    self.RImgQualityMax = self.Transform:Find("PanelQuality/PanelInfo/WaferCircuit/RImgQualityMax"):GetComponent("RawImage")
    self.BtnAdvanced = self.Transform:Find("PanelQuality/PanelInfo/BtnAdvanced"):GetComponent("Button")
    self.PanelCondition = self.Transform:Find("PanelQuality/PanelCondition")
end

function XUiPanelCharQualityOther:InitIcon()
    self.StarIcon = {}
    self.StarAttr = {}
    self.SelectIcon = {}
    self.Line = {}
    self.StarColour = {}
    self.PanelHint = {}
    for i = 1, XCharacterConfigs.MAX_QUALITY_STAR do
        self.StarIcon[i] = self["ImgWaferon" .. i]
        self.StarAttr[i] = self["TxtWaferName" .. i]
        self.SelectIcon[i] = self["ImgSelect" .. i]
        self.Line[i] = self["ImgLine" .. i]
        self.StarColour[i] = self["ImgWaferColour" .. i]
        self.PanelHint[i] = self["PanelHint"..i]
    end
end

function XUiPanelCharQualityOther:ShowPanel(character)
    self.GameObject:SetActive(true)
    self.CharacterId = character.Id
    self.QualityQiehuan:PlayTimelineAnimation()

    for _, hint in pairs(self.PanelHint) do
        hint.gameObject:SetActiveEx(false)
    end

    for i = 1, #self.StarAttr do
        self.StarAttr[i].gameObject:SetActive(false)
        self.SelectIcon[i].gameObject:SetActive(false)
    end

    self:UpdatePanel(character)
end

function XUiPanelCharQualityOther:HidePanel()
    self.GameObject:SetActive(false)
end

function XUiPanelCharQualityOther:UpdatePanel(character)
    local maxStar = XCharacterConfigs.MAX_QUALITY_STAR
    local isMaxQuality = XDataCenter.CharacterManager.IsMaxQuality(character)
    local qualityIcon = XCharacterConfigs.GetCharQualityIcon(character.Quality)

    self.RImgQuality.gameObject:SetActive(not isMaxQuality)
    self.RImgQualityMax.gameObject:SetActive(isMaxQuality)

    for i = 1, XCharacterConfigs.MAX_QUALITY_STAR do
        self.StarAttr[i].gameObject:SetActive(false)
        self.SelectIcon[i].gameObject:SetActive(false)
    end

    self.BtnAdvanced.gameObject:SetActive(false)
    self.PanelCondition.gameObject:SetActive(false)
    self.PanelWaferIcon.gameObject:SetActive(not isMaxQuality)
    self.RImgQuality:SetRawImage(qualityIcon)
    self.RImgQualityMax:SetRawImage(qualityIcon)

    for i = 1, character.Star do
        self.StarIcon[i].gameObject:SetActive(true)
        self.Line[i].gameObject:SetActive(true)
        self.StarColour[i].gameObject:SetActive(false)
    end

    for i = maxStar, character.Star + 1, -1 do
        self.StarIcon[i].gameObject:SetActive(false)
        self.Line[i].gameObject:SetActive(false)
        self.StarColour[i].gameObject:SetActive(true)
    end
end