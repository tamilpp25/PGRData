---@class XGoldenMinerSystemStone
local XGoldenMinerSystemStone = XClass(nil, "XGoldenMinerSystemStone")

---@param game XGoldenMinerGame
function XGoldenMinerSystemStone:Init(game)
    local stoneList = game.StoneEntityList
    local usedTime = game:GetData() and game:GetData():GetUsedTime() or 0
    if XTool.IsTableEmpty(stoneList) then
        return
    end
    for _, stoneEntity in ipairs(stoneList) do
        -- 初始化基础参数
        self:ComputeStoneScore(stoneEntity)
        stoneEntity.Stone.Weight = self:ComputeStoneWeight(stoneEntity)
        stoneEntity.Stone.CurWeight = stoneEntity.Stone.Weight
        self:CheckStoneStatusTime(stoneEntity, usedTime, 0)
        self:UpdateStone(game, stoneEntity, 0)
        self:CheckStoneStatusTime(stoneEntity, usedTime, 0)
    end
end

---@param game XGoldenMinerGame
function XGoldenMinerSystemStone:Update(game, time)
    local stoneList = game.StoneEntityList
    local usedTime = game:GetData() and game:GetData():GetUsedTime() or 0
    if XTool.IsTableEmpty(stoneList) then
        return
    end
    -- 时间停止则不处理延时问题
    if game:IsTimeStop() then
        time = 0
    end
    for _, stoneEntity in ipairs(stoneList) do
        self:UpdateStone(game, stoneEntity, time)
        self:CheckStoneStatusTime(stoneEntity, usedTime, time)
    end
end

--region Data - Compute
---计算抓取物分数
---@param stoneEntity XGoldenMinerEntityStone
---@return number
function XGoldenMinerSystemStone:ComputeStoneWeight(stoneEntity)
    local weight = 0
    weight = self:_GetStoneWeight(stoneEntity)
    if stoneEntity.CarryStone then
        weight = weight + self:_GetStoneWeight(stoneEntity.CarryStone)
    end
    return weight
end

---计算抓取物分数
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:ComputeStoneScore(stoneEntity)
    stoneEntity.Stone.Score = self:_GetStoneScore(stoneEntity)
    stoneEntity.Stone.CurScore = stoneEntity.Stone.Score
    if stoneEntity.CarryStone then
        stoneEntity.CarryStone.Stone.Score = self:_GetStoneScore(stoneEntity.CarryStone)
        stoneEntity.CarryStone.Stone.CurScore = stoneEntity.CarryStone.Stone.Score
    end
end

---@return number
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_GetStoneScore(stoneEntity)
    local score = 0
    if stoneEntity.Data:GetType() == XGoldenMinerConfigs.StoneType.RedEnvelope then
        local redEnvelopeGroup = stoneEntity.Data:GetRedEnvelopeGroup()
        local redEnvelopeId = stoneEntity.AdditionValue[XGoldenMinerConfigs.StoneType.RedEnvelope]
        if not redEnvelopeId then
            stoneEntity.AdditionValue[XGoldenMinerConfigs.StoneType.RedEnvelope] = XGoldenMinerConfigs.GetRedEnvelopeRandId(redEnvelopeGroup)
            redEnvelopeId = stoneEntity.AdditionValue[XGoldenMinerConfigs.StoneType.RedEnvelope]
        end
        score = XGoldenMinerConfigs.GetRedEnvelopeScore(redEnvelopeId)
    else
        score = stoneEntity.Data:GetScore()
    end
    return score
end

---@return number
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_GetStoneWeight(stoneEntity)
    local weight = 0
    if stoneEntity.Data:GetType() == XGoldenMinerConfigs.StoneType.RedEnvelope then
        local redEnvelopeGroup = stoneEntity.Data:GetRedEnvelopeGroup()
        local redEnvelopeId = stoneEntity.AdditionValue[XGoldenMinerConfigs.StoneType.RedEnvelope]
        if not redEnvelopeId then
            stoneEntity.AdditionValue[XGoldenMinerConfigs.StoneType.RedEnvelope] = XGoldenMinerConfigs.GetRedEnvelopeRandId(redEnvelopeGroup)
            redEnvelopeId = stoneEntity.AdditionValue[XGoldenMinerConfigs.StoneType.RedEnvelope]
        end
        weight = XGoldenMinerConfigs.GetRedEnvelopeHeft(redEnvelopeId)
    else
        weight = stoneEntity.Data:GetWeight()
    end
    return weight
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
    if stoneEntity.Status ~= XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.ALIVE
            and stoneEntity.Status ~= XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING
    then
        return
    end
    
    -- 撞上炸弹
    if beHitStoneEntity.Data:GetType() == XGoldenMinerConfigs.StoneType.Boom then
        self:_OnStoneHitBoom(stoneEntity, beHitStoneEntity)
    end
