local XSkyGardenCafeChallengeRound = require("XModule/XSkyGardenCafe/Entity/XSkyGardenCafeChallengeRound")
local XSkyGardenCafeStoryRound = require("XModule/XSkyGardenCafe/Entity/XSkyGardenCafeStoryRound")

local XSkyGardenCafeCardFactory = require("XModule/XSkyGardenCafe/Entity/XSkyGardenCafeCardFactory")
local XSGCafeBuffFactory = require("XModule/XSkyGardenCafe/Entity/Effect/XSGCafeBuffFactory")
local XSkyGardenCafeNpcFactory = require("XModule/XSkyGardenCafe/Entity/XSkyGardenCafeNpcFactory")

local CardUpdateEvent = XMVCA.XSkyGardenCafe.CardUpdateEvent
local CardContainer = XMVCA.XSkyGardenCafe.CardContainer
local DlcEventId = XMVCA.XBigWorldService.DlcEventId

---@class XSkyGardenCafeBattle : XEntityControl 战斗控制器
---@field _Model XSkyGardenCafeModel
---@field _MainControl XSkyGardenCafeControl
---@field _RoundEntity XSkyGardenCafeRound
---@field _Game XCafe.XCafeGame
---@field _CardFactory XSkyGardenCafeCardFactory
---@field _BuffFactory XSGCafeBuffFactory
---@field _NextRoundBuff XSGCafeBuff[]
---@field _NextRoundAddBuff XSGCafeBuff[]
---@field _StageBuffEntities XSGCafeBuff[]
---@field _NpcFactory XSkyGardenCafeNpcFactory
local XSkyGardenCafeBattle = XClass(XEntityControl, "XSkyGardenCafeBattle")

local CsCafeParam = CS.XCafe.XCafeParam

function XSkyGardenCafeBattle:OnInit()
    self._Game = false
    self._StageId = 0
    --回合结算中
    self._IsSettling = false
end

function XSkyGardenCafeBattle:OnRelease()
    self._Game = false
    self._StageId = 0
end

function XSkyGardenCafeBattle:DoEnterFight(stageId, deckId)
    self._StageId = stageId
    local isStory = self:IsStoryStage(stageId)
    if not self._RoundEntity then
        local cls = isStory and XSkyGardenCafeStoryRound or XSkyGardenCafeChallengeRound
        self._RoundEntity = self:AddEntity(cls)
    elseif self._RoundEntity:IsStory() ~= isStory then
        self:RemoveEntity(self._RoundEntity)
        local cls = isStory and XSkyGardenCafeStoryRound or XSkyGardenCafeChallengeRound
        self._RoundEntity = self:AddEntity(cls)
    end

    self._RoundEntity:DoEnter(stageId, deckId)
end

function XSkyGardenCafeBattle:DoExitFight()
    local stageId = self._StageId
    if self._RoundEntity then
        self._RoundEntity:DoExit(stageId)
    end
    if self._Game then
        self._Game:ExitGame()
    end
    self._Model:GetBattleInfo():Reset()
    self._Game = false

    self:BeforeExit()

    self._StageId = 0
    --XLuaUiManager.Close("UiSkyGardenCafeComponent")
end

function XSkyGardenCafeBattle:BeforeFight()
    self._CardFactory = self:AddSubControl(XSkyGardenCafeCardFactory)
    self._BuffFactory = self:AddSubControl(XSGCafeBuffFactory)
    self._NpcFactory = self:AddSubControl(XSkyGardenCafeNpcFactory)

    
    self:InitStageBuff()
end

function XSkyGardenCafeBattle:BeforeExit()
    self:DestroyBuff()

    if self._CardFactory then
        self:RemoveSubControl(self._CardFactory)
    end

    if self._BuffFactory then
        self:RemoveSubControl(self._BuffFactory)
    end

    if self._NpcFactory then
        self:RemoveSubControl(self._NpcFactory)
    end
    self._CardFactory = nil
    self._BuffFactory = nil
    self._NpcFactory = nil
end

