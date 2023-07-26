local XUiTaikoMasterStageGrid = require("XUi/XUiTaikoMaster/XUiTaikoMasterStageGrid")
local XUiTaikoMasterCdDetail = require("XUi/XUiTaikoMaster/XUiTaikoMasterCdDetail")
local MathLerp = CS.UnityEngine.Mathf.Lerp

---@class XUiTaikoMasterCdList@ 没考虑复用
local XUiTaikoMasterCdList = XClass(nil, "XUiTaikoMasterCdList")

function XUiTaikoMasterCdList:Ctor(ui)
    self._SelectedIndex = false
    self._SongArray = false
    -- 用于打开界面时选中关卡
    self._StageIdOnceSelected = false

    self.ScrollRect = ui.PanelAllCds
    self.ScrollPanel = ui.PanelCdZu
    self.Grid = ui.GridCdMessage
    self.Grid.gameObject:SetActiveEx(false)
    ---@type XUiTaikoMasterCdDetail
    self.CdDetail = XUiTaikoMasterCdDetail.New(ui.PanelCdDaily)

    self.PanelMusic = ui.PanelMusic
    self.Viewport = ui.Viewport

    ---@type XUiTaikoMasterStageGrid[]
    self._GridArray = {}
    self._GridWidth = self.Grid.rect.width
    self._SelectedGridWidth = self._GridWidth
    self._SongGridArray = {}
    self._PosArray = {}
    self._StartIndex = -9999
    self._IsMovingGrid = false
    self._MoveTime = 0.3
    self._MoveMaskTime = math.max(0.5, self._MoveTime)
    self._DoMoveTimer = {}
    self._IsSetMask = false
    self._IsScrolling = false

    self:Init()
end

function XUiTaikoMasterCdList:Init()
    self.CdDetail:SetActiveEx(false)
    self.PanelMusic.gameObject:SetActiveEx(false)
    self:RegisterOnDrag()
    self:SetDataSource(XDataCenter.TaikoMasterManager.GetSongArray())
end

function XUiTaikoMasterCdList:OnEnable(hasSelectSong)
    -- 在滚动中被disable，强行重置，必须重播动画（动画控制了透明度）
    -- hasSelectSong防止重复播放音乐导致的“音谱”不工作
    if self._IsScrolling and not hasSelectSong then
        self._IsScrolling = false
        self:Select(self._SelectedIndex)
    end
end

function XUiTaikoMasterCdList:OnDisable()
    self:ClearDoMoveTimer()
    self:SetMask(false)
end

function XUiTaikoMasterCdList:OnDestroy()
    self:ClearDoMoveTimer()
    self.CdDetail:KillFlowText()
    self:SetMask(false)
end

function XUiTaikoMasterCdList:SetDataSource(dataSource)
    self._SongArray = dataSource
    self:RefreshPosArray()
    self:RefreshGridVisible()
end

function XUiTaikoMasterCdList:FindGrid(index, oldStartIndex)
    -- 先猜
    if oldStartIndex then
        local offset = index - oldStartIndex
        local guessGridIndex = index - oldStartIndex + 1
        local guessGrid = self._GridArray[guessGridIndex]
        if guessGrid and guessGrid:GetIndex() == index then
            return guessGridIndex
        end
    end
    -- 猜不中
    for i = 1, #self._GridArray do
        local grid = self._GridArray[i]
        if grid:GetIndex() == index then
            return i
        end
    end
    return false
end

