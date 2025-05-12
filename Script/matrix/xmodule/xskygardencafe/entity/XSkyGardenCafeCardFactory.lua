---@class XSkyGardenCafeCardEntity : XEntity 卡牌
---@field _OwnControl XSkyGardenCafeCardFactory
---@field _Model XSkyGardenCafeModel
---@field _Id number
---@field _BuffEntities XSGCafeBuff[]
---@field _AttachBuffEntities table[]
---@field _ChildCard XSkyGardenCafeCardEntity[] 携带的子牌
local XSkyGardenCafeCardEntity = XClass(XEntity, "XSkyGardenCafeCardEntity")

local EffectTriggerId = XMVCA.XSkyGardenCafe.EffectTriggerId
local Pattern = XMVCA.XSkyGardenCafe.Pattern

local CardResourceChangedTriggerId = { EffectTriggerId.CardResourceChanged }

local IsDebugBuild = CS.XApplication.Debug

function XSkyGardenCafeCardEntity:OnInit(id)
    self._Id = id
    --当前coffee量
    self._CurrentCoffee = self._Model:GetCustomerCoffee(id)
    --buff实际增加的coffee
    self._BuffCoffee = 0
    --buff预览增加的coffee
    self._PreviewBuffCoffee = 0
    --当前预览coffee
    self._PreviewCurCoffee = self._Model:GetCustomerCoffee(id)
    
    self._CurrentReview = self._Model:GetCustomerReview(id)
    --buff增加的review
    self._BuffReview = 0
    --buff预览增加的review
    self._PreviewBuffReview = 0
    --当前预览coffee
    self._PreviewCurReview = self._Model:GetCustomerReview(id)
    
    self._BuffEntities = {}
    self._AttachBuffEntities = {}
    self._ChildCard = {}
    self._BuffArgs = {}
    self._ReplaceHandler = handler(self, self.ReplaceHandler)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_ROUND_BEGIN, self.OnPreviewReset, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_DEAL_INDEX_UPDATE, self.OnPreviewReset, self)
    self:InitBuff()
end

function XSkyGardenCafeCardEntity:Reset()
end

function XSkyGardenCafeCardEntity:IsDisposed()
    return self._Id <= 0
end

function XSkyGardenCafeCardEntity:OnRelease()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_ROUND_BEGIN, self.OnPreviewReset, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_DEAL_INDEX_UPDATE, self.OnPreviewReset, self)
    self:DestroyBuff()

    self._Id = 0
end

function XSkyGardenCafeCardEntity:OnPreviewReset()
    local id = self._Id
    
    self._PreviewBuffCoffee = 0
    self._PreviewCurCoffee = self._Model:GetCustomerCoffee(id)

    self._PreviewBuffReview = 0
    self._PreviewCurReview = self._Model:GetCustomerReview(id)
end

function XSkyGardenCafeCardEntity:GetCardId()
    return self._Id
end

function XSkyGardenCafeCardEntity:GetCardType()
    return self._Model:GetCustomerType(self._Id)
end

function XSkyGardenCafeCardEntity:GetCardQuality()
    return self._Model:GetCustomerQuality(self._Id)
end

function XSkyGardenCafeCardEntity:IsMaxQuality()
    return self._Model:IsMaxQuality(self._Id)
end

function XSkyGardenCafeCardEntity:IsReDraw()
    return self._Model:IsReDrawCustomer(self._Id)
end

function XSkyGardenCafeCardEntity:GetCustomerDetails()
    if self._DetailDesc then
        return self._DetailDesc
    end
    local detail = self._Model:GetCustomerDetails(self._Id)
    return XUiHelper.ReplaceTextNewLine(detail:gsub(Pattern, self._ReplaceHandler))
end

function XSkyGardenCafeCardEntity:GetCustomerDesc()
    local desc = self._Model:GetCustomerDesc(self._Id)
    return XUiHelper.ReplaceTextNewLine(desc)
end

