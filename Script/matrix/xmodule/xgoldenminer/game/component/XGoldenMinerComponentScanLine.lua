---@class XGoldenMinerScanLine
---@field Status number XEnumConst.GOLDEN_MINER.GAME_SCAN_LINE_STATUS
---@field Transform UnityEngine.RectTransform
---@field TriggerEffect UnityEngine.Transform
---@field TriggerEffectDir UnityEngine.Transform[]
---@field TriggerEffectPosDir UnityEngine.Vector3[]
---@field ScanLineCollider UnityEngine.BoxCollider2D
---@field GoInputHandler XGoInputHandler
---@field CurGrabCount number 该扫描线已扫取个数

---@class XGoldenMinerComponentScanLine:XEntity
---@field _OwnControl XGoldenMinerGameControl
---@field _ParentEntity XGoldenMinerEntityPartner
---@field ScanLine UnityEngine.Transform
local XGoldenMinerComponentScanLine = XClass(XEntity, "XGoldenMinerComponentScanLine")

--region Override
function XGoldenMinerComponentScanLine:OnInit()
    ---@type UnityEngine.Transform
    self.Transform = nil
    
    -- Static Value
    self._Type = 0
    ---@type number[]
    self._IgnoreStoneTypeDir = {}
    --- 开始扫描进度
    self._TargetProgress = 0
    --- 扫描目标个数
    self._TargetCount = 0
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
    ---@type function
    self._OnHitFunc = nil

    -- Dynamic Value
    self._CurProgress = 0
    ---@type XGoldenMinerScanLine[]
    self._CurScanLineList = {}
    ---@type XLuaVector3
    self._CurDeltaPos = XLuaVector3.New()
    
    XEventManager.AddEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_GRABBED_HANDLE, self._AddCurProcess, self)
end

function XGoldenMinerComponentScanLine:OnRelease()
    self.Transform = nil
    -- Static Value
    self._Type = nil
    self._IgnoreStoneTypeDir = nil
    self._TargetProgress = nil
    self._TargetCount = nil
    self._TriggerEffectUrl = nil
    self._MoveSpeed = nil
    self._MoveXRange = nil
    self._MoveYRange = nil
    self._OnHitFunc = nil

    -- Dynamic Value
    self._CurProgress = nil
    for _, scanLine in ipairs(self._CurScanLineList) do
        scanLine.Transform = nil
        scanLine.ScanLineCollider = nil
        scanLine.GoInputHandler:RemoveAllListeners()
        scanLine.GoInputHandler = nil
        for i, v in ipairs(scanLine.TriggerEffectDir) do
            scanLine.TriggerEffectDir[i] = nil
        end
        scanLine.TriggerEffectDir = nil
        scanLine.TriggerEffectPosDir = nil
        scanLine.TriggerEffect = nil
    end
    self._CurScanLineList = nil
    XEventManager.RemoveEventListener(XEventId.EVENT_GOLDEN_MINER_GAME_HOOK_GRABBED_HANDLE, self._AddCurProcess, self)
end
--endregion

--region Setter
---@param cfg XTableGoldenMinerPartner
function XGoldenMinerComponentScanLine:InitByCfg(cfg, IgnoreStoneTypeList)
    for _, v in ipairs(IgnoreStoneTypeList) do
        self._IgnoreStoneTypeDir[tonumber(v)] = true
    end
    self._Type = cfg.Type
    self._TriggerEffectUrl = cfg.TriggerEffect
    self._MoveSpeed = cfg.MoveSpeed
    self._MoveXRange.Min = cfg.RangeXMin / 1000000
    self._MoveXRange.Max = cfg.RangeXMax / 1000000
    self._MoveYRange.Min = cfg.RangeYMin / 1000000
    self._MoveYRange.Max = cfg.RangeYMax / 1000000
    self._TargetProgress = cfg.IntParam[1]
    self._TargetCount = cfg.IntParam[2]
end

