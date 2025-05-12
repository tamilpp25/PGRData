---@class XGoldenMinerEntityStone:XEntity
---@field _OwnControl XGoldenMinerGameControl
local XGoldenMinerEntityStone = XClass(XEntity, "XGoldenMinerEntityStone")

--region Be Override
function XGoldenMinerEntityStone:OnInit()
    self.Status = XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.NONE
    ---@type XGoldenMinerMapStoneData
    self.Data = false
    self.CarryStoneUid = 0
    ---额外参数
    ---@type number[]
    self.AdditionValue = {}
end

function XGoldenMinerEntityStone:OnRelease()
    self.Data = nil
    self.AdditionValue = nil
end
--endregion

--region Getter
function XGoldenMinerEntityStone:GetStatus()
    return self.Status
end

---@return UnityEngine.Transform
function XGoldenMinerEntityStone:GetTransform()
    return self:GetComponentStone().Transform
end

---@return XGoldenMinerEntityStone
function XGoldenMinerEntityStone:GetCarryStoneEntity()
    if XTool.IsNumberValid(self.CarryStoneUid) then
        return self._OwnControl:GetEntityWithUid(self.CarryStoneUid)
    end
    return false
end

---@return XGoldenMinerComponentTimeLineAnim
function XGoldenMinerEntityStone:GetComponentAnim()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.TIME_LINE)
end

---@return XGoldenMinerComponentStone
function XGoldenMinerEntityStone:GetComponentStone()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.STONE)
end

---@return XGoldenMinerComponentMove
function XGoldenMinerEntityStone:GetComponentMove()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.STONE_MOVE)
end

---@return XGoldenMinerComponentMouse
function XGoldenMinerEntityStone:GetComponentMouse()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.STONE_MOUSE)
end

---@return XGoldenMinerComponentQTE
function XGoldenMinerEntityStone:GetComponentQTE()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.STONE_QTE)
end

---@return XGoldenMinerComponentMussel
function XGoldenMinerEntityStone:GetComponentMussel()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.STONE_MUSSEL)
end

---@return XGoldenMinerComponentDirectionPoint
function XGoldenMinerEntityStone:GetComponentDirection()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.STONE_DIRECTION)
end

---@return XGoldenMinerComponentProjection
function XGoldenMinerEntityStone:GetComponentProjection()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.STONE_PROJECTION)
end

---@return XGoldenMinerComponentProjector
function XGoldenMinerEntityStone:GetComponentProjector()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.STONE_PROJECTOR)
end

---@return XGoldenMinerComponentAimDirection
function XGoldenMinerEntityStone:GetComponentAimDirection()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.STONE_DIRECTION_AIM)
end

---@return XGoldenMinerComponentShield
function XGoldenMinerEntityStone:GetComponentShield()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.STONE_SHIELD)
end

---@return XGoldenMinerComponentSunMoon
function XGoldenMinerEntityStone:GetComponentSunMoon()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.STONE_SUN_MOON)
end
--endregion

--region Setter
function XGoldenMinerEntityStone:SetStatus(status)
    if self:CheckStatus(status) then
        return
    end
    self.Status = status
    if status == XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.ALIVE then
        self:_ChangeAlive()
    end
end
--endregion

--region Check
function XGoldenMinerEntityStone:IsAlive()
    return self.Status == XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.ALIVE or
            self.Status == XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.SHIP_AIM
end

function XGoldenMinerEntityStone:IsMove()
    return self.Status == XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.ALIVE
end

function XGoldenMinerEntityStone:CheckStatus(status)
    return self.Status == status
end
--endregion

--region Control
function XGoldenMinerEntityStone:_ChangeAlive()
    local direction = self:GetComponentDirection()
    if direction then
        direction:InitAlive()
    end
    local directionAim = self:GetComponentAimDirection()
    if directionAim then
        directionAim:InitAlive()
    end
end
--endregion

--region Debug
function XGoldenMinerEntityStone:__DebugLog()
    return {
        Data = self.Data,
        Component = self._ComponentDir
    }
end
--endregion

return XGoldenMinerEntityStone