---@param strKey string
function XSkyGardenCafeCardEntity:ReplaceHandler(strKey)
    if XTool.IsTableEmpty(self._BuffArgs) then
        return 0
    end
    local v = self._BuffArgs[tonumber(strKey)]
    if not v then
        return 0
    end
    return v
end

function XSkyGardenCafeCardEntity:AddBuffArgs(key, value)
    self._BuffArgs[key] = value
end

function XSkyGardenCafeCardEntity:ClearBuffArgs()
    for k, _ in pairs(self._BuffArgs) do
        self._BuffArgs[k] = nil
    end
end

function XSkyGardenCafeCardEntity:SetCustomerDetails(value)
    self._DetailDesc = value
end

--region 销量

--- 该卡牌总销量
---@return number
function XSkyGardenCafeCardEntity:GetTotalCoffee(isPreview)
    return self:GetOriginCoffee(isPreview) + self:GetAddCoffee(isPreview)
end

--- 该卡牌基础销量
---@return number
function XSkyGardenCafeCardEntity:GetOriginCoffee(isPreview)
    return isPreview and math.floor(self._PreviewCurCoffee) or math.floor(self._CurrentCoffee)
end

--- 该卡牌增益销量
---@return number
function XSkyGardenCafeCardEntity:GetAddCoffee(isPreview)
    local own
    if isPreview then
        own = self._PreviewBuffCoffee
    else
        own = self._BuffCoffee
    end
    if not XTool.IsTableEmpty(self._ChildCard) then
        for _, child in pairs(self._ChildCard) do
            own = own + child:GetTotalCoffee(isPreview)
        end
    end
    local value = self._Model:GetBattleInfo():GetCardForeverData(self:GetCardId(), true)
    return math.floor(own + value)
end

--- 根据百分比获取基础增益销量
---@param percent number 范围0~1
---@return number
function XSkyGardenCafeCardEntity:GetAddBasicCoffeeByPercent(percent, isPreview)
    local oldValue = self:GetOriginCoffee(isPreview)
    return XMVCA.XSkyGardenCafe:GetChangeValueByPercent(oldValue, percent)
end

--- 根据百分比获取最终增益销量
---@param percent number 范围0~1
---@return number
function XSkyGardenCafeCardEntity:GetAddFinalCoffeeByPercent(percent, isPreview)
    local oldValue = self:GetTotalCoffee(isPreview)
    return XMVCA.XSkyGardenCafe:GetChangeValueByPercent(oldValue, percent)
end

--- 增加基础销量
---@param value number
function XSkyGardenCafeCardEntity:AddBasicCoffee(value, isPreview)
    if not value or value == 0 then
        return
    end

    if isPreview then
        self._PreviewCurCoffee = self._PreviewCurCoffee + value
        self:PreviewApplyBuff(CardResourceChangedTriggerId)
    else
        self._CurrentCoffee = self._CurrentCoffee + value
        self:ApplyBuff(EffectTriggerId.CardResourceChanged)
    end

end

--- 增加最终销量
---@param value number
function XSkyGardenCafeCardEntity:AddFinalCoffee(value, isPreview)
    if not value or value == 0 then
        return
    end
    
    if isPreview then
        self._PreviewBuffCoffee = self._PreviewBuffCoffee + value
        self:PreviewApplyBuff(CardResourceChangedTriggerId)
    else
        self._BuffCoffee = self._BuffCoffee + value
        self:ApplyBuff(EffectTriggerId.CardResourceChanged)
    end
end

--endregion

--region 好评

--- 该卡牌实际总好评
---@return number
function XSkyGardenCafeCardEntity:GetTotalReview(isPreview)
    return self:GetOriginReview(isPreview) + self:GetAddReview(isPreview)
end

--- 该卡牌基础好评
---@return number
function XSkyGardenCafeCardEntity:GetOriginReview(isPreview)
    return isPreview and math.floor(self._PreviewCurReview) 
            or math.floor(self._CurrentReview)
end

