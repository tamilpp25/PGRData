---@class XGoldenMinerSystemHook:XEntityControl
---@field _MainControl XGoldenMinerGameControl
local XGoldenMinerSystemHook = XClass(XEntityControl, "XGoldenMinerSystemHook")
local HOOK_SHOOT_SOUND_CUR_ID = 4966

--region Override
function XGoldenMinerSystemHook:OnInit()
    ---@type number[]
    self._HookEntityUidList = { }
    self._SystemStatus = XEnumConst.GOLDEN_MINER.GAME_SYSTEM_HOOK_STATUS.NONE
end

---@param objDir XGoldenMinerGameInitObjDir
function XGoldenMinerSystemHook:EnterGame(objDir)
    ---@type UnityEngine.Vector2
    self._RectSize = objDir.RectSize
    ---@type UnityEngine.Transform[]
    self._HookObjDir = objDir.HookObjDir
    ---@type UnityEngine.Transform
    self._ReflectAimRopeRoot = objDir.ReflectAimRopeRoot

    for _, type in ipairs(self._MainControl:GetGameData():GetHookTypeList()) do
        local hookEntity = self:_CreateHookEntity(type)
        self:_HookIdle(hookEntity:GetComponentHook())
    end
end

function XGoldenMinerSystemHook:OnUpdate(time)
    if XTool.IsTableEmpty(self._HookEntityUidList) then
        return
    end

    for _, uid in ipairs(self._HookEntityUidList) do
        self:UpdateHook(self._MainControl:GetHookEntityByUid(uid):GetComponentHook(), time)
    end
end

function XGoldenMinerSystemHook:OnRelease()
    self._HookEntityUidList = nil
    self._RectSize = nil
    self._HookObjDir = nil
end
--endregion

--region Data - Getter
function XGoldenMinerSystemHook:GetHookEntityUidList()
    return self._HookEntityUidList
end

---@param stoneStatus number XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS
---@return XGoldenMinerEntityStone[]
function XGoldenMinerSystemHook:GetAllHookGrabbingEntityUidList(stoneStatus)
    local result = {}
    for _, uid in ipairs(self._HookEntityUidList) do
        local hookEntity = self._MainControl:GetHookEntityByUid(uid)
        for _, stoneUid in ipairs(hookEntity:GetGrabbingStoneUidList()) do
            if not stoneStatus or self._MainControl:GetStoneEntityByUid(stoneUid):CheckStatus(stoneStatus) then
                result[#result + 1] = stoneUid
            end
        end
    end
    return result
end

---@param stoneStatus number XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS
function XGoldenMinerSystemHook:GetHookGrabbingWeight(stoneStatus)
    local stoneEntityUidList = self:GetAllHookGrabbingEntityUidList(stoneStatus)
    local weight = 0
    for _, uid in pairs(stoneEntityUidList) do
        local stoneEntity = self._MainControl:GetStoneEntityByUid(uid)
        local carryStone = stoneEntity:GetCarryStoneEntity()
        weight = weight + stoneEntity:GetComponentStone().CurWeight
        if carryStone then
            weight = weight + carryStone:GetComponentStone().CurWeight
        end
    end
    return weight
end

---@param stoneStatus number XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS
function XGoldenMinerSystemHook:GetHookGrabbingScore(stoneStatus)
    local stoneEntityUidList = self:GetAllHookGrabbingEntityUidList(stoneStatus)
    local score = 0
    for _, uid in pairs(stoneEntityUidList) do
        local stoneEntity = self._MainControl:GetStoneEntityByUid(uid)
        local carryStone = stoneEntity:GetCarryStoneEntity()
        score = score + stoneEntity:GetComponentStone().CurScore
        if carryStone then
            score = score + carryStone:GetComponentStone().CurScore
        end
        if stoneEntity:GetComponentQTE() then
            score = score + stoneEntity:GetComponentQTE().AddScore
        end
    end
    return score
end

function XGoldenMinerSystemHook:GetFirstHookEntity()
    local hookUidList = self:GetHookEntityUidList()
    if XTool.IsTableEmpty(hookUidList) then
        return
    end

    return self._MainControl:GetHookEntityByUid(hookUidList[1])
end

---@param collider UnityEngine.Collider2D
---@return XGoldenMinerEntityHook
function XGoldenMinerSystemHook:_GetHookEntityByCollider(collider)
    if XTool.IsTableEmpty(self._HookEntityUidList) then
        return false
    end
    for _, uid in ipairs(self._HookEntityUidList) do
        if self._MainControl:GetHookEntityByUid(uid):GetComponentHook():CheckIsTheHook(collider) then
            return true
        end
    end
    return false
end

function XGoldenMinerSystemHook:GetReflectAimRoot()
    return self._ReflectAimRopeRoot
end
--endregion

--region Data - Setter
function XGoldenMinerSystemHook:_SetSystemStatus(status)
    self._SystemStatus = status
end
--endregion

--region Data - Check
function XGoldenMinerSystemHook:CheckSystemIsUsing()
    return self._SystemStatus == XEnumConst.GOLDEN_MINER.GAME_SYSTEM_HOOK_STATUS.USING
end

function XGoldenMinerSystemHook:CheckSystemIsIdle()
    return self._SystemStatus == XEnumConst.GOLDEN_MINER.GAME_SYSTEM_HOOK_STATUS.IDLE
end

function XGoldenMinerSystemHook:CheckIsHitDirection()
    for _, uid in ipairs(self:GetHookEntityUidList()) do
        if not XTool.IsTableEmpty(self._MainControl:GetHookEntityByUid(uid):GetHitStoneUidList()) then
            return true
        end
    end
    return false
end

function XGoldenMinerSystemHook:CheckHasAimHook()
    for _, uid in ipairs(self:GetHookEntityUidList()) do
        if self._MainControl:GetHookEntityByUid(uid):GetComponentHook():CheckType(XEnumConst.GOLDEN_MINER.HOOK_TYPE.AIMING_ANGLE) then
            return true
        end
    end

    return false
end

---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_CheckHookCanGrab(hook)
    return hook:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.SHOOTING) or
            -- 大钩爪一抓一大把不用过滤
            (hook:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.GRABBING) and hook:CheckType(XEnumConst.GOLDEN_MINER.HOOK_TYPE.BIG))
