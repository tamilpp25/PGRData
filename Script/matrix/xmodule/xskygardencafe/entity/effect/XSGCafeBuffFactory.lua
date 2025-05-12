local XSGCafeBuff = require("XModule/XSkyGardenCafe/Entity/Effect/XSGCafeBuff")

local pairs = pairs

---@class XSGCafePriorityLotteryBuff : XSGCafeBuff 优先抽取
local XSGCafePriorityLotteryBuff = XClass(XSGCafeBuff, "XSGCafePriorityLotteryBuff")

function XSGCafePriorityLotteryBuff:ApplyMotion()
    if not self._Card then
        return
    end
    local cardId = self._Card:GetCardId()
    self._Model:GetBattleInfo():InsertPrecede(cardId)
    self:AddEffectCount()
end

function XSGCafePriorityLotteryBuff:RemoveMotion()
    if not self._Card then
        return
    end
    local cardId = self._Card:GetCardId()
    self._Model:GetBattleInfo():RemovePrecede(cardId)
end

---@class XSGCafeStayInHandBuff : XSGCafeBuff 弃牌时保留
local XSGCafeStayInHandBuff = XClass(XSGCafeBuff, "XSGCafeStayInHandBuff")

function XSGCafeStayInHandBuff:ApplyMotion()
    local param1 = self._Params[1]
    --指定当前卡牌
    if param1 == 1 then
        local cardId = self._Card:GetCardId()
        self._Model:GetBattleInfo():InsertStayInHand(cardId)
        self._CardIds = { cardId }
    elseif param1 == 2 then
        --走配置
        local index = 2
        self._CardIds = {}
        while true do
            local cardId = self._Params[index]
            if not cardId or cardId < 0 then
                break
            end
            self._Model:GetBattleInfo():InsertStayInHand(cardId)
            index = index + 1
            self._CardIds[#self._CardIds + 1] = cardId
        end
    elseif param1 == 3 then
        --剩余手牌
        local cards = self._OwnControl:GetMainControl():GetRoundEntity():GetDeckCardEntities()
        if not XTool.IsTableEmpty(cards) then
            for _, card in pairs(cards) do
                local cardId = card:GetCardId()
                self._Model:GetBattleInfo():InsertStayInHand(cardId)
                self._CardIds[#self._CardIds + 1] = cardId
            end
        end
    end

    if not XTool.IsTableEmpty(self._CardIds) then
        self:AddEffectCount()
    end
end

function XSGCafeStayInHandBuff:RemoveMotion()
    if XTool.IsTableEmpty(self._CardIds) then
        return
    end
    for _, cardId in pairs(self._CardIds) do
        self._Model:GetBattleInfo():RemoveStayInHand(cardId)
    end
end

---@class XSGCafeRemoveBuff : XSGCafeBuff 当局永久移除抽取可能性
local XSGCafeRemoveBuff = XClass(XSGCafeBuff, "XSGCafeRemoveBuff")

function XSGCafeRemoveBuff:ApplyMotion()
    local param1 = self._Params[1]
    --指定当前卡牌
    if param1 == 1 then
        if not self._Card then
            XLog.Error("Buff绑定的卡牌为空！")
            return
        end
        local cardId = self._Card:GetCardId()
        self._BanCardIds = { cardId }
        self._Model:GetBattleInfo():InsertBanCard(cardId)
        self:AddEffectCount()
    elseif param1 == 2 then
        --走配置
        local index = 2
        local cardIds = {}
        while true do
            local cardId = self._Params[index]
            if not cardId or cardId < 0 then
                break
            end
            cardIds[#cardIds + 1] = cardId
            self._Model:GetBattleInfo():InsertBanCard(cardId)
            index = index + 1
        end
        self._BanCardIds = cardIds
        self:AddEffectCount()
    end
end

function XSGCafeRemoveBuff:RemoveMotion()
    if XTool.IsTableEmpty(self._BanCardIds) then
        return
    end
    local battleInfo = self._Model:GetBattleInfo()
    for _, cardId in pairs(self._BanCardIds) do
        battleInfo:RemoveBanCard(cardId)
    end
end

---@class XSGCafeReplaceBuff : XSGCafeBuff 替换卡牌
local XSGCafeReplaceBuff = XClass(XSGCafeBuff, "XSGCafeReplaceBuff")

function XSGCafeReplaceBuff:ApplyMotion()
    local param1 = self._Params[1]
    local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
    local deckCards, libCards
    local dict = self:GetParamDict(5, function(v) 
        return v and v > 0
    end)
    if param1 == 1 then
        --指定类型
        deckCards = roundEntity:GetDeckCardsByType(dict, true)
    elseif param1 == 2 then
        --指定非类型
        deckCards = roundEntity:GetDeckCardsByType(dict, false)
    elseif param1 == 3 then
        --指定稀有度
        deckCards = roundEntity:GetDeckCardsByQuality(dict, true)
    elseif param1 == 4 then
        --指定非稀有度
        deckCards = roundEntity:GetDeckCardsByQuality(dict, false)
    end
    
    local param2 = self._Params[2]
    local isRandom = self._Params[3] == 1
    --直接牌库抽
    if param2 == 1 then
        libCards = roundEntity:GetLibCardsByOrder(#deckCards, isRandom)
    elseif param2 == 2 then
        --读取配置抽
        local targets = { self._Params[4] }
        libCards = roundEntity:GetLibCardsByTargets(targets, #deckCards, isRandom)
    elseif param2 == 3 then
        --根据类型抽
        libCards = roundEntity:GetLibCardsByType(self._Params[4], #deckCards, isRandom)
    end
    self._DeckCards = deckCards
    self._LibCards = libCards
    self:AddEffectCount()
    roundEntity:Replace(deckCards, libCards, self._Card)
end

function XSGCafeReplaceBuff:RemoveMotion()
    if XTool.IsTableEmpty(self._DeckCards) and XTool.IsTableEmpty(self._LibCards) then
        return
    end

    local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
    roundEntity:Replace(self._LibCards, self._DeckCards, self._Card)
end

---@class XSGCafeNonDirectedLotteryBuff : XSGCafeBuff 非定向抽取
local XSGCafeNonDirectedLotteryBuff = XClass(XSGCafeBuff, "XSGCafeNonDirectedLotteryBuff")

function XSGCafeNonDirectedLotteryBuff:OnAwake()
    self._LeftRound = self._Params[1] - 1
end

function XSGCafeNonDirectedLotteryBuff:ApplyMotion()
    if self:TryAddNextRound() then
        return
    end
    local param2 = self._Params[2]
    local count = 0
    local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
    --抽取固定数量的牌
    if param2 == 1 then
        count = self._Params[3]
    elseif param2 == 2 then
        --抽取到手牌上限
        count = roundEntity:GetRestDeckCount()
    end
    local libs = roundEntity:GetLibCardsByOrder(count, false)
    self._LibIds = libs
    self:AddEffectCount()
    roundEntity:Replace(nil, libs, self._Card)
end

function XSGCafeNonDirectedLotteryBuff:RemoveMotion()
    --if XTool.IsTableEmpty(self._LibIds) then
    --    return
    --end
    --local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
    --roundEntity:Replace(self._LibIds, nil)
end

---@class XSGCafeTargetedLotteryBuff : XSGCafeBuff 定向抽取
local XSGCafeTargetedLotteryBuff = XClass(XSGCafeBuff, "XSGCafeTargetedLotteryBuff")

function XSGCafeTargetedLotteryBuff:OnAwake()
    self._LeftRound = self._Params[1] - 1
end

function XSGCafeTargetedLotteryBuff:ApplyMotion()
    if self:TryAddNextRound() then
        return
    end

    local isRandom = self._Params[2] == 2
    local check = function(v)
        return v and v > 0
    end
    local index = 4
    local targets = self:GetParamList(index, check)
    local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
    local libIds = roundEntity:GetLibCardsByTargets(targets, self._Params[3], isRandom)
    self._LibIds = libIds
    self:AddEffectCount()
    roundEntity:Replace(nil, libIds, self._Card)
end

function XSGCafeTargetedLotteryBuff:RemoveMotion()
    --if XTool.IsTableEmpty(self._LibIds) then
    --    return
    --end
    --local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
    --roundEntity:Replace(self._LibIds, nil)
end

---@class XSGCafeInsertBuff : XSGCafeBuff 将一张牌插入牌堆
local XSGCafeInsertBuff = XClass(XSGCafeBuff, "XSGCafeInsertBuff")

function XSGCafeInsertBuff:OnAwake()
    self._LeftRound = self._Params[1] - 1
end

function XSGCafeInsertBuff:ApplyMotion()
    if self:TryAddNextRound() then
        return
    end
    local pos = self._Params[2]
    local param3 = self._Params[3]
    local cards
    local factory = self._OwnControl:GetMainControl():GetCardFactory()
    --卡牌自身
    if param3 == 1 then
        if not self._Card then
            XLog.Error("Buff绑定的卡牌为空！")
            return
        end
        cards = { 
            factory:CreateCard(self._Card:GetCardId())
        }
    elseif param3 == 2 then
        cards = {}
        local index = 4
        local check = function(v)
            return v and v > 0
        end
        local cardIds = self:GetParamList(index, check)
        for _, cardId in pairs(cardIds) do
            cards[#cards + 1] = factory:CreateCard(cardId)
        end
    end
    self._Cards = cards
    self._Pos = pos
    self._OwnControl:GetMainControl():GetRoundEntity():InsertToLibs(cards, pos)
    self:AddEffectCount()
end

function XSGCafeInsertBuff:RemoveMotion()
    if XTool.IsTableEmpty(self._Cards) then
        return
    end
    self._OwnControl:GetMainControl():GetRoundEntity():RemoveLibCards(self._Cards)
end

---@class XSGCafePool2DeckBuff : XSGCafeBuff 发牌调整
local XSGCafePool2DeckBuff = XClass(XSGCafeBuff, "XSGCafePool2DeckBuff")

function XSGCafePool2DeckBuff:OnAwake()
    self._LeftRound = self._Params[2] == 1 and 0 or 1
end

function XSGCafePool2DeckBuff:ApplyMotion()
    if self:TryAddNextRound() then
        return
    end
    self._Count = self._Params[1]
     self._OwnControl:GetMainControl():AddDeckCount(self._Count)
    self:AddEffectCount()
end

function XSGCafePool2DeckBuff:RemoveMotion()
    if self._Count and self._Count ~= 0 then
        self._OwnControl:GetMainControl():AddDeckCount(-self._Count)
    end
end

function XSGCafePool2DeckBuff:AddBuffArgs()
    if not self._Card then
        return
    end
    local key = 801
    self._Card:AddBuffArgs(key, self._Count * self._EffectCount)
end

---@class XSGCafeDealCountChangeBuff : XSGCafeBuff 出牌区域数量调整
local XSGCafeDealCountChangeBuff = XClass(XSGCafeBuff, "XSGCafeDealCountChangeBuff")

function XSGCafeDealCountChangeBuff:OnAwake()
    self._LeftRound = self._Params[1] - 1
end

function XSGCafeDealCountChangeBuff:ApplyMotion()
    if self:TryAddNextRound() then
        return
    end
    self._Count = self._OwnControl:GetMainControl():AddDealCount(self._Params[2])
    self:AddEffectCount()
end

function XSGCafeDealCountChangeBuff:RemoveMotion()
    if not self._Count or self._Count == 0 then
        return
    end
    self._OwnControl:GetMainControl():AddDealCount(-self._Count)
end

function XSGCafeDealCountChangeBuff:AddBuffArgs()
    if not self._Card then
        return
    end
    if not self._Count or self._Count == 0 then
        return
    end
    local key = 901
    self._Card:AddBuffArgs(key, self._Count * self._EffectCount)
end

---@class XSGCafeCopyBuff : XSGCafeBuff 复制卡的buff
---@field _TargetCard XSkyGardenCafeCardEntity
local XSGCafeCopyBuff = XClass(XSGCafeBuff, "XSGCafeCopyBuff")

function XSGCafeCopyBuff:ApplyMotion()
    if not self._Card then
        return
    end

    local param1 = self._Params[1]

    --指定位置的卡
    local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
    local index = roundEntity:GetDealCardIndexByCard(self._Card)
    local targetIndex
    if param1 == 1 then --前一张卡
        targetIndex = index - 1
    elseif param1 == 2 then --后一张卡
        targetIndex = index + 1
    end
    local limit = self._Model:GetBattleInfo():GetDealLimit(self._Model:GetMaxDeckCount())
    if targetIndex <= 0 or targetIndex > limit then
        return
    end
    local cardEntities = roundEntity:GetDealCardEntities()
    local card = cardEntities[targetIndex]

    if not card then
        return
    end
    local param2 = self._Params[2]
    local value
    if param2 == 1 then --指定卡
        value = card:GetCardId()
    elseif param2 == 2 then --指定类型
        value = card:GetCardType()
    elseif param2 == 3 then --指定稀有度
        value = card:GetCardQuality()
    end
    local target = self._Params[3]
    if target ~= 0 and target ~= value then
        return
    end
    
    local buffIds = self._Model:GetCustomerBuffIds(card:GetCardId())
    local factory = self._OwnControl:GetMainControl():GetBuffFactory()
    local copyType = XMVCA.XSkyGardenCafe.EffectType.Copy
    ---@type XSGCafeBuff[]
    self._AttachBuff = {}
    for _, buffId in pairs(buffIds) do
        if buffId == self._BuffId then
            XLog.Error("参数配置错误，Buff不能自己触发自己" .. buffId)
            return
        end
        local buffType = self._Model:GetEffectType(buffId)
        if buffType ~= copyType then
            local buff = factory:CreateBuff(buffId, self._Card)
            self._Card:AttachBuff(buff, 1)
            self._AttachBuff[#self._AttachBuff + 1] = buff
        end
    end
    
    for _, buff in pairs(self._AttachBuff) do
        local args = buff:GetArgs()
        buff:Apply(buff:GetTriggerId(), args and table.unpack(args) or nil)
    end
    self._TargetCard = card
    self:AddEffectCount()
end

function XSGCafeCopyBuff:RemoveMotion()
    if XTool.IsTableEmpty(self._AttachBuff) then
        return
    end
    
    for _, buff in pairs(self._AttachBuff) do
        buff:DisApplyAuto()
        self._Card:DetachBuff(buff)
    end
end

function XSGCafeCopyBuff:AddBuffArgs()
    if not self._Card or not self._TargetCard then
        return
    end
    self._Card:SetCustomerDetails(self._TargetCard:GetCustomerDetails())
end

---@class XSGCafeDealIndexBuff : XSGCafeBuff 出牌区下标判断
local XSGCafeDealIndexBuff = XClass(XSGCafeBuff, "XSGCafeDealIndexBuff")

function XSGCafeDealIndexBuff:ApplyMotion()
    local param1 = self._Params[1]
    local count = 0
    local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
    local index = roundEntity:GetDealCardIndexByCard(self._Card)
    if param1 == 1 then
        --固定席位
        count = self._Params[2] == index and self._Params[4] or 0
    elseif param1 == 2 then
        --当前卡与目标下标差值
        count = index - self._Params[2]
    end

    if count <= 0 then
        return
    end

    local buffId = self._Params[3]
    if not buffId or buffId <= 0 then
        XLog.Error("参数配置错误 EffectId = " .. self._BuffId)
        return
    end

    if buffId == self._BuffId then
        XLog.Error("参数配置错误，Buff不能自己触发自己" .. buffId)
        return
    end
    
    local buff = self._OwnControl:CreateBuff(buffId, self._Card)
    self._AttachBuff = buff
    self._AttachCount = count
    self._Card:AttachBuff(buff, count)
    for _ = 1, count do
        self._AttachBuff:ApplyInDeal()
    end

    self:AddEffectCount()
end

function XSGCafeDealIndexBuff:PreviewApplyMotion()
    local param1 = self._Params[1]
    local count = 0
    local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
    local index = roundEntity:GetNextDealIndex()
    if param1 == 1 then
        --固定席位
        count = self._Params[2] == index and self._Params[4] or 0
    elseif param1 == 2 then
        --当前卡与目标下标差值
        count = index - self._Params[2]
    end
    if count <= 0 then
        return
    end
    local buffId = self._Params[3]
    if not buffId or buffId <= 0 then
        XLog.Error("参数配置错误 EffectId = " .. self._BuffId)
        return
    end

    if buffId == self._BuffId then
        XLog.Error("参数配置错误，Buff不能自己触发自己" .. buffId)
        return
    end
    local buff = self._OwnControl:CreateBuff(buffId, self._Card)
    buff:SetPreviewEffectLayer(count)
    for _ = 1, count do
        buff:PreviewApplyInDeal()
    end
    self._AttachBuff = buff
    self._AttachCount = count
    self._PreviewCount = 1
end

function XSGCafeDealIndexBuff:RemoveMotion()
    if not self._AttachBuff then
        return
    end
    
    for _ = 1, self._AttachCount do
        self._AttachBuff:DisApplyAuto()
    end
    
    self._Card:DetachBuff(self._AttachBuff)
end

function XSGCafeDealIndexBuff:AddBuffArgs()
    if not self._Card or not self._AttachBuff then
        return
    end
    self._Card:AddBuffArgs(1301, self._AttachCount)
    self._Card:AddBuffArgs(1399, self._AttachCount * self._AttachBuff:GetBuffExportValue())
end

---@class XSGCafeCardCountBuff : XSGCafeBuff 判断卡的使用生效效果
local XSGCafeCardCountBuff = XClass(XSGCafeBuff, "XSGCafeCardCountBuff")

function XSGCafeCardCountBuff:ApplyMotion()
    local param1 = self._Params[1]
    local param4 = self._Params[4]
    local count
    if param4 == 0 then
        count = 1
    else
        local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
        ---@type XSkyGardenCafeCardEntity[]
        local cards
        if param1 == 1 then
            --手牌
            cards = roundEntity:GetDeckCardEntities()
        elseif param1 == 2 then
            --出牌
            cards = roundEntity:GetDealCardEntities()
        end

        if not XTool.IsTableEmpty(cards) then
            local param2 = self._Params[2]
            if param2 == 2 then
                --指定Ids
                local temp = {}
                local cardIdMap = self:GetParamDict(5, function(v)
                    return v and v > 0
                end)
                for _, card in pairs(cards) do
                    if cardIdMap[card:GetCardId()] then
                        temp[#temp + 1] = card
                    end
                end
                cards = temp
            elseif param2 == 3 then
                --指定Types
                local temp = {}
                local cardTypeMap = self:GetParamDict(5, function(v)
                    return v and v > 0
                end)
                for _, card in pairs(cards) do
                    if cardTypeMap[card:GetCardType()] then
                        temp[#temp + 1] = card
                    end
                end
                cards = temp
            end
        end
        count = XTool.IsTableEmpty(cards) and 0 or #cards
    end

    local buffId = self._Params[3]
    if not buffId or buffId <= 0 then
        XLog.Error("参数配置错误 EffectId = " .. self._BuffId)
        return
    end

    if buffId == self._BuffId then
        XLog.Error("参数配置错误，Buff不能自己触发自己" .. buffId)
        return
    end
    
    local buff = self._OwnControl:CreateBuff(buffId, self._Card)
    self._AttachBuff = buff
    self._AttachCount = count
    self._Card:AttachBuff(buff, count)
    for _ = 1, count do
        buff:ApplyInDeal()
    end
    self:AddEffectCount()
end

function XSGCafeCardCountBuff:PreviewApplyMotion()
    local param1 = self._Params[1]
    local param4 = self._Params[4]
    local count
    if param4 == 0 then
        count = 1
    else
        local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
        ---@type XSkyGardenCafeCardEntity[]
        local cards
        if param1 == 1 then
            --手牌
            cards = roundEntity:GetDeckCardEntities()
        elseif param1 == 2 then
            --出牌
            cards = roundEntity:GetDealCardEntities()
        end

        if not XTool.IsTableEmpty(cards) then
            local param2 = self._Params[2]
            if param2 == 2 then
                --指定Ids
                local temp = {}
                local cardIdMap = self:GetParamDict(5, function(v)
                    return v and v > 0
                end)
                for _, card in pairs(cards) do
                    if cardIdMap[card:GetCardId()] then
                        temp[#temp + 1] = card
                    end
                end
                cards = temp
            elseif param2 == 3 then
                --指定Types
                local temp = {}
                local cardTypeMap = self:GetParamDict(5, function(v)
                    return v and v > 0
                end)
                for _, card in pairs(cards) do
                    if cardTypeMap[card:GetCardType()] then
                        temp[#temp + 1] = card
                    end
                end
                cards = temp
            end
        end
        count = XTool.IsTableEmpty(cards) and 0 or #cards
    end

    local buffId = self._Params[3]
    if not buffId or buffId <= 0 then
        XLog.Error("参数配置错误 EffectId = " .. self._BuffId)
        return
    end

    if buffId == self._BuffId then
        XLog.Error("参数配置错误，Buff不能自己触发自己" .. buffId)
        return
    end

    local buff = self._OwnControl:CreateBuff(buffId, self._Card)
    buff:SetPreviewEffectLayer(count)
    for _ = 1, count do
        buff:PreviewApplyInDeal()
    end
    self._AttachCount = count
    self._PreviewCount = 1
end

function XSGCafeCardCountBuff:RemoveMotion()
    if not self._AttachBuff then
        return
    end
    for _ = 1, self._AttachCount do
        self._AttachBuff:DisApplyAuto()
    end
    self._Card:DetachBuff(self._AttachBuff)
end

function XSGCafeCardCountBuff:AddBuffArgs()
    if not self._Card then
        return
    end
    
    self._Card:AddBuffArgs(1401, self._AttachCount)
end

---@class XSGCafeCarryWhenUseBuff : XSGCafeBuff 出牌时携带符合条件的卡牌一起使用，且不占用槽位
local XSGCafeCarryWhenUseBuff = XClass(XSGCafeBuff, "XSGCafeCarryWhenUseBuff")

function XSGCafeCarryWhenUseBuff:ApplyMotion()
    local param1 = self._Params[1]
    local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
    ---@type XSkyGardenCafeCardEntity[]
    local deckCards = roundEntity:GetDeckCardEntities()
    local libCards = roundEntity:GetPoolEntities()

    if param1 == 1 then
        --指定Ids
        local temp = {}
        local cardIdMap = self:GetParamDict(2, function(v)
            return v and v > 0
        end)
        for _, card in pairs(deckCards) do
            if cardIdMap[card:GetCardId()] then
                temp[#temp + 1] = card
            end
        end
        for _, card in pairs(libCards) do
            if cardIdMap[card:GetCardId()] then
                temp[#temp + 1] = card
            end
        end
        deckCards = temp
    elseif param1 == 2 then
        --指定Types
        local temp = {}
        local cardTypeMap = self:GetParamDict(2, function(v)
            return v and v > 0
        end)
        for _, card in pairs(deckCards) do
            if cardTypeMap[card:GetCardType()] then
                temp[#temp + 1] = card
            end
        end
        for _, card in pairs(libCards) do
            if cardTypeMap[card:GetCardType()] then
                temp[#temp + 1] = card
            end
        end
        deckCards = temp
    end

    if XTool.IsTableEmpty(deckCards) then
        return
    end

    for _, card in pairs(deckCards) do
        self._Card:AttachChildCard(card)
    end
    self:AddEffectCount()
end

---@class XSGCafeCardUseCountBuff : XSGCafeBuff 卡牌使用次数
local XSGCafeCardUseCountBuff = XClass(XSGCafeBuff, "XSGCafeCardUseCountBuff")

function XSGCafeCardUseCountBuff:ApplyMotion()
    local count = self._Model:GetBattleInfo():GetCardUseCount(self._Card:GetCardId())
    local buffId
    if count <= 0 then
        --首次使用
        buffId = self._Params[1]
        count = 1
    else
        buffId = self._Params[2]
    end
    if not buffId or buffId <= 0 then
        XLog.Error("参数配置错误 EffectId = " .. self._BuffId)
        return
    end

    if buffId == self._BuffId then
        XLog.Error("参数配置错误，Buff不能自己触发自己" .. buffId)
        return
    end
    
    local buff = self._OwnControl:CreateBuff(buffId, self._Card)
    self._AttachBuff = buff
    self._AttachCount = count
    for _ = 1, count do
        buff:ApplyInDeal()
    end
    self._Card:AttachBuff(buff, count)
    
    self:AddEffectCount()
end

function XSGCafeCardUseCountBuff:PreviewApplyMotion()
    local count = self._Model:GetBattleInfo():GetCardUseCount(self._Card:GetCardId())
    --预览的需要+1
    count = count + 1
    local buffId
    if count <= 0 then
        --首次使用
        buffId = self._Params[1]
        count = 1
    else
        buffId = self._Params[2]
    end
    if not buffId or buffId <= 0 then
        return
    end

    if buffId == self._BuffId then
        XLog.Error("参数配置错误，Buff不能自己触发自己" .. buffId)
        return
    end

    local buff = self._OwnControl:CreateBuff(buffId, self._Card)
    buff:SetPreviewEffectLayer(count)
    for _ = 1, count do
        buff:PreviewApplyInDeal()
    end
    self._AttachBuff = buff
    self._AttachCount = count
    self._PreviewCount = 1
end

function XSGCafeCardUseCountBuff:RemoveMotion()
    if not self._AttachBuff then
        return
    end
    for _ = 1, self._AttachCount do
        self._AttachBuff:DisApplyAuto()
    end
    self._Card:DetachBuff(self._AttachBuff)
end

function XSGCafeCardUseCountBuff:AddBuffArgs()
    if not self._Card or not self._AttachBuff then
        return
    end

    self._Card:AddBuffArgs(1601, self._AttachCount)
    self._Card:AddBuffArgs(1699, self._AttachCount * self._AttachBuff:GetBuffExportValue()) 
end

---@class XSGCafeGameRoundBuff : XSGCafeBuff 游戏回合
local XSGCafeGameRoundBuff = XClass(XSGCafeBuff, "XSGCafeGameRoundBuff")

function XSGCafeGameRoundBuff:ApplyMotion()
    local round = self._Model:GetBattleInfo():GetRound()
    local buffId = self._Params[2]
    local value = self._Params[1]
    if value == 0 then
        XLog.Error("Buff异常, 第一个参数表不能为0， buffId = " .. self._BuffId)
        return
    end
    if not buffId or buffId <= 0 then
        XLog.Error("参数配置错误 EffectId = " .. self._BuffId)
        return
    end

    if buffId == self._BuffId then
        XLog.Error("参数配置错误，Buff不能自己触发自己" .. buffId)
        return
    end
    
    local count = math.floor((round - 1) / value)
    if count <= 0 then
        return
    end
    local buff = self._OwnControl:CreateBuff(buffId, self._Card)
    self._AttachBuff = buff
    self._AttachCount = count
    for _ = 1, count do
        buff:ApplyInDeal()
    end
    self._Card:AttachBuff(buff, count)
    
    self:AddEffectCount()
end

function XSGCafeGameRoundBuff:PreviewApplyMotion()
    local round = self._Model:GetBattleInfo():GetRound()
    local buffId = self._Params[2]
    local value = self._Params[1]
    if value == 0 then
        XLog.Error("Buff异常, 第一个参数表不能为0， buffId = " .. self._BuffId)
        return
    end
    if not buffId or buffId <= 0 then
        return
    end

    if buffId == self._BuffId then
        XLog.Error("参数配置错误，Buff不能自己触发自己" .. buffId)
        return
    end

    local count = math.floor((round - 1) / value)
    if count <= 0 then
        return
    end
    local buff = self._OwnControl:CreateBuff(buffId, self._Card)
    buff:SetPreviewEffectLayer(count)
    for _ = 1, count do
        buff:PreviewApplyInDeal()
    end
    self._AttachBuff = buff
    self._AttachCount = count
    self._PreviewCount = 1
end

function XSGCafeGameRoundBuff:RemoveMotion()
    if not self._AttachBuff then
        return
    end
    for _ = 1, self._AttachCount do
        self._AttachBuff:DisApplyAuto()
    end
    self._Card:DetachBuff(self._AttachBuff)
end

function XSGCafeGameRoundBuff:AddBuffArgs()
    if not self._Card or not self._AttachBuff then
        return
    end
    
    self._Card:AddBuffArgs(1701, self._AttachCount)
    self._Card:AddBuffArgs(1799, self._AttachCount * self._AttachBuff:GetBuffExportValue())
end

---@class XSGCafeApplyOtherBuff : XSGCafeBuff 触发其他Buff
local XSGCafeApplyOtherBuff = XClass(XSGCafeBuff, "XSGCafeApplyOtherBuff")

function XSGCafeApplyOtherBuff:ApplyMotion()
    if not self._Card then
        XLog.Error("该Buff必须配置在卡上, EffectId = " .. self._BuffId)
        return
    end
    local buffId = self._Params[1]
    if not buffId or buffId <= 0 then
        XLog.Error("参数配置错误 EffectId = " .. self._BuffId)
        return
    end
    if buffId == self._BuffId then
        XLog.Error("参数配置错误，Buff不能自己触发自己" .. buffId)
        return
    end
    
    local buff = self._OwnControl:CreateBuff(buffId, self._Card)
    self._AttachBuff = buff
    self._Card:AttachBuff(buff, 1)
    buff:ApplyInDeal()

    self:AddEffectCount()
end

function XSGCafeApplyOtherBuff:RemoveMotion()
    if not self._AttachBuff then
        return
    end
    self._AttachBuff:DisApplyAuto()
    self._Card:DetachBuff(self._AttachBuff)
end

---@class XSGCafeGameRoundSustainBuff : XSGCafeBuff 游戏回合持续Buff
local XSGCafeGameRoundSustainBuff = XClass(XSGCafeBuff, "XSGCafeGameRoundSustainBuff")

function XSGCafeGameRoundSustainBuff:OnAwake()
    self._Begin = self._Params[1]
    self._End = self._Params[2]
end

function XSGCafeGameRoundSustainBuff:ApplyMotion()
    if self._Card then
        XLog.Error("该Buff不允许配置在卡上, EffectId = " .. self._BuffId)
        return
    end
    local round = self._Model:GetBattleInfo():GetRound()
    if self._Begin > round or self._End < round then
        return
    end

    local buffId = self._Params[3]
    if not buffId or buffId <= 0 then
        XLog.Error("参数配置错误 EffectId = " .. self._BuffId)
        return
    end

    if buffId == self._BuffId then
        XLog.Error("参数配置错误，Buff不能自己触发自己" .. buffId)
        return
    end
    
    local buff = self._OwnControl:CreateBuff(buffId)
    
    self:AddEffectCount()
    self._OwnControl:GetMainControl():AttachStageBuff(buff)
end

function XSGCafeGameRoundSustainBuff:IsRelease()
    local round = self._Model:GetBattleInfo():GetRound()
    return round > self._End
end

---@class XSGCafeCreateNewBuff : XSGCafeBuff 创建新的卡牌
local XSGCafeCreateNewBuff = XClass(XSGCafeBuff, "XSGCafeCreateNewBuff")

function XSGCafeCreateNewBuff:OnAwake()
    self._LeftRound = self._Params[1] - 1
end

function XSGCafeCreateNewBuff:ApplyMotion()
    if self:TryAddNextRound() then
        return
    end

    local isRandom = self._Params[2] == 2
    local check = function(v)
        return v and v > 0
    end
    local index = 4
    local targets = self:GetParamList(index, check)
    local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
    local libIds = roundEntity:CreateNewCard(targets, self._Params[3], isRandom)
    self._LibIds = libIds
    self:AddEffectCount()
    roundEntity:Replace(nil, libIds, self._Card)
end

function XSGCafeCreateNewBuff:RemoveMotion()
end



---@class XSGCafeBuffFactory : XEntityControl
---@field _MainControl XSkyGardenCafeBattle
---@field _Model XSkyGardenCafeModel
local XSGCafeBuffFactory = XClass(XEntityControl, "XSGCafeBuffFactory")

local EffectType = XMVCA.XSkyGardenCafe.EffectType

function XSGCafeBuffFactory:OnInit()
    self._Factory = {
        [EffectType.PriorityLottery] = XSGCafePriorityLotteryBuff,
        [EffectType.StayInHand] = XSGCafeStayInHandBuff,
        [EffectType.Remove] = XSGCafeRemoveBuff,
        [EffectType.Replace] = XSGCafeReplaceBuff,
        [EffectType.NonDirectedLottery] = XSGCafeNonDirectedLotteryBuff,
        [EffectType.TargetedLottery] = XSGCafeTargetedLotteryBuff,
        [EffectType.Insert] = XSGCafeInsertBuff,
        [EffectType.Pool2Deck] = XSGCafePool2DeckBuff,
        [EffectType.DealCountChange] = XSGCafeDealCountChangeBuff,
        [EffectType.ResourceChange] = require("XModule/XSkyGardenCafe/Entity/Effect/XSGCafeResourceChangeBuff"),
        [EffectType.ResourceTransform] = require("XModule/XSkyGardenCafe/Entity/Effect/XSGCafeResourceTransformBuff"),
        [EffectType.Copy] = XSGCafeCopyBuff,
        [EffectType.DealIndex] = XSGCafeDealIndexBuff,
        [EffectType.CardCount] = XSGCafeCardCountBuff,
        [EffectType.CarryWhenUse] = XSGCafeCarryWhenUseBuff,
        [EffectType.CardUseCount] = XSGCafeCardUseCountBuff,
        [EffectType.GameRound] = XSGCafeGameRoundBuff,
        [EffectType.ApplyOther] = XSGCafeApplyOtherBuff,
        [EffectType.GameRoundSustain] = XSGCafeGameRoundSustainBuff,
        [EffectType.ResourceChangeForever] = require("XModule/XSkyGardenCafe/Entity/Effect/XSGCafeResourceChangeForeverBuff"),
        [EffectType.CreateNew] = XSGCafeCreateNewBuff,
    }
end

function XSGCafeBuffFactory:OnRelease()
    self._Factory = nil
end

---@return XSGCafeBuff
function XSGCafeBuffFactory:CreateBuff(id, card)
    local buffType = self._Model:GetEffectType(id)
    local cls = self._Factory[buffType]
    if not cls then
        XLog.Error("不存在类型为：" .. buffType .. "的Buff")
        return
    end
    return self:AddEntity(cls, id, card)
end

---@return XSkyGardenCafeBattle
function XSGCafeBuffFactory:GetMainControl()
    return self._MainControl
end

return XSGCafeBuffFactory