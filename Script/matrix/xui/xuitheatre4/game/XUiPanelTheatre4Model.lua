local XUiPanelTheatre4MapCameraRange = require("XUi/XUiTheatre4/Game/XUiPanelTheatre4MapCameraRange")
---@class XUiPanelTheatre4Model : XUiNode
---@field private _Control XTheatre4Control
---@field Parent XUiTheatre4Game
---@field DragMoveAndZoom XDragMoveAndZoom
local XUiPanelTheatre4Model = XClass(XUiNode, "XUiPanelTheatre4Model")
---@type DG.Tweening.Ease
local Ease = CS.DG.Tweening.Ease
local abs = math.abs

function XUiPanelTheatre4Model:OnStart()
    self:InitDragMoveAndZoom()
    -- 当前地图层的范围
    self.CurMapFloorRange = self._Control.MapSubControl:GetCurMapFloorRange()
    self.PanelMap.gameObject:SetActiveEx(false)
    ---@type table<number, XUiPanelTheatre4Map>
    self.MapList = {}
    -- 当前是第几层
    self.CurrentFloor = 0
    -- 层级动画
    self.FloorAnim = {
        [1] = self.PanelMaskBrighten,
        [2] = self.PanelMaskDimming,
    }
    -- 当前在相机视野范围内的地图index
    self.CameraInViewMapIdList = {}
    -- 当前在相机视野范围内的地图格子Id列表
    self.CameraInViewMapGridIdList = {}
    -- 相机的X坐标
    self.CameraPosX = 0
    -- 相机的Y坐标
    self.CameraPosY = 0
    -- 相机的Z坐标
    self.CameraPosZ = 0
    -- 精确度
    self.Precision = 0.01;
    -- 是否是显示状态
    self.IsShow = false
end

function XUiPanelTheatre4Model:OnEnable()
    self.IsShow = true
end

function XUiPanelTheatre4Model:OnDisable()
    self:SaveCameraFollowLastPos()
    self.IsShow = false
    if self.CurrentFloor == 1 then
        self.CameraInViewMapGridIdList = {}
    end
end

--region 生成和刷新格子相关

-- 生成所有的地图格子
function XUiPanelTheatre4Model:GenerateAllMapGroup()
    -- 获取所有的章节数据
    local chapterList = self._Control.MapSubControl:GetAllChapterData()
    if XTool.IsTableEmpty(chapterList) then
        return
    end
    local curMapId = self._Control.MapSubControl:GetCurrentMapId()
    for _, chapterData in pairs(chapterList) do
        self:GenerateMapGroup(chapterData, curMapId)
    end
end

-- 生成单个地图格子
---@param chapterData XTheatre4ChapterData
function XUiPanelTheatre4Model:GenerateMapGroup(chapterData, curMapId)
    if not chapterData then
        XLog.Error("GenerateMapGroup error: chapterData is nil")
        return
    end
    local index = self._Control.MapSubControl:GetIndexByMapGroupAndMaoId(chapterData:GetMapGroup(), chapterData:GetMapId())
    local key = string.format("Map%s", index)
    local mapIndex = self[key]
    if not mapIndex then
        XLog.Error(string.format("GenerateMapGroup error: mapIndex:%s is nil", key))
        return
    end
    mapIndex.gameObject:SetActiveEx(true)
    local mapId = chapterData:GetMapId()
    local map = self.MapList[mapId]
    if not map then
        local panelMap = XUiHelper.Instantiate(self.PanelMap, mapIndex)
        ---@type XUiPanelTheatre4Map
        map = require("XUi/XUiTheatre4/Game/XUiPanelTheatre4Map").New(panelMap, self)
        self.MapList[mapId] = map
    end
    map:Open()
    map:Refresh(mapId, index)
    map:GenerateMapGrid(curMapId)
    -- 隐藏云雾特效
    if curMapId ~= mapId then
        self:HideCloudEffect(mapId)
    end
    -- 计算地图区域包围盒和地图格子包围盒
    if self.MapCameraRange then
        self.MapCameraRange:CalculateMapAreaBounds(mapId, index)
        self.MapCameraRange:CalculateMapGridBounds(mapId, map:GetAllGridRectTransform())
    end
end