end

function XGoldenMinerSystemHook:_CheckCanHitBoom()
    return not self._MainControl:CheckBuffAliveByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.NOT_ACTIVE_BOOM)
end

function XGoldenMinerSystemHook:_CheckCanForceGrabStoneWithBuffByStoneTypes(stoneTypes)
    stoneTypes = stoneTypes or {}
    local buffUidList = self._MainControl.SystemBuff:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HOOK_EX_FORCE)
    if XTool.IsTableEmpty(buffUidList) then
        return false
    end

    for buffUid, _ in pairs(buffUidList) do
        local buff = self._MainControl:GetEntityWithUid(buffUid)
        local buffParams = buff:GetBuffParams()
        if XTool.IsTableEmpty(buffParams) then
            return false
        end

        for _, param in pairs(buffParams) do
            for _, stoneType in ipairs(stoneTypes) do
                if param == stoneType then
                    return true
                end
            end
        end
    end

    return false
end

function XGoldenMinerSystemHook:_CheckCanGrabDirection()
    return self:_CheckCanForceGrabStoneWithBuffByStoneTypes({ XEnumConst.GOLDEN_MINER.STONE_TYPE.HOOK_DIRECTION_POINT, XEnumConst.GOLDEN_MINER.STONE_TYPE.AIM_DIRECTION })
end

function XGoldenMinerSystemHook:_CheckCanGrabBoom()
    return self:_CheckCanForceGrabStoneWithBuffByStoneTypes({ XEnumConst.GOLDEN_MINER.STONE_TYPE.BOOM })
end

function XGoldenMinerSystemHook:_CheckCanGrabShield()
    return self:_CheckCanForceGrabStoneWithBuffByStoneTypes({ XEnumConst.GOLDEN_MINER.STONE_TYPE.SHIELD })
end

function XGoldenMinerSystemHook:_CheckIsHitReflectWallByCollider(collider)
    return XTool.IsNumberValid(self._MainControl.SystemMap:GetReflectEdgeUidByCollider(collider))
end
--endregion

