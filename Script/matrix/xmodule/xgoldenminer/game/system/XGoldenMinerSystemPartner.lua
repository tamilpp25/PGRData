---@class XGoldenMinerValueLimit
---@field Min number
---@field Max number

local CSXResourceManagerLoad = CS.XResourceManager.Load

---@class XGoldenMinerSystemPartner:XEntityControl
---@field _MainControl XGoldenMinerGameControl
local XGoldenMinerSystemPartner = XClass(XEntityControl, "XGoldenMinerSystemPartner")

--region Override
function XGoldenMinerSystemPartner:OnInit()
    ---资源字典
    self._ResourcePool = {}
    ---@type XGoldenMinerEntityPartner[]
    self._PartnerUidList = {}
end

---@param objDir XGoldenMinerGameInitObjDir
function XGoldenMinerSystemPartner:EnterGame(objDir)
    ---@type UnityEngine.Transform
    self._PartnerRoot = objDir.PartnerRoot
    self._RectSizeX = objDir.RectSize.x
    self._RectSizeY = objDir.RectSize.y

    local buffList = self._MainControl.SystemBuff:GetBuffUidListByType(XEnumConst.GOLDEN_MINER.BUFF_TYPE.ADD_PARTNER)
    if not XTool.IsTableEmpty(buffList) then
        for uid, _ in pairs(buffList) do
            self:_CreatePartner(self._MainControl:GetBuffEntityByUid(uid):GetBuffParams(1))
        end
    end
    
    if XTool.IsTableEmpty(self._PartnerUidList) then
        return
    end

    for _, uid in ipairs(self._PartnerUidList) do
        if self._MainControl:GetPartnerEntityByUid(uid):CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_STATUS.NONE) then
            self:_UpdatePartnerNone(self._MainControl:GetPartnerEntityByUid(uid))
        end
    end
end

function XGoldenMinerSystemPartner:OnUpdate(time)
    if XTool.IsTableEmpty(self._PartnerUidList) then
        return
    end
    for _, uid in ipairs(self._PartnerUidList) do
        local partner = self._MainControl:GetPartnerEntityByUid(uid)
        if partner:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_STATUS.ALIVE) then
            self:_UpdatePartnerAlive(partner, time)
        elseif partner:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_STATUS.BE_DIE) then
            self:_UpdatePartnerBeDie(partner, time)
        end
    end
end

function XGoldenMinerSystemPartner:OnRelease()
    for _, resource in pairs(self._ResourcePool) do
        resource:Release()
    end
    self._ResourcePool = nil
    self._PartnerUidList = nil
    self._PartnerRoot = nil
end
--endregion

--region Getter
function XGoldenMinerSystemPartner:GetPartnerUidList()
    return self._PartnerUidList
end
--endregion

