---@class XPlanetCamera
---@field _Root CS.UnityEngine.Transform 父节点可能为空
---@field _GameObject CS.UnityEngine.GameObject
---@field _Transform CS.UnityEngine.Transform
---@field _Camera CS.UnityEngine.Camera
---@field _CameraMode XPlanetConfigs.SceneCameraMode
local XPlanetCamera = XClass(nil, "XPlanetCamera")
local Input = CS.UnityEngine.Input
local Quaternion = CS.UnityEngine.Quaternion
local RotateUnit = 57.29578    -- 旋转度

function XPlanetCamera:Ctor(root, gameObject)
    self._Root = root
    self._GameObject = gameObject
    self._Transform = gameObject.transform
    self._CameraMode = XPlanetConfigs.SceneCameraMode.FreeMode
    self._FreeModeStartDragRotation = self:GetTransform().rotation
    self:_InitFollowModeParams()
    self:_InitFreeModeParams()
    
    self._BeforeModeChangeRootPosition = false  -- 模式改变前根节点坐标
    self._BeforeModeChangeRootRotation = false  -- 模式改变前根节点旋转
    self._BeforeModeChangeCamPosition = false   -- 模式改变前相机节点坐标
    self._BeforeModeChangeCamRotation = false   -- 模式改变前相机节点旋转
    self._FreeModeScrollValue = 1
    
    self._IsInMove = false
    self:InitCamera()
end


--region 模式参数
function XPlanetCamera:ChangeMode(mode)
    -- 切换模式时记录当前相机状态
    self._BeforeModeChangeRootPosition = self:GetTransform().position
    self._BeforeModeChangeRootRotation = self:GetTransform().rotation
    self._BeforeModeChangeCamPosition = self:GetCameraTransform().position
    self._BeforeModeChangeCamRotation = self:GetCameraTransform().rotation
    
    if mode == XPlanetConfigs.SceneCameraMode.FreeMode then
        -- 跟随视角转自由视角需要重置一下camRoot
        if self._CameraMode == XPlanetConfigs.SceneCameraMode.FollowMode then
            local lookPosition = not XTool.UObjIsNil(self._FollowModeTran) and self._FollowModeTran.position or self:GetCameraCenterRayPosition()
            local rot = self:GetLookAtRotation(self._FollowModeStartPosition, lookPosition, self._FollowModeStartRotation)

            self:SetCameraRootWorldRotation(rot)
            self:SetCameraWorldPosition(self._BeforeModeChangeCamPosition)
            self:SetCameraWorldRotation(self._BeforeModeChangeCamRotation)

            self._FreeModeLookPosition = lookPosition
            self._FollowModeTran = false
            self._FollowModeStartPosition = false
            self._FollowModeStartRotation = false
        elseif self._CameraMode == XPlanetConfigs.SceneCameraMode.StaticMode then
            self._FreeModeScrollValue = 1
        end
    end
    
    self._CameraMode = mode
end

function XPlanetCamera:CheckIsInFollowMode()
    return self:_CheckMode(XPlanetConfigs.SceneCameraMode.FollowMode)
end

function XPlanetCamera:CheckIsInFreeMode()
    return self:_CheckMode(XPlanetConfigs.SceneCameraMode.FreeMode)
end

function XPlanetCamera:CheckIsInStaticMode()
    return self:_CheckMode(XPlanetConfigs.SceneCameraMode.StaticMode)
end

function XPlanetCamera:CheckIsInMovieMode()
    return self:_CheckMode(XPlanetConfigs.SceneCameraMode.MovieMode)
end

---@param sceneCameraMode number XPlanetConfigs.SceneCameraMode
function XPlanetCamera:_CheckMode(sceneCameraMode)
    return self._CameraMode == sceneCameraMode
end
--endregion


--region 自由模式（可交互旋转）
function XPlanetCamera:_InitFreeModeParams()
    self._FreeModeStartDragRotation = nil
    self._FreeModeStartDragMousePosition = nil
    self._FreeModeIsDrag = false
    self._FreeModeAfterDragSpeed = 0
    self._FreeModeAfterDragDelta = nil
    self._FreeModeAfterDragBefore = nil
    self._FreeModeAfterDragAfter = nil
end

---限制滑轮高度
function XPlanetCamera:_FreeModeSetAndCheckScrollValue(scrollValue)
    self._FreeModeScrollValue = scrollValue or 1
    self._FreeModeScrollValue = math.min(self._FreeModeScrollValue, 1)
    self._FreeModeScrollValue = math.max(self._FreeModeScrollValue, 0)
end

function XPlanetCamera:_FreeModeGetCurCameraParams()
    local maxCam = XDataCenter.PlanetManager.GetCamera(XPlanetConfigs.GetCamBuildMax())
    local minCam = XDataCenter.PlanetManager.GetCamera(XPlanetConfigs.GetCamBuildMin())
    local position, rotation, fov
    position = Vector3.SlerpUnclamped(minCam:GetPosition(), maxCam:GetPosition(), self._FreeModeScrollValue)
    rotation = Quaternion.SlerpUnclamped(minCam:GetRotation(), maxCam:GetRotation(), self._FreeModeScrollValue)
    fov = minCam:GetFov() + (minCam:GetFov() - maxCam:GetFov()) * self._FreeModeScrollValue
    return position, rotation, fov
end

function XPlanetCamera:_FreeModeSetCurCamera()
    local position, rotation, fov = self:_FreeModeGetCurCameraParams()
    
    self:SetCameraLocalPosition(position)
    self:SetCameraFov(fov)
    self:SetCameraLocalRotation(rotation)
