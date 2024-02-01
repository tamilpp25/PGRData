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
function XGoldenMinerComponentShipShell:InitShell(shell, url, rectSize)
    self._ShipShell = shell
    self._ShipShell.transform.rect.size = rectSize
    if not string.IsNilOrEmpty(url) then
        self._ShipShell:SetRawImage(url)
    end
end
--endregion

return XGoldenMinerComponentShipShell