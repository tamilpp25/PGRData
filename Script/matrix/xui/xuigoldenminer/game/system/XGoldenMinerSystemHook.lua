---@class XGoldenMinerSystemHook
local XGoldenMinerSystemHook = XClass(nil, "XGoldenMinerSystemHook")

---@param game XGoldenMinerGame
function XGoldenMinerSystemHook:Init(game)
    if XTool.IsTableEmpty(game.HookEntityList) then
        return
    end

    for _, hookEntity in ipairs(game.HookEntityList) do
        self:HookIdle(game, hookEntity.Hook)
        self:ChangeHookRopeLength(hookEntity.Hook, hookEntity.Hook.RopeLength)
    end
end

---@param game XGoldenMinerGame
function XGoldenMinerSystemHook:Update(game, time)
    if XTool.IsTableEmpty(game.HookEntityList) then
        return
    end

    for _, hookEntity in ipairs(game.HookEntityList) do
        self:UpdateHook(game, hookEntity.Hook, time)
    end
end

--region Hook
---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:ChangeHookRopeLength(hook, length)
    if not hook or XTool.IsTableEmpty(hook.RopeObjList) then
        return
    end
    hook.RopeLength = length
    hook.RopeLength = math.max(hook.RopeLength, hook.RopeMinLength)
    hook.RopeLength = math.min(hook.RopeLength, hook.RopeMaxLength)
    local deltaPosition

    if XTool.IsTableEmpty(hook.CurMoveHitPointLengthList) then
        deltaPosition = Vector3(0, hook.RopeMinLength - hook.RopeLength, 0)
        hook.HookObj.localPosition = hook.HookObjStartLocalPosition + deltaPosition
        for i, rope in ipairs(hook.RopeObjList) do
            if i == 1 then
                rope.sizeDelta = Vector2(rope.sizeDelta.x, hook.RopeLength)
            else
                rope.gameObject:SetActiveEx(false)
            end
        end
    else
        -- 线段起点索引
        local index = 0
        local deltaLength = 0
        for i, hitPointLength in ipairs(hook.CurMoveHitPointLengthList) do
            if hook.RopeLength > hitPointLength then
                index = i + 1
            end
        end

        if index > 1 then
            local curAngle = hook.CurMoveAngleList[index]
            local curStartPosition = hook.CurMoveStartPointList[index]
            local rotation = CS.UnityEngine.Quaternion.Euler(curAngle)
            deltaLength = hook.RopeLength - hook.CurMoveHitPointLengthList[index - 1]
            deltaPosition = rotation * Vector3.down * deltaLength
            -- 绳子分段创建
            if not hook.RopeObjList[index] then
                hook.RopeObjList[index] = XUiHelper.Instantiate(hook.RopeObjList[1].gameObject, hook.RopeObjList[1].parent).transform
                hook.RopeObjList[index].gameObject:SetActiveEx(false)
            end
            -- 校准绳子角度及位置
            if hook.RopeObjList[index].localPosition ~= curStartPosition + hook.RopeObjStartLocalPosition then
                hook.RopeObjList[index].localPosition = curStartPosition + hook.RopeObjStartLocalPosition
            end
            if hook.RopeObjList[index].localEulerAngles ~= curAngle then
                hook.RopeObjList[index].localEulerAngles = curAngle
            end
            -- 设置绳子长度
            for i, rope in ipairs(hook.RopeObjList) do
                if i == index then
                    local connectObj = XUiHelper.TryGetComponent(hook.HookObj, "Shackle")
                    local hookPosition = curStartPosition + deltaPosition
                    if connectObj then
                        hookPosition = hookPosition - connectObj.localPosition
                    end
                    rope.sizeDelta = Vector2(rope.sizeDelta.x, Vector3.Distance(rope.localPosition, hookPosition) + hook.RopeMinLength)
                    rope.gameObject:SetActiveEx(true)
                elseif i < index then
                    --因为绳子Obj比钩子Obj坐标超出RopeObjStartLocalPosition
                    --校准转角后钩子坐标需要去除这部分坐标
                    local l = (hook.CurMoveHitPointLengthList[i]) - (i > 1 and hook.CurMoveHitPointLengthList[i - 1] or hook.RopeObjStartLocalPosition.y) 
                    rope.sizeDelta = Vector2(rope.sizeDelta.x, math.max(l, hook.RopeMinLength))
                    rope.gameObject:SetActiveEx(true)
                elseif i > index then
                    rope.gameObject:SetActiveEx(false)
                end
            end
            -- 校准钩子角度及位置
            hook.HookObj.localPosition = curStartPosition + deltaPosition
            if hook.HookObj.localEulerAngles ~= curAngle then
                hook.HookObj.localEulerAngles = curAngle
            end
        else
            deltaPosition = Vector3(0, hook.RopeMinLength - hook.RopeLength, 0)
            hook.HookObj.localPosition = hook.HookObjStartLocalPosition + deltaPosition
            if hook.HookObj.localEulerAngles ~= Vector3.zero then
                hook.HookObj.localEulerAngles = Vector3.zero
            end
            for i, rope in ipairs(hook.RopeObjList) do
                if i == 1 then
                    rope.sizeDelta = Vector2(rope.sizeDelta.x, hook.RopeLength)
                    rope.gameObject:SetActiveEx(true)
                else
                    rope.gameObject:SetActiveEx(false)
                end
            end
        end
    end
    if hook.RopeCollider then
        hook.RopeCollider.transform.position = hook.HookObj.position
    end
