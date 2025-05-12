---@class XGoldenMinerComponentShipGrab:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityShip
local XGoldenMinerComponentShipGrab = XClass(XEntity, "XGoldenMinerComponentShipGrab")

--region Override
function XGoldenMinerComponentShipGrab:OnInit()
    ---@type UnityEngine.Collider
    self._ShipCollider = nil
    ---@type CS.XGoInputHandler
    self._InputHandler = nil
    
    self._CanGrabStoneTypes = nil
    self._CanGrabRealStoneTypes = nil
    self._CanGrabVirtualStoneTypes = nil
end

function XGoldenMinerComponentShipGrab:OnRelease()
    self._ShipCollider = nil
    self._InputHandler = nil

    self._CanGrabStoneTypes = nil
    self._CanGrabRealStoneTypes = nil
    self._CanGrabVirtualStoneTypes = nil
end
--endregion

--region Getter
function XGoldenMinerComponentShipGrab:GetCanGrabStoneTypes()
    return self._CanGrabStoneTypes
end

function XGoldenMinerComponentShipGrab:GetCanGrabRealStoneTypes()
    return self._CanGrabRealStoneTypes
end

function XGoldenMinerComponentShipGrab:GetCanGrabVirtualStoneTypes()
    return self._CanGrabVirtualStoneTypes
end

--endregion

--region Setter
function XGoldenMinerComponentShipGrab:SetShipCollider(collider)
    self._ShipCollider = collider
end

function XGoldenMinerComponentShipGrab:SetInputHandler(inputHandler)
    self._InputHandler = inputHandler
end

function XGoldenMinerComponentShipGrab:SetShipColliderEnable(enable)
    if self._ShipCollider then
        self._ShipCollider.enabled = enable
    end
end

function XGoldenMinerComponentShipGrab:SetCanGrabStoneTypes(types)
    self._CanGrabStoneTypes = types
end

function XGoldenMinerComponentShipGrab:SetCanGrabRealStoneTypes(types)
    self._CanGrabRealStoneTypes = types
end

function XGoldenMinerComponentShipGrab:SetCanGrabVirtualStoneTypes(types)
    self._CanGrabVirtualStoneTypes = types
end
--endregion

return XGoldenMinerComponentShipGrab