--region Partner - Create
---@return XGoldenMinerEntityPartner
function XGoldenMinerSystemPartner:_CreatePartner(type)
    ---@type XGoldenMinerEntityPartner
    local partner = self._MainControl:AddEntity(self._MainControl.ENTITY_TYPE.PARTNER)
    if type == XEnumConst.GOLDEN_MINER.PARTNER_TYPE.PARTNER_SHIP then
        self:_CreateComponentPartnerShip(partner)
    elseif type == XEnumConst.GOLDEN_MINER.PARTNER_TYPE.SCAN_LINE then
        self:_CreateComponentScanLine(partner)
    end
    self._PartnerUidList[#self._PartnerUidList + 1] = partner:GetUid()
    return partner
end

---@param partner XGoldenMinerEntityPartner
---@return XGoldenMinerComponentPartnerShip
function XGoldenMinerSystemPartner:_CreateComponentPartnerShip(partner)
    ---@type XGoldenMinerComponentPartnerShip
    local partnerShip = partner:AddChildEntity(self._MainControl.COMPONENT_TYPE.PARTNER_SHIP)
    local partnerType = XEnumConst.GOLDEN_MINER.PARTNER_TYPE.PARTNER_SHIP
    local ignoreStageList = self._MainControl:GetCfgPartnerIgnoreStoneList(partnerType)
    local cfg = self._MainControl:GetCfgPartner(partnerType)
    partnerShip:InitByCfg(cfg, ignoreStageList)
    partnerShip:InitObj(self:_LoadPartnerPrefab(cfg.Prefab), self._RectSizeX, self._RectSizeY)
    return partnerShip
end

---@param partner XGoldenMinerEntityPartner
---@return XGoldenMinerComponentScanLine
function XGoldenMinerSystemPartner:_CreateComponentScanLine(partner)
    ---@type XGoldenMinerComponentScanLine
    local scanLine = partner:AddChildEntity(self._MainControl.COMPONENT_TYPE.PARTNER_SCAN)
    local partnerType = XEnumConst.GOLDEN_MINER.PARTNER_TYPE.SCAN_LINE
    local ignoreStageList = self._MainControl:GetCfgPartnerIgnoreStoneList(partnerType)
    local cfg = self._MainControl:GetCfgPartner(partnerType)
    scanLine:InitByCfg(cfg, ignoreStageList)
    scanLine:InitObj(self:_LoadPartnerPrefab(cfg.Prefab), self._RectSizeX, self._RectSizeY)
    scanLine:InitHitFunc(function(collider)
        return self:_OnScanLineHit(scanLine, collider)
    end)
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PARTNER_SCAN_INIT)
    return scanLine
end

---@return UnityEngine.Transform
function XGoldenMinerSystemPartner:_LoadPartnerPrefab(path)
    if string.IsNilOrEmpty(path) or not self._PartnerRoot then
        return
    end
    local resource = self._ResourcePool[path]
    if not resource then
        resource = CSXResourceManagerLoad(path)
        self._ResourcePool[path] = resource
    end
    if resource == nil or not resource.Asset then
        XLog.Error(string.format("XGoldenMinerSystemPartner:_LoadPartnerPrefab加载资源，路径：%s", path))
        return
    end
    local obj = XUiHelper.Instantiate(resource.Asset, self._PartnerRoot)
    return obj
end
--endregion

--region Partner - Update
---@param partner XGoldenMinerEntityPartner
function XGoldenMinerSystemPartner:_UpdatePartnerNone(partner)
    partner:SetStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_STATUS.ALIVE)
    self:_SetPartnerShipAlive(partner:GetComponentPartnerShip())
end

---@param partner XGoldenMinerEntityPartner
function XGoldenMinerSystemPartner:_UpdatePartnerAlive(partner, time)
    self:_UpdatePartnerShip(partner:GetComponentPartnerShip(), time)
    self:_UpdateScanLine(partner:GetComponentScanLine(), time)
end

---@param partner XGoldenMinerEntityPartner
function XGoldenMinerSystemPartner:_UpdatePartnerBeDie(partner, time)
    partner:SetStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_STATUS.DIE)
end
--endregion

--region PartnerShip - Update
---@param partnerShip XGoldenMinerComponentPartnerShip
function XGoldenMinerSystemPartner:_UpdatePartnerShip(partnerShip, time)
    if not partnerShip then
        return
    end
    if partnerShip:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_SHIP_STATUS.IDLE) then
        self:_UpdatePartnerShipIdle(partnerShip, time)
    elseif partnerShip:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_SHIP_STATUS.AIM) then
        self:_UpdatePartnerShipAim(partnerShip, time)
    elseif partnerShip:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_SHIP_STATUS.MOVE) then
        self:_UpdatePartnerShipMove(partnerShip, time)
    elseif partnerShip:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_SHIP_STATUS.GRAB) then
        self:_UpdatePartnerShipGrab(partnerShip, time)
    elseif partnerShip:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_SHIP_STATUS.BACK) then
        self:_UpdatePartnerShipBack(partnerShip, time)
    end
end

---@param partnerShip XGoldenMinerComponentPartnerShip
function XGoldenMinerSystemPartner:_SetPartnerShipAlive(partnerShip)
    if not partnerShip then
        return
    end
    partnerShip:ChangeIdle()
