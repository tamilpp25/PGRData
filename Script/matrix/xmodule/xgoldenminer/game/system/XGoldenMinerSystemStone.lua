---管理抓取物的逻辑（依赖XGoldenMinerSystemMap）
---@class XGoldenMinerSystemStone:XEntityControl
---@field _MainControl XGoldenMinerGameControl
local XGoldenMinerSystemStone = XClass(XEntityControl, "XGoldenMinerSystemStone")

--region Override
function XGoldenMinerSystemStone:OnInit()
    self._BoomHandlerStoneTypeDir = {
        [XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.ALIVE] = true,
        [XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING] = true,
        [XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.SHIP_AIM] = true,
    }
end

function XGoldenMinerSystemStone:EnterGame()
    self:OnUpdate(0, true)
end

function XGoldenMinerSystemStone:OnUpdate(time, isInit)
    local stoneUidDir = self._MainControl:GetStoneEntityUidDirByType()
    local usedTime = self._MainControl:GetGameData() and self._MainControl:GetGameData():GetUsedTime() or 0
    if XTool.IsTableEmpty(stoneUidDir) then
        return
    end
    -- 时间停止则不处理延时问题
    if self._MainControl:IsTimeStop() then
        time = 0
    end
    for uid, _ in pairs(stoneUidDir) do
        if not isInit then
            self:_UpdateStone(self._MainControl:GetStoneEntityByUid(uid), time)
        end
        self:_CheckStoneStatusTime(self._MainControl:GetStoneEntityByUid(uid), usedTime, time)
    end
end

function XGoldenMinerSystemStone:OnRelease()
    self._BoomHandlerStoneTypeDir = nil
end
--endregion

--region Data - Setter
---抓取物状态改变
---@param stoneEntity XGoldenMinerEntityStone
---@param status number XEnumConst.GOLDEN_MINER.GAME_GRAB_OBJ_STATUS
function XGoldenMinerSystemStone:SetStoneEntityStatus(stoneEntity, status)
    if not stoneEntity or stoneEntity:CheckStatus(status) then
        return
    end
    if status == XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.ALIVE then
    elseif status == XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_ALIVE then
    elseif status == XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING then
        self:_SetMusselGrabbing(stoneEntity)
        self:_SetMouseGrabbing(stoneEntity)
    elseif status == XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED then
    elseif status == XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.HIDE then
    elseif status == XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_DESTROY then
        self:_SetBoomBeDestroy(stoneEntity)
        -- 定春被炸
        self:_SetMouseBeBoomDestroy(stoneEntity)

        if stoneEntity:GetComponentStone().BeDestroyTime <= 0 and not stoneEntity:GetComponentMussel() then
            self:SetStoneEntityStatus(stoneEntity, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.DESTROY)
            return
        end
    elseif status == XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.DESTROY then
    end
    stoneEntity:SetStatus(status)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_SetStoneEntityTransform(stoneEntity, active)
    if stoneEntity:GetTransform() then
        stoneEntity:GetTransform().gameObject:SetActiveEx(active)
    end
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_SetStoneEntityCollider(stoneEntity, active)
    local stoneComponent = stoneEntity:GetComponentStone()
    if stoneComponent.Collider and not XTool.UObjIsNil(stoneComponent.Collider) then
        stoneComponent.Collider.enabled = active
    end
    if stoneComponent.GoInputHandler then
        stoneComponent.GoInputHandler.enabled = active
    end
end
--endregion

--region Stone - Hit
---@param stoneEntity XGoldenMinerEntityStone
---@param beHitStoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:OnStoneHit(stoneEntity, beHitStoneEntity)
    if not beHitStoneEntity then
        return
    end
    -- 自己不处于Alive和Grabbing状态不处理碰撞
    if not self._BoomHandlerStoneTypeDir[stoneEntity:GetStatus()] then
        return
    end
    
    -- 撞上炸弹
    if beHitStoneEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.BOOM) then
        self:_OnStoneHitBoom(stoneEntity, beHitStoneEntity)
    end
end

---@param stoneEntity XGoldenMinerEntityStone
---@param beHitStoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_OnStoneHitBoom(stoneEntity, beHitStoneEntity)
    -- 炸弹如果不是将爆炸不管
    if not beHitStoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_DESTROY) then
        return
    end

    -- 河蚌被炸
    if stoneEntity:GetComponentMussel() then
        self:_SetMusselBeBoom(stoneEntity)
        return
    end

    -- 定春被炸
    if stoneEntity:GetComponentMouse() then
        self:_SetMouseBeBoom(stoneEntity)
        return
    end

    -- 如果不会被炸毁不管
    if not stoneEntity.Data:IsBoomDestroy() then
        return
    end
    self:SetStoneEntityStatus(stoneEntity, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_DESTROY)
