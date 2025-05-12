---@class XGoldenMinerComponentShipMove:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityShip
local XGoldenMinerComponentShipMove = XClass(XEntity, "XGoldenMinerComponentShipMove")

--region Override
function XGoldenMinerComponentShipMove:OnInit()
    self._Status = XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.NONE

    -- Static value
    ---@type UnityEngine.Transform
    self._MoveRoot = nil
    self._MoveRootPosY = 0
    self._MoveXRange = 0
    self._MoveBaseSpeed = 0
    self._MoveSpeedPercent = 100
    -- Dynamic value
    self._CurBuffAddSpeedPercent = 0
    ---@type XLuaVector3
    self._CurPosVector = XLuaVector3.New()

    -- 绳子更新飞船移动
    self._IsRopeUpdateShipMove = false
    self._IsUpdateByHookRevoke = false

    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_SHIP_MOVE, self._SetStatus, self)
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_STATUS_CHANGED, self._OnHookStatusChanged, self)
end

function XGoldenMinerComponentShipMove:OnRelease()
    self._MoveRoot = nil
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_SHIP_MOVE, self._SetStatus, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_STATUS_CHANGED, self._OnHookStatusChanged, self)
end
--endregion

--region Getter
function XGoldenMinerComponentShipMove:_GetMoveSpeed()
    return self._MoveBaseSpeed * (self._MoveSpeedPercent + self._CurBuffAddSpeedPercent) / 100
end
--endregion

--region Setter
function XGoldenMinerComponentShipMove:SetMoveRoot(value)
    self._MoveRoot = value
    self._MoveRootPosY = self._MoveRoot.localPosition.y
end

function XGoldenMinerComponentShipMove:SetMoveRange(value)
    self._MoveXRange = value
end

function XGoldenMinerComponentShipMove:SetMoveBaseSpeed(value)
    self._MoveBaseSpeed = value
end

function XGoldenMinerComponentShipMove:ComputeBuffSpeedPercent(value, isAdd)
    if isAdd then
        self._CurBuffAddSpeedPercent = self._CurBuffAddSpeedPercent + value
    else
        self._CurBuffAddSpeedPercent = self._CurBuffAddSpeedPercent - value
    end
end

function XGoldenMinerComponentShipMove:SetIsRopeUpdateShipMove(value)
    self._IsRopeUpdateShipMove = value
end

function XGoldenMinerComponentShipMove:_SetCurMovePos(value)
    if math.abs(value) * 2 > self._MoveXRange then
        self:_SetStatus(XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.NONE)
        return
    end
    self._CurPosVector:Update(value, self._MoveRootPosY, 0)
    self._MoveRoot.localPosition = self._CurPosVector
end

function XGoldenMinerComponentShipMove:_SetCurMovePosByRope(ropeAngleZ, ropeDetailVector)
    local radian = math.rad(ropeAngleZ)
    ropeDetailVector = math.abs(ropeDetailVector)
    local x = self._MoveRoot.localPosition.x + math.sin(radian) * ropeDetailVector
    local y = self._MoveRoot.localPosition.y - math.cos(radian) * ropeDetailVector
    self._CurPosVector:Update(x, y, 0)
    self._MoveRoot.localPosition = self._CurPosVector
end

function XGoldenMinerComponentShipMove:_SetStatus(status, isLeft)
    if self:_CheckStatus(status) then
        return
    end
    if status == XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.NONE and isLeft ~= nil then
        if isLeft and self:_CheckStatus(XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.RIGHT) then
            return
        end

        if not isLeft and self:_CheckStatus(XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.LEFT) then
            return
        end
    end
    self._Status = status
end

function XGoldenMinerComponentShipMove:_OnHookStatusChanged(hookStatus)
    self._IsUpdateByHookRevoke = hookStatus == XEnumConst.GOLDEN_MINER.GAME_HOOK_STATUS.REVOKING
    -- 根据飞船是否被绳子回收来决定是否开启飞船碰撞
    self._ParentEntity:GetComponentGrab():SetShipColliderEnable(self._IsUpdateByHookRevoke)
end
--endregion

--region Check
function XGoldenMinerComponentShipMove:_CheckStatus(status)
    return self._Status == status
end

function XGoldenMinerComponentShipMove:IsMoving()
    return self._Status ~= XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.NONE
end
--endregion

--region Control
function XGoldenMinerComponentShipMove:AddCurBuffAddSpeedPercent(value)
    self._CurBuffAddSpeedPercent = self._CurBuffAddSpeedPercent + value
end

function XGoldenMinerComponentShipMove:UpdateShipMove(deltaTime)
    if self._IsRopeUpdateShipMove and self._IsUpdateByHookRevoke then
        -- 用绳子回收时的数据更新飞船移动
        local hook = self._OwnControl.SystemHook:GetFirstHookEntity()
        if not hook then
            return
        end

        -- 如果没有抓取的物体，不更新飞船位置
        if XTool.IsTableEmpty(self._OwnControl.SystemHook:GetAllHookGrabbingEntityUidList()) then
            return
        end

        local hookComponent = hook:GetComponentHook()
        local ropeDetailVector = hookComponent:GetCurRopeDetailVector()
        local ropeAngleZ = hookComponent:GetCurRopeAngleZ()
        self:_SetCurMovePosByRope(ropeAngleZ, ropeDetailVector)
    else
        -- 正常使用左右移动
        if self:_CheckStatus(XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.NONE) then
            return
        end
        local speed = self:_GetMoveSpeed()
        XMVCA.XGoldenMiner:DebugLog("飞船移动速度:", speed, ",当前速度倍率:", self._MoveSpeedPercent + self._CurBuffAddSpeedPercent)
        if self:_CheckStatus(XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.LEFT) then
            local pos = self._CurPosVector.x - deltaTime * speed
            self:_SetCurMovePos(pos)
        elseif self:_CheckStatus(XEnumConst.GOLDEN_MINER.SHIP_MOVE_STATUS.RIGHT) then
            local pos = self._CurPosVector.x + deltaTime * speed
            self:_SetCurMovePos(pos)
        end
    end
end
--endregion

return XGoldenMinerComponentShipMove