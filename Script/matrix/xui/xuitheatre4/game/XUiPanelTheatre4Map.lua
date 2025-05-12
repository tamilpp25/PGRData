---@class XUiPanelTheatre4Map : XUiNode
---@field private _Control XTheatre4Control
---@field Parent XUiPanelTheatre4Model
---@field CameraArea UnityEngine.RectTransform
local XUiPanelTheatre4Map = XClass(XUiNode, "XUiPanelTheatre4Map")
local CSVector3 = CS.UnityEngine.Vector3

function XUiPanelTheatre4Map:OnStart()
    self._Control:RegisterClickEvent(self, self.BtnChapterClick, self.OnBtnChapterClick)
    self.PanelMapGrid.gameObject:SetActiveEx(false)
    self.ImgLock.gameObject:SetActiveEx(false)
    ---@type table<number, XUiPanelTheatre4Grid>
    self.PanelGridList = {}
    self.MapId = 1
    self.Index = 1
    ---@type table<number, table<number, boolean>> [x][y] = 是否隐藏
    self.MapHiddenGridPos = {}
    -- 当前是第几层
    self.CurrentFloor = 0
    -- 层级动画
    ---@type table<number, UnityEngine.Playables.PlayableDirector>
    self.FloorAnim = {
        [1] = self.GridChapterEnable:GetComponent("PlayableDirector"),
        [2] = self.GridChapterDisable:GetComponent("PlayableDirector"),
    }
end

function XUiPanelTheatre4Map:Refresh(mapId, index)
    self.MapId = mapId
    self.Index = index
    self.MapHiddenGridPos = self._Control.MapSubControl:GetHiddenGridPosInfo(self.MapId)
    self:RefreshUiData()
end

function XUiPanelTheatre4Map:GetIndex()
    return self.Index
end

-- 章节点击
function XUiPanelTheatre4Map:OnBtnChapterClick()
    local duration = self._Control:GetClientConfig("LocationBtnFocusToMapTime", 1, true) / 1000
    self.Parent.Parent:FocusToMapBaseCameraPosAndDistance(self.MapId, duration)
end

--region 地图格子相关

-- 生成地图格子
function XUiPanelTheatre4Map:GenerateMapGrid(curMapId)
    local gridIds = self._Control.MapSubControl:GetMapGridIdsByMapId(self.MapId)
    if XTool.IsTableEmpty(gridIds) then
        return
    end
    -- 地图偏移值
    local offsetX, offsetY = self._Control.MapSubControl:GetMapOffset(self.MapId)
    if XEnumConst.Theatre4.IsDebug then
        if curMapId == self.MapId then
            XLog.Warning(string.format("<color=#F1D116>Theatre4:</color> 地图:%s, 偏移值, offsetX:%s, offsetY:%s", self.MapId, offsetX, offsetY))
        end
    end
    for _, gridId in pairs(gridIds) do
        local grid = self.PanelGridList[gridId]
        if not grid then
            local mapGrid = XUiHelper.Instantiate(self.PanelMapGrid, self.PanelGridContent)
            ---@type XUiPanelTheatre4Grid
            grid = require("XUi/XUiTheatre4/Game/XUiPanelTheatre4Grid").New(mapGrid, self)
            self.PanelGridList[gridId] = grid
        end
        grid:Open()
        grid:SetGridId(gridId)
        grid:InitGridSizeAndPos(offsetX, offsetY)
        if curMapId ~= self.MapId then
            grid:Refresh()
        end
    end
end

-- 获取所有格子的RectTransform
---@return table<number, UnityEngine.RectTransform>
function XUiPanelTheatre4Map:GetAllGridRectTransform()
    local gridRectTransformList = {}
    for _, grid in pairs(self.PanelGridList) do
        local gridId, gridRectTransform = grid:GetGridRectTransform()
        gridRectTransformList[gridId] = gridRectTransform
    end
    return gridRectTransformList
end

function XUiPanelTheatre4Map:RefreshAllGrid()
    self.MapHiddenGridPos = self._Control.MapSubControl:GetHiddenGridPosInfo(self.MapId)
    for _, grid in pairs(self.PanelGridList) do
        grid:Refresh()
    end
end

function XUiPanelTheatre4Map:RefreshUiData()
    self.TxtChapterName.text = self._Control.MapSubControl:GetMapIndexName(self.Index)
end

-- 处理地图层级动画
function XUiPanelTheatre4Map:HandleMapFloorAnim(lastFloor, curFloor, isLastFrame)
    if lastFloor > 0 then
        local lastAnim = self.FloorAnim[lastFloor]
        if lastAnim then
            lastAnim:Stop()
            lastAnim:Evaluate()
        end
    end
    local curAnim = self.FloorAnim[curFloor]
    if curAnim then
        curAnim.time = isLastFrame and curAnim.duration - 0.001 or 0
        curAnim:Play()
        curAnim:Evaluate()
    end
end

-- 处理格子层级动画
function XUiPanelTheatre4Map:HandleGridFloorAnim(lastFloor, curFloor, gridIds, isLastFrame)
    for _, gridId in pairs(gridIds) do
        local grid = self.PanelGridList[gridId]
        if grid then
            grid:HandleFloorAnim(lastFloor, curFloor, isLastFrame)
        end
    end
end

