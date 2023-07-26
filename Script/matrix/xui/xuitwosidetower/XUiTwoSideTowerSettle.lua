local XUiTwoSideTowerSettle = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerSettle")

function XUiTwoSideTowerSettle:OnAwake()
    self.GridCombo.gameObject:SetActiveEx(false)
end

---@param chapterData XTwoSideTowerChapter
function XUiTwoSideTowerSettle:OnStart(chapterData)
    self.ChapterData = chapterData
    self.BtnExitFight.CallBack = function() self:Close() end
    self:Refresh()
end

function XUiTwoSideTowerSettle:Refresh()
    local pointList = self.ChapterData:GetPointData()
    local totalFeature = {}
    local shieldFeature = {}
    local totalCount = 0
    local shieldCount = 0
    local maxPoint = 0
    for _, point in pairs(pointList) do
        local initScore = point:GetInitScore()
        maxPoint = maxPoint + initScore
        local featureList = self.ChapterData:GetNegativeFeatureList(point)
        local shieldList = point:GetFinishFeatures()
        for _, featureId in pairs(featureList) do
            totalCount = totalCount + 1
            if not totalFeature[featureId] then
                totalFeature[featureId] = 1
            else
                totalFeature[featureId] = totalFeature[featureId] + 1
            end
        end
        for _, shieldId in pairs(shieldList) do
            shieldCount = shieldCount + 1
            if not shieldFeature[shieldId] then
                shieldFeature[shieldId] = 1
            else
                shieldFeature[shieldId] = shieldFeature[shieldId] + 1
            end
        end
    end

    for featureId, featureCount in pairs(totalFeature) do
        local go = CS.UnityEngine.GameObject.Instantiate(self.GridCombo, self.PanelComboContent)
        go.gameObject:SetActiveEx(true)
        local uiObj = go:GetComponent("UiObject")
        local featureCfg = XTwoSideTowerConfigs.GetFeatureCfg(featureId)
        local shieldNumber = shieldFeature[featureId] or 0
        uiObj:GetObject("RImgCombo"):SetRawImage(featureCfg.Icon)
        uiObj:GetObject("TxtNumber").text = CS.XTextManager.GetText("TwoSideTowerSettleBuffDesc", shieldNumber, featureCount)
        uiObj:GetObject("EffectSettle").gameObject:SetActiveEx(shieldNumber == featureCount)
        uiObj:GetObject("EffectRed").gameObject:SetActiveEx(featureCfg.Type == 2)
    end

    self.TxtShieldDetail.text = XUiHelper.ConvertLineBreakSymbol(CS.XTextManager.GetText("TwoSideTowerSettleShieldDetail", totalCount - shieldCount, shieldCount))
    local icon = self.ChapterData:GetChapterScoreIcon()
    self.RImgRank:SetRawImage(icon)
    self.TxtWinTitle.text = CS.XTextManager.GetText("TwoSideTowerSettleTitle",self.ChapterData:GetChapterName())
end

return XUiTwoSideTowerSettle
