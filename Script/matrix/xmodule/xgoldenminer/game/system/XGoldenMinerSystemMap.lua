---@class XGoldenMinerSystemMap:XEntityControl
---@field _MainControl XGoldenMinerGameControl
local XGoldenMinerSystemMap = XClass(XEntityControl, "XGoldenMinerSystemMap")

local MILLION_PERCENT = 1000000
local W_PERCENT = 10000
local CSXResourceManagerLoad = CS.XResourceManager.Load
local DEFAULT_TABLE = {}

--region Override
function XGoldenMinerSystemMap:OnInit()
    self._RelicCount = 0
    self._CurGrabbedRelicCount = 0
    ---资源字典
    self._ResourcePool = {}
    ---@type table<number, boolean>
    self._StoneEntityUidDir = {}
    ---@type table<number, table<number, boolean>>
    self._StoneEntityUidTypeDir = {}
    self._ElectromagneticTime = self._MainControl:GetClientElectromagneticTime()
    
    self._ChangeGoldIgnoreStoneType = {
        [XEnumConst.GOLDEN_MINER.STONE_TYPE.MOUSE] = true,
        [XEnumConst.GOLDEN_MINER.STONE_TYPE.MUSSEL] = true,
        [XEnumConst.GOLDEN_MINER.STONE_TYPE.RELIC_FRAG] = true,
    }
end

---@param objDir XGoldenMinerGameInitObjDir
function XGoldenMinerSystemMap:EnterGame(objDir)
    ---@type UnityEngine.Vector2
    self._RectSize = objDir.RectSize
    ---@type UnityEngine.Transform
    self._MapObjRoot = objDir.MapRoot
    self._ElectromagneticBox = objDir.ElectromagneticBox
    
    local mapStoneList = self._MainControl:GetGameData():GetMapStoneDataList()
    if XTool.IsTableEmpty(mapStoneList) then
        return
    end
    for _, stoneData in ipairs(mapStoneList) do
        self:_CreateStone(stoneData)
        
        if stoneData:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.RELIC_FRAG) then
            self._RelicCount = self._RelicCount + 1
        end
    end

    if self._RelicCount > 0 then
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_GET_RELIC_FRAG, 0, self._RelicCount)
    end
    
    local stoneType
    stoneType = XEnumConst.GOLDEN_MINER.STONE_TYPE.AIM_DIRECTION
    local stoneUidList = {}
    for uid, _ in pairs(self._StoneEntityUidDir) do
        table.insert(stoneUidList, uid)
    end
    table.sort(stoneUidList)
    if not XTool.IsTableEmpty(self._StoneEntityUidTypeDir[stoneType]) then
        for stoneEntityUid, _ in pairs(self._StoneEntityUidTypeDir[stoneType]) do
            local aimDirection = self._MainControl:GetStoneEntityByUid(stoneEntityUid):GetComponentAimDirection()
            for _, uid in ipairs(stoneUidList) do
                if not aimDirection:GetTargetStone()
                        and aimDirection:GetTargetStoneId() == self._MainControl:GetStoneEntityByUid(uid).Data:GetId()
                then
                    aimDirection:SetTargetStone(self._MainControl:GetStoneEntityByUid(uid):GetTransform())
                end
            end
        end
    end

    stoneType = XEnumConst.GOLDEN_MINER.STONE_TYPE.PROJECTOR
    if not XTool.IsTableEmpty(self._StoneEntityUidTypeDir[stoneType]) then
        for projectorUid, _ in pairs(self._StoneEntityUidTypeDir[stoneType]) do
            local projectorEntity = self._MainControl:GetStoneEntityByUid(projectorUid)
            self:_InitComponentProject(projectorEntity)
        end
    end
end

function XGoldenMinerSystemMap:OnRelease()
    for _, resource in pairs(self._ResourcePool) do
        resource:Release()
    end
    self._ResourcePool = nil
    self._StoneEntityUidDir = nil
    self._StoneEntityUidTypeDir = nil
    self._MapObjRoot = nil
    self._RectSize = nil
    
    self._ChangeGoldIgnoreStoneType = nil
end
--endregion

--region Data - Getter
function XGoldenMinerSystemMap:_GetStoneCountByType(type)
    local result = 0
    for _, _ in pairs(self._StoneEntityUidTypeDir[type]) do
        result = result + 1
    end
    return result
end

---@return number[]
function XGoldenMinerSystemMap:GetStoneUidDirByType(type)
    if not XTool.IsNumberValid(type) then
        return self._StoneEntityUidDir
    end
    if self._StoneEntityUidTypeDir[type] then
        return self._StoneEntityUidTypeDir[type]
    end
    return DEFAULT_TABLE
end