end
--endregion

--region Stone - Update 
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_CheckStoneStatusTime(stoneEntity, usedTime, time)
    local stoneComponent = stoneEntity:GetComponentStone()
    if stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.NONE)
            or stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_ALIVE)
    then
        if stoneComponent.BornDelayTime > 0 and stoneComponent.BornDelayTime > usedTime then
            self:SetStoneEntityStatus(stoneEntity, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_ALIVE)
        else
            self:SetStoneEntityStatus(stoneEntity, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.ALIVE)
        end
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.ALIVE) then
        if stoneComponent.AutoDestroyTime > 0 and stoneComponent.AutoDestroyTime <= usedTime then
            self:SetStoneEntityStatus(stoneEntity, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.DESTROY)
        end
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING) then
        return
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED) then
        return
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.HIDE) then
        stoneComponent.HideTime = stoneComponent.HideTime - time
        if stoneComponent.HideTime <= 0 then
            self:SetStoneEntityStatus(stoneEntity, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.ALIVE)
        end
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_DESTROY) then
        if stoneEntity:GetComponentMussel() then
            return
        end
        stoneComponent.BeDestroyTime = stoneComponent.BeDestroyTime - time
        if stoneComponent.BeDestroyTime <= 0 then
            self:SetStoneEntityStatus(stoneEntity, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.DESTROY)
        end
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.DESTROY) then
        return
    end
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStone(stoneEntity, time)
    if stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.NONE) then
        return
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_ALIVE) then
        self:_UpdateStoneBeAlive(stoneEntity, time)
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.ALIVE) then
        self:_UpdateStoneAlive(stoneEntity, time)
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING) then
        self:_UpdateStoneGrabbing(stoneEntity, time)
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED) then
        self:_UpdateStoneGrabbed(stoneEntity, time)
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.HIDE) then
        self:_UpdateStoneHide(stoneEntity, time)
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.SHIP_CATCHING) then
        self:_OnStoneGrabbing(stoneEntity, time)
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_DESTROY) then
        self:_UpdateStoneBeDestroy(stoneEntity, time)
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.DESTROY) then
        self:_UpdateStoneDestroy(stoneEntity, time)
    end
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStoneBeAlive(stoneEntity, time)
    self:_SetStoneEntityTransform(stoneEntity, false)
    self:_SetStoneEntityCollider(stoneEntity, false)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStoneAlive(stoneEntity, time)
    self:_SetStoneEntityTransform(stoneEntity, true)
    self:_SetStoneEntityCollider(stoneEntity, true)
    
    self:_SetMouseAlive(stoneEntity)
    
    self:_UpdateMusselTime(stoneEntity, time)
    self:_UpdateHookDirectionPointTime(stoneEntity, time)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStoneGrabbing(stoneEntity, time)
    self:_SetStoneEntityTransform(stoneEntity, true)
    self:_SetStoneEntityCollider(stoneEntity, true)

    self:_OnStoneGrabbing(stoneEntity, time)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStoneGrabbed(stoneEntity, time)
    if stoneEntity:GetComponentMussel() then
        -- 河蚌被抓去也能开闭
        self:_SetStoneEntityTransform(stoneEntity, true)
        self:_SetStoneEntityCollider(stoneEntity, true)
        self:_UpdateMusselTime(stoneEntity, time)
        return
    end
    if stoneEntity:GetComponentProjector() then
        self:_OnProjectorDisappear(stoneEntity)
        self:_SetStoneEntityTransform(stoneEntity, false)
        self:_SetStoneEntityCollider(stoneEntity, false)
        return
    end
    self:_SetStoneEntityTransform(stoneEntity, false)
    self:_SetStoneEntityCollider(stoneEntity, false)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStoneHide(stoneEntity, time)
    self:_SetStoneEntityTransform(stoneEntity, false)
    self:_SetStoneEntityCollider(stoneEntity, false)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStoneBeDestroy(stoneEntity, time)
    self:_SetStoneEntityTransform(stoneEntity, true)
    self:_SetStoneEntityCollider(stoneEntity, false)
    
    self:_OnMouseDestroy(stoneEntity)
    self:_UpdateMusselTime(stoneEntity, time)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStoneDestroy(stoneEntity, time)
    if stoneEntity:GetComponentProjector() then
        self:_OnProjectorDisappear(stoneEntity)
    end
    self:_SetStoneEntityTransform(stoneEntity, false)
    self:_SetStoneEntityCollider(stoneEntity, false)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_OnStoneGrabbing(stoneEntity, time)
    -- 河蚌被抓去也能开闭
    self:_UpdateMusselTime(stoneEntity, time)
    if stoneEntity:GetComponentProjector() then
        self:_OnProjectorDisappear(stoneEntity)
    end
