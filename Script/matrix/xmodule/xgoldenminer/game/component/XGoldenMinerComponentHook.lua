local Vector3Zero = Vector3.zero
local CSQuaternion = CS.UnityEngine.Quaternion
local Physics2D = CS.UnityEngine.Physics2D

local REFLECT_EDGE_CONTACT_FILTER2D_MIN_DEPTH = 6 -- Normal画布距离是5 加一为了跳过基础元素 只检测反射Collider
local LAYER_MASK_UI = CS.UnityEngine.LayerMask.GetMask("UI")

---@class XGoldenMinerComponentHook:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityHook
local XGoldenMinerComponentHook = XClass(XEntity, "XGoldenMinerComponentHook")

--region Override
function XGoldenMinerComponentHook:OnInit()
    self.Type = 0
    self.Status = XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.NONE

    -- Static Value
    ---@type UnityEngine.Transform
    self.Transform = nil
    ---@type UnityEngine.Transform
    self._GrabPoint = nil
    ---@type UnityEngine.Transform
    self._HookObj = nil
    self._IdleSpeed = 0
    self._ShootSpeed = 0
    self._RopeMinLength = 0
    self._RopeMaxLength = 0
    self._RopeLeftAngleLimit = 0
    self._RopeRightAngleLimit = 0
    ---@type UnityEngine.Vector3
    self._HookObjStartLocalPosition = nil
    ---@type UnityEngine.Vector3
    self._RopeObjStartLocalPosition = nil
    ---@type UnityEngine.Transform[]
    self._AimTranList = {}
    ---绳子碰撞点，用于碰撞转向点
    ---@type UnityEngine.Collider2D
    self._RopeCollider = nil
    ---@type UnityEngine.Collider2D[]
    self._ColliderList = {}
    ---第一段绳子起始位置坐标
    self._IgnoreTypeList = {}
    self._ExIgnoreStoneTypeDir = {}
    self._CanGrabDestroyStoneTypeDir = {}
    ---@type XGoInputHandler
    self.RopeInputHandler = nil
    ---@type XGoInputHandler[]
    self.GoInputHandlerList = {}
    self._MaxReflectCount = 0
    self._ReflectLimitCountByBuff = 0

    -- Dynamic value
    ---@type boolean
    self._IsAim = false
    ---@type UnityEngine.Transform[]
    self._CurRopeObjList = {}
    self._CurShootSpeed = 0
    self._CurRopeLength = 0
    self._CurRevokeSpeedPercent = 1
    ---@type number
    self._CurIdleRotateDirection = false
    ---@type XLuaVector3
    self._CurIdleRotateAngle = XLuaVector3.New()
    ---@type number
    self._LastReflectRotateAngle = nil
    self._ReflectCount = 0
    ---Z轴角度
    ---@type UnityEngine.Vector3[]
    self._CurMoveAngleList = {}
    ---当前移动路径起点(localPosition)
    ---@type UnityEngine.Vector3[]
    self._CurMoveStartPointList = {}
    ---撞到转向点时线段总长度字典
    self._CurMoveHitPointLengthList = {}
    self._CurMoveDelayChangeAngleTime = 0
    self._CurMoveCacheAngle = 0
    self._IsNoShowFaceId = false

    ---@type XLuaVector3
    self._CacheRopeDeltaPos = XLuaVector3.New()
    ---@type XLuaVector2
    self._CacheRopeSize = XLuaVector2.New()

    self._IsHumanReversMoveBuffAlive = false -- 倒反天罡Buff影响
    self._CurRopeDetailVector = 0
    self._CurRopeAngleZ = 0
    self._MaxRevokeRopeLength = 0
    self._CurRevokeRopeLength = 0
    ---@type number
    self._AimReflectCount = 0
    self._ReflectAimList = {}
end

function XGoldenMinerComponentHook:OnRelease()
    self._AimTranList = nil
    self._ColliderList = nil
    self._RopeCollider = nil
    self._IgnoreTypeList = nil
    self._ExIgnoreStoneTypeDir = nil
    self._CanGrabDestroyStoneTypeDir = nil
    if self.RopeInputHandler then
        self.RopeInputHandler:RemoveAllListeners()
    end
    self.RopeInputHandler = nil
    for _, obj in ipairs(self.GoInputHandlerList) do
        obj:RemoveAllListeners()
    end
    self.GoInputHandlerList = nil

    self._CurRopeObjList = nil
    self._CurIdleRotateAngle = nil
    self._LastReflectRotateAngle = nil
    self._ReflectCount = nil
    self._CurMoveAngleList = nil
    self._CurMoveStartPointList = nil
    self._CurMoveHitPointLengthList = nil
    self._IsNoShowFaceId = nil

    self._CacheRopeDeltaPos = nil
    self._CacheRopeSize = nil

    self._IsHumanReversMoveBuffAlive = nil
    self._CurRopeDetailVector = 0
    self._CurRopeAngleZ = 0
    self._MaxRevokeRopeLength = 0
    self._CurRevokeRopeLength = 0
    self._AimReflectCount = 0
    self._ReflectAimList = nil
