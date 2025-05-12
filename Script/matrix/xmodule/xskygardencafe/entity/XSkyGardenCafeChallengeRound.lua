local XSkyGardenCafeRound = require("XModule/XSkyGardenCafe/Entity/XSkyGardenCafeRound")

---@class XSkyGardenCafeChallengeRound : XSkyGardenCafeRound
local XSkyGardenCafeChallengeRound = XClass(XSkyGardenCafeRound, "XSkyGardenCafeChallengeRound")

function XSkyGardenCafeChallengeRound:IsStory()
    return false
end

function XSkyGardenCafeChallengeRound:OnEnter(stageId, deckId)
    local battleInfo = self._Model:GetBattleInfo()
    if not deckId or deckId <= 0 then
        deckId = battleInfo:GetDeckId()
    end
    
    if not deckId or deckId <= 0 then
        self._OwnControl:GetMainControl():OpenHandBook(XMVCA.XSkyGardenCafe.UIType.DeckEditor, stageId)
        return
    end

    if not XMVCA.XSkyGardenCafe:IsEnterLevel() then
        self._OwnControl:GetMainControl():SetFightData(stageId, deckId)
        XMVCA.XSkyGardenCafe:EnterGameLevel()
        return
    end
    
    self._OwnControl:BeforeFight()
    self._DeckId = deckId
    self._OwnControl:OpenBattleView(deckId)
    --self:StartPatrolTimer()
end

function XSkyGardenCafeChallengeRound:InitBattleInfo()
    local battleInfo = self._Model:GetBattleInfo()
    local stageId = self._StageId
    local cardIdList = self._Model:GetCardDeck(self._DeckId):GetCardsPool()
    --随机打乱
    cardIdList = XTool.RandomArray(cardIdList, os.time(), true)
    --创建牌组
    self:InitLibCards(cardIdList)
    
    battleInfo:InitBattleInfo({
        StageId = stageId,
        Round = 1,
        ActPoint = self._Model:GetActPoint(stageId),
        Review = self._Model:GetStageInitReview(stageId),
        DeckCount = self._Model:GetMaxCustomer(stageId),
        CardGroupId = self:GetDeckId()
    })
end

function XSkyGardenCafeChallengeRound:GetDeckId()
    return self._DeckId
end

return XSkyGardenCafeChallengeRound