end

function XPlanetCamera:ChangeFreeModeByCamera(cb)
    local beforeIsFollow = self._CameraMode == XPlanetConfigs.SceneCameraMode.FollowMode
    self:_FreeModeSetAndCheckScrollValue(self._FreeModeScrollValue)
    
    self:ChangeMode(XPlanetConfigs.SceneCameraMode.FreeMode)
    self:_InitFreeModeParams()
    self._Camera.transform:SetParent(self._Transform)
    self:SetCameraRootWorld(Vector3.zero)
    if beforeIsFollow then
        self:PlaySound(XPlanetConfigs.SoundCueId.CamFar)
        self:MoveCamFollowToFree(nil, cb)
    else
        self:_FreeModeSetCurCamera()
        if cb then cb() end
    end
end

---自由模式拖拽转动
function XPlanetCamera:FreeModeBeginDrag()
    if not self:CheckIsInFreeMode()
            or XDataCenter.GuideManager.CheckIsInGuidePlus()    -- 引导时屏蔽旋转
            or Input.touchCount == 2 then                   -- 二指缩放屏蔽旋转
        return
    end
    self._FreeModeStartDragRotation = self:GetTransform().rotation
    self._FreeModeStartDragMousePosition = Input.mousePosition
    self._FreeModeIsDrag = true
    self._FreeModeAfterDragSpeed = 0
    self._FreeModeAfterDragBefore = Input.mousePosition
    self._FreeModeAfterDragAfter = nil
    self._FreeModeAfterDragDelta = nil
end

---自由模式拖拽转动
function XPlanetCamera:FreeModeOnDrag()
    if not self:CheckIsInFreeMode()
            or Input.touchCount == 2                        -- 二指缩放屏蔽旋转
            or XDataCenter.GuideManager.CheckIsInGuidePlus()    -- 引导时屏蔽旋转
            or not self._FreeModeIsDrag   then
        self._FreeModeStartDragRotation = nil
        self._FreeModeStartDragMousePosition = nil
        self._FreeModeIsDrag = false
        self._FreeModeAfterDragSpeed = 0
        return
    end
    local deltaMousePosition = Input.mousePosition - self._FreeModeStartDragMousePosition
    local screen = CS.UnityEngine.Screen
    local screenDragDelta = Vector2(deltaMousePosition.x / screen.width, deltaMousePosition.y / screen.height)
    local tran = self:GetTransform()
    local cameraTran = self:GetCameraTransform()

    local x = screenDragDelta.x * RotateUnit * XPlanetConfigs.GetPlanetRotateSpeed()
    local y = screenDragDelta.y * RotateUnit * XPlanetConfigs.GetPlanetRotateSpeed()
    -- 上下拖拽相当于将目标物体按相机的right方向旋转
    local yRot = Quaternion.AngleAxis(-y, cameraTran.right)
    -- 左右拖拽相当于将目标物体按相机的up方向旋转
    local xRot = Quaternion.AngleAxis(x, cameraTran.up)
    local rot = xRot * yRot
    tran.rotation = rot * self._FreeModeStartDragRotation
    
    self._FreeModeAfterDragAfter = Input.mousePosition
    self._FreeModeAfterDragDelta = self._FreeModeAfterDragAfter - self._FreeModeAfterDragBefore
    self._FreeModeAfterDragDelta = Vector2(self._FreeModeAfterDragDelta.x / screen.width, self._FreeModeAfterDragDelta.y / screen.height)
    self._FreeModeAfterDragBefore = Input.mousePosition
end

---自由模式拖拽转动
function XPlanetCamera:FreeModeEndDrag()
    if not self:CheckIsInFreeMode()
            or XDataCenter.GuideManager.CheckIsInGuidePlus()    -- 引导时屏蔽旋转
            or Input.touchCount == 2 then                   -- 二指缩放屏蔽旋转
        return
    end
    self._FreeModeStartDragRotation = nil
    self._FreeModeStartDragMousePosition = nil
    self._FreeModeIsDrag = false
    self._FreeModeAfterDragSpeed = XPlanetConfigs.GetPlanetRotateSpeed()
end

---自由模式拖拽惯性
function XPlanetCamera:FreeAfterDragUpdate()
    if not self:CheckIsInFreeMode() or Input.touchCount >= 1 or self._FreeModeIsDrag then
        return
    end
    if not self._FreeModeAfterDragDelta or not self._FreeModeAfterDragSpeed or self._FreeModeAfterDragSpeed <= 0 then
        return
    end
    
    local tran = self:GetTransform()
    local cameraTran = self:GetCameraTransform()

    -- 速度衰减
    if self._FreeModeAfterDragSpeed > 0.01 then
        self._FreeModeAfterDragSpeed = self._FreeModeAfterDragSpeed - self._FreeModeAfterDragSpeed / XPlanetConfigs.GetPlanetRotateReduction()
    else
        self:FreeAfterDragStop()
        return
    end

    local x = self._FreeModeAfterDragDelta.x * RotateUnit * self._FreeModeAfterDragSpeed
    local y = self._FreeModeAfterDragDelta.y * RotateUnit * self._FreeModeAfterDragSpeed
    
    local yRot = Quaternion.AngleAxis(-y, cameraTran.right)
    local xRot = Quaternion.AngleAxis(x, cameraTran.up)
    local rot = xRot * yRot
    tran.rotation = rot * tran.rotation
end