end
--endregion

--region Getter
function XGoldenMinerComponentHook:GetHookEntity()
    return self._ParentEntity
end

function XGoldenMinerComponentHook:GetGrabPoint()
    return self._GrabPoint
end

function XGoldenMinerComponentHook:GetAimTranList()
    return self._AimTranList
end

function XGoldenMinerComponentHook:GetShootSpeed()
    return self._ShootSpeed
end

function XGoldenMinerComponentHook:GetCurHookPosition()
    return self._HookObj.position
end

function XGoldenMinerComponentHook:GetCurRopeLength()
    return self._CurRopeLength
end

function XGoldenMinerComponentHook:GetCurShootSpeed()
    return self._CurShootSpeed
end

function XGoldenMinerComponentHook:GetCurRevokeSpeedPercent()
    return self._CurRevokeSpeedPercent
end

function XGoldenMinerComponentHook:GetCurIdleRotateAngle()
    return self._CurIdleRotateAngle
end

function XGoldenMinerComponentHook:GetLastReflectRotateAngle()
    return self._LastReflectRotateAngle
end

function XGoldenMinerComponentHook:GetReflectCount()
    return self._ReflectCount
end

function XGoldenMinerComponentHook:IsNoShowFaceId()
    return self._IsNoShowFaceId
end

function XGoldenMinerComponentHook:GetCurRopeDetailVector()
    return self._CurRopeDetailVector
end

function XGoldenMinerComponentHook:GetCurRopeAngleZ()
    if self._CurRopeAngleZ < 0 then
        self._CurRopeAngleZ = self._CurRopeAngleZ + 360
    elseif self._CurRopeAngleZ > 360 then
        self._CurRopeAngleZ = self._CurRopeAngleZ % 360
    end
    return self._CurRopeAngleZ
end
--endregion

--region Setter
function XGoldenMinerComponentHook:SetTransform(transform, length)
    self.Transform = transform
    self._HookObj = XUiHelper.TryGetComponent(self.Transform, "Hook")
    self._HookObjStartLocalPosition = self._HookObj.localPosition
    self._GrabPoint = XUiHelper.TryGetComponent(self.Transform, "Hook/RopeCord/TriggerObjs")
    self._CurRopeObjList = { XUiHelper.TryGetComponent(self.Transform, "RopeRoot/Rope") }
    self._RopeObjStartLocalPosition = self._CurRopeObjList[1].localPosition
    self._AimTranList = {
        XUiHelper.TryGetComponent(self.Transform, "Hook/RopeCord/Aim"),
        XUiHelper.TryGetComponent(self.Transform, "Hook/RopeCord/Aim2"),
        XUiHelper.TryGetComponent(self.Transform, "Hook/RopeCord/Aim3")
    }
    self:_SetHitCollider(self._HookObj.gameObject:GetComponentsInChildren(typeof(CS.UnityEngine.Collider2D)))
    self:_SetRopeCollider(XUiHelper.TryGetComponent(self.Transform, "RopeCollider"))

    for _, aim in pairs(self._AimTranList) do
        self._CacheRopeSize:Update(aim.sizeDelta.x, length)
        aim.sizeDelta = self._CacheRopeSize
        aim.gameObject:SetActiveEx(false)
    end
    self._CurIdleRotateAngle:UpdateByVector(self.Transform.localRotation.eulerAngles)
    self:_CheckAndSetIdleRotateAngleLimit()
end

---@param collider2DList System.Collections.ArrayList<UnityEngine.Collider2D>
function XGoldenMinerComponentHook:_SetHitCollider(collider2DList)
    for i = 0, collider2DList.Length - 1 do
        self._ColliderList[i + 1] = collider2DList[i]
        self.GoInputHandlerList[i + 1] = self._ColliderList[i + 1].transform:GetComponent(typeof(CS.XGoInputHandler))
        if XTool.UObjIsNil(self.GoInputHandlerList[i + 1]) then
            self.GoInputHandlerList[i + 1] = self._ColliderList[i + 1].transform.gameObject:AddComponent(typeof(CS.XGoInputHandler))
        end
    end