end

---设置钩爪为待使用状态
---@param game XGoldenMinerGame
---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:HookIdle(game, hook)
    if XTool.IsTableEmpty(game.HookEntityList) and not hook then
        return
    end

    if hook.Status == XGoldenMinerConfigs.GAME_HOOK_STATUS.REVOKING then
        self:OnHookRevokeToIdle(game, hook)
    end
    self:_SetHookStatus(hook, XGoldenMinerConfigs.GAME_HOOK_STATUS.IDLE)

    for _, hookEntity in ipairs(game.HookEntityList) do
        if hookEntity.Hook.Status ~= XGoldenMinerConfigs.GAME_HOOK_STATUS.IDLE then
            return
        end
    end
    game.HookEntityStatus = XGoldenMinerConfigs.GAME_HOOK_ENTITY_STATUS.IDLE
end

---@param game XGoldenMinerGame
---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:OnHookRevokeToIdle(game, hook)
    local hookEntity = game:GetHookEntityByHook(hook)
    for _, stoneEntity in ipairs(hookEntity.HookGrabbingStoneList) do
        if stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING then
            game:SetStoneEntityStatus(stoneEntity, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBED)
            hookEntity.HookGrabbedStoneList[#hookEntity.HookGrabbedStoneList + 1] = stoneEntity
        end
    end
    game:OnHookRevokeToIdle(hookEntity)
end

---@param game XGoldenMinerGame
function XGoldenMinerSystemHook:HookShoot(game)
    if XTool.IsTableEmpty(game.HookEntityList) then
        return
    end
    if game:IsPause() or game:IsEnd() or game:IsQTE() then
        return
    end

    if game.HookEntityStatus ~= XGoldenMinerConfigs.GAME_HOOK_ENTITY_STATUS.IDLE then
        return
    end
    game.HookEntityStatus = XGoldenMinerConfigs.GAME_HOOK_ENTITY_STATUS.USING

    for _, hookEntity in ipairs(game.HookEntityList) do
        self:_SetHookStatus(hookEntity.Hook, XGoldenMinerConfigs.GAME_HOOK_STATUS.SHOOTING)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE,
            XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.SHOOTING,
            XGoldenMinerConfigs.GAME_FACE_PLAY_ID.SHOOTING)
end

---@param game XGoldenMinerGame
---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:HookRevoke(game, hook)
    if XTool.IsTableEmpty(game.HookEntityList) then
        return
    end
    if game:IsPause() or game:IsEnd() or game:IsQTE() then
        return
    end
    if game.HookEntityStatus ~= XGoldenMinerConfigs.GAME_HOOK_ENTITY_STATUS.USING then
        return
    end
    if hook.Status ~= XGoldenMinerConfigs.GAME_HOOK_STATUS.SHOOTING
            and hook.Status ~= XGoldenMinerConfigs.GAME_HOOK_STATUS.GRABBING
            and hook.Status ~= XGoldenMinerConfigs.GAME_HOOK_STATUS.QTE then
        return
    end

    self:_SetHookStatus(hook, XGoldenMinerConfigs.GAME_HOOK_STATUS.REVOKING)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE,
            XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.REVOKING,
            XGoldenMinerConfigs.GAME_FACE_PLAY_ID.REVOKING)
