---@class XGoldenMinerComponentPartnerShip:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityPartner
---@field Aim UnityEngine.RectTransform
---@field TriggerEffect UnityEngine.Transform
local XGoldenMinerComponentPartnerShip = XClass(XEntity, "XGoldenMinerComponentPartnerShip")

--region Override
function XGoldenMinerComponentPartnerShip:OnInit()
    self._Status = XEnumConst.GOLDEN_MINER.GAME_PARTNER_SHIP_STATUS.NONE
    ---@type UnityEngine.Transform
    self.Transform = nil
    
    -- Static Value
    self._Type = 0
    self._IgnoreStoneTypeDir = {}
    ---@type UnityEngine.Vector3
    self._SelfStartPosition = nil
    ---@type XLuaVector2
    self._StartLocalPos = XLuaVector2.New()
    self._TargetPosYOffset = 0
    ---@type string
    self._TriggerEffectUrl = nil
    self._MoveSpeed = 0
    ---@type XGoldenMinerValueLimit
    self._MoveXRange = {
        Min = 0,
        Max = 0,
    }
    ---@type XGoldenMinerValueLimit
    self._MoveYRange = {
        Min = 0,
        Max = 0,
    }
    self._IdleCD = 0
    self._AimCD = 0
    self._GrabTime = 0
    self._GrabFinalScalePercent = 0
    ---@type string
    self._AimEffectUrl = nil
    
    -- Dynamic Value
    self._CurIdleCd = 0
    self._CurAimCD = 0
    self._CurMoveTime = 0
    self._CurAimPassTime = 0
    self._CurGrabTime = 0
    ---@type UnityEngine.Vector2
    self._CurMoveDirection = nil
    ---@type XLuaVector2
    self._CurMoveShipPos = XLuaVector2.New()
    ---@type UnityEngine.Vector2
    self._CurMoveTargetPos = nil
    ---@type XGoldenMinerEntityStone
    self._CurTarget = nil
    self._CurGrabDeltaScale = 0
    ---@type XLuaVector3
    self._CacheVector3 = XLuaVector3.New()
end

function XGoldenMinerComponentPartnerShip:OnRelease()
    self.Transform = nil
    self.Aim = nil
    self.TriggerEffect = nil
    -- Static Value
    self._Type = nil
    self._SelfStartPosition = nil
    self._IgnoreStoneTypeDir = nil
    self._StartLocalPos = nil
    self._TargetPosYOffset = nil
    self._TriggerEffectUrl = nil
    self._MoveSpeed = nil
    self._MoveXRange = nil
    self._MoveYRange = nil
    self._IdleCD = nil
    self._AimCD = nil
    self._GrabTime = nil
    self._GrabFinalScalePercent = nil
    self._AimEffectUrl = nil
    -- Dynamic Value
    self._CurIdleCd = nil
    self._CurAimCD = nil
    self._CurMoveTime = nil
    self._CurAimPassTime = nil
    self._CurGrabTime = nil
    self._CurMoveDirection = nil
    self._CurMoveTargetPos = nil
    self._CurTarget = nil
    self._CurGrabDeltaScale = nil
    self._CacheVector3 = nil
end
--endregion

--region Getter
function XGoldenMinerComponentPartnerShip:GetIgnoreTypeDir()
    return self._IgnoreStoneTypeDir
end

function XGoldenMinerComponentPartnerShip:GetCurAimTarget()
    return self._CurTarget
end

function XGoldenMinerComponentPartnerShip:GetRangeX()
    return self._MoveXRange
end

function XGoldenMinerComponentPartnerShip:GetRangeY()
    return self._MoveYRange
end

function XGoldenMinerComponentPartnerShip:GetSelfStartPosition()
    return self._SelfStartPosition
end
--endregion

--region Setter
---@param cfg XTableGoldenMinerPartner
function XGoldenMinerComponentPartnerShip:InitByCfg(cfg, IgnoreStoneTypeList)
    for _, v in ipairs(IgnoreStoneTypeList) do
        self._IgnoreStoneTypeDir[tonumber(v)] = true
    end
    self._Type = cfg.Type
    self._StartLocalPos:Update(cfg.IntParam[1] / 1000000, cfg.IntParam[2] / 1000000) 
    self._TargetPosYOffset = cfg.IntParam[3]
    self._TriggerEffectUrl = cfg.TriggerEffect
    self._MoveSpeed = cfg.MoveSpeed
    self._MoveXRange.Min = cfg.RangeXMin / 1000000
    self._MoveXRange.Max = cfg.RangeXMax / 1000000
    self._MoveYRange.Min = cfg.RangeYMin / 1000000
    self._MoveYRange.Max = cfg.RangeYMax / 1000000
    self._GrabFinalScalePercent = cfg.FloatParam[1]
    self._IdleCD = cfg.FloatParam[2]
    self._AimCD = cfg.FloatParam[3]
    self._AimShinyCD = cfg.FloatParam[4] or 0.1
    self._GrabTime = cfg.FloatParam[5] or 0.5
    self._AimEffectUrl = cfg.StringParam[1]

    self:UpdateIdleCd(self._IdleCD)
    self:_UpdateAimCd(self._AimCD)
