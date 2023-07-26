local XUiChapterPanelGrid = require("XUi/XUiCourse/ExamMain/XUiChapterPanelGrid")

--战斗执照主界面章节布局
local XUiChapterPanel = XClass(nil, "XUiChapterPanel")

function XUiChapterPanel:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.ChapterIdList = XCourseConfig.GetChapterIdListByStageType(XCourseConfig.SystemType.Exam)
    self:Init()
end

function XUiChapterPanel:Init()
    self.ChapterGridList = {}

    local stage
    local clickCb = handler(self, self.ClickStageGrid)  --点击章节格子回调
    local closeCb = handler(self, self.CancelSelect)     --关闭章节详情回调
    local asset = XCourseConfig.GetCourseClientConfig("ExamChapterPanelGrid").Values[1]
    for index, chapterId in ipairs(self.ChapterIdList) do
        stage = XUiHelper.TryGetComponent(self.PanelStageContent.transform, "Stage" .. index)
        local line = XUiHelper.TryGetComponent(self.PanelStageContent.transform, "Line" .. index - 1)
        local isUnLock = XDataCenter.CourseManager.CheckChapterIsOpen(chapterId)
        if stage then
            local imgDian1 = stage:Find("ImDian1")
            local imgDian2 = stage:Find("ImDian2")
            imgDian1.gameObject:SetActiveEx(isUnLock)
            imgDian2.gameObject:SetActiveEx(not isUnLock)
            local prefab = stage:LoadPrefab(asset)
            table.insert(self.ChapterGridList, XUiChapterPanelGrid.New(prefab, stage, clickCb, closeCb))
        else
            XLog.Error(string.format("XUiChapterPanel 无法找到UiCourseXianDuan上的Stage%d控件，chapterId：%d", index, chapterId))
        end

        if line then
            local disable = line:Find("Disable")
            local enable  = line:Find("Enable")
            disable.gameObject:SetActiveEx(not isUnLock)
            enable.gameObject:SetActiveEx(isUnLock)
        end
    end

    --隐藏多余的控件
    local index = #self.ChapterIdList + 1
    stage = XUiHelper.TryGetComponent(self.PanelStageContent.transform, "Stage" .. index)
    while not XTool.UObjIsNil(stage) do
        stage.gameObject:SetActiveEx(false)
        local line = XUiHelper.TryGetComponent(self.PanelStageContent.transform, "Line" .. index - 1)
        if line then
            line.gameObject:SetActiveEx(false)
        end

        index = index + 1
        stage = XUiHelper.TryGetComponent(self.PanelStageContent.transform, "Stage" .. index)
    end
    
    self.PaneStageList.onValueChanged:AddListener(function(vec2Data) 
        self:OnStageListScroll()
    end)
end

function XUiChapterPanel:Refresh()
    for index, grid in ipairs(self.ChapterGridList) do
        grid:Refresh(self.ChapterIdList[index])
    end
end

--获得滑动列表可视范围的节点对象
function XUiChapterPanel:GetPanelStageContent()
    return self.PanelStageContent
end

function XUiChapterPanel:SetScrollCallBack(cb)
    self.ScrollCallBack = cb
end

function XUiChapterPanel:OnStageListScroll()
    if self.ScrollCallBack then
        self.ScrollCallBack()
    end
end

-- 选中一个 stage grid
function XUiChapterPanel:ClickStageGrid(grid)
    local curGrid = self.CurStageGrid
    if curGrid and curGrid:GetChapterId() == grid:GetChapterId() then
        return
    end

    -- 滚动容器自由移动
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted

    -- 选中当前选择
    self.CurStageGrid = grid

    -- 面板移动
    self:PlayScrollViewMove(grid)
end

local OFFSET = 400  --滑动偏移
function XUiChapterPanel:PlayScrollViewMove(grid)
    -- 动画
    local gridTfPosY = grid:GetParentLocalPosY()
    local diffY = gridTfPosY + self.PanelStageContent.localPosition.y
    if diffY < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffY > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosY = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridTfPosY + OFFSET
        local tarPos = self.PanelStageContent.localPosition
        tarPos.y = tarPosY
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

-- 返回滚动容器是否动画回弹
function XUiChapterPanel:CancelSelect()
    if not self.CurStageGrid then
        return false
    end

    self.CurStageGrid = nil

    return self:ScrollRectRollBack()
end

function XUiChapterPanel:ScrollRectRollBack()
    -- 滚动容器回弹
    local height = self.GameObject:GetComponent("RectTransform").rect.height
    local innerHeight = self.PanelStageContent.rect.height
    innerHeight = innerHeight < height and height or innerHeight
    local diff = innerHeight - height
    local tarPosY
    if self.PanelStageContent.localPosition.y < -height / 2 - diff then
        tarPosY = -height / 2 - diff
    elseif self.PanelStageContent.localPosition.y > -height / 2 then
        tarPosY = -height / 2
    else
        self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        return false
    end

    self:PlayScrollViewMoveBack(tarPosY)
    return true
end

function XUiChapterPanel:PlayScrollViewMoveBack(tarPosY)
    local tarPos = self.PanelStageContent.localPosition
    tarPos.y = tarPosY
    XLuaUiManager.SetMask(true)

    XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
        self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        XLuaUiManager.SetMask(false)
    end)
end

return XUiChapterPanel