---自由模式停止拖拽惯性
function XPlanetCamera:FreeAfterDragStop()
    self._FreeModeAfterDragDelta = nil
    self._FreeModeAfterDragSpeed = 0
end

local TouchPhase = CS.UnityEngine.TouchPhase
local oldTouch1, oldTouch2
---自由模式缩放
function XPlanetCamera:FreeModeScroll()
    if (not self:CheckIsInFreeMode()) or self._IsInMove or self._FreeModeIsDrag then
        return
    end
    if Input.GetAxis("Mouse ScrollWheel") ~= 0 then
        local value = CS.UnityEngine.Mathf.Clamp(self._FreeModeScrollValue + Input.GetAxis("Mouse ScrollWheel") * 0.7, 0, 1)
        self:_FreeModeSetAndCheckScrollValue(value)
        self:_FreeModeSetCurCamera()
    end
    if (Input.touchCount == 2) then
        self:FreeAfterDragStop()
        local touch1 = Input.GetTouch(0)
        local touch2 = Input.GetTouch(1)
        
        if touch2.phase == TouchPhase.Began then
            oldTouch1 = touch1
            oldTouch2 = touch2
            return
        end
        if (not oldTouch1) or (not oldTouch2) then
            return
        end

        local oldDistance = Vector2.Distance(oldTouch1.position,oldTouch2.position)
        local newDistance = Vector2.Distance(touch1.position,touch2.position)
        local offset = oldDistance - newDistance
        local screen = CS.UnityEngine.Screen
        offset = offset / (screen.width / 2)
        local value = CS.UnityEngine.Mathf.Clamp(self._FreeModeScrollValue + offset, 0, 1)
        oldTouch1 = touch1
        oldTouch2 = touch2

        self:_FreeModeSetAndCheckScrollValue(value)
        self:_FreeModeSetCurCamera()
    end
end
--endregion


--region 跟随模式（跟随某物体，不可交互）
function XPlanetCamera:_InitFollowModeParams()
    -- 跟随定位到角色身上参数
    self._FollowModeIsStart = false
    self._FollowModeTran = nil
    self._FollowModeCam = nil
    self._FollowModeCurTranForward = false
    self._FollowModeStartPosition = false
    self._FollowModeStartRotation = false

    -- 不固定朝向角色前方参数
    self._FollowUnLockCurCamPos2Planet = false          -- 相机当前相对球心坐标
    self._FollowUnLockCurFollowTranPos2Planet = false   -- 跟随目标当前相对球心坐标
    self._FollowUnLockCamStartRotation = false          -- 开始跟随时相机旋转度
    self._FollowUnLockDeltaRotation = false             -- 跟随模式下与开始跟随时相机坐标旋转度差值
end

---@param camera XPlanetSceneCamera
function XPlanetCamera:ChangeFollowModeByCamera(followTran, camera, cb, isNoAnim)
    if not followTran then
        XUiManager.TipErrorWithKey("PlanetRunningNoLeader")
        if cb then cb() end
        return
    end
    self:ChangeMode(XPlanetConfigs.SceneCameraMode.FollowMode)
    
    self._FollowModeTran = followTran
    self._FollowModeCam = camera
    self._FollowModeIsStart = false
    if not isNoAnim then
        self:SetFollowModeWithAnim(cb)
    else
        -- 将镜头定位到角色
        local fromFollowRotation = self:GetTransform().localRotation
        local fromPosition = self:GetCameraCenterRayPosition()
        local target = self._FollowModeTran.position
        local toRotation = self:GetLookAtRotation(fromPosition, target, fromFollowRotation)
        self:SetCameraRootWorldRotation(toRotation)
        
        self._FollowModeCurTranForward = self._FollowModeTran.forward
        self._FollowModeStartPosition = self._FollowModeTran.position
        self._FollowModeStartRotation = self._Transform.rotation

        self._Camera.transform:SetParent(self._FollowModeTran)
        self:SetCameraRootWorldRotation(self:GetCamRootFollowTranRot())
        self:SetCameraLocal(self._FollowModeCam)
        self._Camera.transform:SetParent(self._Transform)
        self._FollowModeIsStart = true
        if cb then cb() end
    end
end

function XPlanetCamera:SetFollowModeWithAnim(cb)
    self:PlaySound(XPlanetConfigs.SoundCueId.CamNear)
    self:FreeModeToOtherMode(self._FollowModeTran, self._FollowModeCam, nil, function()
        self._FollowUnLockCurCamPos2Planet = self:GetCameraTransform().position - self:GetTransform().position
        self._FollowUnLockCurFollowTranPos2Planet = self._FollowModeTran.position - self:GetTransform().position
        self._FollowUnLockCamStartRotation = self:GetCameraTransform().rotation
        self._FollowUnLockDeltaRotation = nil
        self._FollowModeIsStart = true
        if cb then cb() end
    end)
end

