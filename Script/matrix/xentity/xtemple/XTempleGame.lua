local GAME_STATE = {
    None = 0,
    Start = 1,
    Playing = 2,
    Settle = 3,
    End = 4,
}

local XTempleMap = require("XEntity/XTemple/Grid/XTempleMap")
local XTempleTimeOfDay = require("XEntity/XTemple/Weather/XTempleTimeOfDay")
local XTempleBlock = require("XEntity/XTemple/Grid/XTempleBlock")
local XTempleRule = require("XEntity/XTemple/Rule/XTempleRule")
local XTempleGrid = require("XEntity/XTemple/Grid/XTempleGrid")
local XTempleOption = require("XEntity/XTemple/Action/XTempleOption")
local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
local XTempleAction = require("XEntity/XTemple/Action/XTempleAction")
local TIME_OF_DAY = XTempleEnumConst.TIME_OF_DAY
local RULE = XTempleEnumConst.RULE
local GRID = XTempleEnumConst.GRID
local ACTION = XTempleEnumConst.ACTION

---@field _OwnControl XTempleGameControl
---@class XTempleGame:XEntity
local XTempleGame = XClass(XEntity, "XTempleGame")

function XTempleGame:Ctor()
    ---@type XTempleMap
    self._Map = self:AddChildEntity(XTempleMap)

    ---@type XTempleTimeOfDay[]
    self._TimeOfDay = {}
    self._TimeIndex = 1

    self._State = GAME_STATE.None
    self._Timer = false
    self._SpendTime = 0
    self._Score = 0
    self._Round = 0

    ---@type XTempleRule[]
    self._PublicRules = {}

    ---@type XQueue
    self._ActionQueue = XQueue.New()

    ---@type XTempleGameActionRecord[]
    self._ActionRecord = {}

    self._EditingBlock = false
    self._EditingOptionId = false

    self._RuleId = 0

    self._RandomSeed = 51

    self._ScoreRecord = {}

    self._OptionScoreRecord = 0
    self._ScoreDetailRecord = {}
    self._ScoreDetail2Send = {}

    self._MapSize = XTempleEnumConst.MAP_SIZE

    ---@type XTempleOption[][]
    self._Options = {}
    ---@type XTempleOption[]
    self._OptionDict = {}
    self._OptionRound = 0

    self._IsSimulating = false
    self._EndLess = false
    self._IsEditor = false
end

function XTempleGame:SetMapSize(mapSize)
    self._MapSize = mapSize
end

function XTempleGame:GetMapSize()
    return self._MapSize
end

---@return XTempleMap
function XTempleGame:GetMap()
    return self._Map
end

function XTempleGame:Start()
    self:UpdatePublicRules()
    self:NextOptionRound()
    self._State = GAME_STATE.Start
    self:UpdateScore()
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_TALK, XTempleEnumConst.NPC_TALK.STAGE_ENTER)
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:Update()
        end, 0)
    end
end

function XTempleGame:Stop()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XTempleGame:InstantUpdate()
    for i = 1, 999 do
        if not self:Update() then
            break
        end
    end
end

function XTempleGame:Update()
    -- 等待服务端回调
    if XMVCA.XTemple:IsRequesting() then
        return
    end
    if self._State == GAME_STATE.Start then
        self._State = GAME_STATE.Playing
        self:SendShowTimeEvent()
        return true
    end
    if self._State == GAME_STATE.Playing then
        ---@type XTempleAction
        local action = self._ActionQueue:Dequeue()
        if action then
            action:Execute(self)
            return true
        end
        return false
    end
    if self._State == GAME_STATE.Settle then
        if not self:IsEditor() then
            --XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_TALK, XTempleEnumConst.NPC_TALK.SUCCESS)
            XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_SETTLE)
        end
        self._State = GAME_STATE.End
        return false
    end
    if self._State == GAME_STATE.End then
        -- 结束
        return false
    end
    return false
end

