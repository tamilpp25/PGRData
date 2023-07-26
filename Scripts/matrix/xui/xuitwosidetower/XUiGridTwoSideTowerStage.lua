---@class XUiGridTwoSideTowerStage
local XUiGridTwoSideTowerStage = XClass(nil, "XUiGridTwoSideTowerStage")

local CSInstantiate = CS.UnityEngine.GameObject.Instantiate

---@param transform UnityEngine.RectTransform
---@param pointData XTwoSideTowerPoint
---@param chapter XTwoSideTowerChapter
function XUiGridTwoSideTowerStage:Ctor(transform, pointData, isPositive, clickCallback, chapter, root)
    self.GameObject = transform.gameObject
    self.Transform = transform
    self.PointData = pointData
    self.ClickCallback = clickCallback
    self.ChapterData = chapter
    self.Root = root
    XTool.InitUiObject(self)
    self.BuffList = {self.PanelAffix01}
    self.UnknowBuffList = {self.PanelAffix02}
    self.BtnClick.CallBack = function()
        self:OnClickBtn()
    end
    self:Refresh()
end

function XUiGridTwoSideTowerStage:GetPointId()
    return self.PointData:GetId()
end

function XUiGridTwoSideTowerStage:OnClickBtn()
    local isPositive = self.ChapterData:IsPointPositive(self.PointData)
    if isPositive then
        XLuaUiManager.Open("UiTwoSideTowerStageDetailPositive", self.PointData,self.ChapterData)
    else
        XLuaUiManager.Open("UiTwoSideTowerStageDetailNegative", self.PointData, self.ChapterData)
    end
    if self.ClickCallback then
        self.ClickCallback(self)
    end
end

function XUiGridTwoSideTowerStage:Refresh(pointData, chapterData)
    self.PointData = pointData or self.PointData
    self.ChapterData = chapterData or self.ChapterData

    self.GreatHear1.gameObject:SetActiveEx(false)
    self.GreatHear2.gameObject:SetActiveEx(false)
    self.GreatHear.gameObject:SetActiveEx(false)
    self.CommonFuBenClear.gameObject:SetActiveEx(false)

    local stageList = self.PointData:GetStageDataList()
    local isPositive = self.ChapterData:IsPointPositive(self.PointData)
    self.RImgBg:SetRawImage(self.PointData:GetPointIconByDirection(isPositive))
    self.TxtOrder.text = self.PointData:GetNumberName()
    if isPositive then
        for i = 1, 2 do
            if i > #stageList then
                self["GreatHear" .. i].gameObject:SetActiveEx(false)
            else
                ---@type XTwoSideTowerStage
                local stageData = stageList[i]
                ---@type UnityEngine.RectTransform
                local obj = self["GreatHear" .. i]
                obj.gameObject:SetActiveEx(true)
                local bossIcon = obj:Find("RImgBossIcon"):GetComponent("RawImage")
                bossIcon:SetRawImage(stageData:GetSmallMonsterIcon())
                local passTag = obj:Find("PanelDisable")
                passTag.gameObject:SetActiveEx(stageData:IsPass())
            end
        end
    else
        self.GreatHear.gameObject:SetActiveEx(true)
        local stageData = self.PointData:GetNegativeStage()
        local bossIcon = self.GreatHear:Find("RImgBossIcon"):GetComponent("RawImage")
        bossIcon:SetRawImage(stageData:GetSmallMonsterIcon())
        self.CommonFuBenClear.gameObject:SetActiveEx(stageData:IsPass())
    end
    self.PanelSelectEffect.gameObject:SetActiveEx(self.ChapterData:IsCurrPoint(self.PointData))

    -- 刷新特性列表
    self:RefreshBuffList()

    -- 切换动画
    self:PlaySwitchAnim()
end

-- 刷新特性列表
function XUiGridTwoSideTowerStage:RefreshBuffList()
    self:ResetBuffGridList()
    local isChapterPositive = self.ChapterData:IsPositive()
    local stageData = self.PointData:GetNegativeStage()
    local isPass = stageData:IsPass()
    local totalFeatures = self.ChapterData:GetNegativeFeatureList(self.PointData, isChapterPositive)
    for i, featureId in ipairs(totalFeatures) do
        local isUnknow = featureId == XTwoSideTowerConfigs.UnknowFeatureId
        local gridBuff = self:GetBuffGrid(featureId)
        gridBuff.transform:SetAsLastSibling()
        if not isUnknow then
            local featureCfg = XTwoSideTowerConfigs.GetFeatureCfg(featureId)
            local icon = featureCfg.Icon
            local isShield = self.PointData:IsShieldFeature(featureId)
            if isPass then
                isShield = not self.PointData:IsFinishFeature(featureId)
            end

            local buffIcon = gridBuff:Find("ImgAffix"):GetComponent("RawImage")
            local panelScreen = gridBuff:Find("PanelScreen")
            panelScreen.gameObject:SetActiveEx(isShield)
            buffIcon:SetRawImage(icon)
        end
    end
end

-- 获取单个特性格子
function XUiGridTwoSideTowerStage:GetBuffGrid(featureId)
    local isUnknow = featureId == XTwoSideTowerConfigs.UnknowFeatureId
    local buffGrid

    if isUnknow then
        self.UnknowBuffIndex = self.UnknowBuffIndex + 1
        buffGrid = self.UnknowBuffList[self.UnknowBuffIndex]
        if not buffGrid then
            buffGrid = CSInstantiate(self.PanelAffix02, self.PanelAffixList)
            table.insert(self.UnknowBuffList, buffGrid)
        end
    else
        self.BuffIndex = self.BuffIndex + 1
        buffGrid = self.BuffList[self.BuffIndex]
        if not buffGrid then
            buffGrid = CSInstantiate(self.PanelAffix01, self.PanelAffixList)
            table.insert(self.BuffList, buffGrid)
        end
    end
    buffGrid.gameObject:SetActiveEx(true)

    return buffGrid
end

-- 重置特性格子列表
function XUiGridTwoSideTowerStage:ResetBuffGridList()
    self.BuffIndex = 0
    self.UnknowBuffIndex = 0
    for _, buff in ipairs(self.BuffList) do
        buff.gameObject:SetActiveEx(false)
    end
    for _, buff in ipairs(self.UnknowBuffList) do
        buff.gameObject:SetActiveEx(false)
    end
end

function XUiGridTwoSideTowerStage:SetSelect(isSelect)
end

-- 播放切换动画
function XUiGridTwoSideTowerStage:PlaySwitchAnim()
    local pointId = self.PointData:GetId()
    local lastPositive = self.Root.Root:GetPointPositive(pointId)
    local isPositive = self.ChapterData:IsPointPositive(self.PointData)
    if lastPositive ~= isPositive then
        if isPositive then
            self:PlayNegativeToPositiveAnimation()
        else
            self:PlayPositiveToNegativeAnimation()
        end
        self.Root.Root:SetPointPositive(pointId, isPositive)
    end
end

function XUiGridTwoSideTowerStage:PlayPositiveToNegativeAnimation()
    self.QieHuan1:Stop()
    self.QieHuan2:Stop()
    self.QieHuan1:Play()
end

function XUiGridTwoSideTowerStage:PlayNegativeToPositiveAnimation()
    self.QieHuan1:Stop()
    self.QieHuan2:Stop()
    self.QieHuan2:Play()
end

return XUiGridTwoSideTowerStage