end

---@param stoneEntity XGoldenMinerEntityStone
---@param beHitStoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_OnStoneHitBoom(stoneEntity, beHitStoneEntity)
    -- 炸弹如果不是将爆炸不管
    if beHitStoneEntity.Status ~= XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_DESTROY then
        return
    end

    -- 河蚌被炸
    if stoneEntity.Mussel then
        self:SetMusselBeBoom(stoneEntity)
        return
    end

    -- 定春被炸
    if stoneEntity.Mouse then
        self:SetMouseBeBoom(stoneEntity)
        return
    end

    -- 如果不会被炸毁不管
    if not stoneEntity.Data:IsBoomDestroy() then
        return
    end
    self:SetStoneEntityStatus(stoneEntity, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_DESTROY)
end
--endregion

--region Update - Stone
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:CheckStoneStatusTime(stoneEntity, usedTime, time)
    if stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.NONE
            or stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_ALIVE
    then
        if stoneEntity.Stone.BornDelayTime > 0 and stoneEntity.Stone.BornDelayTime > usedTime then
            self:SetStoneEntityStatus(stoneEntity, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_ALIVE)
        else
            self:SetStoneEntityStatus(stoneEntity, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.ALIVE)
        end
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.ALIVE then
        if stoneEntity.Stone.AutoDestroyTime > 0 and stoneEntity.Stone.AutoDestroyTime <= usedTime then
            self:SetStoneEntityStatus(stoneEntity, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.DESTROY)
        end
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING then
        return
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBED then
        return
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.HIDE then
        stoneEntity.Stone.HideTime = stoneEntity.Stone.HideTime - time
        if stoneEntity.Stone.HideTime <= 0 then
            self:SetStoneEntityStatus(stoneEntity, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.ALIVE)
        end
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_DESTROY then
        if stoneEntity.Mussel then
            return
        end
        stoneEntity.Stone.BeDestroyTime = stoneEntity.Stone.BeDestroyTime - time
        if stoneEntity.Stone.BeDestroyTime <= 0 then
            self:SetStoneEntityStatus(stoneEntity, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.DESTROY)
        end
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.DESTROY then
        return
    end
end

---@param game XGoldenMinerGame
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:UpdateStone(game, stoneEntity, time)
    if stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.NONE then
        return
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_ALIVE then
        self:_UpdateStoneBeAlive(game, stoneEntity, time)
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.ALIVE then
        self:_UpdateStoneAlive(game, stoneEntity, time)
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING then
        self:_UpdateStoneGrabbing(game, stoneEntity, time)
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBED then
        self:_UpdateStoneGrabbed(game, stoneEntity, time)
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.HIDE then
        self:_UpdateStoneHide(game, stoneEntity, time)
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_DESTROY then
        self:_UpdateStoneBeDestroy(game, stoneEntity, time)
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.DESTROY then
        self:_UpdateStoneDestroy(game, stoneEntity, time)
    end
end

---@param game XGoldenMinerGame
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStoneBeAlive(game, stoneEntity, time)
    self:SetStoneEntityTransform(stoneEntity, false)
    self:SetStoneEntityCollider(stoneEntity, false)
end

---@param game XGoldenMinerGame
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStoneAlive(game, stoneEntity, time)
    self:SetStoneEntityTransform(stoneEntity, true)
    self:SetStoneEntityCollider(stoneEntity, true)
    
    self:SetMouseAlive(stoneEntity)
    
    self:UpdateMusselTime(stoneEntity, time)
    self:UpdateHookDirectionPointTime(stoneEntity, time)
end

---@param game XGoldenMinerGame
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStoneGrabbing(game, stoneEntity, time)
    self:SetStoneEntityTransform(stoneEntity, true)
    self:SetStoneEntityCollider(stoneEntity, true)

    -- 河蚌被抓去也能开闭
    self:UpdateMusselTime(stoneEntity, time)
end

---@param game XGoldenMinerGame
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStoneGrabbed(game, stoneEntity, time)
    if stoneEntity.Mussel then
        -- 河蚌被抓去也能开闭
        self:SetStoneEntityTransform(stoneEntity, true)
        self:SetStoneEntityCollider(stoneEntity, true)
        self:UpdateMusselTime(stoneEntity, time)
    else
        self:SetStoneEntityTransform(stoneEntity, false)
        self:SetStoneEntityCollider(stoneEntity, false)
    end
