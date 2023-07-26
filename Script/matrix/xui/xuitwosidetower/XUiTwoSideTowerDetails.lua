local XUiTwoSideTowerDetails = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerDetails")

---@param pointData XTwoSideTowerPoint
function XUiTwoSideTowerDetails:OnStart(featureList, pointData, chapter, cb)
    self.FeatureList = featureList
    if pointData then
        self.PointData = pointData
        self.StageId = self.PointData:GetNegativeStage():GetStageId()
        ---@type XTwoSideTowerChapter
        self.Chapter = chapter
        self.Cb = cb
    end
    self.GridBuffDic = {}
    self.BtnTanchuangCloseBig.CallBack = function()
        self:Close()
        if self.Cb then
            self.Cb()
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_TWO_SIDE_TOWER_FEATURE_FORBID)
    end
    self:Refresh()
end

function XUiTwoSideTowerDetails:Refresh()
    self.PanelScore.gameObject:SetActiveEx(self.PointData)
    if self.PointData and self.TxtScore then
        self.TxtScore.gameObject:SetActiveEx(self.PointData:GetReduceScore() > 0)
    end
    if self.Chapter and self.TxtTips then
        self.TxtTips.gameObject:SetActiveEx(not self.Chapter:IsPositive())
    end
    for _, featureId in pairs(self.FeatureList) do
        if featureId == XTwoSideTowerConfigs.UnknowFeatureId then
            goto CONTINUE
        end

        local featureCfg = XTwoSideTowerConfigs.GetFeatureCfg(featureId)
        if not self.GridBuffDic[featureId] then
            ---@type UnityEngine.RectTransform
            local gridBuff = CS.UnityEngine.GameObject.Instantiate(self.GridBuff, self.Content)
            self.GridBuffDic[featureId] = gridBuff
            local btnShield = gridBuff:Find("BtnShield"):GetComponent("XUiButton")
            local btnRelieve = gridBuff:Find("BtnRelieve"):GetComponent("XUiButton")
            btnShield.CallBack = function()
                XDataCenter.TwoSideTowerManager.ShieldFeatureRequest(featureId, self.StageId, true, function(pointData)
                    btnShield.gameObject:SetActiveEx(false)
                    btnRelieve.gameObject:SetActiveEx(true)
                    self.Chapter:UpdatePointData(pointData)
                    self:Refresh()
                end)
            end
            btnRelieve.CallBack = function()
                XDataCenter.TwoSideTowerManager.ShieldFeatureRequest(featureId, self.StageId, false, function(pointData)
                    btnShield.gameObject:SetActiveEx(true)
                    btnRelieve.gameObject:SetActiveEx(false)
                    self.Chapter:UpdatePointData(pointData)
                    self:Refresh()
                end)
            end
        end
        local gridBuff = self.GridBuffDic[featureId]
        local isShield = self.PointData and self.PointData:IsShieldFeature(featureId) or false
        local buffName = gridBuff:Find("TxtBuffName"):GetComponent("Text")
        buffName.text = featureCfg.Name
        local buffDesc = gridBuff:Find("TxtAmbien"):GetComponent("Text")
        buffDesc.transform.sizeDelta = self.PointData and CS.UnityEngine.Vector2(813, buffDesc.transform.sizeDelta.y) or CS.UnityEngine.Vector2(1055, buffDesc.transform.sizeDelta.y)
        buffDesc.transform.anchoredPosition = self.PointData and CS.UnityEngine.Vector2(-104, buffDesc.transform.anchoredPosition.y) or CS.UnityEngine.Vector2(17.6, buffDesc.transform.anchoredPosition.y)
        buffDesc.text = featureCfg.Desc
        local buffIcon = gridBuff:Find("IconBuff/RImgIcon"):GetComponent("RawImage")
        buffIcon:SetRawImage(featureCfg.Icon)
        local btnShield = gridBuff:Find("BtnShield"):GetComponent("XUiButton")
        local btnRelieve = gridBuff:Find("BtnRelieve"):GetComponent("XUiButton")
        local panelScreen = gridBuff:Find("IconBuff/PanelScreen")
        local effect = gridBuff:Find("IconBuff/Effect")
        panelScreen.gameObject:SetActiveEx(self.PointData and self.PointData:IsShieldFeature(featureId))
        effect.gameObject:SetActiveEx(featureCfg.Type == 2)
        btnShield.gameObject:SetActiveEx(not isShield and self.PointData and self.Chapter)
        btnRelieve.gameObject:SetActiveEx(isShield and self.PointData and self.Chapter)

        :: CONTINUE ::
    end
    self.GridBuff.gameObject:SetActiveEx(false)
end

return XUiTwoSideTowerDetails