---@param obj UnityEngine.GameObject
function XGoldenMinerComponentScanLine:InitObj(obj, rectSizeX, rectSizeY)
    self.Transform = obj.transform
    XTool.InitUiObject(self)
    self._MoveXRange.Min = self._MoveXRange.Min * rectSizeX
    self._MoveXRange.Max = self._MoveXRange.Max * rectSizeX
    self._MoveYRange.Min = self._MoveYRange.Min * rectSizeY
    self._MoveYRange.Max = self._MoveYRange.Max * rectSizeY
    self.ScanLine.gameObject:SetActiveEx(false)
end

function XGoldenMinerComponentScanLine:InitHitFunc(func)
    self._OnHitFunc = func
end

function XGoldenMinerComponentScanLine:_AddCurProcess(value)
    if XTool.IsNumberValid(value) then
        self._CurProgress = self._CurProgress + 1
    end
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PARTNER_SCAN_PRECESS, self._CurProgress, self._TargetProgress)
end

function XGoldenMinerComponentScanLine:_SetCurProcess(value)
    self._CurProgress = value
    XEventManager.DispatchEvent(XEventId.EVENT_GOLDEN_MINER_GAME_PARTNER_SCAN_PRECESS, self._CurProgress, self._TargetProgress)
end
--endregion

--region Check
function XGoldenMinerComponentScanLine:CheckIsIgnoreType(type)
    return self._IgnoreStoneTypeDir[type]
end

---@param scanLine XGoldenMinerScanLine
---@param status number XEnumConst.GOLDEN_MINER.GAME_SCAN_LINE_STATUS
function XGoldenMinerComponentScanLine:_CheckStatus(scanLine, status)
    return scanLine.Status == status
end

---@param scanLine XGoldenMinerScanLine
function XGoldenMinerComponentScanLine:_CheckScanLineBeDie(scanLine)
    return scanLine.Transform.anchoredPosition.y >= self._MoveYRange.Max
end

---@param scanLine XGoldenMinerScanLine
function XGoldenMinerComponentScanLine:_CheckScanLineCanAddGrabCount(scanLine)
    return self:_CheckStatus(scanLine, XEnumConst.GOLDEN_MINER.GAME_SCAN_LINE_STATUS.ALIVE) and
            scanLine.CurGrabCount < self._TargetCount
end
--endregion

--region Control - ScanLine
local zero = Vector3.zero
function XGoldenMinerComponentScanLine:UpdateScanLine(deltaTime)
    if self._CurProgress >= self._TargetProgress then
        self:_SetCurProcess(self._CurProgress - self._TargetProgress)
        local scanLine = self:_GetRecycleScanLine()
        if not scanLine then
            scanLine = self:_CreateScanLine()
            table.insert(self._CurScanLineList, scanLine)
        end
        self:_ResetScanLine(scanLine)
    end
    for _, scanLine in ipairs(self._CurScanLineList) do
        if self:_CheckStatus(scanLine, XEnumConst.GOLDEN_MINER.GAME_SCAN_LINE_STATUS.NONE) then
            self:ChangeAlive(scanLine)
        elseif self:_CheckStatus(scanLine, XEnumConst.GOLDEN_MINER.GAME_SCAN_LINE_STATUS.ALIVE) then
            self._CurDeltaPos:Update(0, self._MoveSpeed * deltaTime)
            scanLine.Transform.anchoredPosition = scanLine.Transform.anchoredPosition + self._CurDeltaPos
            for i, effectRoot in ipairs(scanLine.TriggerEffectDir) do
                effectRoot.position = scanLine.TriggerEffectPosDir[i] or zero
            end
            if self:_CheckScanLineBeDie(scanLine) then
                self:ChangeDie(scanLine)
            end
        end
    end
end

---@return XGoldenMinerScanLine
function XGoldenMinerComponentScanLine:_GetRecycleScanLine()
    if XTool.IsTableEmpty(self._CurScanLineList) then
        return nil
    end
    for _, scanLine in ipairs(self._CurScanLineList) do
        if self:_CheckStatus(scanLine, XEnumConst.GOLDEN_MINER.GAME_SCAN_LINE_STATUS.DIE) then
            return scanLine
        end
    end
    return nil