--region Hook - Create
---@return XGoldenMinerEntityHook
function XGoldenMinerSystemHook:_CreateHookEntity(type)
    ---@type XGoldenMinerEntityHook
    local hookEntity = self._MainControl:AddEntity(self._MainControl.ENTITY_TYPE.HOOK)
    self:_CreateHookComponent(hookEntity, type, self._HookObjDir[type])
    self:_RegisterHookHitCallBack(hookEntity)
    self._HookEntityUidList[#self._HookEntityUidList + 1] = hookEntity:GetUid()
    return hookEntity
end

---@param hookEntity XGoldenMinerEntityHook
---@return XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_CreateHookComponent(hookEntity, type, hookObj)
    if XTool.UObjIsNil(hookObj) then
        return false
    end
    ---@type XGoldenMinerComponentHook
    local hook = hookEntity:AddChildEntity(self._MainControl.COMPONENT_TYPE.HOOK)
    local length = math.ceil(math.sqrt(self._RectSize.x ^ 2 + self._RectSize.y ^ 2))
    hook:SetTransform(hookObj, length)
    hook:SetType(type)
    hook:SetIgnoreTypeList(self._MainControl:GetCfgHookIgnoreTypeList(type))
    hook:SetRopeAngleLimit(self._MainControl:GetClientHookIdleAngleRange())
    hook:SetRopeLengthLimit(length + self._MainControl:GetClientHookRopeExLength())
    hook:SetIdleSpeed(self._MainControl:GetClientRopeRockSpeed())
    hook:SetShootSpeed(self._MainControl:GetClientRopeStretchSpeed())
    hook:UpdateRoleLength(hook:GetCurRopeLength())
    hook:SetMaxReflectCount(self._MainControl:GetClientHookMaxReflectCount())
    return hook
end

---@param hookEntity XGoldenMinerEntityHook
function XGoldenMinerSystemHook:_RegisterHookHitCallBack(hookEntity)
    local hookComponent = hookEntity:GetComponentHook()
    if not hookComponent or XTool.IsTableEmpty(hookComponent.GoInputHandlerList) then
        return
    end
    for _, goInputHandler in ipairs(hookComponent.GoInputHandlerList) do
        goInputHandler:AddTriggerEnter2DCallback(function(collider)
            self:_HookHit(hookEntity, collider)
        end)
    end
    if hookComponent.RopeInputHandler then
        hookComponent.RopeInputHandler:AddTriggerEnter2DCallback(function(collider)
            self:_RopeHit(hookEntity, collider)
        end)
    end
end
--endregion

--region Hook - Hit
---@param hookEntity XGoldenMinerEntityHook
---@param collider UnityEngine.Collider2D
function XGoldenMinerSystemHook:_HookHit(hookEntity, collider)
    if self:_GetHookEntityByCollider(collider) then
        return
    end
    if collider.gameObject.name == XEnumConst.GOLDEN_MINER.HOOK_IGNORE_HIT then
        return
    end

    -- 弹射墙不被钩子命中
    if self:_CheckIsHitReflectWallByCollider(collider) then
        return
    end

    local stoneEntity = self._MainControl.SystemMap:GetEntityByCollider(collider)
    self:_OnHookHit(hookEntity, stoneEntity)
end

---@param hookEntity XGoldenMinerEntityHook
---@param collider UnityEngine.Collider2D
function XGoldenMinerSystemHook:_RopeHit(hookEntity, collider)
    if self:_GetHookEntityByCollider(collider) then
        return
    end
    if collider.gameObject.name == XEnumConst.GOLDEN_MINER.HOOK_IGNORE_HIT then
        return
    end

    if self:_HandleReflectEdge(hookEntity, collider) then
        return
    end

    local stoneEntity = self._MainControl.SystemMap:GetEntityByCollider(collider)
    self:_OnRopeHit(hookEntity, stoneEntity)
end

---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:_OnHookHit(hookEntity, stoneEntity)
    local hookComponent = hookEntity:GetComponentHook()
    --过滤不是发射中或抓取中的大钩爪
    if not self:_CheckHookCanGrab(hookComponent) then
        return
    end

    if not stoneEntity then
        if XTool.IsTableEmpty(hookEntity:GetGrabbingStoneUidList()) then
            XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE,
                    XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.GRAB_NONE,
                    XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_ID.GRAB_NONE)
        end
        self:HookRevoke(hookComponent)
        return
    end

    -- 过滤忽略类型
    if hookComponent:CheckIsIgnoreStoneType(stoneEntity.Data:GetType()) then
        return
    end

    -- 根据日月类型过滤（此判断要放在其他的前面优先判断）
    if self:_HandleSunMoonStone(hookEntity, stoneEntity) then
        return
    end

    -- 河蚌抓过或关闭就过滤
    if stoneEntity:GetComponentMussel() and
            (stoneEntity:GetComponentMussel().IsGrabbed or stoneEntity:GetComponentMussel().Status == XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.CLOSE)
    then
        self:HookRevoke(hookComponent)
        return
    end

    -- 状态不对过滤
    if not stoneEntity:IsAlive() then
        return
    end

    -- QTE
    if stoneEntity:GetComponentQTE() then
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_QTE_START, hookEntity, stoneEntity)
        return
    end

    -- 是否是能直接摧毁抓取物并加分
    if hookComponent:CheckIsGrabDestroyType(stoneEntity.Data:GetType()) then
        local score = self._MainControl:HandleStoneEntityToGrabbed(stoneEntity)
        hookComponent:SetIsNoShowFaceId(true)
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
                XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.STONE_BOOM,
                stoneEntity:GetTransform(),
                stoneEntity.Data:GetCatchEffect())
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE,
                XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.PLAY_BY_SCORE,
                self._MainControl:GetControl():GetFaceIdByScore(XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_ID.GRABBED, score))
        stoneEntity:SetStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED)
        self._MainControl:AddMapScore(score)
        self:HookRevoke(hookComponent)
        return
    end

    -- 转向点处理
    if self:_OnHookHitDirectionOrAimDir(hookEntity, stoneEntity) then
        return
    end

    -- 投影处理
    if self:_OnHookHitProjection(hookEntity, stoneEntity) then
        return
    end

    -- 碰到炸弹处理
    if self:_OnHookHitBoom(hookEntity, stoneEntity) then
        return
    end

    -- 碰到炸弹携带者处理
    if self:_OnHookHitBoom(hookEntity, stoneEntity:GetCarryStoneEntity()) then
        return
    end

    -- 碰到盾牌处理
    if self:_OnHookHitShield(hookEntity, stoneEntity) then
        return
    end

    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_HIT, stoneEntity.Data:GetType())
    if hookComponent:CheckType(XEnumConst.GOLDEN_MINER.HOOK_TYPE.MAGNETIC)
            or hookComponent:CheckType(XEnumConst.GOLDEN_MINER.HOOK_TYPE.STORE_PRESS_MAGNETIC)
    then
        if stoneEntity:GetComponentMussel() then
            self._MainControl:HookGrab(hookEntity, stoneEntity)
        else
            self._MainControl:HandleHookGrabStone(hookEntity, stoneEntity)
        end
        return
    end
    self._MainControl:HookGrab(hookEntity, stoneEntity)
