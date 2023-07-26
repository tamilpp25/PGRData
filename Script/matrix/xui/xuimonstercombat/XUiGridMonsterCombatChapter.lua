local XUiGridMonsterCombatStage = require("XUi/XUiMonsterCombat/XUiGridMonsterCombatStage")

---@class XUiGridMonsterCombatChapter
---@field PaneStageList UnityEngine.RectTransform
---@field BoundSizeFitter XBoundSizeFitter
---@field ScrollRect UnityEngine.UI.ScrollRect
---@field GridStageParentList table<number, UnityEngine.Transform>
---@field GridStageList table<number, XUiGridMonsterCombatStage>
---@field CurStageGrid XUiGridMonsterCombatStage
---@field AnimEnable UnityEngine.RectTransform
local XUiGridMonsterCombatChapter = XClass(nil, "XUiGridMonsterCombatChapter")

local MAX_STAGE_COUNT = XUiHelper.GetClientConfig("MonsterCombatStageMaxCount", XUiHelper.ClientConfigType.Int)

function XUiGridMonsterCombatChapter:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.GridStageList = {}
    self.GridStageParentList = {}
    self.LineList = {}

    self:InitUiView()
end

function XUiGridMonsterCombatChapter:InitUiView()
    -- ScrollRect的点击和拖拽会触发关闭详细面板
    XUiHelper.RegisterClickEvent(self, self.ScrollRect, self.CancelSelect)

    ---@type XUguiDragProxy
    local dragProxy = self.PaneStageList:GetComponent(typeof(CS.XUguiDragProxy))
    if not dragProxy then
        dragProxy = self.PaneStageList.gameObject:AddComponent(typeof(CS.XUguiDragProxy))
    end
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))

    -- 关卡父节点 和 关卡连线
    self.GridStageParentList = {}
    self.LineList = {}
    for i = 1, MAX_STAGE_COUNT do
        local parent = XUiHelper.TryGetComponent(self.PanelStageContent, string.format("Stage%d", i))
        if parent then
            self.GridStageParentList[i] = parent
        end
        local line = XUiHelper.TryGetComponent(self.PanelStageContent, string.format("Line%d", i))
        if line then
            self.LineList[i] = line
        end
    end
end

function XUiGridMonsterCombatChapter:Refresh(data)
    self.ChapterId = data.ChapterId
    self.HideStageDetail = data.HideStageDetail
    self.ShowStageDetail = data.ShowStageDetail

    self.ChapterEntity = XDataCenter.MonsterCombatManager.GetChapterEntity(self.ChapterId)
    self.StageIdList = self.ChapterEntity:GetStageIds()
    self:UpdateStageList()
    -- 播放动画
    self.AnimEnable:PlayTimelineAnimation()
end

-- 刷新关卡，关卡需要全部显示出来
function XUiGridMonsterCombatChapter:UpdateStageList()
    for i = 1, #self.StageIdList do
        local stageId = self.StageIdList[i]
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        local grid = self.GridStageList[i]
        if not grid then
            local uiName = "GridMonsterCombatStage"
            uiName = stageCfg.StageGridStyle and string.format("%s%s", uiName, stageCfg.StageGridStyle) or uiName

            local parent = self.GridStageParentList[i]
            local prefabName = XMonsterCombatConfigs.GetMonsterCombatStagePrefabByKey(uiName)
            local prefab = parent:LoadPrefab(prefabName)

            grid = XUiGridMonsterCombatStage.New(prefab, self, handler(self, self.ClickStageGrid))
            self.GridStageList[i] = grid
            parent.gameObject:SetActiveEx(true)
        end
        grid:Refresh(stageId)
        self:SetLineActive(i, true)
    end

    local activeStageCount = #self.GridStageList
    for i = activeStageCount + 1, MAX_STAGE_COUNT do
        local parent = self.GridStageParentList[i]
        if parent then
            parent.gameObject:SetActiveEx(false)
        end
        self:SetLineActive(i, false)
    end

    if self.BoundSizeFitter then
        self.BoundSizeFitter:SetLayoutHorizontal()
    end
end

function XUiGridMonsterCombatChapter:SetLineActive(index, active)
    local line = self.LineList[index]
    if line then
        line.gameObject:SetActiveEx(active)
    end
end

function XUiGridMonsterCombatChapter:GoToStage(index)
    local gridTf = self.GridStageParentList[index]
    local posX = gridTf.localPosition.x - self.PaneStageList.rect.width / 2
    self.ScrollRect.horizontalNormalizedPosition = 0
    self.ScrollRect.horizontalNormalizedPosition = posX / (1 * self.ScrollRect.content.rect.width - self.PaneStageList.rect.width)
end

---@param grid XUiGridMonsterCombatStage
function XUiGridMonsterCombatChapter:ClickStageGrid(grid)
    local curGrid = self.CurStageGrid
    if curGrid and curGrid.StageId == grid.StageId then
        return
    end
    -- 选中回调
    if self.ShowStageDetail then
        self.ShowStageDetail(grid.StageId)
    end
    -- 取消上一次的选择
    if curGrid then
        curGrid:SetStageSelect(false)
    end
    -- 选中当前选择
    grid:SetStageSelect(true)
    local isContain, containIndex = table.contains(self.StageIdList, grid.StageId)
    if isContain then
        -- 滚动容器自由移动
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        -- 面板移动
        self:PlayScrollViewMove(containIndex)
    end
    self.CurStageGrid = grid
end

function XUiGridMonsterCombatChapter:CancelSelect()
    if not self.CurStageGrid then
        return false
    end
    -- 取消当前选择
    self.CurStageGrid:SetStageSelect(false)
    self.CurStageGrid = nil
    -- 取消回调
    if self.HideStageDetail then
        self.HideStageDetail()
    end
    return self:ScrollRectRollBack()
end

-- 移到动画
function XUiGridMonsterCombatChapter:PlayScrollViewMove(index)
    local gridTf = self.GridStageParentList[index]
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

-- 滚动容器回弹
function XUiGridMonsterCombatChapter:ScrollRectRollBack()
    local width = self.PaneStageList.rect.width
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

function XUiGridMonsterCombatChapter:PlayScrollViewMoveBack(tarPosX)
    local tarPos = self.PanelStageContent.localPosition
    tarPos.x = tarPosX
    XLuaUiManager.SetMask(true)
    XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        XLuaUiManager.SetMask(false)
    end)
end

function XUiGridMonsterCombatChapter:OnDragProxy(dragType)
    if dragType == 0 then
        self:OnScrollRectBeginDrag()
    elseif dragType == 2 then
        self:OnScrollRectEndDrag()
    end
end

function XUiGridMonsterCombatChapter:OnScrollRectBeginDrag()
    if self:CancelSelect() then
        self.ScrollRect.enabled = false
    end
end

function XUiGridMonsterCombatChapter:OnScrollRectEndDrag()
    self.ScrollRect.enabled = true
end

function XUiGridMonsterCombatChapter:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiGridMonsterCombatChapter:OnDisable()
    if self.GridStageList then
        for _, v in pairs(self.GridStageList) do
            v:OnDisable()
        end
    end
end

return XUiGridMonsterCombatChapter