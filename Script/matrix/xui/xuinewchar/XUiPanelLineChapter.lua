local XUiGridTreasureGrade = require("XUi/XUiFubenMainLineChapter/XUiGridTreasureGrade")
local XUiNewCharStageItem = require("XUi/XUiNewChar/XUiNewCharStageItem")
local XUiPanelLineChapter = XClass(nil, "XUiPanelLineChapter")
local XUguiDragProxy = CS.XUguiDragProxy

function XUiPanelLineChapter:Ctor(uiRoot, ui, chapterTemplate)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot
    self.ChapterTemplate = chapterTemplate
    self.StageGroup = {}
    self.GridTreasureList = {}

    XTool.InitUiObject(self)
    
    XUiHelper.RegisterClickEvent(self, self.BtnTreasureBg, self.OnBtnTreasureBgClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTreasure, self.OnBtnTreasureClick)

    self.RedPointId = XRedPointManager.AddRedPointEvent(self.ImgRedProgress, self.OnCheckRewards, self, { XRedPointConditions.Types.CONDITION_NEWCHARACT_TREASURE }, chapterTemplate.Id, false)
    -- 初始化prefab组件
end

function XUiPanelLineChapter:OnShow(delay)
    self.GameObject:SetActiveEx(false)
    self:Refresh()
    self.AnimTimer = XScheduleManager.ScheduleOnce(function()
        self.GameObject:SetActiveEx(true)
        --self.AnimEnable:PlayTimelineAnimation()
        self.LineEnable:PlayTimelineAnimation()
        for _, v in ipairs(self.ActStages) do
            v.IconEnable:PlayTimelineAnimation()
        end
    end, delay or 1000)
    self:UpdateChapterStars()
    if self.PaneStageList and self.NeedReset then
        self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    else
        self.NeedReset = true
    end
    -- self.PanelTreasure.gameObject:SetActiveEx(false)
end

function XUiPanelLineChapter:OnHide()
    self.GameObject:SetActiveEx(true)
    self.LineDisable:PlayTimelineAnimation()
    for _, v in ipairs(self.ActStages) do
        v.IconDisable:PlayTimelineAnimation()
    end
    if self.AnimTimer then
        XScheduleManager.UnSchedule(self.AnimTimer)
        self.AnimTimer = nil
    end
end

-- 更新刷新
function XUiPanelLineChapter:Refresh()
    local dragProxy = self.PaneStageList:GetComponent(typeof(XUguiDragProxy))
    if not dragProxy then
        dragProxy = self.PaneStageList.gameObject:AddComponent(typeof(XUguiDragProxy))
    end
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))

    self.ActStageIds = self.ChapterTemplate.StageId
    --XDataCenter.FubenNewCharActivityManager.GetAvailableStageIds(self.ChapterTemplate.Id)
    -- 线条处理
    self:HandleStageLines()
    -- 关卡处理
    self:HandleStages()
    -- 界面信息
    -- self:SwitchFestivalBg(chapterTemplate)
end