end

---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:_OnRopeHit(hookEntity, stoneEntity)
    local hookComponent = hookEntity:GetComponentHook()
    if not hookComponent:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.SHOOTING) then
        return
    end

    if not stoneEntity then
        return
    end

    -- 过滤忽略类型
    if hookComponent:CheckIsIgnoreStoneType(stoneEntity.Data:GetType()) then
        return
    end

    -- 状态不对过滤
    if not stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.ALIVE) then
        return
    end

    -- 挡板撞击处理
    if self:_OnHookHitDirectionPoint(hookEntity, stoneEntity) then
        return
    end
end

---撞到挡板
---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:_OnHookHitDirectionPoint(hookEntity, stoneEntity)
    if not (stoneEntity:GetComponentDirection() or stoneEntity:GetComponentAimDirection())
            or self:_CheckCanGrabDirection()
    then
        return false
    end
    if table.indexof(hookEntity:GetHitStoneUidList(), stoneEntity:GetUid()) then
        return true
    end

    hookEntity:AddHitStone(stoneEntity:GetUid())
    local direction = stoneEntity:GetComponentDirection()
    local aimDirection = stoneEntity:GetComponentAimDirection()

    -- 转向点此时的角度
    local directionPointAngle
    if direction then
        directionPointAngle = direction:GetCurAngle()
        XMVCA.XGoldenMiner:DebugWarning("撞击转向器,方向改变!角度:"
        , direction:GetCurAngle()
        , ",StoneId:", stoneEntity.Data:GetId())
    else
        directionPointAngle = aimDirection:GetTargetAngle()
        XMVCA.XGoldenMiner:DebugWarning("撞击指定转向器,方向改变!目标StoneId:"
        , aimDirection:GetTargetStoneId()
        , ",StoneId:", stoneEntity.Data:GetId())
    end
    local hookComponent = hookEntity:GetComponentHook()
    -- 钩子的角度修正
    local curIdleRotateAngle = hookComponent:GetCurIdleRotateAngle()
    local curAngle = Vector3(0, 0, directionPointAngle + 90) - curIdleRotateAngle
    if aimDirection then
        local crossVector = XLuaVector2.GetLinesCrossPoint(
                hookEntity:GetComponentHook().Transform.position,
                hookEntity:GetComponentHook():GetCurHookPosition(),
                aimDirection.Transform.position,
                aimDirection:GetTargetStonePos())
        hookComponent:SetLastReflectRotateAngle((directionPointAngle + 90) % 360)
        hookComponent:UpdateCurDelayChangeAngleTimeByCrossPoint(crossVector, curAngle)
    else
        hookComponent:SetLastReflectRotateAngle(curAngle.z - curIdleRotateAngle.z)
        hookComponent:AddCurHitPointInfo(curAngle.z)
    end

    -- 抓到挡板表情
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE,
            XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.GRAB_STONE,
            self._MainControl._MainControl:GetCfgStoneTypeGrabFaceId(stoneEntity.Data:GetType()))
    -- 撞到挡板事件
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_HIT, stoneEntity.Data:GetType())

    return true