end

---@param game XGoldenMinerGame
---@param hook XGoldenMinerComponentHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:HookGrab(game, hook, stoneEntity)
    if XTool.IsTableEmpty(game.HookEntityList) then
        return
    end
    if game:IsPause() or game:IsEnd() then
        return
    end
    if game.HookEntityStatus ~= XGoldenMinerConfigs.GAME_HOOK_ENTITY_STATUS.USING then
        return
    end
    if hook.Status ~= XGoldenMinerConfigs.GAME_HOOK_STATUS.SHOOTING then
        return
    end
    self:_SetHookStatus(hook, XGoldenMinerConfigs.GAME_HOOK_STATUS.GRABBING)
    self:SetStoneEntityOnHook(hook, stoneEntity)
end

---@param game XGoldenMinerGame
---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:OnHookHit(game, hookEntity, stoneEntity)
    if hookEntity.Hook.Status ~= XGoldenMinerConfigs.GAME_HOOK_STATUS.SHOOTING then
        return
    end
    
    if not stoneEntity then
        if XTool.IsTableEmpty(hookEntity.HookGrabbingStoneList) then
            XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE,
                    XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.GRAB_NONE,
                    XGoldenMinerConfigs.GAME_FACE_PLAY_ID.GRAB_NONE)
        end
        self:HookRevoke(game, hookEntity.Hook)
        return
    end
    
    -- 过滤忽略类型
    for _, ignoreType in ipairs(XGoldenMinerConfigs.GetFalculaIgnoreTypeList(hookEntity.Hook.Type)) do
        if ignoreType == stoneEntity.Data:GetType() then
            return
        end
    end
    
    -- 河蚌抓过或关闭就过滤
    if stoneEntity.Mussel and
            (stoneEntity.Mussel.IsGrabbed or stoneEntity.Mussel.Status == XGoldenMinerConfigs.GAME_MUSSEL_STATUS.CLOSE)
    then
        self:HookRevoke(game, hookEntity.Hook)
        return
    end
    
    -- 状态不对过滤
    if stoneEntity.Status ~= XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.ALIVE then
        return
    end
    
    -- QTE
    if stoneEntity.QTE then
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_START, hookEntity, stoneEntity)
        return
    end
    
    -- 钩爪不处理挡板撞击处理
    if stoneEntity.HookDirectionPoint then
        return
    end

    -- 碰到炸弹直接收回
    if self:_OnHookHitBoom(game, hookEntity, stoneEntity) then
        return
    end
    
    -- 碰到炸弹携带者直接收回
    if self:_OnHookHitBoom(game, hookEntity, stoneEntity.CarryStone) then
        return
    end

    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_HIT, stoneEntity.Data:GetType())
    if hookEntity.Hook.Type == XGoldenMinerConfigs.FalculaType.Magnetic
            or hookEntity.Hook.Type == XGoldenMinerConfigs.FalculaType.StorePressMagnetic
    then
        if stoneEntity.Mussel then
            game:HookGrab(hookEntity, stoneEntity)
        else
            game:SetStoneGrab(hookEntity, stoneEntity)
        end
        return
    end
    game:HookGrab(hookEntity, stoneEntity)
end

---@param game XGoldenMinerGame
---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:OnRopeHit(game, hookEntity, stoneEntity)
    if hookEntity.Hook.Status ~= XGoldenMinerConfigs.GAME_HOOK_STATUS.SHOOTING then
        return
    end

    -- 过滤忽略类型
    for _, ignoreType in ipairs(XGoldenMinerConfigs.GetFalculaIgnoreTypeList(hookEntity.Hook.Type)) do
        if ignoreType == stoneEntity.Data:GetType() then
            return
        end
    end

    -- 状态不对过滤
    if stoneEntity.Status ~= XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.ALIVE then
        return
    end

    -- 挡板撞击处理
    if self:_OnHookHitDirectionPoint(game, hookEntity, stoneEntity) then
        return
    end
end

