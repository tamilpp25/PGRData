---@class XSkyGardenCafeRound : XEntity 回合控制
---@field _Model XSkyGardenCafeModel
---@field _OwnControl XSkyGardenCafeBattle
---@field _PoolEntities XSkyGardenCafeCardEntity[]
---@field _DeckEntities XSkyGardenCafeCardEntity[]
---@field _DealEntities XSkyGardenCafeCardEntity[]
---@field _ReDrawEntities XSkyGardenCafeCardEntity[]
---@field _RoundBeforeCardEntities XSkyGardenCafeCardEntity[]
local XSkyGardenCafeRound = XClass(XEntity, "XSkyGardenCafeRound")

local tableInsert = table.insert
local tableRemove = table.remove
local tableRange = table.range
local tableSort = table.sort

local DlcEventId = XMVCA.XBigWorldService.DlcEventId
local EffectTriggerId = XMVCA.XSkyGardenCafe.EffectTriggerId
local DrawCardType = XMVCA.XSkyGardenCafe.DrawCardType

local RoundState = {
    None = 0,
    RoundBeginBefore = 1,
    RoundBeginAfter = 2,
    RoundEndBefore = 3,
    RoundEndAfter = 4,
}

function XSkyGardenCafeRound:OnInit()
    self:ResetData()
    XEventManager.AddEventListener(DlcEventId.EVENT_CAFE_APPLY_BUFF, self.OnEventApplyBuff, self)
end

function XSkyGardenCafeRound:ResetData()
    --关卡
    self._StageId = 0
    --牌组
    self._PoolEntities = {}
    --手牌组
    self._DeckEntities = {}
    --出牌组
    self._DealEntities = {}
    --重抽组
    self._ReDrawEntities = {}
    --抽卡前的卡
    self._RoundBeforeCardEntities = {}
    --选中的需要重抽卡牌的位置
    self._ReDrawSelectIndex = {}
    --巡逻时间间隔
    self._PatrolInterval = self._Model:GetPatrolInterval() * XScheduleManager.SECOND
    --状态
    self._RoundState = RoundState.None
    --下个席位下标
    self._NextDealIndex = 1
    --最大席位下标
    self._MaxDealIndex = self._Model:GetMaxDeckCount()

    ---@param cardA XSkyGardenCafeCardEntity
    ---@param cardB XSkyGardenCafeCardEntity
    self._SortCardFunc = function(cardA, cardB)
        local idA = cardA:GetCardId()
        local idB = cardB:GetCardId()
        local isZeroA = idA <= 0
        local isZeroB = idB <= 0
        if isZeroA ~= isZeroB then
            return isZeroB
        end
        local qA = self._Model:GetCustomerQuality(idA)
        local qB = self._Model:GetCustomerQuality(idB)
        if qA ~= qB then
            return qA > qB
        end
        local pA = self._Model:GetCustomerPriority(idA)
        local pB = self._Model:GetCustomerPriority(idB)
        if pA ~= pB then
            return pA > pB
        end
        return idA > idB
    end
end

function XSkyGardenCafeRound:OnRelease()
    XEventManager.RemoveEventListener(DlcEventId.EVENT_CAFE_APPLY_BUFF, self.OnEventApplyBuff, self)
end

