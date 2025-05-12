---@class XSGCafeBattle 对局信息
local XSGCafeBattle = XClass(nil, "XSGCafeBattle")

function XSGCafeBattle:Ctor()
   self:Reset()
end

function XSGCafeBattle:UpdateData(battleInfo)
    if not battleInfo then
        return
    end
    self._StageId = battleInfo.StageId or 0
    self._Round = battleInfo.Round or 1
    self._Score = battleInfo.SumSales or 0
    self._ActPoint = battleInfo.ActPoint or 0
    self._Review = battleInfo.ReviewNum or 0
    self._DeckCards = battleInfo.HandCards or {}
    self._LibCards = battleInfo.CardsWarehouse or {}
    self._AbandonCards = battleInfo.AbandonCards or {}
    self:TranslateListToBoolTable(self._PrecedeCard, battleInfo.PriorityCard)
    self:TranslateListToBoolTable(self._StayInHandCard, battleInfo.RetainHandCard)
    self._CardUseCount = battleInfo.UseCardTimes or {}
    self._CardForeverValue = battleInfo.BuffAdditionDict or {}
    self._DeckId = battleInfo.CardGroupId or 0
    
    
    self:ResetWhenDataSync()
end

function XSGCafeBattle:InitBattleInfo(battleInfo)
    self:Reset()
    
    self._StageId = battleInfo.StageId
    self._Round = battleInfo.Round
    self._ActPoint = battleInfo.ActPoint
    self._Review = battleInfo.Review
    self._AbandonCards = {}
    self._DeckCount = battleInfo.DeckCount
    self._DeckId = battleInfo.CardGroupId or 0
end

function XSGCafeBattle:SetDeckCount(count)
    self._DeckCount = count
end

function XSGCafeBattle:DoSettle(score, rewardIds)
    self._Score = score
    self._RewardIds = rewardIds
end

function XSGCafeBattle:Reset()
    --销量
    self._Score = 0
    --关卡Id
    self._StageId = 0
    --回合
    self._Round = 1
    --好评
    self._Review = 0
    --卡牌槽
    self._ActPoint = 0
    --手牌数
    self._DeckCount = 0
    --手牌卡牌
    self._DeckCards = false
    --出牌卡牌
    self._DealCards = false
    --牌库
    self._LibCards = false
    --弃牌
    self._AbandonCards = false

    --增加销量
    self._AddScore = 0
    self._AddCardScore = 0
    --增加好评
    self._AddReview = 0
    self._AddCardReview = 0
    --增加卡槽位
    self._AddActPoint = 0
    --增加手牌数
    self._AddDeckCount = 0
    
    self._RewardIds = false
    
    --优先抽卡
    self._PrecedeCard = {}
    --保留手牌
    self._StayInHandCard = {}
    --禁用卡牌（无法再抽取到）
    self._BanCards = {}
    
    --卡牌使用次数
    self._CardUseCount = {}
    --卡牌永久修改的
    self._CardForeverValue = {}

    self._DeckId = 0
end

function XSGCafeBattle:ResetWhenDataSync()
    self._AddActPoint = 0
    self._AddReview = 0
    self._AddScore = 0

    self:ResetAddCardReview()
    self:ResetAddCardScore()
end

function XSGCafeBattle:GetStageId()
    return self._StageId
end

function XSGCafeBattle:GetDeckId()
    return self._DeckId
end

--- 获取回合数
---@return number
function XSGCafeBattle:GetRound()
    return self._Round
end

--- 下个回合
function XSGCafeBattle:NextRound()
    self._Round = self._Round + 1
end

--- 上个回合的分数
---@return number
function XSGCafeBattle:GetScore()
    return self._Score
end

--- 上个回合加上本回合的总分数
---@return number
function XSGCafeBattle:GetTotalScore()
    return math.max(0,  self._Score + self:GetAddScore())
end

--- 本回合加成分数
---@return number
function XSGCafeBattle:GetAddScore()
    return self._AddScore + self._AddCardScore
end

function XSGCafeBattle:GetAddScoreByPercent(percent)
    local oldValue = self:GetTotalScore()
    return XMVCA.XSkyGardenCafe:GetChangeValueByPercent(oldValue, percent)
end

--- 增加Buff直接加成分数
---@param value number
function XSGCafeBattle:AddScore(value)
    self._AddScore = self._AddScore + value
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_APPLY_BUFF, XMVCA.XSkyGardenCafe.EffectTriggerId.RoundResourceChanged)
end

--- 增加卡牌加成分数
---@param value number
function XSGCafeBattle:AddCardScore(value)
    self._AddCardScore = math.max(0, self._AddCardScore + value)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_APPLY_BUFF, XMVCA.XSkyGardenCafe.EffectTriggerId.RoundResourceChanged)
end

--- 重置卡牌加成分数
function XSGCafeBattle:ResetAddCardScore()
    self._AddCardScore = 0
end

--- 上个回合的好感
---@return number
function XSGCafeBattle:GetReview()
    return self._Review
end

--- 本回合加成好感
---@return number
function XSGCafeBattle:GetAddReview()
    return self._AddReview + self._AddCardReview
end