-- 刷新所有地图格子
function XUiPanelTheatre4Model:RefreshAllMap()
    for _, map in pairs(self.MapList) do
        map:RefreshAllGrid()
    end
end

-- 刷新单个地图格子
function XUiPanelTheatre4Model:RefreshMap(mapId)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("RefreshMap error: mapId:%s map is nil", mapId))
        return
    end
    map:RefreshAllGrid()
end

--endregion

--region 相机拖拽缩放相关

-- 获取XDragMoveAndZoom并添加回调
function XUiPanelTheatre4Model:InitDragMoveAndZoom()
    if not self.DragMoveAndZoom then
        XLog.Error("XUiPanelTheatre4Model:InitDragMoveAndZoom error: XDragMoveAndZoom is nil")
        return
    end
    self.DragMoveAndZoom:RegisterCameraDrag(handler(self, self.OnCameraDrag))
    self.DragMoveAndZoom:RegisterCameraZoom(handler(self, self.OnCameraZoom))
    local param = self._Control.MapSubControl:GetCameraParams()
    self.DragMoveAndZoom:SetCameraParams(param.CameraDistanceMin, param.CameraDistanceMax, param.CameraMoveSpeedMin,
            param.CameraMoveSpeedMax, param.CameraZoomSpeed, param.DragMaxWidth, param.DragMaxHeight, param.DragMinWidth,
            param.DragMinHeight)

    -- 获取相机
    self.Camera = self.UiCamera:GetComponent(typeof(CS.UnityEngine.Camera))
    if not self.Camera then
        XLog.Error("XUiPanelTheatre4Model:InitDragMoveAndZoom error: Camera is nil")
        return
    end
    -- 地图相机范围
    ---@type XUiPanelTheatre4MapCameraRange
    self.MapCameraRange = XUiPanelTheatre4MapCameraRange.New(self.PanelMapList, self, self.Camera)
    -- 添加相机位置变动计时器
    self:AddCameraPosTimer()
end

-- 添加相机位置变动计时器
function XUiPanelTheatre4Model:AddCameraPosTimer()
    if self.CameraPosTimer then
        XScheduleManager.UnSchedule(self.CameraPosTimer)
        self.CameraPosTimer = nil
    end
    -- 添加相机位置变动计时器
    self.CameraPosTimer = XScheduleManager.ScheduleForeverEx(function()
        if XTool.UObjIsNil(self.GameObject) then
            XScheduleManager.UnSchedule(self.CameraPosTimer)
            self.CameraPosTimer = nil
            return
        end
        if not self.IsShow then
            return
        end
        self:CheckCameraPosChange()
    end, 0)
end

-- 检查相机位置是否发生变化
function XUiPanelTheatre4Model:CheckCameraPosChange()
    if not self.UiCamera then
        return
    end
    if abs(self.CameraPosX - self.UiCamera.position.x) > self.Precision
            or abs(self.CameraPosY - self.UiCamera.position.y) > self.Precision
            or abs(self.CameraPosZ - self.UiCamera.position.z) > self.Precision then
        self.CameraPosX = self.UiCamera.position.x
        self.CameraPosY = self.UiCamera.position.y
        self.CameraPosZ = self.UiCamera.position.z
        self:CameraViewRefresh()
    end
end

-- 相机视野刷新逻辑处理
function XUiPanelTheatre4Model:CameraViewRefresh()
    if not self.MapCameraRange then
        return
    end
    -- 检查地图背景是否在视野内
    self.MapCameraRange:CheckMapBgInView()
    -- 检查地图区域是否在视野内
    local mapIdList = self.MapCameraRange:CheckMapAreaInView()
    local addMapIdList = self:GetAddMapIdList(mapIdList)
    if not XTool.IsTableEmpty(addMapIdList) then
        self:PlayAddMapIdFloorAnim(addMapIdList)
    end
    self.CameraInViewMapIdList = mapIdList
    -- 检查地图格子是否在视野内
    local mapGridIdList = self.MapCameraRange:CheckMapGridInView()
    local addMapGridIdList = self:GetAddMapGridIdList(mapGridIdList)
    if not XTool.IsTableEmpty(addMapGridIdList) then
        self:PlayAddMapGridIdFloorAnim(addMapGridIdList)
    end
    self.CameraInViewMapGridIdList = mapGridIdList
end

