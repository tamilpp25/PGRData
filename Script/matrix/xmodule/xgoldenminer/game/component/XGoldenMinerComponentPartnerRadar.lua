---@class XGoldenMinerComponentPartnerRadar:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityPartner
---@field TriggerEffect UnityEngine.Transform
local XGoldenMinerComponentPartnerRadar = XClass(XEntity, "XGoldenMinerComponentPartnerRadar")

--region Override
function XGoldenMinerComponentPartnerRadar:OnInit()
    self._Status = XEnumConst.GOLDEN_MINER.GAME_PARTNER_RADAR_STATUS.NONE
    ---@type UnityEngine.Transform
    self.Transform = nil
    -- Static Value
    self._Type = 0
    ---@type UnityEngine.Vector3
    self._SelfStartPosition = nil
    ---@type XLuaVector2
    self._StartLocalPos = XLuaVector2.New()
    ---@type string
    self._TriggerEffectUrl = nil
    self._IdleCD = 0
    self._ScanCD = 0
    self._RandomStoneIds = nil

    -- Dynamic Value
    self._CurIdleCD = 0
    self._CurScanCD = 0
    self._TriggerCallBack = nil
end

function XGoldenMinerComponentPartnerRadar:OnRelease()
    self.Transform = nil
    --self.Aim = nil
    self.TriggerEffect = nil
    -- Static Value
    self._Type = nil
    self._SelfStartPosition = nil
    self._StartLocalPos = nil
    self._TriggerEffectUrl = nil
    self._IdleCD = 0
    self._ScanCD = 0
    self._RandomStoneIds = nil

    -- Dynamic Value
    self._CurIdleCD = 0
    self._CurScanCD = 0
    self._TriggerCallBack = nil
end
--endregion

--region Getter
function XGoldenMinerComponentPartnerRadar:GetSelfStartPosition()
    return self._SelfStartPosition
end

function XGoldenMinerComponentPartnerRadar:GetOneRoundTime()
    return self._ScanCD + self._IdleCD
end

-- 获取指定数量的随机抓取物列表（用来计算剩余时间的分数）
function XGoldenMinerComponentPartnerRadar:GetRandomStoneIdList(times)
    local stoneIdList = {}

    for _ = 1, times do
        table.insert(stoneIdList, self._RandomStoneIds[math.random(1, #self._RandomStoneIds)])
    end

    return stoneIdList
end
--endregion

--region Setter
---@param cfg XTableGoldenMinerPartner
function XGoldenMinerComponentPartnerRadar:InitByCfg(cfg)
    self._Type = cfg.Type
    self._StartLocalPos:Update(cfg.IntParam[1] / 1000000, cfg.IntParam[2] / 1000000)
    self._TriggerEffectUrl = cfg.TriggerEffect
    self._IdleCD = cfg.FloatParam[1]
    self._ScanCD = cfg.FloatParam[2]
    --self._IdleCD = 0.01
    --self._ScanCD = 0.01

    self._RandomStoneIds = {}
    for i = 3, #cfg.IntParam do
        table.insert(self._RandomStoneIds, cfg.IntParam[i])
    end

    self:UpdateIdleCd(self._IdleCD)
    self:UpdateScanCd(self._ScanCD)
end

---@param obj UnityEngine.GameObject
function XGoldenMinerComponentPartnerRadar:InitObj(obj, rectSizeX, rectSizeY)
    self.Transform = obj.transform
    XTool.InitUiObject(self)
    self._StartLocalPos:Update(self._StartLocalPos.x * rectSizeX, self._StartLocalPos.y * rectSizeY)
    self.Transform.anchoredPosition = Vector2(self._StartLocalPos.x, self._StartLocalPos.y)
    self._SelfStartPosition = self.Transform.position
    if not string.IsNilOrEmpty(self._TriggerEffectUrl) then
        self.TriggerEffect:LoadPrefab(self._TriggerEffectUrl)
    end
end

---@param status number XEnumConst.GOLDEN_MINER.GAME_PARTNER_RADAR_STATUS
function XGoldenMinerComponentPartnerRadar:_SetStatus(status)
    self._Status = status
end

---@param cb function
function XGoldenMinerComponentPartnerRadar:SetTriggerCallBack(cb)
    self._TriggerCallBack = cb
end
--endregion

--region Check
function XGoldenMinerComponentPartnerRadar:CheckStatus(status)
    return self._Status == status
end
--endregion

--region Control - Status
function XGoldenMinerComponentPartnerRadar:ChangeIdle()
    self:UpdateIdleCd(self._IdleCD)
    self.IdleAnimation.gameObject:SetActiveEx(true)
    self.ScanAnimation.gameObject:SetActiveEx(false)
    self:_SetStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_RADAR_STATUS.IDLE)
end

function XGoldenMinerComponentPartnerRadar:_ChangeScan()
    self:UpdateScanCd(self._ScanCD)
    self.IdleAnimation.gameObject:SetActiveEx(false)
    self.ScanAnimation.gameObject:SetActiveEx(true)
    self:_SetStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_RADAR_STATUS.SCAN)
end
--endregion

--region Control

function XGoldenMinerComponentPartnerRadar:Update(deltaTime)
    if self:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_RADAR_STATUS.IDLE) then
        local curCD = self._CurIdleCD - deltaTime
        if curCD <= 0 then
            self:_ChangeScan()
        else
            self._CurIdleCD = curCD
        end
    elseif self:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_RADAR_STATUS.SCAN) then
        local curCD = self._CurScanCD - deltaTime
        if curCD <= 0 then
            if self._TriggerCallBack then
                self._TriggerCallBack(self._RandomStoneIds[math.random(1, #self._RandomStoneIds)])
            end
            self:ChangeIdle()
        else
            self._CurScanCD = curCD
        end
    end
end

function XGoldenMinerComponentPartnerRadar:UpdateIdleCd(time)
    self._CurIdleCD = time
end

function XGoldenMinerComponentPartnerRadar:UpdateScanCd(time)
    self._CurScanCD = time
end

function XGoldenMinerComponentPartnerRadar:GetCurRoundSpendTime()
    if self:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_RADAR_STATUS.IDLE) then
        return self._IdleCD - self._CurIdleCD
    elseif self:CheckStatus(XEnumConst.GOLDEN_MINER.GAME_PARTNER_RADAR_STATUS.SCAN) then
        return self._IdleCD + self._ScanCD - self._CurScanCD
    end
end

--endregion

return XGoldenMinerComponentPartnerRadar