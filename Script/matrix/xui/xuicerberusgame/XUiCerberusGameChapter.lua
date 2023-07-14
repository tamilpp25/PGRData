-- 三头犬小队玩法 CerberusGame (活动)
local XUiCerberusGameChapter = XLuaUiManager.Register(XLuaUi, "UiCerberusGameChapter")
local XUiGridCerberusGameStage = require("XUi/XUiCerberusGame/Grid/XUiGridCerberusGameStage")
local ScaleLevel = {
    Small = 0,
    Big = 0,
    Normal = 0,
}

function XUiCerberusGameChapter:OnAwake()
    ---@type table<number, XUiGridCerberusGameStage>
    self.GridNormalStageDic = {}
    self.GridHardStageDic = {}
    self.GridDifficultyDicStageDic = 
    {
        [XCerberusGameConfig.StageDifficulty.Normal] = self.GridNormalStageDic,
        [XCerberusGameConfig.StageDifficulty.Hard] = self.GridHardStageDic,
    }

    self:InitButton()
    self:InitTimes()
end

function XUiCerberusGameChapter:InitButton()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function () XLuaUiManager.RunMain() end)
    self:RegisterClickEvent(self.BtnNormal, self.OnBtnNormalClick)
    self:RegisterClickEvent(self.BtnHard, self.OnBtnHardClick)
    self:BindHelpBtn(self.BtnHelpCourse, "CerberusHelp")
end

function XUiCerberusGameChapter:InitTimes()
    local timeId = XDataCenter.CerberusGameManager.GetActivityConfig().TimeId
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

function XUiCerberusGameChapter:OnStart(chapterId, difficulty)
    self.ChapterId = chapterId
end

function XUiCerberusGameChapter:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_CERBERUS_GAME_PASS_STORY_POINT, self.RefreshUiShow, self)
end

function XUiCerberusGameChapter:OnEnable()
    self.Super.OnEnable(self)

    self.CurrDifficulty = XDataCenter.CerberusGameManager.GetLastSelectStoryLineDifficulty() or XCerberusGameConfig.StageDifficulty.Normal
    self.StoryLineCfg = XDataCenter.CerberusGameManager.GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, self.CurrDifficulty)
    self:RefreshUiShow()

    XEventManager.AddEventListener(XEventId.EVENT_CERBERUS_GAME_PASS_STORY_POINT, self.RefreshUiShow, self)
end

function XUiCerberusGameChapter:RefreshUiShow()
    self:RefreshStageLine()
    self:RefreshBtnDifficultyShow()

    -- 标题
    self.TxtName.text = self.StoryLineCfg.Name
    local name02Key = self.CurrDifficulty == XCerberusGameConfig.StageDifficulty.Normal and "CerbrusGameChapterLineNameStory" or "CerbrusGameChapterLineNameFight"
    self.TxtName02.text =  CS.XTextManager.GetText(name02Key)

    -- 其他固定文本和图片ui
    local totalCount = XDataCenter.CerberusGameManager.GetAllStoryStarsCountByDifficulty(self.ChapterId, XCerberusGameConfig.StageDifficulty.Normal)
    local activeCount = XDataCenter.CerberusGameManager.GetStoryActiveStarsCountByDifficulty(self.ChapterId, XCerberusGameConfig.StageDifficulty.Normal)
    local prog = activeCount / totalCount
    local progStr = string.format("%.0f%%", prog * 100)  -- 将小数转换为百分比字符串
    self.BtnNormal:SetNameByGroup(0, progStr)

    totalCount = XDataCenter.CerberusGameManager.GetAllStoryStarsCountByDifficulty(self.ChapterId, XCerberusGameConfig.StageDifficulty.Hard)
    activeCount = XDataCenter.CerberusGameManager.GetStoryActiveStarsCountByDifficulty(self.ChapterId, XCerberusGameConfig.StageDifficulty.Hard)
    prog = activeCount / totalCount
    progStr = string.format("%.0f%%", prog * 100)  -- 将小数转换为百分比字符串
    self.BtnHard:SetNameByGroup(0, progStr)
end

