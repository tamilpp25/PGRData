local XUiPanelCollection = XClass(nil, "XUiPanelCollection")

function XUiPanelCollection:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiPanelCollection:Refresh(exhibitionType)
    local collectionRate = XDataCenter.ExhibitionManager.GetCollectionRate(true, exhibitionType)
    self.TxtPanelCollectionRate.text = math.floor(collectionRate * 100)
    self.ImgRate.fillAmount = collectionRate
    if exhibitionType then
        self.TextNameLabel.text = CS.XTextManager.GetText("ExhibitionCollectionLable" .. exhibitionType)
    else
        self.TextNameLabel.text = CS.XTextManager.GetText("ExhibitionCollectionDefaultLable")
    end
    local totalCharacterNum = XDataCenter.ExhibitionManager.GetCollectionTotalNum(exhibitionType)
    local curFinishNum = XDataCenter.ExhibitionManager.GetTaskFinishNum(true, exhibitionType)
    if totalCharacterNum == 0 then
        self.ImgRateNew.fillAmount = 1
        self.ImgRateLower.fillAmount = 1
        self.ImgRateMiddle.fillAmount = 1
        self.ImgRateHigher.fillAmount = 1
    else
        self.ImgRateNew.fillAmount = curFinishNum[XEnumConst.CHARACTER.GrowUpLevel.New] / totalCharacterNum
        self.ImgRateLower.fillAmount = curFinishNum[XEnumConst.CHARACTER.GrowUpLevel.Lower] / totalCharacterNum
        self.ImgRateMiddle.fillAmount = curFinishNum[XEnumConst.CHARACTER.GrowUpLevel.Middle] / totalCharacterNum
        self.ImgRateHigher.fillAmount = curFinishNum[XEnumConst.CHARACTER.GrowUpLevel.Higher] / totalCharacterNum
    end
    self.TxtNumNew.text = curFinishNum[XEnumConst.CHARACTER.GrowUpLevel.New]
    self.TxtTotalNew.text = totalCharacterNum
    self.TxtNumLower.text = curFinishNum[XEnumConst.CHARACTER.GrowUpLevel.Lower]
    self.TxtTotalLower.text = totalCharacterNum
    self.TxtNumMiddle.text = curFinishNum[XEnumConst.CHARACTER.GrowUpLevel.Middle]
    self.TxtTotalMiddle.text = totalCharacterNum
    self.TxtNumHigher.text = curFinishNum[XEnumConst.CHARACTER.GrowUpLevel.Higher]
    self.TxtTotalHigher.text = totalCharacterNum
    self.InfoLabelNew.text = XExhibitionConfigs.GetExhibitionLevelNameByLevel(XEnumConst.CHARACTER.GrowUpLevel.New)
    self.InfoLabelLower.text = XExhibitionConfigs.GetExhibitionLevelNameByLevel(XEnumConst.CHARACTER.GrowUpLevel.Lower)
    self.InfoLabelMiddle.text = XExhibitionConfigs.GetExhibitionLevelNameByLevel(XEnumConst.CHARACTER.GrowUpLevel.Middle)
    self.InfoLabelHigher.text = XExhibitionConfigs.GetExhibitionLevelNameByLevel(XEnumConst.CHARACTER.GrowUpLevel.Higher)
end

function XUiPanelCollection:Show(exhibitionType)
    self:Refresh(exhibitionType)
    self.GameObject:SetActive(true)
end

function XUiPanelCollection:Hide()
    self.GameObject:SetActive(false)
end

return XUiPanelCollection