--- 随机打乱数组
---@param list XSkyGardenCafeCardEntity[]
---@param count number
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:RandomCards(list, count)
    if XTool.IsTableEmpty(list) then
        return
    end
    --不用随机了
    if #list <= count then
        return tableRange(list, 1, #list)
    end
    local precede, normal = self:GetDifferentPriorityCards(list, count)

    local subCount = count - #precede

    --优先抽卡 == 需要抽卡数
    if subCount == 0 then
        return precede
    end
    math.randomseed(os.time())
    --优先抽卡数量不足, 从普通池里随机subCount个
    if subCount > 0 then
        local subList = {}
        for idx = 1, subCount do
            local i = math.random(1, #normal)
            subList[idx] = normal[i]
            tableRemove(normal, i)
        end
        return XTool.MergeArray(precede, subList)
    end
    --优先抽卡数量已经足够
    local subList = {}
    for idx = 1, count do
        local i = math.random(1, #precede)
        subList[idx] = precede[i]
        tableRemove(precede, i)
    end
    return subList
end

--- 顺序抽卡
---@param count number 抽取数量
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:SequenceCards(count)
    if count <= 0 then
        return
    end
    --剩余卡数量
    local restCount = #self._PoolEntities

    --牌不够抽了
    if restCount < count then
        self:ReEnterPoolCards()
        restCount = #self._PoolEntities
    end

    if restCount < count then
        local log = string.format("抽卡异常：剩余卡牌（%d）, 需要抽取的卡牌（%d）", restCount, count)
        XLog.Error(log)
        count = restCount
    end
    local precede, normal = self:GetDifferentPriorityCards(self._PoolEntities, count)
    --跟优先抽卡的数量差距
    local subCount = count - #precede

    --优先抽卡 == 需要抽卡数
    if subCount == 0 then
        return precede
    end
    --优先抽卡数量不足, 从普通池里抽subCount个
    if subCount > 0 then
        for index = 1, subCount do
            precede[#precede + 1] = normal[index]
        end

        return precede
    end

    return tableRange(precede, 1, count)
end

--- 获取不同优先级卡组
---@param list XSkyGardenCafeCardEntity[]
---@param count number
---@return XSkyGardenCafeCardEntity[], XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetDifferentPriorityCards(list, count)
    if XTool.IsTableEmpty(list) or count <= 0 then
        return
    end
    ---@type XSkyGardenCafeCardEntity[]
    local precede = {}
    ---@type XSkyGardenCafeCardEntity[]
    local normal = {}
    local battleInfo = self._Model:GetBattleInfo()
    for _, card in pairs(list) do
        if battleInfo:IsPrecede(card:GetCardId()) then
            precede[#precede + 1] = card
        else
            normal[#normal + 1] = card
        end
    end

    return precede, normal
end

--- 弃牌堆重新进入牌堆
function XSkyGardenCafeRound:ReEnterPoolCards()
    local battleInfo = self._Model:GetBattleInfo()
    local abandonIds = battleInfo:GetAbandonCards()
    if XTool.IsTableEmpty(abandonIds) then
        return
    end
    local factory = self._OwnControl:GetCardFactory()
    for _, cardId in pairs(abandonIds) do
        local card = factory:CreateCard(cardId)
        self._PoolEntities[#self._PoolEntities + 1] = card
    end
    battleInfo:SyncAbandonCards({}, false)
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
end

--- 是否为剧情回合控制器
---@return boolean
--------------------------
function XSkyGardenCafeRound:IsStory()
    return false
end

function XSkyGardenCafeRound:StartPatrolTimer()
    if self._PatrolTimer then
        return
    end
    self._PatrolTimer = XScheduleManager.ScheduleForever(function()
        XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAFE_RANDOM_START_PATROL_NPC)
    end, self._PatrolInterval)
end

function XSkyGardenCafeRound:StopPatrolTimer()
    if not self._PatrolTimer then
        return
    end
    XScheduleManager.UnSchedule(self._PatrolTimer)
    self._PatrolTimer = nil
end

function XSkyGardenCafeRound:DoRoundBegin(isContinue)
    self._RoundState = RoundState.RoundBeginBefore
    self:OnRoundBegin()
    self:ApplyBuffRoundBefore()
    local battleInfo = self._Model:GetBattleInfo()
    if not isContinue then
        if battleInfo:GetRound() == 1 and self._Model:IsReDrawStage(self._StageId) then
            self:ReDraw()
        else
            self:LibToDeck()
        end
    else
        tableSort(self._DeckEntities, self._SortCardFunc)
        self:DoLibToDeckPerformance(#self._DeckEntities)
    end
    self._RoundState = RoundState.RoundBeginAfter
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_ROUND_BEGIN)
end

function XSkyGardenCafeRound:DoRoundEnd()
    self._RoundState = RoundState.RoundEndBefore
    local battleInfo = self._Model:GetBattleInfo()
    --触发回合Buff
    self._OwnControl:ApplyStageBuff(EffectTriggerId.RoundEnd)
    --弃牌堆
    local abandon = {}
    --触发回合改变(弃牌前)
    for _, card in pairs(self._DealEntities) do
        card:ApplyBuff(EffectTriggerId.RoundEnd)
    end
    --弃掉所有出牌区卡牌
    self:ClearAllDealCards(abandon)
    --触发手牌Buff
    for i = #self._DeckEntities, 1, -1 do
        local card = self._DeckEntities[i]
        --触发未使用的Buff
        card:ApplyBuff(EffectTriggerId.KeepInDeck)
        card:ApplyBuff(EffectTriggerId.RoundEnd)
    end
    local removeIndex = self:DiscardDeckCard(abandon)
    self._OwnControl:Deal2Pool()
    self._OwnControl:Deck2Pool(removeIndex)
    --放入弃牌堆 
    battleInfo:SyncAbandonCards(abandon, true)
    self._OwnControl:SyncNextRoundBuff()
    battleInfo:NextRound()
    self:OnRoundEnd()
    self._RoundState = RoundState.RoundEndAfter
end

function XSkyGardenCafeRound:DoRequestRoundChange(cb)
    local serverData = self._OwnControl:ToServerData()
    local req = {
        CafeGambling = serverData
    }
    local tarRound = self._Model:GetStageRounds(self._StageId)
    XNetwork.Call("BigWorldCafeNextRoundRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end
        self._Model:GetBattleInfo():UpdateData(serverData)
        local round = self._Model:GetBattleInfo():GetRound()
        local isEnd = round > tarRound

        self._OwnControl:ChangeRoundSettle(false)
        if cb then
            cb()
        end
        if not isEnd then
            self._OwnControl:GetMainControl():PopupBroadcast()
            XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_ROUND_BEGIN)
        end
    end)
end

function XSkyGardenCafeRound:DoEnter(stageId, deckId)
    self._StageId = stageId
    self:OnEnter(stageId, deckId)
end

function XSkyGardenCafeRound:InitBattleInfo()
end

function XSkyGardenCafeRound:InitBattleInfoByServer()
    local battleInfo = self._Model:GetBattleInfo()
    local libIds = battleInfo:GetLibCards()
    self:InitLibCards(libIds)
    local deckIds = battleInfo:GetDeckCards()
    self:InitDeckCards(deckIds)
end

function XSkyGardenCafeRound:InitLibCards(cardIdList)
    if XTool.IsTableEmpty(cardIdList) then
        return
    end
    local factory = self._OwnControl:GetCardFactory()
    for _, cardId in pairs(cardIdList) do
        local card = factory:CreateCard(cardId)
        self._PoolEntities[#self._PoolEntities + 1] = card
    end
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
end

function XSkyGardenCafeRound:ClearAllLibCards()
    if XTool.IsTableEmpty(self._PoolEntities) then
        return
    end
    local factory = self._OwnControl:GetCardFactory()
    for _, card in pairs(self._PoolEntities) do
        factory:RemoveEntity(card)
    end
    self._PoolEntities = {}
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
end

function XSkyGardenCafeRound:InitDeckCards(cardIdList)
    if XTool.IsTableEmpty(cardIdList) then
        return
    end
    local factory = self._OwnControl:GetCardFactory()
    for _, cardId in pairs(cardIdList) do
        local card = factory:CreateCard(cardId)
        self._DeckEntities[#self._DeckEntities + 1] = card
    end
end

function XSkyGardenCafeRound:ClearAllDealCards(abandon)
    if XTool.IsTableEmpty(self._DealEntities) then
        return
    end
    local factory = self._OwnControl:GetCardFactory()
    local battleInfo = self._Model:GetBattleInfo()
    for _, card in pairs(self._DealEntities) do
        local id = card:GetCardId()
        if not battleInfo:IsBanCard(id) then
            abandon[#abandon + 1] = id
        end
        factory:RemoveEntity(card)
    end
    self._DealEntities = {}
    self:UpdateDealIndex()
end

function XSkyGardenCafeRound:DiscardDeckCard(abandon)
    if XTool.IsTableEmpty(self._DeckEntities) then
        return
    end
    local removeIndex = {}
    local battleInfo = self._Model:GetBattleInfo()
    local factory = self._OwnControl:GetCardFactory()
    for i = #self._DeckEntities, 1, -1 do
        local card = self._DeckEntities[i]
        local cardId = card:GetCardId()
        local isBanCard = battleInfo:IsBanCard(cardId)
        --不保留在手上
        if not battleInfo:IsStayInHand(cardId) or isBanCard then
            card:ApplyBuff(EffectTriggerId.Discard)
            if not isBanCard then
                --弃牌堆
                abandon[#abandon + 1] = cardId
            end
            removeIndex[#removeIndex + 1] = i - 1
            --移除
            tableRemove(self._DeckEntities, i)
            factory:RemoveEntity(card)
        end
    end
    return removeIndex
end

function XSkyGardenCafeRound:GetDeckCardIds()
    local list = {}
    for _, card in pairs(self._DeckEntities) do
        list[#list + 1] = card:GetCardId()
    end
    return list
end

function XSkyGardenCafeRound:GetDealCardIds()
    local list = {}
    for _, card in pairs(self._DealEntities) do
        list[#list + 1] = card:GetCardId()
    end
    return list
end

function XSkyGardenCafeRound:GetLibCardIds()
    local list = {}
    for _, card in pairs(self._PoolEntities) do
        list[#list + 1] = card:GetCardId()
    end
    return list
end

function XSkyGardenCafeRound:GetDeckCardEntities()
    return self._DeckEntities
end

function XSkyGardenCafeRound:GetDealCardEntities()
    return self._DealEntities
end

function XSkyGardenCafeRound:GetReDrawCardEntities()
    return self._ReDrawEntities
end

--- 获取牌组卡牌，切记不要修改卡组内容与顺序
---@return
function XSkyGardenCafeRound:GetPoolEntities()
    return self._PoolEntities
end

function XSkyGardenCafeRound:GetDealCardIndexByCard(card)
    if not card then
        return -1
    end
    if XTool.IsTableEmpty(self._DealEntities) then
        return -1
    end
    for index, entity in pairs(self._DealEntities) do
        if entity == card then
            return index
        end
    end
    return -1
end

--- 根据卡牌Id获取卡牌，如果有相同卡牌，只能取到第一个
---@param cardId number
---@return number
function XSkyGardenCafeRound:GetDealCardIndexByCardId(cardId)
    if not cardId or cardId < 0 then
        return -1
    end
    if XTool.IsTableEmpty(self._DealEntities) then
        return -1
    end
    for index, entity in pairs(self._DealEntities) do
        if entity:GetCardId() == cardId then
            return index
        end
    end
    return -1
end

function XSkyGardenCafeRound:GetDeckCount()
    return #self._DeckEntities
end

function XSkyGardenCafeRound:GetRestDeckCount()
    local limit = self._Model:GetBattleInfo():GetDeckLimit(self._Model:GetMaxDeckCount())
    return limit - #self._DeckEntities
end

function XSkyGardenCafeRound:GetRestDealCount()
    local limit = self._Model:GetBattleInfo():GetDealLimit()
    return limit - #self._DealEntities
end

function XSkyGardenCafeRound:DoExit(stageId)
    self:ResetData()

    self:OnExit(stageId)

    --self:StopPatrolTimer()
end

--- 发牌
function XSkyGardenCafeRound:LibToDeck()
    --顺序抽卡
    local cards = self:SequenceCards(self:GetRestDeckCount())
    self:DoLibToDeck(cards)
    --触发抽卡Buff
    self:ApplyBuff(true, true, true, EffectTriggerId.DrawCard, DrawCardType.Round, cards)
    
    self:PreviewApplyBuff(true, false, false, {
        EffectTriggerId.RoundBegin, EffectTriggerId.Deck2Deal, EffectTriggerId.KeepInDeck
    })
    --触发关卡Buff
    self._OwnControl:ApplyStageBuff(EffectTriggerId.DrawCard, DrawCardType.Round, cards)
end

--- 执行牌库到手牌
---@param cards XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:DoLibToDeck(cards)
    local count = cards and #cards or 0
    local roundBeforeCount = #self._RoundBeforeCardEntities
    count = count + roundBeforeCount
    if count <= 0 then
        return
    end
    local dict = {}
    if roundBeforeCount > 0 then
        self._OwnControl:GetBattleInfo():AddDeckCount(roundBeforeCount)
        for i = roundBeforeCount, 1, -1 do
            local card = self._RoundBeforeCardEntities[i]
            self._DeckEntities[#self._DeckEntities + 1] = card
            local cnt = dict[card] or 0
            cnt = cnt + 1
            dict[card] = cnt
            tableRemove(self._RoundBeforeCardEntities, i)
        end
    end
    for _, card in pairs(cards) do
        local cnt = dict[card] or 0
        cnt = cnt + 1
        dict[card] = cnt
    end
    self:MoveLibCardsToDeckCards(cards)
    local indexList = self:GetDeckInsertCardIndex(dict)
    self:DoLibToDeckPerformanceByIndex(indexList)
end

--- 牌库到手牌的表现
function XSkyGardenCafeRound:DoLibToDeckPerformance(count)
    --执行抽卡(表现)
    self._OwnControl:Pool2Deck(count)
    --加载Npc
    self._OwnControl:GetNpcFactory():LoadNpcWhenDrawCard(self._DeckEntities)
end

function XSkyGardenCafeRound:DoLibToDeckPerformanceByIndex(indexList)
    --执行抽卡(表现)
    self._OwnControl:Pool2DeckByIndexList(indexList)
    --加载Npc
    self._OwnControl:GetNpcFactory():LoadNpcWhenDrawCard(self._DeckEntities)
end

function XSkyGardenCafeRound:GetDeckInsertCardIndex(cardDict)
    local indexList = {}
    if XTool.IsTableEmpty(cardDict) then
        return indexList
    end
    tableSort(self._DeckEntities, self._SortCardFunc)
    for i, card in pairs(self._DeckEntities) do
        local cnt = cardDict[card] or 0
        if cnt > 0 then
            indexList[#indexList + 1] = i - 1
            cnt = cnt - 1
            cardDict[card] = cnt
        end
    end
    return indexList
end

--- 移动牌库的牌到手牌中
---@param cards XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:MoveLibCardsToDeckCards(cards, needCSIndex)
    return self:MoveLibCardsToTarget(cards, self._DeckEntities, needCSIndex)
end

--- 移动牌库的牌到重抽组中
---@param cards XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:MoveLibCardsToReDrawCards(cards, needCSIndex)
    return self:MoveLibCardsToTarget(cards, self._ReDrawEntities, needCSIndex)
end

--- 移动牌库的牌到回合开始的牌组中
---@param cards XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:MoveLibCardsToRoundBeforeCards(cards, needCSIndex)
    return self:MoveLibCardsToTarget(cards, self._RoundBeforeCardEntities, needCSIndex)
end

function XSkyGardenCafeRound:MoveLibCardsToTarget(cards, targets, needCSIndex)
    if XTool.IsTableEmpty(cards) then
        return
    end
    --插入手牌中
    local removeDict = {}
    local removeIndex
    if needCSIndex then
        removeIndex = {}
    end
    for _, card in pairs(cards) do
        targets[#targets + 1] = card
        if not removeDict[card] then
            removeDict[card] = 1
        else
            local mark = removeDict[card]
            removeDict[card] = mark + 1
        end
    end
    --从牌库中移除
    for i = #self._PoolEntities, 1, -1 do
        if XTool.IsTableEmpty(removeDict) then
            break
        end
        local card = self._PoolEntities[i]
        local mark = removeDict[card]
        if mark and mark > 0 then
            mark = mark - 1
            if mark <= 0 then
                mark = nil
            end
            removeDict[card] = mark
            --移除
            tableRemove(self._PoolEntities, i)
            if needCSIndex then
                removeIndex[#removeIndex + 1] = i - 1
            end
        end
    end
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
    return removeIndex
end

--- 移动牌库的牌到手牌中
---@param cards XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:MoveDeckCardsToLibCards(cards, needCSIndex)
    if XTool.IsTableEmpty(cards) then
        return
    end
    --插入手牌中
    local removeDict = {}
    local removeIndex
    if needCSIndex then
        removeIndex = {}
    end
    for _, card in pairs(cards) do
        self._PoolEntities[#self._PoolEntities + 1] = card
        if not removeDict[card] then
            removeDict[card] = 1
        else
            local mark = removeDict[card]
            removeDict[card] = mark + 1
        end
    end
    --从牌库中移除
    for i = #self._DeckEntities, 1, -1 do
        if XTool.IsTableEmpty(removeDict) then
            break
        end
        local card = self._DeckEntities[i]
        local mark = removeDict[card]
        if mark and mark > 0 then
            mark = mark - 1
            if mark <= 0 then
                mark = nil
            end
            removeDict[card] = mark
            --移除
            tableRemove(self._DeckEntities, i)
            if needCSIndex then
                removeIndex[#removeIndex + 1] = i - 1
            end
        end
    end
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
    return removeIndex
end

function XSkyGardenCafeRound:DealToDeck(dealIndex, deckIndex)
    local card = self._DealEntities[dealIndex]
    if not card then
        XLog.Error("出牌转到手牌区异常!!!")
        return
    end
    --取消出牌Buff
    card:DisApplyBuff(EffectTriggerId.Deck2Deal)
    tableInsert(self._DeckEntities, deckIndex, card)
    tableRemove(self._DealEntities, dealIndex)

    self:UpdateDealIndex()
    self:UpdateCardInfo()
end

--- 手牌区转出牌区
---@param deckIndex number
---@param dealIndex number
function XSkyGardenCafeRound:DeckToDeal(deckIndex, dealIndex)
    local card = self._DeckEntities[deckIndex]
    if not card then
        XLog.Error("手牌转到出牌区异常!!!")
        return
    end
    tableInsert(self._DealEntities, dealIndex, card)
    tableRemove(self._DeckEntities, deckIndex)
    local battleInfo = self._Model:GetBattleInfo()
    battleInfo:AddCardUseCount(card:GetCardId())
    self:UpdateDealIndex()

    self:UpdateCardInfo()
    --触发出牌Buff
    card:ApplyBuff(EffectTriggerId.Deck2Deal)
    self:ApplyBuff(false, true, false, EffectTriggerId.Deck2Deal)

    local max = self._Model:GetMaxDeckCount()
    local cur = self:GetDeckCount()
    if max > cur then
        --出牌后必抽一张
        local cards = self:SequenceCards(1)
        self:DoLibToDeck(cards)
        self:ApplyBuffWhenDrawCard(card, cards)
    end

    self:UpdateCardInfo()
    self:PreviewApplyBuff(true, true, false, { 
        EffectTriggerId.Deck2Deal, EffectTriggerId.RoundBegin
    })
    
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_UPDATE_PLAY_CARD)
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_DECK_TO_DEAL)
    self._OwnControl:GetNpcFactory():LoadNpc(card)
end

function XSkyGardenCafeRound:DealSwitch(sourceIndex, targetIndex)
    if true then
        XLog.Error("该方法已经弃用！！！")
        return
    end
    local cardSource = self._DealEntities[sourceIndex]
    local cardTarget = self._DealEntities[targetIndex]
    self._DealEntities[sourceIndex] = cardTarget
    self._DealEntities[targetIndex] = cardSource
    self:UpdateCardInfo()
end

function XSkyGardenCafeRound:UpdateCardInfo()
    local battleInfo = self._Model:GetBattleInfo()
    battleInfo:ResetAddCardScore()
    battleInfo:ResetAddCardReview()
    for _, card in pairs(self._DealEntities) do
        battleInfo:AddCardScore(card:GetTotalCoffee())
        battleInfo:AddCardReview(card:GetTotalReview())
    end
end

function XSkyGardenCafeRound:ReDraw()
    local cards = self:SequenceCards(self:GetRestDeckCount())
    if cards and #cards > 1 then
        tableSort(cards, self._SortCardFunc)
    end
    local deckCards = {}
    local reDrawCards = {}
    for _, card in pairs(cards) do
        if card:IsReDraw() then
            reDrawCards[#reDrawCards + 1] = card
        else
            deckCards[#deckCards + 1] = card
        end
    end
    if not XTool.IsTableEmpty(deckCards) or not XTool.IsTableEmpty(self._RoundBeforeCardEntities) then
        self:DoLibToDeck(deckCards)
        self:ApplyBuff(true, true, true, EffectTriggerId.DrawCard, DrawCardType.Round, deckCards)
    end
    if not XTool.IsTableEmpty(reDrawCards) then
        self:MoveLibCardsToReDrawCards(reDrawCards)
    end
    self._OwnControl:ReDraw(#self._ReDrawEntities)
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_RE_DRAW_CARD, true)
end

function XSkyGardenCafeRound:DoReDrawToDeck()
    if XTool.IsTableEmpty(self._ReDrawEntities) then
        return
    end
    local dict = {}
    for _, card in pairs(self._ReDrawEntities) do
        local cnt = dict[card] or 0
        cnt = cnt + 1
        dict[card] = cnt
    end
    self:MoveLibCardsToDeckCards(self._ReDrawEntities)
    self:ApplyBuff(true, true, true, EffectTriggerId.DrawCard, DrawCardType.Round, self._ReDrawEntities)

    self:PreviewApplyBuff(true, false, false, { EffectTriggerId.RoundBegin, EffectTriggerId.Deck2Deal})

    self._ReDrawEntities = {}
    local indexList = self:GetDeckInsertCardIndex(dict)
    self._OwnControl:ReDrawToDeck(indexList)
    --加载Npc
    self._OwnControl:GetNpcFactory():LoadNpcWhenDrawCard(self._DeckEntities)
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_RE_DRAW_CARD, false)

    self._OwnControl:RequestEnterGame(self:GetDeckId())
end

function XSkyGardenCafeRound:SetReDrawSelectIndex(index, value)
    self._ReDrawSelectIndex[index] = value
end

function XSkyGardenCafeRound:IsSelectReDrawCard()
    for _, value in pairs(self._ReDrawSelectIndex) do
        if value then
            return true
        end
    end
    return false
end

function XSkyGardenCafeRound:ReDrawToDeck()
    local listIndex = {}
    for index, value in pairs(self._ReDrawSelectIndex) do
        if value then
            listIndex[#listIndex + 1] = index
        end
    end
    --抽几张?
    local cards = self:SequenceCards(#listIndex)
    math.randomseed(os.time())
    --替换
    for cardIndex, selectIndex in pairs(listIndex) do
        --抽取的卡牌
        local newCard = cards[cardIndex]
        --原来的卡牌
        local card = self._ReDrawEntities[selectIndex]
        --替换为新的卡牌
        self._ReDrawEntities[selectIndex] = newCard
        --将卡牌放入到牌组中
        local randomIndex = math.random(1, #self._PoolEntities)
        tableInsert(self._PoolEntities, randomIndex, card)
    end
    --表现
    self:DoReDrawToDeck()
end

--region 子类重写

function XSkyGardenCafeRound:OnEnter(stageId)
end

function XSkyGardenCafeRound:OnExit(stageId)
end

function XSkyGardenCafeRound:OnRoundBegin()
end

function XSkyGardenCafeRound:OnRoundEnd()
end

function XSkyGardenCafeRound:GetDeckId()
end

--endregion 子类重写

---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetLibCardsByType(type, count, isRandom)
    local ownCount = #self._PoolEntities
    if ownCount < count then
        self:ReEnterPoolCards()
        ownCount = #self._PoolEntities
        count = math.min(ownCount, count)
    end
    local list = {}
    local sum = 0
    for _, card in pairs(self._PoolEntities) do
        local t = card:GetCardType()
        if t == type then
            list[#list + 1] = card
            sum = sum + 1
        end

        if not isRandom and sum == count then
            break
        end
    end

    if #list <= count then
        return list
    end

    list = self:RandomCards(list, count)
    return list
end

---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetLibCardsByQuality(quality, count, isRandom)
    local ownCount = #self._PoolEntities
    if ownCount < count then
        self:ReEnterPoolCards()
        ownCount = #self._PoolEntities
        count = math.min(ownCount, count)
    end

    local list = {}
    local sum = 0
    for _, card in pairs(self._PoolEntities) do
        local q = card:GetCardQuality()
        if q == quality then
            list[#list + 1] = card
            sum = sum + 1
        end

        if not isRandom and sum == count then
            break
        end
    end

    if #list <= count then
        return list
    end

    list = self:RandomCards(list, count)
    return list
end

---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetLibCardsByTargets(targets, count, isRandom)
    if XTool.IsTableEmpty(targets) then
        return {}
    end
    local map = {}
    for _, id in pairs(targets) do
        if not map[id] then
            map[id] = 1
        else
            map[id] = map[id] + 1
        end
    end

    local list = {}
    for _, card in pairs(self._PoolEntities) do
        local id = card:GetCardId()
        local need = map[id]
        if need and need > 0 then
            list[#list + 1] = card
            map[id] = map[id] - 1
        end
    end

    if #list <= count then
        return list
    end

    list = isRandom and self:RandomCards(list, count) or tableRange(list, 1, count)

    return list
end

function XSkyGardenCafeRound:CreateNewCard(targets, count, isRandom)
    local needCount = targets and #targets or 0
    local list
    if needCount > count then
        if isRandom then
            targets = XTool.RandomArray(targets, os.time(), false)
        end
        list = tableRange(targets, 1, count)
    else
        list = XTool.Clone(targets)
    end
    local cards = {}
    local factory = self._OwnControl:GetCardFactory()
    for _, cardId in pairs(list) do
        local card = factory:CreateCard(cardId)

        self._PoolEntities[#self._PoolEntities + 1] = card

        cards[#cards + 1] = card
    end
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
    return cards
end

---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetLibCardsByOrder(count, isRandom)
    local ownCount = #self._PoolEntities
    if ownCount < count then
        self:ReEnterPoolCards()
        ownCount = #self._PoolEntities
        count = math.min(ownCount, count)
    end

    if isRandom then
        return self:RandomCards(self._PoolEntities, count)
    end

    return tableRange(self._PoolEntities, 1, count)
end

---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetDeckCardsByType(dict, isTarget)
    if XTool.IsTableEmpty(dict) then
        return
    end
    local list = {}
    for _, card in pairs(self._DeckEntities) do
        local t = card:GetCardType()
        if isTarget then
            if dict[t] then
                list[#list + 1] = card
            end
        else
            if not dict[t] then
                list[#list + 1] = card
            end
        end
    end

    return list
end

---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetDeckCardsByQuality(dict, isTarget)
    if XTool.IsTableEmpty(dict) then
        return
    end
    local list = {}
    for _, card in pairs(self._DeckEntities) do
        local q = card:GetCardQuality()
        if isTarget then
            if dict[q] then
                list[#list + 1] = card
            end
        else
            if not dict[q] then
                list[#list + 1] = card
            end

        end
    end

    return list
end

--- 替换卡牌
---@param deckCards XSkyGardenCafeCardEntity[]
---@param libCards XSkyGardenCafeCardEntity[]
---@param card XSkyGardenCafeCardEntity
function XSkyGardenCafeRound:Replace(deckCards, libCards, card)
    if self._RoundState == RoundState.RoundBeginBefore then
        self:MoveLibCardsToRoundBeforeCards(libCards, false)
        return
    end
    local addDeckCount = 0
    --先移除
    if deckCards then
        --将卡牌添加到卡组中
        local removeDeckIndex = self:MoveDeckCardsToLibCards(deckCards, true)
        --1.将卡从手牌中移除（表现）
        self._OwnControl:Deck2Pool(removeDeckIndex)

        addDeckCount = addDeckCount - #deckCards
    end

    --再插入手牌
    local insert2Deck
    if libCards then
        local battleInfo = self._Model:GetBattleInfo()
        local maxCount = self._Model:GetMaxDeckCount()
        local curCount = battleInfo:GetDeckLimit(maxCount) + addDeckCount
        local insCount = #libCards
        local needInsert = math.min(insCount, maxCount - curCount)
        battleInfo:AddDeckCount(needInsert)
        if needInsert ~= insCount then
            if needInsert <= 0 then
                insert2Deck = {}
            else
                insert2Deck = tableRange(libCards, 1, needInsert)
            end
            XUiManager.TipMsg(self._OwnControl:GetMainControl():GetDeckNumIsFullText())
        else
            insert2Deck = libCards
        end
        --将卡牌添加到手牌中
        self:MoveLibCardsToDeckCards(insert2Deck, false)
        if card then
            self:ApplyBuffWhenDrawCard(card, insert2Deck)
        end

        --将卡从牌组中移动到手牌-执行表现
        local dict = {}
        for _, c in pairs(insert2Deck) do
            local cnt = dict[c] or 0
            cnt = cnt + 1
            dict[c] = cnt
        end
        local indexList = self:GetDeckInsertCardIndex(dict)
        self._OwnControl:Pool2DeckByIndexList(indexList)
    end

    self:UpdateCardInfo()
end

--- 插入一张卡牌到牌库中
---@param cards XSkyGardenCafeCardEntity[]
---@param pos number 插入位置
function XSkyGardenCafeRound:InsertToLibs(cards, pos)
    if XTool.IsTableEmpty(cards) then
        return
    end
    local libs = self._PoolEntities
    --随机位置
    if pos == 1 then
        math.randomseed(os.time())
        for _, card in pairs(cards) do
            local index = math.random(1, #libs)
            tableInsert(libs, index, card)
        end
    elseif pos == 2 then
        --牌堆顶
        for i, card in pairs(cards) do
            tableInsert(libs, i, card)
        end
    elseif pos == 3 then
        --牌堆底
        for _, card in pairs(cards) do
            libs[#libs + 1] = card
        end
    end
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
end

--- 移除卡牌
---@param cards XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:RemoveLibCards(cards)
    if XTool.IsTableEmpty(cards) then
        return
    end

    local removeDict = {}
    for _, card in pairs(cards) do
        local count = removeDict[card] or 0
        count = count + 1
        removeDict[card] = count
    end

    local factory = self._OwnControl:GetCardFactory()
    for i = #self._PoolEntities, 1, -1 do
        local card = self._PoolEntities[i]
        local count = removeDict[card]
        if count and count > 0 then
            tableRemove(self._PoolEntities, i)
            count = count - 1
            if count <= 0 then
                count = nil
            end
            removeDict[card] = count

            factory:RemoveEntity(card)
        end
    end
    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
end

function XSkyGardenCafeRound:ApplyBuffRoundBefore()
    self:ApplyBuff(true, false, true, EffectTriggerId.RoundBegin)
    self:PreviewApplyBuff(true, false, false, { EffectTriggerId.Deck2Deal})
    self._OwnControl:ApplyNextRoundBuff()
    self._OwnControl:ApplyStageBuff(EffectTriggerId.RoundBegin)
end

function XSkyGardenCafeRound:OnEventApplyBuff(triggerType, ...)
    self:ApplyBuff(true, true, false, triggerType, ...)
end

function XSkyGardenCafeRound:ApplyBuff(isDeck, isDeal, isPool, triggerType, ...)
    if isDeck then
        for _, card in pairs(self._DeckEntities) do
            card:DisApplyBuff(triggerType)
            card:ApplyBuff(triggerType, ...)
        end
    end

    if isDeal then
        for _, card in pairs(self._DealEntities) do
            card:DisApplyBuff(triggerType)
            card:ApplyBuff(triggerType, ...)
        end
    end

    if isPool then
        for _, card in pairs(self._PoolEntities) do
            card:DisApplyBuff(triggerType)
            card:ApplyBuff(triggerType, ...)
        end
    end
end

function XSkyGardenCafeRound:DisApplyBuff(isDeck, isDeal, triggerType)
    if isDeck then
        for _, card in pairs(self._DeckEntities) do
            card:DisApplyBuff(triggerType)
        end
    end

    if isDeal then
        for _, card in pairs(self._DealEntities) do
            card:DisApplyBuff(triggerType)
        end
    end
end

function XSkyGardenCafeRound:PreviewApplyBuff(isDeck, isDeal, isPool, triggerDict, triggerArgDict)
    if isDeck then
        for _, card in pairs(self._DeckEntities) do
            card:PreviewApplyBuff(triggerDict, triggerArgDict)
        end
    end

    if isDeal then
        for _, card in pairs(self._DealEntities) do
            card:PreviewApplyBuff(triggerDict, triggerArgDict)
        end
    end

    if isPool then
        for _, card in pairs(self._PoolEntities) do
            card:PreviewApplyBuff(triggerDict, triggerArgDict)
        end
    end
end

---@param drawCard XSkyGardenCafeCardEntity
---@param cards XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:ApplyBuffWhenDrawCard(drawCard, cards)
    --触发抽卡Buff
    if drawCard then
        drawCard:ApplyBuff(EffectTriggerId.DrawCard, DrawCardType.PlayCard, cards)
    end
    if cards then
        for _, c in pairs(cards) do
            c:ApplyBuff(EffectTriggerId.DrawCard, DrawCardType.PlayCard, cards)
        end
    end
end

function XSkyGardenCafeRound:GetRoundState()
    return self._RoundState
end

function XSkyGardenCafeRound:UpdateDealIndex()
    local index = #self._DealEntities + 1
    self._NextDealIndex = math.min(self._MaxDealIndex, index)

    XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_DEAL_INDEX_UPDATE)
end

function XSkyGardenCafeRound:IsFullDeal()
    return self._NextDealIndex > self._MaxDealIndex
end

function XSkyGardenCafeRound:GetNextDealIndex()
    return self._NextDealIndex
end

return XSkyGardenCafeRound