--- 该卡牌增益好评
---@return number
function XSkyGardenCafeCardEntity:GetAddReview(isPreview)
    local own
    if isPreview then
        own = self._PreviewBuffReview
    else
        own = self._BuffReview
    end
    if not XTool.IsTableEmpty(self._ChildCard) then
        for _, child in pairs(self._ChildCard) do
            own = own + child:GetTotalReview(isPreview)
        end
    end
    local value = self._Model:GetBattleInfo():GetCardForeverData(self:GetCardId(), false)
    return math.floor(own + value)
end

--- 根据百分比获取基础增益好评
---@param percent number 范围0~1
---@return number
function XSkyGardenCafeCardEntity:GetAddBasicReviewByPercent(percent, isPreview)
    local oldValue = self:GetOriginReview(isPreview)
    return XMVCA.XSkyGardenCafe:GetChangeValueByPercent(oldValue, percent)
end

--- 根据百分比获取最终增益好评
---@param percent number 范围0~1
---@return number
function XSkyGardenCafeCardEntity:GetAddFinalReviewByPercent(percent, isPreview)
    local oldValue = self:GetTotalReview(isPreview)
    return XMVCA.XSkyGardenCafe:GetChangeValueByPercent(oldValue, percent)
end

--- 增加基础好评
---@param value number
function XSkyGardenCafeCardEntity:AddBasicReview(value, isPreview)
    if not value or value == 0 then
        return
    end
    if isPreview then
        self._PreviewCurReview = self._PreviewCurReview + value
        self:PreviewApplyBuff(CardResourceChangedTriggerId)
    else
        self._CurrentReview = self._CurrentReview + value
        self:ApplyBuff(EffectTriggerId.CardResourceChanged)
    end
end

--- 增加最终好评
---@param value number
function XSkyGardenCafeCardEntity:AddFinalReview(value, isPreview)
    if not value or value == 0 then
        return
    end
    if isPreview then
        self._PreviewBuffReview = self._PreviewBuffReview + value
        self:PreviewApplyBuff(CardResourceChangedTriggerId)
    else
        self._BuffReview = self._BuffReview + value
        self:ApplyBuff(EffectTriggerId.CardResourceChanged)
    end
end

--endregion

function XSkyGardenCafeCardEntity:PreviewApplyBuff(triggerDict, triggerArgDict)
    if not XTool.IsTableEmpty(self._BuffEntities) then
        for _, buff in pairs(self._BuffEntities) do
            buff:PreviewApply(triggerDict, triggerArgDict)
        end
    end
    if not XTool.IsTableEmpty(self._AttachBuffEntities) then
        for _, data in pairs(self._AttachBuffEntities) do
            local buff = data.Buff
            local count = data.Count
            if buff then
                for _ = 1, count do
                    buff:PreviewApply(triggerDict, triggerArgDict)
                end
            end
        end
    end
end

function XSkyGardenCafeCardEntity:ApplyBuff(triggerType, ...)
    if not XTool.IsTableEmpty(self._BuffEntities) then
        for _, buff in pairs(self._BuffEntities) do
            buff:Apply(triggerType, ...)
        end
    end
    if not XTool.IsTableEmpty(self._AttachBuffEntities) then
        for _, data in pairs(self._AttachBuffEntities) do
            local buff = data.Buff
            local count = data.Count
            if buff then
                for _ = 1, count do
                    buff:Apply(triggerType, ...)
                end
            end
        end
    end
end

function XSkyGardenCafeCardEntity:DisApplyBuff(triggerType)
    if not XTool.IsTableEmpty(self._BuffEntities) then
        for _, buff in pairs(self._BuffEntities) do
            buff:DisApply(triggerType)
        end
    end
    
    if not XTool.IsTableEmpty(self._AttachBuffEntities) then
        for _, data in pairs(self._AttachBuffEntities) do
            local buff = data.Buff
            local count = data.Count
            if buff then
                for _ = 1, count do
                    buff:DisApply(triggerType)
                end
            end
        end
    end
end