---撞到挡板
---@param game XGoldenMinerGame
---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:_OnHookHitDirectionPoint(game, hookEntity, stoneEntity)
    if not stoneEntity.HookDirectionPoint then
        return false
    end
    if table.indexof(hookEntity.HookHitStoneList, stoneEntity) then
        return true
    end

    hookEntity.HookHitStoneList[#hookEntity.HookHitStoneList + 1] = stoneEntity
    hookEntity.Hook.CurMoveStartPointList[#hookEntity.Hook.CurMoveStartPointList + 1] = hookEntity.Hook.HookObj.localPosition
    hookEntity.Hook.CurMoveHitPointLengthList[#hookEntity.Hook.CurMoveHitPointLengthList + 1] = hookEntity.Hook.RopeLength
    
    -- 转向点此时的角度
    local directionPointAngle = stoneEntity.HookDirectionPoint.AngleList[stoneEntity.HookDirectionPoint.CurAngleIndex]
    -- 钩子的角度修正
    local curAngle = Vector3(0, 0, directionPointAngle + 90) - hookEntity.Hook.CurIdleRotateAngle
    table.insert(hookEntity.Hook.CurMoveAngleList, curAngle)
    
    --XGoldenMinerConfigs.DebugLog("撞击挡板,方向改变!角度="
    --        ..stoneEntity.HookDirectionPoint.AngleList[stoneEntity.HookDirectionPoint.CurAngleIndex]
    --        ..",StoneId="..stoneEntity.Data:GetId())
    -- 抓到挡板表情
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE,
            XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.GRAB_STONE,
            XGoldenMinerConfigs.GetStoneTypeGrabFaceId(stoneEntity.Data:GetType()))
    -- 撞到挡板事件
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_HIT, stoneEntity.Data:GetType())

    return true
end

---撞到炸弹
---@param game XGoldenMinerGame
---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:_OnHookHitBoom(game, hookEntity, stoneEntity)
    if not stoneEntity or stoneEntity.Data:GetType() ~= XGoldenMinerConfigs.StoneType.Boom then
        return false
    end
    
    -- 防爆直接穿过
    if game:CheckHasBuff(XGoldenMinerConfigs.BuffType.GoldenMinerNotActiveBoom) then
        return true
    end
    game:SetStoneEntityStatus(stoneEntity, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_DESTROY)
    self:HookRevoke(game, hookEntity.Hook)

    -- 抓到炸弹表情
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE,
            XGoldenMinerConfigs.GAME_FACE_PLAY_TYPE.GRAB_STONE,
            XGoldenMinerConfigs.GetStoneTypeGrabFaceId(stoneEntity.Data:GetType()))
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_HIT, stoneEntity.Data:GetType())
    return true
end

---@param hook XGoldenMinerComponentHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:SetStoneEntityOnHook(hook, stoneEntity)
    ---@type XGoldenMinerEntityStone
    local tempStoneEntity = stoneEntity
    -- 河蚌只抓携带物
    if tempStoneEntity.Mussel then
        tempStoneEntity = stoneEntity.CarryStone
    end
    if not tempStoneEntity or XTool.UObjIsNil(tempStoneEntity.Stone.Transform) then
        return
    end
    tempStoneEntity.Stone.Transform:SetParent(hook.GrabPoint, false)
    local rectTransform = tempStoneEntity.Stone.Transform:GetComponent("RectTransform")
    rectTransform.anchorMin = Vector2(0.5, 1)
    rectTransform.anchorMax = Vector2(0.5, 1)
    rectTransform.pivot = Vector2(0.5, 1)

    if stoneEntity.Mouse then
        tempStoneEntity.Stone.Transform.localPosition = Vector3(0, XGoldenMinerConfigs.GetMouseGrabOffset(), 0)
    else
        tempStoneEntity.Stone.Transform.localPosition = Vector3.zero
    end
    tempStoneEntity.Stone.Transform.localRotation = CS.UnityEngine.Quaternion.identity
    
    if string.IsNilOrEmpty(tempStoneEntity.Data:GetCatchEffect()) or tempStoneEntity.QTE then
        return
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
            XGoldenMinerConfigs.GAME_EFFECT_TYPE.GRAB,
            tempStoneEntity.Stone.Transform,
            tempStoneEntity.Data:GetCatchEffect())
end