---@param explore XPlanetRunningExplore
function XPlanetCamera:FollowModeUpdate(explore, deltaTime)
    if not self:CheckIsInFollowMode() then
        return
    end
    if not self._FollowModeIsStart then
        return
    end
    if not explore:GetCaptainTransform() then
        return
    end
    if explore:GetCaptainTransform() ~= self._FollowModeTran then
        self._FollowModeTran = explore:GetCaptainTransform()
        self._FollowModeCurTranForward = self._FollowModeTran.forward
    end
    if self._FollowModeCurTranForward == self._FollowModeTran.forward then
        return
    end
    self._FollowModeCurTranForward = self._FollowModeTran.forward

    -- 不固定朝向角色前方
    local newCurFollowTranPos2Planet = self._FollowModeTran.position - self:GetTransform().position
    if newCurFollowTranPos2Planet == self._FollowUnLockCurFollowTranPos2Planet then
        return
    end
    local deltaRot = Quaternion.FromToRotation(self._FollowUnLockCurFollowTranPos2Planet, newCurFollowTranPos2Planet)
    if not self._FollowUnLockDeltaRotation then
        self._FollowUnLockDeltaRotation = deltaRot
    else
        self._FollowUnLockDeltaRotation = deltaRot * self._FollowUnLockDeltaRotation
    end
    local newCamPosition = deltaRot * self._FollowUnLockCurCamPos2Planet + self:GetTransform().position
    
    self:SetCameraWorldPosition(newCamPosition)
    self:SetCameraWorldRotation(self._FollowUnLockDeltaRotation * self._FollowUnLockCamStartRotation)
    
    self._FollowUnLockCurCamPos2Planet = self:GetCameraTransform().position - self:GetTransform().position
    self._FollowUnLockCurFollowTranPos2Planet = self._FollowModeTran.position - self:GetTransform().position
end

---获取跟随机位Cam相对于CamRoot的LocalPosition, LocalRotation, fov
function XPlanetCamera:_GetFollowResultLocalParams()
    local fromCamPosition = self:GetCameraTransform().localPosition
    local fromCamRotation = self:GetCameraTransform().localRotation
    local fromCamFov = self._Camera.fieldOfView

    local pos, rot, fov 
    if XTool.UObjIsNil(self._FollowModeTran) then
        return fromCamPosition, fromCamRotation, fromCamFov
    end
    self._Camera.transform:SetParent(self._FollowModeTran)
    self:SetCameraLocal(self._FollowModeCam)
    self._Camera.transform:SetParent(self._Transform)
    pos = self:GetCameraTransform().localPosition
    rot = self:GetCameraTransform().localRotation
    fov = self._Camera.fieldOfView

    self:SetCameraLocalPosition(fromCamPosition)
    self:SetCameraLocalRotation(fromCamRotation)
    self:SetCameraFov(fromCamFov)
    return pos, rot, fov
end

---获取跟随机位Cam的Up向量(用于平滑过渡)
function XPlanetCamera:_GetFollowModeResultCamUp()
    local fromCamPosition = self:GetCameraTransform().localPosition
    local fromCamRotation = self:GetCameraTransform().localRotation
    local fromCamFov = self._Camera.fieldOfView

    if XTool.UObjIsNil(self._FollowModeTran) then
        return self._Camera.transform.up
    end
    self._Camera.transform:SetParent(self._FollowModeTran)
    self:SetCameraLocal(self._FollowModeCam)
    self._Camera.transform:SetParent(self._Transform)
    local result = self._Camera.transform.up

    self:SetCameraLocalPosition(fromCamPosition)
    self:SetCameraLocalRotation(fromCamRotation)
    self:SetCameraFov(fromCamFov)
    return result
end

function XPlanetCamera:_GetCamToLocalParams4CamRoot()
    local fromCamRotation = self:GetCameraTransform().localRotation
    local fromCamPosition = self:GetCameraTransform().localPosition
    local fromCamFov = self._Camera.fieldOfView
    return fromCamPosition, fromCamRotation, fromCamFov
end

function XPlanetCamera:_GetFollowTargetPosition()
    if not self._FollowModeTran then
        return Vector3.zero
    end
    return self._FollowModeTran.position
end

function XPlanetCamera:GetCamRootFollowTranRot()
    local forward = self._FollowModeTran.position - self._Transform.position
    local up = self._FollowModeTran.forward
    return Quaternion.LookRotation(forward, up)
end
--endregion


--region 静态模式（不可交互）
---@param camera XPlanetSceneCamera
function XPlanetCamera:ChangeStaticModeByCamera(camera, positionOffset, rotationOffset, isAnim, beginCb, endCb)
    self:ChangeMode(XPlanetConfigs.SceneCameraMode.StaticMode)
    self:GetCameraTransform():SetParent(self:GetTransform())
    self:ResetCameraRoot()
    if isAnim then
        local fromPosition = self:GetCameraTransform().localPosition
        local fromRotation = self:GetCameraTransform().localRotation
        local fromFov = self._Camera.fieldOfView

        local toPosition = camera:GetPosition()
        local toRotation = camera:GetRotation()
        if positionOffset then
            toPosition = toPosition + positionOffset
        end
        if rotationOffset then
            toRotation = toRotation * rotationOffset
        end
        self:MoveCamTo(fromPosition, fromRotation, fromFov, toPosition, toRotation, camera:GetFov(), beginCb, endCb)
    else
        if beginCb then beginCb() end
        self:SetCameraLocal(camera, positionOffset, rotationOffset)
        if endCb then endCb() end
    end
end

function XPlanetCamera:StaticModeMove(position, rotation, isAnim, beginCb, endCb)
    if not self:CheckIsInStaticMode() or self._IsInMove then
        return
    end
    self:GetCameraTransform():SetParent(self:GetTransform())
    if isAnim then
        local fromPosition = self:GetCameraTransform().localPosition
        local fromRotation = self:GetCameraTransform().localRotation
        local fromFov = self._Camera.fieldOfView
        local toPosition = position and position or fromPosition
        local toRotation = rotation and rotation or fromRotation
        local toFov = self._Camera.fieldOfView
        self:MoveCamTo(fromPosition, fromRotation, fromFov, toPosition, toRotation, toFov, beginCb, endCb)
    else
        if beginCb then beginCb() end
        self:SetCameraLocalPosition(position)
        self:SetCameraLocalRotation(rotation)
        if endCb then endCb() end
    end