function XUiCerberusGameChapter:RefreshStageLine()
    if not self.StoryLineCfg then
        return
    end

    -- 路线图
    local linePrefab = self.PanelChapter:LoadPrefab(self.StoryLineCfg.FubenPrefab)
    self.PanelDrag = linePrefab.transform:Find("PanelDrag"):GetComponent(typeof(CS.XDragArea))
    ScaleLevel.Small = self.PanelDrag.MinScale
    ScaleLevel.Big = self.PanelDrag.MaxScale
    ScaleLevel.Normal = (self.PanelDrag.MinScale + self.PanelDrag.MaxScale) / 2
  
    for k, storyPointId in pairs(self.StoryLineCfg.StoryPointIds) do
        local stageIndexParentTrans = linePrefab:FindTransform("Stage"..k)
        local xStoryPoint = XDataCenter.CerberusGameManager.GetXStoryPointById(storyPointId)
        stageIndexParentTrans.gameObject:SetActiveEx(xStoryPoint:GetIsOpen())

        local prefabPath = self.StoryLineCfg[XCerberusGameConfig.StoryPointShowType[xStoryPoint:GetConfig().GridShowType or 1]]
        local gridStageGo = stageIndexParentTrans:LoadPrefab(prefabPath)
        local curStageDic = self.GridDifficultyDicStageDic[self.CurrDifficulty]
        ---@type XUiGridCerberusGameStage
        local gridStage = curStageDic and curStageDic[storyPointId]
        if not gridStage then
            gridStage = XUiGridCerberusGameStage.New()
            curStageDic[storyPointId] = gridStage
        end
        gridStage:Refresh(xStoryPoint, gridStageGo, k, self)
        XUiHelper.RegisterClickEvent(gridStage, gridStage.BtnNode, function ()
            self:OnGridStoryPointClick(xStoryPoint, gridStage)
        end)
    end
    self:AutoPosByLastStage()
end

-- 如果有记录过上一次点击的stage，则定位置
-- 如果没有则定位到最新open的stage
function XUiCerberusGameChapter:AutoPosByLastStage()
    local targetTransform = nil
    local lastSeleXStoryPoint = XDataCenter.CerberusGameManager.GetLastSelectXStoryPoint()
    if lastSeleXStoryPoint then
        local curStageDic = self.GridDifficultyDicStageDic[self.CurrDifficulty]
        local targetStage = curStageDic[lastSeleXStoryPoint:GetId()]
        targetTransform = targetStage and targetStage.Transform
    end
    if targetTransform then
        self.PanelDrag:FocusTarget(targetTransform, ScaleLevel.Big, 0, CS.UnityEngine.Vector3.zero)
        return
    end

    for i = #self.StoryLineCfg.StoryPointIds, 1, -1 do
        local storyPointId = self.StoryLineCfg.StoryPointIds[i]
        local xStoryPoint = XDataCenter.CerberusGameManager.GetXStoryPointById(storyPointId)
        if xStoryPoint:GetIsShow() then
            local curStageDic = self.GridDifficultyDicStageDic[self.CurrDifficulty]
            local targetStage = curStageDic[storyPointId]
            targetTransform = targetStage and targetStage.Transform
            break
        end
    end
    if targetTransform then
        self.PanelDrag:FocusTarget(targetTransform, ScaleLevel.Big, 0, CS.UnityEngine.Vector3.zero)
    end
end

-- 自动定位
function XUiCerberusGameChapter:AutoPos(targetTransform, scale, time, v3, cb)
    self.PanelDrag:FocusTarget(targetTransform, scale, time, v3, cb)
end

---@param xStoryPoint XCerberusGameStage
---@param gridStage XUiGridCerberusGameStage
function XUiCerberusGameChapter:OnGridStoryPointClick(xStoryPoint, gridStage)
    if xStoryPoint:GetType() == XCerberusGameConfig.StoryPointType.Battle then
        XLuaUiManager.Open("UiCerberusGameDetail", xStoryPoint, self.ChapterId, self.CurrDifficulty, gridStage)
    elseif xStoryPoint:GetType() == XCerberusGameConfig.StoryPointType.Story then
        XLuaUiManager.Open("UiCerberusGamePlotDetail", xStoryPoint, gridStage)
    elseif xStoryPoint:GetType() == XCerberusGameConfig.StoryPointType.Communicate then
        XDataCenter.CerberusGameManager.StartCommunication(xStoryPoint:GetConfig().Id)
    end

    self:AutoPos(gridStage.Transform, ScaleLevel.Big, 0.5, CS.UnityEngine.Vector3.zero)
