-- 三头犬小队玩法 CerberusGame (活动)
local XUiCerberusGameChapter = XLuaUiManager.Register(XLuaUi, "UiCerberusGameChapter")
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
        [XEnumConst.CerberusGame.StageDifficulty.Normal] = self.GridNormalStageDic,
        [XEnumConst.CerberusGame.StageDifficulty.Hard] = self.GridHardStageDic,
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
    local timeId = XMVCA.XCerberusGame:GetActivityConfig().TimeId
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
    self:OnEnableCb()
    self:RefreshUiShow()

    XEventManager.AddEventListener(XEventId.EVENT_CERBERUS_GAME_PASS_STORY_POINT, self.RefreshUiShow, self)
end

function XUiCerberusGameChapter:OnEnableCb()
    self.Super.OnEnable(self)

    local tempDiff = XMVCA.XCerberusGame:GetLastSelectChapterStoryLineDifficulty(self.ChapterId) or XEnumConst.CerberusGame.StageDifficulty.Normal
    if tempDiff == XEnumConst.CerberusGame.StageDifficulty.Hard and not self:CheckHardOpen() then
        tempDiff = XEnumConst.CerberusGame.StageDifficulty.Normal
    end
    self.CurrDifficulty = tempDiff
    self.StoryLineCfg = XMVCA.XCerberusGame:GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, self.CurrDifficulty)
end

function XUiCerberusGameChapter:RefreshUiShow()
    self:RefreshStageLine()
    self:RefreshBtnDifficultyShow()

    -- 标题
    self.TxtName.text = self.StoryLineCfg.Name
    local name02Key = self.CurrDifficulty == XEnumConst.CerberusGame.StageDifficulty.Normal and "CerbrusGameChapterLineNameStory" or "CerbrusGameChapterLineNameFight"
    self.TxtName02.text =  CS.XTextManager.GetText(name02Key)

    -- 其他固定文本和图片ui
    local totalCount = XMVCA.XCerberusGame:GetAllStoryStarsCountByDifficulty(self.ChapterId, XEnumConst.CerberusGame.StageDifficulty.Normal)
    local activeCount = XMVCA.XCerberusGame:GetStoryActiveStarsCountByDifficulty(self.ChapterId, XEnumConst.CerberusGame.StageDifficulty.Normal)
    local prog = activeCount / totalCount
    local progStr = string.format("%.0f%%", prog * 100)  -- 将小数转换为百分比字符串
    self.BtnNormal:SetNameByGroup(0, progStr)

    totalCount = XMVCA.XCerberusGame:GetAllStoryStarsCountByDifficulty(self.ChapterId, XEnumConst.CerberusGame.StageDifficulty.Hard)
    activeCount = XMVCA.XCerberusGame:GetStoryActiveStarsCountByDifficulty(self.ChapterId, XEnumConst.CerberusGame.StageDifficulty.Hard)
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
    self:AutoPosByLastStage()
end

-- 如果有记录过上一次点击的stage，则定位置
-- 如果没有则定位到最新open的stage
function XUiCerberusGameChapter:AutoPosByLastStage()
    local targetTransform = nil
    local lastSeleXStoryPoint = XMVCA.XCerberusGame:GetLastSelectXStoryPoint()
    if lastSeleXStoryPoint then
        local curStageDic = self.GridDifficultyDicStageDic[self.CurrDifficulty]
        local targetStage = curStageDic[lastSeleXStoryPoint:GetId()]
        targetTransform = targetStage and targetStage.Transform
    end
    if targetTransform then
        self:AutoPos(targetTransform, ScaleLevel.Big, 0, CS.UnityEngine.Vector3.zero)
        return
    end

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
        self:AutoPos(targetTransform, ScaleLevel.Big, 0, CS.UnityEngine.Vector3.zero)
    end
end

-- 自动定位
function XUiCerberusGameChapter:AutoPos(targetTransform, scale, time, v3, cb)
    self.PanelDrag:FocusTarget(targetTransform, scale, time, v3, cb)
end

---@param xStoryPoint XCerberusGameStage
---@param gridStage XUiGridCerberusGameStage
function XUiCerberusGameChapter:OnGridStoryPointClick(xStoryPoint, gridStage)
    if xStoryPoint:GetType() == XEnumConst.CerberusGame.StoryPointType.Battle then
        XLuaUiManager.Open("UiCerberusGameDetail", xStoryPoint, self.ChapterId, self.CurrDifficulty, gridStage)
    elseif xStoryPoint:GetType() == XEnumConst.CerberusGame.StoryPointType.Story then
        XLuaUiManager.Open("UiCerberusGamePlotDetail", xStoryPoint, gridStage)
    elseif xStoryPoint:GetType() == XEnumConst.CerberusGame.StoryPointType.Communicate then
        XMVCA.XCerberusGame:StartCommunication(xStoryPoint:GetConfig().Id)
    end

    self:AutoPos(gridStage.Transform, ScaleLevel.Big, 0.5, CS.UnityEngine.Vector3.zero)