---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_SetHookStatus(hook, status)
    if hook.Status == status then
        return
    end
    if status == XGoldenMinerConfigs.GAME_HOOK_STATUS.SHOOTING then
        hook.CurMoveStartPointList = {hook.HookObjStartLocalPosition}
        hook.CurMoveHitPointLengthList = {}
        hook.CurMoveAngleList = { Vector3.zero }
        for _, collider in ipairs(hook.ColliderList) do
            collider.enabled = true
        end
    elseif status == XGoldenMinerConfigs.GAME_HOOK_STATUS.GRABBING  -- 磁力钩不存在Grabbing状态
            and (hook.Type == XGoldenMinerConfigs.FalculaType.Magnetic
            or hook.Type == XGoldenMinerConfigs.FalculaType.StorePressMagnetic) then
        return
    else
        for _, collider in ipairs(hook.ColliderList) do
            collider.enabled = false
        end
    end

    hook.Status = status
end
--endregion

--region Data
---计算回收速度
---@param hookEntity XGoldenMinerEntityHook
---@param buffContainer XGoldenMinerEntityBuffContainer
---@return number
function XGoldenMinerSystemHook:ComputeRevokeSpeed(hookEntity)
    local speed
    if not XTool.IsTableEmpty(hookEntity.HookHitStoneList) then
        local hitStoneCount = #hookEntity.HookHitStoneList
        speed = XGoldenMinerConfigs.GetHookHitPointRevokeSpeed(hitStoneCount)
        --XGoldenMinerConfigs.DebugLog("撞到转向点急速回收,撞到转向点数量="..hitStoneCount
        --        ..",初始速度参数="..XGoldenMinerConfigs.GetHookHitPointRevokeSpeed(hitStoneCount))
    else
        speed = XGoldenMinerConfigs.GetRopeShortenSpeed()
    end
    local weight = 0
    local qteSpeedRate = 1
    for _, stoneEntity in pairs(hookEntity.HookGrabbingStoneList) do
        if stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING then
            weight = weight + stoneEntity.Stone.CurWeight
        end
        if stoneEntity.QTE and stoneEntity.QTE.SpeedRate > qteSpeedRate then
            qteSpeedRate = stoneEntity.QTE.SpeedRate
            --XGoldenMinerConfigs.DebugLog("QTE回收，速度倍率="..qteSpeedRate)
        end
    end
    local param = weight + XGoldenMinerConfigs.GetShortenSpeedParameter()
    param = XTool.IsNumberValid(param) and param or 1
    speed = speed * (1 - (weight / param)) * hookEntity.Hook.CurRevokeSpeedPercent * qteSpeedRate
    --XGoldenMinerConfigs.DebugLog("当前钩爪回收速度="..speed)
    return math.max(speed, XGoldenMinerConfigs.GetShortenMinSpeed())
end
--endregion

--region Update
---@param game XGoldenMinerGame
---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:UpdateHook(game, hook, time)
    if not hook then
        return
    end
    if hook.Status == XGoldenMinerConfigs.GAME_HOOK_STATUS.IDLE then
        self:_UpdateHookIdle(game, hook, time)
    elseif hook.Status == XGoldenMinerConfigs.GAME_HOOK_STATUS.READY then
        self:_UpdateHookReady(game, hook, time)
    elseif hook.Status == XGoldenMinerConfigs.GAME_HOOK_STATUS.SHOOTING then
        self:_UpdateHookShooting(game, hook, time)
    elseif hook.Status == XGoldenMinerConfigs.GAME_HOOK_STATUS.GRABBING then
        self:_UpdateHookGrab(game, hook, time)
    elseif hook.Status == XGoldenMinerConfigs.GAME_HOOK_STATUS.REVOKING then
        self:_UpdateHookRevoking(game, hook, time)
    elseif hook.Status == XGoldenMinerConfigs.GAME_HOOK_STATUS.QTE then
        self:_UpdateHookQTE(game, hook, time)
    end
end

