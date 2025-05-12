local XTemple2Map = require("XModule/XTemple2/Game/XTemple2Map")
local XTemple2Block = require("XModule/XTemple2/Game/XTemple2Block")
local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")
local XTemple2Grid = require("XModule/XTemple2/Game/XTemple2Grid")
local XTemple2AStar = require("XModule/XTemple2/Game/XTemple2AStar")
local XTemple2Animation = require("XModule/XTemple2/Game/XTemple2Animation")
local XTemple2Rule = require("XModule/XTemple2/Game/XTemple2Rule")
local RULE = XTemple2Enum.RULE
local SCORE_TYPE = XTemple2Enum.SCORE_TYPE

local STATE = {
    NONE = 0,
    START = 1,
    SET_BLOCK = 2,
}

---@class XTemple2Game
local XTemple2Game = XClass(nil, "XTemple2Game")

function XTemple2Game:Ctor()
    ---@type XTemple2Map
    self._Map = XTemple2Map.New()

    self._State = STATE.NONE

    ---@type XTemple2Block[]
    self._AllBlock = {}

    ---@type XTemple2Block[]
    self._BlockPool = {}

    ---@type XTemple2Block[]
    self._BlockRandomPool = {}

    ---@type XTemple2Block[]
    self._BlockRandomPoolResult = false

    ---@type XTemple2AStar
    self._AStar = XTemple2AStar.New()

    ---@type XTemple2Animation
    self._Animation = XTemple2Animation.New()

    self._NpcId = 0

    ---@alias XTemple2GameRule {Rule:XTemple2Rule,Grids:XTemple2Grid[]}[]
    ---@type XTemple2GameRule[]
    self._AllRules = {}

    self._Grid2Rule = {}

    self._OperationUid = 1
    ---@type XTemple2GameOperation[]
    self._Operations = {}

    self._IsSettle = false

    self._RandomPoolAmount = 0

    self._Seed = 0

    self._PlotIds = {}

    self._Score = {
        [SCORE_TYPE.TOTAL_SCORE] = 0,
        [SCORE_TYPE.GRID_SCORE] = 0,
        [SCORE_TYPE.PATH_SCORE] = 0,
        [SCORE_TYPE.LIKE_SCORE] = 0,
        [SCORE_TYPE.TASK_SCORE] = 0,
    }

    self._Score4Rule = {}

    ---@type XLuaVector2
    self._StartPos = XLuaVector2.New()
    ---@type XLuaVector2
    self._EndPos = XLuaVector2.New()
end

function XTemple2Game:SetNpcId(npcId)
    self._NpcId = npcId
end

function XTemple2Game:GetNpcId()
    return self._NpcId
end

function XTemple2Game:SetSeed(value)
    self._Seed = value or 0
end

function XTemple2Game:GetSeed()
    return self._Seed
end