end
--endregion


--region 剧情模式(不可交互)
function XPlanetCamera:ChangeMovieModeByCamera(camera, lookAtTran, dontAnim, callBack)
    if not lookAtTran then
        if callBack then
            callBack()
        end
        XLog.Error("PlanetCamera change cam Error: lookAtTran is null!")
        return
    end
    self:ChangeMode(XPlanetConfigs.SceneCameraMode.MovieMode)
    if dontAnim then
        self:GetCameraTransform():SetParent(lookAtTran)
        self:SetCameraLocal(camera)
        self:GetCameraTransform():SetParent(self:GetTransform())
        if callBack then
            callBack()
        end
    else
        self:FreeModeToOtherMode(lookAtTran, camera, nil, callBack)
    end
end

--endregion


--region Camera
function XPlanetCamera:SetCameraFov(fov)
    if self._Camera then
        self._Camera.fieldOfView = fov
    end
end

---@param camera XPlanetSceneCamera
function XPlanetCamera:SetCameraLocal(camera, positionOffset, rotationOffset)
    if camera then
        local position = camera:GetPosition()
        if positionOffset then
            position = position + positionOffset
        end
        local rotation = camera:GetRotation()
        if rotationOffset then
            rotation = rotation * rotationOffset
        end
        self:GetCameraTransform().localPosition = position
        self:GetCameraTransform().localRotation = rotation
        self._Camera.fieldOfView = camera:GetFov()
    end
end

function XPlanetCamera:SetCameraLocalPosition(position)
    if position then
        self:GetCameraTransform().localPosition = position
    end
end

function XPlanetCamera:SetCameraLocalRotation(rotation)
    if rotation then
        self:GetCameraTransform().localRotation = rotation
    end
end

---@param camera XPlanetSceneCamera
function XPlanetCamera:SetCameraWorld(camera, positionOffset, rotationOffset)
    if camera then
        local position = camera:GetPosition()
        if positionOffset then
            position = position + positionOffset
        end
        local rotation = camera:GetRotation()
        if rotationOffset then
            rotation = rotation * rotationOffset
        end
        self:GetCameraTransform().position = position
        self:GetCameraTransform().rotation = rotation
        self._Camera.fieldOfView = camera:GetFov()
    end
end

function XPlanetCamera:SetCameraWorldPosition(position)
    if position then
        self:GetCameraTransform().position = position
    end
end

function XPlanetCamera:SetCameraWorldRotation(rotation)
    if rotation then
        self:GetCameraTransform().rotation = rotation
    end
end

function XPlanetCamera:ResetCamera()
    self:GetCameraTransform().localPosition = Vector3.zero
    self:GetCameraTransform().localRotation = Quaternion.identity
    self._Camera.fieldOfView = 60
end
--endregion


--region CameraRoot
function XPlanetCamera:SetCameraRootLocal(position, rotation)
    if position then
        self:GetTransform().localPosition = position
    end
    if rotation then
        self:GetTransform().localRotation = rotation
    end
end

function XPlanetCamera:SetCameraRootLocalPosition(position)
    if position then
        self:GetTransform().localPosition = position
    end
end

function XPlanetCamera:SetCameraRootLocalRotation(rotation)
    if rotation then
        self:GetTransform().localRotation = rotation
    end
end

function XPlanetCamera:SetCameraRootWorld(position, rotation)
    if position then
        self:GetTransform().position = position
    end
    if rotation then
        self:GetTransform().rotation = rotation
    end
end

function XPlanetCamera:SetCameraRootWorldPosition(position)
    if position then
        self:GetTransform().position = position
    end
end

function XPlanetCamera:SetCameraRootWorldRotation(rotation)
    if rotation then
        self:GetTransform().rotation = rotation
    end
end

function XPlanetCamera:ResetCameraRoot()
    self:GetTransform().localPosition = Vector3.zero
    self:GetTransform().localRotation = Quaternion.identity
end
--endregion


--region Anim
---自由模式聚焦动画
function XPlanetCamera:FreeModeLookAt(position, beginCb, endCb)
    if not self:CheckIsInFreeMode() then
        return
    end
    self:FreeAfterDragStop()
    local tran = self:GetTransform()
    local fromRotation = tran.rotation
    local toRotation = self:GetTowardRotation(self:GetCameraCenterRayPosition(), position) * fromRotation
    self:_AnimRotateCamRoot(fromRotation, toRotation, beginCb, endCb)
end