-- 设置层级
function XUiPanelTheatre4Map:SetFloor(floor)
    self.CurrentFloor = floor
    for _, grid in pairs(self.PanelGridList) do
        grid:SetFloor(floor)
    end
end

-- 播放被打断的格子动画
function XUiPanelTheatre4Map:PlayInterruptGridAnim()
    for _, grid in pairs(self.PanelGridList) do
        grid:PlayInterruptGridAnim()
    end
end

-- 检查格子是否隐藏
function XUiPanelTheatre4Map:CheckGridIsHidden(posX, posY)
    return self.MapHiddenGridPos[posX] and self.MapHiddenGridPos[posX][posY]
end

function XUiPanelTheatre4Map:GetMapSize()
    local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
    local gridList = self.PanelGridList
    for _, grid in pairs(gridList) do
        local x, y = grid:GetGridWorldPos()
        if x and y then
            if x < minX then
                minX = x
            end
            if x > maxX then
                maxX = x
            end
            if y < minY then
                minY = y
            end
            if y > maxY then
                maxY = y
            end
        end
    end
    local gridSize = 5
    return minX + gridSize, maxX - gridSize, minY + gridSize, maxY - gridSize
end

--endregion

--region 相机拖拽缩放相关

-- 获取点在地图的左边还是右边
---@param posX number 世界坐标X
function XUiPanelTheatre4Map:GetPointInMapLeftOrRight(posX)
    local worldPos = CSVector3(posX, 0, 0)
    local localPoint = self.CameraArea:InverseTransformPoint(worldPos)
    return localPoint.x > 0 and 0 or 1 -- 0左边 1右边
end

-- 世界坐标转CameraArea区域的局部坐标
---@param posX number 世界坐标X
---@param posY number 世界坐标Y
---@return UnityEngine.Vector3 局部坐标
function XUiPanelTheatre4Map:WorldToLocalPoint(posX, posY)
    local worldPos = CSVector3(posX, posY, 0)
    return self.CameraArea:InverseTransformPoint(worldPos)
end

-- CameraArea区域的局部坐标转世界坐标
---@param posX number 局部坐标X
---@param posY number 局部坐标Y
---@return UnityEngine.Vector3 世界坐标
function XUiPanelTheatre4Map:LocalToWorldPoint(posX, posY)
    local localPos = CSVector3(posX, posY, 0)
    return self.CameraArea:TransformPoint(localPos)
end

-- 检测点是否在地图范围内
---@param posX number 世界坐标X
---@param posY number 世界坐标Y
---@return boolean 是否在地图范围内
function XUiPanelTheatre4Map:CheckPointInMapRangeByPos(posX, posY)
    local worldPos = CSVector3(posX, posY, 0)
    local localPoint = self.CameraArea:InverseTransformPoint(worldPos)
    return self.CameraArea.rect:Contains(localPoint)
end

--endregion

--region 主动触发

-- 主动触发格子点击
function XUiPanelTheatre4Map:TriggerGridClick(gridId)
    local grid = self.PanelGridList[gridId]
    if grid then
        grid:TriggerGridClick()
    end
end

--endregion

--region 格子数据

-- 获取格子世界坐标
---@param gridId number 格子Id
---@return number, number X坐标, Y坐标
function XUiPanelTheatre4Map:GetGridWorldPos(gridId)
    local grid = self.PanelGridList[gridId]
    if grid then
        return grid:GetGridWorldPos()
    end
end

--endregion

--region 建造相关

-- 显示建造可选择的特效
function XUiPanelTheatre4Map:ShowBuildOptionalEffect(gridIds)
    for _, gridId in pairs(gridIds) do
        local grid = self.PanelGridList[gridId]
        if grid then
            grid:ShowBuildOptionalEffect()
        end
    end
end

-- 隐藏建造可选择的特效
function XUiPanelTheatre4Map:HideBuildOptionalEffect()
    for _, grid in pairs(self.PanelGridList) do
        grid:HideBuildOptionalEffect()
    end
end

-- 显示建造特效
function XUiPanelTheatre4Map:ShowBuildEffect(gridIds)
    for _, gridId in pairs(gridIds) do
        local grid = self.PanelGridList[gridId]
        if grid then
            grid:ShowBuildEffect()
        end
    end
end

-- 隐藏建造特效
function XUiPanelTheatre4Map:HideBuildEffect()
    for _, grid in pairs(self.PanelGridList) do
        grid:HideBuildEffect()
    end
end

-- 显示建筑详情特效
function XUiPanelTheatre4Map:ShowBuildDetailEffect(gridIds)
    for _, gridId in pairs(gridIds) do
        local grid = self.PanelGridList[gridId]
        if grid then
            grid:ShowBuildDetailEffect()
        end
    end
end

-- 隐藏建筑详情特效
function XUiPanelTheatre4Map:HideBuildDetailEffect()
    for _, grid in pairs(self.PanelGridList) do
        grid:HideBuildDetailEffect()
    end
end

--endregion

--region 特效相关

-- 播放格子特效
---@param gridId number 格子Id
function XUiPanelTheatre4Map:PlayGridEffect(gridId)
    local grid = self.PanelGridList[gridId]
    if grid then
        grid:PlayGridEffect()
    end
end

-- 隐藏所有格子特效
function XUiPanelTheatre4Map:HideAllGridEffect()
    for _, grid in pairs(self.PanelGridList) do
        grid:HideGridEffect()
    end
end

--endregion

return XUiPanelTheatre4Map