end

---@param game XGoldenMinerGame
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStoneHide(game, stoneEntity, time)
    self:SetStoneEntityTransform(stoneEntity, false)
    self:SetStoneEntityCollider(stoneEntity, false)
end

---@param game XGoldenMinerGame
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStoneBeDestroy(game, stoneEntity, time)
    self:SetStoneEntityTransform(stoneEntity, true)
    self:SetStoneEntityCollider(stoneEntity, false)
    
    self:OnMouseDestroy(stoneEntity)
    self:UpdateMusselTime(stoneEntity, time)
end

---@param game XGoldenMinerGame
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:_UpdateStoneDestroy(game, stoneEntity, time)
    self:SetStoneEntityTransform(stoneEntity, false)
    self:SetStoneEntityCollider(stoneEntity, false)
end

---抓取物状态改变
---@param stoneEntity XGoldenMinerEntityStone
---@param status number XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS
function XGoldenMinerSystemStone:SetStoneEntityStatus(stoneEntity, status)
    if not stoneEntity or stoneEntity.Status == status then
        return
    end
    if status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.ALIVE then
    elseif status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_ALIVE then
        
    elseif status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING then
        self:SetMusselGrabbing(stoneEntity)
        self:SetMouseGrabbing(stoneEntity)
    elseif status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBED then
    elseif status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.HIDE then
    elseif status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_DESTROY then
        self:SetBoomBeDestroy(stoneEntity)
        
        -- 定春被炸
        self:SetMouseBeBoomDestroy(stoneEntity)
        
        if stoneEntity.Stone.BeDestroyTime <= 0 and not stoneEntity.Mussel then
            self:SetStoneEntityStatus(stoneEntity, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.DESTROY)
            return
        end
    elseif status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.DESTROY then
    end
    stoneEntity.Status = status
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:SetStoneEntityTransform(stoneEntity, active)
    if stoneEntity.Stone.Transform then
        stoneEntity.Stone.Transform.gameObject:SetActiveEx(active)
    end
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:SetStoneEntityCollider(stoneEntity, active)
    if stoneEntity.Stone.Collider and not XTool.UObjIsNil(stoneEntity.Stone.Collider) then
        stoneEntity.Stone.Collider.enabled = active
    end
    if stoneEntity.Stone.GoInputHandler then
        stoneEntity.Stone.GoInputHandler.enabled = active
    end
end
--endregion

--region Stone - Mouse
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:OnMouseDestroy(stoneEntity)
    if not stoneEntity.Mouse or not stoneEntity.Mouse.IsBoom then
        return
    end
    local curBazierPoint = XTool.GetBezierPoint((stoneEntity.Mouse.BoomTime - stoneEntity.Stone.BeDestroyTime) / stoneEntity.Mouse.BoomTime, 
            stoneEntity.Mouse.BoomStartPos,
            stoneEntity.Mouse.BoomBezierControlPoint, 
            stoneEntity.Mouse.BoomEndPos)
    stoneEntity.Stone.Transform.localPosition = curBazierPoint
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:SetMouseBeBoom(stoneEntity)
    if not stoneEntity.Mouse then
        return
    end
    stoneEntity.Mouse.IsBoom = true
    self:SetStoneEntityStatus(stoneEntity, XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_DESTROY)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:SetMouseBeBoomDestroy(stoneEntity)
    if not stoneEntity.Mouse or not stoneEntity.Mouse.IsBoom then
        return
    end
    stoneEntity.Stone.BeDestroyTime = stoneEntity.Mouse.BoomTime
    local screen = CS.UnityEngine.Screen
    --随机左右边界
    local endPosX = math.random(0, 1) == 1 and screen.width or 0
    stoneEntity.Mouse.BoomStartPos = stoneEntity.Stone.Transform.localPosition
    stoneEntity.Mouse.BoomEndPos = Vector3(endPosX, stoneEntity.Stone.Transform.localPosition.y, stoneEntity.Stone.Transform.localPosition.z)
    --中间点，起点和终点的向量相加乘0.5，再加一个高度
    stoneEntity.Mouse.BoomBezierControlPoint = (stoneEntity.Stone.Transform.localPosition + stoneEntity.Mouse.BoomEndPos) * 0.5 + (Vector3.up * 400)
    
    self:SetMouseStatus(stoneEntity.Mouse, XGoldenMinerConfigs.GAME_MOUSE_STATE.BOOM)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
            XGoldenMinerConfigs.GAME_EFFECT_TYPE.STONE_BOOM,
            stoneEntity.Stone.Transform,
            stoneEntity.Data:GetCatchEffect())
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:SetMouseGrabbing(stoneEntity)
    if not stoneEntity.Mouse then
        return
    end

    if stoneEntity.Stone.Transform.rotation ~= CS.UnityEngine.Quaternion.identity then
        stoneEntity.Stone.Transform.rotation = CS.UnityEngine.Quaternion.identity
    end
    self:SetMouseStatus(stoneEntity.Mouse, XGoldenMinerConfigs.GAME_MOUSE_STATE.GRABBING)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:SetMouseAlive(stoneEntity)
    if not stoneEntity.Mouse then
        return
    end
    self:SetMouseStatus(stoneEntity.Mouse, XGoldenMinerConfigs.GAME_MOUSE_STATE.ALIVE)