end

---撞到炸弹
---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:_OnHookHitBoom(hookEntity, stoneEntity)
    if not stoneEntity or not stoneEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.BOOM) then
        return false
    end

    if self:_CheckCanGrabBoom() then
        return false
    end

    -- 防爆直接穿过
    if not self:_CheckCanHitBoom() then
        return true
    end
    self._MainControl.SystemStone:SetStoneEntityStatus(stoneEntity, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_DESTROY)
    self:HookRevoke(hookEntity:GetComponentHook())

    -- 抓到炸弹表情
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE,
            XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.GRAB_STONE,
            self._MainControl._MainControl:GetCfgStoneTypeGrabFaceId(stoneEntity.Data:GetType()))
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_HIT, stoneEntity.Data:GetType())
    return true
end

---钩子撞到转向点
---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:_OnHookHitDirectionOrAimDir(hookEntity, stoneEntity)
    if (not stoneEntity:GetComponentDirection() and not stoneEntity:GetComponentAimDirection()) then
        return false
    end

    if self:_CheckCanGrabDirection() then
        return false
    end

    return true
end

---撞到投影
---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:_OnHookHitProjection(hookEntity, stoneEntity)
    if not stoneEntity:GetComponentProjection() then
        return false
    end
    -- 撞到投影出声
    local soundId = self._MainControl:GetClientProjectorSoundId(3)
    if XTool.IsNumberValid(soundId) then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, soundId)
    end
    -- 钩爪回收发表情
    self:HookRevoke(hookEntity:GetComponentHook())
    return true
end

---碰到盾牌
---@param hookEntity XGoldenMinerEntityHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:_OnHookHitShield(hookEntity, stoneEntity)
    if not stoneEntity:GetComponentShield() then
        return false
    end

    if self:_CheckCanGrabShield() then
        return false
    end

    self:HookRevoke(hookEntity:GetComponentHook()) -- 直接回收勾爪

    return true
end

function XGoldenMinerSystemHook:_HandleSunMoonStone(hookEntity, stoneEntity)
    local sunMoonComponent = stoneEntity:GetComponentSunMoon()
    if not sunMoonComponent then
        return false
    end

    if sunMoonComponent.StoneRealType == XEnumConst.GOLDEN_MINER.STONE_SUN_MOON_REAL_TYPE.VIRTUAL then
        if not self._MainControl.SystemBuff:CheckHasAliveBuffByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.HOOK_EX_GRAB_VIRTUAL) then
            return true
        end
    end

    return false
end