-- 获取新增的mapIdList
function XUiPanelTheatre4Model:GetAddMapIdList(mapIdList)
    local addMapIdList = {}
    for _, mapId in pairs(mapIdList) do
        if not table.contains(self.CameraInViewMapIdList, mapId) then
            table.insert(addMapIdList, mapId)
        end
    end
    return addMapIdList
end

-- 获取新增的mapGridIdList
function XUiPanelTheatre4Model:GetAddMapGridIdList(mapGridIdList)
    local addMapGridIdList = {}
    for mapId, gridIds in pairs(mapGridIdList) do
        local addGridIds = {}
        local lastGirdIds = self.CameraInViewMapGridIdList[mapId] or {}
        for _, gridId in pairs(gridIds) do
            if not table.contains(lastGirdIds, gridId) then
                table.insert(addGridIds, gridId)
            end
        end
        if not XTool.IsTableEmpty(addGridIds) then
            addMapGridIdList[mapId] = addGridIds
        end
    end
    return addMapGridIdList
end

-- 获取上一个层级 层级只有1和2两层
function XUiPanelTheatre4Model:GetLastFloor()
    if self.CurrentFloor <= 0 then
        return 0
    end
    local lastFloor = 1
    if self.CurrentFloor == 1 then
        lastFloor = 2
    end
    return lastFloor
end

-- 播放新加的Index层级动画
function XUiPanelTheatre4Model:PlayAddMapIdFloorAnim(addMapIdList)
    for _, mapId in pairs(addMapIdList) do
        local map = self.MapList[mapId]
        if not map then
            XLog.Error(string.format("PlayAddMapIdFloorAnim error: mapId:%s map is nil", mapId))
            return
        end
        map:HandleMapFloorAnim(self:GetLastFloor(), self.CurrentFloor, true)
    end
end

-- 播放新加的GridId层级动画
function XUiPanelTheatre4Model:PlayAddMapGridIdFloorAnim(addMapGridIdList)
    for mapId, gridIds in pairs(addMapGridIdList) do
        local map = self.MapList[mapId]
        if not map then
            XLog.Error(string.format("PlayAddMapGridIdFloorAnim error: mapId:%s map is nil", mapId))
            return
        end
        map:HandleGridFloorAnim(self:GetLastFloor(), self.CurrentFloor, gridIds, true)
    end
end

-- 相机拖拽回调
function XUiPanelTheatre4Model:OnCameraDrag(posX, posY)
    local mapId = self._Control.MapSubControl:GetCurrentMapId()
    local isInRange = self:CheckPointInMapRangeByPos(mapId)
    local x = self:GetPointInMapLeftOrRight(mapId)
    self.Parent:RefreshLocationBtn(isInRange, x)
end

-- 相机缩放回调
function XUiPanelTheatre4Model:OnCameraZoom(zoom)
    local curFloor = self:CalculateCurFloor(zoom)
    if self.CurrentFloor == curFloor then
        return
    end
    self:HandleFloorAnim(self.CurrentFloor, curFloor)
    self:SetFloor(curFloor)
end

-- 计算当前层级
function XUiPanelTheatre4Model:CalculateCurFloor(zoom)
    if XTool.IsTableEmpty(self.CurMapFloorRange) then
        return 1
    end
    local curFloor = 1
    for i, data in pairs(self.CurMapFloorRange) do
        if zoom >= data.Min and zoom <= data.Max then
            curFloor = i
            break
        end
    end
    return curFloor
end

-- 处理层级动画
function XUiPanelTheatre4Model:HandleFloorAnim(lastFloor, curFloor)
    if lastFloor > 0 then
        local lastAnim = self.FloorAnim[lastFloor]
        if lastAnim then
            lastAnim:StopTimelineAnimation(false, true)
        end
    end
    local curAnim = self.FloorAnim[curFloor]
    if curAnim then
        curAnim:PlayTimelineAnimation()
    end
    for _, mapId in pairs(self.CameraInViewMapIdList) do
        local map = self.MapList[mapId]
        if not map then
            XLog.Error(string.format("CameraInViewMapIdList error: mapId:%s map is nil", mapId))
            return
        end
        map:HandleMapFloorAnim(lastFloor, curFloor)
    end
    for mapId, gridIds in pairs(self.CameraInViewMapGridIdList) do
        local map = self.MapList[mapId]
        if not map then
            XLog.Error(string.format("CameraInViewMapGridIdList error: mapId:%s map is nil", mapId))
            return
        end
        map:HandleGridFloorAnim(lastFloor, curFloor, gridIds)
    end
    -- 播放格子出现音效
    if lastFloor > 0 and curFloor == 2 then
        local cueId = self._Control:GetClientConfig("SwitchFloorCueId", 1, true)
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
    end