end
--endregion

--region Stone - Mouse
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_OnMouseDestroy(stoneEntity)
    local mouseComponent = stoneEntity:GetComponentMouse()
    if not mouseComponent or not mouseComponent.IsBoom then
        return
    end
    local curBezierPoint = XTool.GetBezierPoint((mouseComponent.BoomTime - stoneEntity:GetComponentStone().BeDestroyTime) / mouseComponent.BoomTime, 
            mouseComponent.BoomStartPos,
            mouseComponent.BoomBezierControlPoint, 
            mouseComponent.BoomEndPos)
    stoneEntity:GetTransform().localPosition = curBezierPoint
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_SetMouseBeBoom(stoneEntity)
    stoneEntity:GetComponentMouse().IsBoom = true
    self:SetStoneEntityStatus(stoneEntity, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_DESTROY)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_SetMouseBeBoomDestroy(stoneEntity)
    local mouseComponent = stoneEntity:GetComponentMouse()
    if not mouseComponent or not mouseComponent.IsBoom then
        return
    end
    stoneEntity:GetComponentStone().BeDestroyTime = mouseComponent.BoomTime
    local screen = CS.UnityEngine.Screen
    --随机左右边界
    local endPosX = math.random(0, 1) == 1 and screen.width or 0
    mouseComponent.BoomStartPos = stoneEntity:GetTransform().localPosition
    mouseComponent.BoomEndPos = Vector3(endPosX, mouseComponent.BoomStartPos.y, mouseComponent.BoomStartPos.z)
    --中间点，起点和终点的向量相加乘0.5，再加一个高度
    mouseComponent.BoomBezierControlPoint = (mouseComponent.BoomStartPos + mouseComponent.BoomEndPos) * 0.5 + (Vector3.up * 400)
    
    self:_SetMouseStatus(mouseComponent, XEnumConst.GOLDEN_MINER.GAME_MOUSE_STATE.BOOM)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
            XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.STONE_BOOM,
            stoneEntity:GetTransform(),
            stoneEntity.Data:GetCatchEffect())
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_SetMouseGrabbing(stoneEntity)
    if not stoneEntity:GetComponentMouse() then
        return
    end

    stoneEntity:GetTransform().rotation = CS.UnityEngine.Quaternion.identity
    self:_SetMouseStatus(stoneEntity:GetComponentMouse(), XEnumConst.GOLDEN_MINER.GAME_MOUSE_STATE.GRABBING)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_SetMouseAlive(stoneEntity)
    if not stoneEntity:GetComponentMouse() then
        return
    end
    self:_SetMouseStatus(stoneEntity:GetComponentMouse(), XEnumConst.GOLDEN_MINER.GAME_MOUSE_STATE.ALIVE)
end

---@param mouse XGoldenMinerComponentMouse
function XGoldenMinerSystemStone:_SetMouseStatus(mouse, toStatus)
    if not mouse or mouse.Status == toStatus then
        return
    end
    for status, trans in pairs(mouse.StateTrans) do
        trans.gameObject:SetActiveEx(status == toStatus)
    end
    local oldCarryParent = mouse.CarryPoint[mouse.Status]
    local newCarryParent = mouse.CarryPoint[toStatus]
    if oldCarryParent and newCarryParent and oldCarryParent.childCount > 0 then
        for i = oldCarryParent.childCount - 1, 0, -1 do
            oldCarryParent:GetChild(i):SetParent(newCarryParent, false)
        end
    end
    mouse.Status = toStatus
end
--endregion

--region Stone - Boom
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_SetBoomBeDestroy(stoneEntity)
    if not stoneEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.BOOM) then
        return
    end
    local RawImg = stoneEntity:GetTransform():GetComponent("RawImage")
    local stoneComponent = stoneEntity:GetComponentStone()
    if stoneComponent.BoomCollider then
        stoneComponent.BoomCollider.enabled = true
    end
    if RawImg then
        RawImg.enabled = false
    end
    stoneComponent.BeDestroyTime = 0.5
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
            XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.STONE_BOOM,
            stoneEntity:GetTransform(),
            stoneEntity.Data:GetCatchEffect())
end
--endregion