--- 上个回合加上本回合的总好感
---@return number
function XSGCafeBattle:GetTotalReview()
    return math.max(0,  self._Review + self:GetAddReview())
end

function XSGCafeBattle:GetAddReviewByPercent(percent)
    local oldValue = self:GetTotalReview()
    return XMVCA.XSkyGardenCafe:GetChangeValueByPercent(oldValue, percent)
end

--- 增加Buff直接加成好感
---@param value number
function XSGCafeBattle:AddReview(value)
    self._AddReview = self._AddReview + value
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_APPLY_BUFF, XMVCA.XSkyGardenCafe.EffectTriggerId.RoundResourceChanged)
end

--- 增加卡牌加成好感
---@param value number
function XSGCafeBattle:AddCardReview(value)
    self._AddCardReview = self._AddCardReview + value
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_APPLY_BUFF, XMVCA.XSkyGardenCafe.EffectTriggerId.RoundResourceChanged)
end

--- 重置卡牌加成好感
function XSGCafeBattle:ResetAddCardReview()
    self._AddCardReview = 0
end

function XSGCafeBattle:GetRewardIds()
    return self._RewardIds
end

function XSGCafeBattle:GetDeckCards()
    return self._DeckCards
end

function XSGCafeBattle:GetLibCards()
    return self._LibCards
end

function XSGCafeBattle:GetDeckLimit(max)
    return math.min(max, self._DeckCount + self._AddDeckCount)
end

function XSGCafeBattle:AddDeckCount(count)
    self._AddDeckCount = self._AddDeckCount + count
end

function XSGCafeBattle:GetDealLimit()
    return self._ActPoint + self._AddActPoint
end

function XSGCafeBattle:AddDealCount(count)
    self._AddActPoint = self._AddActPoint + count
end

function XSGCafeBattle:SyncAbandonCards(cards, isAppend)
    if isAppend then
        self._AbandonCards = XTool.MergeArray(self._AbandonCards, cards)
    else
        self._AbandonCards = cards or {}
    end
end

function XSGCafeBattle:GetAbandonCards()
    return self._AbandonCards
end
--region Buff数据

function XSGCafeBattle:InsertPrecede(cardId)
    self._PrecedeCard[cardId] = true
end

function XSGCafeBattle:RemovePrecede(cardId)
    self._PrecedeCard[cardId] = nil
end

function XSGCafeBattle:IsPrecede(cardId)
    return self._PrecedeCard[cardId] ~= nil
end

function XSGCafeBattle:GetPrecedeCards()
    local list = {}
    for id, _ in pairs(self._PrecedeCard) do
        list[#list + 1] = id
    end
    return list
end

function XSGCafeBattle:InsertStayInHand(cardId)
    self._StayInHandCard[cardId] = true 
end

function XSGCafeBattle:RemoveStayInHand(cardId)
    self._StayInHandCard[cardId] = nil
end

function XSGCafeBattle:IsStayInHand(cardId)
    return self._StayInHandCard[cardId] ~= nil
end

function XSGCafeBattle:GetStayInHandCards()
    local list = {}
    for id, _ in pairs(self._StayInHandCard) do
        list[#list + 1] = id
    end
    return list
end

function XSGCafeBattle:InsertBanCard(cardId)
    self._BanCards[cardId] = true
end

function XSGCafeBattle:RemoveBanCard(cardId)
    self._BanCards[cardId] = nil
end

function XSGCafeBattle:IsBanCard(cardId)
    return self._BanCards[cardId] ~= nil
end

function XSGCafeBattle:GetBanCards()
    local list = {}
    for id, _ in pairs(self._BanCards) do
        list[#list + 1] = id
    end
    return list
end

function XSGCafeBattle:GetCardUseCount(cardId)
    local count = self._CardUseCount[cardId]
    return count or 0
end

function XSGCafeBattle:AddCardUseCount(cardId)
    local count = self._CardUseCount[cardId] or 0
    self._CardUseCount[cardId] = count + 1
end

function XSGCafeBattle:GetCardUseCountDict()
    return self._CardUseCount
end

function XSGCafeBattle:ChangeCardForeverData(cardId, isCoffee, value)
    local data = self._CardForeverValue[cardId]
    if not data then
        data = {
            Coffee = 0,
            Review = 0
        }
        self._CardForeverValue[cardId] = data
    end
    if isCoffee then
        data.Coffee = math.max(0, data.Coffee + value)
    else
        data.Review =  math.max(0, data.Review + value)
    end
end

function XSGCafeBattle:GetCardForeverData(cardId, isCoffee)
    local data = self._CardForeverValue[cardId]
    if not data then
        return 0
    end
    local value
    if isCoffee then
        value = data.Coffee
    else
        value = data.Review
    end
    if not value then
        value = 0
    end
    return value
end

function XSGCafeBattle:GetCardForeverDict()
    return self._CardForeverValue
end

function XSGCafeBattle:TranslateListToBoolTable(tb, list)
    if XTool.IsTableEmpty(list) then
        tb = {}
        return
    end
    tb = {}
    for _, id in pairs(list) do
        tb[id] = true
    end
end

--endregion Buff数据

return XSGCafeBattle