---@class XGoldenMinerComponentMove:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityStone
local XGoldenMinerComponentMove = XClass(XEntity, "XGoldenMinerComponentMove")

--region Override
function XGoldenMinerComponentMove:OnInit()
    self.MoveType = XEnumConst.GOLDEN_MINER.GAME_STONE_MOVE_TYPE.NONE

    self.StartDirection = 0
    self.CurDirection = 0
    self.Speed = 0
    ---@type UnityEngine.Vector3
    self.StartPoint = false             -- 运动轨迹起点
    ---@type UnityEngine.Vector3
    self.CircleMovePoint = false        -- 圆周运动圆心
    ---@type UnityEngine.Vector3
    self._CircleAxis = Vector3.back     -- 圆周运动旋转轴
    self.MoveMinLimit = 0
    self.MoveMaxLimit = 0
    -- Dynamic Value
    ---@type XLuaVector3
    self._CurPos = XLuaVector3.New()
    ---@type XLuaVector3
    self._CurScale = XLuaVector3.New()
end

function XGoldenMinerComponentMove:OnRelease()
    self._CircleAxis = nil
    self._CurPos = nil
    self._CurScale = nil
end
--endregion

--region Getter
function XGoldenMinerComponentMove:GetCurDirection()
    if not self.CurDirection then
        return 1
    end
    return self.CurDirection >= 0 and 1 or -1
end
--endregion

--region Setter
function XGoldenMinerComponentMove:SetCurPos(value)
    self._CurPos:UpdateByVector(value)
end

function XGoldenMinerComponentMove:SetCurScale(value)
    self._CurScale:UpdateByVector(value)
end
--endregion

--region Check
function XGoldenMinerComponentMove:IsHorizontal()
    return self.MoveType == XEnumConst.GOLDEN_MINER.GAME_STONE_MOVE_TYPE.HORIZONTAL
end

function XGoldenMinerComponentMove:IsVertical()
    return self.MoveType == XEnumConst.GOLDEN_MINER.GAME_STONE_MOVE_TYPE.VERTICAL
end

function XGoldenMinerComponentMove:IsCircle()
    return self.MoveType == XEnumConst.GOLDEN_MINER.GAME_STONE_MOVE_TYPE.CIRCLE
end
--endregion

--region Control
function XGoldenMinerComponentMove:UpdateMove(deltaTime)
    if self:IsHorizontal() then
        local x = self._CurPos.x + deltaTime * self.CurDirection * self.Speed
        if x < self.MoveMinLimit then
            x = self.MoveMinLimit
            self:ChangeMoveDirection()
        elseif x > self.MoveMaxLimit then
            x = self.MoveMaxLimit
            self:ChangeMoveDirection()
        end
        self._CurPos:Update(x, self._CurPos.y, self._CurPos.z)
        self._ParentEntity:GetTransform().localPosition = self._CurPos
    elseif self:IsVertical() then
        local y = self._CurPos.y + deltaTime * self.CurDirection * self.Speed
        if y < self.MoveMinLimit then
            y = self.MoveMinLimit
            self:ChangeMoveDirection()
        elseif y > self.MoveMaxLimit then
            y = self.MoveMaxLimit
            self:ChangeMoveDirection()
        end
        self._CurPos:Update(self._CurPos.x, y, self._CurPos.z)
        self._ParentEntity:GetTransform().localPosition = self._CurPos
    elseif self:IsCircle() then
        self._ParentEntity:GetTransform():RotateAround(self.CircleMovePoint, self._CircleAxis, self.Speed * deltaTime)
    end
end

local MILLION_PERCENT = 1000000
function XGoldenMinerComponentMove:ChangeMoveDirection()
    self.CurDirection = -self.CurDirection
    local isTurnType = self._ParentEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.MOUSE) or
            self._ParentEntity.Data:CheckType(XEnumConst.GOLDEN_MINER.STONE_TYPE.PROJECTION)
    if not isTurnType or self:IsCircle() then
        return
    end
    -- 定春移动需要处理表现方向
    local scale = self._ParentEntity.Data:GetScale() / MILLION_PERCENT
    self._CurScale:Update(math.abs(scale) * self.CurDirection, scale, scale)
    -- 转向时翻面
    self._ParentEntity:GetTransform().localScale = self._CurScale
    -- 携带物转向不翻面
    --local carryEntity = self._ParentEntity:GetCarryStoneEntity()
    --if carryEntity then
    --    carryEntity:GetTransform().localScale = Vector3(
    --            carryEntity:GetTransform().localScale.x * self.CurDirection,
    --            carryEntity:GetTransform().localScale.y,
    --            carryEntity:GetTransform().localScale.z)
    --end
end
--endregion

return XGoldenMinerComponentMove