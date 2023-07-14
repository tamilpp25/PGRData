local XUiTwoSideTowerStageDetailNegative = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerStageDetailNegative")

---@param pointData XTwoSideTowerPoint
---@param chapter XTwoSideTowerChapter
function XUiTwoSideTowerStageDetailNegative:OnStart(pointData, chapter)
    self.PointData = pointData
    self.ChapterData = chapter
    self.GridBuffList = {}
    self.BtnEnter.CallBack = function()
        local stageId = self.PointData:GetNegativeStage():GetStageId()
        XDataCenter.TwoSideTowerManager.OpenUiBattleRoleRoom(stageId)
    end
    self.BtnShield.CallBack = function()
        local featureList = self.ChapterData:GetNegativeFeatureList(self.PointData)
        XLuaUiManager.Open("UiTwoSideTowerDetails", featureList, self.PointData, self.ChapterData,function() self:Refresh() end)
    end
    self:RegisterClickEvent(self.BtnMaskB, function()
        self:Close()
    end)
    self.BtnStageDetail.CallBack = function()
        XUiManager.DialogTip(CS.XTextManager.GetText("TwoSideTowerStageDetailTitle"), self.PointData:GetNegativeStage():GetDesc(), XUiManager.DialogType.NoBtn)
    end
    self:Refresh()
    self:RevertBuffShield()
end

function XUiTwoSideTowerStageDetailNegative:Refresh()
    ---@type XTwoSideTowerStage
    local stageData = self.PointData:GetNegativeStage()
    local isUnlockPoint = self.ChapterData:IsUnlockPoint(self.PointData)
    local isCurrPoint = self.ChapterData:IsCurrPoint(self.PointData)
    if not isCurrPoint then
        self.BtnEnter:SetName(CS.XTextManager.GetText("TwoSideTowerFightAgain"))
    end
    local isPositive = self.ChapterData:IsPositive()
    self.PanelCondition.gameObject:SetActiveEx(not isUnlockPoint)
    self.BtnEnter.gameObject:SetActiveEx(isUnlockPoint)
    self.BtnShield.gameObject:SetActiveEx(isUnlockPoint)
    self.TxtPointName.text = stageData:GetStageNumberName()
    self.RImgBigBossIcon:SetRawImage(stageData:GetBigMonsterIcon())
    local isReduceScore = self.PointData:GetReduceScore() > 0 
    self.TxtScoreReduce.gameObject:SetActiveEx(isReduceScore)
    self.RImgWeakIcon:SetRawImage(stageData:GetWeakIcon())
    local totalFeatures = self.ChapterData:GetNegativeFeatureList(self.PointData, isPositive)
    for i, feature in pairs(totalFeatures) do
        local isUnknow = feature == XTwoSideTowerConfigs.UnknowFeatureId
        local icon = XTwoSideTowerConfigs.GetUnknowFeatureIcon()
        local isShowEffect = false
        local isShield = self.PointData:IsShieldFeature(feature)

        if not isUnknow then
            local featureCfg = XTwoSideTowerConfigs.GetFeatureCfg(feature)
            icon = featureCfg.Icon
            isShowEffect = featureCfg.Type == 2
        end

        local buffUiObj = self.GridBuffList[i]
        if not buffUiObj then
            ---@type UnityEngine.RectTransform
            local buffGo = CS.UnityEngine.GameObject.Instantiate(self.GridBuff, self.PanelBuffContent)
            buffUiObj = buffGo:GetComponent("UiObject")
            table.insert(self.GridBuffList, buffUiObj)
        end

        buffUiObj:GetObject("RImgIcon"):SetRawImage(icon)
        buffUiObj:GetObject("PanelScreen").gameObject:SetActiveEx(isShield)
        buffUiObj:GetObject("Effect").gameObject:SetActiveEx(isShowEffect)
        buffUiObj:GetObject("Bg01").gameObject:SetActiveEx(isUnknow)
        buffUiObj:GetObject("Bg02").gameObject:SetActiveEx(not isUnknow)
        buffUiObj:GetObject("BtnClick").CallBack = function()
            if isUnlockPoint then
                XLuaUiManager.Open("UiTwoSideTowerDetails", self.ChapterData:GetNegativeFeatureList(self.PointData), self.PointData, self.ChapterData,function() self:Refresh() end)
            end
        end
    end
    self.GridBuff.gameObject:SetActiveEx(false)
end

-- 还原buff屏蔽
function XUiTwoSideTowerStageDetailNegative:RevertBuffShield()
    local stageData = self.PointData:GetNegativeStage()
    if not stageData:IsPass() then
        return
    end

    local isPositive = self.ChapterData:IsPositive()
    local totalFeatureIds = self.ChapterData:GetNegativeFeatureList(self.PointData, isPositive)
    for i, featureId in pairs(totalFeatureIds) do
        local isShield = self.PointData:IsShieldFeature(featureId)
        local isFinish = not self.PointData:IsFinishFeature(featureId)
        if isShield ~= isFinish then
            XDataCenter.TwoSideTowerManager.ShieldFeatureRequest(featureId, stageData:GetStageId(), isFinish, function(pointData)
                self.ChapterData:UpdatePointData(pointData)
                self:Refresh()
            end)
        end
    end
end

return XUiTwoSideTowerStageDetailNegative
