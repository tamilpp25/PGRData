local XUiCerberusGameChapter = require("XUi/XUiCerberusGame/XUiCerberusGameChapter")
local XUiCerberusGameChapterV2P9 = XLuaUiManager.Register(XUiCerberusGameChapter, "UiCerberusGameChapterV2P9")

function XUiCerberusGameChapterV2P9:InitTimes()
    local secondTimeId = XMVCA.XCerberusGame:GetClientConfigValueByKey("CerberusGameRound2Time")
    local timeId = secondTimeId
    if not timeId then
        return
    end
    
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        end
    end)
end

function XUiCerberusGameChapterV2P9:OnEnableCb()
    local tempDiff = XMVCA.XCerberusGame:GetLastSelectChapterStoryLineDifficulty(self.ChapterId) or XEnumConst.CerberusGame.StageDifficulty.Normal
    if tempDiff == XEnumConst.CerberusGame.StageDifficulty.Hard and not self:CheckHardOpen() then
        tempDiff = XEnumConst.CerberusGame.StageDifficulty.Normal
    end
    self.CurrDifficulty = tempDiff
    self.StoryLineCfg = XMVCA.XCerberusGame:GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, self.CurrDifficulty)
end

function XUiCerberusGameChapterV2P9:RefreshUiShow()
    -- 标题
    self.TxtName.text = self.StoryLineCfg.Name
    -- 通关了普通难度才能显示难度选择按钮
    self.PanelTopDifficult.gameObject:SetActiveEx(self:CheckHardOpen())
    self.BtnNormal.gameObject:SetActiveEx(self.CurrDifficulty == XEnumConst.CerberusGame.StageDifficulty.Hard)
    self.BtnHard.gameObject:SetActiveEx(self.CurrDifficulty == XEnumConst.CerberusGame.StageDifficulty.Normal)

    self:RefreshStageLine()
    XMVCA.XCerberusGame:SetLastSelectStoryLineDifficulty(self.CurrDifficulty)
    XMVCA.XCerberusGame:SetLastSelectChapterStoryLineDifficulty(self.ChapterId,self.CurrDifficulty)
end

function XUiCerberusGameChapterV2P9:RefreshStageLine()
    if not self.StoryLineCfg then
        return
    end

    -- 路线图
    local linePrefab = self.PanelChapter:LoadPrefab(self.StoryLineCfg.FubenPrefab)
    self.PanelStageContent = linePrefab:FindTransform("PanelStageContent")
    self.PanelStageList = linePrefab:FindTransform("PanelDrag"):GetComponent("ScrollRect")
  
    for k, storyPointId in pairs(self.StoryLineCfg.StoryPointIds) do
        local stageIndexParentTrans = linePrefab:FindTransform("Stage"..k)
        local xStoryPoint = XMVCA.XCerberusGame:GetXStoryPointById(storyPointId)
        stageIndexParentTrans.gameObject:SetActiveEx(xStoryPoint:GetIsOpen())

        local gridShowType = XTool.IsNumberValid(xStoryPoint:GetConfig().GridShowType) and xStoryPoint:GetConfig().GridShowType or 1
        local prefabPath = self.StoryLineCfg[XEnumConst.CerberusGame.StoryPointShowType[gridShowType]]
        local gridStageGo = stageIndexParentTrans:LoadPrefab(prefabPath)
        local curStageDic = self.GridDifficultyDicStageDic[self.CurrDifficulty]
        ---@type XUiGridCerberusGameStage
        local gridStage = curStageDic and curStageDic[storyPointId]
        if not gridStage then
            local XUiGridCerberusGameStage = require("XUi/XUiCerberusGame/Grid/XUiGridCerberusGameStage")
            gridStage = XUiGridCerberusGameStage.New()
            curStageDic[storyPointId] = gridStage
        end
        gridStage:Refresh(xStoryPoint, gridStageGo, k, self)
        XUiHelper.RegisterClickEvent(gridStage, gridStage.BtnNode, function ()
            self:OnGridStoryPointClick(xStoryPoint, gridStage)
        end)
    end
    self.PanelStageContent:GetComponent("XBoundSizeFitter"):SetLayoutHorizontal()
    self:AutoPosByLastStage()
end

-- 只定位到最新open的stage
function XUiCerberusGameChapterV2P9:AutoPosByLastStage()
    local targetTransform = nil
    for i = #self.StoryLineCfg.StoryPointIds, 1, -1 do
        local storyPointId = self.StoryLineCfg.StoryPointIds[i]
        local xStoryPoint = XMVCA.XCerberusGame:GetXStoryPointById(storyPointId)
        if xStoryPoint:GetIsShow() then
            local curStageDic = self.GridDifficultyDicStageDic[self.CurrDifficulty]
            local targetStage = curStageDic[storyPointId]
            targetTransform = targetStage and targetStage.Transform
            break
        end
    end
    if targetTransform then
        self:AutoPos(targetTransform.parent, nil, 0)
    end
end

-- 自动定位
function XUiCerberusGameChapterV2P9:AutoPos(targetTransform, scale, time, offsetV3, cb)
    local gridRect = targetTransform:GetComponent("RectTransform")
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    local left = 600
    
    local value = CS.XResolutionManager.OriginWidth / 2 - left
    if math.abs(diffX) > value then
        local tarPosX = (CS.XResolutionManager.OriginWidth / 4) - gridRect.localPosition.x - left
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, time or XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
            self:SetPanelStageListMovementType(CS.UnityEngine.UI.ScrollRect.MovementType.Elastic)
        end)
    end
end

function XUiCerberusGameChapterV2P9:SetPanelStageListMovementType(moveMentType)
    if not self.PanelStageList then return end
    self.PanelStageList.movementType = moveMentType
end

function XUiCerberusGameChapterV2P9:OnGridStoryPointClick(xStoryPoint, gridStage)
    if xStoryPoint:GetType() == XEnumConst.CerberusGame.StoryPointType.Battle then
        XLuaUiManager.Open("UiCerberusGameDetailV2P9", xStoryPoint, self.ChapterId, self.CurrDifficulty, gridStage)
    elseif xStoryPoint:GetType() == XEnumConst.CerberusGame.StoryPointType.Story then
        XLuaUiManager.Open("UiCerberusGamePlotDetail", xStoryPoint, gridStage)
    elseif xStoryPoint:GetType() == XEnumConst.CerberusGame.StoryPointType.Communicate then
        XMVCA.XCerberusGame:StartCommunication(xStoryPoint:GetConfig().Id)
    end

    self:AutoPos(gridStage.Transform.parent, nil, 0.5)
end

return XUiCerberusGameChapterV2P9