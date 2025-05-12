local XSGCafeBuff = require("XModule/XSkyGardenCafe/Entity/Effect/XSGCafeBuff")

---@class XSGCafeResourceChangeBuff : XSGCafeBuff 卡牌的基础资源改变
local XSGCafeResourceChangeBuff = XClass(XSGCafeBuff, "XSGCafeResourceChangeBuff")

function XSGCafeResourceChangeBuff:OnAwake()
    self._LeftRound = self._Params[1] - 1
end

function XSGCafeResourceChangeBuff:ApplyMotion(isPreview)
    if self:TryAddNextRound() then
        return
    end
    local param2 = self._Params[2]
    local param4 = self._Params[4]
    local isPercent = self._Params[5] ~= 1
    local value = isPercent and self._Params[6] / 10000 or self._Params[6]
    ---@type XSkyGardenCafeCardEntity[]
    local cards = nil
    ---@type XSkyGardenCafeCardEntity[]
    local previewCards = nil
    --对卡牌自身生效
    if param2 == 1 then
        local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
        if isPreview then
            previewCards = { self._Card }
        else
            cards = { self._Card }
        end
    elseif param2 == 2 then
        --指定位置的卡
        local index = self._Params[3]
        local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
        if isPreview then
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
    elseif param2 == 3 then
        --指定位序的卡
        local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
        local currentIndex = roundEntity:GetDealCardIndexByCard(self._Card)
        if currentIndex < 0 then
            return
        end
        local index = currentIndex + self._Params[3]
        if isPreview and index == roundEntity:GetNextDealIndex() then
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
    elseif param2 == 4 then
        --指定卡
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
    elseif param2 == 5 then
        local battleInfo = self._Model:GetBattleInfo()
        if isPreview then
            if param4 == 1 or param4 == 3 then
                local changeScore = isPercent and battleInfo:GetAddScoreByPercent(value) or value
                self._Card:AddFinalCoffee(changeScore, true)

            elseif param4 == 2 or param4 == 4 then
                local changeReview = isPercent and battleInfo:GetAddReviewByPercent(value) or value
                self._Card:AddFinalReview(changeReview, true)

            elseif param4 == 5 or param4 == 6 then
                local changeScore = isPercent and battleInfo:GetAddScoreByPercent(value) or value
                local changeReview = isPercent and battleInfo:GetAddReviewByPercent(value) or value
                self._Card:AddFinalCoffee(changeScore, true)
                self._Card:AddFinalReview(changeReview, true)
            end
        else
            --玩家持有的资源
            local changeScore, changeReview
            if param4 == 1 or param4 == 3 then
                changeScore = isPercent and battleInfo:GetAddScoreByPercent(value) or value
                battleInfo:AddScore(changeScore)

            elseif param4 == 2 or param4 == 4 then
                changeReview = isPercent and battleInfo:GetAddReviewByPercent(value) or value
                battleInfo:AddReview(changeReview)

            elseif param4 == 5 or param4 == 6 then
                changeScore = isPercent and battleInfo:GetAddScoreByPercent(value) or value
                changeReview = isPercent and battleInfo:GetAddReviewByPercent(value) or value
                battleInfo:AddScore(changeScore)
                battleInfo:AddReview(changeReview)
            end
            self._ChangeScore = changeScore
            self._ChangeReview = changeReview
            --触发完直接结束
            self:AddEffectCount()
        end
        return
    elseif param2 == 6 then
        --当前手牌
        local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
        local cardEntities = roundEntity:GetDeckCardEntities()
        cards = {}
        for _, card in pairs(cardEntities) do
            cards[#cards + 1] = card
        end
    elseif param2 == 7 then
        local roundEntity = self._OwnControl:GetMainControl():GetRoundEntity()
        local cardEntities = roundEntity:GetDealCardEntities()
        cards = {}
        for _, card in pairs(cardEntities) do
            cards[#cards + 1] = card
        end
    end
    --先预览
    if self._PreviewCount < self._PreviewLayer and self:DoApplyByCards(previewCards, true) then
        self._PreviewCount = self._PreviewCount + 1
    end

    --再触发
    if self:DoApplyByCards(cards, false) then
        self:AddEffectCount()
    end
end

function XSGCafeResourceChangeBuff:PreviewApplyMotion()
    self:ApplyMotion(true)
end

---@param cards XSkyGardenCafeCardEntity[]
function XSGCafeResourceChangeBuff:DoApplyByCards(cards, isPreview)
    if XTool.IsTableEmpty(cards) then
        return false
    end
    local param4 = self._Params[4]
    local isPercent = self._Params[5] ~= 1
    local value = isPercent and self._Params[6] / 10000 or self._Params[6]
    if not isPreview then
        self._EffectCards = cards
    end
    if param4 == 1 then
        self._EffectCoffees = {}
        --基础销量
        for i, card in pairs(cards) do
            local v = isPercent and card:GetAddBasicCoffeeByPercent(value, isPreview) or value
            card:AddBasicCoffee(v, isPreview)
            self._EffectCoffees[i] = v
        end

        return true
    elseif param4 == 2 then
        self._EffectReviews = {}
        --基础好评
        for i, card in pairs(cards) do
            local v = isPercent and card:GetAddBasicReviewByPercent(value, isPreview) or value
            card:AddBasicReview(v, isPreview)
            self._EffectReviews[i] = v
        end

        return true
    elseif param4 == 3 then
        self._EffectCoffees = {}
        --最终销量
        for i, card in pairs(cards) do
            local v = isPercent and card:GetAddFinalCoffeeByPercent(value, isPreview) or value
            card:AddFinalCoffee(v, isPreview)
            self._EffectCoffees[i] = v
        end

        return true
    elseif param4 == 4 then
        self._EffectReviews = {}
        --最终好评
        for i, card in pairs(cards) do
            local v = isPercent and card:GetAddFinalReviewByPercent(value, isPreview) or value
            card:AddFinalReview(v, isPreview)
            self._EffectReviews[i] = v
        end

        return true
    elseif param4 == 5 then
        self._EffectCoffees = {}
        self._EffectReviews = {}
        --基础销量&基础好评
        for i, card in pairs(cards) do
            local v1 = isPercent and card:GetAddBasicCoffeeByPercent(value, isPreview) or value
            local v2 = isPercent and card:GetAddBasicReviewByPercent(value, isPreview) or value
            card:AddBasicCoffee(v1, isPreview)
            card:AddBasicReview(v2, isPreview)
            self._EffectCoffees[i] = v1
            self._EffectReviews[i] = v2
        end

        return true
    elseif param4 == 6 then
            self._EffectCoffees = {}
            self._EffectReviews = {}
        --最终销量&最终好评
        for i, card in pairs(cards) do
            local v1 = isPercent and card:GetAddFinalCoffeeByPercent(value, isPreview) or value
            local v2 = isPercent and card:GetAddFinalReviewByPercent(value, isPreview) or value
            card:AddFinalCoffee(v1, isPreview)
            card:AddFinalReview(v2, isPreview)
            self._EffectCoffees[i] = v1
            self._EffectReviews[i] = v2
        end

        return true
    end

    return false
end

function XSGCafeResourceChangeBuff:RemoveMotion()
    local param2 = self._Params[2]
    local param4 = self._Params[4]

    if param2 == 5 then
        --玩家持有的资源
        local battleInfo = self._Model:GetBattleInfo()
        if self._ChangeScore and self._ChangeScore ~= 0 then
            battleInfo:AddScore(-self._ChangeScore)
        end
        if self._ChangeReview and self._ChangeReview ~= 0 then
            battleInfo:AddReview(-self._ChangeReview)
        end
    else
        if XTool.IsTableEmpty(self._EffectCards) then
            return
        end
        local cards = self._EffectCards
        if param4 == 1 then
            --基础销量
            for i, card in pairs(cards) do
                local value = self._EffectCoffees[i]
                card:AddBasicCoffee(-value)
            end
        elseif param4 == 2 then
            --基础好评
            for i, card in pairs(cards) do
                local value = self._EffectReviews[i]
                card:AddBasicReview(-value)
            end
        elseif param4 == 3 then
            --最终销量
            for i, card in pairs(cards) do
                local value = self._EffectCoffees[i]
                card:AddFinalCoffee(-value)
            end
        elseif param4 == 4 then
            --最终好评
            for i, card in pairs(cards) do
                local value = self._EffectReviews[i]
                card:AddFinalReview(-value)
            end
        elseif param4 == 5 then
            --基础销量&基础好评
            for i, card in pairs(cards) do
                local value1 = self._EffectCoffees[i]
                local value2 = self._EffectReviews[i]
                card:AddBasicCoffee(-value1)
                card:AddBasicReview(-value2)
            end
        elseif param4 == 6 then
            --最终销量&最终好评
            for i, card in pairs(cards) do
                local value1 = self._EffectCoffees[i]
                local value2 = self._EffectReviews[i]
                card:AddFinalCoffee(-value1)
                card:AddFinalReview(-value2)
            end
        end
    end
end

function XSGCafeResourceChangeBuff:AddBuffArgs()
    if not self._Card then
        return
    end
    local param2 = self._Params[2]
    local param4 = self._Params[4]
    if param2 == 5 then
        if self._ChangeScore and self._ChangeScore ~= 0 then
            self._Card:AddBuffArgs(1001, self._ChangeScore)
        end
        if self._ChangeReview and self._ChangeReview ~= 0 then
            self._Card:AddBuffArgs(1002, self._ChangeReview)
        end
    else
        if param4 == 1 or param4 == 3 then
            if XTool.IsTableEmpty(self._EffectCoffees) then
                return
            end
            for _, value in pairs(self._EffectCoffees) do
                self._Card:AddBuffArgs(1001, value)
            end
        end

        if param4 == 2 or param4 == 4 then
            if XTool.IsTableEmpty(self._EffectReviews) then
                return
            end
            for _, value in pairs(self._EffectReviews) do
                self._Card:AddBuffArgs(1002, value)
            end
        end

        if param4 == 5 or param4 == 6 then
            if XTool.IsTableEmpty(self._EffectCoffees) then
                return
            end
            for i, value in pairs(self._EffectCoffees) do
                self._Card:AddBuffArgs(1001, value)
                self._Card:AddBuffArgs(1002, self._EffectReviews[i])
            end
        end
    end
end

function XSGCafeResourceChangeBuff:GetBuffExportValue()
    local param2 = self._Params[2]
    local param4 = self._Params[4]
    if param2 == 5 then
        if self._ChangeScore and self._ChangeScore ~= 0 then
            return self._ChangeScore
        end
        if self._ChangeReview and self._ChangeReview ~= 0 then
            return self._ChangeReview
        end
    else
        if param4 == 1 or param4 == 3 then
            if XTool.IsTableEmpty(self._EffectCoffees) then
                return 0
            end
            for _, value in pairs(self._EffectCoffees) do
                return value
            end
        end

        if param4 == 2 or param4 == 4 then
            if XTool.IsTableEmpty(self._EffectReviews) then
                return 0
            end
            for _, value in pairs(self._EffectReviews) do
                return value
            end
        end

        if param4 == 5 or param4 == 6 then
            if XTool.IsTableEmpty(self._EffectCoffees) then
                return
            end
            for i, value in pairs(self._EffectCoffees) do
                return value
            end
        end
    end
    return 0
end

return XSGCafeResourceChangeBuff