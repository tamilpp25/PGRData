local XUiStageGrid = require("XUi/XUiCourse/ExamStage/XUiStageGrid")
local XUiGridRewardItem = require("XUi/XUiCourse/XLesson/XUiGridRewardItem")

--战斗执照-执照关卡界面
local XUiCourseManagement = XLuaUiManager.Register(XLuaUi, "UiCourseManagement")

function XUiCourseManagement:OnAwake()
    self.StageGridList = {}
    self.RectTransform = self.Transform:GetComponent("RectTransform")
    self:RegisterButtonEvent()
end

function XUiCourseManagement:OnStart(chapterId)
    self.RewardGrids = {}
    self:SetChapterId(chapterId)
end

function XUiCourseManagement:OnEnable()
    self:Refresh()
    
    --策划调整为不自动关闭
    --XDataCenter.CourseManager.CheckOpenLiveWell(handler(self, self.Close))
    XDataCenter.CourseManager.CheckOpenLiveWell()

    XEventManager.AddEventListener(XEventId.EVENT_COURSE_DATA_NOTIFY, self.DataNotifyFunc, self)
end

function XUiCourseManagement:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_COURSE_DATA_NOTIFY, self.DataNotifyFunc, self)
end

function XUiCourseManagement:Refresh()
    local chapterId = self.ChapterId

    --标题
    self.TxtTitle.text = XCourseConfig.GetCourseChapterName(chapterId)
    --进度
    local totalPointCount = XCourseConfig.GetCourseChapterClearPoint(chapterId)
    local curPointCount = XDataCenter.CourseManager.GetChapterCurPoint(chapterId)
    self.TxtPercent.text = string.format(XCourseConfig.GetCourseClientConfig("ExamStagePercent").Values[1], curPointCount, totalPointCount)
    --关卡列表
    local stageIdList = XCourseConfig.GetCourseChapterStageIdsById(chapterId)
    local asset = XCourseConfig.GetCourseClientConfig("ExamManagementGridPrefab").Values[1]
    --local jumpStageCb = handler(self, self.JumpStage)
    local clickStageCb = handler(self, self.ClickStageGrid)
    local stageGrid, eggStage
    for index, stageId in ipairs(stageIdList) do
        stageGrid = self["Stage" .. index]
        eggStage = self["EggStage" .. index]
        if eggStage then
            local prefab = eggStage:LoadPrefab(asset)
            stageGrid = self.StageGridList[index]
            if not stageGrid then
                stageGrid = XUiStageGrid.New(prefab, index, self, clickStageCb)
                self.StageGridList[index] = stageGrid
            end
            stageGrid:Refresh(stageId, chapterId)
        end
        if stageGrid then
            stageGrid.GameObject:SetActiveEx(true)
        end
    end
    --隐藏多余的控件
    local index = #stageIdList + 1
    stageGrid = self["Stage" .. index]
    while not XTool.UObjIsNil(stageGrid) do
        stageGrid.gameObject:SetActiveEx(false)
        index = index + 1
        stageGrid = self["Stage" .. index]
    end
    self:RefreshReward()
    self:CheckRewardRedDot()
end

-- 选中一个 stage grid
function XUiCourseManagement:ClickStageGrid(grid)
    local curGrid = self.CurStageGrid
    if curGrid and curGrid:GetStageId() == grid:GetStageId() then
        return
    end

    if curGrid then
        curGrid:SetSelectActive(false)
    end

    -- 滚动容器自由移动
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted

    -- 选中当前选择
    self.CurStageGrid = grid

    self.BtnCloseDetail.gameObject:SetActiveEx(true)
    self:OpenOneChildUi("UiCoursePrepare", handler(self, self.CancelSelect))
    self.PaneStageList.enabled = false
    -- 面板移动
    self:PlayScrollViewMove(grid)
    
    -- 选中回调
    if self.ShowStageCb then
        self.ShowStageCb(grid.StageId)
    end
end

function XUiCourseManagement:PlayScrollViewMove(grid)
    local stage = self["Stage" .. grid:GetIndex()]
    if XTool.UObjIsNil(stage) then
        return
    end

    -- 动画
    local gridTfPosX = stage.localPosition.x
    local diffX = gridTfPosX + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridTfPosX
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiCourseManagement:JumpStage(stageId)
    local chapterId = XCourseConfig.GetChapterIdByStageId(stageId)
    if not XTool.IsNumberValid(chapterId) then
        return
    end
    self:SetChapterId(chapterId)
    self:Refresh()
end