---@param collider UnityEngine.Collider2D
function XGoldenMinerSystemMap:GetEntityByCollider(collider)
    if XTool.IsTableEmpty(self._StoneEntityUidDir) then
        return false
    end
    for uid, _ in pairs(self._StoneEntityUidDir) do
        local entity = self._MainControl:GetStoneEntityByUid(uid)
        if entity:GetTransform() and entity:GetTransform() == collider.transform then
            return entity
        end
        local musselComponent = entity:GetComponentMussel()
        if musselComponent then
            if musselComponent.OpenCollider and musselComponent.OpenCollider == collider then
                return entity
            end
            if musselComponent.CloseCollider and musselComponent.CloseCollider == collider then
                return entity
            end
        end
        local carryStoneEntity = entity:GetCarryStoneEntity()
        if carryStoneEntity and carryStoneEntity:GetTransform() and carryStoneEntity:GetTransform() == collider.transform then
            return entity
        end
    end
    return false
end

---@param stoneEntity XGoldenMinerEntityStone
---@return number
function XGoldenMinerSystemMap:_GetStoneScore(stoneEntity)
    local score = 0
    if stoneEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.RED_ENVELOPE) then
        local redEnvelopeGroupId = stoneEntity.Data:GetRedEnvelopeGroup()
        local redEnvelopeId = stoneEntity.AdditionValue[XEnumConst.GOLDEN_MINER.STONE_TYPE.RED_ENVELOPE]
        if not redEnvelopeId then
            stoneEntity.AdditionValue[XEnumConst.GOLDEN_MINER.STONE_TYPE.RED_ENVELOPE] = self._MainControl:GetCfgRedEnvelopeRandId(redEnvelopeGroupId)
            redEnvelopeId = stoneEntity.AdditionValue[XEnumConst.GOLDEN_MINER.STONE_TYPE.RED_ENVELOPE]
        end
        score = self._MainControl:GetCfgRedEnvelopeScore(redEnvelopeId)
    else
        score = stoneEntity.Data:GetScore()
    end
    return score
end

---@return number
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemMap:_GetStoneWeight(stoneEntity)
    local weight = 0
    if stoneEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.RED_ENVELOPE) then
        local redEnvelopeGroupId = stoneEntity.Data:GetRedEnvelopeGroup()
        local redEnvelopeId = stoneEntity.AdditionValue[XEnumConst.GOLDEN_MINER.STONE_TYPE.RED_ENVELOPE]
        if not redEnvelopeId then
            stoneEntity.AdditionValue[XEnumConst.GOLDEN_MINER.STONE_TYPE.RED_ENVELOPE] = self._MainControl:GetCfgRedEnvelopeRandId(redEnvelopeGroupId)
            redEnvelopeId = stoneEntity.AdditionValue[XEnumConst.GOLDEN_MINER.STONE_TYPE.RED_ENVELOPE]
        end
        weight = self._MainControl:GetCfgRedEnvelopeHeft(redEnvelopeId)
    else
        weight = stoneEntity.Data:GetWeight()
    end
    return weight
end

---@param rangeX XGoldenMinerValueLimit
---@param rangeY XGoldenMinerValueLimit
---@return XGoldenMinerEntityStone
function XGoldenMinerSystemMap:GetNearestStoneByTypeDir(ignoreTypeDir, rangeX, rangeY, startPosition)
    ---@type XGoldenMinerEntityStone
    local resultEntity = nil
    local distance
    for uid, _ in pairs(self._StoneEntityUidDir) do
        local stoneEntity = self._MainControl:GetStoneEntityByUid(uid)
        local isIgnoreType = ignoreTypeDir[stoneEntity.Data:GetType()]
        local isAlive = stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.ALIVE)
        local anchoredPosition = stoneEntity:GetTransform().anchoredPosition
        local isInRangeX = anchoredPosition.x >= rangeX.Min and anchoredPosition.x <= rangeX.Max
        local isInRangeY = anchoredPosition.y >= rangeY.Min and anchoredPosition.y <= rangeY.Max

        if (not isIgnoreType) and isAlive and isInRangeX and isInRangeY then
            local position = stoneEntity:GetTransform().position - startPosition
            local value = position.magnitude
            if not distance or distance > value then
                distance = value
                resultEntity = stoneEntity
            end
        end
    end
    return resultEntity
end
--endregion

--region Stone - Create
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemMap:_RemoveStoneEntity(stoneEntity)
    self._StoneEntityUidDir[stoneEntity:GetUid()] = nil
    self._StoneEntityUidTypeDir[stoneEntity.Data:GetType()][stoneEntity:GetUid()] = nil
    self._MainControl:RemoveEntity(stoneEntity)
end