---@param model XTemple2Model
function XTemple2Game:InitGame(gameConfig, model, mapConfig)
    self._OperationUid = 1

    self._Map:Init(gameConfig, model)

    self._BlockPool = {}
    self._BlockRandomPool = {}

    if gameConfig[1] then
        local blockPool = gameConfig[1].BlockPool
        if blockPool then
            for i = 1, #blockPool do
                local blockId = blockPool[i]
                local block = self:GetBlock(blockId)
                if block then
                    self._BlockPool[#self._BlockPool + 1] = block
                end
            end
        end

        local randomBlockPool = gameConfig[1].RandomBlockPool
        if randomBlockPool then
            for i = 1, #randomBlockPool do
                local blockId = randomBlockPool[i]
                local block = self:GetBlock(blockId)
                if block then
                    self._BlockRandomPool[#self._BlockRandomPool + 1] = block
                end
            end
        end

        local randomPoolAmount = gameConfig[1].RandomPoolAmount
        self._RandomPoolAmount = randomPoolAmount or 0
    end

    self:InitRules(model, mapConfig)
end

---@param model XTemple2Model
function XTemple2Game:InitRules(model, stageConfig)
    self._AllRules = {}
    local allRules = {}
    local rulesFromStage = stageConfig.Rule
    for i = 1, #rulesFromStage do
        local ruleId = rulesFromStage[i]
        allRules[ruleId] = XTemple2Enum.RULE_EFFECTIVE_RANGE.GLOBAL
    end

    -- 地块用到的格子
    local usedGrids = {}
    local pool = self:GetBlockPool()
    for i = 1, #pool do
        local block = pool[i]
        if block:CheckIsSelected4FavouriteRule(self, model) then
            self:_FindBlockUsedGrids(block, usedGrids, model)
        end
    end

    -- 随机地块用到的格子
    local randomPool = self:GetBlockRandomPool()
    for i = 1, #randomPool do
        local block = randomPool[i]
        if block:CheckIsSelected4FavouriteRule(self, model) then
            self:_FindBlockUsedGrids(block, usedGrids, model)
        end
    end

    -- 地图上用到的格子
    local map = self:GetMap()
    local row = map:GetRowAmount()
    local column = map:GetColumnAmount()
    for y = 1, row do
        for x = 1, column do
            local grid = map:GetGrid(x, y)
            usedGrids[grid:GetId()] = true
        end
    end

    for id, _ in pairs(usedGrids) do
        local config = model:GetGrid(id)
        local rules = config.Rule
        self._Grid2Rule[id] = rules
        for i = 1, #rules do
            local ruleId = rules[i]
            if not allRules[ruleId] then
                allRules[ruleId] = XTemple2Enum.RULE_EFFECTIVE_RANGE.GRID
            end
        end
    end

    for ruleId, effectiveRange in pairs(allRules) do
        if not self._AllRules[ruleId] then
            local config = model:GetRule(ruleId)
            if config then
                ---@type XTemple2Rule
                local rule = XTemple2Rule.New()
                rule:Init(config)
                self._AllRules[ruleId] = {
                    Rule = rule,
                    Grids = {},
                }
                if effectiveRange == XTemple2Enum.RULE_EFFECTIVE_RANGE.GLOBAL then
                    rule:SetIsGlobal(true)
                end
            else
                XLog.Error("[XTemple2Game] 关卡配置的规则,不存在:", ruleId)
            end
        end
    end

    if XMain.IsEditorDebug then
        local str = ""
        for ruleId, _ in pairs(self._AllRules) do
            str = str .. ruleId .. ","
        end
        XLog.Debug("[XTemple2Game] 规则包括:", str)
    end
end

---@param block XTemple2Block
---@param model XTemple2Model
function XTemple2Game:_FindBlockUsedGrids(block, result, model, favouriteGrids)
    local row = block:GetRowAmount()
    local column = block:GetColumnAmount()
    for y = 1, column do
        for x = 1, row do
            local grid = block:GetGrid(x, y)
            local gridId = grid:GetId()
            if result[gridId] == nil then
                ---@type XTable.XTableTemple2Grid
                local gridConfig = model:GetGrid(gridId)
                if gridConfig and gridConfig.ShowOnStageDetail == 1 then
                    result[gridId] = gridConfig
                    if favouriteGrids and block:IsFavouriteBlock() then
                        favouriteGrids[gridId] = true
                    end
                else
                    result[gridId] = false
                end
            end
        end
    end
end

---@param allBlockConfig XTable.XTableTemple2Block[]
---@param model XTemple2Model
function XTemple2Game:InitBlocks(allBlockConfig, model)
    self._AllBlock = {}

    for _, config in pairs(allBlockConfig) do
        ---@type XTemple2Block
        local block = XTemple2Block.New()
        block:SetId(config.Id)
        block:SetName(config.Name)
        block:SetTypeName(config.TypeName)
        block:SetEffectiveTimes(config.EffectiveTimes)
        block:SetNoRotate(config.NoRotate)

        local tempGrids = {}
        for j = 1, XTemple2Enum.BLOCK_SIZE.X do
            tempGrids[j] = config["Grid" .. j]
        end

        local grids = self:GenerateGrids(tempGrids, model)
        block:SetGrids(grids)
        self._AllBlock[#self._AllBlock + 1] = block
        block:InitFavouriteNpcId(model)
    end
    table.sort(self._AllBlock, function(a, b)
        return a:GetId() < b:GetId()
    end)
end

function XTemple2Game:GetGrids()
    return self._Map:GetGrids()
end

---@return XTemple2Map
function XTemple2Game:GetMap()
    return self._Map
end

function XTemple2Game:IncreaseCurrentEffectiveTimes(blockId)
    local blockOriginal = self:GetBlock(blockId)
    if blockOriginal then
        blockOriginal:IncreaseCurrentEffectiveTimes()
    else
        XLog.Error("[XTemple2GameControl] 增加使用次数失败:", blockId)
    end
end

function XTemple2Game:DecreaseCurrentEffectiveTimes(blockId)
    local blockOriginal = self:GetBlock(blockId)
    if blockOriginal then
        blockOriginal:DecreaseCurrentEffectiveTimes()
    else
        XLog.Error("[XTemple2GameControl] 增加使用次数失败:", blockId)
    end
end

---@param block XTemple2Block
function XTemple2Game:InsertBlock(block, operationUid)
    if not block then
        return false
    end
    local map = self:GetMap()
    if map:InsertBlock(block, operationUid or self._OperationUid) then
        -- 已有操作,不需记录
        if not operationUid then
            local position = block:GetPosition()
            ---@class XTemple2GameOperation
            local operation = {
                Round = self._OperationUid,
                BlockId = block:GetId(),
                Rotation = block:GetRotation(),
                X = position.x,
                Y = position.y,
                IsSendRequest = false,
            }
            self._Operations[#self._Operations + 1] = operation
            self._OperationUid = self._OperationUid + 1
        end
        return true
    end
    return false
end

function XTemple2Game:GetAllBlock()
    return self._AllBlock
end

function XTemple2Game:Add2AllBlock(block)
    self._AllBlock[#self._AllBlock + 1] = block
end

function XTemple2Game:GetBlockPool()
    return self._BlockPool
end

function XTemple2Game:GetBlockRandomPool()
    return self._BlockRandomPool
end

function XTemple2Game:GetBlockRandomPoolResult()
    local seed = self:GetSeed()
    if seed == 0 then
        XLog.Error("[XTemple2Game] 未赋值的随机种子，有问题")
        return self._BlockRandomPool
    end
    if self._BlockRandomPoolResult then
        return self._BlockRandomPoolResult
    end
    local luckyList = {}
    local blockRandomPool = self:GetBlockRandomPool()
    if seed == 0 then
        XLog.Error("[XTemple2Game] 未赋值的随机种子，有问题")
    end
    math.randomseed(seed)
    local randomPool = {}
    local randomAmount = self:GetRandomPoolAmount()
    local size = #blockRandomPool
    for i = 1, size do
        randomPool[i] = blockRandomPool[i]
    end
    if randomAmount > size then
        randomAmount = size
        XLog.Warning("[XTemple2Game] 随机需要的数量，超出了已选择的地块数量，检查配置")
    end
    for i = 1, randomAmount do
        local luckyGuy = math.random(1, #randomPool)
        luckyList[#luckyList + 1] = table.remove(randomPool, luckyGuy)
    end
    self._BlockRandomPoolResult = luckyList
    return luckyList
end

function XTemple2Game:Add2BlockPool(block)
    if self:IsOnPool(block) then
        return false
    end
    self._BlockPool[#self._BlockPool + 1] = block
    return true
end

function XTemple2Game:Add2BlockRandomPool(block)
    if self:IsOnRandomPool(block) then
        return false
    end
    self._BlockRandomPool[#self._BlockRandomPool + 1] = block
    return true
end

function XTemple2Game:IsOnPool(block)
    for i = 1, #self._BlockPool do
        if self._BlockPool[i]:Equals(block) then
            return true
        end
    end
    return false
end

function XTemple2Game:IsOnRandomPool(block)
    for i = 1, #self._BlockRandomPool do
        if self._BlockRandomPool[i]:Equals(block) then
            return true
        end
    end
    return false
end

function XTemple2Game:RemoveFromPool(block)
    for i = 1, #self._BlockPool do
        if self._BlockPool[i]:Equals(block) then
            table.remove(self._BlockPool, i)
            return true
        end
    end
    return false
end

function XTemple2Game:RemoveFromRandomPool(block)
    for i = 1, #self._BlockRandomPool do
        if self._BlockRandomPool[i]:Equals(block) then
            table.remove(self._BlockRandomPool, i)
            return true
        end
    end
    return false
end

-- 注意事项, 配置生成数组时, 中间为空项会被跳过, 必须填值
---@param model XTemple2Model
function XTemple2Game:GenerateGrids(map, model)
    local grids = {}
    for y = 1, #map do
        local list = map[y]
        local countX = #list
        for x = 1, countX do
            local encodeInfo = list[x]
            ---@type XTemple2Grid
            local grid = XTemple2Grid.New()
            grids[x] = grids[x] or {}
            grids[x][y] = grid
            grid:SetEncodeInfo(encodeInfo)
            grid:SetPosition(x, y)
            local id = grid:GetId()
            local gridConfig = model:GetGrid(id)
            grid:SetConfig(gridConfig)

            -- 向前遍历, 填满空格
            for i = y - 1, 1, -1 do
                if grids[x][i] == nil then
                    local emptyGrid = XTemple2Grid.New()
                    grids[x][i] = emptyGrid
                    emptyGrid:SetPosition(x, i)
                else
                    break
                end
            end
        end
    end
    return grids
end

---@return XTemple2Block
function XTemple2Game:GetBlock(blockId)
    for i = 1, #self._AllBlock do
        local block = self._AllBlock[i]
        if block:GetId() == blockId then
            return block
        end
    end
    return false
end

function XTemple2Game:ClearPool()
    self._BlockPool = {}
    self._BlockRandomPool = {}
end

function XTemple2Game:GetEntrance()
    --local map = self:GetMap()
    --local maxY = map:GetRowAmount()
    --local maxX = map:GetColumnAmount()
    --local startPos, endPos
    ---- 隐藏规则，多个出口的情况下，以id大的为出口
    --local startId, endId = 0, 0
    --for y = 1, maxY do
    --    for x = 1, maxX do
    --        local grid = map:GetGrid(x, y)
    --        if grid:IsStartPoint() then
    --            if grid:GetId() > startId then
    --                startPos = grid:GetPosition()
    --                startId = grid:GetId()
    --            end
    --        elseif grid:IsEndPoint() then
    --            if grid:GetId() > endId then
    --                endPos = grid:GetPosition()
    --                endId = grid:GetId()
    --            end
    --        end
    --    end
    --end
    --return startPos, endPos
    return self._StartPos, self._EndPos
end

--TODO by zlb 缓存喜好格
---@return XTemple2Grid, XTemple2Rule
function XTemple2Game:GetFavouriteGrid()
    local startPos = self:GetEntrance()
    if not startPos then
        return false
    end
    local startX, startY = startPos.x, startPos.y
    local map = self:GetMap()
    local maxY = map:GetRowAmount()
    local maxX = map:GetColumnAmount()
    -- 找最近的
    local favouriteGrid, favouriteRule
    local favouriteDistance = math.huge
    for y = 1, maxY do
        for x = 1, maxX do
            local grid = map:GetGrid(x, y)
            local ruleIdArray = grid:GetRule()
            if ruleIdArray then
                for i = 1, #ruleIdArray do
                    local rule = self:GetRule(ruleIdArray[i])
                    if rule then
                        if rule:IsFavouriteRule() and rule:GetNpcId() == self._NpcId then
                            local distance = math.abs(startX - x) + math.abs(startY - y)
                            if distance < favouriteDistance then
                                favouriteGrid = grid
                                favouriteRule = rule
                            end
                        end
                    else
                        XLog.Error("[XTemple2Game] 不存在的规则:", ruleIdArray[i])
                    end
                end
            end
        end
    end
    return favouriteGrid, favouriteRule
end

function XTemple2Game:GetPath()
    local map = self:GetMap()
    local startPos, endPos = self:GetEntrance()
    local path

    local favouriteGrid = self:GetFavouriteGrid()
    ---@class XTemple2GamePathParams
    local pathParams
    if favouriteGrid then
        local pos = favouriteGrid:GetPosition()
        local path1 = self._AStar:GetPath(map, startPos, pos)
        if path1 then
            -- 不能踩在喜好物品上
            local relayPos = path1[#path1 - 1]
            local path2 = self._AStar:GetPath(map, relayPos, endPos)
            if path2 then
                path = {}
                for i = 1, #path1 - 1 do
                    table.insert(path, path1[i])
                end
                pathParams = {}
                pathParams.FavouritePathIndex = #path
                for i = 2, #path2 do
                    table.insert(path, path2[i])
                end
            end
        end
    end
    if not path then
        path = self._AStar:GetPath(map, startPos, endPos)
    end

    return path, pathParams
end

function XTemple2Game:PrintPath()
    local map = self:GetMap()
    local startPos, endPos = self:GetEntrance()
    local path = self._AStar:GetPath(map, startPos, endPos)
    if not path then
        XLog.Error("[XTemple2Game] find path fail")
        return
    end
    local content = ""
    for i = 1, #path do
        local point = path[i]
        local x = point.x
        local y = point.y
        content = content .. string.format("(%d,%d)-", x, y)
    end
    XLog.Error(content)
    return path
end

---@param ui XUiTemple2CheckBoard
function XTemple2Game:Update(ui)
    if self._Animation:IsPlaying() then
        self._Animation:Update(ui, self)
    end
end

function XTemple2Game:IsCanStart()
    if self._Animation:IsPlaying() then
        return false
    end
    if self._Animation:IsFinish() then
        return false
    end
    if self:GetIsSettle() then
        return false
    end
    return true
end

function XTemple2Game:IsAnimationFinish()
    return self._Animation:IsFinish()
end

function XTemple2Game:IsAnimationPlaying()
    return self._Animation:IsPlaying()
end

function XTemple2Game:SetIsSettle()
    self._IsSettle = true
end

function XTemple2Game:GetIsSettle()
    return self._IsSettle
end

function XTemple2Game:StartWalk(path, animationDataList)
    if path then
        self._Animation:StartWalk(path, animationDataList)
    end
end

function XTemple2Game:ResetRuleScore()
    local map = self:GetMap()
    local maxY = map:GetRowAmount()
    local maxX = map:GetColumnAmount()
    for y = 1, maxY do
        for x = 1, maxX do
            local grid = map:GetGrid(x, y)
            -- 把规则得分重置
            grid:ResetScore()
        end
    end
end

function XTemple2Game:GetScore(type)
    return self._Score[type] or 0
end

function XTemple2Game:GetTotalScoreDict()
    return self._Score
end

---@param path XLuaVector2
---@param pathParams XTemple2GamePathParams
function XTemple2Game:UpdatePathAndScore()
    self:ResetRuleScore()
    self:UpdateEntranceAndExit()
    local path, pathParams = self:GetPath()

    -- !!!!! 注意，updateScore有先后顺序
    local scoreGrid = self:_UpdateScore(XTemple2Enum.SCORE_TYPE.GRID_SCORE, path, pathParams)
    self._Score[SCORE_TYPE.GRID_SCORE] = scoreGrid

    local scorePath = self:_UpdateScore(SCORE_TYPE.PATH_SCORE, path, pathParams)
    self._Score[SCORE_TYPE.PATH_SCORE] = scorePath

    local scoreLike = self:_UpdateScore(SCORE_TYPE.LIKE_SCORE, path, pathParams)
    self._Score[SCORE_TYPE.LIKE_SCORE] = scoreLike

    local scoreTask = self:_UpdateScore(SCORE_TYPE.TASK_SCORE, path, pathParams)
    self._Score[SCORE_TYPE.TASK_SCORE] = scoreTask

    local scoreBaseGrid = self:_UpdateScore(SCORE_TYPE.BASE_GIRD_SCORE, path, pathParams)
    self._Score[SCORE_TYPE.BASE_GIRD_SCORE] = scoreBaseGrid

    self._Score[SCORE_TYPE.TOTAL_SCORE] = scoreGrid + scorePath + scoreLike + scoreTask
    return path, pathParams
end

---@param path XLuaVector2
---@param pathParams XTemple2GamePathParams
function XTemple2Game:_UpdateScore(type, path, pathParams)
    if type == SCORE_TYPE.TOTAL_SCORE then
        XLog.Warning("[XTemple2Game] 如果已经单独获取过单项得分，就不该直接获取总分")
        local scoreGrid = self:_UpdateScore(XTemple2Enum.SCORE_TYPE.GRID_SCORE, path)
        local scorePath = self:_UpdateScore(XTemple2Enum.SCORE_TYPE.PATH_SCORE, path)
        local scoreLike = self:_UpdateScore(XTemple2Enum.SCORE_TYPE.LIKE_SCORE, path)
        local taskScore = self:_UpdateScore(XTemple2Enum.SCORE_TYPE.TASK_SCORE, path)
        return scoreGrid + scorePath + scoreLike + taskScore
    end
    -- !!!!! 注意，updateScore有先后顺序
    if type == SCORE_TYPE.GRID_SCORE then
        local map = self:GetMap()
        local maxY = map:GetRowAmount()
        local maxX = map:GetColumnAmount()

        -- 收集经过的所有格子
        local dictPath = {}
        if path then
            for i = 1, #path do
                local point = path[i]
                local x = point.x
                local y = point.y
                dictPath[y] = dictPath[y] or {}
                dictPath[y - 1] = dictPath[y - 1] or {}
                dictPath[y + 1] = dictPath[y + 1] or {}
                dictPath[y + 1][x] = true
                dictPath[y - 1][x] = true
                dictPath[y][x - 1] = true
                dictPath[y][x + 1] = true
            end
        end

        for ruleId, ruleData in pairs(self._AllRules) do
            if not XTool.IsTableEmpty(ruleData.Grids) then
                ruleData.Grids = {}
            end
        end

        local allRule = self._AllRules
        for y = 1, maxY do
            for x = 1, maxX do
                local grid = map:GetGrid(x, y)
                if grid:IsValid() then
                    local gridId = grid:GetId()
                    local rules = self._Grid2Rule[gridId]
                    if rules then
                        for i = 1, #rules do
                            local ruleId = rules[i]
                            local ruleData = allRule[ruleId]
                            ruleData.Grids[#ruleData.Grids + 1] = grid
                        end
                    elseif XMain.IsEditorDebug then
                        local ruleIdArray = grid:GetRule()
                        if #ruleIdArray > 0 then
                            XLog.Error(string.format("[XTemple2Game] 格子%s对应的规则不存在:", gridId))
                        end
                    end
                end
            end
        end

        ---@type XTemple2GameRule
        local ruleArray = {}
        for ruleId, ruleData in pairs(allRule) do
            if #ruleData.Grids > 0 or ruleData.Rule:IsGlobal() then
                local priorityA = ruleData.Rule:GetExecutePriority()
                local index = #ruleArray + 1
                for i = 1, #ruleArray do
                    local priorityB = ruleArray[i].Rule:GetExecutePriority()
                    if priorityA < priorityB then
                        index = i
                        break
                    end
                end
                table.insert(ruleArray, index, ruleData)
            end
        end

        self._Score4Rule = {}
        local validGridList
        for i = 1, #ruleArray do
            local ruleData = ruleArray[i]
            local grids = ruleData.Grids
            if ruleData.Rule:IsGlobal() then
                if not validGridList then
                    validGridList = map:GetValidGridList()
                end
                grids = validGridList
            end
            local score = ruleData.Rule:Execute(self, grids, dictPath)

            -- 每一个规则执行完后, 收集该规则的分差
            self._Score4Rule[ruleData.Rule:GetId()] = score
        end

        local ruleScore = 0
        for y = 1, maxY do
            for x = 1, maxX do
                local grid = map:GetGrid(x, y)
                ruleScore = ruleScore + grid:GetRuleScore()
            end
        end
        return ruleScore
    end
    -- !!!!! 注意，updateScore有先后顺序
    if type == SCORE_TYPE.PATH_SCORE then
        local score = 0
        if path then
            local map = self:GetMap()
            for i = 1, #path do
                local pos = path[i]
                local x, y = pos.x, pos.y
                local grid = map:GetGrid(x, y)
                if grid then
                    local up = map:GetGrid(x, y + 1)
                    local down = map:GetGrid(x, y - 1)
                    local left = map:GetGrid(x - 1, y)
                    local right = map:GetGrid(x + 1, y)
                    local scoreToAdd = 0
                    if up and up:IsValid() then
                        scoreToAdd = scoreToAdd + up:GetRuleScore()
                    end
                    if down and down:IsValid() then
                        scoreToAdd = scoreToAdd + down:GetRuleScore()
                    end
                    if right and right:IsValid() then
                        scoreToAdd = scoreToAdd + right:GetRuleScore()
                    end
                    if left and left:IsValid() then
                        scoreToAdd = scoreToAdd + left:GetRuleScore()
                    end
                    score = score + scoreToAdd
                end
            end
        end
        return score
    end
    if type == SCORE_TYPE.LIKE_SCORE then
        local score = 0
        local favouriteGrid, rule = self:GetFavouriteGrid()
        if rule then
            local ruleScore = rule:GetParams1()
            if ruleScore then
                score = score + ruleScore
            end

            -- 翻倍 喜好前的路径得分
            if path then
                if pathParams then
                    local scoreDouble = 0
                    local map = self:GetMap()
                    for i = 1, #path do
                        local pos = path[i]
                        local x, y = pos.x, pos.y
                        local grid = map:GetGrid(x, y)
                        if grid then
                            local up = map:GetGrid(x, y + 1)
                            local down = map:GetGrid(x, y - 1)
                            local left = map:GetGrid(x - 1, y)
                            local right = map:GetGrid(x + 1, y)
                            local scoreToAdd = 0
                            if up and up:IsValid() then
                                scoreToAdd = scoreToAdd + up:GetRuleScore()
                            end
                            if down and down:IsValid() then
                                scoreToAdd = scoreToAdd + down:GetRuleScore()
                            end
                            if right and right:IsValid() then
                                scoreToAdd = scoreToAdd + right:GetRuleScore()
                            end
                            if left and left:IsValid() then
                                scoreToAdd = scoreToAdd + left:GetRuleScore()
                            end
                            if pathParams.FavouritePathIndex then
                                -- 经过喜好时，前面的得分翻倍
                                if i <= pathParams.FavouritePathIndex then
                                    scoreDouble = scoreDouble + scoreToAdd
                                end
                            end
                        end
                    end
                    if scoreDouble > 0 then
                        score = score + scoreDouble
                        XLog.Debug("[XTemple2Game] 喜好得分翻倍:" .. scoreDouble)
                    end
                end

            end

            self._Score4Rule[rule:GetId()] = score
        end
        return score
    end

    if type == SCORE_TYPE.TASK_SCORE then
        local score = self:GetTaskScore()
        return score
    end

    if type == SCORE_TYPE.BASE_GIRD_SCORE then
        local score = 0
        local map = self:GetMap()
        local column, row = map:GetSize()
        for y = 1, row do
            for x = 1, column do
                local grid = map:GetGrid(x, y)
                if grid then
                    score = score + grid:GetScore()
                end
            end
        end
        return score
    end

    XLog.Error("[XTemple2Game] 未定义的分数类型:", type)
    return 0
end

---@return XTemple2Rule
function XTemple2Game:GetRule(ruleId)
    if self._AllRules[ruleId] then
        return self._AllRules[ruleId].Rule
    end
end

function XTemple2Game:IsRuleExist(ruleId)
    local ruleData = self._AllRules[ruleId]
    if ruleData then
        if ruleData.Rule:IsGlobal() then
            return true
        else
            if #ruleData.Grids > 0 then
                return true
            end
        end
    end
    return false
end

function XTemple2Game:GetOperations()
    return self._Operations
end

---@return boolean, XTemple2Block, XTemple2GameOperation
function XTemple2Game:RemoveBlockByGridPosition(x, y)
    local operationToRemove
    local map = self:GetMap()
    local grid = map:GetGrid(x, y)
    ---@type XTemple2Block
    local block
    local uid = grid:GetOperationUid()
    local operations = self:GetOperations()
    for i = 1, #operations do
        local operation = operations[i]
        if operation.Round == uid then
            local blockId = operation.BlockId
            block = self:GetBlock(blockId)
            if block then
                block = block:Clone()
                block:SetPositionXY(operation.X, operation.Y)
                block:SetRotation(operation.Rotation)
                table.remove(operations, i)
                operationToRemove = operation
            end
            break
        end
    end
    if block then
        for deleteY = y - XTemple2Enum.BLOCK_SIZE.Y, y + XTemple2Enum.BLOCK_SIZE.Y do
            for deleteX = x - XTemple2Enum.BLOCK_SIZE.X, x + XTemple2Enum.BLOCK_SIZE.X do
                local deleteGrid = map:GetGrid(deleteX, deleteY)
                if deleteGrid and deleteGrid:GetOperationUid() == uid then
                    map:RemoveGrid(deleteX, deleteY)
                end
            end
        end
        return true, block, operationToRemove
    end
    return false
end

---@param operations XTemple2GameOperation[]
function XTemple2Game:SetOperations(operations)
    for i = 1, #operations do
        local operation = operations[i]
        local blockId = operation.BlockId
        local block = self:GetBlock(blockId)
        block:SetPositionXY(operation.X, operation.Y)
        block:SetRotation(operation.Rotation)
        self:InsertBlock(block, operation.Round)
        self:IncreaseCurrentEffectiveTimes(blockId)
        block:SetRotation(0)
    end
    local lastOperation = operations[#operations]
    if lastOperation then
        self._OperationUid = lastOperation.Round + 1
    end
    self._Operations = operations
end

function XTemple2Game:GetTaskScore()
    local score = 0
    local map = self:GetMap()
    local column, row = map:GetSize()
    for y = 1, row do
        for x = 1, column do
            local grid = map:GetGrid(x, y)
            if grid then
                score = score + grid:GetTaskScore()
            end
        end
    end
    return score
end

function XTemple2Game:SetRandomPoolAmount(value)
    self._RandomPoolAmount = value
end

function XTemple2Game:GetRandomPoolAmount()
    return self._RandomPoolAmount
end

function XTemple2Game:SetTriggeredPlot(value)
    for i = 1, #self._PlotIds do
        if self._PlotIds[i] == value then
            XLog.Error("[XTemple2Game] 重复记录剧情id:", value)
            return
        end
    end
    self._PlotIds[#self._PlotIds + 1] = value
end

function XTemple2Game:GetTriggeredPlot()
    return self._PlotIds
end

---@param block XTemple2Block
function XTemple2Game:ClampBlockPosition(block, x, y)
    local anchorPosition = block:GetAnchorPosition()
    local anchorX = anchorPosition.x
    local anchorY = anchorPosition.y
    local map = self:GetMap()

    local up, down, left, right = block:GetValidSize()
    local toUp = map:GetRowAmount() - up + anchorY
    local toDown = anchorY - down + 1
    local toLeft = anchorX - left + 1
    local toRight = map:GetColumnAmount() - right + anchorX

    x = XMath.Clamp(x, toLeft, toRight)
    y = XMath.Clamp(y, toDown, toUp)
    return x, y
end

function XTemple2Game:FindBlock(name)
    for i = 1, #self._BlockPool do
        local block = self._BlockPool[i]
        if block:GetName() == name then
            return true
        end
    end
    local randomPool = self:GetBlockRandomPoolResult()
    for i = 1, #randomPool do
        local block = randomPool[i]
        if block:GetName() == name then
            return true
        end
    end
    return false
end

function XTemple2Game:GetState()
    return self._State
end

---@param game XTemple2Game
function XTemple2Game:CloneMap(game)
    self._Map:Clone(game:GetMap())
    --self._Map:PrintMap()
end

function XTemple2Game:Clone()
    ---@type XTemple2Game
    local game = XTemple2Game.New()
    game._State = self._State
    game._AllBlock = self._AllBlock
    --game._BlockPool = self._BlockPool
    --game._BlockRandomPool = self._BlockRandomPool
    --game._BlockRandomPoolResult = self._BlockRandomPoolResult
    --game._AStar = self._AStar
    game._NpcId = self._NpcId
    game._AllRules = self._AllRules
    game._Grid2Rule = self._Grid2Rule
    --game._OperationUid = self._OperationUid
    --game._Operations = self._Operations
    --game._IsSettle = self._IsSettle
    --game._RandomPoolAmount = self._RandomPoolAmount
    game._Seed = self._Seed
    --game._PlotIds = self._PlotIds
    --game._Score = self._Score
    return game
end

function XTemple2Game:GetScore4Rule()
    return self._Score4Rule
end

--local function SortExit(a, b)
--    if a.Distance ~= b.Distance then
--        return a.Distance < b.Distance
--    end
--    -- 隐藏规则，多个出口的情况下，以id大的为出口
--    return a:GetId() > b:GetId()
--end

function XTemple2Game:UpdateEntranceAndExit()
    local map = self:GetMap()
    local maxY = map:GetRowAmount()
    local maxX = map:GetColumnAmount()
    local startPos, endPos
    -- 隐藏规则，多个出口的情况下，以id大的为出口
    local startId, endId = 0, 0
    for y = 1, maxY do
        for x = 1, maxX do
            local grid = map:GetGrid(x, y)
            if grid:IsStartPoint() then
                if grid:GetId() > startId then
                    startPos = grid:GetPosition()
                    startId = grid:GetId()
                end
            elseif grid:IsEndPoint() then
                if grid:GetId() > endId then
                    endPos = grid:GetPosition()
                    endId = grid:GetId()
                end
            end
        end
    end
    self._StartPos:UpdateByVector(startPos)
    self._EndPos:UpdateByVector(endPos)

    -- 下面是以路径短为优先
    --local map = self:GetMap()
    --local maxY = map:GetRowAmount()
    --local maxX = map:GetColumnAmount()
    --local startPos, endPos
    --
    --for y = 1, maxY do
    --    for x = 1, maxX do
    --        local grid = map:GetGrid(x, y)
    --        if grid:IsStartPoint() then
    --            startPos = grid:GetPosition()
    --        end
    --    end
    --end
    --
    -----@type XTemple2Grid[]
    --local exitList = {}
    --
    --for y = 1, maxY do
    --    for x = 1, maxX do
    --        local grid = map:GetGrid(x, y)
    --        if grid:IsEndPoint() then
    --            exitList[#exitList + 1] = grid
    --        end
    --    end
    --end
    --
    ---- 多个终点
    --if #exitList == 1 then
    --    endPos = exitList[1]:GetPosition()
    --elseif #exitList > 1 then
    --    local exitDataList = {}
    --    for i = 1, #exitList do
    --        local grid = exitList[i]
    --        local path = self._AStar:GetPath(map, startPos, grid:GetPosition())
    --        exitDataList[i] = {
    --            Grid = grid,
    --            Distance = #path,
    --        }
    --    end
    --    table.sort(exitDataList, SortExit)
    --    if exitDataList then
    --        endPos = exitDataList[1].Grid:GetPosition()
    --    end
    --end
    --
    --self._StartPos:UpdateByVector(startPos)
    --if endPos then
    --    self._EndPos:UpdateByVector(endPos)
    --else
    --    self._EndPos:Update(0, 0)
    --end
end

function XTemple2Game:GetOneFavouriteBlock()
    local pool = self:GetBlockPool()
    for i = 1, #pool do
        local block = pool[i]
        if block:IsFavouriteBlock() then
            return block
        end
    end

    local randomPool = self:GetBlockRandomPoolResult()
    for i = 1, #randomPool do
        local block = randomPool[i]
        if block:IsFavouriteBlock() then
            return block
        end
    end
end

function XTemple2Game:GetGrid2Rule()
    return self._Grid2Rule
end

return XTemple2Game