function XGoldenMinerSystemHook:_HandleReflectEdge(hookEntity, collider)
    local reflectEdgeEntityUid = self._MainControl.SystemMap:GetReflectEdgeUidByCollider(collider)
    if not XTool.IsNumberValid(reflectEdgeEntityUid) then
        return false
    end

    local hookComponent = hookEntity:GetComponentHook()
    if not hookComponent:CheckCanReflect() then
        return false
    end

    ---@type XGoldenMinerEntityReflectEdge
    local reflectEdgeEntity = self._MainControl:GetEntityWithUid(reflectEdgeEntityUid)
    local reflectEdgeComponent = reflectEdgeEntity:GetComponentReflectEdge()
    local edgeFlag = reflectEdgeComponent:GetFlag()
    if edgeFlag == XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.NONE then
        return false
    end

    local newAngle
    local lastReflectRotateAngle = hookComponent:GetLastReflectRotateAngle()
    local hookIdleAngle = hookComponent:GetCurIdleRotateAngle()
    if not lastReflectRotateAngle then
        if edgeFlag == XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.TOP or edgeFlag == XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.BOTTOM then
            newAngle = 180 - hookIdleAngle.z
        elseif edgeFlag == XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.LEFT then
            newAngle = -hookIdleAngle.z
        elseif edgeFlag == XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.RIGHT then
            newAngle = 360 - hookIdleAngle.z
        end
    else
        if edgeFlag == XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.TOP or edgeFlag == XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.BOTTOM then
            if lastReflectRotateAngle < 180 then
                newAngle = 180 - lastReflectRotateAngle
            else
                newAngle = 540 - lastReflectRotateAngle
            end
        elseif edgeFlag == XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.LEFT or edgeFlag == XEnumConst.GOLDEN_MINER.REFLECT_EDGE_FLAG.RIGHT then
            newAngle = 360 - lastReflectRotateAngle
        end
    end

    hookComponent:SetLastReflectRotateAngle(newAngle)
    hookComponent:AddCurHitPointInfo(XLuaVector3.New(0, 0, newAngle - hookIdleAngle.z))
    hookComponent:SetReflectCount(hookComponent:GetReflectCount() + 1)

    return true
end
--endregion

--region Hook - Control
function XGoldenMinerSystemHook:HookShoot()
    if XTool.IsTableEmpty(self._HookEntityUidList) then
        return
    end
    if self._MainControl:IsPause() or self._MainControl:IsEnd() or self._MainControl:IsQTE() then
        return
    end

    if not self:CheckSystemIsIdle() then
        return
    end
    self:_SetSystemStatus(XEnumConst.GOLDEN_MINER.GAME_SYSTEM_HOOK_STATUS.USING)

    for _, uid in ipairs(self._HookEntityUidList) do
        local hookComponent = self._MainControl:GetHookEntityByUid(uid):GetComponentHook()
        self:_SetHookStatus(hookComponent, XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.SHOOTING)
        --每次发射时重置弹射信息
        hookComponent:SetLastReflectRotateAngle(nil)
        hookComponent:SetReflectCount(0)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE,
            XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.SHOOTING,
            XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_ID.SHOOTING)
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, HOOK_SHOOT_SOUND_CUR_ID)
end

---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:HookRevoke(hook)
    if self._MainControl:IsPause() or self._MainControl:IsEnd() or self._MainControl:IsQTE() then
        return
    end
    if not self:CheckSystemIsUsing() then
        return
    end
    if not hook:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.SHOOTING)
            and not hook:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.GRABBING)
            and not hook:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.QTE)
    then
        return
    end

    self:_SetHookStatus(hook, XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.REVOKING)
    if hook:IsNoShowFaceId() then
        return
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_FACE,
            XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_TYPE.REVOKING,
            XEnumConst.GOLDEN_MINER.GAME_FACE_PLAY_ID.REVOKING)
end

function XGoldenMinerSystemHook:HookRevokeAll(status)
    if XTool.IsTableEmpty(self._HookEntityUidList) then
        return
    end
    for _, uid in ipairs(self._HookEntityUidList) do
        local hookComponent = self._MainControl:GetHookEntityByUid(uid):GetComponentHook()
        if status and hookComponent:CheckStatus(status) then
            self:HookRevoke(hookComponent)
        else
            self:HookRevoke(hookComponent)
        end
    end
end

---@param hook XGoldenMinerComponentHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:HookGrab(hook, stoneEntity)
    if XTool.IsTableEmpty(self._HookEntityUidList) then
        return
    end
    if self._MainControl:IsPause() or self._MainControl:IsEnd() then
        return
    end
    if not self:CheckSystemIsUsing() then
        return
    end
    if not self:_CheckHookCanGrab(hook) then
        return
    end
    self:_SetHookStatus(hook, XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.GRABBING)
    self:_SetStoneEntityOnHook(hook, stoneEntity)
end

---设置钩爪为待使用状态
---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_HookIdle(hook)
    if XTool.IsTableEmpty(self._HookEntityUidList) and not hook then
        return
    end

    if hook:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.REVOKING) then
        self:_OnHookRevokeToIdle(hook)
    end
    self:_SetHookStatus(hook, XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.IDLE)

    for _, uid in ipairs(self._HookEntityUidList) do
        if not self._MainControl:GetHookEntityByUid(uid):GetComponentHook():CheckStatus(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.IDLE) then
            return
        end
    end
    self:_SetSystemStatus(XEnumConst.GOLDEN_MINER.GAME_SYSTEM_HOOK_STATUS.IDLE)