function XPlanetCamera:FreeModeToOtherMode(followTran, camera, beginCb, endCb)
    if self._IsInMove then
        return
    end
    self:FreeAfterDragStop()

    local fromPosition, fromRotation, fromFov
    local toPosition, toRotation, toFov
    local fromUp, toUp
    local tempRot = Quaternion.identity
    local targetPos = followTran.position
    
    -- 机位变转
    local onRefresh04 = function(t)
        self:SetCameraLocalPosition(Vector3.SlerpUnclamped(fromPosition, toPosition, t))
        local forward = targetPos - self:GetCameraTransform().position
        tempRot:SetLookRotation(forward, Vector3.SlerpUnclamped(fromUp, toUp, t))
        self:SetCameraWorldRotation(tempRot)
        self:SetCameraFov(fromFov + (toFov - fromFov) * t)
    end
    local onEnd = function()
        self:SetCameraLocalPosition(toPosition)
        self:SetCameraWorldRotation(toRotation)
        self:SetCameraFov(toFov)

        XLuaUiManager.SetMask(false)
        self._IsInMove = false
        if endCb then endCb() end
    end

    -- 校准
    local onRefresh03 = function(t)
        tempRot:SetLookRotation(targetPos - self:GetCameraTransform().position, fromUp)
        self:SetCameraWorldRotation(Quaternion.Lerp(fromRotation, tempRot, t))
    end
    local onEnd03 = function()
        XUiHelper.Tween(1.2, onRefresh04, onEnd)
    end

    -- 定位到followTran
    local rootFromRotation = self:GetTransform().localRotation
    local rootFromPosition = self:GetCameraCenterRayPosition()
    local followPosition = followTran.position
    local rootToRotation = self:GetTowardRotation(rootFromPosition, followPosition) * rootFromRotation
    
    local onRefresh02 = function(t)
        self:SetCameraRootLocal(nil,  Quaternion.Lerp(rootFromRotation, rootToRotation, t))
    end
    local onEnd02 = function()
        self._FollowModeCurTranForward = followTran.forward
        self._FollowModeStartPosition = followTran.position
        self._FollowModeStartRotation = self._Transform.rotation
        fromPosition = self:GetCameraTransform().localPosition
        fromRotation = self:GetCameraTransform().rotation
        fromFov = self._Camera.fieldOfView
        fromUp = self:GetCameraTransform().up
        self:GetCameraTransform():SetParent(followTran)
        self:SetCameraLocal(camera)
        self:GetCameraTransform():SetParent(self:GetTransform())
        toPosition = self:GetCameraTransform().localPosition
        toRotation = self:GetCameraTransform().rotation
        toFov = camera:GetFov()
        toUp = self:GetCameraTransform().up

        -- 计算相机注视点
        local target2CamVector = followTran.position - self:GetCameraTransform().position
        local camTarget2CamVector = Vector3.Project(target2CamVector, self:GetCameraTransform().forward)
        targetPos = self:GetCameraTransform().position + camTarget2CamVector

        self:SetCameraLocalPosition(fromPosition)
        self:SetCameraWorldRotation(fromRotation)
        
        XUiHelper.Tween(0.1, onRefresh03, onEnd03)
    end

    -- 缩放至最高
    self._FreeToFollowScrollValue = self._FreeModeScrollValue
    local onRefresh01 = function(t)
        self:_FreeModeSetAndCheckScrollValue((1 - self._FreeToFollowScrollValue) * t + self._FreeToFollowScrollValue)
        self:_FreeModeSetCurCamera()
    end
    local onEnd01 = function()
        XUiHelper.Tween(0.5, onRefresh02, onEnd02)
    end

    XLuaUiManager.SetMask(true)
    self._IsInMove = true
    if beginCb then beginCb() end
    -- 最高不缩放
    if self._FreeModeScrollValue == 1 then
        onEnd01()
    else
        XUiHelper.Tween(0.5 * (1 - self._FreeModeScrollValue), onRefresh01, onEnd01)
    end
end

function XPlanetCamera:FreeModeScrollToValue(value, beginCb, endCb)
    if self._IsInMove then
        return
    end
    self:FreeAfterDragStop()

    self._FreeToFollowScrollValue = self._FreeModeScrollValue
    local onRefresh01 = function(t)
        self:_FreeModeSetAndCheckScrollValue((value - self._FreeToFollowScrollValue) * t + self._FreeToFollowScrollValue)
        self:_FreeModeSetCurCamera()
    end
    local onEnd01 = function()
        self:_FreeModeSetAndCheckScrollValue(value)
        self:_FreeModeSetCurCamera()
        XLuaUiManager.SetMask(false)
        self._IsInMove = false
        if endCb then endCb() end
    end

    XLuaUiManager.SetMask(true)
    self._IsInMove = true
    if beginCb then beginCb() end
    -- 最高不缩放
    if self._FreeModeScrollValue == value then
        onEnd01()
    else
        XUiHelper.Tween(0.5, onRefresh01, onEnd01)
    end
end

---旋转根节点
function XPlanetCamera:_AnimRotateCamRoot(fromRotation, toRotation, beginCb, endCb)
    if self._IsInMove then
        return
    end
    XLuaUiManager.SetMask(true)
    self._IsInMove = true
    if beginCb then beginCb() end
    XUiHelper.Tween(0.5, function(t)
        self:SetCameraRootLocalRotation(Quaternion.Slerp(fromRotation, toRotation, t))
    end, function()
        self:SetCameraRootLocalRotation(toRotation)
        XLuaUiManager.SetMask(false)
        self._IsInMove = false
        if endCb then endCb() end
    end)
end
--endregion


--region 音效
---@param cueId number XPlanetConfigs.SoundCueId
function XPlanetCamera:PlaySound(cueId)
    XSoundManager.PlaySoundByType(cueId, XSoundManager.SoundType.Sound)
end
--endregion


--region 相机轨迹动画
function XPlanetCamera:MoveCamRootTo(fromPosition, fromRotation, toPosition, toRotation, beginCb, endCb)
    if self._IsInMove then
        return
    end
    XLuaUiManager.SetMask(true)
    if beginCb then beginCb() end
    XUiHelper.Tween(0.5, function(t)
        self._IsInMove = true
        if fromPosition then
            self:SetCameraRootLocalPosition(CS.UnityEngine.Vector3.Slerp(fromPosition, toPosition, t))
        end
        self:SetCameraRootLocalRotation(Quaternion.Slerp(fromRotation, toRotation, t))
    end, function()
        
        if endCb then endCb() end
        self:SetCameraRootLocalRotation(toRotation)
        self:SetCameraRootLocalPosition(toPosition)
        XLuaUiManager.SetMask(false)
        self._IsInMove = false
    end)