---@param game XGoldenMinerGame
---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_UpdateHookIdle(game, hook, time)
    for _, aim in pairs(hook.AimTranList) do
        aim.gameObject:SetActiveEx(hook.IsAim)
    end
    -- 存在一个钩子还在出钩状态就不摇晃
    if game.HookEntityStatus ~= XGoldenMinerConfigs.GAME_HOOK_ENTITY_STATUS.IDLE then
        return
    end
    -- 待机摇晃
    local leftRangeAngle, rightRangeAngle = XGoldenMinerConfigs.GetHookIdleAngleRange()
    if hook.Type == XGoldenMinerConfigs.FalculaType.Normal
            or hook.Type == XGoldenMinerConfigs.FalculaType.Magnetic
            or hook.Type == XGoldenMinerConfigs.FalculaType.Big
            or hook.Type == XGoldenMinerConfigs.FalculaType.StorePressMagnetic then
        -- 自由摇晃
        if not hook.IdleRotateDirection then
            hook.IdleRotateDirection = Vector3.forward
        end
        if hook.CurIdleRotateAngle.z <= leftRangeAngle then
            hook.IdleRotateDirection = Vector3.forward
        elseif hook.CurIdleRotateAngle.z >= rightRangeAngle then
            hook.IdleRotateDirection = Vector3.back
        end
        local deltaAngle = hook.IdleRotateDirection * hook.IdleSpeed * time
        hook.CurIdleRotateAngle = hook.CurIdleRotateAngle + deltaAngle
        hook.Transform:Rotate(deltaAngle)
    elseif hook.Type == XGoldenMinerConfigs.FalculaType.Double then
        -- 钩子2与钩子1对称摇晃
        ---@type XGoldenMinerComponentHook
        local tempHook = false
        -- 找到钩子1
        for _, hookEntity in ipairs(game.HookEntityList) do
            if hook ~= hookEntity.Hook then
                tempHook = hookEntity.Hook
            end
        end
        if not tempHook then
            return
        end
        -- 对称摇晃
        local rotateAngleZ = (rightRangeAngle - tempHook.CurIdleRotateAngle.z) + leftRangeAngle
        hook.CurIdleRotateAngle = Vector3(tempHook.CurIdleRotateAngle.x, tempHook.CurIdleRotateAngle.y, rotateAngleZ)
        hook.Transform.localEulerAngles = hook.CurIdleRotateAngle
    elseif hook.Type == XGoldenMinerConfigs.FalculaType.AimingAngle then
        -- 没有控制方向退出
        if not hook.IdleRotateDirection then
            return
        end
        -- 到达左右边界不再移动
        if hook.IdleRotateDirection == Vector3.forward and hook.CurIdleRotateAngle.z >= rightRangeAngle
                or hook.IdleRotateDirection == Vector3.back and hook.CurIdleRotateAngle.z <= leftRangeAngle then
            return
        end
        hook.CurIdleRotateAngle = hook.CurIdleRotateAngle + hook.IdleRotateDirection * hook.IdleSpeed * time
        if hook.CurIdleRotateAngle.z <= leftRangeAngle then
            hook.CurIdleRotateAngle = Vector3(hook.CurIdleRotateAngle.x, hook.CurIdleRotateAngle.y, leftRangeAngle)
        elseif hook.CurIdleRotateAngle.z >= rightRangeAngle then
            hook.CurIdleRotateAngle = Vector3(hook.CurIdleRotateAngle.x, hook.CurIdleRotateAngle.y, rightRangeAngle)
        end
        hook.Transform.localEulerAngles = hook.CurIdleRotateAngle
    end
end

---@param game XGoldenMinerGame
---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_UpdateHookReady(game, hook, time)
    
end

---@param game XGoldenMinerGame
---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_UpdateHookShooting(game, hook, time)
    local shootSpeed = hook.CurShootSpeed
    hook.RopeLength = hook.RopeLength + time * shootSpeed
    self:ChangeHookRopeLength(hook, hook.RopeLength)
    
    if hook.RopeLength >= hook.RopeMaxLength then
        self:HookRevoke(game, hook)
    end

    for _, aim in pairs(hook.AimTranList) do
        aim.gameObject:SetActiveEx(false)
    end
end

---@param game XGoldenMinerGame
---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_UpdateHookGrab(game, hook, time)

end

---@param game XGoldenMinerGame
---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_UpdateHookRevoking(game, hook, time)
    local hookEntity = game:GetHookEntityByHook(hook)
    local revokeSpeed = self:ComputeRevokeSpeed(hookEntity, game.BuffContainer)
    hook.RopeLength = hook.RopeLength - time * revokeSpeed
    self:ChangeHookRopeLength(hook, hook.RopeLength)
    if hook.RopeLength == hook.RopeMinLength then
        self:HookIdle(game, hook)
    end
end

---@param game XGoldenMinerGame
---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_UpdateHookQTE(game, hook, time)

end
--endregion

return XGoldenMinerSystemHook