---@param stoneData XGoldenMinerMapStoneData
---@return XGoldenMinerEntityStone
function XGoldenMinerSystemMap:_CreateStone(stoneData)
    ---@type XGoldenMinerEntityStone
    local stoneEntity = self._MainControl:AddEntity(self._MainControl.ENTITY_TYPE.STONE)
    stoneEntity.Data = stoneData
    local transform = self:_CreateComponentStone(stoneEntity, stoneData).Transform
    self:_CreateComponentMove(stoneEntity, stoneData, transform)
    
    if stoneData:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.MOUSE) then
        self:_CreateComponentMouse(stoneEntity, stoneData, transform)
    elseif stoneData:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.QTE) then
        self:_CreateComponentQTE(stoneEntity, stoneData, transform)
    elseif stoneData:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.MUSSEL) then
        self:_CreateComponentMussel(stoneEntity, stoneData, transform)
    elseif stoneData:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.HOOK_DIRECTION_POINT) then
        self:_CreateComponentDirectionPoint(stoneEntity, stoneData, transform)
    elseif stoneData:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.PROJECTION) then
        self:_CreateComponentProjection(stoneEntity, stoneData, transform)
    elseif stoneData:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.PROJECTOR) then
        self:_CreateComponentProjector(stoneEntity, stoneData, transform)
    elseif stoneData:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.AIM_DIRECTION) then
        self:_CreateComponentAimDirection(stoneEntity, stoneData, transform)
    end
    if stoneData:IsHaveCarryStone() then
        local carryStoneEntity = self:_CreateEntityCarryStone(stoneEntity, stoneData:GetCarryStoneId())
        stoneEntity.CarryStoneUid = carryStoneEntity:GetUid()
    end
    
    local func = function(collider)
        self:_StoneHit(stoneEntity, collider)
    end
    self:_RegisterStoneHitCallBack(stoneEntity, func)
    self:_RegisterMusselHitCallBack(stoneEntity, func)
    
    -- 初始化基础参数
    self:_ComputeStoneScore(stoneEntity)
    self:_ComputeStoneWeight(stoneEntity)

    --加入记录
    if not self._StoneEntityUidTypeDir[stoneData:GetType()] then
        self._StoneEntityUidTypeDir[stoneData:GetType()] = {}
    end
    self._StoneEntityUidTypeDir[stoneData:GetType()][stoneEntity:GetUid()] = true
    self._StoneEntityUidDir[stoneEntity:GetUid()] = true
    
    return stoneEntity
end

---@param stoneEntity XGoldenMinerEntityStone
---@param stoneData XGoldenMinerMapStoneData
---@return XGoldenMinerComponentStone
function XGoldenMinerSystemMap:_CreateComponentStone(stoneEntity, stoneData)
    ---@type XGoldenMinerComponentStone
    local stone = stoneEntity:AddChildEntity(self._MainControl.COMPONENT_TYPE.STONE)
    stone.Transform = self:_LoadStone(stoneData, self._MapObjRoot)
    if not stone.Transform then
        XLog.Error("抓取物创建失败!请检查Prefab字段!id="..stoneData:GetId())
    end
    stone.Collider = XUiHelper.TryGetComponent(stone.Transform, "", "Collider2D")
    stone.BornDelayTime = stoneData:GetBornDelay()
    stone.AutoDestroyTime = stoneData:GetDestroyTime() > 0 and (stoneData:GetBornDelay() + stoneData:GetDestroyTime()) or 0
    stone.BeDestroyTime = 0
    stone.HideTime = 0
    stone.GoInputHandler = stone.Transform:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(stone.GoInputHandler) then
        stone.GoInputHandler = stone.Transform.gameObject:AddComponent(typeof(CS.XGoInputHandler))
    end

    if stoneData:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.BOOM) then  -- 爆炸物默认碰撞体关闭
        stone.BoomCollider = XUiHelper.TryGetComponent(stone.Transform, "", "CircleCollider2D")
        if stone.BoomCollider then
            stone.BoomCollider.enabled = false
        end
    end
    return stone
end

