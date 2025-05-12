local XSGCafeBuff = require("XModule/XSkyGardenCafe/Entity/Effect/XSGCafeBuff")

---@class XSGCafeResourceChangeForeverBuff : XSGCafeBuff 卡牌资源永久改变
local XSGCafeResourceChangeForeverBuff = XClass(XSGCafeBuff, "XSGCafeResourceChangeForeverBuff")

function XSGCafeResourceChangeForeverBuff:OnAwake()
    self._LeftRound = self._Params[1] - 1
end

function XSGCafeResourceChangeForeverBuff:ApplyMotion(isPreview)
    if self:TryAddNextRound()  then
        return
    end
    local param2 = self._Params[2]
    ---@type XSkyGardenCafeCardEntity[]
    local cards = nil
    ---@type XSkyGardenCafeCardEntity[]
    local previewCards = nil
    if param2 == 1 then  --对卡牌自身生效
        if isPreview then
            previewCards = { self._Card }
        else
            cards = { self._Card }
        end
    elseif param2 == 2 then  --指定位置的卡
        local index = self._Params[3]
        local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
        if index == roundEntity:GetNextDealIndex() then
            --未使用时只对自己生效
            if self._Params[7] == 1 and roundEntity:GetDealCardIndexByCard(self._Card) <= 0 then
                previewCards = { self._Card }
            else
                previewCards = roundEntity:GetDeckCardEntities()
            end
        else
            local cardEntities = roundEntity:GetDealCardEntities()
            cards = { cardEntities and cardEntities[index] or nil }
        end

    elseif param2 == 3 then --指定位序的卡
        local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
        local currentIndex = roundEntity:GetDealCardIndexByCard(self._Card)
        if currentIndex < 0 then
            return
        end
        local index = currentIndex + self._Params[3]
        if index == roundEntity:GetNextDealIndex() then
            --未使用时只对自己生效
            if self._Params[7] == 1 and roundEntity:GetDealCardIndexByCard(self._Card) <= 0 then
                previewCards = { self._Card }
            else
                previewCards = roundEntity:GetDeckCardEntities()
            end
        else
            local cardEntities = roundEntity:GetDealCardEntities()
            cards = { cardEntities and cardEntities[index] or nil }
        end
    elseif param2 == 4 then --指定卡
        local cardId = self._Params[3]
        local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
        local cardEntities = roundEntity:GetDealCardEntities()
        cards = {}
        for _, card in pairs(cardEntities) do
            if card:GetCardId() == cardId then
                cards[#cards + 1] = card
            end
        end
        if isPreview then
            previewCards = {}
            for _, card in pairs(roundEntity:GetDeckCardEntities()) do
                if card:GetCardId() == cardId then
                    previewCards[#previewCards + 1] = card
                end
            end
        end
    elseif param2 == 5 then  --当前手牌
        local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
        local cardEntities = roundEntity:GetDeckCardEntities()
        cards = {}
        for _, card in pairs(cardEntities) do
            cards[#cards + 1] = card
        end
    elseif param2 == 6 then --已使用的牌（必须回合结束时）
        local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
        local cardEntities = roundEntity:GetDealCardEntities()
        cards = {}
        for _, card in pairs(cardEntities) do
            cards[#cards + 1] = card
        end
    end

    if isPreview then
        if self._PreviewCount < self._PreviewLayer and self:DoApplyByCards(previewCards, true) then
            self._PreviewCount = self._PreviewCount + 1
        end
    else
        if self:DoApplyByCards(cards, false) then
            self:AddEffectCount()
        end
    end
end

function XSGCafeResourceChangeForeverBuff:PreviewApplyMotion()
    self:ApplyMotion(true)
end

---@param cards XSkyGardenCafeCardEntity[]
function XSGCafeResourceChangeForeverBuff:DoApplyByCards(cards, isPreview)
    if XTool.IsTableEmpty(cards) then
        return false
    end
    local param4 = self._Params[4]
    local isPercent = self._Params[5] ~= 1
    local value = isPercent and self._Params[6] / 10000 or self._Params[6]

    if not isPreview then
        self._EffectCards = cards
    end
    local battleInfo = self._Model:GetBattleInfo()
    if param4 == 1 then  --基础销量
        self._EffectCoffees = {}
        for i, card in pairs(cards) do
            local v = isPercent and card:GetAddBasicCoffeeByPercent(value, isPreview) or value
            if isPreview then
                card:AddFinalCoffee(v, isPreview)
            else
                battleInfo:ChangeCardForeverData(card:GetCardId(), true, v)
            end
            self._EffectCoffees[i] = v
        end
        return true
    elseif param4 == 2 then --基础好评
        self._EffectReviews = {}
        for i, card in pairs(cards) do
            local v = isPercent and card:GetAddBasicReviewByPercent(value, isPreview) or value
            if isPreview then
                card:AddFinalReview(v, isPreview)
            else
                battleInfo:ChangeCardForeverData(card:GetCardId(), false, v)
            end
            self._EffectReviews[i] = v
        end
        return true
    elseif param4 == 3 then --基础销量&基础好评
        self._EffectCoffees = {}
        self._EffectReviews = {}
        --最终销量
        for i, card in pairs(cards) do
            local v1 = isPercent and card:GetAddBasicCoffeeByPercent(value, isPreview) or value
            local v2 = isPercent and card:GetAddBasicReviewByPercent(value, isPreview) or value
            if isPreview then
                card:AddFinalCoffee(v1, isPreview)
                card:AddFinalReview(v2, isPreview)
            else
                battleInfo:ChangeCardForeverData(card:GetCardId(), true, v1)
                battleInfo:ChangeCardForeverData(card:GetCardId(), false, v2)
            end
            self._EffectCoffees[i] = v1
            self._EffectReviews[i] = v2
        end
        return true
    end
    return false
end

function XSGCafeResourceChangeForeverBuff:RemoveMotion()
    local param4 = self._Params[4]
    if XTool.IsTableEmpty(self._EffectCards) then
        return
    end
    local battleInfo = self._Model:GetBattleInfo()
    local cards = self._EffectCards
    if param4 == 1 then
        --基础销量
        for i, card in pairs(cards) do
            local value = self._EffectCoffees[i]
            battleInfo:ChangeCardForeverData(card:GetCardId(), true, -value)
        end
    elseif param4 == 2 then
        for i, card in pairs(cards) do
            local value = self._EffectReviews[i]
            battleInfo:ChangeCardForeverData(card:GetCardId(), false, -value)
        end
    elseif param4 == 3 then
        for i, card in pairs(cards) do
            local value1 = self._EffectCoffees[i]
            local value2 = self._EffectReviews[i]
            battleInfo:ChangeCardForeverData(card:GetCardId(), true, -value1)
            battleInfo:ChangeCardForeverData(card:GetCardId(), false, -value2)
        end
    end
end

function XSGCafeResourceChangeForeverBuff:AddBuffArgs()
    if not self._Card then
        return
    end
    local param4 = self._Params[4]
    if param4 == 1 then
        for _, value in pairs(self._EffectCoffees) do
            self._Card:AddBuffArgs(2001, value)
        end
    elseif param4 == 2 then
        for _, value in pairs(self._EffectReviews) do
            self._Card:AddBuffArgs(2002, value)
        end
    elseif param4 == 3 then
        for i, value in pairs(self._EffectCoffees) do
            self._Card:AddBuffArgs(2001, value)
            self._Card:AddBuffArgs(2002, self._EffectReviews[i])
        end
    end
end

function XSGCafeResourceChangeForeverBuff:GetBuffExportValue()
    local param4 = self._Params[4]
    if param4 == 1 then
        for _, value in pairs(self._EffectCoffees) do
           return value
        end
    elseif param4 == 2 then
        for _, value in pairs(self._EffectReviews) do
            return value
        end
    elseif param4 == 3 then
        for i, value in pairs(self._EffectCoffees) do
            return value
        end
    end
    return 0
end

return XSGCafeResourceChangeForeverBuff