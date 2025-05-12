---@class XSGCafeBuff : XEntity Buff基类
---@field _Id number
---@field _Type number
---@field _Model XSkyGardenCafeModel
---@field _OwnControl XSGCafeBuffFactory
---@field _Card XSkyGardenCafeCardEntity
---@field _Params number[]
local XSGCafeBuff = XClass(XEntity, "XSGCafeBuff")

local EffectTriggerId = XMVCA.XSkyGardenCafe.EffectTriggerId
local DlcEventId = XMVCA.XBigWorldService.DlcEventId

local ApplyInDealTriggerId = { EffectTriggerId.Deck2Deal }

function XSGCafeBuff:OnInit(buffId, card)
    self._BuffId = buffId
    self._Card = card
    self._EffectType = self._Model:GetEffectType(buffId)
    self._TriggerId = self._Model:GetEffectTriggerId(buffId)
    self._Params = self._Model:GetEffectParams(buffId)
    self._IsCanRunAuto = false
    --Buff执行次数
    self._EffectCount = 0
    --Buff层数
    self._EffectLayer = 1
    --唯一触发，不能还原
    self._IsSingleShot = self._Model:IsSingleShotEffect(buffId)
    --是否被销毁
    self._IsDisposed = false
    self._IsReleaseWhenDestroy = true
    --Buff预览次数
    self._PreviewCount = 0
    --Buff预览最大次数
    self._PreviewLayer = 1
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_ROUND_BEGIN, self.OnPreviewReset, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_DEAL_INDEX_UPDATE, self.OnPreviewReset, self)
    self:OnAwake()
end

function XSGCafeBuff:OnAwake()
end

function XSGCafeBuff:OnRelease()
    if XMVCA.XSkyGardenCafe.NotPermanentEffectType[self._EffectType] then
        self:DisApply(self._TriggerId, true)
    end
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_ROUND_BEGIN, self.OnPreviewReset, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_DEAL_INDEX_UPDATE, self.OnPreviewReset, self)
    self:OnDestroy()

    self._EffectCount = 0
    self._TriggerId = nil
    self._Card = nil
    self._IsDisposed = true
end

function XSGCafeBuff:OnPreviewReset()
    self._PreviewCount = 0
    self._PreviewLayer = 1
end

function XSGCafeBuff:IsDisposed()
    return self._IsDisposed
end

function XSGCafeBuff:CheckCondition(isPreview, ...)
    local conditions = self._Model:GetEffectConditions(self._BuffId)
    if XTool.IsTableEmpty(conditions) then
        return true
    end
    local success = true
    local control = self._OwnControl:GetMainControl():GetMainControl()
    for _, conditionId in pairs(conditions) do
        local res, _ = control:CheckCondition(conditionId, self._Card, isPreview, ...)
        if not res then
            success = false
            break
        end
    end
    return success
end

function XSGCafeBuff:PreviewApply(triggerDict, triggerArgDict)
    if XTool.IsTableEmpty(triggerDict) then
        return
    end
    if not triggerDict[self._TriggerId] then
        return
    end

    if self._IsPreviewing then
        return
    end

    if self._PreviewCount >= self._PreviewLayer then
        return
    end

    if self._EffectCount >= self._EffectLayer then
        return
    end
    local args = triggerArgDict and triggerArgDict[self._TriggerId] or nil
    if not self:CheckCondition(true, args and table.unpack(args) or nil) then
        return
    end
    self._IsPreviewing = true
    
    self:PreviewApplyMotion()
    if self._PreviewCount >= 1 then
        self:AddBuffArgs()
    end
    self._IsPreviewing = false
    self._OwnControl:GetMainControl():RefreshContainer(true)
end

