local XLuckyTenantChessBoard = require("XModule/XLuckyTenant/Game/XLuckyTenantChessBoard")
local XLuckyTenantBag = require("XModule/XLuckyTenant/Game/XLuckyTenantBag")
local XLuckyTenantRandomPool = require("XModule/XLuckyTenant/Game/XLuckyTenantRandomPool")
local XLuckyTenantChessSkill = require("XModule/XLuckyTenant/Game/Skill/XLuckyTenantChessSkill")
local XLuckyTenantOperationProxy = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperationProxy")
local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XLuckyTenantAnimationGroup = require("XModule/XLuckyTenant/Game/Animation/XLuckyTenantAnimationGroup")
local GameState = XLuckyTenantEnum.GameState

---@class XLuckyTenantGame
local XLuckyTenantGame = XClass(nil, "XLuckyTenantGame")

function XLuckyTenantGame:Ctor()
    ---@type XLuckyTenantChessBoard
    self._ChessBoard = XLuckyTenantChessBoard.New()

    ---@type XLuckyTenantBag
    self._Bag = XLuckyTenantBag.New()

    ---@type XLuckyTenantRandomPool
    self._RandomPool = XLuckyTenantRandomPool.New()

    self._Seed = 0
    self._StageId = 0
    self._IsFirstTimeEntering = false

    self._Round = 0
    self._AmountOfPiecesToSelect = 3
    ---@type XLuckyTenantPiece[]
    self._PiecesToSelect = {}
    self._PiecesFixedBucket = {}
    self._PiecesRandomBucket = {}
    self._ConditionBucket = {}
    self._IsDirtyPiecesToSelect = true
    self._HasSelectOrDelete = false

    ---@type XLuckyTenantChessSkill[]
    self._PassiveSkill = {}

    self._TotalScore = 0
    self._ScoreThisRound = 0

    ---@type XTableLuckyTenantStageTask[]
    self._Quest = {}
    self._QuestHasBeenCompleted = 0
    self._IsNormalClear = false

    self._GameState = GameState.ShowQuestGoalsOnFirstRound

    -- free refresh twice on first round
    self._FreeRefreshTimes = 0

    self._TestCase = false

    -- 只在回合计算时存在，临时值
    self._OperationProxyOnlyExistInTurnCalculation = false

    self._Animations = {}

    self._HasSupplyChess = false

    self._Record = {
        SelectPiece = {},
        DeletePiece = {}
    }

    self._RoundFin = false
    self._IsOver = false
end

---@param model XLuckyTenantModel
function XLuckyTenantGame:Init(model, stageId, seed, isFirstTimeEntering, isResumeGame)
    local config = model:GetLuckyTenantStageConfigById(stageId)
    if not config then
        XLog.Error("[XLuckyTenantGame] 不存在的关卡:" .. tostring(stageId))
        return
    end
    self._Seed = seed
    math.randomseed(seed)

    self._FreeRefreshTimes = config.FirstSupplyCnt

    self._StageId = stageId
    self._IsFirstTimeEntering = isFirstTimeEntering
    -- 恢复游戏时, 不需要初始化背包
    self._Bag:Init(model, config, isResumeGame, self)
    self._ChessBoard:Init(config)
    self._RandomPool:Init(model)
    self:InitQuest(model)
end

---@param model XLuckyTenantModel
function XLuckyTenantGame:InitQuest(model)
    local stageId = self._StageId
    self._Quest = model:GetStageTasks(stageId)
    XMVCA.XLuckyTenant:Print("设置任务目标结束")
end

function XLuckyTenantGame:NextRound(model)
    self._IsDirtyPiecesToSelect = true
    self._HasSelectOrDelete = false
    self._Round = self._Round + 1
    self._ScoreThisRound = 0
    XMVCA.XLuckyTenant:Print("第", self._Round, "回合开始")
end

function XLuckyTenantGame:ResetChessBoard(model)
    if self._TestCase then
        self._ChessBoard:SetTestCase(self, model, self._Bag, self._TestCase)
    else
        self._ChessBoard:SetPieces(self._Bag)
    end
end

function XLuckyTenantGame:GetOperationProxyOnlyExistInTurnCalculation()
    return self._OperationProxyOnlyExistInTurnCalculation
end