--- 给卡牌附加Buff
---@param buff XSGCafeBuff
function XSkyGardenCafeCardEntity:AttachBuff(buff, count)
    if not buff or count <= 0 then
        return
    end
    local data = {
        Buff = buff,
        Count = count,
    }
    buff:SetEffectLayer(count)
    self._AttachBuffEntities[#self._AttachBuffEntities + 1] = data
end

--- 移除卡牌附加的Buff
---@param buff XSGCafeBuff
function XSkyGardenCafeCardEntity:DetachBuff(buff)
    if not buff then
        return
    end
    
    local removed = false
    for i = #self._AttachBuffEntities, 1, -1 do
        local data = self._AttachBuffEntities[i]
        if data.Buff and data.Buff == buff then
            table.remove(self._AttachBuffEntities, i)
            removed = true
            break
        end
    end
    if removed then
        local factory = self._OwnControl:GetMainControl():GetBuffFactory()
        factory:RemoveEntity(buff)
    end
end

function XSkyGardenCafeCardEntity:InitBuff()
    local buffIds = self._Model:GetCustomerBuffIds(self._Id)
    if not XTool.IsTableEmpty(buffIds) then
        local factory = self._OwnControl:GetMainControl():GetBuffFactory()
        for _, buffId in pairs(buffIds) do
            local buff = factory:CreateBuff(buffId, self)
            self._BuffEntities[#self._BuffEntities + 1] = buff
        end
    end
end

function XSkyGardenCafeCardEntity:DestroyBuff()
    local battle = self._OwnControl:GetMainControl()
    local factory = battle:GetBuffFactory()
    for _, buff in pairs(self._BuffEntities) do
        if buff:IsRelease() then
            factory:RemoveEntity(buff)
        else
            battle:AddNextRoundBuff(buff)
        end
    end

    for _, data in pairs(self._AttachBuffEntities) do
        local buff = data.Buff
        
        if not buff then
            goto continue
        end
        
        if buff:IsRelease() then
            factory:RemoveEntity(buff)
        else
            battle:AddNextRoundBuff(buff)
        end
        ::continue::
    end

    self._AttachBuffEntities = nil
    self._BuffEntities = nil
end

function XSkyGardenCafeCardEntity:IsBuffEffect(buffId, count)
    for _, buff in pairs(self._BuffEntities) do
        if buff:GetBuffId() == buffId then
            return buff:GetEffectCount() == count
        end
    end
    for _, data in pairs(self._AttachBuffEntities) do
        local buff = data.Buff
        if buff and buff:GetBuffId() == buffId then
            return buff:GetEffectCount() == count
        end
    end
    return false
end

function XSkyGardenCafeCardEntity:AttachChildCard(card)
    if not card then
        return
    end
    
    self._ChildCard[#self._ChildCard + 1] = card
end

function XSkyGardenCafeCardEntity:PrintBuff()
    if not IsDebugBuild then
        return
    end
    local log = {}
    for _, buff in pairs(self._BuffEntities) do
        log[#log + 1] = string.format("[Id = %s, 执行次数: %s]", buff:GetBuffId(), buff._EffectCount)
    end
    for _,data in pairs(self._AttachBuffEntities) do
        local buff = data.Buff
        log[#log + 1] = string.format("[Id = %s, 执行次数: %s]", buff:GetBuffId(), buff._EffectCount)
    end
    XLog.Warning(string.format("【%s】挂载了Buff：%s", self._OwnControl:GetMainControl():GetMainControl():GetCustomerName(self._Id), table.concat(log, "\t")))
end


---@class XSkyGardenCafeCardFactory : XEntityControl 卡牌管理
---@field _MainControl XSkyGardenCafeBattle
---@field _Model XSkyGardenCafeModel
local XSkyGardenCafeCardFactory = XClass(XEntityControl, "XSkyGardenCafeCardFactory")

function XSkyGardenCafeCardFactory:OnInit()
end

function XSkyGardenCafeCardFactory:OnRelease()
end

function XSkyGardenCafeCardFactory:CreateCard(id)
    return self:AddEntity(XSkyGardenCafeCardEntity, id)
end

function XSkyGardenCafeCardFactory:GetMainControl()
    return self._MainControl
end

return XSkyGardenCafeCardFactory