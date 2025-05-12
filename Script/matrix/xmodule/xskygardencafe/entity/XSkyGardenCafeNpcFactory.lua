---@class XSkyGardenCafeNpc : XEntity 演出npc
---@field _NpcUUId number
---@field _CardId number
---@field _Transform UnityEngine.Transform
---@field _Model XSkyGardenCafeModel
local XSkyGardenCafeNpc = XClass(XEntity, "XSkyGardenCafeNpc")

---@type X3CCommand
local X3CCmd = CS.X3CCommand
local EventId = XMVCA.XBigWorldService.DlcEventId
local HudType = XMVCA.XSkyGardenCafe.HudType

function XSkyGardenCafeNpc:OnInit(uuid, cardId, posId, transform)
    self._NpcUUId = uuid
    self._CardId = cardId
    self._PosId = posId
    self._Transform = transform
end

function XSkyGardenCafeNpc:OnRelease()
    self:HideCoffee()
    self:HideEmoji()
    self:HideReview()
    self._NpcUUId = 0
    self._CardId = 0
    self._Transform = nil
end

function XSkyGardenCafeNpc:IsValid()
    return self._Transform and not XTool.UObjIsNil(self._Transform)
end

function XSkyGardenCafeNpc:GetCardId()
    return self._CardId
end

function XSkyGardenCafeNpc:GetNpcUUId()
    return self._NpcUUId
end

function XSkyGardenCafeNpc:GetPosId()
    return self._PosId
end

function XSkyGardenCafeNpc:GetLevelNpcBaseId()
    return self._Model:GetCustomerNpcId(self._CardId)
end

function XSkyGardenCafeNpc:IsMaxQuality()
    return self._Model:IsMaxQuality(self._CardId)
end

function XSkyGardenCafeNpc:ShowDialog()
    local textList = self._Model:GetShowClickText(self:GetLevelNpcBaseId())
    if XTool.IsTableEmpty(textList) then
        return
    end
    local index = math.random(1, #textList)
    local result = XMVCA.X3CProxy:Send(X3CCmd.CMD_CAFE_NPC_CLICK_DOWN, {
        NpcUUID = self._NpcUUId,
        RandomIndex = index - 1, --C#从0开始
    })
    if not result or result.Success == false then
        return
    end
    local value = textList[index]
    XEventManager.DispatchEvent(EventId.EVENT_CAFE_HUD_REFRESH, self._NpcUUId, self._Transform, 
            nil, HudType.DialogHud, value)
end

function XSkyGardenCafeNpc:ShowCoffee(value)
    if not self:IsValid() then
        return
    end
    if value == 0 then
        return
    end
    
    if not self._CoffeeOffset then
        local offsetX, offsetY = self._Model:GetShowCoffeeOffset(self._PosId)
        self._CoffeeOffset = Vector3(offsetX, offsetY, 0)
    end
    XEventManager.DispatchEvent(EventId.EVENT_CAFE_HUD_REFRESH, self._NpcUUId, self._Transform, 
            self._CoffeeOffset, HudType.CoffeeHud, value)
end

function XSkyGardenCafeNpc:HideCoffee()
    XEventManager.DispatchEvent(EventId.EVENT_CAFE_HUD_HIDE, self._NpcUUId, HudType.CoffeeHud)
end

function XSkyGardenCafeNpc:ShowReview(value)
    if not self:IsValid() then
        return
    end
    if value == 0 then
        return
    end
    
    if not self._ReviewOffset then
        local offsetX, offsetY = self._Model:GetShowReviewOffset(self._PosId)
        self._ReviewOffset = Vector3(offsetX, offsetY, 0)
    end
    XEventManager.DispatchEvent(EventId.EVENT_CAFE_HUD_REFRESH, self._NpcUUId, self._Transform,
            self._ReviewOffset, HudType.ReviewHud, value)
end

function XSkyGardenCafeNpc:HideReview()
    XEventManager.DispatchEvent(EventId.EVENT_CAFE_HUD_HIDE, self._NpcUUId, HudType.ReviewHud)
end

function XSkyGardenCafeNpc:ShowEmoji()
    if not self:IsValid() then
        return
    end
    if not self._EmojiOffset then
        local offsetX, offsetY = self._Model:GetShowEmojiOffset(self._PosId)
        self._EmojiOffset = Vector3(offsetX, offsetY, 0)
    end
    local value = self._Model:GetShowSettleEmoji(self:GetLevelNpcBaseId())
    
    XEventManager.DispatchEvent(EventId.EVENT_CAFE_HUD_REFRESH, self._NpcUUId, self._Transform,
            self._EmojiOffset, HudType.EmojiHud, value)
end

function XSkyGardenCafeNpc:HideEmoji()
    XEventManager.DispatchEvent(EventId.EVENT_CAFE_HUD_HIDE, self._NpcUUId, HudType.EmojiHud)
end


---@class XSkyGardenCafeNpcFactory : XEntityControl Npc管理
---@field _MainControl XSkyGardenCafeBattle
---@field _Model XSkyGardenCafeModel
---@field _NpcDict table<number, XSkyGardenCafeNpc>
local XSkyGardenCafeNpcFactory = XClass(XEntityControl, "XSkyGardenCafeNpcFactory")

function XSkyGardenCafeNpcFactory:OnInit()
    --self._MaxIdleCount = self._Model:GetMaxIdleNpcCount()
    --self._MaxPatrolCount = self._Model:GetMaxPatrolNpcCount()
    
    self._NpcDict = {}
    self._Card2NpcId = {}
    
    self._BarNpcUUId = -1
end

function XSkyGardenCafeNpcFactory:OnRelease()
    if not XTool.IsTableEmpty(self._NpcDict) then
        for uuId, _ in pairs(self._NpcDict) do
            XMVCA.X3CProxy:Send(X3CCmd.CMD_CAFE_REMOVE_NPC, {
                NpcUUID = uuId
            })
        end
    end
    self._NpcDict = false
end

function XSkyGardenCafeNpcFactory:GetNpc(uuid)
    local npc = self._NpcDict[uuid]
    return npc
end

function XSkyGardenCafeNpcFactory:CreateNpc(cardId, posId)
    local npcId = self._Model:GetCustomerNpcId(cardId)
    if not npcId or npcId <= 0 then
        XLog.Error("创建NPC失败, NPCID无效, CustomerId = " .. cardId)
        return
    end
    if not posId or posId <= 0 then
        XLog.Error("创建NPC失败, 点位值无效！ SpotId = " .. posId)
        return
    end
    
    local spotId = self._Model:GetSpotId(posId)
    local res = XMVCA.X3CProxy:Send(X3CCmd.CMD_CAFE_CREATE_IDLE_NPC, {
        LevelNpcBaseId = npcId,
        SpotId = spotId
    })
    
    if not res then
        XLog.Error("创建Npc失败, X3C返回内容为空！")
        return
    end
    local uuid, root = res.NpcUUID, res.NpcRoot
    local npc = self._NpcDict[uuid]
    if npc then
        XLog.Error("重复创建Npc")
        return
    end
    npc = self:AddEntity(XSkyGardenCafeNpc, uuid, cardId, posId, root)
    self._NpcDict[uuid] = npc
    self._Card2NpcId[cardId] = uuid
    
    return uuid
end

function XSkyGardenCafeNpcFactory:RemoveNpc(uuid)
    local npc = self:GetNpc(uuid)
    if not npc then
        return
    end
    XMVCA.X3CProxy:Send(X3CCmd.CMD_CAFE_REMOVE_NPC, {
        NpcUUID = uuid
    })
    self._Card2NpcId[npc:GetCardId()] = nil
    self:RemoveEntity(npc)
    self._NpcDict[uuid] = nil
end

function XSkyGardenCafeNpcFactory:GetMaxNpcCount()
    return self._MaxPatrolCount + self._MaxIdleCount + 1
end

---@param card XSkyGardenCafeCardEntity
function XSkyGardenCafeNpcFactory:LoadNpc(card)
    if not card then
        return
    end
    local cardId = card:GetCardId()
    --已经加载在吧台的角色，直接飞特效
    if card:IsMaxQuality() and self._Card2NpcId[cardId] == self._BarNpcUUId then
        local npc = self:GetNpc(self._BarNpcUUId)
        npc:ShowCoffee(card:GetTotalCoffee())
        npc:ShowReview(card:GetTotalReview())
        return
    end
    
    local uuid = self:CreateNpc(card:GetCardId(), self._Model:RandomPosId())
    if not uuid or uuid <= 0 then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EFFECT_BEGIN_FLY)
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_EFFECT_FLY_COMPLETE)
        return
    end
    local npc = self:GetNpc(uuid)
    if npc then
        npc:ShowCoffee(card:GetTotalCoffee())
        npc:ShowReview(card:GetTotalReview())
    end