---@param stoneEntity XGoldenMinerEntityStone
---@param stoneData XGoldenMinerMapStoneData
---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentMove
function XGoldenMinerSystemMap:_CreateComponentMove(stoneEntity, stoneData, transform)
    if not transform or XTool.UObjIsNil(transform) then
        return false
    end
    -- 静止的物体不需要Move
    if stoneData:GetMoveType() == XEnumConst.GOLDEN_MINER.GAME_STONE_MOVE_TYPE.NONE then
        return false
    end
    ---@type XGoldenMinerComponentMove
    local move = stoneEntity:AddChildEntity(self._MainControl.COMPONENT_TYPE.STONE_MOVE)
    move.MoveType = stoneData:GetMoveType()
    move.StartDirection = stoneData:GetStartMoveDirection()
    move.CurDirection = stoneData:GetStartMoveDirection()
    move.Speed = stoneData:GetMoveSpeed()
    if move.MoveType == XEnumConst.GOLDEN_MINER.GAME_STONE_MOVE_TYPE.CIRCLE then
        local x =  transform.localPosition.x + stoneData:GetMoveRange() * math.cos(move.StartDirection / 180 * math.pi)
        local y =  transform.localPosition.y + stoneData:GetMoveRange() * math.sin(move.StartDirection / 180 * math.pi)
        move.CircleMovePoint = transform.position
        move.StartPoint = Vector3(x, y, 0)
        transform:Rotate(0, 0, move.CurDirection - 90)
        transform.localPosition = move.StartPoint
    else
        move.StartPoint = transform.localPosition
        local aLimit, bLimit
        if move.MoveType == XEnumConst.GOLDEN_MINER.GAME_STONE_MOVE_TYPE.HORIZONTAL then
            aLimit = transform.localPosition.x
        elseif move.MoveType == XEnumConst.GOLDEN_MINER.GAME_STONE_MOVE_TYPE.VERTICAL then
            aLimit = transform.localPosition.y
        end
        bLimit = aLimit + move.StartDirection * stoneData:GetMoveRange()
        move.MoveMinLimit = math.min(aLimit, bLimit)
        move.MoveMaxLimit = math.max(aLimit, bLimit)
    end
    move:SetCurPos(transform.localPosition)
    move:SetCurScale(transform.localScale)

    -- 定春需要处理水平或竖直方向
    --if stoneData:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.MOUSE) 
    --        and (move:IsHorizontal() or move:IsVertical()) then
    --    transform.localScale = Vector3(
    --            transform.localScale.x * stoneData:GetStartMoveDirection(),
    --            transform.localScale.y,
    --            transform.localScale.z)
    --end
    return move
end

---@param stoneEntity XGoldenMinerEntityStone
---@param stoneData XGoldenMinerMapStoneData
---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentMouse
function XGoldenMinerSystemMap:_CreateComponentMouse(stoneEntity, stoneData, transform)
    ---@type XGoldenMinerComponentMouse
    local component = stoneEntity:AddChildEntity(self._MainControl.COMPONENT_TYPE.STONE_MOUSE)
    component.IsBoom = false
    component.StateTrans[XEnumConst.GOLDEN_MINER.GAME_MOUSE_STATE.ALIVE] = XUiHelper.TryGetComponent(transform, "Run")
    component.StateTrans[XEnumConst.GOLDEN_MINER.GAME_MOUSE_STATE.GRABBING] = XUiHelper.TryGetComponent(transform, "Grab")
    component.StateTrans[XEnumConst.GOLDEN_MINER.GAME_MOUSE_STATE.BOOM] = XUiHelper.TryGetComponent(transform, "Bomb")

    component.CarryPoint[XEnumConst.GOLDEN_MINER.GAME_MOUSE_STATE.ALIVE] = XUiHelper.TryGetComponent(transform, "Run/RunCarryItemParent")
    component.CarryPoint[XEnumConst.GOLDEN_MINER.GAME_MOUSE_STATE.GRABBING] = XUiHelper.TryGetComponent(transform, "Grab/GrabCarryItemParent")
    return component
end

---@param stoneEntity XGoldenMinerEntityStone
---@param stoneData XGoldenMinerMapStoneData
---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentQTE
function XGoldenMinerSystemMap:_CreateComponentQTE(stoneEntity, stoneData, transform)
    if not self._MainControl.SystemQTE or not stoneData:IsHaveQTE() then
        return false
    end
    ---@type XGoldenMinerComponentQTE
    local qte = stoneEntity:AddChildEntity(self._MainControl.COMPONENT_TYPE.STONE_QTE)
    qte.QTEGroupId = stoneData:GetQTEGroupId()
    qte.Time = stoneData:GetQTETime()
    
    local qteId = self._MainControl:GetCfgQTELevelGroupByCount(qte.QTEGroupId, qte.CurClickCount)
    local icon = self._MainControl:GetCfgQTELevelGroupIcon(qteId)
    qte:InitQTEComponent(transform, self._MainControl:GetCfgQTELevelGroupMaxClickCount(qte.QTEGroupId), icon)
    return qte
end

