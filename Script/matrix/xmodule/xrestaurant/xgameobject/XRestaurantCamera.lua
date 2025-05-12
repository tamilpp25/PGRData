---@class XCameraAuxiliary 摄像机辅助数据
---@field _Type number
---@field CenterPos UnityEngine.Vector3
---@field MinPos UnityEngine.Vector3
---@field MaxPos UnityEngine.Vector3
local XCameraAuxiliary = XClass(nil, "XCameraAuxiliary")

local CsTime = CS.UnityEngine.Time
local CsIsInView = CS.XUiHelper.IsInView
local CsMoveForward = CS.XRestaurantWorkHelper.MoveForward
local CsMoveXAndZ = CS.XRestaurantWorkHelper.MoveXAndZ

function XCameraAuxiliary:Ctor()
    self.CenterPos = CS.UnityEngine.Vector3.zero
    self.MinPos = CS.UnityEngine.Vector3.zero
    self.MaxPos = CS.UnityEngine.Vector3.zero
end

function XCameraAuxiliary:Refresh(type, center, min, max)
    self._Type = type
    self.CenterPos = center
    self.MinPos = min
    self.MaxPos = max
end

--- 判断点是否包含在该范围内只比较X轴
---@param pos UnityEngine.Vector3
---@return boolean
--------------------------
function XCameraAuxiliary:Include(pos)
    if not pos then
        return false
    end
    return pos.x >= self.MinPos.x and pos.x <= self.MaxPos.x
end

---@class XAreaInfoNode 区域节点
---@field Type number
---@field _Last XAreaInfoNode
---@field _Next XAreaInfoNode
local XAreaInfoNode = XClass(nil, "XAreaInfoNode")

function XAreaInfoNode:Ctor(type)
    self.Type = type
end

function XAreaInfoNode:SetNext(next)
    self._Next = next
end

function XAreaInfoNode:SetLast(last)
    self._Last = last
end

function XAreaInfoNode:GetNext()
    return self._Next
end

function XAreaInfoNode:GetLast()
    return self._Last
end


local XRestaurantIScene = require("XModule/XRestaurant/XGameObject/XRestaurantIScene")
---@class XRestaurantCamera : XRestaurantIScene 餐厅摄像机
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Camera UnityEngine.Camera
---@field Bound XCameraBound
---@field _Rotation UnityEngine.Quaternion
---@field _OutRotation UnityEngine.Quaternion
---@field _Speed number
---@field _Fov number
---@field _MinX number 可滑动最小距离
---@field _MaxX number 可滑动最大距离
---@field _Duration number
---@field _Auxiliary XCameraAuxiliary
---@field _AreaType number
---@field _AreaInfoMap table<number, XAreaInfoNode>
---@field _LevelUpEffect UnityEngine.GameObject
---@field _BeginDragPosX number 开始拖动X
---@field _EndDragPosX number 结束拖动X
---@field _MoveMinimumX number 移动到下一区域的最小值
---@field _TouchHandler XBlackRockChess.XTouchHandler
local XRestaurantCamera = XClass(XRestaurantIScene, "XRestaurantCamera")

local CameraDuration = 0.6
local ZoomSpeed, MoveSpeed

function XRestaurantCamera:Init()
    local minX, maxX, speed, euler, duration, inFov, outFov, moveMinimumX, outEuler = self._Model:GetCameraProperty()
    MoveSpeed, ZoomSpeed = self._Model:GetCameraPhotoProperty()
    self._MinX = minX
    self._MaxX = maxX
    self._Speed = speed
    self._Duration = duration
    self._Rotation = CS.UnityEngine.Quaternion.Euler(euler.x, euler.y, euler.z)
    self._OutRotation = CS.UnityEngine.Quaternion.Euler(outEuler.x, outEuler.y, outEuler.z)
    self._AreaType = self._Model:GetEnterAreaType()
    self._Auxiliary = XCameraAuxiliary.New()
    self._Fov = inFov
    self._OutFov = outFov
    self._BeginDragPosX = 0
    self._EndDragPosX = 0
    self._MoveMinimumX = moveMinimumX
    self._PosInfo = {}
    self:InitAreaInfo()