end

-- 设置层级
function XUiPanelTheatre4Model:SetFloor(curFloor)
    self.CurrentFloor = curFloor
    for _, map in pairs(self.MapList) do
        map:SetFloor(curFloor)
    end
end

-- 播放被打断的格子动画
---@param mapId number 地图Id
function XUiPanelTheatre4Model:PlayInterruptGridAnim(mapId)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("PlayInterruptGridAnim error: mapId:%s map is nil", mapId))
        return
    end
    map:PlayInterruptGridAnim()
end

-- 保存相机当前的位置和距离
function XUiPanelTheatre4Model:SaveCameraFollowLastPos()
    local posX = self.DragMoveAndZoom.CameraPositionX
    local posY = self.DragMoveAndZoom.CameraPositionY
    local distance = self.DragMoveAndZoom.CameraDistance
    self._Control:SaveCameraFollowLastPos(posX, posY, distance)
end

-- 打印相机当前的位置和距离 (位置是相对于CameraArea的局部坐标)
function XUiPanelTheatre4Model:PrintCameraFollowLastPos()
    local posX = self.DragMoveAndZoom.CameraPositionX
    local posY = self.DragMoveAndZoom.CameraPositionY
    local distance = self.DragMoveAndZoom.CameraDistance
    for _, map in pairs(self.MapList) do
        if map:CheckPointInMapRangeByPos(posX, posY) then
            local localPos = map:WorldToLocalPoint(posX, posY)
            XLog.Warning(string.format("<color=#F1D116>Theatre4:</color> mapId:%s posX:%s posY:%s distance:%s localPosX:%s localPosY:%s",
                    map.MapId, posX, posY, distance, localPos.x, localPos.y))
            break
        end
    end
end

-- 获取点是在地图的左边还是右边
---@param mapId number 地图Id
---@return number 锚点X
function XUiPanelTheatre4Model:GetPointInMapLeftOrRight(mapId)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("GetPointInMapLeftOrRight error: mapId:%s map is nil", mapId))
        return 0, 0.5 -- 默认在地图左边
    end
    local posX = self.DragMoveAndZoom.CameraPositionX
    return map:GetPointInMapLeftOrRight(posX)
end

-- 检测相机是否在地图范围内
---@param mapId number 地图Id
---@return boolean
function XUiPanelTheatre4Model:CheckPointInMapRangeByPos(mapId)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("CheckPointInMapRangeByPos error: mapId:%s map is nil", mapId))
        return false
    end
    local posX = self.DragMoveAndZoom.CameraPositionX
    local posY = self.DragMoveAndZoom.CameraPositionY
    return map:CheckPointInMapRangeByPos(posX, posY)
end

-- 局部坐标转世界坐标
---@param mapId number 地图Id
---@param posX number x局部坐标
---@param posY number y局部坐标
---@return number, number x世界坐标, y世界坐标
function XUiPanelTheatre4Model:LocalToWorldPointByMapId(mapId, posX, posY)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("LocalToWorldPointByMapId error: mapId:%s map is nil", mapId))
        return 0, 0
    end
    local worldPoint = map:LocalToWorldPoint(posX, posY)
    return worldPoint.x, worldPoint.y
end

-- 设置相机位置和距离
---@param posX number x世界坐标
---@param posY number y世界坐标
---@param distance number 距离
function XUiPanelTheatre4Model:SetCameraPositionAndDistance(posX, posY, distance)
    self.DragMoveAndZoom:SetCameraPositionAndDistance(posX, posY, distance)
end

function XUiPanelTheatre4Model:SetCameraPosition(posX, posY, distance)
    self.DragMoveAndZoom:SetCameraPosition(posX, posY, distance)
end