end

function XUiCerberusGameChapter:CheckHardOpen()
    local hardCondition = XMVCA.XCerberusGame:GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, XEnumConst.CerberusGame.StageDifficulty.Hard).OpenCondition
    local isHardValid = XTool.IsNumberValid(hardCondition)
    local hardOpen = nil
    local desc = nil
    if isHardValid then
        hardOpen, desc = XConditionManager.CheckCondition(hardCondition)
    else
        hardOpen = true
    end

    return hardOpen, desc
end

function XUiCerberusGameChapter:CheckNormalOpen()
    local normalCondition = XMVCA.XCerberusGame:GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, XEnumConst.CerberusGame.StageDifficulty.Normal).OpenCondition
    local isNomalValid = XTool.IsNumberValid(normalCondition)
    local normalOpen = nil
    local desc = nil
    if isNomalValid then
        normalOpen, desc = XConditionManager.CheckCondition(normalCondition)
    else
        normalOpen = true
    end

    return normalOpen, desc
end

function XUiCerberusGameChapter:RefreshBtnDifficultyShow()
    self.BtnNormal.gameObject:SetActiveEx(self.CurrDifficulty == XEnumConst.CerberusGame.StageDifficulty.Normal)
    self.BtnHard.gameObject:SetActiveEx(self.CurrDifficulty == XEnumConst.CerberusGame.StageDifficulty.Hard)
    XMVCA.XCerberusGame:SetLastSelectStoryLineDifficulty(self.CurrDifficulty)
    XMVCA.XCerberusGame:SetLastSelectChapterStoryLineDifficulty(self.ChapterId,self.CurrDifficulty)
end

-- 如果是一模一样的数据，说明现在是要展开难度选项
function XUiCerberusGameChapter:ShowSelect(targetDifficulty)
    -- 如果本来就展开了 则关起来
    if self.BtnNormal.gameObject.activeInHierarchy and self.BtnHard.gameObject.activeInHierarchy then
        self.BtnNormal.gameObject:SetActiveEx(targetDifficulty == XEnumConst.CerberusGame.StageDifficulty.Normal)
        self.BtnHard.gameObject:SetActiveEx(targetDifficulty == XEnumConst.CerberusGame.StageDifficulty.Hard)
        return
    end

    self.BtnNormal.gameObject:SetActiveEx(true)
    self.BtnHard.gameObject:SetActiveEx(true)
end

function XUiCerberusGameChapter:OnBtnNormalClick()
    local normalCondition = XMVCA.XCerberusGame:GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, XEnumConst.CerberusGame.StageDifficulty.Normal).OpenCondition
    if XTool.IsNumberValid(normalCondition) then
        local normalOpen, desc = XConditionManager.CheckCondition(normalCondition)
        if not normalOpen then
            XUiManager.TipError(desc)
            return
        end
    end


    local targetDifficulty = XEnumConst.CerberusGame.StageDifficulty.Normal
    if self.CurrDifficulty == targetDifficulty then
        self:ShowSelect(targetDifficulty)
        return
    end

    self.CurrDifficulty = targetDifficulty
    self.StoryLineCfg = XMVCA.XCerberusGame:GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, self.CurrDifficulty)
    self:RefreshUiShow()
    self:PlayAnimation("QieHuan")
    self.BtnNormal.transform:SetAsFirstSibling()
end

function XUiCerberusGameChapter:OnBtnHardClick()
    local hardCondition = XMVCA.XCerberusGame:GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, XEnumConst.CerberusGame.StageDifficulty.Hard).OpenCondition
    if XTool.IsNumberValid(hardCondition) then
        local hardOpen, desc = XConditionManager.CheckCondition(hardCondition)
        if not hardOpen then
            XUiManager.TipError(desc)
            return
        end
    end

    local targetDifficulty = XEnumConst.CerberusGame.StageDifficulty.Hard
    if self.CurrDifficulty == targetDifficulty then
        self:ShowSelect(targetDifficulty)
        return
    end

    self.CurrDifficulty = targetDifficulty
    self.StoryLineCfg = XMVCA.XCerberusGame:GetStoryLineCfgByChapterAndDifficulty(self.ChapterId, self.CurrDifficulty)
    self:RefreshUiShow()
    self:PlayAnimation("QieHuan")
    self.BtnHard.transform:SetAsFirstSibling()
end

return XUiCerberusGameChapter