end

---@param ropeColliderObj UnityEngine.Transform
function XGoldenMinerComponentHook:_SetRopeCollider(ropeColliderObj)
    if ropeColliderObj then
        self._RopeCollider = ropeColliderObj.transform:GetComponent(typeof(CS.UnityEngine.Collider2D))
        self.RopeInputHandler = self._RopeCollider.transform:GetComponent(typeof(CS.XGoInputHandler))
        if XTool.UObjIsNil(self.RopeInputHandler) then
            self.RopeInputHandler = self._RopeCollider.gameObject:AddComponent(typeof(CS.XGoInputHandler))
        end
    end
end

function XGoldenMinerComponentHook:SetStatus(status)
    self.Status = status
end

function XGoldenMinerComponentHook:SetType(type)
    self.Type = type
end

function XGoldenMinerComponentHook:SetRopeAngleLimit(leftLimit, rightLimit)
    self._RopeLeftAngleLimit = leftLimit
    self._RopeRightAngleLimit = rightLimit
end

function XGoldenMinerComponentHook:SetRopeLengthLimit(maxLimit)
    self._RopeMaxLength = maxLimit
    self._RopeMinLength = self._CurRopeObjList[1].sizeDelta.y
    self._CurRopeLength = self._RopeMinLength
end

function XGoldenMinerComponentHook:SetIdleSpeed(value)
    self._IdleSpeed = value
end

function XGoldenMinerComponentHook:SetShootSpeed(value)
    self._ShootSpeed = value
    self:SetCurShootSpeed(value)
end

function XGoldenMinerComponentHook:SetAim(isAim, reflectCount)
    self._IsAim = isAim
    self._AimReflectCount = reflectCount
    self:UpdateAim()
end

function XGoldenMinerComponentHook:SetIgnoreTypeList(ignoreTypeList)
    self._IgnoreTypeList = ignoreTypeList
end

function XGoldenMinerComponentHook:SetExIgnoreTypeDir(list)
    for _, type in ipairs(list) do
        self._ExIgnoreStoneTypeDir[type] = true
    end
end

function XGoldenMinerComponentHook:SetGrabDestroyTypeDir(list, isClear)
    if isClear then
        self._CanGrabDestroyStoneTypeDir = {}
    end
    if not XTool.IsTableEmpty(list) then
        for _, type in ipairs(list) do
            self._CanGrabDestroyStoneTypeDir[type] = true
        end
    end
end

function XGoldenMinerComponentHook:SetCurShootSpeed(value)
    self._CurShootSpeed = value
end

function XGoldenMinerComponentHook:SetCurRevokeSpeedPercent(value)
    self._CurRevokeSpeedPercent = value
end