function XLuckyTenantGame:CalculateScore(model, animationGroups)
    -- 每次update，构建一个proxy，给每次更新复用数据
    ---@type XLuckyTenantOperationProxy
    local operationProxy = XLuckyTenantOperationProxy.New(self, model)
    self._OperationProxyOnlyExistInTurnCalculation = operationProxy
    -- 顺序改为从左上角开始
    ---@type number[]
    local positions = self._ChessBoard:GetPositionTranspose()

    local piecesCollectedOnStart = {}
    for i = 1, #positions do
        local piece = self._ChessBoard:GetPieceByIndex(positions[i])
        if piece then
            local id = piece:GetIdConcatUid()
            piecesCollectedOnStart[id] = true
        end
    end

    for times = 1, 9 do
        local record = {}
        XMVCA.XLuckyTenant:Print("执行", self._Round, "回合第", times, "次计算")
        operationProxy:UpdateMultiSkills(self._PassiveSkill)
        operationProxy.Times = times

        local pieceUidDictionary = {}
        for i = 1, #positions do
            local position = positions[i]
            local piece = self._ChessBoard:GetPieceByIndex(position)
            if piece then
                local score = piece:GetValueIncludingTemp()
                self._ChessBoard:SetPositionScore(position, score)
                pieceUidDictionary[position] = piece:GetUid()
            else
                pieceUidDictionary[position] = 0
                self._ChessBoard:SetPositionScore(position, 0)
            end
        end

        local isSomethingHappened = false
        ---@type XLuckyTenantChessSkill[]
        local pendingSkills = {}
        for i = 1, #positions do
            local position = positions[i]
            local piece = self._ChessBoard:GetPieceByIndex(position)
            if piece and piece:IsPiece() then
                local isHasCollectedOnStart = piecesCollectedOnStart[piece:GetIdConcatUid()]
                local skills = piece:GetSkills(model)
                for j = 1, #skills do
                    local skill = skills[j]
                    if times == 1 or (not skill:IsEffectJustOnFirstRound() and times > 1) then
                        if isHasCollectedOnStart or skill:IsEffectUponJoining() then
                            pendingSkills[#pendingSkills + 1] = skill
                        end
                    end
                end

                if #pendingSkills > 0 then
                    local animationGroup
                    if animationGroups then
                        animationGroup = XLuckyTenantAnimationGroup.New()
                        animationGroups[#animationGroups + 1] = animationGroup
                    end

                    for i = 1, #pendingSkills do
                        local skill = pendingSkills[i]
                        operationProxy:Update(skill)
                        operationProxy:SaveOperationPackage()

                        -- 单个技能遍历后, 立即执行
                        local operationPackages = operationProxy.ManyOperationPackages
                        if #operationPackages > 0 then
                            isSomethingHappened = true

                            for i = 1, #operationPackages do
                                local package = operationPackages[i]
                                package:Do(model, self, animationGroup, operationProxy)
                                package:SaveRecord(record)
                            end
                            operationProxy.ManyOperationPackages = {}
                            operationProxy:ExecuteToDelete()
                        end
                        operationProxy:SaveOperationPackage()
                    end

                    for i = #pendingSkills, 1, -1 do
                        pendingSkills[i] = nil
                    end
                end
            end
        end
        if not isSomethingHappened then
            break
        end

        for i = 1, #positions do
            local position = positions[i]
            local piece = self._ChessBoard:GetPieceByIndex(position)
            local uid
            if piece then
                uid = piece:GetUid()
            end
            if uid ~= pieceUidDictionary[position] then
                local oldScore = self._ChessBoard:GetPositionScore(position)
                self._ChessBoard:AddPositionScoreImplemented(position, oldScore)
            end
        end
        if times == 9 then
            XMVCA.XLuckyTenant:Print("[XLuckyTenantGame] 棋盘计分循环了9次还没结束，有死循环吗？")
        end
        operationProxy:SetOperationsLastCalculate(record)
    end

    -- 统计分数
    ---@type XLuckyTenantAnimationGroup
    local animationGroup
    if animationGroups then
        animationGroup = XLuckyTenantAnimationGroup.New()
    end

    for i = 1, #positions do
        local position = positions[i]
        local score = self._ChessBoard:GetPositionScore(position)
        if score ~= 0 then
            self:SetScoreThisRound(self:GetScoreThisRound() + score)

            if animationGroup then
                animationGroup:SetAnimation({
                    Type = XLuckyTenantEnum.Animation.GetScore,
                    Position = position,
                    Value = score
                })
                animationGroups[#animationGroups + 1] = animationGroup
            end
        end
    end
    self._TotalScore = self._TotalScore + self._ScoreThisRound
    self._TotalScore = math.min(self._TotalScore, 9999)
    self._OperationProxyOnlyExistInTurnCalculation = false
    operationProxy = nil
end

function XLuckyTenantGame:DeletePieceSkill(piece)
    -- 删除被动技能
    local skills = piece:GetSkills()
    if skills then
        for i = 1, #skills do
            ---@type XLuckyTenantChessSkill
            local skill = skills[i]
            if skill:IsPassive() then
                self:DeletePassiveSkill(skill)
            end
            if self._OperationProxyOnlyExistInTurnCalculation then
                skill:OnDestroy(self._OperationProxyOnlyExistInTurnCalculation)
                --else
                --XMVCA.XLuckyTenant:Print("在非计算分数时，删除棋子，不触发被消除技能", skill:GetId())
            end
        end
    end
end

function XLuckyTenantGame:DeletePieceByUid(uid, fromPlayer)
    self._ChessBoard:DeletePieceByUid(uid)
    local piece = self._Bag:GetPiece(uid)
    if piece then
        if fromPlayer then
            table.insert(self._Record.DeletePiece, piece:GetId())
        end
        self:DeletePieceSkill(piece)
        self._Bag:DeletePieceByUid(uid)
    else
        XLog.Error("[XLuckyTenantGame] 删除棋子:" .. tostring(uid))
    end
end

function XLuckyTenantGame:SelectPiece(model, index)
    local options = self:GetOptionsThisRound(model)
    local piece = options[index]
    if not piece then
        XLog.Error("[XLuckyTenantGame] 选择棋子失败,该index没有对应棋子:" .. tostring(index))
        return false
    end
    options[index] = false
    self:AddNewPieceToBag(model, piece:GetId())
    self._HasSelectOrDelete = true
    self:NextState(model)
    table.insert(self._Record.SelectPiece, piece:GetId())
    return true, piece
end

---@param model XLuckyTenantModel
---@return XLuckyTenantPiece[]
function XLuckyTenantGame:GetOptionsThisRound(model)
    if self._IsDirtyPiecesToSelect then
        self._IsDirtyPiecesToSelect = false
        local size = #self._PiecesToSelect
        for i = 1, size do
            local piece = self._PiecesToSelect[i]
            self._Bag:EnterPool(piece)
        end
        self._PiecesToSelect = {}
        self:UpdateRandomBucket(model, true)
        self:RefreshOptions(model)
    end
    return self._PiecesToSelect
end

-- 刷新棋子选项
function XLuckyTenantGame:RefreshOptions(model)
    local needAmount = self._AmountOfPiecesToSelect
    if #self._PiecesRandomBucket < needAmount then
        XLog.Error("[XLuckyTenantGame] 随机池数量小于" .. self._AmountOfPiecesToSelect)
        return
    end

    for i = 1, #self._PiecesToSelect do
        self._PiecesToSelect[i] = nil
    end

    local fixedBucket = self._PiecesFixedBucket
    local fixedBucketSize = #fixedBucket
    if fixedBucketSize > 0 then
        local size = math.min(needAmount, fixedBucketSize)
        for i = 1, size do
            local pieceId = fixedBucket[1]
            if pieceId and pieceId > 0 then
                table.remove(fixedBucket, 1)
                local piece = self._Bag:NewPiece(model, pieceId)
                self._PiecesToSelect[#self._PiecesToSelect + 1] = piece
                needAmount = needAmount - 1
                size = size - 1
            end
        end
    end

    if needAmount > 0 then
        local selected = self:RandomSelect(model, self._PiecesRandomBucket, needAmount)
        for i = 1, #selected do
            ---@type XTableLuckyTenantChessRandomGroup
            local groupConfig = selected[i]
            local pieceId = groupConfig.PieceId
            local piece = self._Bag:NewPiece(model, pieceId)
            self._PiecesToSelect[#self._PiecesToSelect + 1] = piece
        end
    end

    if #self._PiecesToSelect == 0 then
        XLog.Error("[XLuckyTenantGame] 可选择棋子为0, 必有问题")
    end
end

function XLuckyTenantGame:_AddUniquePiece(array, usedHashmap, element)
    if not usedHashmap[element] then
        array[#array + 1] = element
        usedHashmap[element] = true
        return true
    end
    return false
end

---@param model XLuckyTenantModel
---@param groupConfig XTable.XTableLuckyTenantChessRandomGroup
function XLuckyTenantGame:GetPieceWeight(model, groupConfig)
    local conditions = groupConfig.Condition
    local weight = groupConfig.PieceWeight
    if #conditions == 0 then
        return weight
    end
    local isMatchCondition = nil
    for i = 1, #conditions do
        local conditionId = conditions[i]
        if self._ConditionBucket[conditionId] ~= nil then
            isMatchCondition = self._ConditionBucket[conditionId]
        else
            isMatchCondition = false
            local condition = model:GetLuckyTenantChessConditionConfigById(conditionId)
            if condition then
                if condition.Type == XLuckyTenantEnum.Condition.Round then
                    if self:GetRound() >= tonumber(condition.Params[1]) then
                        isMatchCondition = true
                    else
                        isMatchCondition = false
                    end
                elseif condition.Type == XLuckyTenantEnum.Condition.TagAmount then
                    if self._Bag:GetTagAmount(tostring(condition.Params[1])) > tonumber(condition.Params[2]) then
                        isMatchCondition = true
                    else
                        isMatchCondition = false
                    end

                elseif condition.Type == XLuckyTenantEnum.Condition.Identical then
                    local amount = self._Bag:GetPieceAmountById(tonumber(condition.Params[1]))
                    if amount >= tonumber(condition.Params[2]) then
                        isMatchCondition = true
                    else
                        isMatchCondition = false
                    end

                end
            end
            self._ConditionBucket[conditionId] = isMatchCondition
        end
        if isMatchCondition then
            weight = weight + groupConfig.IncreaseWeight[i]
        end
    end
    if weight < 0 then
        weight = 0
        --XLog.Error("[XLuckyTenantGame] 随机抽取棋子，权重为负数，请检查配置:" .. tostring(groupConfig.Id))
    end
    return weight
end

function XLuckyTenantGame:RandomSelect(model, elements, n)
    n = n or 3  -- 默认选择 3 个元素
    local selected = {}
    local remaining = {}

    -- 复制元素到 remaining 数组
    for _, element in ipairs(elements) do
        table.insert(remaining, element)
    end

    for i = 1, n do
        if #remaining == 0 then
            break -- 如果没有剩余元素，退出循环
        end

        -- 计算总权重
        local totalWeight = 0
        for _, element in ipairs(remaining) do
            totalWeight = totalWeight + self:GetPieceWeight(model, element)
        end

        -- 随机选择
        local rand = math.random() * totalWeight
        local cumulativeWeight = 0

        for j = 1, #remaining do
            cumulativeWeight = cumulativeWeight + self:GetPieceWeight(model, remaining[j])
            if rand <= cumulativeWeight then
                table.insert(selected, remaining[j])  -- 选择该元素的 id
                table.remove(remaining, j)  -- 从剩余元素中移除该元素
                break
            end
        end
    end

    return selected
end

---@param model XLuckyTenantModel
function XLuckyTenantGame:UpdateRandomBucket(model)
    self._PiecesRandomBucket = {}
    self._ConditionBucket = {}
    if not XTool.IsTableEmpty(self._PiecesFixedBucket) then
        self._PiecesFixedBucket = {}
    end
    ---@type XTable.XTableLuckyTenantChessRound
    local round = model:GetValidRoundConfig(self._StageId, self:GetRound())
    if not round then
        XLog.Error("[XLuckyTenantGame] 暴力遍历round表都找不到匹配的round配置")
        return
    end
    --local usedPieces = {}

    -- 使用 提前配置好的棋子
    local presetPieces
    if self._IsFirstTimeEntering then
        presetPieces = round.FirstUseInStage
    elseif self:GetRound() == round.StartRound then
        presetPieces = round.FirstUseInRound
    end
    if presetPieces then
        for i = 1, #presetPieces do
            local id = presetPieces[i]
            --self:_AddUniquePiece(self._PiecesFixedBucket, usedPieces, id)
            self._PiecesFixedBucket[#self._PiecesFixedBucket + 1] = id
        end
    end

    local elements = self._PiecesRandomBucket
    local groups = round.Group
    for i = 1, #groups do
        local groupId = groups[i]
        self:GetRandomBucketByGroupId(elements, model, groupId)
    end
end

function XLuckyTenantGame:GetRandomBucketByGroupId(elements, model, groupId)
    for i = 1, 99 do
        local groupConfig = model:GetLuckyTenantChessRandomGroupConfigById(groupId * 1000 + i)
        if groupConfig and groupConfig.GroupId == groupId then
            elements[#elements + 1] = groupConfig
        else
            if i == 1 then
                XMVCA.XLuckyTenant:Print("[XLuckyTenantGame] 随机池group的配置，应该是groupId + index，检查下配置", tostring(groupId))
            end
            break
        end
    end
end

function XLuckyTenantGame:DebugLog()
    local str = ""
    str = str .. "拥有的棋子:"
    local bag = self._Bag
    local pieces = bag:GetPieces()
    for i, piece in pairs(pieces) do
        str = str .. piece:GetName() .. ","
    end
    XLog.Debug(str)
end

---@return XLuckyTenantChessBoard
function XLuckyTenantGame:GetChessboard()
    return self._ChessBoard
end

---@return XLuckyTenantBag
function XLuckyTenantGame:GetBag()
    return self._Bag
end

---@return XLuckyTenantRandomPool
function XLuckyTenantGame:GetRandomPool()
    return self._RandomPool
end

function XLuckyTenantGame:DeletePieceOnChessboard(x, y)
    local piece = self._ChessBoard:GetPieceByPosition(x, y)
    if piece then
        self:DeletePieceSkill(piece)
        self._ChessBoard:Delete(x, y)
        --self._Bag:DeletePieceByUid(piece:GetUid())
    else
        XLog.Error("[XLuckyTenantGame] 尝试删除不存在的位置")
    end
end

function XLuckyTenantGame:DeletePieceByPosition(x, y)
    local piece = self._ChessBoard:GetPieceByPosition(x, y)
    if piece then
        self:DeletePieceSkill(piece)
        self._ChessBoard:Delete(x, y)
        self._Bag:DeletePieceByUid(piece:GetUid())
    else
        XLog.Error("[XLuckyTenantGame] 尝试删除不存在的位置")
    end
end

function XLuckyTenantGame:GetTotalScore()
    return self._TotalScore
end

function XLuckyTenantGame:GetScoreThisRound()
    return self._ScoreThisRound
end

function XLuckyTenantGame:SetScoreThisRound(score)
    self._ScoreThisRound = score
end

---@return boolean, XLuckyTenantPiece
function XLuckyTenantGame:AddNewPieceToBag(model, pieceId, uid)
    local piece = self._Bag:NewPiece(model, pieceId, uid)
    if piece then
        local isSuccess = self._Bag:AddPiece(piece)

        -- 进入背包时执行
        if isSuccess then
            local skills = piece:GetSkills(model)
            for i = 1, #skills do
                local skill = skills[i]
                skill:OnStart(model, self)
            end
        end
        return isSuccess, piece
    end
    return false
end

function XLuckyTenantGame:AddPassiveSkillById(model, skillId)
    ---@type XLuckyTenantChessSkill
    local skill = XLuckyTenantChessSkill.New()
    skill:SetPassiveSkill(skillId, model)
    self:AddPassiveSkill(skill)
    return true
end

---@param skill XLuckyTenantChessSkill
function XLuckyTenantGame:AddPassiveSkill(skill)
    XLog.Debug("[XLuckyTenantChessSkill] 增加被动技能:" .. tostring(skill:GetName()))
    self._PassiveSkill[#self._PassiveSkill + 1] = skill
end

function XLuckyTenantGame:DeletePassiveSkill(skill)
    for i = 1, #self._PassiveSkill do
        if self._PassiveSkill[i]:Equals(skill) then
            table.remove(self._PassiveSkill, i)
            return
        end
    end
end

function XLuckyTenantGame:GetRound()
    if self._Round == 0 then
        return 1
    end
    return self._Round
end

function XLuckyTenantGame:GetState()
    return self._GameState
end

function XLuckyTenantGame:SetState(state)
    --if self._TestCase then
    --    if state == GameState.SelectPiece then
    --        state = GameState.Roll
    --        self._HasSelectOrDelete = true
    --    end
    --end
    self._GameState = state
    --XMVCA.XLuckyTenant:Print("设置游戏状态:", state)
end

function XLuckyTenantGame:NextState(model)
    local gameState = self._GameState
    if gameState == GameState.ShowQuestGoalsOnFirstRound then
        self:SetState(GameState.SelectPiece)
        return
    end
    if gameState == GameState.SelectPiece then
        if self._HasSelectOrDelete then
            self:SetState(GameState.Roll)
        else
            XLog.Error("[XLuckyTenantGame] 尚未选择棋子")
        end
        return
    end
    if gameState == GameState.Roll then
        self:SetState(GameState.Animation)
        XMVCA.XLuckyTenant:Print("播放动画开始")
        return
    end
    if gameState == GameState.Animation then
        self:SetState(GameState.CheckQuestCompletionStatus)
        return
    end
    if gameState == GameState.CheckQuestCompletionStatus then
        local roundFin = self:GetRoundFin()
        local stateFromServer
        if roundFin and roundFin > 0 then
            if roundFin == 1 then
                stateFromServer = XLuckyTenantEnum.GameState.PerfectClear
            elseif roundFin == 2 then
                stateFromServer = XLuckyTenantEnum.GameState.GameOver
            end
        end

        local quest = self:GetQuest()
        if quest then
            -- normalClear是在失败时, 也可以结算
            if self:GetTotalScore() >= quest.Score then
                self._QuestHasBeenCompleted = self._QuestHasBeenCompleted + 1
                self:GetQuestReward(quest, model)
                if quest.NormalClear then
                    self._IsNormalClear = true
                end
                if quest.PerfectClear then
                    self:SetState(GameState.PerfectClear)
                else
                    local nextQuest = self:GetNextQuest()
                    if not nextQuest then
                        XMVCA.XLuckyTenant:Print("[XLuckyTenantGame] 没有配置通关，却没有下一个任务分数，有问题")
                        self:SetState(GameState.PerfectClear)
                        return
                    end
                    self:SetState(GameState.ShowNextQuestGoals)
                end
            else
                if self._IsNormalClear then
                    self:SetState(GameState.NormalClear)
                else
                    self:SetState(GameState.GameOver)
                end
            end
        else
            local nextQuest = self:GetNextQuest()
            if nextQuest then
                self:SetState(GameState.SelectPiece)
            else
                XMVCA.XLuckyTenant:Print("[XLuckyTenantGame] 状态错误，已经没有下一个任务分数，游戏应该被终结")
            end
        end

        if stateFromServer and self:GetState() ~= stateFromServer then
            -- 普通通关，服务端也认为是失败
            if not self:IsNormalClear() then
                XLog.Error("[XLuckyTenantGame] 和服务端的结算结果不一致， 服务端已经结束游戏了，客户端强制结束")
            end
            self:SetState(stateFromServer)
        end
        return
    end
    if gameState == GameState.ShowNextQuestGoals then
        self:SetState(GameState.SelectPiece)
        return
    end
end

function XLuckyTenantGame:GetQuest(round)
    round = round or self:GetRound()
    for i = 1, #self._Quest do
        local quest = self._Quest[i]
        if quest.Round == round then
            return quest
        end
    end
end

function XLuckyTenantGame:GetNextQuest(round)
    round = round or self:GetRound()
    for i = 1, #self._Quest do
        local quest = self._Quest[i]
        if round < quest.Round then
            return quest
        end
    end
end

function XLuckyTenantGame:GetCurrentQuest(round)
    round = round or self:GetRound()
    for i = 1, #self._Quest do
        local quest = self._Quest[i]
        if round <= quest.Round then
            return quest
        end
    end
end

function XLuckyTenantGame:GetQuestProgress()
    return self._QuestHasBeenCompleted, #self._Quest
end

function XLuckyTenantGame:IsNormalClear()
    return self._IsNormalClear
end

function XLuckyTenantGame:IsPerfectClear()
    return self._GameState == GameState.PerfectClear
end

function XLuckyTenantGame:IsGameOver()
    return self._GameState == GameState.GameOver
end

---@param quest XTable.XTableLuckyTenantStageTask
function XLuckyTenantGame:GetQuestReward(quest, model)
    local rewardPieces = quest.RewardPieces
    local rewardAmount = quest.RewardPiecesAmount
    for i = 1, #rewardPieces do
        local pieceId = rewardPieces[i]
        local amount = rewardAmount[i] or 1
        for i = 1, amount do
            self:AddNewPieceToBag(model, pieceId)
        end
    end
end

function XLuckyTenantGame:GetFreeRefreshTimes()
    if self:GetRound() == 1 then
        return self._FreeRefreshTimes
    end
    return 0
end

function XLuckyTenantGame:ReduceFreeRefreshTimes()
    self._FreeRefreshTimes = math.max(0, self._FreeRefreshTimes - 1)
end

function XLuckyTenantGame:SetHasSelectOrDelete(value)
    self._HasSelectOrDelete = value
end

function XLuckyTenantGame:SetTestCase(testCase)
    self._TestCase = testCase
end

function XLuckyTenantGame:RemoveTestCase()
    self._TestCase = false
end

function XLuckyTenantGame:GetStageId()
    return self._StageId
end

---@param model XLuckyTenantModel
function XLuckyTenantGame:Resume(model, record)
    self._Seed = XTime.GetServerNowTimestamp()
    math.randomseed(self._Seed)
    self._Round = record.Round
    self._TotalScore = record.Score

    if self._Round == 1 then
        self._FreeRefreshTimes = math.max(0, self._FreeRefreshTimes - record.SupplyRefresh + 1)
    end

    local quests = model:GetStageTasks(self._StageId)
    local questAmount = 0
    for i = 1, #quests do
        local quest = quests[i]
        if quest.Round < self._Round then
            questAmount = questAmount + 1
            if quest.NormalClear then
                self._IsNormalClear = true
            end
        else
            break
        end
    end
    self._QuestHasBeenCompleted = questAmount

    if record.RoundProgress == 1 then
        self._GameState = GameState.SelectPiece
        if #record.SuppleChess > 0 then
            self._HasSupplyChess = true
            self._IsDirtyPiecesToSelect = false
            self:UpdateRandomBucket(model, true)
            self._PiecesToSelect = {}
            for i = 1, #record.SuppleChess do
                local pieceId = record.SuppleChess[i]
                local piece = self._Bag:NewPiece(model, pieceId)
                self._PiecesToSelect[i] = piece
            end
        end
    elseif record.RoundProgress == 2 then
        self._GameState = GameState.Roll
    elseif record.RoundProgress == 3 then
        -- 客户端在动画补棋时回合数+1，服务端在播放动画前，回合数+1
        -- 这个阶段，其实是上一个回合的动画阶段
        -- 所以恢复游戏时，手动-1
        self._Round = self._Round - 1
        self._GameState = GameState.CheckQuestCompletionStatus
        XMVCA.XLuckyTenant:Print("恢复游戏，因为播放动画时退出，所以回合数-1为:" .. tostring(self._Round))
    end

    local bag = record.Bag
    if bag then
        for _, pieceData in pairs(bag) do
            local pieceId = pieceData.ChessId
            local isSuccess, piece = self:AddNewPieceToBag(model, pieceId, pieceData.Uid)
            if isSuccess then
                local message = XMessagePack.Decode(pieceData.ChessParams)
                piece:DecodeMessage(message)
            else
                XMVCA.XLuckyTenant:Error("[XLuckyTenantGame] 恢复棋子失败 id:" .. tostring(pieceId))
            end
        end
    end

    local chessboard = record.ChessBoard
    if chessboard then
        for i = 1, #chessboard do
            local uid = chessboard[i]
            if uid > 0 then
                local piece = self._Bag:GetPiece(uid)
                if piece then
                    self:GetChessboard():SetPieceByIndex(piece, i)
                else
                    XMVCA.XLuckyTenant:Print("[XLuckyTenantGame] 恢复棋子失败 uid:" .. tostring(uid))
                end
            end
        end
    end
    XMVCA.XLuckyTenant:Print("恢复游戏结束")
end

function XLuckyTenantGame:GetRecord()
    local record = {
        StageId = self._StageId,
        Round = self._Round,
        Score = self._TotalScore,
        IsNormalClear = self:IsNormalClear(),
    }
    return record
end

function XLuckyTenantGame:GetSeed()
    return self._Seed
end

function XLuckyTenantGame:HasSupplyChess()
    return self._HasSupplyChess
end

function XLuckyTenantGame:ClearHasSupplyChess()
    self._HasSupplyChess = false
end

function XLuckyTenantGame:GetRecord4Server()
    return self._Record
end

function XLuckyTenantGame:SetRoundFin(value)
    self._RoundFin = value
end

function XLuckyTenantGame:GetRoundFin()
    return self._RoundFin
end

return XLuckyTenantGame