-- 聚焦相机到指定位置
---@param posX number x坐标
---@param posY number y坐标
---@param duration number 持续时间
---@param ease DG.Tweening.Ease 缓动函数
---@param callback function 回调
function XUiPanelTheatre4Model:FocusCameraToPosition(posX, posY, duration, ease, callback)
    if not ease then
        ease = Ease.InOutQuad
    end
    XLuaUiManager.SetMask(true)
    self.DragMoveAndZoom:FocusCameraToPosition(posX, posY, duration, ease, function()
        XLuaUiManager.SetMask(false)
        if callback then
            callback()
        end
    end)
end

-- 缩放相机的距离
---@param distance number 相机距离
---@param duration number 持续时间
---@param ease DG.Tweening.Ease 缓动函数
---@param callback function 回调
function XUiPanelTheatre4Model:ZoomCameraToDistance(distance, duration, ease, callback)
    if not ease then
        ease = Ease.InOutQuad
    end
    XLuaUiManager.SetMask(true)
    self.DragMoveAndZoom:ZoomCameraToDistance(distance, duration, ease, function()
        XLuaUiManager.SetMask(false)
        if callback then
            callback()
        end
    end)
end

-- 同时聚焦和缩放相机到指定位置和距离
---@param posX number x坐标
---@param posY number y坐标
---@param distance number 相机距离
---@param duration number 持续时间
---@param ease DG.Tweening.Ease 缓动函数
---@param callback function 回调
function XUiPanelTheatre4Model:FocusAndZoomCamera(posX, posY, distance, duration, ease, callback)
    if not ease then
        ease = Ease.InOutQuad
    end
    XLuaUiManager.SetMask(true)
    self.DragMoveAndZoom:FocusAndZoomCamera(posX, posY, distance, duration, ease, function()
        XLuaUiManager.SetMask(false)
        if callback then
            callback()
        end
    end)
end

-- 保存聚焦到格子前相机的参数
function XUiPanelTheatre4Model:SaveFocusGridBeforeCameraPos()
    if not self._Control:CheckOpenCameraFocusRecover() then
        return
    end
    local posX = self.DragMoveAndZoom.CameraPositionX
    local posY = self.DragMoveAndZoom.CameraPositionY
    self._Control:SaveFocusGridBeforeCameraPos(posX, posY)
end

--endregion

--region 主动触发

-- 主动触发格子点击
function XUiPanelTheatre4Model:TriggerGridClick(mapId, gridId)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("TriggerGridClick error: mapId:%s map is nil", mapId))
        return
    end
    map:TriggerGridClick(gridId)
end

--endregion

--region 格子数据

-- 获取格子世界坐标
---@param mapId number 地图Id
---@param gridId number 格子Id
---@return number, number X坐标, Y坐标
function XUiPanelTheatre4Model:GetGridWorldPos(mapId, gridId)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("GetGridWorldPos error: mapId:%s map is nil", mapId))
        return 0, 0
    end
    return map:GetGridWorldPos(gridId)
end

function XUiPanelTheatre4Model:GetMapSize(mapId)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("GetGridWorldPos error: mapId:%s map is nil", mapId))
        return 0, 0
    end
    return map:GetMapSize()
end

--endregion

--region 建造相关

-- 显示建造可选择的特效
function XUiPanelTheatre4Model:ShowBuildOptionalEffect(mapId, gridIds)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("ShowBuildOptionalEffect error: mapId:%s map is nil", mapId))
        return
    end
    map:ShowBuildOptionalEffect(gridIds)
end

-- 隐藏建造可选择的特效
function XUiPanelTheatre4Model:HideBuildOptionalEffect(mapId)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("HideBuildOptionalEffect error: mapId:%s map is nil", mapId))
        return
    end
    map:HideBuildOptionalEffect()
end

-- 显示建造已选择特效
function XUiPanelTheatre4Model:ShowBuildEffect(mapId, gridIds)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("ShowBuildEffect error: mapId:%s map is nil", mapId))
        return
    end
    map:ShowBuildEffect(gridIds)
end

-- 隐藏建造特效
function XUiPanelTheatre4Model:HideBuildEffect(mapId)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("HideBuildEffect error: mapId:%s map is nil", mapId))
        return
    end
    map:HideBuildEffect()
end

-- 显示建筑详情特效
function XUiPanelTheatre4Model:ShowBuildDetailEffect(mapId, gridIds)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("ShowBuildDetailEffect error: mapId:%s map is nil", mapId))
        return
    end
    map:ShowBuildDetailEffect(gridIds)