function XGoldenMinerComponentHook:AddCurHitPointInfo(angle)
    self._CurMoveStartPointList[#self._CurMoveStartPointList + 1] = self._HookObj.localPosition
    self._CurMoveHitPointLengthList[#self._CurMoveHitPointLengthList + 1] = self:GetCurRopeLength()
    self._CurMoveAngleList[#self._CurMoveAngleList + 1] = angle
end

function XGoldenMinerComponentHook:OnHookChangeToRevoke()
    self._MaxRevokeRopeLength = self._CurRopeLength
end

function XGoldenMinerComponentHook:SetIsNoShowFaceId(value)
    self._IsNoShowFaceId = value
end

function XGoldenMinerComponentHook:SetLastReflectRotateAngle(value)
    self._LastReflectRotateAngle = value
end

function XGoldenMinerComponentHook:SetReflectCount(value)
    self._ReflectCount = value
end

function XGoldenMinerComponentHook:SetMaxReflectCount(value)
    self._MaxReflectCount = value
end

function XGoldenMinerComponentHook:SetReflectLimitCountByBuff(value)
    self._ReflectLimitCountByBuff = value
end

function XGoldenMinerComponentHook:SetIsHumanReversMoveBuffAlive(alive)
    self._IsHumanReversMoveBuffAlive = alive
end
--endregion

--region Check
function XGoldenMinerComponentHook:CheckStatus(status)
    return self.Status == status
end

function XGoldenMinerComponentHook:CheckType(type)
    return self.Type == type
end

---@param collider UnityEngine.Collider2D
function XGoldenMinerComponentHook:CheckIsTheHook(collider)
    if not XTool.IsTableEmpty(self._ColliderList) then
        for _, hookCollider in ipairs(self._ColliderList) do
            if hookCollider == collider then
                return true
            end
        end
    end
    if self._RopeCollider and self._RopeCollider == collider then
        return true
    end
    return false
end

function XGoldenMinerComponentHook:CheckIsIgnoreStoneType(type)
    for _, ignoreType in ipairs(self._IgnoreTypeList) do
        if ignoreType == type then
            return true
        end
    end
    if self._ExIgnoreStoneTypeDir[type] then
        return true
    end
    return false
end

function XGoldenMinerComponentHook:CheckIsGrabDestroyType(type)
    if self._CanGrabDestroyStoneTypeDir[type] then
        return true
    end
    return false
end

function XGoldenMinerComponentHook:CheckIsRevoke()
    return self._CurRopeLength >= self._RopeMaxLength
end

function XGoldenMinerComponentHook:CheckIsIdle()
    return self._CurRopeLength <= self._RopeMinLength
end

function XGoldenMinerComponentHook:CheckHaveHitPoint()
    return not XTool.IsTableEmpty(self._CurMoveStartPointList)
end

function XGoldenMinerComponentHook:_CheckIsRopeLeftLimit()
    return self._CurIdleRotateAngle.z <= self._RopeLeftAngleLimit
end

function XGoldenMinerComponentHook:_CheckIsRopeRightLimit()
    return self._CurIdleRotateAngle.z >= self._RopeRightAngleLimit
end

function XGoldenMinerComponentHook:_CheckCurIdleRotateDirectionIsLeft()
    return self._CurIdleRotateDirection == -1
end

function XGoldenMinerComponentHook:_CheckCurIdleRotateDirectionIsRight()
    return self._CurIdleRotateDirection == 1
end

function XGoldenMinerComponentHook:_CheckAndSetIdleRotateAngleLimit()
    if self:_CheckIsRopeLeftLimit() then
        self._CurIdleRotateAngle:Update(nil, nil, self._RopeLeftAngleLimit)
    elseif self:_CheckIsRopeRightLimit() then
        self._CurIdleRotateAngle:Update(nil, nil, self._RopeRightAngleLimit)
    end
end

function XGoldenMinerComponentHook:_CheckIsDelayChangeAngle()
    return self._CurMoveDelayChangeAngleTime > 0
end

function XGoldenMinerComponentHook:CheckCanReflect()
    return self._ReflectCount < self._ReflectLimitCountByBuff and self._ReflectCount < self._MaxReflectCount
end

--检查是否倒反天罡影响钩子回收逻辑
function XGoldenMinerComponentHook:_CheckCanReverseMove()
    return self._IsHumanReversMoveBuffAlive and not XTool.IsTableEmpty(self._OwnControl.SystemHook:GetAllHookGrabbingEntityUidList())
end
--endregion

--region Control - StatusChange
function XGoldenMinerComponentHook:ChangeShooting()
    self._CurMoveStartPointList = { self._HookObjStartLocalPosition }
    self._CurMoveHitPointLengthList = {}
    self._CurMoveAngleList = { Vector3Zero }
    self._CurMoveDelayChangeAngleTime = 0
    self._CurRevokeRopeLength = 0
    self:UpdateHitColliderEnable(true)
end
--endregion

--region Control - Update
function XGoldenMinerComponentHook:UpdateHitColliderEnable(value)
    for _, collider in ipairs(self._ColliderList) do
        collider.enabled = value
    end
end

function XGoldenMinerComponentHook:UpdateAim(isClose)
    if XTool.IsTableEmpty(self._AimTranList) then
        return
    end
    local isShow = false

    if isClose ~= nil then
        isShow = isClose
    else
        isShow = self._IsAim
    end

    if XTool.IsNumberValid(self._AimReflectCount) then
        if isShow then
            ---- 关于墙壁反射的瞄准线
            local rotation = CSQuaternion.Euler(self._CurIdleRotateAngle)
            local hookDirection = rotation * Vector3.down
            local aimLineDataList = { { position = Vector2(self.Transform.position.x, self.Transform.position.y),
                                        direction = Vector2(hookDirection.x, hookDirection.y),
                                        originCollider = nil } }

            self:_FillAimLineDataList(aimLineDataList, self._AimReflectCount)

            for index, data in ipairs(aimLineDataList) do
                --if index ~= 1 then
                -- 等于1时为默认基础瞄准线
                local reflectAim = self:_GetReflectAim(index)
                if reflectAim then
                    reflectAim.position = Vector3(data.position.x, data.position.y, reflectAim.position.z)
                    reflectAim.rotation = CSQuaternion.Euler(0, 0, Vector2.SignedAngle(Vector2.down, data.direction))
                end
                --end
            end
        else
            for _, reflectAimTrans in ipairs(self._ReflectAimList) do
                reflectAimTrans.gameObject:SetActiveEx(false)
            end
        end
    else
        for _, aim in pairs(self._AimTranList) do
            aim.gameObject:SetActiveEx(isShow)
        end
    end

    --if isShow and XTool.IsNumberValid(self._AimReflectCount) then
    --    ---- 关于墙壁反射的瞄准线
    --    local rotation = CSQuaternion.Euler(self._CurIdleRotateAngle)
    --    local hookDirection = rotation * Vector3.down
    --    local aimLineDataList = { { position = Vector2(self.Transform.position.x, self.Transform.position.y),
    --                                direction = Vector2(hookDirection.x, hookDirection.y),
    --                                originCollider = nil } }
    --
    --    self:_FillAimLineDataList(aimLineDataList, self._AimReflectCount)
    --
    --    for index, data in ipairs(aimLineDataList) do
    --        --if index ~= 1 then
    --        -- 等于1时为默认基础瞄准线
    --        local reflectAim = self:_GetReflectAim(index)
    --        if reflectAim then
    --            reflectAim.position = Vector3(data.position.x, data.position.y, reflectAim.position.z)
    --            reflectAim.rotation = CSQuaternion.Euler(0, 0, Vector2.SignedAngle(Vector2.down, data.direction))
    --        end
    --        --end
    --    end
    --else
    --    for _, reflectAimTrans in ipairs(self._ReflectAimList) do
    --        reflectAimTrans.gameObject:SetActiveEx(false)
    --    end
    --end
end

function XGoldenMinerComponentHook:_FillAimLineDataList(aimLineDataList, reflectCount)
    local tableCount = XTool.GetTableCount(aimLineDataList)
    if tableCount == 0 then
        return
    end

    if tableCount >= reflectCount + 1 then
        return aimLineDataList
    end

    local pos, dir, collider = self:_GetReflectedStartPosAndAngle(aimLineDataList[tableCount].position, aimLineDataList[tableCount].direction, aimLineDataList[tableCount].originCollider)
    if not pos or not dir or not collider then
        return aimLineDataList
    end

    table.insert(aimLineDataList, { position = pos, direction = dir, originCollider = collider })

    self:_FillAimLineDataList(aimLineDataList, reflectCount)
end

---@param startPos UnityEngine.Vector2
---@param direction UnityEngine.Vector2
---@param originCollider UnityEngine.Collider2D
---@return UnityEngine.Vector2, UnityEngine.Vector2, UnityEngine.Collider2D
---通过传入的起始点和方向，获取反射点和反射方向（参数originCollider标记是从哪个反射墙返弹的，下次计算需要过滤掉）
function XGoldenMinerComponentHook:_GetReflectedStartPosAndAngle(startPos, direction, originCollider)
    -- 根据深度筛选到只有反射平面的碰撞体
    local hitResults = Physics2D.RaycastAll(startPos, direction, 10000, LAYER_MASK_UI, REFLECT_EDGE_CONTACT_FILTER2D_MIN_DEPTH)

    for i = 0, hitResults.Length - 1 do
        local hitInfo = hitResults[i]
        local hitCollider = hitInfo.collider
        if not originCollider or hitCollider ~= originCollider then
            local reflectEdgeEntityUid = self._OwnControl.SystemMap:GetReflectEdgeUidByCollider(hitCollider)
            if XTool.IsNumberValid(reflectEdgeEntityUid) then
                local hitPoint = hitInfo.point
                local hitNormal = hitInfo.normal

                return hitPoint, Vector2.Reflect(direction, hitNormal), hitCollider
            end
        end
    end
end

function XGoldenMinerComponentHook:_GetReflectAim(index)
    if not self._ReflectAimList[index] then
        local aimGo = XUiHelper.Instantiate(self._AimTranList[1].gameObject, self._OwnControl.SystemHook:GetReflectAimRoot())
        aimGo.transform.localPosition = Vector3.zero
        self._ReflectAimList[index] = aimGo.transform
    end

    self._ReflectAimList[index].gameObject:SetActiveEx(true)
    return self._ReflectAimList[index]
end

---@param hookEntityList XGoldenMinerComponentHook[]
function XGoldenMinerComponentHook:UpdateIdleRope(time, hookEntityList)
    if self:CheckType(XEnumConst.GOLDEN_MINER.HOOK_TYPE.DOUBLE) then
        -- 钩子2与钩子1对称摇晃
        ---@type XGoldenMinerComponentHook
        local tempHook = false
        -- 找到钩子1
        for _, hookEntity in ipairs(hookEntityList) do
            if self ~= hookEntity.Hook then
                tempHook = hookEntity.Hook
            end
        end
        if not tempHook then
            return
        end
        -- 对称摇晃
        local tempIdleRotateAngle = tempHook:GetCurIdleRotateAngle()
        local rotateAngleZ = (self._RopeRightAngleLimit - tempIdleRotateAngle.z) + self._RopeLeftAngleLimit
        self:_UpdateCurIdleRotateAngle(tempIdleRotateAngle.x, tempIdleRotateAngle.y, rotateAngleZ)
    elseif self:CheckType(XEnumConst.GOLDEN_MINER.HOOK_TYPE.AIMING_ANGLE) then
        -- 没有控制方向退出
        if not self._CurIdleRotateDirection then
            return
        end
        -- 到达左右边界不再移动 -- 2.17 瞄准勾爪适配倒反天罡海克斯（可以360度旋转）
        --if self:_CheckCurIdleRotateDirectionIsRight() and self:_CheckIsRopeRightLimit()
        --        or self:_CheckCurIdleRotateDirectionIsLeft() and self:_CheckIsRopeLeftLimit() then
        --    return
        --end
        self:_UpdateCurIdleRotateAngleByTime(time, false)
    else
        -- 自由摇晃
        if not self._CurIdleRotateDirection then
            self:UpdateCurIdleRotateDirection(1)
        end
        if self:_CheckIsRopeLeftLimit() then
            self:UpdateCurIdleRotateDirection(1)
        elseif self:_CheckIsRopeRightLimit() then
            self:UpdateCurIdleRotateDirection(-1)
        end
        self:_UpdateCurIdleRotateAngleByTime(time)
    end
end

function XGoldenMinerComponentHook:_UpdateCurIdleRotateAngle(x, y, z)
    self._CurIdleRotateAngle:Update(x, y, z)
    self:_CheckAndSetIdleRotateAngleLimit()
    self.Transform.localEulerAngles = self._CurIdleRotateAngle
end

function XGoldenMinerComponentHook:_UpdateCurIdleRotateAngleByTime(time, isCheckLimit)
    isCheckLimit = isCheckLimit == nil and true or isCheckLimit

    local z = self._CurIdleRotateAngle.z + self._CurIdleRotateDirection * self._IdleSpeed * time
    self._CurIdleRotateAngle:Update(nil, nil, z)
    if isCheckLimit then
        self:_CheckAndSetIdleRotateAngleLimit()
    end
    self.Transform.localEulerAngles = self._CurIdleRotateAngle
end

function XGoldenMinerComponentHook:UpdateCurIdleRotateDirection(direction)
    self._CurIdleRotateDirection = direction
end

function XGoldenMinerComponentHook:UpdateRoleLength(length, isRevoking)
    if XTool.IsTableEmpty(self._CurRopeObjList) then
        return
    end
    self._CurRopeLength = length
    self._CurRopeLength = math.max(self._CurRopeLength, self._RopeMinLength)
    self._CurRopeLength = math.min(self._CurRopeLength, self._RopeMaxLength)
    if isRevoking then
        self._CurRevokeRopeLength = self._MaxRevokeRopeLength - self._CurRopeLength
    end

    if not self:CheckHaveHitPoint() then
        self:_UpdateRopeLength(false)
    else
        if isRevoking and self:_CheckCanReverseMove() then
            self:_UpdateRopeLengthByReverseMove()
        else
            self:_UpdateRopeLengthHasHitPoint()
        end
    end

    if self._RopeCollider then
        self._RopeCollider.transform.position = self._HookObj.position
    end
end

---@param crossPoint XLuaVector2
function XGoldenMinerComponentHook:UpdateCurDelayChangeAngleTimeByCrossPoint(crossPoint, angle)
    local pos = self:GetCurHookPosition()
    local crossLocalPoint = self.Transform:InverseTransformPoint(Vector3(crossPoint.x, crossPoint.y, pos.z))
    local dis = XLuaVector3.Distance(crossLocalPoint, self._HookObj.localPosition)
    self._CurMoveDelayChangeAngleTime = math.max(0, dis / self:GetCurShootSpeed())
    self._CurMoveCacheAngle = angle
end

function XGoldenMinerComponentHook:DownCurDelayChangeAngleTime(deltaTime)
    if self:_CheckIsDelayChangeAngle() then
        self._CurMoveDelayChangeAngleTime = math.max(0, self._CurMoveDelayChangeAngleTime - deltaTime)
        if self._CurMoveDelayChangeAngleTime == 0 then
            self:AddCurHitPointInfo(self._CurMoveCacheAngle)
        end
    end
end

function XGoldenMinerComponentHook:_UpdateRopeLength(resetEulerAngle)
    self._CurRopeAngleZ = self._CurIdleRotateAngle.z
    self._CacheRopeDeltaPos:Update(self._HookObjStartLocalPosition.x,
            self._HookObjStartLocalPosition.y + self._RopeMinLength - self._CurRopeLength,
            self._HookObjStartLocalPosition.z)
    self._HookObj.localPosition = self._CacheRopeDeltaPos
    if resetEulerAngle then
        self._HookObj.localEulerAngles = Vector3Zero
    end
    for i, rope in ipairs(self._CurRopeObjList) do
        if i == 1 then
            self._CacheRopeSize:Update(rope.sizeDelta.x, self._CurRopeLength)
            self._CurRopeDetailVector = rope.sizeDelta.y - self._CacheRopeSize.y
            rope.sizeDelta = self._CacheRopeSize
            rope.gameObject:SetActiveEx(true)
        else
            rope.gameObject:SetActiveEx(false)
        end
    end
end

function XGoldenMinerComponentHook:_UpdateRopeLengthHasHitPoint()
    local deltaPosition
    -- 线段起点索引
    local changeIndex = 0
    local deltaLength = 0

    for i, hitPointLength in ipairs(self._CurMoveHitPointLengthList) do
        if self._CurRopeLength > hitPointLength then
            changeIndex = i + 1
        end
    end

    if changeIndex > 1 then
        local curAngle = self._CurMoveAngleList[changeIndex]
        self._CurRopeAngleZ = curAngle.z + self._CurIdleRotateAngle.z
        local curStartPosition = self._CurMoveStartPointList[changeIndex]
        local rotation = CSQuaternion.Euler(curAngle)
        deltaLength = self._CurRopeLength - self._CurMoveHitPointLengthList[changeIndex - 1]
        deltaPosition = rotation * Vector3.down * deltaLength
        -- 分段校准绳子角度及位置
        local curChangeRopeObj = self:_GetRopeObj(changeIndex)
        curChangeRopeObj.localPosition = curStartPosition + self._RopeObjStartLocalPosition
        curChangeRopeObj.localEulerAngles = curAngle
        -- 设置绳子长度
        for i, rope in ipairs(self._CurRopeObjList) do
            if i == changeIndex then
                local connectObj = XUiHelper.TryGetComponent(self._HookObj, "Shackle")
                local hookPosition = curStartPosition + deltaPosition
                if connectObj then
                    hookPosition = hookPosition - connectObj.localPosition
                end
                self._CacheRopeSize:Update(rope.sizeDelta.x, XLuaVector3.Distance(rope.localPosition, hookPosition) + self._RopeMinLength)
                self._CurRopeDetailVector = rope.sizeDelta.y - self._CacheRopeSize.y
                rope.sizeDelta = self._CacheRopeSize
                rope.gameObject:SetActiveEx(true)
            elseif i < changeIndex then
                --因为绳子Obj比钩子Obj坐标超出RopeObjStartLocalPosition
                --校准转角后钩子坐标需要去除这部分坐标
                local l = (self._CurMoveHitPointLengthList[i]) - (i > 1 and self._CurMoveHitPointLengthList[i - 1] or self._RopeObjStartLocalPosition.y)
                self._CacheRopeSize:Update(rope.sizeDelta.x, math.max(l, self._RopeMinLength))
                rope.sizeDelta = self._CacheRopeSize
                rope.gameObject:SetActiveEx(true)
            elseif i > changeIndex then
                rope.gameObject:SetActiveEx(false)
            end
        end
        -- 校准钩子角度及位置
        self._HookObj.localPosition = curStartPosition + deltaPosition
        self._HookObj.localEulerAngles = curAngle
    else
        self:_UpdateRopeLength(true)
    end
end

function XGoldenMinerComponentHook:_UpdateRopeLengthByReverseMove()
    -- 线段起点索引
    local changeIndex = 0
    -- 倒翻天罡Buff影响，绳子回收时按队列的方式回收
    for i, hitPointLength in ipairs(self._CurMoveHitPointLengthList) do
        if self._CurRevokeRopeLength > hitPointLength then
            changeIndex = i + 1
        end
    end

    if changeIndex > 1 then
        local curAngle = self._CurMoveAngleList[changeIndex]
        self._CurRopeAngleZ = curAngle.z + self._CurIdleRotateAngle.z

        for i, rope in ipairs(self._CurRopeObjList) do
            if i == changeIndex then
                local curRopeMaxLength = self._CurMoveHitPointLengthList[i] or self._MaxRevokeRopeLength
                self._CacheRopeSize:Update(rope.sizeDelta.x, curRopeMaxLength - self._CurRevokeRopeLength)
                self._CurRopeDetailVector = rope.sizeDelta.y - self._CacheRopeSize.y
                rope.sizeDelta = self._CacheRopeSize
                rope.gameObject:SetActiveEx(true)
            elseif i < changeIndex then
                rope.gameObject:SetActiveEx(false)
            elseif i > changeIndex then
                if XTool.IsNumberValid(self._CurMoveHitPointLengthList[i - 1]) then
                    local radian = math.rad(curAngle.z)
                    self._CacheRopeDeltaPos:Update(rope.localPosition.x - self._CurRopeDetailVector * math.sin(radian),
                            rope.localPosition.y + self._CurRopeDetailVector * math.cos(radian),
                            rope.localPosition.z)
                    rope.localPosition = self._CacheRopeDeltaPos
                    rope.gameObject:SetActiveEx(true)
                else
                    rope.gameObject:SetActiveEx(false)
                end
            end
        end

        local ropeAngleZ = curAngle.z
        if ropeAngleZ < 0 then
            ropeAngleZ = ropeAngleZ + 360
        end
        local radian = math.rad(ropeAngleZ)
        local ropeDetailVector = math.abs(self._CurRopeDetailVector)
        self._CacheRopeDeltaPos:Update(self._HookObj.localPosition.x - math.sin(radian) * ropeDetailVector,
                self._HookObj.localPosition.y + math.cos(radian) * ropeDetailVector,
                self._HookObj.localPosition.z)
        self._HookObj.localPosition = self._CacheRopeDeltaPos

        if self:CheckIsIdle() then
            local tempAngle = self._CurRopeAngleZ
            if tempAngle < -180 then
                tempAngle = tempAngle + 360
            elseif tempAngle > 180 then
                tempAngle = tempAngle - 360
            end
            self._CurIdleRotateAngle:Update(0, 0, tempAngle)
            self._HookObj.localPosition = self._HookObjStartLocalPosition
            self._HookObj.localEulerAngles = Vector3Zero
            self._CurRopeObjList[changeIndex].localPosition = self._RopeObjStartLocalPosition
            self._CurRopeObjList[changeIndex].localEulerAngles = Vector3Zero
            self.Transform.localEulerAngles = self._CurIdleRotateAngle
        end
    else
        self._CurRopeAngleZ = self._CurIdleRotateAngle.z
        for i, rope in ipairs(self._CurRopeObjList) do
            local curRopeMaxLength = self._CurMoveHitPointLengthList[i] or self._MaxRevokeRopeLength
            if i == 1 then
                self._CacheRopeSize:Update(rope.sizeDelta.x, curRopeMaxLength - self._CurRevokeRopeLength)
                self._CurRopeDetailVector = rope.sizeDelta.y - self._CacheRopeSize.y
                rope.sizeDelta = self._CacheRopeSize
                rope.gameObject:SetActiveEx(true)
            else
                if XTool.IsNumberValid(self._CurMoveHitPointLengthList[i - 1]) then
                    self._CacheRopeDeltaPos:Update(rope.localPosition.x,
                            rope.localPosition.y + self._CurRopeDetailVector,
                            rope.localPosition.z)
                    rope.localPosition = self._CacheRopeDeltaPos
                    rope.gameObject:SetActiveEx(true)
                else
                    rope.gameObject:SetActiveEx(false)
                end
            end
        end

        self._CacheRopeDeltaPos:Update(self._HookObj.localPosition.x,
                self._HookObj.localPosition.y + self._CurRopeDetailVector,
                self._HookObj.localPosition.z)
        self._HookObj.localPosition = self._CacheRopeDeltaPos
    end
end

function XGoldenMinerComponentHook:_GetRopeObj(index)
    if not self._CurRopeObjList[index] then
        self._CurRopeObjList[index] = XUiHelper.Instantiate(self._CurRopeObjList[1].gameObject, self._CurRopeObjList[1].parent).transform
        self._CurRopeObjList[index].gameObject:SetActiveEx(false)
    end
    return self._CurRopeObjList[index]
end
--endregion

return XGoldenMinerComponentHook 