end

function XUiCerberusGameChapter:RefreshBtnDifficultyShow()
    self.BtnNormal.gameObject:SetActiveEx(self.CurrDifficulty == XCerberusGameConfig.StageDifficulty.Normal)
    self.BtnHard.gameObject:SetActiveEx(self.CurrDifficulty == XCerberusGameConfig.StageDifficulty.Hard)

    local normalCondition = XDataCenter.CerberusGameManager.GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, XCerberusGameConfig.StageDifficulty.Normal).OpenCondition
    local hardCondition = XDataCenter.CerberusGameManager.GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, XCerberusGameConfig.StageDifficulty.Hard).OpenCondition

    local isNomalValid = XTool.IsNumberValid(normalCondition)
    local normalOpen = nil
    if isNomalValid then
        normalOpen = XConditionManager.CheckCondition(normalCondition)
    else
        normalOpen = true
    end
    
    local isHardValid = XTool.IsNumberValid(hardCondition)
    local hardOpen = nil
    if isHardValid then
        hardOpen = XConditionManager.CheckCondition(hardCondition)
    else
        hardOpen = true
    end

    XDataCenter.CerberusGameManager.SetLastSelectStoryLineDifficulty(self.CurrDifficulty)
end

-- 如果是一模一样的数据，说明现在是要展开难度选项
function XUiCerberusGameChapter:ShowSelect(targetDifficulty)
    -- 如果本来就展开了 则关起来
    if self.BtnNormal.gameObject.activeInHierarchy and self.BtnHard.gameObject.activeInHierarchy then
        self.BtnNormal.gameObject:SetActiveEx(targetDifficulty == XCerberusGameConfig.StageDifficulty.Normal)
        self.BtnHard.gameObject:SetActiveEx(targetDifficulty == XCerberusGameConfig.StageDifficulty.Hard)
        return
    end

    self.BtnNormal.gameObject:SetActiveEx(true)
    self.BtnHard.gameObject:SetActiveEx(true)
end

function XUiCerberusGameChapter:OnBtnNormalClick()
    local normalCondition = XDataCenter.CerberusGameManager.GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, XCerberusGameConfig.StageDifficulty.Normal).OpenCondition
    if XTool.IsNumberValid(normalCondition) then
        local normalOpen, desc = XConditionManager.CheckCondition(normalCondition)
        if not normalOpen then
            XUiManager.TipError(desc)
            return
        end
    end


    local targetDifficulty = XCerberusGameConfig.StageDifficulty.Normal
    if self.CurrDifficulty == targetDifficulty then
        self:ShowSelect(targetDifficulty)
        return
    end

    self.CurrDifficulty = targetDifficulty
    self.StoryLineCfg = XDataCenter.CerberusGameManager.GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, self.CurrDifficulty)
    self:RefreshUiShow()
    self:PlayAnimation("QieHuan")
    self.BtnNormal.transform:SetAsFirstSibling()
end

function XUiCerberusGameChapter:OnBtnHardClick()
    local hardCondition = XDataCenter.CerberusGameManager.GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, XCerberusGameConfig.StageDifficulty.Hard).OpenCondition
    if XTool.IsNumberValid(hardCondition) then
        local hardOpen, desc = XConditionManager.CheckCondition(hardCondition)
        if not hardOpen then
            XUiManager.TipError(desc)
            return
        end
    end

    local targetDifficulty = XCerberusGameConfig.StageDifficulty.Hard
    if self.CurrDifficulty == targetDifficulty then
        self:ShowSelect(targetDifficulty)
        return
    end

    self.CurrDifficulty = targetDifficulty
    self.StoryLineCfg = XDataCenter.CerberusGameManager.GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, self.CurrDifficulty)
    self:RefreshUiShow()
    self:PlayAnimation("QieHuan")
    self.BtnHard.transform:SetAsFirstSibling()
end

return XUiCerberusGameChapter