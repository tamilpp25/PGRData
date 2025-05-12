local XSkyGardenCafeRound = require("XModule/XSkyGardenCafe/Entity/XSkyGardenCafeRound")

---@class XSkyGardenCafeStoryRound : XSkyGardenCafeRound
local XSkyGardenCafeStoryRound = XClass(XSkyGardenCafeRound, "XSkyGardenCafeStoryRound")

function XSkyGardenCafeStoryRound:IsStory()
    return true
end

function XSkyGardenCafeStoryRound:OnEnter(stageId)
    if not XMVCA.XSkyGardenCafe:IsEnterLevel() then
        self._OwnControl:GetMainControl():SetFightData(stageId, 0)
        XMVCA.XSkyGardenCafe:EnterGameLevel()
        return
    end
    
    self._OwnControl:BeforeFight()
    
    --剧情关没有自选卡组，直接随机卡组出来，开始游戏
    local groupId = self._Model:GetStageGenerateGroupId(stageId)
    self._GenerateIds = self._Model:GetGenerateIds(groupId)
    self._IsSingleGenerate = self._Model:IsSingleGenerate(stageId)
    self._OwnControl:OpenBattleView()
    
    --self:StartPatrolTimer()
end

function XSkyGardenCafeStoryRound:OnRoundEnd()
    if self._IsSingleGenerate then
        return
    end
    local battleInfo = self._Model:GetBattleInfo()
    local round = battleInfo:GetRound()
    local generateId = self:GetGenerateId(round)
    --固定排序
    local isFixedOrder = self._Model:IsFixedOrder(generateId)
    local libs = self._Model:GetCustomerIds(generateId)
    if not isFixedOrder then
       libs = XTool.RandomArray(libs, os.time(), false)
    --else
    --    --上个回合的生产Id
    --    local lastGenerateId = self:GetGenerateId(round - 1)
    --    --不同池子，直接刷新整个池子
    --    if lastGenerateId ~= generateId then
    --        local libs = self._Model:GetCustomerIds(generateId)
    --        --直接更新整个牌库
    --        self:ClearAllLibCards()
    --        self:InitLibCards(libs)
    --        battleInfo:SyncAbandonCards({})
    --    end
    end
    
    --直接更新整个牌库
    self:ClearAllLibCards()
    self:InitLibCards(libs)
    battleInfo:SyncAbandonCards({})
end

function XSkyGardenCafeStoryRound:OnExit(stageId)
end

function XSkyGardenCafeStoryRound:GetGenerateId(round)
    if round < 1 then
        return 0
    end
    local index = math.min(round, #self._GenerateIds)
    return self._GenerateIds[index]
end

function XSkyGardenCafeStoryRound:InitBattleInfo()
    local stageId = self._StageId
    local battleInfo = self._Model:GetBattleInfo()
    local round = 1
    local generateId = self:GetGenerateId(round) 
    local cardIdList = self._Model:GetCustomerIds(generateId)
    --固定排序
    local isFixedOrder = self._Model:IsFixedOrder(generateId)
    if not isFixedOrder then
        cardIdList = XTool.RandomArray(cardIdList, os.time(), false)
    end
    --创建牌组
    self:InitLibCards(cardIdList)
    battleInfo:InitBattleInfo({
        StageId = stageId,
        Round = round,
        ActPoint = self._Model:GetActPoint(stageId),
        Review = self._Model:GetStageInitReview(stageId),
        DeckCount = self._Model:GetMaxCustomer(stageId),
        CardGroupId = self:GetDeckId()
    })
end

function XSkyGardenCafeStoryRound:GetDeckId()
    return 0
end

return XSkyGardenCafeStoryRound