end

---@param obj UnityEngine.GameObject
function XGoldenMinerComponentPartnerShip:InitObj(obj, rectSizeX, rectSizeY)
    self.Transform = obj.transform
    XTool.InitUiObject(self)
    self._StartLocalPos:Update(self._StartLocalPos.x * rectSizeX, self._StartLocalPos.y * rectSizeY)
    self._MoveXRange.Min = self._MoveXRange.Min * rectSizeX
    self._MoveXRange.Max = self._MoveXRange.Max * rectSizeX
    self._MoveYRange.Min = self._MoveYRange.Min * rectSizeY
    self._MoveYRange.Max = self._MoveYRange.Max * rectSizeY
    self.Transform.anchoredPosition = Vector2(self._StartLocalPos.x, self._StartLocalPos.y)
    self._SelfStartPosition = self.Transform.position
    if not string.IsNilOrEmpty(self._TriggerEffectUrl) then
        self.TriggerEffect:LoadPrefab(self._TriggerEffectUrl)
    end
    if not string.IsNilOrEmpty(self._AimEffectUrl) then
        self.Aim:LoadPrefab(self._AimEffectUrl)
    end
    self:_CloseAim()
    self:_CloseTriggerEffect()
end

---@param status number XEnumConst.GOLDEN_MINER.GAME_PARTNER_SHIP_STATUS
function XGoldenMinerComponentPartnerShip:_SetStatus(status)
    self._Status = status
end

---@param targetStoneEntity XGoldenMinerEntityStone
function XGoldenMinerComponentPartnerShip:_SetAimTarget(targetStoneEntity)
    XMVCA.XGoldenMiner:DebugWarning("当前小飞碟目标：", targetStoneEntity:__DebugLog())
    self._CurTarget = targetStoneEntity
end
--endregion

--region Check
function XGoldenMinerComponentPartnerShip:CheckStatus(status)
    return self._Status == status
end

function XGoldenMinerComponentPartnerShip:CheckBeChangeAim()
    return self._CurIdleCd <= 0
end

function XGoldenMinerComponentPartnerShip:CheckBeChangeMove()
    return self._CurAimCD <= 0
end

function XGoldenMinerComponentPartnerShip:CheckBeChangeBack()
    return self._CurGrabTime <= 0
end

function XGoldenMinerComponentPartnerShip:CheckMoveStop()
    return self._CurMoveTime <= 0
end

function XGoldenMinerComponentPartnerShip:CheckCurTargetIsAlive()
    if not self._CurTarget then
        self:_CloseAim()
        return false
    end
    if self._CurTarget:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.SHIP_AIM) then
        return true
    else
        XMVCA.XGoldenMiner:DebugWarning("当前小飞碟目标丢失！重新返回以寻找目标！")
        self:_CloseAim()
        return false
    end
end
--endregion

--region Control - Status
function XGoldenMinerComponentPartnerShip:ChangeIdle()
    self:_SetStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_SHIP_STATUS.IDLE)
end

---@param stoneEntity XGoldenMinerEntityStone
function XGoldenMinerComponentPartnerShip:ChangeAim(stoneEntity)
    self:_UpdateAimCd(self._AimCD)
    self:_SetStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_SHIP_STATUS.AIM)
    if not stoneEntity then
        return
    end
    self:_SetAimTarget(stoneEntity)
    self:_OpenAnim()
    self:UpdateAim()
    stoneEntity:SetStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.SHIP_AIM)
end

function XGoldenMinerComponentPartnerShip:ChangeMove()
    local targetEntityPosition = self._CurTarget:GetTransform().anchoredPosition
    local shipPosition = self.Transform.anchoredPosition
    self._CurMoveShipPos:Update(shipPosition.x, shipPosition.y)
    self._CurMoveTargetPos = Vector2(targetEntityPosition.x, targetEntityPosition.y + self._TargetPosYOffset)
    self._CurMoveDirection = (self._CurMoveTargetPos - shipPosition).normalized
    self._CurMoveTime = (self._CurMoveTargetPos - shipPosition).magnitude / self._MoveSpeed
    self:_SetStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_SHIP_STATUS.MOVE)
end

function XGoldenMinerComponentPartnerShip:ChangeGrab()
    self:_CloseAim()
    self:_OpenTriggerEffect()
    self:_UpdateGrabTime(self._GrabTime)
    self:_SetStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_SHIP_STATUS.GRAB)
    if not self._CurTarget then
        return
    end
    local targetScale = self._CurTarget:GetTransform().localScale.x
    self._CurGrabDeltaScale = targetScale - self._GrabFinalScalePercent * targetScale
    self._CurTarget:SetStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.SHIP_CATCHING)
end