function XUiTaikoMasterCdList:RefreshGridVisible()
    if self._IsMovingGrid then
        return
    end
    local scrollRectLeftX = -self.ScrollPanel.offsetMin.x
    local scrollRectRightX = scrollRectLeftX + self.Viewport.rect.width
    local visibleGridStart, visibleGridEnd = 0, 0
    for i = 1, #self._PosArray do
        local leftX = self._PosArray[i]
        local rightX = self._PosArray[i + 1] or scrollRectRightX
        if leftX > scrollRectRightX then
            break
        end
        if
            (leftX >= scrollRectLeftX and leftX <= scrollRectRightX) or
                (rightX >= scrollRectLeftX and rightX <= scrollRectRightX)
         then
            if visibleGridStart == 0 then
                visibleGridStart = i
            else
                visibleGridEnd = i
            end
        end
    end
    local oldStartIndex = self._GridArray[1] and self._GridArray[1]:GetIndex() or false
    local usedGridIndex = 0
    local isBackward = oldStartIndex and oldStartIndex == visibleGridStart + 1
    for index = visibleGridStart, visibleGridEnd do
        -- 将旧的挪到对应位置
        local gridIndex = self:FindGrid(index, oldStartIndex)
        if gridIndex then
            -- 猜测
            local targetGridIndex = index - visibleGridStart + 1
            self:ExchangeGrid(gridIndex, targetGridIndex)
        elseif isBackward then
            self:ExchangeGrid(1, #self._GridArray)
        end
        usedGridIndex = usedGridIndex + 1
        local grid = self:GetGrid(usedGridIndex)
        grid:SetActive(true)
        if self:RefreshGrid(grid, index) then
            self:SetPosIndex(grid, index)
        end
    end
    for i = usedGridIndex + 1, #self._GridArray do
        local grid = self._GridArray[i]
        grid:SetActive(false)
    end
end

function XUiTaikoMasterCdList:ExchangeGrid(index1, index2)
    if index1 == index2 then
        return
    end
    local grid1 = self._GridArray[index1]
    self._GridArray[index1] = self._GridArray[index2]
    self._GridArray[index2] = grid1
end

function XUiTaikoMasterCdList:SetPosIndex(grid, posIndex, x)
    self:SetRectPosIndex(grid:GetRectTransform(), posIndex, x)
end

function XUiTaikoMasterCdList:SetRectPosIndex(rectTransform, posIndex, x)
    rectTransform:SetInsetAndSizeFromParentEdge(
        CS.UnityEngine.RectTransform.Edge.Left,
        x or self._PosArray[posIndex],
        rectTransform.rect.width
    )
end

function XUiTaikoMasterCdList:GetGrid(index)
    local grid = self._GridArray[index]
    if not grid then
        local uiGrid = CS.UnityEngine.Object.Instantiate(self.Grid, self.Grid.transform.parent)
        grid = XUiTaikoMasterStageGrid.New(uiGrid)
        grid:SetActive(true)
        self._GridArray[index] = grid
    end
    return grid
end

function XUiTaikoMasterCdList:RefreshPosArray()
    local posX = 0
    self._PosArray = {}
    for i = 1, #self._SongArray do
        self._PosArray[#self._PosArray + 1] = posX
        if i == self._SelectedIndex then
            posX = posX + self._SelectedGridWidth
        else
            posX = posX + self._GridWidth
        end
    end
    self.ScrollPanel.sizeDelta = Vector2(posX, self.ScrollPanel.sizeDelta.y)
end

function XUiTaikoMasterCdList:RegisterOnDrag()
    self.ScrollRect.onValueChanged:AddListener(handler(self, self.OnValueChanged))
end

function XUiTaikoMasterCdList:OnValueChanged()
    self:RefreshGridVisible()
end

function XUiTaikoMasterCdList:GetSelectedSong()
    return self._SongArray[self._SelectedIndex]
end

---@param grid XUiTaikoMasterStageGrid
function XUiTaikoMasterCdList:RefreshGrid(grid, index)
    local gridSongId = self:GetSongId(index)
    if not gridSongId then
        return false
    end
    local isDirty = grid:Refresh(gridSongId, self._SelectedIndex, index)
    if self._StageIdOnceSelected then
        local songId = XTaikoMasterConfigs.GetSongIdByStageId(self._StageIdOnceSelected)
        if songId == gridSongId then
            self.CdDetail:SetDifficulty(XTaikoMasterConfigs.GetDifficulty(self._StageIdOnceSelected))
            self._StageIdOnceSelected = false
        end
    end
    return isDirty
end

function XUiTaikoMasterCdList:GetSongId(index)
    return self._SongArray[index]
end

function XUiTaikoMasterCdList:SelectStage(stageId)
    if self:SelectSong(XTaikoMasterConfigs.GetSongIdByStageId(stageId)) then
        self._StageIdOnceSelected = stageId
    end
end

function XUiTaikoMasterCdList:SelectSong(songId)
    for i = 1, #self._SongArray do
        if self._SongArray[i] == songId then
            XEventManager.DispatchEvent(XEventId.EVENT_TAIKO_MASTER_STAGE_SELECT, i)
            return true
        end
    end
    return false
end

function XUiTaikoMasterCdList:GetGridIndex(index)
    return index and (index - self._StartIndex + 1)
end

function XUiTaikoMasterCdList:Select(index)
    local oldGridIndex = self:FindGrid(self._SelectedIndex)
    local oldGrid = self._GridArray[oldGridIndex]
    if oldGrid then
        oldGrid:Fold()
    end
    local oldSelectedIndex = self._SelectedIndex
    self._SelectedIndex = index
    if index then
        local songId = self:GetSongId(index)
        XDataCenter.TaikoMasterManager.PlaySong(songId)
        self._SelectedGridWidth = self.CdDetail:GetRectTransform().rect.width
        self:SetGridPosDirty()
        self.CdDetail:Refresh(songId)
        self.CdDetail:SetActiveEx(true)
        self.CdDetail:PlayEnableAnimation()
        self.PanelMusic.gameObject:SetActiveEx(true)
        self:RefreshPosArray()
        if not self:PlayGridMove(index, true) then
            self:RefreshGridVisible()
        end
        self:SetPosIndex(self.CdDetail, index)
        self:PlayScrollViewMove(index)
        self.ScrollRect.horizontal = false
    else
        self.ScrollRect.horizontal = true
        self._SelectedGridWidth = self._GridWidth
        self:SetGridPosDirty()
        self.CdDetail:SetActiveEx(false)
        self.PanelMusic.gameObject:SetActiveEx(false)
        if self:PrepareForGridMove(oldSelectedIndex) then
            if not self:PlayGridMove(oldSelectedIndex, false) then
                self:RefreshGridVisible()
            end
        else
            self:RefreshPosArray()
        end
        XDataCenter.TaikoMasterManager.PlayDefaultBgm()
    end
end

function XUiTaikoMasterCdList:SetGridPosDirty()
    for i = 1, #self._GridArray do
        self._GridArray[i]:SetPosDirty()
    end
end

function XUiTaikoMasterCdList:PlayScrollViewMove(index)
    if not index then
        return
    end
    local uiContent = self.ScrollPanel
    local x = self._PosArray[index]
    if not x then
        return
    end
    -- 居中
    x = (x * 2 - self.Viewport.rect.width) / 2
    local gridWidth = (self._PosArray[index + 1] or uiContent.rect.width) - self._PosArray[index]
    x = x + gridWidth / 2
    -- 到达左右边界
    -- local maxLeftX = uiContent.rect.width - self.Viewport.rect.width
    -- x = XMath.Clamp(x, 0, maxLeftX)
    self._IsScrolling = true
    self:SetMask(true)
    self:DoMove(
        uiContent,
        -x,
        self._MoveMaskTime,
        XUiHelper.EaseType.Sin,
        function()
            self._IsScrolling = false
            self:SetMask(false)
        end
    )
end

-- refer to XUiHelper.DoMove
function XUiTaikoMasterCdList:DoMove(rectTf, tarPos, duration, easeType, cb)
    local startPos = rectTf.offsetMin.x
    easeType = easeType or XUiHelper.EaseType.Linear
    local timer
    timer =
        XUiHelper.Tween(
        duration,
        function(t)
            if not rectTf:Exist() then
                return true
            end
            local value = MathLerp(startPos, tarPos, t)
            rectTf:SetInsetAndSizeFromParentEdge(CS.UnityEngine.RectTransform.Edge.Left, value, rectTf.rect.width)
        end,
        function()
            self:RemoveDoMoveTimer(timer)
            if cb then
                cb()
            end
        end,
        function(t)
            return XUiHelper.Evaluate(easeType, t)
        end
    )
    self._DoMoveTimer[#self._DoMoveTimer + 1] = timer
end

-- 因为是动态列表，右边viewPort外的部分没有现成的格子可用了，所以激活外侧的格子，并且刷新它们
function XUiTaikoMasterCdList:PrepareForGridMove(selectedIndex)
    local selectedGridIndex = self:FindGrid(selectedIndex)
    if not selectedGridIndex then
        return false
    end
    local oldPosArray = XTool.Clone(self._PosArray)
    self:RefreshPosArray()
    local curPosArray = self._PosArray
    local scrollRectLeftX = -self.ScrollPanel.offsetMin.x
    local scrollRectRightX = scrollRectLeftX + self.Viewport.rect.width
    local songIndex = selectedIndex
    for gridIndex = selectedGridIndex + 1, #self._GridArray do
        local grid = self._GridArray[gridIndex]
        songIndex = songIndex + 1
        if not grid:IsActive() then
            local curPosX = curPosArray[songIndex]
            if curPosX and curPosX < scrollRectRightX then
                self:RefreshGrid(grid, songIndex)
                grid:SetActive(true)
                self:SetPosIndex(grid, songIndex, oldPosArray[songIndex])
            end
        end
    end
    return true
end

function XUiTaikoMasterCdList:PlayGridMove(selectedSongIndex, unfold)
    if not selectedSongIndex then
        return false
    end
    local selectedGridIndex = self:FindGrid(selectedSongIndex)
    local selectedGrid = self._GridArray[selectedGridIndex]
    if not selectedGrid then
        return false
    end
    selectedGrid:SetActive(not unfold)
    local movingGridAmount = 0
    for gridIndex = selectedGridIndex + 1, #self._GridArray do
        local grid = self._GridArray[gridIndex]
        if grid:IsActive() then
            local rectTransform = grid:GetRectTransform()
            movingGridAmount = movingGridAmount + 1
            local startPos = rectTransform.offsetMin.x
            self:DoMove(
                rectTransform,
                self._PosArray[grid:GetIndex()],
                self._MoveTime,
                XUiHelper.EaseType.Sin,
                function()
                    movingGridAmount = movingGridAmount - 1
                    if movingGridAmount == 0 then
                        self._IsMovingGrid = false
                        self:RefreshGridVisible()
                    end
                end
            )
        end
    end
    if movingGridAmount > 0 then
        self._IsMovingGrid = true
    end
    return true
end

function XUiTaikoMasterCdList:SetMask(value)
    if value == self._IsSetMask then
        return
    end
    self._IsSetMask = value
    XLuaUiManager.SetMask(value)
end

function XUiTaikoMasterCdList:ClearDoMoveTimer()
    for i = 1, #self._DoMoveTimer do
        XScheduleManager.UnSchedule(self._DoMoveTimer[i])
    end
    self._DoMoveTimer = {}
end

function XUiTaikoMasterCdList:RemoveDoMoveTimer(timer)
    for i = 1, #self._DoMoveTimer do
        if self._DoMoveTimer[i] == timer then
            table.remove(self._DoMoveTimer, i)
            break
        end
    end
end

function XUiTaikoMasterCdList:CheckRedPointSongUnlock(songId)
    for i = 1, #self._GridArray do
        local grid = self._GridArray[i]
        if grid:IsActive() and grid:GetSongId() == songId then
            grid:CheckRedPointCdUnlock()
            return
        end
    end
end

return XUiTaikoMasterCdList