end

function XRestaurantCamera:InitAreaInfo()
    --备菜
    local node1 = XAreaInfoNode.New(XMVCA.XRestaurant.AreaType.IngredientArea)
    --烹饪
    local node2 = XAreaInfoNode.New(XMVCA.XRestaurant.AreaType.FoodArea)
    --售卖
    local node3 = XAreaInfoNode.New(XMVCA.XRestaurant.AreaType.SaleArea)

    node1:SetNext(node2)
    node2:SetNext(node3)
    node2:SetLast(node1)
    node3:SetLast(node2)

    self._AreaInfoMap = {
        [XMVCA.XRestaurant.AreaType.IngredientArea] = node1,
        [XMVCA.XRestaurant.AreaType.FoodArea] = node2,
        [XMVCA.XRestaurant.AreaType.SaleArea] = node3,
    }
end

function XRestaurantCamera:SetGameObject(obj)
    if XTool.UObjIsNil(obj) then
        return
    end
    self.GameObject = obj.gameObject
    self.Transform = obj.transform
    self.Camera = self.Transform:GetComponent("Camera")
    
    self.Camera.depth = 5
    self.Bound = self.GameObject:GetComponent(typeof(CS.XCameraBound))
    if not self.Bound then
        self.Bound = self.GameObject:AddComponent(typeof(CS.XCameraBound))
    end

    self:CheckLevelUpEffect()
    
    self:RefreshAuxiliary(self._AreaType)
    self.Transform.localPosition = self._Auxiliary.CenterPos
    self.Transform.localRotation = self._OutRotation

    self._DefaultPos = self.Transform.localPosition
    self.Camera.fieldOfView = self._OutFov

    local physicsRaycaster = self.GameObject:GetComponent(typeof(CS.UnityEngine.EventSystems.PhysicsRaycaster))
    if not physicsRaycaster then
        physicsRaycaster = self.GameObject:AddComponent(typeof(CS.UnityEngine.EventSystems.PhysicsRaycaster))
    end
    --设置响应事件遮罩
    physicsRaycaster:SetEventMask(CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.HomeCharacter) | CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.Room))
    CS.XGraphicManager.BindCamera(self.Camera)
end

function XRestaurantCamera:CheckLevelUpEffect()
    self._LevelUpEffect = self.Transform:Find("upyanhua")
    if XTool.UObjIsNil(self._LevelUpEffect) then
        return
    end
    self._LevelUpEffect.gameObject:SetActiveEx(false)
    if not self._Model:IsLevelUp() then
        return
    end
    --升级会直接到main界面
    self._OwnControl:StartBusiness()
    local vector3 = CS.UnityEngine.Vector3
    self._LevelUpEffect.localPosition = vector3.zero
    self._LevelUpEffect.localEulerAngles = vector3.zero
    self._LevelUpEffect.localScale = vector3.one
    self._LevelUpEffect.gameObject:SetActiveEx(true)

    local tip = self._Model:GetBoardCastTip( 3)
    tip = string.format(tip, "LV" .. self._Model:GetRestaurantLv())
    self._OwnControl:Broadcast(tip)
    self._Model:MarkLevelUp(false)
end

function XRestaurantCamera:Release()
    self:StopPhotoTimer()
    XRestaurantIScene.Release(self)
    self.Camera = nil
end

--- 移动相机
---@param direction number 方向向量
---@return void
--------------------------
function XRestaurantCamera:MoveCamera(direction)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    local posX = direction * self._Speed + self.Transform.localPosition.x
    posX = CS.UnityEngine.Mathf.Clamp(posX, self._MinX, self._MaxX)
    self._DefaultPos.x = posX
    self.Transform.localPosition = self._DefaultPos
