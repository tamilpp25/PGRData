---@class XUiPanelTheatre4MapCameraRange : XUiNode
---@field private _Control XTheatre4Control
local XUiPanelTheatre4MapCameraRange = XClass(XUiNode, "XUiPanelTheatre4MapCameraRange")
---@type UnityEngine.GeometryUtility
local GeometryUtility = CS.UnityEngine.GeometryUtility
---@type UnityEngine.Vector3
local Vector3 = CS.UnityEngine.Vector3
---@type UnityEngine.Bounds
local Bounds = CS.UnityEngine.Bounds
---@type System.Array
local Array = CS.System.Array
---@type UnityEngine.Plane
local Plane = CS.UnityEngine.Plane
---@type UnityEngine.Debug
local Debug = CS.UnityEngine.Debug
---@type UnityEngine.Color
local Color = CS.UnityEngine.Color

local MapBgMaxValue = 240
local MapBgOffset = 20
local MapAreaOffset = 30
local MapGridOffset = 10

---@param camera UnityEngine.Camera
function XUiPanelTheatre4MapCameraRange:OnStart(camera)
    self.Camera = camera
    self.Planes = Array.CreateInstance(typeof(Plane), 6)
    self.Corners = Array.CreateInstance(typeof(Vector3), 4)
    -- 地图背景包围盒列表
    self.MapBgBoundsList = {}
    -- 地图区域包围盒列表
    self.MapAreaBoundsList = {}
    -- 地图格子包围盒列表
    self.MapGridBoundsList = {}
    self:CalculateMapBgBounds()
end

-- 判断包围盒是否在视野内
---@param bounds UnityEngine.Bounds
---@return boolean 是否在视野内 true在 false不在
function XUiPanelTheatre4MapCameraRange:IsInView(bounds)
    GeometryUtility.CalculateFrustumPlanes(self.Camera, self.Planes)
    return GeometryUtility.TestPlanesAABB(self.Planes, bounds)
end

-- 计算包围盒
---@param rectTransform UnityEngine.RectTransform
---@param centerOffset UnityEngine.Vector3
---@param sizeOffset UnityEngine.Vector3
---@return UnityEngine.Bounds
function XUiPanelTheatre4MapCameraRange:CalculateBounds(rectTransform, centerOffset, sizeOffset)
    rectTransform:GetWorldCorners(self.Corners)
    local center = (self.Corners[2] + self.Corners[0]) * 0.5 + centerOffset
    local size = Vector3(self.Corners[2].x - self.Corners[0].x, self.Corners[2].y - self.Corners[0].y, 0) + sizeOffset
    return Bounds(center, size)
end

-- 计算地图背景包围盒
function XUiPanelTheatre4MapCameraRange:CalculateMapBgBounds()
    for i = 1, MapBgMaxValue do
        local name = string.format("MapBg%s", i)
        local rectTransform = self[name]:GetComponent(typeof(CS.UnityEngine.RectTransform))
        if rectTransform then
            local bounds = self:CalculateBounds(rectTransform, Vector3.zero, Vector3(MapBgOffset, MapBgOffset, 0))
            self.MapBgBoundsList[i] = { Bounds = bounds, Name = name }
        else
            XLog.Error("CalculateMapBgBounds error: rectTransform is nil")
        end
    end
end

-- 计算地图区域包围盒
function XUiPanelTheatre4MapCameraRange:CalculateMapAreaBounds(mapId, index)
    local name = string.format("MapArea%s", index)
    local rectTransform = self[name]:GetComponent(typeof(CS.UnityEngine.RectTransform))
    if rectTransform then
        local offsetX, offsetY = self._Control.MapSubControl:GetMapOffset(mapId)
        local centerOffset = self:GetMapCenterOffset(rectTransform, offsetX, offsetY)
        local bounds = self:CalculateBounds(rectTransform, centerOffset, Vector3(MapAreaOffset, MapAreaOffset, 0))
        self.MapAreaBoundsList[mapId] = { Bounds = bounds, Name = name }
    else
        XLog.Error("CalculateMapAreaBounds error: rectTransform is nil")
    end
end

-- 获取地图中心偏移世界坐标
---@param rectTransform UnityEngine.RectTransform
function XUiPanelTheatre4MapCameraRange:GetMapCenterOffset(rectTransform, posX, posY)
    local rect = rectTransform.rect
    -- 左下角坐标
    local localPos = Vector3(-rect.width * 0.5, -rect.height * 0.5, 0)
    -- 左下角世界坐标
    local point = rectTransform:TransformPoint(localPos)
    -- 地图偏移值坐标
    local x = posX - rect.width * 0.5
    local y = posY - rect.height * 0.5
    local offsetPos = Vector3(x, y, 0)
    -- 地图偏移值世界坐标
    local offsetPoint = rectTransform:TransformPoint(offsetPos)
    return offsetPoint - point
