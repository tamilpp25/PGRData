local XSkyGardenCafeConfig = require("XModule/XSkyGardenCafe/XSkyGardenCafeConfig")

local XSGCafeStage
local XSGCafeDeck
local XSGCafeBattle

local pairs = pairs

---@class XSkyGardenCafeModel : XSkyGardenCafeConfig
---@field _StageInfo table<number, XSGCafeStage>
---@field _CardDecks table<number, XSGCafeDeck>
---@field _OwnCards XSGCafeDeck
---@field _BattleInfo XSGCafeBattle
local XSkyGardenCafeModel = XClass(XSkyGardenCafeConfig, "XSkyGardenCafeModel")
function XSkyGardenCafeModel:OnInit()
    XSkyGardenCafeConfig.OnInit(self)
    -- 活动数据
    self._ActivityId = 1

    self:Reset()
end

function XSkyGardenCafeModel:ClearPrivate()
    XSkyGardenCafeConfig.ClearPrivate(self)
    self._Cookies = false
end

function XSkyGardenCafeModel:ResetAll()
    XSkyGardenCafeConfig.ResetAll(self)
    self:Reset()
end

function XSkyGardenCafeModel:Reset()
    --关卡数据
    self._StageInfo = {}
    self._TotalChallengeStar = false
    self._EndlessStageId = false

    --卡组&卡牌
    self._CardDecks = {}
    self._SelectDeckId = 1
    self._OwnCards = false

    --对局信息
    self._BattleInfo = false
    
    self._LeftPatrol = nil
    self._LeftPosition = nil
    
    --缓存Key
    self._Cookies = false
    
    self._FightData = nil
end

function XSkyGardenCafeModel:IsOpen()
    if not self._ActivityId or self._ActivityId <= 0 then
        return false
    end
    local timeId = self:GetActivityTimeId(self._ActivityId)
    if timeId and timeId > 0 then
        if not XFunctionManager.CheckInTimeByTimeId(timeId, false) then
            return false
        end
    end
    
    return true
end

function XSkyGardenCafeModel:GetActivityName()
    local t = self:GetActivityTemplate(self._ActivityId)
    return t and t.Name or ""
end

function XSkyGardenCafeModel:GetStoryStageIds()
    local storyChapterId = self:GetStoryChapterId(self._ActivityId)
    return self:GetChapterStageIds(storyChapterId)
end

function XSkyGardenCafeModel:GetChallengeStageIds()
    local challengeChapterId = self:GetChallengeChapterId(self._ActivityId)
    return self:GetChapterStageIds(challengeChapterId)
end

function XSkyGardenCafeModel:GetTotalChallengeStar()
    if self._TotalChallengeStar then
        return self._TotalChallengeStar
    end
    local stageIds = self:GetChallengeStageIds()
    local star = 0
    for _, stageId in pairs(stageIds) do
        local target = self:GetStageTarget(stageId)
        local count = target and #target or 0
        star = star + count
    end
    self._TotalChallengeStar = star
    
    return star
end

---@return XSGCafeStage
function XSkyGardenCafeModel:GetStageInfo(stageId)
    local info = self._StageInfo[stageId]
    if not info then
        if not XSGCafeStage then
            XSGCafeStage = require("XModule/XSkyGardenCafe/Data/XSGCafeStage")
        end
        info = XSGCafeStage.New(stageId)
        self._StageInfo[stageId] = info
    end
    return info
end

function XSkyGardenCafeModel:InitStageInfo(stageList)
    if not stageList then
        return
    end
    for _, stageInfo in pairs(stageList) do
        self:UpdateStageInfo(stageInfo)
    end
end

function XSkyGardenCafeModel:UpdateStageInfo(stageInfo)
    if not stageInfo then
        return
    end
    local stageId = stageInfo.StageId
    if not stageId or stageId <= 0 then
        return
    end
    local info = self:GetStageInfo(stageId)
    info:UpdateData(stageInfo)
end

function XSkyGardenCafeModel:GetEndlessStageId()
    if self._EndlessStageId then
        return self._EndlessStageId
    end
    local stageIds = self:GetChallengeStageIds()
    for _, stageId in pairs(stageIds) do
        if self:IsEndlessChallengeStage(stageId) then
            self._EndlessStageId = stageId
            break
        end
    end
    return self._EndlessStageId
end

--- 获取卡组信息
---@param deckId number 卡组Id  
---@return XSGCafeDeck
--------------------------
function XSkyGardenCafeModel:GetCardDeck(deckId)
    local deck = self._CardDecks[deckId]
    if deck then
        return deck
    end

    if not XSGCafeDeck then
        XSGCafeDeck = require("XModule/XSkyGardenCafe/Data/XSGCafeDeck")
    end
    deck = XSGCafeDeck.New(deckId, true)
    self._CardDecks[deckId] = deck
    
    return deck