end

---@param deckCards XSkyGardenCafeCardEntity[]
function XSkyGardenCafeNpcFactory:LoadNpcWhenDrawCard(deckCards)
    if self._BarNpcUUId and self._BarNpcUUId > 0 then
        return
    end
    
    if not XTool.IsTableEmpty(deckCards) then
        for _, card in pairs(deckCards) do
            if not card:IsMaxQuality() then
                goto continue
            end
            local cardId = card:GetCardId()
            local npcId = self._Model:GetCustomerNpcId(cardId)
            if not npcId or npcId <= 0 then
                goto continue
            end
            local posId = self._Model:GetNpcDefaultPosId(npcId, true)
            if not posId or posId <= 0 then
                goto continue
            end
            self._BarNpcUUId = self:CreateNpc(cardId, posId)
            XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_BAR_COUNTER_NPC_CHANGED)
            ::continue::
        end
    end
end

---@param deckCards XSkyGardenCafeCardEntity[]
function XSkyGardenCafeNpcFactory:RemoveNpcWhenRoundEnd(deckCards)
    local keepBarNpc = false
    if self._BarNpcUUId and not XTool.IsTableEmpty(deckCards) then
        for _, card in pairs(deckCards) do
            local uuid = self._Card2NpcId[card:GetCardId()]
            if uuid == self._BarNpcUUId then
                keepBarNpc = true
                break
            end
        end
    end
    local keepId = -1
    --保留吧台角色
    if keepBarNpc then
        keepId = self._BarNpcUUId
    else --不保留吧台角色
        self._BarNpcUUId = false
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_BAR_COUNTER_NPC_CHANGED)
    end
    for uuid, _ in pairs(self._NpcDict) do
        if uuid ~= keepId then
            self:RemoveNpc(uuid)
        end
    end
end

function XSkyGardenCafeNpcFactory:PlayRoundEnd()
    local skipId = self._BarNpcUUId
    local count = 0
    local scheduleOnce = XScheduleManager.ScheduleOnce
    local delay = 200
    for uuid, npc in pairs(self._NpcDict) do
        if skipId ~= uuid then
            scheduleOnce(function()
                npc:ShowEmoji()
            end, delay * count)
            count = count + 1
        end
    end
    return (count * delay + 2000)
end

function XSkyGardenCafeNpcFactory:GetBarCounterNpcUUID()
    return self._BarNpcUUId
end

return XSkyGardenCafeNpcFactory