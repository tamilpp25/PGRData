---@class XGoldenMinerEntityShip:XEntity
---@field _OwnControl XGoldenMinerGameControl
local XGoldenMinerEntityShip = XClass(XEntity, "XGoldenMinerEntityShip")

--region Be Override
function XGoldenMinerEntityShip:OnInit()
end

function XGoldenMinerEntityShip:OnRelease()
end
--endregion

--region Getter
---@return XGoldenMinerComponentShipMove
function XGoldenMinerEntityShip:GetComponentMove()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.SHIP_MOVE)
end

---@return XGoldenMinerComponentShipShell
function XGoldenMinerEntityShip:GetComponentShell()
    return self:GetFirstChildEntityWithType(self._OwnControl.COMPONENT_TYPE.SHIP_SHELL)
end
--endregion

return XGoldenMinerEntityShip