end

---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_OnHookRevokeToIdle(hook)
    local hookEntity = hook:GetHookEntity()
    for _, uid in ipairs(hookEntity:GetGrabbingStoneUidList()) do
        local stoneEntity = self._MainControl:GetStoneEntityByUid(uid)
        if stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING) then
            self._MainControl.SystemStone:SetStoneEntityStatus(stoneEntity, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED)
            hookEntity:AddGrabbedStone(uid)
        end
    end
    self._MainControl:OnHookRevokeToIdle(hookEntity)
end

---@param hook XGoldenMinerComponentHook
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemHook:_SetStoneEntityOnHook(hook, stoneEntity)
    ---@type XGoldenMinerEntityStone
    local tempStoneEntity = stoneEntity
    -- 河蚌只抓携带物
    if tempStoneEntity:GetComponentMussel() then
        tempStoneEntity = stoneEntity:GetCarryStoneEntity()
    end
    if not tempStoneEntity or XTool.UObjIsNil(tempStoneEntity:GetTransform()) then
        return
    end
    local rectTransform = tempStoneEntity:GetTransform():GetComponent("RectTransform")

    if tempStoneEntity:GetComponentAimDirection() then
        tempStoneEntity:GetTransform():SetParent(hook:GetGrabPoint(), true)
        tempStoneEntity:GetComponentAimDirection().Transform.localPosition = Vector3(0, -60, 0)
    else
        tempStoneEntity:GetTransform():SetParent(hook:GetGrabPoint(), false)
        rectTransform.anchorMin = Vector2(0.5, 1)
        rectTransform.anchorMax = Vector2(0.5, 1)
        rectTransform.pivot = Vector2(0.5, 1)
        if tempStoneEntity:GetComponentMouse() then
            tempStoneEntity:GetTransform().localPosition = Vector3(0, self._MainControl:GetClientMouseGrabOffset(), 0)
        else
            tempStoneEntity:GetTransform().localPosition = Vector3.zero
        end
        tempStoneEntity:GetTransform().localRotation = CS.UnityEngine.Quaternion.identity
    end

    if string.IsNilOrEmpty(tempStoneEntity.Data:GetCatchEffect()) or tempStoneEntity:GetComponentAimDirection() then
        return
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
            XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.GRAB,
            tempStoneEntity:GetTransform(),
            tempStoneEntity.Data:GetCatchEffect())
end

---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_SetHookStatus(hook, status)
    if hook:CheckStatus(status) then
        return
    end
    if status == XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.SHOOTING then
        hook:ChangeShooting()
    elseif status == XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.GRABBING  -- 磁力钩不存在Grabbing状态
            and (hook:CheckType(XEnumConst.GOLDEN_MINER.HOOK_TYPE.MAGNETIC) or
            hook:CheckType(XEnumConst.GOLDEN_MINER.HOOK_TYPE.STORE_PRESS_MAGNETIC))
    then
        return
    elseif status == XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.GRABBING
            and hook:CheckType(XEnumConst.GOLDEN_MINER.HOOK_TYPE.BIG)
    then
        -- 大钩爪抓取时也可以抓物体故不进行操作(4期重新开启)

    elseif status == XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.REVOKING then
        hook:OnHookChangeToRevoke()
    else
        hook:UpdateHitColliderEnable(false)
    end

    hook:SetStatus(status)

    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_STATUS_CHANGED, status)
end
--endregion

--region Hook - Update
---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:UpdateHook(hook, time)
    if not hook then
        return
    end
    if hook:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.IDLE) then
        self:_UpdateHookIdle(hook, time)
    elseif hook:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.READY) then
        self:_UpdateHookReady(hook, time)
    elseif hook:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.SHOOTING) then
        self:_UpdateHookShooting(hook, time)
    elseif hook:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.GRABBING) then
        self:_UpdateHookGrab(hook, time)
    elseif hook:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.REVOKING) then
        self:_UpdateHookRevoking(hook, time)
    elseif hook:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.QTE) then
        self:_UpdateHookQTE(hook, time)
    end
end