end

---@param partnerShip XGoldenMinerComponentPartnerShip
function XGoldenMinerSystemPartner:_UpdatePartnerShipIdle(partnerShip, time)
    partnerShip:DownIdleCd(time)
    if partnerShip:CheckBeChangeAim() then
        self:_CheckAndResetShipTarget(partnerShip)
    end
end

---@param partnerShip XGoldenMinerComponentPartnerShip
function XGoldenMinerSystemPartner:_UpdatePartnerShipAim(partnerShip, time)
    if self:_CheckAndResetShipTarget(partnerShip) then
        return
    end
    partnerShip:DownAimCd(time)
    if partnerShip:CheckBeChangeMove() then
        partnerShip:ChangeMove()
    end
end

---@param partnerShip XGoldenMinerComponentPartnerShip
function XGoldenMinerSystemPartner:_UpdatePartnerShipMove(partnerShip, time)
    if self:_CheckAndResetShipTarget(partnerShip) then
        return
    end
    partnerShip:UpdateMovePos(time)
    partnerShip:UpdateAim()
    if partnerShip:CheckMoveStop() then
        partnerShip:ChangeGrab()
    end
end

---@param partnerShip XGoldenMinerComponentPartnerShip
function XGoldenMinerSystemPartner:_UpdatePartnerShipGrab(partnerShip, time)
    partnerShip:GrabbingTarget()
    partnerShip:DownGrabTime(time)
    if partnerShip:CheckBeChangeBack() then
        self._MainControl:AddMapScore(self._MainControl:HandleStoneEntityToGrabbed(partnerShip:GetCurAimTarget(), true))
        partnerShip:GrabTarget()
        partnerShip:ChangeBack()
    end
end

---@param partnerShip XGoldenMinerComponentPartnerShip
function XGoldenMinerSystemPartner:_UpdatePartnerShipBack(partnerShip, time)
    partnerShip:UpdateMovePos(time)
    if partnerShip:CheckMoveStop() then
        partnerShip:ChangeIdle()
    end
end

---@param partnerShip XGoldenMinerComponentPartnerShip
function XGoldenMinerSystemPartner:_CheckAndResetShipTarget(partnerShip)
    if partnerShip:CheckCurTargetIsAlive() then
        return false
    end
    partnerShip:UpdateIdleCd(0)
    if partnerShip:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_SHIP_STATUS.MOVE) then
        partnerShip:ChangeBack(true)
    else
        local stoneEntity = self._MainControl.SystemMap:GetNearestStoneByTypeDir(
                partnerShip:GetIgnoreTypeDir(),
                partnerShip:GetRangeX(),
                partnerShip:GetRangeY(),
                partnerShip:GetSelfStartPosition())
        partnerShip:ChangeAim(stoneEntity)
    end
    return true
end
--endregion

--region ScanLine - Update
---@param scanLine XGoldenMinerComponentScanLine
function XGoldenMinerSystemPartner:_UpdateScanLine(scanLine, time)
    if not scanLine then
        return
    end
    scanLine:UpdateScanLine(time)
end

---@param scanLine XGoldenMinerComponentScanLine
---@param collider UnityEngine.BoxCollider2D
---@return boolean
function XGoldenMinerSystemPartner:_OnScanLineHit(scanLine, collider)
    ---@type XGoldenMinerEntityStone
    local stoneEntity = self._MainControl.SystemMap:GetEntityByCollider(collider)
    if not stoneEntity or not stoneEntity:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.ALIVE) then
        return false
    end
    if scanLine:CheckIsIgnoreType(stoneEntity.Data:GetType()) then
        return false
    end
    stoneEntity:SetStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED)
    self._MainControl:AddMapScore(self._MainControl:HandleStoneEntityToGrabbed(stoneEntity, true))
    XMVCA.XGoldenMiner:DebugWarning("扫描线扫描:", stoneEntity:__DebugLog())
    return true
end
--endregion

return XGoldenMinerSystemPartner