function XSGCafeBuff:Apply(triggerType, ...)
    if self._TriggerId ~= triggerType then
        return
    end

    if self._IsEffecting then
        return
    end
    
    if not self:CheckCondition(false, ...) then
        self:DisApply(triggerType)
        return
    end
    self._Args = { ... }
    if self._IsSingleShot and self._EffectCount > 0 then
        return
    end
    while true do
        if self._EffectCount <= 0 then
            break
        end
        self:DisApply(triggerType)
    end
    self._IsEffecting = true
    for _ = 1, self._EffectLayer do
        self:ApplyMotion()
    end
    if self._EffectCount >= 1 then
        self:AddBuffArgs()
    end
    self._IsEffecting = false
    self._OwnControl:GetMainControl():RefreshContainer(false)
    self._OwnControl:GetMainControl():RefreshContainer(true)
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_UPDATE_PLAY_CARD)
end

function XSGCafeBuff:ApplyAuto()
    if not self._IsCanRunAuto then
        XLog.Error("不能触发Buff, 未通过检测 BuffId = " .. self._BuffId)
        return
    end
    self:Apply(self._TriggerId, table.unpack(self._Args))
    self._IsCanRunAuto = false
end

function XSGCafeBuff:ApplyInDeal()
    self:Apply(EffectTriggerId.Deck2Deal)
end

function XSGCafeBuff:PreviewApplyInDeal()
    self:PreviewApply(ApplyInDealTriggerId)
end

function XSGCafeBuff:DisApply(triggerType, isForce)
    if self._TriggerId ~= triggerType then
        return
    end
    if self._EffectCount <= 0 then
        return
    end

    if not isForce and (self._IsSingleShot and self._EffectCount > 0) then
        return
    end
    
    self:RemoveMotion()
    self:SubEffectCount()
    self._OwnControl:GetMainControl():RefreshContainer(false)
    self._OwnControl:GetMainControl():RefreshContainer(true)
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_UPDATE_PLAY_CARD)
end

function XSGCafeBuff:DisApplyAuto()
    self:DisApply(self._TriggerId)
end

function XSGCafeBuff:PreviewApplyMotion()
end

function XSGCafeBuff:ApplyMotion()
end

function XSGCafeBuff:RemoveMotion()
end

function XSGCafeBuff:OnDestroy()
end

function XSGCafeBuff:IsRelease()
    return self._IsReleaseWhenDestroy
end

function XSGCafeBuff:AddEffectCount()
    self._EffectCount = self._EffectCount + 1
end

function XSGCafeBuff:SubEffectCount()
    self._EffectCount = self._EffectCount - 1
end

function XSGCafeBuff:GetEffectCount()
    return self._EffectCount
end

function XSGCafeBuff:GetParamList(startIndex, validCheck)
    local list = {}
    while true do
        local value = self._Params[startIndex]
        if not validCheck(value) then
            break
        end
        list[#list + 1] = value
        startIndex = startIndex + 1
    end
    return list
end

function XSGCafeBuff:GetParamDict(startIndex, validCheck)
    local dict = {}
    while true do
        local value = self._Params[startIndex]
        if not validCheck(value) then
            break
        end
        dict[value] = true
        startIndex = startIndex + 1
    end
    return dict
end

function XSGCafeBuff:GetBuffId()
    return self._BuffId
end

function XSGCafeBuff:SetEffectLayer(value)
    self._EffectLayer = value
end

function XSGCafeBuff:SetPreviewEffectLayer(value)
    self._PreviewLayer = value
end

function XSGCafeBuff:IsCardValid()
    if not self._Card then
        return false
    end
    return self._Card:GetCardId() ~= 0
end

function XSGCafeBuff:TryAddNextRound()
    if not self._LeftRound then
        return false
    end
    local round = self._Model:GetBattleInfo():GetRound()
    if self._AddRound == round then
        return true
    end
    if self._LeftRound <= 0 then
        self._IsReleaseWhenDestroy = true
        return false
    end
    self._LeftRound = self._LeftRound - 1
    self._IsCanRunAuto = true
    self._OwnControl:GetMainControl():AddNextRoundBuff(self)
    self._AddRound = round
    self._IsReleaseWhenDestroy = false
    return true
end

function XSGCafeBuff:GetTriggerId()
    return self._TriggerId
end

function XSGCafeBuff:GetArgs()
    return self._Args
end

function XSGCafeBuff:AddBuffArgs()
end

function XSGCafeBuff:GetBuffExportValue()
    return 0
end

return XSGCafeBuff