function XUiCourseManagement:RegisterButtonEvent()
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
    self:BindExitBtns()
    -- ScrollRect的点击和拖拽会触发关闭详细面板
    --self:RegisterClickEvent(self.PaneStageList, handler(self, self.CancelSelect))
    self:RegisterClickEvent(self.BtnCloseDetail, self.CancelSelect)
    --local dragProxy = self.PaneStageList.gameObject:AddComponent(typeof(CS.XUguiDragProxy))
    --dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
    self.PaneStageList.gameObject:AddComponent(typeof(CS.UnityEngine.UI.XEmpty4Raycast))
    
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)
    self:RegisterClickEvent(self.BtnTreasureBg, self.OnClosePanelReward)
    self.BtnTanchuangClose.CallBack = function() self:OnClosePanelReward() end
end

function XUiCourseManagement:RefreshReward()
    local curPointCount = XDataCenter.CourseManager.GetChapterCurPoint(self.ChapterId)
    local totalPoint = XCourseConfig.GetTotalStarPointCount(self.ChapterId)
    self.ImgJindu.fillAmount = curPointCount / totalPoint
    self.ImgLingqu.gameObject:SetActiveEx(XDataCenter.CourseManager.CheckRewardAllDraw(self.ChapterId))
    self.TxtStarNum.text = XUiHelper.GetText("Fract", curPointCount, totalPoint)
end

function XUiCourseManagement:OnBtnTreasureClick()
    self:RefreshPanelReward()
    self.PanelTreasure.gameObject:SetActiveEx(true)
end

function XUiCourseManagement:OnClosePanelReward()
    self.PanelTreasure.gameObject:SetActiveEx(false)
end

function XUiCourseManagement:RefreshPanelReward()
    local courseRewardIdList = XCourseConfig.GetRewardIdListByChapterId(self.ChapterId)
    for i, rewardId in ipairs(courseRewardIdList) do
        local grid = self.RewardGrids[i]
        if not grid then
            grid = XUiGridRewardItem.New(XUiHelper.Instantiate(self.GridTreasureGrade, self.PanelGradeContent))
            self.RewardGrids[i] = grid
        end
        grid:RefreshUi(rewardId, self.ChapterId)
    end
    self.GridTreasureGrade.gameObject:SetActiveEx(false)
end

-- 返回滚动容器是否动画回弹
function XUiCourseManagement:CancelSelect()
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
    if self.CurStageGrid then
        self.CurStageGrid:SetSelectActive(false)
        self.CurStageGrid = nil
    end
    self:CloseChildUi("UiCoursePrepare")
    self.PaneStageList.enabled = true
    return self:ScrollRectRollBack()
end

function XUiCourseManagement:OnDragProxy(dragType)
    if dragType == 0 then
        self:OnScrollRectBeginDrag()
    elseif dragType == 2 then
        self:OnScrollRectEndDrag()
    end
end

function XUiCourseManagement:OnScrollRectBeginDrag()
    if self:CancelSelect() then
        self.PaneStageList.enabled = false
    end
end

function XUiCourseManagement:OnScrollRectEndDrag()
    self.PaneStageList.enabled = true
end

function XUiCourseManagement:ScrollRectRollBack()
    -- 滚动容器回弹
    local width = self.RectTransform.rect.width
    local innerWidth = self.PanelStageContent.rect.width
    innerWidth = innerWidth < width and width or innerWidth
    local diff = innerWidth - width
    local tarPosX
    if self.PanelStageContent.localPosition.x < -width / 2 - diff then
        tarPosX = -width / 2 - diff
    elseif self.PanelStageContent.localPosition.x > -width / 2 then
        tarPosX = -width / 2
    else
        self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        return false
    end

    self:PlayScrollViewMoveBack(tarPosX)
    return true
end

function XUiCourseManagement:PlayScrollViewMoveBack(tarPosX)
    local tarPos = self.PanelStageContent.localPosition
    tarPos.x = tarPosX
    XLuaUiManager.SetMask(true)

    XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
        self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        XLuaUiManager.SetMask(false)
    end)
end

function XUiCourseManagement:SetChapterId(chapterId)
    self.ChapterId = chapterId
end

function XUiCourseManagement:CheckRewardRedDot()
    local chapterId = self.ChapterId
    self.ImgRedProgress.gameObject:SetActiveEx(XDataCenter.CourseManager.CheckChapterRewardReddot(chapterId))
end

function XUiCourseManagement:DataNotifyFunc()
    self:RefreshReward()
    self:CheckRewardRedDot()
end

function XUiCourseManagement:Close()
    if self.PanelTreasure.gameObject.activeSelf then
        self:OnClosePanelReward()
        return
    end
    self.Super.Close(self)
end 