---@param stoneEntity XGoldenMinerEntityStone
---@param stoneData XGoldenMinerMapStoneData
---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentMussel
function XGoldenMinerSystemMap:_CreateComponentMussel(stoneEntity, stoneData, transform)
    if not stoneData:IsHaveMussel() then
        return false
    end
    ---@type XGoldenMinerComponentMussel
    local mussel = stoneEntity:AddChildEntity(self._MainControl.COMPONENT_TYPE.STONE_MUSSEL)
    mussel.CanHide = true
    mussel.IsGrabbed = stoneData:GetMusselIsGrabbed()
    mussel.InitIsOpen = stoneData:GetMusselInitIsOpen()
    mussel.OpenTime = stoneData:GetMusselOpenTime()
    mussel.HideTime = stoneData:GetMusselHideTime()
    mussel.AnimOpen = XUiHelper.TryGetComponent(transform, "AnimOpen/Open")
    mussel.AnimClose = XUiHelper.TryGetComponent(transform, "AnimClose/Close")
    mussel.OpenCollider = XUiHelper.TryGetComponent(transform, "AnimOpen", "Collider2D")
    mussel.CloseCollider = XUiHelper.TryGetComponent(transform, "AnimClose", "Collider2D")
    mussel.GrabCarry = XUiHelper.TryGetComponent(transform, "UiGoldenMinerBx04/ContentPos")
    if not mussel.GrabCarry then
        mussel.GrabCarry = XUiHelper.TryGetComponent(transform, "ContentPos")
    end
    if mussel.InitIsOpen then
        mussel.Status = XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.OPEN
        mussel.CurTime = mussel.OpenTime
    else
        mussel.Status = XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.CLOSE
        mussel.CurTime = mussel.HideTime
    end
    if mussel.AnimOpen then
        mussel.AnimOpen.gameObject:SetActiveEx(mussel.Status == XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.OPEN)
        mussel.AnimClose.gameObject:SetActiveEx(mussel.Status == XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.CLOSE)
    end
    if mussel.OpenCollider then
        mussel.OpenCollider.gameObject:SetActiveEx(mussel.Status == XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.OPEN)
        mussel.OpenGoInputHandler = mussel.OpenCollider.transform:GetComponent(typeof(CS.XGoInputHandler))
        if XTool.UObjIsNil(mussel.OpenGoInputHandler) then
            mussel.OpenGoInputHandler = mussel.OpenCollider.gameObject:AddComponent(typeof(CS.XGoInputHandler))
        end
    end
    if mussel.CloseCollider then
        mussel.CloseCollider.gameObject:SetActiveEx(mussel.Status == XEnumConst.GOLDEN_MINER.GAME_MUSSEL_STATUS.CLOSE)
        mussel.CloseGoInputHandler = mussel.CloseCollider.transform:GetComponent(typeof(CS.XGoInputHandler))
        if XTool.UObjIsNil(mussel.CloseGoInputHandler) then
            mussel.CloseGoInputHandler = mussel.CloseCollider.gameObject:AddComponent(typeof(CS.XGoInputHandler))
        end
    end
    return mussel
end

---@param stoneEntity XGoldenMinerEntityStone
---@param stoneData XGoldenMinerMapStoneData
---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentDirectionPoint
function XGoldenMinerSystemMap:_CreateComponentDirectionPoint(stoneEntity, stoneData, transform)
    if not stoneData:IsHaveDirectionPoint() then
        return false
    end
    ---@type XGoldenMinerComponentDirectionPoint
    local directionPoint = stoneEntity:AddChildEntity(self._MainControl.COMPONENT_TYPE.STONE_DIRECTION, stoneData:GetId())
    directionPoint.AngleList = stoneData:GetHookDirectionPointAngleList()
    directionPoint.AngleTimeList = stoneData:GetHookDirectionPointTimeList()
    directionPoint.CurAngleIndex = 1
    directionPoint.CurTime = directionPoint.AngleTimeList[directionPoint.CurAngleIndex]
    directionPoint.AngleTransform = transform
    directionPoint.CurAngleVector:UpdateByVector(transform.localEulerAngles)
    directionPoint.FillImage = XUiHelper.TryGetComponent(transform, "RImgBg03", "Image")
    return directionPoint
end

---@param stoneEntity XGoldenMinerEntityStone
---@param stoneData XGoldenMinerMapStoneData
---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentProjection
function XGoldenMinerSystemMap:_CreateComponentProjection(stoneEntity, stoneData, transform)
    ---@type XGoldenMinerComponentProjection
    local projection = stoneEntity:AddChildEntity(self._MainControl.COMPONENT_TYPE.STONE_PROJECTION)
    projection.Transform = transform
    return projection
end

---@param stoneEntity XGoldenMinerEntityStone
---@param stoneData XGoldenMinerMapStoneData
---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentProjector
function XGoldenMinerSystemMap:_CreateComponentProjector(stoneEntity, stoneData, transform)
    ---@type XGoldenMinerComponentProjector
    local projector = stoneEntity:AddChildEntity(self._MainControl.COMPONENT_TYPE.STONE_PROJECTOR)
    projector:SetTransform(transform)
    return projector
end