end

---@return XGoldenMinerScanLine
function XGoldenMinerComponentScanLine:_CreateScanLine()
    ---@type XGoldenMinerScanLine
    local scanLine = {}
    local go = XUiHelper.Instantiate(self.ScanLine.transform, self.ScanLine.transform.parent)
    go.name = XEnumConst.GOLDEN_MINER.HOOK_IGNORE_HIT
    scanLine.Transform = go.transform
    XTool.InitUiObject(scanLine)
    scanLine.Transform.anchoredPosition = Vector2(scanLine.Transform.anchoredPosition.x, self._MoveYRange.Min)
    scanLine.ScanLineCollider.size = Vector2(self._MoveXRange.Max - self._MoveXRange.Min, scanLine.ScanLineCollider.size.y)
    scanLine.TriggerEffectDir = {
        scanLine.TriggerEffect,
    }
    scanLine.TriggerEffectPosDir = {}
    for i = 2, self._TargetCount do
        local effectRoot = XUiHelper.Instantiate(scanLine.TriggerEffect.transform, scanLine.TriggerEffect.transform.parent)
        scanLine.TriggerEffectDir[i] = effectRoot.transform
    end
    if not string.IsNilOrEmpty(self._TriggerEffectUrl) then
        for _, effectRoot in ipairs(scanLine.TriggerEffectDir) do
            effectRoot:LoadPrefab(self._TriggerEffectUrl)
        end
    end
    for _, effectRoot in ipairs(scanLine.TriggerEffectDir) do
        effectRoot.gameObject:SetActiveEx(false)
    end
    scanLine.GoInputHandler:AddTriggerEnter2DCallback(function(collider)
        self:_OnScanLineHit(scanLine, collider)
    end)
    return scanLine
end

---@param scanLine XGoldenMinerScanLine
---@param collider UnityEngine.BoxCollider2D
function XGoldenMinerComponentScanLine:_OnScanLineHit(scanLine, collider)
    if not self:_CheckScanLineCanAddGrabCount(scanLine) then
        return
    end
    if self._OnHitFunc(collider) then
        scanLine.CurGrabCount = scanLine.CurGrabCount + 1
        scanLine.TriggerEffectPosDir[scanLine.CurGrabCount] = collider.transform.position
        scanLine.TriggerEffectDir[scanLine.CurGrabCount].position = collider.transform.position
        scanLine.TriggerEffectDir[scanLine.CurGrabCount].gameObject:SetActiveEx(false)
        scanLine.TriggerEffectDir[scanLine.CurGrabCount].gameObject:SetActiveEx(true)
        self._OwnControl:PlayPartnerTriggerSound(self._Type)
    end
end
--endregion

--region Control - Status
---@param scanLine XGoldenMinerScanLine
function XGoldenMinerComponentScanLine:_ResetScanLine(scanLine)
    scanLine.Status = XEnumConst.GOLDEN_MINER.GAME_SCAN_LINE_STATUS.NONE
    scanLine.CurGrabCount = 0
    scanLine.Transform.anchoredPosition = Vector2(scanLine.Transform.anchoredPosition.x, self._MoveYRange.Min)
end

---@param scanLine XGoldenMinerScanLine
function XGoldenMinerComponentScanLine:ChangeAlive(scanLine)
    scanLine.Status = XEnumConst.GOLDEN_MINER.GAME_SCAN_LINE_STATUS.ALIVE
    scanLine.Transform.gameObject:SetActiveEx(true)
end

---@param scanLine XGoldenMinerScanLine
function XGoldenMinerComponentScanLine:ChangeDie(scanLine)
    scanLine.Status = XEnumConst.GOLDEN_MINER.GAME_SCAN_LINE_STATUS.DIE
    scanLine.Transform.gameObject:SetActiveEx(false)
    for _, effectRoot in ipairs(scanLine.TriggerEffectDir) do
        effectRoot.gameObject:SetActiveEx(false)
    end
end
--endregion

return XGoldenMinerComponentScanLine