---@class XGoldenMinerComponentShipShell:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityShip
local XGoldenMinerComponentShipShell = XClass(XEntity, "XGoldenMinerComponentShipShell")

--region Override
function XGoldenMinerComponentShipShell:OnInit()
    ---@type UnityEngine.UI.RawImage
    self._ShipShell = nil
end

function XGoldenMinerComponentShipShell:OnRelease()
    self._ShipShell = nil
end
--endregion

--region Setter
function XGoldenMinerComponentShipShell:SetShipShell(shellRawImage)
    self._ShipShell = shellRawImage
end
--endregion

--region Getter

function XGoldenMinerComponentShipShell:GetShipShell()
    return self._ShipShell
end

--endregion

return XGoldenMinerComponentShipShell