---处理投影仪方向指向支持配置
---@param projectorEntity XGoldenMinerEntityStone
function XGoldenMinerSystemMap:_InitComponentProject(projectorEntity)
    if XTool.IsNumberValid(projectorEntity.Data:GetRotationZ()) then
        projectorEntity:GetComponentProjector():SetTransAngle(projectorEntity.Data:GetRotationZ() / W_PERCENT)
        return
    end
    local firstReferenceAngle
    local projectorLocalPosition = projectorEntity:GetTransform().localPosition
    local angle = 0
    for uid, _ in pairs(self._StoneEntityUidTypeDir[XEnumConst.GOLDEN_MINER.STONE_TYPE.PROJECTION]) do
        local stoneLocalPosition = self._MainControl:GetStoneEntityByUid(uid):GetTransform().localPosition
        local direction = stoneLocalPosition - projectorLocalPosition
        local directionAngle = XUiHelper.GetUiAngleByVector3ReturnDirection(Vector3.right, direction.normalized)
        if not firstReferenceAngle then
            firstReferenceAngle = directionAngle
        else
            angle = angle + (directionAngle - firstReferenceAngle)
        end
    end
    angle = angle / self:_GetStoneCountByType(XEnumConst.GOLDEN_MINER.STONE_TYPE.PROJECTION) + firstReferenceAngle
    firstReferenceAngle = false
    projectorEntity:GetComponentProjector():SetTransAngle(angle)
end

---@param stoneEntity XGoldenMinerEntityStone
---@param stoneData XGoldenMinerMapStoneData
---@param transform UnityEngine.Transform
---@return XGoldenMinerComponentAimDirection
function XGoldenMinerSystemMap:_CreateComponentAimDirection(stoneEntity, stoneData, transform)
    ---@type XGoldenMinerComponentAimDirection
    local aimDirection = stoneEntity:AddChildEntity(self._MainControl.COMPONENT_TYPE.STONE_DIRECTION_AIM)
    aimDirection.Transform = transform
    aimDirection:SetTargetStoneId(stoneData:GetAimDirectionTargetStoneId())
    return aimDirection
end

---@param stoneEntity XGoldenMinerEntityStone
---@return XGoldenMinerEntityStone
function XGoldenMinerSystemMap:_CreateEntityCarryStone(stoneEntity, carryStoneId)
    if not stoneEntity.Data:IsHaveCarryStone() then
        return false
    end
    local stoneComponent = stoneEntity:GetComponentStone()
    local mouseComponent = stoneEntity:GetComponentMouse()
    local musselComponent = stoneEntity:GetComponentMussel()
    if mouseComponent then
        stoneComponent.CarryItemParent = mouseComponent.CarryPoint[XEnumConst.GOLDEN_MINER.GAME_MOUSE_STATE.ALIVE]
    elseif musselComponent and musselComponent.GrabCarry then
        stoneComponent.CarryItemParent = musselComponent.GrabCarry
    else
        stoneComponent.CarryItemParent = stoneComponent.Transform
    end
    if not stoneComponent.CarryItemParent then
        return false
    end

    ---@type XGoldenMinerEntityStone
    local carryStone = self._MainControl:AddEntity(self._MainControl.ENTITY_TYPE.STONE)
    ---@type XGoldenMinerMapStoneData
    local carryStoneData = self._MainControl:CreateStoneData(carryStoneId)
    carryStone.Data = carryStoneData
    ---@type XGoldenMinerComponentStone
    local carryStoneComponent = carryStone:AddChildEntity(self._MainControl.COMPONENT_TYPE.STONE)
    carryStoneComponent.Transform = self:_LoadStone(carryStoneData, stoneComponent.CarryItemParent)
    carryStoneComponent.Collider = XUiHelper.TryGetComponent(carryStoneComponent.Transform, "", "Collider2D")
    -- 携带物不需要碰撞体
    if carryStoneComponent.Collider then
        carryStoneComponent.Collider.enabled = false
    end
    -- 不移动不处理移动方向
    if stoneEntity.Data:GetMoveType() == XEnumConst.GOLDEN_MINER.GAME_STONE_MOVE_TYPE.NONE then
        return carryStone
    end
    -- 携带物要处理方向
    carryStoneComponent.Transform.localScale = Vector3(
            carryStoneComponent.Transform.localScale.x * stoneEntity.Data:GetStartMoveDirection(),
            carryStoneComponent.Transform.localScale.y,
            carryStoneComponent.Transform.localScale.z)

    if carryStoneData:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.BOOM) then  -- 爆炸物默认碰撞体关闭
        carryStoneComponent.BoomCollider = XUiHelper.TryGetComponent(carryStoneComponent.Transform, "", "CircleCollider2D")
        if carryStoneComponent.BoomCollider then
            carryStoneComponent.BoomCollider.enabled = false
        end
    end
    return carryStone
end

---@param stoneEntity XGoldenMinerEntityStone
---@param func function(collider)
function XGoldenMinerSystemMap:_RegisterStoneHitCallBack(stoneEntity, func)
    if not stoneEntity then
        return
    end
    local stoneComponent = stoneEntity:GetComponentStone()
    if not stoneComponent.GoInputHandler or XTool.UObjIsNil(stoneComponent.GoInputHandler) then
        return
    end
    stoneComponent.GoInputHandler:AddTriggerEnter2DCallback(func)
end