end

--- 摄像机滑动过程中停止
---@param beginCb function
---@param endCb function
---@return void
--------------------------
function XRestaurantCamera:StopCamera(beginCb, endCb)
    local areaType
    local subX = self._EndDragPosX - self._BeginDragPosX
    local pos = self.Transform.localPosition
    if subX > 0 then
        pos.x = pos.x + self._MoveMinimumX
    else
        pos.x = pos.x - self._MoveMinimumX
    end
    for _, type in pairs(XMVCA.XRestaurant.AreaType) do
        if type == XMVCA.XRestaurant.AreaType.None then
            goto continue
        end
        self:RefreshAuxiliary(type)
        if self._Auxiliary:Include(pos) then
            areaType = type
            break
        end
        ::continue::
    end
    self:RefreshAuxiliary(areaType)
    self:MoveTo(areaType, beginCb, endCb)
end

function XRestaurantCamera:RefreshAuxiliary(areaType)
    if not self._Auxiliary then
        return
    end
    if areaType == XMVCA.XRestaurant.AreaType.None then
        return
    end
    local info = self._PosInfo[areaType]
    if not info then
        info = {
            Center = XMVCA.XRestaurant:StrPos2Vector3(self._Model:GetCameraAuxiliaryCenterPos(areaType)),
            Min = XMVCA.XRestaurant:StrPos2Vector3(self._Model:GetCameraAuxiliaryMinPos(areaType)),
            Max = XMVCA.XRestaurant:StrPos2Vector3(self._Model:GetCameraAuxiliaryMaxPos(areaType))
        }
        self._PosInfo[areaType] = info
    end
    self._Auxiliary:Refresh(areaType, info.Center, info.Min, info.Max)
end

function XRestaurantCamera:MoveTo(areaType, beginCb, endCb)
    self:RefreshAuxiliary(areaType)
    self:SetAreaType(areaType)
    XLuaUiManager.SetMask(true)
    if beginCb then beginCb() end
    XUiHelper.DoMove(self.Transform, self._Auxiliary.CenterPos, self._Duration, XUiHelper.EaseType.Sin, function()
        self:InvokeOnCameraViewChange()
        if endCb then endCb() end
        XLuaUiManager.SetMask(false)
    end)
end

function XRestaurantCamera:OnEnterBusiness()
    if XTool.UObjIsNil(self.Camera) then
        return
    end
    --if self.Camera.fieldOfView == self._Fov then
    --    return
    --end
    local k = self._Fov - self._OutFov
    XUiHelper.Tween(CameraDuration, function(dt)
        local fov = k * dt + self._OutFov
        self:DoMoveFov(fov)
    end, function() 
        self:DoMoveFov(self._Fov)
    end)
    self:DoRotate(self._Rotation)
end

function XRestaurantCamera:OnExitBusiness()
    if XTool.UObjIsNil(self.Camera) then
        return
    end
    --if self.Camera.fieldOfView == self._OutFov then
    --    return
    --end 
    local k = self._OutFov - self._Fov
    XUiHelper.Tween(CameraDuration, function(dt)
        local fov = k * dt + self._Fov
        self:DoMoveFov(fov)
    end, function()
        self:DoMoveFov(self._OutFov)
        
    end)
    self:DoRotate(self._OutRotation)
end

function XRestaurantCamera:OnEnterPhoto()
    if self._TouchHandler then
        self:SetTouchHandlerEnable(true)
        return
    end
    
    self._PhotoEleCache = {}
    self._TouchHandler = self.GameObject:AddComponent(typeof(CS.XBlackRockChess.XTouchHandler))
    self._ZoomCb = handler(self, self.OnZoom)
    self._TouchHandler:AddZoomAction(self._ZoomCb)
    self.Bound:Init(self.Camera, Vector3(19.3, 2.4, 7.6), Vector3(34.6, 3.5, 10))
end

