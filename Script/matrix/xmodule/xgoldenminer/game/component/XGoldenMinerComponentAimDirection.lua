---@class XGoldenMinerComponentAimDirection:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityStone
local XGoldenMinerComponentAimDirection = XClass(XEntity, "XGoldenMinerComponentAimDirection")

function XGoldenMinerComponentAimDirection:OnInit()
    -- Static Value
    ---@type UnityEngine.Transform
    self.Transform = nil
    self._TargetStoneId = 0
    ---方向切线向量
    ---@type XLuaVector2
    self._TangentVector = XLuaVector2.New()
    
    -- Dynamic Value
    ---@type UnityEngine.Transform
    self._TargetStone = nil
    self._TargetAngle = nil
    ---@type UnityEngine.Vector3
    self._TargetStonePos = nil
end

function XGoldenMinerComponentAimDirection:OnRelease()
    self.Transform = nil
    self._TargetStone = nil
end

--region Getter
function XGoldenMinerComponentAimDirection:GetTargetStoneId()
    return self._TargetStoneId
end

function XGoldenMinerComponentAimDirection:GetTargetStone()
    return self._TargetStone
end

function XGoldenMinerComponentAimDirection:GetTargetStonePos()
    return self._TargetStone.position
end

function XGoldenMinerComponentAimDirection:GetTargetAngle()
    return self._TargetAngle
end
--endregion

--region Setter
function XGoldenMinerComponentAimDirection:SetTargetStoneId(value)
    self._TargetStoneId = value
end

---@param stone UnityEngine.Transform
function XGoldenMinerComponentAimDirection:SetTargetStone(stone)
    self._TargetStone = stone
    self._TargetStonePos = self._TargetStone.position
end

function XGoldenMinerComponentAimDirection:_SetLocalAngleZ(value)
    local localEulerAngles = self.Transform.localEulerAngles
    self.Transform.localEulerAngles = Vector3(localEulerAngles.x, localEulerAngles.y, value)
end
--endregion

--region Control
function XGoldenMinerComponentAimDirection:InitAlive()
    if not self._TargetStone then
        return
    end
    local from = self.Transform.localPosition
    local to = self._TargetStone.localPosition
    local direction = to - from
    
    self._TargetAngle = XUiHelper.GetUiAngleByVector3Return360(Vector3.right, direction.normalized)
    self:_SetLocalAngleZ(self._TargetAngle)
end
--endregion

return XGoldenMinerComponentAimDirection