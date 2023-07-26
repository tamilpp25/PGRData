local XUiLessonStage = require("XUi/XUiCourse/XLesson/XUiLessonStage")

--课程关卡界面的布局
local XUiLessonChapter = XClass(nil, "XUiLessonChapter")

function XUiLessonChapter:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    XUiHelper.RegisterClickEvent(self, self.ScrollRect, self.CancelSelect)

    self.GridStageList = {}
end

function XUiLessonChapter:Refresh(data, moveToUnlock)
    self.HideStageCb = data.HideStageCb
    self.ShowStageCb = data.ShowStageCb
    self.ChapterId = data.ChapterId
    self:SetStageList(moveToUnlock)
end

function XUiLessonChapter:SetStageList(moveToUnlock)
    local stageList = XCourseConfig.GetCourseChapterStageIdsById(self.ChapterId)

    if XTool.IsTableEmpty(stageList) then
        return
    end

    for i = 1, #stageList do
        local stageId = stageList[i]
        local parent = XUiHelper.TryGetComponent(self.PanelStageContent.transform, "Stage" .. i)
        if XTool.IsTableEmpty(self.GridStageList[stageId]) and not XTool.UObjIsNil(parent) then
            local stageShowType = XCourseConfig.GetCourseStageShowTypeByStageId(stageId)
            local prefabName = XCourseConfig.GetStageShowTypePrefabPath(stageShowType)
            local prefab = parent:LoadPrefab(prefabName)
            self.GridStageList[stageId] = XUiLessonStage.New(prefab, self.RootUi, handler(self, self.ClickStageGrid), parent)
        end
        -- 刷新关卡
        self.GridStageList[stageId]:Refresh(stageId, i)
    end
    if moveToUnlock then
        self:MoveToUnlock(stageList)
    end
end

function XUiLessonChapter:Show()
    if self.GameObject.activeSelf == true then
        return
    end
    self.GameObject:SetActiveEx(true)
end

function XUiLessonChapter:Hide()
    if not self.GameObject:Exist() or self.GameObject.activeSelf == false then
        return
    end
    self.GameObject:SetActiveEx(false)
end

-- 选中一个 stage grid
function XUiLessonChapter:ClickStageGrid(grid)
    local curGrid = self.CurStageGrid
    if curGrid and curGrid.StageId == grid.StageId then
        return
    end

    -- 滚动容器自由移动
    self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted

    -- 选中当前选择
    self.CurStageGrid = grid

    -- 面板移动
    self:PlayScrollViewMove(grid)
    
    -- 选中回调
    if self.ShowStageCb then
        self.ShowStageCb(grid.StageId)
        self:RefreshScrollEnable(false)
    end
end

function XUiLessonChapter:PlayScrollViewMove(grid)
    -- 动画
    local gridTfPosX = grid:GetParentLocalPosX()
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

-- 返回滚动容器是否动画回弹
function XUiLessonChapter:CancelSelect()
    if not self.CurStageGrid then
        return false
    end

    self.CurStageGrid = nil

    if self.HideStageCb then
        self:RefreshScrollEnable(true)
        self.HideStageCb()
    end
    return self:ScrollRectRollBack()
end

function XUiLessonChapter:ScrollRectRollBack()
    -- 滚动容器回弹
    local width = self.GameObject:GetComponent("RectTransform").rect.width
    local innerWidth = self.PanelStageContent.rect.width
    innerWidth = innerWidth < width and width or innerWidth
    local diff = innerWidth - width
    local tarPosX
    if self.PanelStageContent.localPosition.x < -width / 2 - diff then
        tarPosX = -width / 2 - diff
    elseif self.PanelStageContent.localPosition.x > -width / 2 then
        tarPosX = -width / 2
    else
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        return false
    end

    self:PlayScrollViewMoveBack(tarPosX)
    return true
end

function XUiLessonChapter:PlayScrollViewMoveBack(tarPosX)
    local tarPos = self.PanelStageContent.localPosition
    tarPos.x = tarPosX
    XLuaUiManager.SetMask(true)

    XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        XLuaUiManager.SetMask(false)
    end)
end

function XUiLessonChapter:MoveToUnlock(stageList)
    if XTool.IsTableEmpty(stageList) then
        return
    end
    local index, id
    for i, stageId in ipairs(stageList) do
        local unlock = XDataCenter.CourseManager.CheckStageIsOpen(stageId)
        if unlock then
            index = i
            id = stageId
        else
            break
        end
    end
    if not XTool.IsNumberValid(index) then
        return
    end
    local grid = self.GridStageList[id]
    if not (index == #stageList and XDataCenter.CourseManager.CheckStageIsOpen(id)) then
        grid:RefreshEffect(true)
    end
    
    if index > 1 then
        self:PlayScrollViewMove(grid)
    end
   
end

function XUiLessonChapter:SelectDefaultStage(stageId)
    local grid = self.GridStageList[stageId]
    if not grid then
        return
    end
    self:ClickStageGrid(grid)
end

function XUiLessonChapter:RefreshScrollEnable(enable)
    self.ScrollRect.enabled = enable
end

return XUiLessonChapter