end

---@param mouse XGoldenMinerComponentMouse
function XGoldenMinerSystemStone:SetMouseStatus(mouse, toStatus)
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
function XGoldenMinerSystemStone:SetBoomBeDestroy(stoneEntity)
    if stoneEntity.Data:GetType() ~= XGoldenMinerConfigs.StoneType.Boom then
        return
    end
    local RawImg = stoneEntity.Stone.Transform:GetComponent("RawImage")
    if stoneEntity.Stone.BoomCollider then
        stoneEntity.Stone.BoomCollider.enabled = true
    end
    if RawImg then
        RawImg.enabled = false
    end
    stoneEntity.Stone.BeDestroyTime = 0.5
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
            XGoldenMinerConfigs.GAME_EFFECT_TYPE.STONE_BOOM,
            stoneEntity.Stone.Transform,
            stoneEntity.Data:GetCatchEffect())
end
--endregion

--region Stone - Mussel
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:UpdateMusselTime(stoneEntity, time)
    if not stoneEntity.Mussel or not time then
        return
    end
    -- 永久暴露便不再计时
    if not stoneEntity.Mussel.CanHide then
        if stoneEntity.Mussel.Status == XGoldenMinerConfigs.GAME_MUSSEL_STATUS.CLOSE then
            self:SetMusselStatus(stoneEntity.Mussel, XGoldenMinerConfigs.GAME_MUSSEL_STATUS.OPEN)
        end
        self:CheckMusselCarryStatus(stoneEntity)
        return
    end
    stoneEntity.Mussel.CurTime = stoneEntity.Mussel.CurTime - time
    if stoneEntity.Mussel.Status == XGoldenMinerConfigs.GAME_MUSSEL_STATUS.OPEN then
        if stoneEntity.Mussel.CurTime <= 0 then
            self:SetMusselStatus(stoneEntity.Mussel, XGoldenMinerConfigs.GAME_MUSSEL_STATUS.CLOSE)
            stoneEntity.Mussel.CurTime = stoneEntity.Mussel.HideTime
            --XGoldenMinerConfigs.DebugLog("河蚌关闭:id=".. stoneEntity.Data:GetId())
        end
    elseif stoneEntity.Mussel.Status == XGoldenMinerConfigs.GAME_MUSSEL_STATUS.CLOSE then
        if stoneEntity.Mussel.CurTime <= 0 then
            self:SetMusselStatus(stoneEntity.Mussel, XGoldenMinerConfigs.GAME_MUSSEL_STATUS.OPEN)
            stoneEntity.Mussel.CurTime = stoneEntity.Mussel.OpenTime
            --XGoldenMinerConfigs.DebugLog("河蚌开启:id=".. stoneEntity.Data:GetId())
        end
    end

    self:CheckMusselCarryStatus(stoneEntity)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:SetMusselBeBoom(stoneEntity)
    if not stoneEntity.Mussel then
        return
    end
    stoneEntity.Mussel.CanHide = false
    self:SetMusselStatus(stoneEntity.Mussel, XGoldenMinerConfigs.GAME_MUSSEL_STATUS.OPEN)
    self:SetStoneEntityTransform(stoneEntity.CarryStone, false)
    --XGoldenMinerConfigs.DebugLog("河蚌不再闭合:id=".. stoneEntity.Data:GetId())
end

