local XUiGridStageSpecialTrain = require("XUi/XUiSummerEpisode/XUiGridStageSpecialTrain")

local XUiSummerEpisodeChapter = XClass(nil, "XUiSummerEpisodeChapter")

local MAX_STAGE_COUNT = CS.XGame.ClientConfig:GetInt("MainLineStageMaxCount")

function XUiSummerEpisodeChapter:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageList = {}
    self.GridStageList = {}
    self.LineList = {}

    XTool.InitUiObject(self)

    -- ScrollRect的点击和拖拽会触发关闭详细面板
    CsXUiHelper.RegisterClickEvent(self.ScrollRect, handler(self, self.CancelSelect))
    local dragProxy = self.ScrollRect.gameObject:AddComponent(typeof(CS.XUguiDragProxy))
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))

    --初始化StageUI
    for i = 1, 3, 1 do
        self.StageList[i] = self["Stage" .. i]
        self.GridStageList[i] = XUiGridStageSpecialTrain.New(self["StageGrid" .. i], self, self.RootUi)
        self.GridStageList[i].Parent = self.StageList[i]
        self.StageList[i].gameObject:SetActiveEx(false)
    end

end

function XUiSummerEpisodeChapter:SetupChapterStage(chapterData)
    self.ChapterData = chapterData
    self.StageIds = chapterData.StageIds

    for i, v in ipairs(self.StageIds) do
        local grid = self.GridStageList[i]
        if grid then
            grid:Refresh(v, chapterData, i)
            self.StageList[i].gameObject:SetActiveEx(true)
        end
    end

    self.ScrollRect.horizontalNormalizedPosition = 0
end


function XUiSummerEpisodeChapter:OnDragProxy(dragType)
    if dragType == 0 then
        self:OnScrollRectBeginDrag()
    elseif dragType == 2 then
        self:OnScrollRectEndDrag()
    end
end

function XUiSummerEpisodeChapter:OnScrollRectBeginDrag()
    if self:CancelSelect() then
        self.ScrollRect.enabled = false
    end
end

function XUiSummerEpisodeChapter:OnScrollRectEndDrag()
    self.ScrollRect.enabled = true
end

-- 返回滚动容器是否动画回弹
function XUiSummerEpisodeChapter:CancelSelect()
    if not self.CurStageGrid then
        return false
    end

    self.CurStageGrid = nil

    self.RootUi:CloseStageDetail()

    local result = self:ScrollRectRollBack()

    return result
end

-- 滚动容器回弹
function XUiSummerEpisodeChapter:ScrollRectRollBack()

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

--播放回弹动画
function XUiSummerEpisodeChapter:PlayScrollViewMoveBack(tarPosX)
    local tarPos = self.PanelStageContent.localPosition
    tarPos.x = tarPosX
    XLuaUiManager.SetMask(true)

    XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        XLuaUiManager.SetMask(false)
    end)
end


function XUiSummerEpisodeChapter:PlayScrollViewMove(grid)
    -- 动画
    local gridTf = grid.Parent
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


-- 选中关卡
function XUiSummerEpisodeChapter:ClickStageGrid(grid)

    local stageCfg = grid.StageCfg
    local stageInfo = grid.StageInfo

    local curGrid = self.CurStageGrid
    if curGrid and curGrid.StageId == grid.StageId then
        return
    end

    if not stageInfo.Unlock then
        XUiManager.TipMsg(XDataCenter.FubenManager.GetFubenOpenTips(grid.StageId))
        return
    end


    -- 滚动容器自由移动
    self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    -- 面板移动
    self:PlayScrollViewMove(grid)

    self.CurStageGrid = grid

    self.RootUi:OpenStageDetail(stageCfg)
end



return XUiSummerEpisodeChapter