end

-- 计算地图格子包围盒
---@param mapId number
---@param gridRectTransformList table<number, UnityEngine.RectTransform>
function XUiPanelTheatre4MapCameraRange:CalculateMapGridBounds(mapId, gridRectTransformList)
    local gridBoundsList = {}
    for gridId, rectTransform in pairs(gridRectTransformList) do
        if rectTransform then
            local bounds = self:CalculateBounds(rectTransform, Vector3.zero, Vector3(MapGridOffset, MapGridOffset, 0))
            local canvasGroup = rectTransform:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
            gridBoundsList[gridId] = { Bounds = bounds, CanvasGroup = canvasGroup }
        end
    end
    self.MapGridBoundsList[mapId] = gridBoundsList
end

-- 检查地图背景是否在视野内 在就设置canvasGroup的alpha为1 不在就设置为0
function XUiPanelTheatre4MapCameraRange:CheckMapBgInView()
    for _, data in pairs(self.MapBgBoundsList) do
        local bounds = data.Bounds
        local name = data.Name
        self[name].alpha = self:IsInView(bounds) and 1 or 0
    end
end

-- 检查地图区域是否在视野内 在就设置canvasGroup的alpha为1 不在就设置为0
---@return number[] 在视野内的区域地图Id列表
function XUiPanelTheatre4MapCameraRange:CheckMapAreaInView()
    local inViewMapIdList = {}
    for mapId, data in pairs(self.MapAreaBoundsList) do
        local bounds = data.Bounds
        local name = data.Name
        local inView = self:IsInView(bounds)
        self[name].alpha = inView and 1 or 0
        if inView then
            table.insert(inViewMapIdList, mapId)
        end
    end
    return inViewMapIdList
end

-- 检查地图格子是否在视野内 在就设置canvasGroup的alpha为1 不在就设置为0
---@return number[][] 在视野内的格子Id列表
function XUiPanelTheatre4MapCameraRange:CheckMapGridInView()
    local inViewMapGridIdList = {}
    for mapId, gridBoundsList in pairs(self.MapGridBoundsList) do
        local gridIdList = {}
        for gridId, data in pairs(gridBoundsList) do
            local bounds = data.Bounds
            local canvasGroup = data.CanvasGroup
            local inView = self:IsInView(bounds)
            canvasGroup.alpha = inView and 1 or 0
            if inView then
                table.insert(gridIdList, gridId)
            end
        end
        if not XTool.IsTableEmpty(gridIdList) then
            inViewMapGridIdList[mapId] = gridIdList
        end
    end
    return inViewMapGridIdList
end

-- 计算包围盒的8个顶点
local function CalculateBoundsCorners(bounds)
    local corners = {}
    local min = bounds.min
    local max = bounds.max
    -- Bottom
    table.insert(corners, Vector3(min.x, min.y, min.z))
    table.insert(corners, Vector3(max.x, min.y, min.z))
    table.insert(corners, Vector3(max.x, min.y, max.z))
    table.insert(corners, Vector3(min.x, min.y, max.z))
    -- Top
    table.insert(corners, Vector3(min.x, max.y, min.z))
    table.insert(corners, Vector3(max.x, max.y, min.z))
    table.insert(corners, Vector3(max.x, max.y, max.z))
    table.insert(corners, Vector3(min.x, max.y, max.z))
    return corners
end

-- 使用Debug.DrawLine绘制边框
local function DrawWireCube(bounds)
    local corners = CalculateBoundsCorners(bounds)
    -- Bottom
    Debug.DrawLine(corners[1], corners[2], Color.green)
    Debug.DrawLine(corners[2], corners[3], Color.green)
    Debug.DrawLine(corners[3], corners[4], Color.green)
    Debug.DrawLine(corners[4], corners[1], Color.green)
    -- Top
    Debug.DrawLine(corners[5], corners[6], Color.green)
    Debug.DrawLine(corners[6], corners[7], Color.green)
    Debug.DrawLine(corners[7], corners[8], Color.green)
    Debug.DrawLine(corners[8], corners[5], Color.green)
    -- Sides
    Debug.DrawLine(corners[1], corners[5], Color.green)
    Debug.DrawLine(corners[2], corners[6], Color.green)
    Debug.DrawLine(corners[3], corners[7], Color.green)
    Debug.DrawLine(corners[4], corners[8], Color.green)
end

return XUiPanelTheatre4MapCameraRange