function XGoldenMinerComponentPartnerShip:ChangeBack(isClearIdleCd)
    if isClearIdleCd then
        self:UpdateIdleCd(0)
    else
        self:UpdateIdleCd(self._IdleCD)
    end
    self:_CloseAim()
    self:_CloseTriggerEffect()
    self._CurMoveTargetPos = Vector2(self._StartLocalPos.x, self._StartLocalPos.y)
    self._CurMoveDirection = (self._CurMoveTargetPos - self._CurMoveShipPos).normalized
    self._CurMoveTime = (self._CurMoveTargetPos - self._CurMoveShipPos).magnitude / self._MoveSpeed
    
    self:_SetStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_SHIP_STATUS.BACK)
end
--endregion

--region Control - Idle
function XGoldenMinerComponentPartnerShip:DownIdleCd(deltaTime)
    if self._CurIdleCd <= 0 then
        return
    end
    self._CurIdleCd = self._CurIdleCd - deltaTime
end

function XGoldenMinerComponentPartnerShip:UpdateIdleCd(time)
    self._CurIdleCd = time
end
--endregion

--region Control - Aim
function XGoldenMinerComponentPartnerShip:_OpenAnim()
    if not self._CurTarget then
        return
    end
    self._CurAimPassTime = 0
    self.Aim.gameObject:SetActiveEx(true)
end

function XGoldenMinerComponentPartnerShip:_CloseAim()
    self._CurAimPassTime = 0
    self.Aim.gameObject:SetActiveEx(false)
end

function XGoldenMinerComponentPartnerShip:UpdateAim()
    if not self._CurTarget then
        return
    end
    self.Aim.position = self._CurTarget:GetTransform().position
    self.Aim.sizeDelta = self._CurTarget:GetTransform().sizeDelta * math.abs(self._CurTarget:GetTransform().localScale.x)

    if self.AimOff then
        local a = math.floor(self._CurAimPassTime / self._AimShinyCD)
        if a % 2 == 0 then
            self.AimOff.gameObject:SetActiveEx(false)
            self.AimOn.gameObject:SetActiveEx(true)
        else
            self.AimOff.gameObject:SetActiveEx(true)
            self.AimOn.gameObject:SetActiveEx(false)
        end
    end
end

function XGoldenMinerComponentPartnerShip:DownAimCd(deltaTime)
    if self._CurAimCD <= 0 then
        return
    end
    self._CurAimCD = self._CurAimCD - deltaTime
    self._CurAimPassTime = self._CurAimPassTime + deltaTime
end

function XGoldenMinerComponentPartnerShip:_UpdateAimCd(time)
    self._CurAimCD = time
end
--endregion

--region Control - Move
function XGoldenMinerComponentPartnerShip:UpdateMovePos(deltaTime)
    if self._CurMoveTime <= 0 then
        return
    end
    self._CurMoveShipPos:AddVector(self._CurMoveDirection * deltaTime * self._MoveSpeed)
    self.Transform.anchoredPosition = self._CurMoveShipPos
    self._CurMoveTime = self._CurMoveTime - deltaTime
    self._CurAimPassTime = self._CurAimPassTime + deltaTime
end
--endregion

--region Control - Grab
function XGoldenMinerComponentPartnerShip:DownGrabTime(deltaTime)
    if self._CurGrabTime <= 0 then
        return
    end
    local deltaScale = (self._CurGrabDeltaScale / self._GrabTime) * deltaTime
    self._CacheVector3:Update(deltaScale, math.abs(deltaScale), math.abs(deltaScale))
    
    local targetCurScale = self._CurTarget:GetTransform().localScale - self._CacheVector3
    local deltaPos = (self._TargetPosYOffset / self._GrabTime / 2) * deltaTime
    local targetCurPos = self._CurTarget:GetTransform().anchoredPosition + Vector2(0, deltaPos)
    self._CurGrabTime = self._CurGrabTime - deltaTime
    self._CurTarget:GetTransform().localScale = targetCurScale
    self._CurTarget:GetTransform().anchoredPosition = targetCurPos
end

function XGoldenMinerComponentPartnerShip:GrabbingTarget()
    if not self._CurTarget then
        return
    end
    local status = XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.SHIP_CATCHING
    if self._CurTarget:CheckStatus(status) then
        return
    end
    self._CurTarget:SetStatus(status)
end

function XGoldenMinerComponentPartnerShip:GrabTarget()
    if not self._CurTarget then
        return
    end
    self._CurTarget:SetStatus(XEnumConst.GOLDEN_MINER.GAME_STONE_STATUS.GRABBED)
end

function XGoldenMinerComponentPartnerShip:_OpenTriggerEffect()
    if not self._CurTarget then
        return
    end
    self.TriggerEffect.position = self._CurTarget:GetTransform().position
    self.TriggerEffect.gameObject:SetActiveEx(true)
    self._OwnControl:PlayPartnerTriggerSound(self._Type)
end

function XGoldenMinerComponentPartnerShip:_CloseTriggerEffect()
    self.TriggerEffect.gameObject:SetActiveEx(false)
end

function XGoldenMinerComponentPartnerShip:_UpdateGrabTime(time)
    self._CurGrabTime = time
end
--endregion

return XGoldenMinerComponentPartnerShip