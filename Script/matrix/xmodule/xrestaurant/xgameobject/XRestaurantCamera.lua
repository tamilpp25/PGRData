---@class XCameraAuxiliary 摄像机辅助数据
---@field _Type number
---@field CenterPos UnityEngine.Vector3
---@field MinPos UnityEngine.Vector3
---@field MaxPos UnityEngine.Vector3
local XCameraAuxiliary = XClass(nil, "XCameraAuxiliary")

function XCameraAuxiliary:Ctor()
    self.CenterPos = CS.UnityEngine.Vector3.zero
    self.MinPos = CS.UnityEngine.Vector3.zero
    self.MaxPos = CS.UnityEngine.Vector3.zero
end

function XCameraAuxiliary:Refresh(type)
    self._Type = type
    self.CenterPos = XRestaurantConfigs.StrPos2Vector3(XRestaurantConfigs.GetCameraAuxiliaryCenterPos(type))
    self.MinPos = XRestaurantConfigs.StrPos2Vector3(XRestaurantConfigs.GetCameraAuxiliaryMinPos(type))
    self.MaxPos = XRestaurantConfigs.StrPos2Vector3(XRestaurantConfigs.GetCameraAuxiliaryMaxPos(type))
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

---@class XRestaurantCamera 餐厅摄像机
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Camera UnityEngine.Camera
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
local XRestaurantCamera = XClass(nil, "XRestaurantCamera")

local CameraDuration = 0.6

function XRestaurantCamera:Ctor()
    local minX, maxX, speed, euler, duration, inFov, outFov, moveMinimumX, outEuler = XRestaurantConfigs.GetCameraProperty()
    self._MinX = minX
    self._MaxX = maxX
    self._Speed = speed
    self._Duration = duration
    self._Rotation = CS.UnityEngine.Quaternion.Euler(euler.x, euler.y, euler.z)
    self._OutRotation = CS.UnityEngine.Quaternion.Euler(outEuler.x, outEuler.y, outEuler.z)
    self._AreaType = XRestaurantConfigs.AreaType.FoodArea
    self._Auxiliary = XCameraAuxiliary.New()
    self._Fov = inFov
    self._OutFov = outFov
    self._BeginDragPosX = 0
    self._EndDragPosX = 0
    self._MoveMinimumX = moveMinimumX
    self:InitAreaInfo()
end

function XRestaurantCamera:InitAreaInfo()
    --备菜
    local node1 = XAreaInfoNode.New(XRestaurantConfigs.AreaType.IngredientArea)
    --烹饪
    local node2 = XAreaInfoNode.New(XRestaurantConfigs.AreaType.FoodArea)
    --售卖
    local node3 = XAreaInfoNode.New(XRestaurantConfigs.AreaType.SaleArea)

    node1:SetNext(node2)
    node2:SetNext(node3)
    node2:SetLast(node1)
    node3:SetLast(node2)

    self._AreaInfoMap = {
        [XRestaurantConfigs.AreaType.IngredientArea] = node1,
        [XRestaurantConfigs.AreaType.FoodArea] = node2,
        [XRestaurantConfigs.AreaType.SaleArea] = node3,
    }
end

function XRestaurantCamera:SetGameObject(obj)
    if XTool.UObjIsNil(obj) then
        return
    end
    self.GameObject = obj.gameObject
    self.Transform = obj.transform
    self.Camera = self.Transform:GetComponent("Camera")

    self:CheckLevelUpEffect()

    self._Auxiliary:Refresh(self._AreaType)
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
    local viewModel = XDataCenter.RestaurantManager.GetViewModel()
    if not viewModel:GetProperty("_IsLevelUp") then
        return
    end
    local vector3 = CS.UnityEngine.Vector3
    self._LevelUpEffect.localPosition = vector3.zero
    self._LevelUpEffect.localEulerAngles = vector3.zero
    self._LevelUpEffect.localScale = vector3.one
    self._LevelUpEffect.gameObject:SetActiveEx(true)

    local tip = XRestaurantConfigs.GetClientConfig("BoardCastTips", 3)
    tip = string.format(tip, "LV" .. viewModel:GetProperty("_Level"))
    XDataCenter.RestaurantManager.Broadcast(tip)
    
    viewModel:SetProperty("_IsLevelUp", false)
end

function XRestaurantCamera:Release()
    if XTool.UObjIsNil(self.GameObject) then
        XUiHelper.Destroy(self.GameObject)
    end
    self.GameObject = nil
    self.Transform = nil
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
    for _, type in pairs(XRestaurantConfigs.AreaType) do
        self._Auxiliary:Refresh(type)
        if self._Auxiliary:Include(pos) then
            areaType = type
            break
        end
    end
    self._Auxiliary:Refresh(areaType)
    self:MoveTo(areaType, beginCb, endCb)
end

function XRestaurantCamera:MoveTo(areaType, beginCb, endCb)
    self._Auxiliary:Refresh(areaType)
    self:SetAreaType(areaType)
    XLuaUiManager.SetMask(true)
    if beginCb then beginCb() end
    XUiHelper.DoMove(self.Transform, self._Auxiliary.CenterPos, self._Duration, XUiHelper.EaseType.Sin, function()
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

function XRestaurantCamera:DoMoveFov(fov)
    if XTool.UObjIsNil(self.GameObject) then
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
--endregion------------------getter and setter finish------------------

return XRestaurantCamera