end

---@param fromCamera XPlanetSceneCamera
---@param toCamera XPlanetSceneCamera
function XPlanetCamera:MoveCamToByCamera(fromCamera, toCamera, beginCb, endCb)
    local fromPosition = fromCamera and fromCamera:GetPosition() or self:GetCameraTransform().localPosition
    local fromRotation = fromCamera and fromCamera:GetRotation() or self:GetCameraTransform().localRotation
    local fromFov = fromCamera and fromCamera:GetFov() or self._Camera.fieldOfView
    local toPosition = toCamera:GetPosition()
    local toRotation = toCamera:GetRotation()
    local toFov = toCamera:GetFov()
    self:MoveCamTo(fromPosition, fromRotation, fromFov, toPosition, toRotation, toFov, beginCb, endCb)
end

function XPlanetCamera:MoveCamTo(fromPosition, fromRotation, fromFov, toPosition, toRotation, toFov, beginCb, endCb)
    if self._IsInMove then
        return
    end
    XLuaUiManager.SetMask(true)
    if beginCb then beginCb() end
    XUiHelper.Tween(0.5, function(t)
        self._IsInMove = true
        self:SetCameraLocalRotation(Quaternion.Slerp(fromRotation, toRotation, t))
        self:SetCameraLocalPosition(CS.UnityEngine.Vector3.Slerp(fromPosition, toPosition, t))
        self:SetCameraFov(fromFov + (toFov - fromFov) * t)
    end, function()
        self:SetCameraLocalRotation(toRotation)
        self:SetCameraLocalPosition(toPosition)
        self:SetCameraFov(toFov)
        XLuaUiManager.SetMask(false)
        self._IsInMove = false
        if endCb then endCb() end
    end)
end

---跟随视角转自由平滑过渡
function XPlanetCamera:MoveCamFollowToFree(beginCb, endCb)
    if self._IsInMove then
        return
    end
    self._IsInMove = true

    local tempUp = self:GetCameraTransform().up
    local fromPosition, fromRotation, fromFov = self:_GetCamToLocalParams4CamRoot()
    self:_FreeModeSetCurCamera()
    local targetUp = self:GetCameraTransform().up
    local toPosition, toRotation, toFov = self:_GetCamToLocalParams4CamRoot()
    self:SetCameraLocalPosition(fromPosition)
    self:SetCameraLocalRotation(fromRotation)
    self:SetCameraFov(fromFov)
    local tempRot = Quaternion.identity

    local target2CamVector = self._FreeModeLookPosition - self:GetCameraTransform().position
    local camTarget2CamVector = Vector3.Project(target2CamVector, self:GetCameraTransform().forward)
    local targetPos = self:GetCameraTransform().position + camTarget2CamVector
    local onRefresh = function(t)
        -- 二次缓动position以适应rotation平滑缓动
        self:SetCameraLocalPosition(Vector3.Slerp(fromPosition, Vector3.Slerp(fromPosition, toPosition, t), t))

        local up = CS.UnityEngine.Vector3.Lerp(tempUp, targetUp, t) -- 二次缓动rotation平滑看向跟随目标
        tempRot:SetLookRotation(targetPos - self:GetCameraTransform().position, up)
        self:SetCameraWorldRotation(tempRot)
        self:SetCameraFov(fromFov + (toFov - fromFov) * t)
        --fromRotation = self:GetCameraTransform().localRotation    -- 一次缓动rotation结果
    end
    local onFinish = function()
        XUiHelper.Tween(0.1, function(t)
            local tempF = Quaternion.Slerp(self:GetCameraTransform().localRotation, toRotation, t)
            self:SetCameraLocalRotation(tempF)
        end, function()
            self:_FreeModeSetCurCamera()
            XLuaUiManager.SetMask(false)
            self._IsInMove = false
            if endCb then
                endCb()
            end
        end)
    end

    if beginCb then beginCb() end
    XLuaUiManager.SetMask(true)
    XUiHelper.Tween(1, onRefresh, onFinish)
end

---获取聚焦球体目标旋转向量
---@param fromPosition Vector3 当前相机朝向点世界坐标
---@param targetPosition Vector3 目标点世界坐标
---@param fromRotation Quaternion 起始旋转向量
function XPlanetCamera:GetLookAtRotation(fromPosition, targetPosition, fromRotation)
    local tran = self:GetTransform()

    local fromDirection = (fromPosition - tran.position).normalized
    local toDirection = (targetPosition - tran.position).normalized
    local rot = Quaternion.FromToRotation(fromDirection, toDirection)
    return rot * fromRotation
end

---获取CameraRoot聚焦目标旋转差值
---@param fromPosition Vector3 当前相机朝向点世界坐标
---@param targetPosition Vector3 目标点世界坐标
function XPlanetCamera:GetTowardRotation(fromPosition, targetPosition)
    local tran = self:GetTransform()

    local fromDirection = (fromPosition - tran.position).normalized
    local toDirection = (targetPosition - tran.position).normalized
    local rot = Quaternion.FromToRotation(fromDirection, toDirection)
    return rot
end