function XRestaurantCamera:OnExitPhoto()
    self:SetTouchHandlerEnable(false)
    self._PhotoEleCache = {}
    self:ResetPhoto()
    self:StopPhotoTimer()
end

function XRestaurantCamera:SetTouchHandlerEnable(value)
    if not self._TouchHandler then
        return
    end
    self._TouchHandler.enabled = value
end

function XRestaurantCamera:OnZoom(value)
    if not CsMoveForward(self.Transform, self.Bound, ZoomSpeed, value) then
        return
    end
    self:InvokeOnCameraViewChange()
end

--只允许向上下左右单个方向移动
function XRestaurantCamera:OnMoveInXZ(x, y)
    if not CsMoveXAndZ(self.Transform, self.Bound, MoveSpeed * CsTime.deltaTime, x, y) then
        return
    end
    self:InvokeOnCameraViewChange()
end

function XRestaurantCamera:ResetPhoto()
    self:DoRotate(self._Rotation)
    self:MoveTo(self:GetAreaType())
end

function XRestaurantCamera:DoMoveFov(fov)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    if XTool.UObjIsNil(self.Camera) then
        return
    end
    self.Camera.fieldOfView = fov
end

function XRestaurantCamera:DoRotate(rotate)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.Transform:DOLocalRotateQuaternion(rotate, CameraDuration)
end

function XRestaurantCamera:CheckObjInView(trans)
    if not self.Camera then
        return false
    end
    if XTool.UObjIsNil(trans) then
        return false
    end
    if not trans.gameObject.activeInHierarchy then
        return false
    end
    return CsIsInView(self.Camera, trans)
end

function XRestaurantCamera:CheckInArea(areaType)
    self:RefreshAuxiliary(areaType)
    return self._Auxiliary:Include(self.Transform.position)
end

--region   ------------------getter and setter start-------------------
function XRestaurantCamera:GetAreaType()
    return self._AreaType
end

function XRestaurantCamera:SetAreaType(areaType)
    self._AreaType = areaType
end

function XRestaurantCamera:GetNextAreaInfo()
    local info = self._AreaInfoMap[self._AreaType]
    return info and info:GetNext()
end

function XRestaurantCamera:GetLastAreaInfo()
    local info = self._AreaInfoMap[self._AreaType]
    return info and info:GetLast()
end

function XRestaurantCamera:OnBeginDrag()
    self._BeginDragPosX = self.Transform.position.x
end

function XRestaurantCamera:OnEndDrag()
    self._EndDragPosX = self.Transform.position.x
end

function XRestaurantCamera:GetCamera()
    return self.Camera
end

function XRestaurantCamera:SetOnCameraViewChangeCb(cb)
    self._OnCameraViewChangeCb = cb
end

function XRestaurantCamera:InvokeOnCameraViewChange()
    if not self._OnCameraViewChangeCb then
        return
    end
    self.LastCheckTime = CsTime.time
    self._OnCameraViewChangeCb()
end

function XRestaurantCamera:StartPhotoTimer()
    if self.PhotoTimer then
        return
    end
    self.LastCheckTime = CsTime.time
    self.PhotoTimer = XScheduleManager.ScheduleForever(function()
        if CsTime.time - self.LastCheckTime < 0.2 then
            return
        end
        self:InvokeOnCameraViewChange()
    end, 0)
end

function XRestaurantCamera:StopPhotoTimer()
    if not self.PhotoTimer then
        return
    end
    XScheduleManager.UnSchedule(self.PhotoTimer)
    self.PhotoTimer = nil
end

function XRestaurantCamera:GetPhotoEleCache(id)
    return self._PhotoEleCache[id]
end

function XRestaurantCamera:SetPhotoEleCache(id, obj)
    self._PhotoEleCache[id] = obj
end

function XRestaurantCamera:GetMoveDuration()
    return self._Duration
end
--endregion------------------getter and setter finish------------------

return XRestaurantCamera