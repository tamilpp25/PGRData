---@class XUiPanelGame2048StageList: XUiNode
---@field _Control XGame2048Control
---@field Parent XUiGame2048Chapter
---@field ScrollView UnityEngine.UI.ScrollRect
local XUiPanelGame2048StageList = XClass(XUiNode, 'XUiPanelGame2048StageList')
local XUiGridGame2048Stage = require('XUi/XUiGame2048/UiGame2048Chapter/XUiGridGame2048Stage')

function XUiPanelGame2048StageList:OnStart(chapterId)
    self._ChapterId = chapterId
    self:InitStages()

    --关卡滑动窗口的边界值
    self.ScrollLimitX = math.abs(self.ScrollView.viewport.rect.width / 2)
    self:RegisterClickEvent(self.ScrollView, function()
        self:SetSelectStage(nil)
    end)

    local dragProxy = self.ScrollView.gameObject:AddComponent(typeof(CS.XUguiDragProxy))
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))

    self.ScrollView.onValueChanged:AddListener(function(vec2)

        if self._ScrollLastPosX == nil then
            self._ScrollLastPosX = vec2.x
        end
        -- 控制触发的滑动距离
        if math.abs(vec2.x - self._ScrollLastPosX) < 0.1 then
            return
        else
            self._ScrollLastPosX = vec2.x
        end
        -- 控制仅在PC滚轮操作下才额外执行取消选择
        if not self._FocusScrollMoving and self._ScrollMovingByHand == false then
            self:OnScrollRectBeginDrag()
        end
    end)
    
    self._IsInit = true
end

function XUiPanelGame2048StageList:OnEnable()
    if self._IsInit then
        self._IsInit = false
    else
        -- 取消选中
        self:CancelSelect()
    end

    self:RefreshAutoSelect()
end

function XUiPanelGame2048StageList:InitStages()
    -- 初始化关卡UI
    local stageIds = self._Control:GetChapterStageIdsById(self._ChapterId)

    if not XTool.IsTableEmpty(stageIds) then
        self._StageGrids = {}
        self._StageIdMapIndex = {}
        for index, stageId in ipairs(stageIds) do
            if self['Stage'..index] then
                local go = CS.UnityEngine.GameObject.Instantiate(self.Parent.GridStage, self['Stage'..index].transform)
                go.transform.localPosition = Vector3.zero

                local grid = XUiGridGame2048Stage.New(go, self, stageId, index)
                grid:Open()
                self._StageIdMapIndex[stageId] = index
                table.insert(self._StageGrids, grid)
            else
                break
            end
        end
    end
end

function XUiPanelGame2048StageList:RefreshStages()
    if not XTool.IsTableEmpty(self._StageGrids) then
        for i, v in ipairs(self._StageGrids) do
            v:Refresh()
        end
    end
end