--region Stone - Mussel
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateMusselTime(stoneEntity, time)
    local musselComponent = stoneEntity:GetComponentMussel()
    if not musselComponent or not time then
        return
    end
    -- 永久暴露便不再计时
    if not musselComponent.CanHide then
        if musselComponent.Status == XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.CLOSE then
            self:_SetMusselStatus(musselComponent, XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.OPEN)
        end
        self:_CheckMusselCarryStatus(stoneEntity)
        return
    end
    musselComponent.CurTime = musselComponent.CurTime - time
    if musselComponent.Status == XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.OPEN then
        if musselComponent.CurTime <= 0 then
            self:_SetMusselStatus(musselComponent, XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.CLOSE)
            musselComponent.CurTime = musselComponent.HideTime
            XMVCA.XGoldenMiner:DebugWarning("河蚌关闭:id=".. stoneEntity.Data:GetId())
        end
    elseif musselComponent.Status == XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.CLOSE then
        if musselComponent.CurTime <= 0 then
            self:_SetMusselStatus(musselComponent, XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.OPEN)
            musselComponent.CurTime = musselComponent.OpenTime
            XMVCA.XGoldenMiner:DebugWarning("河蚌开启:id=".. stoneEntity.Data:GetId())
        end
    end

    self:_CheckMusselCarryStatus(stoneEntity)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_SetMusselBeBoom(stoneEntity)
    local musselComponent = stoneEntity:GetComponentMussel()
    if not musselComponent then
        return
    end
    musselComponent.CanHide = false
    self:_SetMusselStatus(musselComponent, XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.OPEN)
    self:_SetStoneEntityTransform(stoneEntity:GetCarryStoneEntity(), false)
    XMVCA.XGoldenMiner:DebugWarning("河蚌被炸,不再闭合:id=".. stoneEntity.Data:GetId())
end

---@param mussel XGoldenMinerComponentMussel
function XGoldenMinerSystemStone:_SetMusselStatus(mussel, state)
    if mussel.Status == state then
        return
    end
    if mussel.AnimOpen then
        mussel.OpenCollider.gameObject:SetActiveEx(state == XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.OPEN)
        mussel.CloseCollider.gameObject:SetActiveEx(state == XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.CLOSE)
        mussel.AnimOpen.gameObject:SetActiveEx(state == XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.OPEN)
        mussel.AnimClose.gameObject:SetActiveEx(state == XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.CLOSE)
    end
    mussel.Status = state
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_SetMusselGrabbing(stoneEntity)
    if not stoneEntity:GetComponentMussel() then
        return
    end
    stoneEntity:GetComponentMussel().IsGrabbed = true
    XMVCA.XGoldenMiner:DebugWarning("河蚌携带物被抓取:id=".. stoneEntity.Data:GetId())
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_CheckMusselCarryStatus(stoneEntity)
    local musselComponent = stoneEntity:GetComponentMussel()
    local carryEntity = stoneEntity:GetCarryStoneEntity()
    if not musselComponent or not carryEntity then
        return
    end
    
    if stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBING) then
        self:_SetStoneEntityTransform(carryEntity, musselComponent.IsGrabbed)
    elseif stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED)
            or stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_DESTROY)
            or stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.DESTROY)
    then
        self:_SetStoneEntityTransform(carryEntity, false)
    elseif stoneEntity:IsAlive() then
        -- 河蚌本身状态
        if musselComponent.Status == XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.OPEN then
            self:_SetStoneEntityTransform(carryEntity, not musselComponent.IsGrabbed)
        elseif musselComponent.Status == XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.CLOSE then
            self:_SetStoneEntityTransform(carryEntity, musselComponent.IsGrabbed or false)
        end
    end
end
--endregion

--region Stone - HookDirectionPoint
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateHookDirectionPointTime(stoneEntity, time)
    if not stoneEntity:GetComponentDirection() or not time then
        return
    end
    stoneEntity:GetComponentDirection():Update(time)
end
--endregion

--region Stone - Projector
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_OnProjectorDisappear(stoneEntity)
    local projectorComponent = stoneEntity:GetComponentProjector()
    if projectorComponent:IsDisappear() then
        return
    end
    projectorComponent:SetIsDisappear(true)
    projectorComponent:CloseShowEffect()
    local isBoom = false
    for uid, _ in pairs(self._MainControl:GetStoneEntityUidDirByType(XEnumConst.GOLDEN_MINER.STONE_TYPE.PROJECTION)) do
        local stone = self._MainControl:GetStoneEntityByUid(uid)
        if stone:IsAlive() then
            --stone.Stone.BeDestroyTime = 0.4
            isBoom = true
            self:SetStoneEntityStatus(stone, XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.BE_DESTROY)
            XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
                    XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.STONE_BOOM,
                    stone:GetTransform(),
                    self._MainControl:GetClientTypeBoomEffect())
        end
    end
    local soundId = self._MainControl:GetClientProjectorSoundId(isBoom and 1 or 2)
    if XTool.IsNumberValid(soundId) then
        XSoundManager.PlaySoundByType(soundId, XSoundManager.SoundType.Sound)
    end
end
--endregion

return XGoldenMinerSystemStone