---@param mussel XGoldenMinerComponentMussel
function XGoldenMinerSystemStone:SetMusselStatus(mussel, state)
    if mussel.Status == state then
        return
    end
    if mussel.AnimOpen then
        mussel.OpenCollider.gameObject:SetActiveEx(state == XGoldenMinerConfigs.GAME_MUSSEL_STATUS.OPEN)
        mussel.CloseCollider.gameObject:SetActiveEx(state == XGoldenMinerConfigs.GAME_MUSSEL_STATUS.CLOSE)
        mussel.AnimOpen.gameObject:SetActiveEx(state == XGoldenMinerConfigs.GAME_MUSSEL_STATUS.OPEN)
        mussel.AnimClose.gameObject:SetActiveEx(state == XGoldenMinerConfigs.GAME_MUSSEL_STATUS.CLOSE)
    end
    mussel.Status = state
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:SetMusselGrabbing(stoneEntity)
    if not stoneEntity.Mussel then
        return
    end
    stoneEntity.Mussel.IsGrabbed = true
    --XGoldenMinerConfigs.DebugLog("河蚌携带物被抓取:id=".. stoneEntity.Data:GetId())
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:CheckMusselCarryStatus(stoneEntity)
    if not stoneEntity.Mussel or not stoneEntity.CarryStone then
        return
    end
    
    if stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBING then
        self:SetStoneEntityTransform(stoneEntity.CarryStone, stoneEntity.Mussel.IsGrabbed)
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.GRABBED
            or stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.BE_DESTROY
            or stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.DESTROY
    then
        self:SetStoneEntityTransform(stoneEntity.CarryStone, false)
    elseif stoneEntity.Status == XGoldenMinerConfigs.GAME_GRAB_OBJ_STATUS.ALIVE then
        -- 河蚌本身状态
        if stoneEntity.Mussel.Status == XGoldenMinerConfigs.GAME_MUSSEL_STATUS.OPEN then
            self:SetStoneEntityTransform(stoneEntity.CarryStone, not stoneEntity.Mussel.IsGrabbed)
        elseif stoneEntity.Mussel.Status == XGoldenMinerConfigs.GAME_MUSSEL_STATUS.CLOSE then
            self:SetStoneEntityTransform(stoneEntity.CarryStone, stoneEntity.Mussel.IsGrabbed or false)
        end
    end
end
--endregion

--region Stone - HookDirectionPoint
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:UpdateHookDirectionPointTime(stoneEntity, time)
    if not stoneEntity.HookDirectionPoint or not time then
        return
    end
    stoneEntity.HookDirectionPoint.CurTime = stoneEntity.HookDirectionPoint.CurTime - time
    local angleListCount = #stoneEntity.HookDirectionPoint.AngleList
    if stoneEntity.HookDirectionPoint.CurTime <= 0 and angleListCount > 1 then
        local index = stoneEntity.HookDirectionPoint.CurAngleIndex
        index = index + 1
        if angleListCount < index then
            index = 1
        end
        stoneEntity.HookDirectionPoint.CurAngleIndex = index
        stoneEntity.HookDirectionPoint.CurTime = stoneEntity.HookDirectionPoint.AngleTimeList[index]
        --XGoldenMinerConfigs.DebugLog("转向点转向:角度="..stoneEntity.HookDirectionPoint.AngleList[index]
        --        ..",持续时间="..stoneEntity.HookDirectionPoint.AngleTimeList[index]
        --        ..",StoneId="..stoneEntity.Data:GetId())
    end
    if stoneEntity.HookDirectionPoint.FillImage then
        if angleListCount > 1 then
            local timeLimit = stoneEntity.HookDirectionPoint.AngleTimeList[stoneEntity.HookDirectionPoint.CurAngleIndex]
            stoneEntity.HookDirectionPoint.FillImage.fillAmount = 1 - stoneEntity.HookDirectionPoint.CurTime / timeLimit
        else
            stoneEntity.HookDirectionPoint.FillImage.fillAmount = 1
        end
    end
    self:CheckHookDirectionPointAngle(stoneEntity)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemStone:CheckHookDirectionPointAngle(stoneEntity)
    if not stoneEntity.HookDirectionPoint then
        return
    end
    local index = stoneEntity.HookDirectionPoint.CurAngleIndex
    if stoneEntity.HookDirectionPoint.AngleTransform.localEulerAngles.z ~= stoneEntity.HookDirectionPoint.AngleList[index] then
        stoneEntity.HookDirectionPoint.AngleTransform.localEulerAngles = Vector3(
                stoneEntity.HookDirectionPoint.AngleTransform.localEulerAngles.x,
                stoneEntity.HookDirectionPoint.AngleTransform.localEulerAngles.y,
                stoneEntity.HookDirectionPoint.AngleList[index])
    end
end
--endregion

return XGoldenMinerSystemStone