function XUiPanelLineChapter:HandleStages()
    self.ActStages = {}
    for i = 1, #self.ActStageIds do
        local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i))
        if not itemStage then
            XLog.Error("XUiPanelLineChapter:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end
        -- 组件初始化
        -- XLog.Warning(self.ActStageIds[i], isOpen, itemStage)
        self.StageGroup[i] = itemStage
        self.ActStages[i] = XUiNewCharStageItem.New(self, itemStage)
        itemStage.gameObject:SetActiveEx(true)
        self.ActStages[i]:UpdateNode(self.ChapterTemplate.Id, self.ActStageIds[i], i)
    end
    self:UpdateNodeLines()
end

function XUiPanelLineChapter:HandleStageLines()
    self.ActStageLine = {}
    for i = 2, #self.ActStageIds do
        local itemLine = self.PanelStageContent:Find(string.format("Line%d", i-1))
        if not itemLine then
            XLog.Error("XUiPanelLineChapter:SetUiData() error: prefab not found a child name:" .. string.format("Line%d", i))
            return
        end
        itemLine.gameObject:SetActiveEx(false)
        self.ActStageLine[i] = itemLine
    end
end

-- 更新节点线条
function XUiPanelLineChapter:UpdateNodeLines()
    if not self.ChapterTemplate or not self.ActStageIds then return end
    local stageLength = #self.ActStageIds
    for i = 2, stageLength do
        --local isOpen = XDataCenter.FubenNewCharActivityManager.CheckStageOpen(self.ActStageIds[i])
        self:SetStageLineActive(i, true)
        --if isOpen then
        --    self.LastOpenStage = i
        --end
    end
    self:SetStageLineActive(1, true)
end

function XUiPanelLineChapter:SetStageLineActive(index, isActive)
    if self.ActStageLine[index] then
        self.ActStageLine[index].gameObject:SetActiveEx(isActive)
    end
end

-- 选中关卡
function XUiPanelLineChapter:UpdateNodesSelect(stageId)
    local stageIds = self.ActStageIds
    for i = 1, #stageIds do
        if self.ActStages[i] then
            self.ActStages[i]:SetNodeSelect(stageIds[i] == stageId)
        end
    end
end

-- 取消选中
function XUiPanelLineChapter:ClearNodesSelect()
    for i = 1, #self.ActStageIds do
        if self.ActStages[i] then
            self.ActStages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end

function XUiPanelLineChapter:GetStages()
    local stageIds = {}
    for i = 1, #self.ChapterTemplate.StageId do
        stageIds[i] = self.ChapterTemplate.StageId[i]
    end
    return stageIds
end

-- 打开剧情，战斗详情
function XUiPanelLineChapter:OpenStageDetails(stageId, festivalId)
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(festivalId, stageId)
    local detailType = XDataCenter.FubenFestivalActivityManager.StageFuben
    if not fStage then
        self.IsOpenDetails = true
        self.StageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local stageType = self.StageCfg.StageType
        if stageType == XFubenConfigs.STAGETYPE_FIGHT or stageType == XFubenConfigs.STAGETYPE_FIGHTEGG then
            detailType = XDataCenter.FubenFestivalActivityManager.StageFuben
        elseif stageType == XFubenConfigs.STAGETYPE_STORY or stageType == XFubenConfigs.STAGETYPE_STORYEGG then
            detailType = XDataCenter.FubenFestivalActivityManager.StageStory
        end
    else
        self.FStage = fStage
        self.IsOpenDetails = true
        detailType = self.FStage:GetStageShowType()
    end

    if detailType == XDataCenter.FubenFestivalActivityManager.StageFuben then
        XLuaUiManager.Open("UiFubenExploreDetail", self, self.FStage and self.FStage:GetStageCfg() or self.StageCfg, function()
                if self.CurChapterGrid then
                    self.CurChapterGrid:ScaleBack()
                end
                self:CloseStageDetails()
            end, XDataCenter.FubenManager.StageType.ActivtityBranch)
    end
    if self.AssetPanel then
        self.AssetPanel.GameObject:SetActiveEx(false)
    end
    self.PanelStageContentRaycast.raycastTarget = false
end

-- 关闭剧情，战斗详情
function XUiPanelLineChapter:CloseStageDetails()
    self.IsOpenDetails = false
    self.PanelStageContentRaycast.raycastTarget = true
    self:ClearNodesSelect()
    --self:ReopenAssetPanel()
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
end

function XUiPanelLineChapter:OnBntCloseDetailClick()
    self:CloseStageDetails()
end

function XUiPanelLineChapter:OnDragProxy(dragType)
    if self.IsOpenDetails and dragType == 0 then
        self:CloseStageDetails()
    end
end

function XUiPanelLineChapter:PlayScrollViewMove(gridTransform)
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    local gridRect = gridTransform:GetComponent("RectTransform")
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridRect.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiPanelLineChapter:MoveIntoStage(stageIndex)
    local gridRect = self.StageGroup[stageIndex]
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX > CS.XResolutionManager.OriginWidth / 2 then
        local tarPosX = (CS.XResolutionManager.OriginWidth / 4) - gridRect.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
            self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        end)
    end