end

--- 更新卡组信息
--------------------------
function XSkyGardenCafeModel:UpdateCardDeck(cardGroupDict, isInit)
    if not cardGroupDict then
        return
    end
    local initDict
    if isInit then
        initDict = {}
    end
    for deckId, cardList in pairs(cardGroupDict) do
        local deck = self:GetCardDeck(deckId)
        if initDict then
            initDict[deckId] = true
        end
        for _, cardId in pairs(cardList) do
            deck:Insert(cardId)
        end
        deck:Sync()
    end

    if isInit then
        self:InitCardDeckByPreset(initDict)
    end
end

function XSkyGardenCafeModel:InitCardDeckByPreset(initDict)
    local list = XMVCA.XSkyGardenCafe.DeckIds
    for _, deckId in pairs(list) do
        if initDict and not initDict[deckId] then
            local deck = self:GetCardDeck(deckId)
            local ids = self:GetPresetCustomerIds(deckId)
            for _, cardId in pairs(ids) do
                deck:Insert(cardId)
            end
            deck:Sync()
        end
    end
end

--- 获取已有牌组
---@return XSGCafeDeck
--------------------------
function XSkyGardenCafeModel:GetOwnCardDeck()
    if self._OwnCards then
        return self._OwnCards
    end
    if not XSGCafeDeck then
        XSGCafeDeck = require("XModule/XSkyGardenCafe/Data/XSGCafeDeck")
    end
    self._OwnCards = XSGCafeDeck.New(-1, false)
    
    return self._OwnCards
end

function XSkyGardenCafeModel:UpdateOwnCardDeck(cardDict)
    if not cardDict then
        return
    end
    local deck = self:GetOwnCardDeck()
    deck:UpdateCards(cardDict)
end

function XSkyGardenCafeModel:CheckCardUnlock(cardId)
    local deck = self:GetOwnCardDeck()
    local card = deck:GetOrAddCard(cardId)
    return card:IsUnlock()
end

function XSkyGardenCafeModel:GetSelectDeckId()
    return self._SelectDeckId
end

function XSkyGardenCafeModel:SetSelectDeckId(id)
    self._SelectDeckId = id
end

function XSkyGardenCafeModel:SetFightData(stageId, deckId)
    if not self._FightData then
        self._FightData = {
            StageId = 0,
            DeckId = 0
        }
    end
    self._FightData.StageId = stageId
    self._FightData.DeckId = deckId or 0
end

function XSkyGardenCafeModel:GetFightData()
    return self._FightData
end

function XSkyGardenCafeModel:UpdateBattle(battleInfo)
    if not battleInfo then
        return
    end
    local stageId = battleInfo.StageId
    if not stageId or stageId <= 0 then
        return
    end
    local info = self:GetBattleInfo()
    info:SetDeckCount(self:GetMaxCustomer(stageId))
    info:UpdateData(battleInfo)
end

---@return XSGCafeBattle
function XSkyGardenCafeModel:GetBattleInfo()
    if not self._BattleInfo then
        if not XSGCafeBattle then
            XSGCafeBattle = require("XModule/XSkyGardenCafe/Data/XSGCafeBattle")
        end
        self._BattleInfo = XSGCafeBattle.New()
    end
    return self._BattleInfo 
end

function XSkyGardenCafeModel:RandomPosId()
    local allIds = self:GetAllPositionIds()
    local total = #allIds
    local left = self._LeftPosition or total
    math.randomseed(os.time())
    local index = math.random(1, left)
    local id = allIds[index]
    --随机之后，跟当前最后一个进行交换
    allIds[index], allIds[left] = allIds[left], allIds[index]
    left = left - 1
    if left <= 0 then
        allIds[1], allIds[total] = allIds[total], allIds[1]
        left = total - 1
    end
    self._LeftPosition = left
    
    return id
end

function XSkyGardenCafeModel:RandomRouteId()
    local allIds = self:GetAllPatrolIds()
    local total = #allIds
    local left = self._LeftPatrol or total
    math.randomseed(os.time())
    local index = math.random(1, left)
    local id = allIds[index]
    --随机之后，跟当前最后一个进行交换
    allIds[index], allIds[left] = allIds[left], allIds[index]
    left = left - 1
    if left <= 0 then
        allIds[1], allIds[total] = allIds[total], allIds[1]
        left = total - 1
    end
    self._LeftPatrol = left

    return id
end

function XSkyGardenCafeModel:GetCookies(key)
    if self._Cookies and self._Cookies[key] then
        return self._Cookies[key]
    end
    local finalKey = string.format("SKY_GARDEN_CAFE_%s_%s_%s", self._ActivityId, XPlayer.Id, key)
    if not self._Cookies then
        self._Cookies = {}
    end
    self._Cookies[key] = finalKey
    
    return finalKey
end

return XSkyGardenCafeModel