end

-- 隐藏建筑详情特效
function XUiPanelTheatre4Model:HideBuildDetailEffect(mapId)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("HideBuildDetailEffect error: mapId:%s map is nil", mapId))
        return
    end
    map:HideBuildDetailEffect()
end

--endregion

--region 特效相关

-- 播放云雾隐藏特效
---@param mapGroup number 地图组
---@param mapId number 地图Id
---@param callback function 回调
function XUiPanelTheatre4Model:PlayCloudHideEffect(mapGroup, mapId, callback)
    local index = self._Control.MapSubControl:GetIndexByMapGroupAndMaoId(mapGroup, mapId)
    local key = string.format("Effect%s", index)
    local effect = self[key]
    if not effect then
        XLog.Error(string.format("PlayCloudHideEffect error: effect:%s is nil", key))
        if callback then
            callback()
        end
        return
    end
    -- 特效隐藏状态直接回调
    if not effect.gameObject.activeSelf then
        if callback then
            callback()
        end
        return
    end
    local loadEffect = effect:GetComponent("XUiLoadEffect")
    if XTool.UObjIsNil(loadEffect) or XTool.UObjIsNil(loadEffect.EffectGameObject) then
        XLog.Error("PlayCloudHideEffect error: loadEffect or EffectGameObject is nil")
        if callback then
            callback()
        end
        return
    end
    local anim = XUiHelper.TryGetComponent(loadEffect.EffectGameObject.transform, "Animation")
    if XTool.UObjIsNil(anim) then
        XLog.Error("PlayCloudHideEffect error: anim is nil")
        if callback then
            callback()
        end
        return
    end
    XLuaUiManager.SetMask(true)
    local finishCallback = function()
        effect.gameObject:SetActiveEx(false)
        XLuaUiManager.SetMask(false)
        if callback then
            callback()
        end
    end
    anim:PlayTimelineAnimation(finishCallback)
end

-- 隐藏云雾特效
function XUiPanelTheatre4Model:HideCloudEffect(mapId)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("HideCloudEffect error: mapId:%s map is nil", mapId))
        return
    end
    -- 隐藏云雾特效
    local effectKey = string.format("Effect%s", map:GetIndex())
    local effect = self[effectKey]
    if effect then
        effect.gameObject:SetActiveEx(false)
    end
end

-- 播放格子特效
---@param mapId number 地图Id
---@param gridId number 格子Id
function XUiPanelTheatre4Model:PlayGridEffect(mapId, gridId)
    local map = self.MapList[mapId]
    if not map then
        XLog.Error(string.format("PlayGridEffect error: mapId:%s map is nil", mapId))
        return
    end
    map:PlayGridEffect(gridId)
end

--endregion

--region 根据觉醒值替换地图，和播放特效
function XUiPanelTheatre4Model:ReplaceMapByAwakenValue()
    local config = self._Control:GetMapReplaceAndEffectConfig()
    local bg = self.PanelMapBg
    if not bg then
        return
    end
    -- 回滚上次的
    if self._LastEffectConfig then
        for i = 1, #self._LastEffectConfig.MapImageFrom do
            local mapImageFrom = self._LastEffectConfig.MapImageFrom[i]
            local mapImageTo = self._LastEffectConfig.MapImageTo[i]
            local imageFrom = bg:Find(mapImageFrom)
            local imageTo = bg:Find(mapImageTo)
            if imageFrom then
                imageFrom.gameObject:SetActiveEx(true)
            end
            if imageTo then
                imageTo.gameObject:SetActiveEx(false)
            end
        end
    end
    if config then
        self._LastEffectConfig = config
        for i = 1, #config.MapImageFrom do
            local mapImageFrom = config.MapImageFrom[i]
            local mapImageTo = config.MapImageTo[i]
            local imageFrom = bg:Find(mapImageFrom)
            local imageTo = bg:Find(mapImageTo)
            if imageFrom then
                imageFrom.gameObject:SetActiveEx(false)
            end
            if imageTo then
                imageTo.gameObject:SetActiveEx(true)
            end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE4_ADD_CHAPTER, config.Effect)
    else
        self._LastEffectConfig = nil    
    end
    
end
--endregion

return XUiPanelTheatre4Model