---@param stoneEntity XGoldenMinerEntityStone
---@param func function(collider)
function XGoldenMinerSystemMap:_RegisterMusselHitCallBack(stoneEntity, func)
    if not stoneEntity then
        return
    end
    local musselComponent = stoneEntity:GetComponentMussel()
    if not musselComponent or not musselComponent.OpenGoInputHandler then
        return
    end
    musselComponent.OpenGoInputHandler:AddTriggerEnter2DCallback(func)
    musselComponent.CloseGoInputHandler:AddTriggerEnter2DCallback(func)
end

---@param stoneEntity XGoldenMinerEntityStone
---@param collider UnityEngine.Collider2D
function XGoldenMinerSystemMap:_StoneHit(stoneEntity, collider)
    if not self._MainControl.SystemStone then
        return
    end
    local beHitStoneEntity = self:GetEntityByCollider(collider)
    self._MainControl.SystemStone:OnStoneHit(stoneEntity, beHitStoneEntity)
end

---计算抓取物分数
---@param stoneEntity XGoldenMinerEntityStone
---@return number
function XGoldenMinerSystemMap:_ComputeStoneWeight(stoneEntity)
    local weight = 0
    weight = self:_GetStoneWeight(stoneEntity)
    local carryStone = stoneEntity:GetCarryStoneEntity()
    if carryStone then
        weight = weight + self:_GetStoneWeight(carryStone)
    end
    local stoneComponent = stoneEntity:GetComponentStone()
    stoneComponent.Weight = weight
    stoneComponent.CurWeight = stoneComponent.Weight
end

---计算抓取物分数
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemMap:_ComputeStoneScore(stoneEntity)
    local stoneComponent = stoneEntity:GetComponentStone()
    stoneComponent.Score = self:_GetStoneScore(stoneEntity)
    stoneComponent.CurScore = stoneComponent.Score
    local carryStone = stoneEntity:GetCarryStoneEntity()
    if carryStone then
        local carryStoneComponent = carryStone:GetComponentStone()
        carryStoneComponent.Score = self:_GetStoneScore(carryStone)
        carryStoneComponent.CurScore = carryStoneComponent.Score
    end
end
--endregion

--region Stone - Change
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemMap:StoneChangeToGold(stoneEntity)
    if stoneEntity:GetCarryStoneEntity() then
        local goldId = self._MainControl:GetStoneGoldIdByWeight(stoneEntity:GetCarryStoneEntity().Data:GetWeight(), stoneEntity.Data:GetCarryStoneId())
        if not goldId then
            return
        end
        self:_CarryStoneChangeToOther(stoneEntity, goldId)
        return
    end
    if not self._ChangeGoldIgnoreStoneType[stoneEntity.Data:GetType()] then 
        local goldId = self._MainControl:GetStoneGoldIdByWeight(stoneEntity:GetComponentStone().Weight, stoneEntity.Data:GetId())
        if not goldId then
            return
        end
        return self:StoneChangeToOther(stoneEntity, goldId, true)
    end
end

---@param stoneEntity XGoldenMinerEntityStone
---@return XGoldenMinerEntityStone
function XGoldenMinerSystemMap:StoneChangeToOther(stoneEntity, stoneId, isGrab, needEffect)
    local parent = stoneEntity:GetTransform().parent
    local stoneData = self._MainControl:CreateStoneData(stoneId)

    if needEffect then
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
                XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.TYPE_BOOM,
                stoneEntity:GetTransform(),
                self._MainControl:GetClientUseBoomEffect())
    end
    local oldPosition
    if not isGrab then
        oldPosition = stoneEntity:GetTransform().position
    end
    XUiHelper.Destroy(stoneEntity:GetTransform().gameObject)
    self:_RemoveStoneEntity(stoneEntity)

    stoneEntity = self:_CreateStone(stoneData)
    if isGrab then
        stoneEntity:GetTransform():SetParent(parent, false)
        local rectTransform = stoneEntity:GetTransform():GetComponent("RectTransform")
        rectTransform.anchorMin = Vector2(0.5, 1)
        rectTransform.anchorMax = Vector2(0.5, 1)
        rectTransform.pivot = Vector2(0.5, 1)
        stoneEntity:GetTransform().localPosition = Vector3.zero
        stoneEntity:GetTransform().localRotation = CS.UnityEngine.Quaternion.identity
    else
        stoneEntity:GetTransform().position = oldPosition
    end
    return stoneEntity
end