function XSkyGardenCafeBattle:InitStageBuff()
    self._NextRoundBuff = {}
    self._NextRoundAddBuff = {}
    local buffListId = self._Model:GetStageBuffListId(self._StageId)
    if not buffListId or buffListId <= 0 then
        return
    end
    local effectIds = self._Model:GetBuffListEffectIds(buffListId)
    if XTool.IsTableEmpty(effectIds) then
        return
    end
    local factory = self:GetBuffFactory()
    self._StageBuffEntities = {}
    for _, effectId in pairs(effectIds) do
        local buff = factory:CreateBuff(effectId, nil)
        self._StageBuffEntities[#self._StageBuffEntities + 1] = buff
    end
end

function XSkyGardenCafeBattle:ApplyStageBuff(triggerType, ...)
    if XTool.IsTableEmpty(self._StageBuffEntities) then
        return
    end

    for _, buff in pairs(self._StageBuffEntities) do
        buff:Apply(triggerType, ...)
    end
end

function XSkyGardenCafeBattle:DestroyBuff()
    if XTool.IsTableEmpty(self._StageBuffEntities) then
        return
    end
    local factory = self:GetBuffFactory()
    for _, buff in pairs(self._StageBuffEntities) do
        factory:RemoveEntity(buff)
    end
    for _, buff in pairs(self._NextRoundAddBuff) do
        if not buff:IsDisposed() then
            factory:RemoveEntity(buff)
        end
    end
    for _, buff in pairs(self._NextRoundBuff) do
        if not buff:IsDisposed() then
            factory:RemoveEntity(buff)
        end
    end
    self._StageBuffEntities = nil
    self._NextRoundAddBuff = nil
    self._NextRoundBuff = nil
end

function XSkyGardenCafeBattle:AttachStageBuff(buff)
    if not buff then
        return
    end
    self._StageBuffEntities[#self._StageBuffEntities + 1] = buff
end

function XSkyGardenCafeBattle:Play()
    if not self._RoundEntity then
        return
    end
    local cardEntities = self._RoundEntity:GetDealCardEntities()
    if #cardEntities <= 0 then
        XUiManager.TipMsg(self._Model:GetConfig("DealEmptyTip"))
        return
    end
    XLuaUiManager.SetMask(true)
    self._IsSettling = true
    local isSkip = self._MainControl:IsSkipAnimation()
    RunAsyn(function()
        --回合结束
        self._RoundEntity:DoRoundEnd()
        asynWaitSecond(0.5)
        XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_ROUND_NPC_SHOW, true)
        if not isSkip then
            --回合演出结束
            local waitTime = self._NpcFactory:PlayRoundEnd()
            asynWaitSecond(waitTime / 1000)
        end
        self._NpcFactory:RemoveNpcWhenRoundEnd(self._RoundEntity:GetDeckCardEntities())
        local round = self:GetBattleInfo():GetRound()
        local targetRound = self._Model:GetStageRounds(self._StageId)
        if round <= targetRound then
            XEventManager.DispatchEvent(DlcEventId.EVENT_CAFE_ROUND_NPC_SHOW, false)
            --下个回合开始
            self._RoundEntity:DoRoundBegin()
        end
        self._RoundEntity:DoRequestRoundChange()

        XLuaUiManager.SetMask(false)
    end)
end

function XSkyGardenCafeBattle:GiveUp(cb)
    XNetwork.Call("BigWorldCafeGiveUpRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self:DoExitFight()
        if cb then
            cb()
        end
    end)
end

function XSkyGardenCafeBattle:ToServerData()
    local battleInfo = self:GetBattleInfo()
    local roundEntity = self._RoundEntity
    local data = {
        StageId = self._StageId,
        Round = battleInfo:GetRound(),
        SumSales = battleInfo:GetTotalScore(),
        ActPoint = battleInfo:GetDealLimit(),
        HandCardPosNum = battleInfo:GetDeckLimit(self._Model:GetMaxDeckCount()),
        ReviewNum = battleInfo:GetTotalReview(),
        HandCards = roundEntity:GetDeckCardIds(),
        CardsWarehouse = roundEntity:GetLibCardIds(),
        AbandonCards = battleInfo:GetAbandonCards(),
        BanCards = battleInfo:GetBanCards(),
        PriorityCard = battleInfo:GetPrecedeCards(),
        RetainHandCard = battleInfo:GetStayInHandCards(),
        UseCardTimes = battleInfo:GetCardUseCountDict(),
        BuffAdditionDict = battleInfo:GetCardForeverDict(),
        CardGroupId = roundEntity:GetDeckId(),
    }
    
    return data
end

--- 主控制器
---@return XSkyGardenCafeControl
--------------------------
function XSkyGardenCafeBattle:GetMainControl()
    return self._MainControl
end

function XSkyGardenCafeBattle:GetBarCounterNpcUUID()
    return self._NpcFactory:GetBarCounterNpcUUID()
end

function XSkyGardenCafeBattle:ChangeRoundSettle(value)
    self._IsSettling = value
end

function XSkyGardenCafeBattle:IsNeedReDraw()
    local battleInfo = self:GetBattleInfo()
    if battleInfo:GetRound() > 1 then
        return false
    end
    return self._Model:IsReDrawStage(self._StageId)
end

--- 打开战斗界面
--------------------------
function XSkyGardenCafeBattle:OpenBattleView(deckId)
    local stageId = self._StageId
    local battleInfo = self:GetBattleInfo()
    local isContinue
    --重新进入关卡
    if battleInfo:GetStageId() == stageId then
        self._RoundEntity:InitBattleInfoByServer()
        isContinue = true
    else --进入新关卡
        self._RoundEntity:InitBattleInfo()
        isContinue = false
    end
    --初始化参数
    CsCafeParam.InitDuration(0.1, 0.5, 1.0, 0.2, 0.5)
    CsCafeParam.InitCardSize(0, 0, 50, 0)
    CsCafeParam.InitSector(8448.471, 1.2, 180)
    --打开Hud
    --XLuaUiManager.Open("UiSkyGardenCafeComponent")
    --打开战斗界面
    XLuaUiManager.OpenWithCallback("UiSkyGardenCafeGame", function()
        self._Game = CS.XCafe.XCafeGame.Instance
        --c#回调
        local update = handler(self, self.OnCardUpdate)
        local checker = handler(self, self.CanPlayCard)
        --初始化表现
        self._Game:EnterGame(self._Model:GetMaxDeckCount(), self:GetBattleInfo():GetDealLimit(), update, checker)
        
        XLuaUiManager.SetMask(true)
        XScheduleManager.ScheduleOnce(function()
            --回合开始
            self._RoundEntity:DoRoundBegin(isContinue)

            --只有新进入游戏 并且 不是重抽才同步服务器，重抽会在重抽后同步服务器
            if not isContinue and not self:IsNeedReDraw() then
                --同步服务器
                self:RequestEnterGame(deckId)
            end
            XLuaUiManager.SetMask(false)
        end, 1000)
    end, stageId)
end

function XSkyGardenCafeBattle:RequestEnterGame(deckId)
    local cardList
    if deckId and deckId > 0 then
        local deck = self._Model:GetCardDeck(deckId)
        cardList = deck:GetCardsPool()
    end
    
    local req = {
        CafeGambling = self:ToServerData(),
        CardGroupId = deckId,
        CardList = cardList
    }
    XNetwork.Call("BigWorldCafeNewRoundRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if deckId and deckId > 0 then
            local deck = self._Model:GetCardDeck(deckId)
            deck:Sync()
        end
        local battleInfo = self:GetBattleInfo()
        battleInfo:SetDeckCount(self._Model:GetMaxCustomer(self._StageId))
        battleInfo:UpdateData(req.CafeGambling)
    end)
end

function XSkyGardenCafeBattle:OnCardUpdate(evt, type, index, card)
    if evt == CardUpdateEvent.Deal2Deck then
        self._RoundEntity:DealToDeck(type + 1, index + 1)
    elseif evt == CardUpdateEvent.Deck2Deal then
        self._RoundEntity:DeckToDeal(type + 1, index + 1)
    elseif evt == CardUpdateEvent.DealSwitch then
        self._RoundEntity:DealSwitch(type + 1, index + 1)
    end
    self._MainControl:InvokeCardUpdate(evt, type, index, card)
end

function XSkyGardenCafeBattle:CanPlayCard(type, index)
    local tip
    local pass = true
    local restCount = self._RoundEntity:GetRestDealCount()
    if restCount <= 0 then
        XUiManager.TipMsg(self._MainControl:GetDealCountFullText())
        return false
    end
    if type == CardContainer.Deck then
        local battleInfo = self:GetBattleInfo()
        local card = self:GetRoundEntity():GetDeckCardEntities()[index + 1]
        if not card then
            XLog.Error("手牌为空！")
            return false
        end
        local totalScore, totalReview = battleInfo:GetTotalScore(), battleInfo:GetTotalReview()
        local basicScore, basicReview = card:GetTotalCoffee(true), card:GetTotalReview(true)
        if totalScore + basicScore < 0 then
            tip = self._Model:GetResourceNotEnough(true)
            pass = false
        elseif totalReview + basicReview < 0 then
            tip = self._Model:GetResourceNotEnough(false)
            pass = false
        end
        if not pass then
            XUiManager.TipMsg(tip)
            return pass
        end


        local conditions = self._Model:GetCustomerUseCondition(card:GetCardId())
        if not XTool.IsTableEmpty(conditions) then
            local tempTip
            for _, conditionId in pairs(conditions) do
                pass, tempTip = self._MainControl:CheckCondition(conditionId)
                if not pass then
                    tip = tempTip
                    break
                end
            end
        end
    end

    if tip then
        XUiManager.TipMsg(tip)
    end

    return pass
end

function XSkyGardenCafeBattle:Pool2Deck(count)
    if not self._Game then
        XLog.Error("对局还未初始化!")
        return
    end
    if not count or count <= 0 then
        return
    end
    self._Game:PoolToDeck(count)
end

function XSkyGardenCafeBattle:Pool2DeckByIndexList(list)
    if not self._Game then
        XLog.Error("对局还未初始化!")
        return
    end
    if XTool.IsTableEmpty(list) then
        return
    end
    self._Game:PoolToDeck(list)
end

function XSkyGardenCafeBattle:Deal2Pool()
    if not self._Game then
        XLog.Error("对局还未初始化!")
        return
    end
    self._Game:DealToPool()
end

function XSkyGardenCafeBattle:Deck2Pool(list)
    if not self._Game then
        XLog.Error("对局还未初始化!")
        return
    end
    if XTool.IsTableEmpty(list) then
        return
    end
    self._Game:DeckToPool(list)
end

function XSkyGardenCafeBattle:RevertSwitch(sourceIndex, targetIndex)
    if not self._Game then
        XLog.Error("对局还未初始化!")
        return
    end
    self._Game:RevertSwitch(sourceIndex, targetIndex)
end

--- 获取手牌区卡牌
---@param index number
---@return XCafe.XCard
--------------------------
function XSkyGardenCafeBattle:GetDeckCard(index)
    if not self._Game then
        return
    end

    return self._Game:GetDeckCard(index)
end

--- 增加卡槽上限
---@param count number
--------------------------
function XSkyGardenCafeBattle:AddDealEmptyLimit(count)
    if not self._Game then
        return
    end

    if count <= 0 then
        return
    end

    self._Game:AddDealEmptyLimit(count)
end

--- 缩减卡槽上限
---@param count number
--------------------------
function XSkyGardenCafeBattle:SubDealEmptyLimit(count)
    if not self._Game then
        return
    end

    if count >= 0 then
        return
    end
    self._Game:SubDealEmptyLimit(count, self._IsSettling)
end

--- 修改手牌上限
---@param count number
--------------------------
function XSkyGardenCafeBattle:ChangeDeckLimit(count)
    if not self._Game then
        return
    end

    if count == 0 then
        return
    end

    self._Game:ChangeDeckLimit(count)
end

function XSkyGardenCafeBattle:ReDraw(count)
    if not self._Game then
        XLog.Error("对局还未初始化!")
        return
    end
    if count <= 0 then
        return
    end
    self._Game:ReDraw(count)
end

function XSkyGardenCafeBattle:ReDrawToDeck(indexList)
    if not self._Game then
        XLog.Error("对局还未初始化!")
        return
    end
    if XTool.IsTableEmpty(indexList) then
        return
    end
    
    self._Game:ReDrawToDeck(indexList)
end

function XSkyGardenCafeBattle:Collapse()
    if not self._Game then
        return
    end
    self._Game:Collapse()
end

function XSkyGardenCafeBattle:RefreshContainer(isDeck)
    if not self._Game then
        return
    end
    isDeck = isDeck and true or false
    self._Game:RefreshContainer(isDeck)
end

--- 获取出牌区卡牌
---@param index number
---@return XCafe.XCard
--------------------------
function XSkyGardenCafeBattle:GetDeckCard(index)
    if not self._Game then
        return
    end

    return self._Game:GetDealCard(index)
end

---@return XSkyGardenCafeRound
function XSkyGardenCafeBattle:GetRoundEntity()
    return self._RoundEntity
end

function XSkyGardenCafeBattle:GetStageId()
    return self._StageId
end

function XSkyGardenCafeBattle:IsInFight()
    return self._StageId ~= 0
end

function XSkyGardenCafeBattle:IsStoryStage()
    return self._Model:IsStoryStage(self._StageId)
end

function XSkyGardenCafeBattle:GetRoundTitle()
    local maxRound = self._Model:GetStageRounds(self._StageId)
    local round = self:GetBattleInfo():GetRound()
    local str = self._Model:GetConfig("RoundTitle")
    return string.format(str, round, maxRound)
end

function XSkyGardenCafeBattle:GetStageTarget()
    return self._Model:GetStageTarget(self._StageId)
end

---@return XSGCafeBattle
function XSkyGardenCafeBattle:GetBattleInfo()
    return self._Model:GetBattleInfo()
end

function XSkyGardenCafeBattle:GetCardFactory()
    return self._CardFactory
end

function XSkyGardenCafeBattle:GetBuffFactory()
    return self._BuffFactory
end

---@return XSkyGardenCafeNpcFactory
function XSkyGardenCafeBattle:GetNpcFactory()
    return self._NpcFactory
end

function XSkyGardenCafeBattle:AddNextRoundBuff(buff)
    if not self._NextRoundAddBuff then
        self._NextRoundAddBuff = {}
    end
    for _, entity in pairs(self._NextRoundAddBuff) do
        if entity == buff then
            return
        end
    end
    self._NextRoundAddBuff[#self._NextRoundAddBuff + 1] = buff
end

function XSkyGardenCafeBattle:ApplyNextRoundBuff()
    if XTool.IsTableEmpty(self._NextRoundBuff) then
        return
    end
    for _, buff in pairs(self._NextRoundBuff) do
        buff:ApplyAuto()
    end
end

function XSkyGardenCafeBattle:SyncNextRoundBuff()
    if not XTool.IsTableEmpty(self._NextRoundBuff) then
        local factory = self:GetBuffFactory()
        for _, buff in pairs(self._NextRoundBuff) do
            if buff:IsRelease() and not buff:IsDisposed() and not buff:IsCardValid() then
                factory:RemoveEntity(buff)
            end
        end
    end
    
    self._NextRoundBuff = self._NextRoundAddBuff
    self._NextRoundAddBuff = {}
end

function XSkyGardenCafeBattle:AddDeckCount(count)
    if not self._Game then
        return
    end
    local maxCount = self._Model:GetMaxDeckCount()
    local curCount = self._RoundEntity:GetDeckCount()
    if curCount >= maxCount and count > 0 then
        XUiManager.TipMsg(self._MainControl:GetDeckNumIsFullText())
        return
    end
    count = math.min(count, maxCount - curCount)
    local battleInfo = self._Model:GetBattleInfo()
    --1.修改手牌上限（数据）
    battleInfo:AddDeckCount(count)
    --2.修改手牌上限（表现）
    local free = self._RoundEntity:GetRestDeckCount()
    if free > 0 and not self._IsSettling then
        --3.补充空余卡
        local cards = self._RoundEntity:SequenceCards(free)
        self._RoundEntity:DoLibToDeck(cards)
    end
    --self:ChangeDeckLimit(count)
end

function XSkyGardenCafeBattle:AddDealCount(count)
    if not self._Game then
        return
    end
    local maxCount = self._Model:GetMaxDealCount()
    local battleInfo = self._Model:GetBattleInfo()
    local limit = battleInfo:GetDealLimit()
    if limit >= maxCount and count > 0 then
        XUiManager.TipMsg(self._MainControl:GetCafeDealNumIsFull())
        return
    end
    local max = math.min(maxCount, limit + count)
    local realCount = max - limit
    --1.修改出牌上限（数据）
    battleInfo:AddDealCount(realCount)
    --2.修改手牌上限（表现）,如果有卡牌，将卡牌移动回手牌
    if realCount > 0 then
        self:AddDealEmptyLimit(realCount)
    else
        self:SubDealEmptyLimit(realCount)
    end
    return realCount
end

function XSkyGardenCafeBattle:DoNpcClicked(uuid)
    if not self._NpcFactory then
        return
    end
    local npc = self._NpcFactory:GetNpc(uuid)
    if not npc then
        return
    end
    npc:ShowDialog()
end

return XSkyGardenCafeBattle