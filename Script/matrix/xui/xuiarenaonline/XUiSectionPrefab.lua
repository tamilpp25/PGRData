local XUiSectionPrefab = XClass(nil, "XUiSectionPrefab")
local XUiGridStage = require("XUi/XUiArenaOnline/XUiGridStage")
local XUguiDragProxy = CS.XUguiDragProxy

local MAX_SECTION_COUNT = 10
function XUiSectionPrefab:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self:SetUiData()
end

function XUiSectionPrefab:OnEnable()
    self:Refresh()
end

function XUiSectionPrefab:Refresh()
    self.AnimEnable:PlayTimelineAnimation()
    local sectionCfg = XDataCenter.ArenaOnlineManager.GetCurSectionCfg()
    local chapterCfg = XDataCenter.ArenaOnlineManager.GetCurChapterCfg()
    if not sectionCfg or not chapterCfg then return end

    self.StageGrids = {}
    self.TxtName.text = sectionCfg.Name
    self.TxtLv.text = CS.XTextManager.GetText("ArenaOnlineChapterLevel", chapterCfg.MinLevel, chapterCfg.MaxLevel)
    self:SetStageInfo()
    self:SetTimer()
end

function XUiSectionPrefab:SetUiData()
    self:RegisterClickEvent(self.ScrollRect, handler(self, self.CancelSelect))
    local dragProxy = self.ScrollRect:GetComponent(typeof(XUguiDragProxy))
    if not dragProxy then
        dragProxy = self.ScrollRect.gameObject:AddComponent(typeof(XUguiDragProxy))
    end
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
end

function XUiSectionPrefab:SetStageInfo()
    local sectionData = XDataCenter.ArenaOnlineManager.GetCurSectionData()
    local index = 0
    for _, stageId in pairs(sectionData.Stages) do
        index = index + 1
        local name = "GridStage" .. index
        local go = XUiHelper.TryGetComponent(self.PanelStageContent, name)
        if go then
            self.StageGrids[index] = XUiGridStage.New(go, self.UiRoot, self.PanelStageContent, stageId, function(grid)
                self:ClickStageGrid(grid)
            end)
        end
    end

    for i = index, MAX_SECTION_COUNT do
        local name = "Line" .. i
        local go = XUiHelper.TryGetComponent(self.PanelStageContent, name)
        if go then
            go.gameObject:SetActiveEx(false)
        end
    end

    index = index + 1
    for i = index, MAX_SECTION_COUNT do
        local name = "GridStage" .. i
        local go = XUiHelper.TryGetComponent(self.PanelStageContent, name)
        if go then
            go.gameObject:SetActiveEx(false)
        end
    end
end

function XUiSectionPrefab:SetTimer()
    local sectionCfg = XDataCenter.ArenaOnlineManager.GetCurSectionCfg()
    local endTimeSecond = XDataCenter.ArenaOnlineManager.GetNextRefreshTime()
    local now = XTime.GetServerNowTimestamp()
    if now <= endTimeSecond then
        local activeOverStr = CS.XTextManager.GetText("ArenaOnlineLeftTimeOver")
        self:StopTimer()
        if now <= endTimeSecond then
            self.TxtLeftTime.text = CS.XTextManager.GetText(sectionCfg.LeftTimeDesc, XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.DEFAULT))
        else
            self.TxtLeftTime.text = activeOverStr
        end

        self.Timer = XScheduleManager.ScheduleForever(function()
            now = XTime.GetServerNowTimestamp()
            if now > endTimeSecond then
                self:StopTimer()
                return
            end
            if now <= endTimeSecond then
                self.TxtLeftTime.text = CS.XTextManager.GetText(sectionCfg.LeftTimeDesc, XUiHelper.GetTime(endTimeSecond - now, XUiHelper.TimeFormatType.DEFAULT))
            else
                self.TxtLeftTime.text = activeOverStr
            end
        end, XScheduleManager.SECOND, 0)
    end
end

function XUiSectionPrefab:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiSectionPrefab:OnDestroy()
    self:StopTimer()
end

function XUiSectionPrefab:OnDragProxy(dragType)
    if dragType == 0 then
        self:OnScrollRectBeginDrag()
    elseif dragType == 2 then
        self:OnScrollRectEndDrag()
    end
end

function XUiSectionPrefab:OnScrollRectBeginDrag()
    if self:CancelSelect() then
        self.ScrollRect.enabled = false
    end
end

function XUiSectionPrefab:OnScrollRectEndDrag()
    self.ScrollRect.enabled = true
end

-- 选中一个 stage grid
function XUiSectionPrefab:ClickStageGrid(grid)
    local curGrid = self.CurStageGrid
    if curGrid and curGrid.StageId == grid.StageId then
        return
    end

    -- 选中回调
    if self.ShowStageCb then
        self.ShowStageCb(grid.Stage, grid.ChapterOrderId)
    end

    -- 取消上一个选择
    if curGrid then
        curGrid:SetStageActive()
    end

    -- 选中当前选择
    grid:SetStageSelect()

    -- 滚动容器自由移动
    self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted

    -- 面板移动
    self:PlayScrollViewMove(grid)

    self.CurStageGrid = grid
end

function XUiSectionPrefab:PlayScrollViewMove(grid)
    -- 动画
    local gridTf = grid.GameObject:GetComponent("RectTransform")
    local diffX = gridTf.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridTf.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

-- 返回滚动容器是否动画回弹
function XUiSectionPrefab:CancelSelect()
    if not self.CurStageGrid then
        return false
    end

    self.CurStageGrid:SetStageActive()
    self.CurStageGrid = nil
    self.UiRoot:OnHideDetail()
    return self:ScrollRectRollBack()
end

function XUiSectionPrefab:ScrollRectRollBack()
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
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        return false
    end

    self:PlayScrollViewMoveBack(tarPosX)
    return true
end

function XUiSectionPrefab:PlayScrollViewMoveBack(tarPosX)
    local tarPos = self.PanelStageContent.localPosition
    tarPos.x = tarPosX
    XLuaUiManager.SetMask(true)

    XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        XLuaUiManager.SetMask(false)
    end)
end

function XUiSectionPrefab:RegisterClickEvent(uiNode, func)
    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

return XUiSectionPrefab