function XUiPanelGame2048StageList:RefreshAutoSelect()
    local noPassIndex = 0
    local latestUnlockIndex = 0

    if not XTool.IsTableEmpty(self._StageGrids) then
        for index, stageGrid in ipairs(self._StageGrids) do
            local stageId = stageGrid:GetStageId()
            
            -- 找到最后一个解锁的关卡
            if XMVCA.XGame2048:CheckUnlockByStageId(stageId) then
                latestUnlockIndex = index
            end
            -- 找到最近的未通关关卡
            if not XTool.IsNumberValid(noPassIndex) and not XMVCA.XGame2048:CheckPassedByStageId(stageId) then
                noPassIndex = index
            end
        end
    end

    -- 关卡定位
    local curStageData = self._Control:GetCurStageData()
    local curStageIndex = 0
    if not XTool.IsTableEmpty(curStageData) then
        curStageIndex = self._StageIdMapIndex[curStageData.StageId]
    end

    if XTool.IsNumberValid(curStageIndex) then
        -- 定位当前正在进行的关卡
        self:SetSelectStage(self._StageGrids[curStageIndex], true)
    elseif XTool.IsNumberValid(latestUnlockIndex) then
        -- 定位最后一个解锁的关卡
        self:SetSelectStage(self._StageGrids[latestUnlockIndex], true)
    elseif XTool.IsNumberValid(noPassIndex) then
        -- 定位最近未通关的关卡
        self:SetSelectStage(self._StageGrids[noPassIndex], true)
    else
        -- 定位最后一关
        self:SetSelectStage(self._StageGrids[#self._StageGrids], true)
    end
end

--region -------------------- 滚动视图 --------------------

function XUiPanelGame2048StageList:PlayScrollViewMove(grid)
    -- 动画
    local gridTf = grid.Parent.gameObject:GetComponent("RectTransform")
    local diffX = gridTf.localPosition.x + self.Content.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridTf.localPosition.x
        local tarPos = self.Content.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.Content, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end


function XUiPanelGame2048StageList:FocusCurStageUI(stageId, isElastic)
    local index = self._StageIdMapIndex[stageId]
    local ctrl = self._StageGrids[index]
    if ctrl then
        local focusX = self._Control:GetClientConfigNum('UiGridChapterMoveTargetX')
        local tarPosX = focusX - ctrl.Transform.parent.localPosition.x

        if isElastic then
            tarPosX = XMath.Clamp(tarPosX, - ctrl.Transform.parent.parent.transform.sizeDelta.x + self.ScrollLimitX , - self.ScrollLimitX)
        end
        
        self.ScrollView.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        self:PlayScrollViewMoveBack(tarPosX, isElastic)
    end
end

function XUiPanelGame2048StageList:SetScrollViewElastic()
    self.ScrollView.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
    self:SetSelectStage(nil)
end

function XUiPanelGame2048StageList:PlayScrollViewMoveBack(tarPosX, isElastic)
    local moveDuration = CS.XGame.ClientConfig:GetFloat('KotodamaActivityStageMoveDuration')
    local tarPos = self.ScrollView.content.localPosition
    tarPos.x = tarPosX

    XLuaUiManager.SetMask(true)
    self._FocusScrollMoving = true
    self.ScrollView.inertia = false
    XUiHelper.DoMove(self.ScrollView.content, tarPos, moveDuration, XUiHelper.EaseType.Sin, function()
        if isElastic then
            self.ScrollView.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        else
            self.ScrollView.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        end
        XLuaUiManager.SetMask(false)
        self._FocusScrollMoving = false
        self.ScrollView.inertia = true
    end)
end

--- 尝试聚焦上一次选中的关卡，若移动会超过滑动窗限度则不强制移动
--- todo:逻辑需要调整
function XUiPanelGame2048StageList:TryFocusStage()
    local selectIndex = self._Control:GetLastSelectStageIndex(self._ChapterId)
    if XTool.IsNumberValid(selectIndex) then
        local selectGrid = self._StageGrids[selectIndex]
        if selectGrid then
            local halfScreenWidth = self.ScrollView.viewport.rect.width / 2
            local moveMinX = halfScreenWidth
            local moveMaxX = self.ScrollView.content.rect.width - halfScreenWidth
            if selectGrid.Transform.parent.localPosition.x > moveMinX then
                local focusX = self._Control:GetClientConfigNum('UiGridChapterMoveTargetX')
                local tarPosX = focusX - selectGrid.Transform.parent.localPosition.x
                local fixedPositionX = CS.UnityEngine.Mathf.Clamp(tarPosX, -moveMaxX, -moveMinX)
                self:PlayScrollViewMoveBack(fixedPositionX, true)
            end
        end
    end
end

function XUiPanelGame2048StageList:OnDragProxy(dragType)
    if dragType == 0 then
        self:OnScrollRectBeginDrag()
        self._ScrollMovingByHand = true
    elseif dragType == 2 then
        self._ScrollMovingByHand = false
    end
end

function XUiPanelGame2048StageList:OnScrollRectBeginDrag()
    self:CancelSelect()
end


-- 返回滚动容器是否动画回弹
function XUiPanelGame2048StageList:CancelSelect()
    if not self._SelectedStageGrid then
        return false
    end

    self:SetSelectStage(nil)
    self:SetScrollViewElastic()
    return true
end
--endregion

function XUiPanelGame2048StageList:SetSelectStage(stageGrid, ignoreSelect)
    if ignoreSelect then
        if stageGrid then
            self:FocusCurStageUI(stageGrid:GetStageId(), true)
        end
        return
    end
    
    if stageGrid ~= self._SelectedStageGrid then
        if self._SelectedStageGrid then
            self._SelectedStageGrid:SetSelectShow(false)
        end

        self._SelectedStageGrid = stageGrid

        if self._SelectedStageGrid then
            local stageId = self._SelectedStageGrid:GetStageId()
            self._Control:SetCurStageId(stageId)
            self:FocusCurStageUI(stageId)
            self._SelectedStageGrid:SetSelectShow(true)
            if XLuaUiManager.IsUiShow('UiGame2048StageDetail') then
                XLuaUiManager.Close('UiGame2048StageDetail')
            end
            XLuaUiManager.Open('UiGame2048StageDetail')
        else
            XLuaUiManager.Close('UiGame2048StageDetail')
            self._Control:SetCurStageId(nil)
            self:SetScrollViewElastic()
        end
    elseif stageGrid then
        -- 点击相同的关卡需要关闭
        XLuaUiManager.Close('UiGame2048StageDetail')
        self._Control:SetCurStageId(nil)
        stageGrid:SetSelectShow(false)
        self:SetScrollViewElastic()
    end

end

function XUiPanelGame2048StageList:RegisterClickEvent(uiNode, func)
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

return XUiPanelGame2048StageList