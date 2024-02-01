---@class XGoldenMinerSystemShip:XEntityControl
---@field _MainControl XGoldenMinerGameControl
local XGoldenMinerSystemShip = XClass(XEntityControl, "XGoldenMinerSystemShip")

--region Override
---@param objDir XGoldenMinerGameInitObjDir
function XGoldenMinerSystemShip:EnterGame(objDir)
    self._ShipRoot = objDir.HumanRoot
    self._RectSizeX = objDir.RectSize.x

    self._ShipEntityUid = self:_CreateShip()
end

---一般由Game Update
function XGoldenMinerSystemShip:OnUpdate(time)
    if not self:GetShip() then
        return
    end

    self:_UpdateShipMove(self:GetShip():GetComponentMove(), time)
end

function XGoldenMinerSystemShip:OnRelease()
    self._ShipRoot = nil
    self._RectSizeX = nil
    self._ShipEntityUid = nil
end
--endregion

--region Getter
---@return XGoldenMinerEntityShip
function XGoldenMinerSystemShip:GetShip()
    if not XTool.IsNumberValid(self._ShipEntityUid) then
        return
    end
    return self._MainControl:GetEntityWithUid(self._ShipEntityUid)
end
--endregion

--region Check
function XGoldenMinerSystemShip:CheckShipIsMoving()
    if not self:GetShip() then
        return
    end
    if not self:GetShip():GetComponentMove() then
        return
    end
    return self:GetShip():GetComponentMove():IsMoving()
end
--endregion

--region Ship - Create
---@return number ShipEntityUid
function XGoldenMinerSystemShip:_CreateShip()
    local ship = self._MainControl:AddEntity(self._MainControl.ENTITY_TYPE.SHIP)
    self:_CreateShipComponentMove(ship)
    self:_CreateShipComponentShell(ship)
    return ship:GetUid()
end

---@param entity XEntity
---@return XGoldenMinerComponentShipMove
function XGoldenMinerSystemShip:_CreateShipComponentMove(entity)
    ---@type XGoldenMinerComponentShipMove
    local shipMove = entity:AddChildEntity(self._MainControl.COMPONENT_TYPE.SHIP_MOVE)
    shipMove:SetMoveRoot(self._ShipRoot)
    shipMove:SetMoveBaseSpeed(self._MainControl:GetClientHumanMoveSpeed())
    shipMove:SetMoveRange(self._MainControl:GetClientRoleMoveRangePercent() * self._RectSizeX)
    return shipMove
end

---@param entity XEntity
---@return XGoldenMinerComponentShipShell
function XGoldenMinerSystemShip:_CreateShipComponentShell(entity)
    local shell = XUiHelper.TryGetComponent(self._ShipRoot, "Humen", "RawImage")
    if not shell then
        return nil
    end

    ---@type XGoldenMinerComponentShipShell
    local shipShell = entity:AddChildEntity(self._MainControl.COMPONENT_TYPE.SHIP_SHELL)
    
    local upgradeList = self._MainControl._MainControl:GetMainDb():GetAllUpgradeStrengthenList()
    local totalNum = 0
    local shipKey = XEnumConst.GOLDEN_MINER.SHIP_APPEARANCE_ICON_KEY.DEFAULT_SHIP
    -- 飞船外观
    local imageUrl
    for _, strengthenDb in ipairs(upgradeList) do
        if not string.IsNilOrEmpty(strengthenDb:GetLvMaxShipKey()) and strengthenDb:IsMaxLv() then
            totalNum = totalNum + 1
            shipKey = strengthenDb:GetLvMaxShipKey()
        end
    end
    if totalNum >= self._MainControl:GetClientFinalShipMaxCount() then
        shipKey = XEnumConst.GOLDEN_MINER.SHIP_APPEARANCE_ICON_KEY.FINAL_SHIP
    end
    imageUrl = self._MainControl:GetClientShipImagePath(shipKey)
    -- 飞船大小
    local shipSize
    if shipKey == XEnumConst.GOLDEN_MINER.SHIP_APPEARANCE_ICON_KEY.MAX_SPEED_SHIP then
        shipSize = self._MainControl:GetClientShipSize(XEnumConst.GOLDEN_MINER.SHIP_APPEARANCE_SIZE_KEY.MAX_SPEED_SHIP_SIZE)
    elseif shipKey == XEnumConst.GOLDEN_MINER.SHIP_APPEARANCE_ICON_KEY.MAX_CLAMP_SHIP then
        shipSize = self._MainControl:GetClientShipSize(XEnumConst.GOLDEN_MINER.SHIP_APPEARANCE_SIZE_KEY.MAX_CLAMP_SHIP_SIZE)
    elseif shipKey == XEnumConst.GOLDEN_MINER.SHIP_APPEARANCE_ICON_KEY.FINAL_SHIP then
        shipSize = self._MainControl:GetClientShipSize(XEnumConst.GOLDEN_MINER.SHIP_APPEARANCE_SIZE_KEY.FINAL_SHIP_SIZE)
    else
        shipSize = self._MainControl:GetClientShipSize(XEnumConst.GOLDEN_MINER.SHIP_APPEARANCE_SIZE_KEY.DEFAULT_SHIP_SIZE)
    end
    
    shipShell:InitShell(shell, imageUrl, shipSize)
    return shipShell
end
--endregion

--region ShipMove - Update
---@param shipMove XGoldenMinerComponentShipMove
function XGoldenMinerSystemShip:_UpdateShipMove(shipMove, time)
    if not shipMove then
        return
    end
    shipMove:UpdateShipMove(time)
end
--endregion

return XGoldenMinerSystemShip