function XTempleGame:NextRound(spendTime)
    self._Round = self._Round + 1
    self._SpendTime = self._SpendTime + spendTime

    local currentTime = self:GetCurrentTime()
    if not currentTime then
        self:SetEnd()
        return false
    end

    if currentTime:IsOverThisTime(self._SpendTime) then
        self:SaveScore()
        self._SpendTime = 0
        self._TimeIndex = self._TimeIndex + 1
        if not self:GetCurrentTime() then
            self:SetEnd()
            return
        else
            self:SendShowTimeEvent()
            self:UpdatePublicRules()
            self:SaveExecutedRecord()

            -- 切季节的时候, 重置分数记录
            self._ScoreDetailRecord = {}
            self:UpdateScore()
        end
    end
    self:NextOptionRound()
    return true
end

function XTempleGame:SendShowTimeEvent()
    if not self:IsEditor() then
        XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_SHOW_TIME, self:GetCurrentTime():GetType())
    end
end

function XTempleGame:SetEnd()
    self._State = GAME_STATE.Settle
end

function XTempleGame:UpdateScore()
    local map = self._Map
    local score = 0
    local currentTime = self:GetCurrentTime()

    for i = 1, #self._PublicRules do
        local rule = self._PublicRules[i]
        local tempScore = rule:Execute(map, currentTime)
        rule:SetScore(tempScore)
        local isActive = rule:IsActive()
        if isActive then
            score = score + tempScore
        end
    end

    self:SaveScoreDetail()
    self:SetCurrentTimeScore(score, currentTime)
    self:UpdateGridScore()
    return score
end

function XTempleGame:SaveScoreDetail()
    local oldRecord = self._ScoreDetailRecord
    self._ScoreDetailRecord = {}
    for i = 1, #self._PublicRules do
        local rule = self._PublicRules[i]
        if rule:IsActive() then
            local tempScore = rule:GetScore()
            local ruleId = rule:GetId()
            self._ScoreDetailRecord[ruleId] = tempScore

            local recordScore = oldRecord[ruleId] or 0
            local addScore = tempScore - recordScore
            if addScore ~= 0 then
                local oldScore = self._ScoreDetail2Send[ruleId] or 0
                self._ScoreDetail2Send[ruleId] = oldScore + addScore
            end
        end
    end
end

function XTempleGame:GetEditingBlock()
    return self._EditingBlock
end

function XTempleGame:IsEditingBlock()
    if self._EditingBlock then
        return true
    end
    return false
end

---@param block XTempleBlock
function XTempleGame:SetEditingBlock(block)
    self._EditingBlock = block
end

function XTempleGame:SetEditingOption(optionId)
    self._EditingOptionId = optionId
end

function XTempleGame:GetEditingOptionId()
    return self._EditingOptionId
end

function XTempleGame:RemoveEditingBlock()
    self._EditingBlock = false
end

---@return XTempleRule[]
function XTempleGame:GetPublicRules()
    return self._PublicRules
end

function XTempleGame:GetRuleById(id)
    for i = 1, #self._PublicRules do
        local rule = self._PublicRules[i]
        if rule:GetId() == id then
            return rule
        end
    end
end

function XTempleGame:UpdatePublicRules()
    for i = 1, #self._PublicRules do
        local rule = self._PublicRules[i]
        local isActive = rule:IsRuleActive(self:GetCurrentTime())
        rule:SetIsActive(isActive)
    end
end

function XTempleGame:GetRuleId()
    self._RuleId = self._RuleId + 1
    return self._RuleId
end

function XTempleGame:EditorInitFromBlockConfig(blockConfig)
    self._Map:EditorInitAllBlocks(blockConfig)
end

