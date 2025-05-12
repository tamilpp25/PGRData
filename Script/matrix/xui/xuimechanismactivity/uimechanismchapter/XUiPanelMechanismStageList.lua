---@class XUiPanelMechanismStageList
---@field _Control XMechanismActivityControl
---@field Parent XUiMechanismChapter
local XUiPanelMechanismStageList = XClass(XUiNode, 'XUiPanelMechanismStageList')
local XUiGridMechanismStage = require('XUi/XUiMechanismActivity/UiMechanismChapter/XUiGridMechanismStage')

function XUiPanelMechanismStageList:OnStart()
    self._ChapterId = self.Parent._ChapterId
    self.GridChapter.gameObject:SetActiveEx(false)
    self._StageGrids = {}
    self._StageIdMapIndex = {}
    --关卡滑动窗口的边界值
    self.ScrollLimitX = math.abs(self.ScrollView.content.rect.width / 2 - self.ScrollView.viewport.rect.width / 2)
    self:RegisterClickEvent(self.ScrollView, function()
        self:SetSelectStage(nil)
    end)

    local dragProxy = self.ScrollView.gameObject:AddComponent(typeof(CS.XUguiDragProxy))
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
end

function XUiPanelMechanismStageList:OnEnable()
    self:RefreshStageGrids()
    self:TryFocusStage()
end

function XUiPanelMechanismStageList:RefreshStageGrids()
    -- 先隐藏掉所有实例化的UI关卡
    if not XTool.IsTableEmpty(self._StageGrids) then
        for i, v in ipairs(self._StageGrids) do
            v:Close()
        end
    end
    
    -- 获取最新的可显示的关卡
    self._VisibleStageIds = self._Control:GetVisibleStageListByChapterId(self._ChapterId)
    -- 刷新关卡UI
    if not XTool.IsTableEmpty(self._VisibleStageIds) then
        for i, id in ipairs(self._VisibleStageIds) do
            if self._StageGrids[i] then
                self._StageGrids[i]:Open()
                self._StageGrids[i]:Refresh(id)
            else
                if self['Chapter'..i] then
                    self['Chapter'..i].gameObject:SetActiveEx(true)
                    local type = self._Control:GetStageTypeByStageId(id)
                    local clonedGrid = self:GetStageGridGOByType(type)
                    local cloneObj = CS.UnityEngine.GameObject.Instantiate(clonedGrid, self['Chapter'..i].transform)
                    cloneObj.transform.localPosition = Vector3.zero
                    local grid = XUiGridMechanismStage.New(cloneObj, self, i)
                    grid:Open()
                    grid:Refresh(id)
                    self._StageGrids[i] = grid
                end
            end
            self._StageIdMapIndex[id] = i
        end
    end
    
    local hideIndex = self._VisibleStageIds and #self._VisibleStageIds + 1 or 1

    for i = hideIndex, 100 do
        if self['Chapter'..i] then
            self['Chapter'..i].gameObject:SetActiveEx(false)
        else
            -- 一般UI索引都是连着的。如果中断，那么也不会有后续索引的UI
            break
        end
    end
end

--region -------------------- 滚动视图 --------------------

function XUiPanelMechanismStageList:PlayScrollViewMove(grid)
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


function XUiPanelMechanismStageList:FocusCurStageUI(stageId, isElastic)
    local index = self._StageIdMapIndex[stageId]
    local ctrl = self._StageGrids[index]
    if ctrl then
        local focusX = self._Control:GetMechanismClientConfigNum('UiGridChapterMoveTargetX')
        local tarPosX = focusX - ctrl.Transform.parent.localPosition.x
        self.ScrollView.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        self:PlayScrollViewMoveBack(tarPosX, isElastic)
    end
end

function XUiPanelMechanismStageList:SetScrollViewElastic()
    self.ScrollView.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    self:SetSelectStage(nil)
end

function XUiPanelMechanismStageList:PlayScrollViewMoveBack(tarPosX, isElastic)
    local moveDuration = CS.XGame.ClientConfig:GetFloat('KotodamaActivityStageMoveDuration')
    local tarPos = self.ScrollView.content.localPosition
    tarPos.x = tarPosX

    XLuaUiManager.SetMask(true)
    XUiHelper.DoMove(self.ScrollView.content, tarPos, moveDuration, XUiHelper.EaseType.Sin, function()
        if isElastic then
            self.ScrollView.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        else
            self.ScrollView.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        end
        XLuaUiManager.SetMask(false)
    end)
end

--- 尝试聚焦上一次选中的关卡，若移动会超过滑动窗限度则不强制移动
function XUiPanelMechanismStageList:TryFocusStage()
    local selectIndex = self._Control:GetLastSelectStageIndex(self._ChapterId)
    if XTool.IsNumberValid(selectIndex) then
        local selectGrid = self._StageGrids[selectIndex]
        if selectGrid then
            local halfScreenWidth = self.ScrollView.viewport.rect.width / 2
            local moveMinX = halfScreenWidth
            local moveMaxX = self.ScrollView.content.rect.width - halfScreenWidth
            if selectGrid.Transform.parent.localPosition.x > moveMinX then
                local focusX = self._Control:GetMechanismClientConfigNum('UiGridChapterMoveTargetX')
                local tarPosX = focusX - selectGrid.Transform.parent.localPosition.x
                local fixedPositionX = CS.UnityEngine.Mathf.Clamp(tarPosX, -moveMaxX, -moveMinX)
                self:PlayScrollViewMoveBack(fixedPositionX, true)
            end
        end
    end
end

function XUiPanelMechanismStageList:OnDragProxy(dragType)
    if dragType == 0 then
        self:OnScrollRectBeginDrag()
    end
end

function XUiPanelMechanismStageList:OnScrollRectBeginDrag()
    self:CancelSelect()
end


-- 返回滚动容器是否动画回弹
function XUiPanelMechanismStageList:CancelSelect()
    if not self._SelectedStageGrid then
        return false
    end

    self:SetSelectStage(nil)
    self:SetScrollViewElastic()
    return true
end
--endregion

function XUiPanelMechanismStageList:GetStageGridGOByType(type)
    if type == XEnumConst.MechanismActivity.StageType.Normal then
        return self.GridChapterNormal
    elseif type == XEnumConst.MechanismActivity.StageType.Hard then
        return self.GridChapterHard
    else
        return self.GridChapter
    end
end

function XUiPanelMechanismStageList:SetSelectStage(stageGrid)
    if stageGrid ~= self._SelectedStageGrid then
        if self._SelectedStageGrid then
            self._SelectedStageGrid:SetSelectShow(false)
        end
        
        self._SelectedStageGrid = stageGrid

        if self._SelectedStageGrid then
            self._SelectedStageGrid:SetSelectShow(true)
        else
            self:SetScrollViewElastic()
        end
    end
   
end

function XUiPanelMechanismStageList:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridChapter:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridChapter:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

return XUiPanelMechanismStageList