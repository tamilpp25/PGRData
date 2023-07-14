local XUiExpeditionStageDetailComponent = require("XUi/XUiExpedition/MainPage/XUiExpeditionStageDetailComponent")
--虚像地平线章节关卡组件
local XUiExpeditionChapterComponent = XClass(nil, "XUiExpeditionChapterComponent")
function XUiExpeditionChapterComponent:Ctor(rootUi, ui, difficulty)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = self.Transform:GetComponent("RectTransform")
    self.GridStageList = {}
    self.LineList = {}
    self.Difficulty = difficulty
    self:InitUi()
    CsXUiHelper.RegisterClickEvent(self.ScrollRect, handler(self, self.CancelSelect))
    local dragProxy = self.ScrollRect.gameObject:AddComponent(typeof(CS.XUguiDragProxy))
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
end

function XUiExpeditionChapterComponent:OnDragProxy(dragType)
    if dragType == 0 then
        self:OnScrollRectBeginDrag()
    elseif dragType == 2 then
        self:OnScrollRectEndDrag()
    end
end

function XUiExpeditionChapterComponent:OnScrollRectBeginDrag()
    if self:CancelSelect() then
        self.ScrollRect.enabled = false
    end
end

function XUiExpeditionChapterComponent:OnScrollRectEndDrag()
    self.ScrollRect.enabled = true
end

-- 返回滚动容器是否动画回弹
function XUiExpeditionChapterComponent:CancelSelect()
    if not self.StageSelected then
        return false
    end
    self.StageSelected:CancelSelect()
    self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    self.StageSelected = nil
    return self:ScrollRectRollBack()
end

function XUiExpeditionChapterComponent:InitUi()
    self.PanelStageContent = XUiHelper.TryGetComponent(self.Transform, "PaneStageList/ViewPort/PanelStageContent", "RectTransform")
    self.BoundSizeFitter = XUiHelper.TryGetComponent(self.Transform, "PaneStageList/ViewPort/PanelStageContent", "XBoundSizeFitter")
    self.ScrollRect = XUiHelper.TryGetComponent(self.Transform, "PaneStageList", "ScrollRect")
    -- 连线
    for i = 1, self.PanelStageContent.transform.childCount do
        if not self.LineList[i] then
            local line = self.PanelStageContent.transform:Find("Line" .. i)
            self.LineList[i] = not XTool.UObjIsNil(line) and line
        end
    end
end

function XUiExpeditionChapterComponent:ScrollRectRollBack()
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

function XUiExpeditionChapterComponent:PlayScrollViewMoveBack(tarPosX)
    local tarPos = self.PanelStageContent.localPosition
    tarPos.x = tarPosX
    XLuaUiManager.SetMask(true)

    XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
            XLuaUiManager.SetMask(false)
        end)
end

function XUiExpeditionChapterComponent:GoToLastStage()
    local currentIndex = self.Chapter:GetCurrentIndexByDifficulty(self.Difficulty)
    local grid = self.GridStageList[currentIndex]
    if not grid then
        return
    end
    local gridTf = grid.Parent.gameObject:GetComponent("RectTransform")
    local posX = gridTf.localPosition.x - self.RectTransform.rect.width / 2
    self.ScrollRect.horizontalNormalizedPosition = 0
    self.ScrollRect.horizontalNormalizedPosition = posX / (1 * self.ScrollRect.content.rect.width - self.RectTransform.rect.width)
end

function XUiExpeditionChapterComponent:RefreshData()
    if not self.Chapter then self.Chapter = XDataCenter.ExpeditionManager.GetCurrentChapter() end
    self.Stages = self.Chapter:GetStagesByDifficulty(self.Difficulty)
    self:SetStageList()
    self:GoToLastStage()
end

function XUiExpeditionChapterComponent:SetStageList()
    if not self.Stages then
        XLog.Error("虚像地平线章节数据为空！章节Id : " .. tostring(self.ChapterId))
        return
    end
    for i = 1, #self.Stages do
        if self.Stages[i]:GetIsUnlock() then
            local grid = self.GridStageList[i]
            if not grid then
                --没有关卡预制体，则加载预制体
                grid = self:CreateNewStageGrid(self.Stages[i], i)
                self.GridStageList[i] = grid
            end
            grid:RefreshData(self.Stages[i])
            grid.Transform.parent.gameObject:SetActive(true)
            self:SetLineActive(i, true)
        end
    end
    local activeStageCount = #self.GridStageList
    for i = activeStageCount + 1, self.PanelStageContent.transform.childCount do
        local parent = self.PanelStageContent.transform:Find("Stage" .. i)
        if parent then
            parent.gameObject:SetActive(false)
        end
        self:SetLineActive(i, false)
    end
    -- 移动至ListView正确的位置
    if self.BoundSizeFitter then
        self.BoundSizeFitter:SetLayoutHorizontal()
    end
end

-- 创建新关卡预制体
function XUiExpeditionChapterComponent:CreateNewStageGrid(eStage, stageIndex)
    local parent = self.PanelStageContent.transform:Find(string.format("Stage%d", stageIndex))
    if not parent then
        XLog.Error("XUiExpeditionChapterComponent:CreateNewStageGrid error: prefab not found a child name " .. string.format("Stage%d", stageIndex))
        return
    end
    local prefab = parent:LoadPrefab(eStage:GetPrefabPath())
    local grid = XUiExpeditionStageDetailComponent.New(self, self.RootUi, prefab, eStage:GetStageType())
    return grid
end

function XUiExpeditionChapterComponent:SetLineActive(index, active)
    local line = self.LineList[index - 1]
    if line then
        line.gameObject:SetActive(active)
    end
end

function XUiExpeditionChapterComponent:Show()
    if self.GameObject.activeSelf == true then return end
    self.GameObject:SetActive(true)
end

function XUiExpeditionChapterComponent:Hide()
    if not self.GameObject:Exist() or self.GameObject.activeSelf == false then return end
    self.GameObject:SetActive(false)
end

function XUiExpeditionChapterComponent:PlayScrollViewMove(grid)
    -- 动画
    local gridTf = grid.Parent.gameObject:GetComponent("RectTransform")
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

-- 选中一个 stage grid
function XUiExpeditionChapterComponent:ClickStage(stageClick)
    local stageSelected = self.StageSelected
    if stageSelected and stageSelected.EStage:GetStageId() == stageClick.EStage:GetStageId() then
        return false
    end
    if not stageClick.EStage:GetIsUnlock() then
        XUiManager.TipMsg(XDataCenter.FubenManager.GetFubenOpenTips(stageClick.EStage:GetStageId()))
        return false
    end
    if stageSelected then
        stageSelected:CancelSelect()
    end
    stageClick:SetSelect()
    -- 滚动容器自由移动
    self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    -- 面板移动
    self:PlayScrollViewMove(stageClick)
    self.StageSelected = stageClick
    return true
end
return XUiExpeditionChapterComponent