---猫猫点石成金只改携带物
---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerSystemMap:_CarryStoneChangeToOther(stoneEntity, stoneId, needEffect)
    -- 没有携带物则道具白用
    if not stoneEntity:GetCarryStoneEntity() then
        return
    end

    if needEffect then
        XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PLAY_EFFECT,
                XEnumConst.GOLDEN_MINER.GAME_EFFECT_TYPE.TYPE_BOOM,
                stoneEntity:GetTransform(),
                self._MainControl:GetClientUseBoomEffect())
    end
    XUiHelper.Destroy(stoneEntity:GetCarryStoneEntity():GetTransform().gameObject)
    stoneEntity:RemoveChildEntity(stoneEntity:GetCarryStoneEntity())
    stoneEntity.CarryStoneUid = self:_CreateEntityCarryStone(stoneEntity, stoneId):GetUid()

    stoneEntity:GetComponentStone().Score = stoneEntity.Data:GetScore()
    stoneEntity:GetComponentStone().CurScore = stoneEntity:GetComponentStone().Score
    stoneEntity:GetCarryStoneEntity():GetComponentStone().Score = stoneEntity:GetCarryStoneEntity().Data:GetScore()
    stoneEntity:GetCarryStoneEntity():GetComponentStone().CurScore = stoneEntity:GetCarryStoneEntity().Data:GetScore()

    -- 初始化基础参数
    self:_ComputeStoneScore(stoneEntity)
    self:_ComputeStoneWeight(stoneEntity)
end
--endregion

--region Stone - Relic
function XGoldenMinerSystemMap:GetAndUpdateRelicScore()
    if self._CurGrabbedRelicCount >= self._RelicCount then
        return 0
    end
    self._CurGrabbedRelicCount = self._CurGrabbedRelicCount + 1
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_GET_RELIC_FRAG, self._CurGrabbedRelicCount, self._RelicCount)
    return self:GetRelicScore()
end

function XGoldenMinerSystemMap:GetRelicScore()
    if self._CurGrabbedRelicCount == self._RelicCount then
        return self._MainControl:GetClientRelicGatherScore()
    end
    return 0
end
--endregion

--region Handle - Electromagnetic
function XGoldenMinerSystemMap:HandlerElectromagnetic(handler)
    if not self._ElectromagneticBox then
        return 0
    end
    local hookRotation, hookTriggerPosition
    for _, uid in ipairs(self._MainControl:GetHookEntityUidList()) do
        hookRotation = self._MainControl:GetHookEntityByUid(uid):GetComponentHook().Transform.rotation
        hookTriggerPosition = self._MainControl:GetHookEntityByUid(uid):GetComponentHook():GetGrabPoint().position
    end
    if hookRotation then
        self._ElectromagneticBox.transform.rotation = hookRotation
        self._ElectromagneticBox.transform.position = hookTriggerPosition
    end
    self._ElectromagneticBox:RemoveAllListeners()
    self._ElectromagneticBox.gameObject:SetActiveEx(true)
    self._ElectromagneticBox:AddTriggerEnter2DCallback(function(collider)
        local stoneEntity = self:GetEntityByCollider(collider)
        if not stoneEntity then
            return
        end
        handler(stoneEntity)
    end)
    return self._ElectromagneticTime
end

function XGoldenMinerSystemMap:ClearElectromagnetic()
    if not self._ElectromagneticBox then
        return
    end
    self._ElectromagneticBox.gameObject:SetActiveEx(false)
end
--endregion

--region Resource
---@param stoneData XGoldenMinerMapStoneData
---@param objRoot UnityEngine.Transform
---@return UnityEngine.Transform
function XGoldenMinerSystemMap:_LoadStone(stoneData, objRoot)
    local path = stoneData:GetPrefab()

    if string.IsNilOrEmpty(path) or not objRoot or not self._RectSize then
        return
    end
    local resource = self._ResourcePool[path]
    if not resource then
        resource = CSXResourceManagerLoad(path)
        self._ResourcePool[path] = resource
    end

    if resource == nil or not resource.Asset then
        XLog.Error(string.format("XGoldenMinerSystemMap:_LoadStone加载资源，路径：%s", path))
        return
    end

    local obj = XUiHelper.Instantiate(resource.Asset, objRoot)
    -- 抓取物的携带物不存在index,直接返回
    if not XTool.IsNumberValid(stoneData:GetMapIndex()) then
        obj.transform.localPosition = Vector3.zero
        return obj.transform
    end

    local width = self._RectSize.x
    local height = self._RectSize.y
    local xPosPercent = stoneData:GetXPosPercent() / MILLION_PERCENT
    local yPosPercent = stoneData:GetYPosPercent() / MILLION_PERCENT
    local scale = stoneData:GetScale() / MILLION_PERCENT
    local rotationZ = stoneData:GetRotationZ() / W_PERCENT
    local direction
    if stoneData:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.PROJECTION)
        or stoneData:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.MOUSE)
    then
        direction = stoneData:GetStartMoveDirection() >= 0 and scale or -scale
    else
        direction = scale
    end
    obj.transform.localPosition = Vector3(xPosPercent * width, yPosPercent * height, 0)
    obj.transform.localScale = Vector3(direction, scale, scale)
    obj.transform.localEulerAngles = Vector3(0, 0, rotationZ)
    return obj.transform
end
--endregion

return XGoldenMinerSystemMap