---@param gameConfig XTableTempleStageGame[]
function XTempleGame:InitFromGameConfig(gameConfig)
    math.randomseed(self._RandomSeed)

    --region map
    local map = {}
    for j = 1, self._MapSize do
        local config = gameConfig[j]
        local lineConfig = config and config.Map
        local line = {}
        for i = 1, self._MapSize do
            line[i] = lineConfig and lineConfig[i] or 0
        end
        table.insert(map, 1, line)
    end
    local mapGrids = self._OwnControl:GenerateGrids(map)
    self._Map:SetGrids(mapGrids)
    --endregion

    --region rule
    local ruleEntities = {}
    for i = 1, #gameConfig do
        local config = gameConfig[i]
        local ruleId = config.RuleId
        if ruleId == 0 then
            break
        end
        local timeArray = config.RuleTime
        local time = 0
        for i = 1, #timeArray do
            local configTime = timeArray[i]
            if configTime > 0 then
                time = time | (1 << (configTime - 1))
            end
        end

        ---@type XTempleRule
        local rule = self:AddChildEntity(XTempleRule)
        rule:SetData({
            Type = config.RuleType,
            Params = config.RuleParams,
            Id = ruleId,
            Score = config.RuleScore,
            TimeOfDay = time,
            Name = config.RuleName,
            IsHide = config.RuleIsHide
        })
        ruleEntities[#ruleEntities + 1] = rule
    end
    self._PublicRules = ruleEntities
    --endregion

    --region option
    for i = 1, #gameConfig do
        local config = gameConfig[i]
        local round = config.OptionRound
        if round == 0 then
            break
        end
        self._Options[round] = self._Options[round] or {}

        local optionId = config.OptionId
        local optionBlockId = config.OptionBlock
        local optionReward = config.OptionReward
        local optionSpend = config.OptionSpend
        if optionBlockId and optionBlockId ~= 0 then
            ---@type XTempleOption
            local option = self:CreateOption()
            option:SetBlockId(optionBlockId)
            option:SetRound(round)
            option:SetIsExtraScore(optionReward)
            option:SetSpend(optionSpend)
            option:SetId(optionId)
            self:AddOption(option)
        end
    end
    --endregion

    --region Time
    local timeArray = {}
    for i = 1, #gameConfig do
        local config = gameConfig[i]
        local time = config.Time
        if time > 0 then
            ---@type XTempleTimeOfDay
            local timeOfDay = self:AddTimeOfDay()
            timeOfDay:SetType(time)

            local duration = config.TimeDuration
            timeOfDay:SetDuration(duration)
            timeArray[#timeArray + 1] = timeOfDay
        end
    end
    table.sort(timeArray, function(a, b)
        return a:GetType() < b:GetType()
    end)
    self._TimeOfDay = timeArray
    --endregion
end

function XTempleGame:GetTimeArray()
    return self._TimeOfDay
end

function XTempleGame:NextOptionRound()
    self._OptionRound = self._OptionRound + 1
    if XMain.IsDebug then
        local str = "刷新选项:"
        local options = self:GetCurrentOptionsExceptSkip()
        for i = 1, #options do
            ---@type XTempleOption
            local option = options[i]
            str = str .. option:GetBlockId() .. " | "
        end
        XLog.Debug(str)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_TALK, XTempleEnumConst.NPC_TALK.REFRESH_BLOCK)
end

function XTempleGame:EnqueueAction(action)
    self._ActionQueue:Enqueue(action)
end

function XTempleGame:SetCurrentTimeScore(score, time)
    if not time then
        return
    end
    local type = time:GetType()
    self._ScoreRecord[type] = score
end

function XTempleGame:AddScore(score)
    self._Score = self._Score + score
end

function XTempleGame:InsertEditingBlock(optionId, noSpend)
    if not self:IsEditingBlock() then
        return
    end
    local block = self:GetEditingBlock()
    local map = self:GetMap()
    if map:InsertBlock(block, self._OptionRound) then
        if not self._IsSimulating then
            local position = block:GetPosition()
            local round = self._OptionRound
            ---@class XTempleGameActionRecord
            local record = {
                BlockId = block:GetId(),
                X = position.x,
                Y = position.y,
                Round = round,
                OptionId = optionId,
                Rotation = block:GetRotation()
            }
            self:SetActionRecord(record, round)
        end

        local currentTime = self:GetCurrentTime()
        local option = self:GetOptionById(optionId)
        local optionScore = 0
        if option then
            optionScore = option and option:GetScore(currentTime)
            self:AddScore(optionScore)
            self._OptionScoreRecord = optionScore
        end
        local oldScore = self:GetScore(currentTime:GetType())
        local score = self:UpdateScore()
        if not self:IsSimulating() and currentTime then
            score = score - oldScore + optionScore
            self._OwnControl:PlayMusicScore(score)
        end

        self:RemoveEditingBlock()

        local spendTime = option and option:GetSpend() or 0
        if noSpend then
            spendTime = 0
        end
        self:NextRound(spendTime)
        return true
    end
    return false
end

function XTempleGame:GetScore(timeType)
    if timeType == nil then
        return self._Score
    end
    return self._ScoreRecord[timeType] or 0
end

function XTempleGame:GetRound()
    return self._SpendTime
end

function XTempleGame:AddBlock()
    return self._OwnControl:AddEntity(XTempleBlock)
end

function XTempleGame:AddGrid()
    return self:AddChildEntity(XTempleGrid)
end

function XTempleGame:ClearActionRecord()
    self._ActionRecord = {}
end

function XTempleGame:AddRule()
    ---@type XTempleRule
    local rule = self:AddChildEntity(XTempleRule)
    local ruleId = #self._PublicRules + 1
    rule:SetData({
        Type = RULE.DEFAULT,
        Params = {},
        Id = ruleId,
        Score = 1,
        TimeOfDay = 0,
        Name = "",
    })
    self._PublicRules[#self._PublicRules + 1] = rule
    return rule
end

function XTempleGame:RemoveRule(rule2Remove)
    for i = 1, #self._PublicRules do
        local rule = self._PublicRules[i]
        if rule:GetId() == rule2Remove:GetId() then
            table.remove(self._PublicRules, i)
            return
        end
    end
end

---@return XTempleTimeOfDay
function XTempleGame:GetCurrentTime()
    return self._TimeOfDay[self._TimeIndex]
end

function XTempleGame:GetTailTime()
    return self._TimeOfDay[#self._TimeOfDay]
end

function XTempleGame:GetSpendTime()
    return self._SpendTime
end

function XTempleGame:GetTimeArray()
    return self._TimeOfDay
end

function XTempleGame:AddTimeOfDay()
    return self:AddChildEntity(XTempleTimeOfDay)
end

function XTempleGame:GetAllOptions()
    return self._Options
end

function XTempleGame:GetNewRoundIndex()
    return #self._Options + 1
end

---@return XTempleOption[]
function XTempleGame:GetOptionsByRound(optionRound, is4Write)
    if is4Write then
        self._Options[optionRound] = self._Options[optionRound] or {}
    end
    return self._Options[optionRound]
end

function XTempleGame:GetCurrentOptions()
    return self._Options[self._OptionRound]
end

function XTempleGame:GetCurrentOptionsExceptSkip()
    local options = self:GetCurrentOptions()
    if not options then
        return {}
    end
    local result = {}
    for i = 1, #options do
        local option = options[i]
        if not option:IsSkip() then
            result[#result + 1] = option
        end
    end
    return result
end

function XTempleGame:SetEndlessTime4Edit()
    if XTool.IsTableEmpty(self._TimeOfDay) then
        ---@type XTempleTimeOfDay
        local time = self:AddTimeOfDay()
        time:SetType(TIME_OF_DAY.MORNING)
        time:SetDuration(math.huge)
        self._TimeOfDay = { time }
    end
    self._EndLess = true
end

function XTempleGame:GetOptionRound()
    return self._OptionRound
end

function XTempleGame:SetOptionRound(value)
    self._OptionRound = value
end

function XTempleGame:GetActionRecords()
    return self._ActionRecord
end

function XTempleGame:GetLastestActionRecord()
    return self._ActionRecord[#self._ActionRecord]
end

function XTempleGame:HandleActionRecord4Save()
    for i = #self._Options + 1, #self._ActionRecord do
        self._ActionRecord[i] = nil
    end

    --Sparse array
    local max = 0
    for i, v in pairs(self._ActionRecord) do
        max = math.max(i, max)
    end
    for i = 1, max do
        if not self._ActionRecord[i] then
            self:SetActionRecord(nil, i)
        end
    end
end

function XTempleGame:SetActionRecords(records)
    self._ActionRecord = records
end

function XTempleGame:SetActionRecord(record, round)
    if self:IsSimulating() then
        return
    end
    self._ActionRecord[round] = record or {
        BlockId = 0,
        X = 0,
        Y = 0,
        Round = round,
        OptionId = 0,
        Rotation = 0,
    }
end

function XTempleGame:SimulateActionRecordFromData(actionRecord, beginIndex, endIndex, confirm, noSpendTime)
    beginIndex = beginIndex or 1
    endIndex = endIndex or #actionRecord
    if confirm == nil then
        confirm = true
    end
    self._IsSimulating = true
    for i = beginIndex, endIndex do
        local record = actionRecord[i]
        if record then
            local blockId = record.BlockId
            if self._Map:GetBlockById(blockId) then
                local optionId = record.OptionId
                ---@type XTempleAction
                local actionPutDown = XTempleAction.New()
                actionPutDown:SetData({
                    Type = ACTION.PUT_DOWN,
                    BlockId = blockId,
                    OptionId = optionId,
                })
                self:EnqueueAction(actionPutDown)

                if record.Rotation and record.Rotation > 0 then
                    local index = record.Rotation / 90
                    for i = 1, index do
                        ---@type XTempleAction
                        local actionRotate = XTempleAction.New()
                        actionRotate:SetData({
                            Type = ACTION.ROTATE,
                            Rotation = record.Rotation
                        })
                        self:EnqueueAction(actionRotate)
                    end
                end

                local x = record.X
                local y = record.Y
                ---@type XTempleAction
                local actionMove = XTempleAction.New()
                actionMove:SetData({
                    Type = ACTION.DRAG,
                    Position = XLuaVector2.New(x, y)
                })
                self:EnqueueAction(actionMove)

                if confirm then
                    ---@type XTempleAction
                    local actionConfirm = XTempleAction.New()
                    actionConfirm:SetData({
                        Type = ACTION.CONFIRM,
                        NoSpend = noSpendTime,
                    })
                    self:EnqueueAction(actionConfirm)
                end
            else
                ---@type XTempleAction
                local actionSkip = XTempleAction.New()
                actionSkip:SetData({
                    Type = ACTION.SKIP,
                    NoSpend = noSpendTime,
                })
                self:EnqueueAction(actionSkip)
            end
        end
    end

    self:InstantUpdate()
    self._IsSimulating = false
    XEventManager.DispatchEvent(XEventId.EVENT_TEMPLE_UPDATE_GAME)
end

function XTempleGame:SimulateActionRecord(beginIndex, endIndex, confirm, noSpendTime)
    self:SimulateActionRecordFromData(self._ActionRecord, beginIndex, endIndex, confirm, noSpendTime)
end

function XTempleGame:IsSimulating()
    return self._IsSimulating
end

function XTempleGame:GetNextOptionId()
    return #self._OptionDict + 1
end

---@param option XTempleOption
function XTempleGame:AddOption(option, index)
    local round = option:GetRound()
    if not self._Options[round] then
        self._Options[round] = {}
    end
    if index then
        table.insert(self._Options[round], index, option)
    else
        table.insert(self._Options[round], option)
    end
    if self._OptionDict[option:GetId()] then
        XLog.Error("[XTempleGame] 有重复option加入", option:GetId())
    end
    self._OptionDict[option:GetId()] = option
end

---@param option XTempleOption
function XTempleGame:RemoveOption(option)
    self._OptionDict[option:GetId()] = nil

    local round = option:GetRound()
    local options = self._Options[round]
    for i = 1, #options do
        if options[i]:GetId() == option:GetId() then
            table.remove(self._Options, i)
            return true
        end
    end
    return false
end

function XTempleGame:RemoveRound(round)
    local options = self._Options[round]
    if options then
        for i = 1, #options do
            local option = options[i]
            self._OptionDict[option:GetId()] = nil
        end
    end

    if self._Options[round] then
        table.remove(self._Options, round)
        return true
    end
    return false
end

---@return XTempleOption
function XTempleGame:GetOptionById(optionId)
    return self._OptionDict[optionId]
end

function XTempleGame:SaveScore()
    local currentTime = self:GetCurrentTime()
    local score = 0
    for i = 1, #self._PublicRules do
        local rule = self._PublicRules[i]
        if rule:IsRuleActive(currentTime) then
            score = score + rule:GetScore()
        end
    end
    self:SetCurrentTimeScore(score, currentTime)
    self:AddScore(score)
end

function XTempleGame:SetEditor()
    self._IsEditor = true
end

function XTempleGame:CreateOption()
    ---@type XTempleOption
    local option = self:AddChildEntity(XTempleOption)
    return option
end

function XTempleGame:ResetState()
    self._State = GAME_STATE.Playing
end

function XTempleGame:IsEditor()
    return self._IsEditor
end

function XTempleGame:IsPlaying()
    return self._State == GAME_STATE.Playing
end

---@return number 实时分数
function XTempleGame:GetRealTimeScore()
    local currentTime = self:GetCurrentTime()
    if not currentTime then
        return self:GetScore()
    end
    local timeScore = self:GetScore(currentTime:GetType())
    local score = self:GetScore()
    return timeScore + score
end

function XTempleGame:GetRealTimeScoreDetail()
    local scoreDetail = self._ScoreDetail2Send
    if self._OptionScoreRecord ~= 0 then
        scoreDetail[0] = self._OptionScoreRecord
    end
    self._ScoreDetail2Send = {}
    return scoreDetail
end

function XTempleGame:UpdateGridScore()
    for i = 1, #self._PublicRules do
        local rule = self._PublicRules[i]
        if rule:GetIsHide() then
            local gridId = rule:GetKeyParams()
            if gridId then
                local gridType = self._OwnControl:GetGridType(gridId)
                for y = 1, self._Map:GetRowAmount() do
                    for x = 1, self._Map:GetColumnAmount() do
                        local grid = self._Map:GetGrid(x, y)
                        if grid:IsType(gridType) then
                            local score = rule:GetRewardScore()
                            if score > 0 then
                                if rule:IsGridExecuted(grid) then
                                    grid:SetScore(0)
                                    grid:SetRule(false)
                                else
                                    grid:SetScore(score)
                                    grid:SetRule(rule)
                                end
                            else
                                if rule:IsGridExecuted(grid) then
                                    grid:SetScore(score)
                                    grid:SetRule(rule)
                                else
                                    grid:SetScore(0)
                                    grid:SetRule(false)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

function XTempleGame:GetEncodeMap()
    local encodeMap = {}
    for y = 1, self._Map:GetRowAmount() do
        for x = 1, self._Map:GetColumnAmount() do
            local grid = self._Map:GetGrid(x, y)
            if not grid:IsEmpty() then
                encodeMap[#encodeMap + 1] = { Id = grid:GetId(), Rotation = grid:GetRotation(), X = x, Y = y }
            end
        end
    end
    return encodeMap
end

---@param block XTempleBlock
function XTempleGame:ClampBlockPosition(block, x, y)
    local anchorPosition = block:GetAnchorPosition()
    local toLeft = anchorPosition.x
    local toDown = anchorPosition.y
    local map = self:GetMap()
    local toRight = map:GetColumnAmount() - (block:GetColumnAmount() - anchorPosition.x)
    local toUp = map:GetRowAmount() - (block:GetRowAmount() - anchorPosition.y)

    x = XMath.Clamp(x, toLeft, toRight)
    y = XMath.Clamp(y, toDown, toUp)
    return x, y
end

function XTempleGame:PlayMusicInsertFail()
    self._OwnControl:PlayMusicInsertFail()
end

function XTempleGame:RemoveOptionScoreRecord()
    self._OptionScoreRecord = 0
end

-- 初始规则 且 得分大于0的规则, 只生效一次, 需要继承记录
function XTempleGame:SaveExecutedRecord()
    for i = 1, #self._PublicRules do
        local rule = self._PublicRules[i]
        if rule:GetIsHide() and rule:GetRewardScore() > 0 then
            rule:SaveExecutedRecord()
        end
    end
end

function XTempleGame:ClearActionQueue()
    self._ActionQueue:Clear()
end

return XTempleGame