---获取Transform朝向lookPosition的LocalRotation
---@return Quaternion
function XPlanetCamera:GetTranLookAtLocalRotation(transform, lookPosition, up)
    local rot = transform.rotation
    transform:LookAt(lookPosition, up)
    local toR = transform.localRotation
    transform.rotation = rot
    return toR
end
--endregion


--region 射线检测
---射线检测地板对象
---@return CS.UnityEngine.Transfrom
function XPlanetCamera:RayTileCastByScreenPoint(screenPoint, mask)
    local ray = self._Camera:ScreenPointToRay(screenPoint)
    if not mask then
        mask = CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.HomeCharacter) | CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.Room)
    end
    local hit = self:GetCameraTransform():PhysicsRayCast(Vector3.zero, ray.direction, mask)
    return hit
end

---射线检测地板对象
---@return CS.UnityEngine.Transfrom
function XPlanetCamera:RayTileCast()
    return self:RayCast(CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.Room))
end

---射线检测角色对象
---@return CS.UnityEngine.Transfrom
function XPlanetCamera:RayRoleCast()
    return self:RayCast(CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.HomeCharacter))
end

---射线检测场景所有层级对象
---@return CS.UnityEngine.Transfrom
function XPlanetCamera:RayCast(mask)
    local platform = CS.UnityEngine.Application.platform
    local touchPosition = Vector3.zero
    if platform == CS.UnityEngine.RuntimePlatform.WindowsEditor or
            platform == CS.UnityEngine.RuntimePlatform.WindowsPlayer
    then
        touchPosition = Input.mousePosition
    else
        if Input.touchCount > 1 then
            touchPosition = Vector3(Input.GetTouch(0).position.x, Input.GetTouch(0).position.y, 0)
        else
            touchPosition = Input.mousePosition
        end
    end
    local ray = self._Camera:ScreenPointToRay(touchPosition)
    if not mask then
        mask = CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.HomeCharacter) | CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.Room)
    end
    local hit = self:GetCameraTransform():PhysicsRayCast(Vector3.zero, ray.direction, mask)
    return hit
end

function XPlanetCamera:GetCameraCenterRay(mask)
    local screen = CS.UnityEngine.Screen
    local screenPointCenter = Vector3(screen.width / 2, screen.height / 2, 0)
    local ray = self._Camera:ScreenPointToRay(screenPointCenter)
    if not mask then
        mask = CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.HomeCharacter) | CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.Room)
    end
    local hit = self:GetCameraTransform():PhysicsRayCast(Vector3.zero, ray.direction, mask)
    return hit
end

---获取相机中心射线碰撞点坐标
---@return Vector3
function XPlanetCamera:GetCameraCenterRayPosition(mask)
    local hit = self:GetCameraCenterRay(mask)
    if hit then
        return hit.position
    end
    return Vector3.forward
end
--endregion


--region 加载
---获取CameraRoot
function XPlanetCamera:GetCamera()
    return self._Camera
end

---获取CameraRoot
function XPlanetCamera:GetTransform()
    return self._Transform
end

---获取Camera
function XPlanetCamera:GetCameraTransform()
    return self._Camera.transform
end

function XPlanetCamera:InitCamera()
    if not self._Camera then
        local go = self._Transform:LoadPrefab(XPlanetConfigs.GetCamPrefab())
        if XTool.UObjIsNil(go) then
            go = CS.UnityEngine.GameObject("_PlanetCamera")
        end
        go.transform:SetParent(self._Transform)
        self._Camera = go:GetComponent("Camera")
        if XTool.UObjIsNil(self._Camera) then
            self._Camera = go:AddComponent(typeof(CS.UnityEngine.Camera))
            self._Camera.usePhysicalProperties = true
        end
        -- 物理相机缩放处理
        local screenWidth = CS.UnityEngine.Screen.width
        local screenHeight = CS.UnityEngine.Screen.height
        if screenWidth / screenHeight > 2 then  -- 长屏适配
            local oldSize = self._Camera.sensorSize
            self._Camera.sensorSize = Vector2(43, oldSize.y)
        end

        -- 设置相机碰撞检测
        go:AddComponent(typeof(CS.UnityEngine.PostProcessing.PostProcessingBehaviour))
        local physicsRaycaster = go:GetComponent(typeof(CS.UnityEngine.EventSystems.PhysicsRaycaster))
        if not physicsRaycaster then
            physicsRaycaster = go:AddComponent(typeof(CS.UnityEngine.EventSystems.PhysicsRaycaster))
        end
        physicsRaycaster:SetEventMask(CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.HomeCharacter) | CS.UnityEngine.LayerMask.GetMask(HomeSceneLayerMask.Room))
        self:ResetCamera()
    end
    
    local postProcessContainer = self._GameObject:GetComponent(typeof(CS.XPostProcessContainer))
    if postProcessContainer then
        postProcessContainer:SetPostProcessingProfile(self._Camera.gameObject)
    end
end

--- 释放资源
---@return void
function XPlanetCamera:Release()
    self:TryDestroy(self._GameObject)
    self._GameObject = nil
    self._Transform = nil
    self._Camera = nil
    self:_InitFreeModeParams()
    self:_InitFollowModeParams()
end

--- 删除游戏物体
---@param obj UnityEngine.GameObject 物体
---@return boolean 是否销毁成功
function XPlanetCamera:TryDestroy(obj)
    if XTool.UObjIsNil(obj) then
        return false
    end
    XUiHelper.Destroy(obj)
    obj = nil
    return true
end

function XPlanetCamera:Exist()
    return not XTool.UObjIsNil(self._GameObject)
end
--endregion

return XPlanetCamera