---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_UpdateHookIdle(hook, time)
    hook:UpdateAim()
    local isElectromagnetic = self._MainControl:CheckBuffStatusByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.ELECTROMAGNETIC, XEnumConst.GOLDEN_MINER.GAME_BUFF_STATUS.BE_DIE)
    -- 存在一个钩子还在出钩状态 或 电磁炮放炮期间 就不摇晃
    if not self:CheckSystemIsIdle() or isElectromagnetic then
        return
    end
    hook:UpdateIdleRope(time, self._HookEntityUidList)
end

---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_UpdateHookReady(hook, time)
end

---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_UpdateHookShooting(hook, time)
    hook:DownCurDelayChangeAngleTime(time)
    hook:UpdateRoleLength(hook:GetCurRopeLength() + time * hook:GetCurShootSpeed())

    if hook:CheckIsRevoke() then
        self:HookRevoke(hook)
    end

    hook:UpdateAim(false)
end

---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_UpdateHookGrab(hook, time)
end

---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_UpdateHookRevoking(hook, time)
    local hookEntity = hook:GetHookEntity()
    local revokeSpeed = self:_ComputeRevokeSpeed(hookEntity)
    hook:UpdateRoleLength(hook:GetCurRopeLength() - time * revokeSpeed, true)
    if hook:CheckIsIdle() then
        self:_HookIdle(hook)
    else
        hook:UpdateAim(false)
    end
end

---@param hook XGoldenMinerComponentHook
function XGoldenMinerSystemHook:_UpdateHookQTE(hook, time)
end

---计算回收速度
---@param hookEntity XGoldenMinerEntityHook
---@return number
function XGoldenMinerSystemHook:_ComputeRevokeSpeed(hookEntity)
    local speed
    local isNoGabbingStone = XTool.IsTableEmpty(hookEntity:GetGrabbingStoneUidList())
    if not XTool.IsTableEmpty(hookEntity:GetHitStoneUidList()) then
        local hitStoneCount = #hookEntity:GetHitStoneUidList()
        speed = self._MainControl:GetClientHookHitPointRevokeSpeed(hitStoneCount)
        if isNoGabbingStone then
            local noGabbingSpeed = self._MainControl:GetClientRopeShortenNotCatchSpeed()
            if noGabbingSpeed > speed then
                -- 当没抓到东西和撞到转向点同时满足时 谁快用谁的
                speed = noGabbingSpeed
            end
        end
    else
        if isNoGabbingStone then
            speed = self._MainControl:GetClientRopeShortenNotCatchSpeed()
        else
            speed = self._MainControl:GetClientRopeShortenSpeed()
        end
    end
    local weight = 0
    local qteSpeedRate = 1
    for _, uid in pairs(hookEntity:GetGrabbingStoneUidList()) do
        local stoneEntity = self._MainControl:GetStoneEntityByUid(uid)
        if stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING) then
            weight = weight + stoneEntity:GetComponentStone().CurWeight
        end
        local qteComponent = stoneEntity:GetComponentQTE()
        if qteComponent and qteComponent.SpeedRate > qteSpeedRate then
            qteSpeedRate = qteComponent.SpeedRate
            XMVCA.XGoldenMiner:DebugWarning("QTE回收，速度倍率=" .. qteSpeedRate)
        end
    end
    local param = weight + self._MainControl:GetClientShortenSpeedParameter()
    local hookComponent = hookEntity:GetComponentHook()
    param = XTool.IsNumberValid(param) and param or 1
    speed = speed * (1 - (weight / param)) * hookComponent:GetCurRevokeSpeedPercent() * qteSpeedRate
    XMVCA.XGoldenMiner:DebugLog("当前钩爪回收速度=" .. speed, hookComponent:GetCurRevokeSpeedPercent())
    return speed
end
--endregion

--region Hook - AimControl
function XGoldenMinerSystemHook:HookAimRight()
    for _, uid in ipairs(self._HookEntityUidList) do
        self._MainControl:GetHookEntityByUid(uid):GetComponentHook():UpdateCurIdleRotateDirection(1)
    end
end

function XGoldenMinerSystemHook:HookAimLeft()
    for _, uid in ipairs(self._HookEntityUidList) do
        self._MainControl:GetHookEntityByUid(uid):GetComponentHook():UpdateCurIdleRotateDirection(-1)
    end
end

function XGoldenMinerSystemHook:HookAimIdle()
    for _, uid in ipairs(self._HookEntityUidList) do
        self._MainControl:GetHookEntityByUid(uid):GetComponentHook():UpdateCurIdleRotateDirection(false)
    end
end
--endregion

return XGoldenMinerSystemHook