end

function XUiPanelLineChapter:EndScrollViewMove()
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    self:ReopenAssetPanel()
end

-- 背景
function XUiPanelLineChapter:SwitchFestivalBg(festivalTemplate)
    if not festivalTemplate or not festivalTemplate.MainBackgound then return end
    self.RImgFestivalBg:SetRawImage(festivalTemplate.MainBackgound)
end

-- 是否显示红点
function XUiPanelLineChapter:OnCheckRewards(count)
    self.ImgRedProgress.gameObject:SetActiveEx(count >= 0)
end

function XUiPanelLineChapter:UpdateChapterStars()
    local curStars
    local totalStars
    curStars, totalStars = XDataCenter.FubenNewCharActivityManager.GetStarProgressById(self.ChapterTemplate.Id)

    self.ImgJindu.fillAmount = totalStars > 0 and curStars / totalStars or 0
    self.ImgJindu.gameObject:SetActiveEx(true)
    self.TxtStarNum.text = CS.XTextManager.GetText("Fract", curStars, totalStars)

    local received = true
    for _, v in pairs(self.ChapterTemplate.TreasureId) do
        if not XDataCenter.FubenNewCharActivityManager.IsTreasureGet(v) then
            received = false
            break
        end
    end
    self.ImgLingqu.gameObject:SetActiveEx(received)

    self.PanelBfrtTask.gameObject:SetActiveEx(false)
    self.PanelDesc.gameObject:SetActiveEx(true)
    XRedPointManager.Check(self.RedPointId, self.ChapterTemplate.Id)
end

function XUiPanelLineChapter:OnBtnTreasureBgClick()
    self.UiRoot.TopControl.gameObject:SetActiveEx(true)
    self.TreasureDisable:PlayTimelineAnimation(function()
            self.PanelTreasure.gameObject:SetActiveEx(false)
        end)
end

function XUiPanelLineChapter:OnBtnTreasureClick()
    self.UiRoot.TopControl.gameObject:SetActiveEx(false)
    self:InitTreasureGrade()
    self.PanelTreasure.gameObject:SetActiveEx(true)
    self.TreasureEnable:PlayTimelineAnimation()
end

-- 初始化 treasure grade grid panel，填充数据
function XUiPanelLineChapter:InitTreasureGrade()
    local baseItem = self.GridTreasureGrade
    self.GridTreasureGrade.gameObject:SetActiveEx(false)

    -- 先把所有的格子隐藏
    for j = 1, #self.GridTreasureList do
        self.GridTreasureList[j].GameObject:SetActiveEx(false)
    end

    local targetList = self.ChapterTemplate.TreasureId
    if not targetList then
        return
    end
    -- XLog.Warning(targetList)

    local gridCount = #targetList

    for i = 1, gridCount do
        local grid = self.GridTreasureList[i]

        if not grid then
            local item = CS.UnityEngine.Object.Instantiate(baseItem)  -- 复制一个item
            grid = XUiGridTreasureGrade.New(self.UiRoot, item, XDataCenter.FubenManager.StageType.NewCharAct)
            grid.Transform:SetParent(self.PanelGradeContent, false)
            self.GridTreasureList[i] = grid
        end
        
        local treasureCfg = XFubenNewCharConfig.GetTreasureCfg(targetList[i])
        local curStars = XDataCenter.FubenNewCharActivityManager.GetStarProgressById(self.ChapterTemplate.Id)
        grid:UpdateGradeGrid(curStars, treasureCfg, self.ChapterTemplate.Id)

        grid:InitTreasureList()
        grid.GameObject:SetActiveEx(true)
    end
end

return XUiPanelLineChapter