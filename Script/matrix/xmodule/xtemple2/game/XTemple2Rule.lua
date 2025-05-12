local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")
local RULE = XTemple2Enum.RULE

---@class XTemple2Rule
local XTemple2Rule = XClass(nil, "XTemple2Rule")

function XTemple2Rule:Ctor()
    self._Id = 0
    self._Name = false
    self._RuleType = 0
    self._RuleDesc = false
    self._Params = false
    self._NpcId = false
    self._Bubble = false
    self._EffectiveTimes = 0
    self._TempEffectiveTimes = 0
    self._IsGlobal = false
    self._IconRule = false
    self._IconGrid = false
end

---@param config XTable.XTableTemple2Rule
function XTemple2Rule:Init(config)
    self._Id = config.Id
    self._Name = config.Name
    self._RuleType = config.RuleType
    self._RuleDesc = config.RuleDesc
    self._Params = config.Params
    self._Bubble = config.Bubble
    self._NpcId = config.NpcId
    self._EffectiveTimes = config.EffectiveTimes
    self._CurrentEffectiveTimes = 0
    self._IconRule = config.IconRule
    self._IconGrid = config.IconGrid
end

function XTemple2Rule:GetName()
    return self._Name
end

function XTemple2Rule:GetEffectiveTimes()
    return self._EffectiveTimes
end

function XTemple2Rule:ResetTempEffectiveTimes()
    self._TempEffectiveTimes = 0
end

function XTemple2Rule:IncreaseTempEffectiveTimes()
    if self._TempEffectiveTimes == 0 then
        return true
    end
    if self._TempEffectiveTimes >= self._EffectiveTimes then
        return false
    end
    self._TempEffectiveTimes = self._TempEffectiveTimes + 1
    return true
end

---@param game XTemple2Game
function XTemple2Rule:ExecuteAfterSetCharacter(game)
    if self._RuleType == RULE.LIKE then
        game:SetFavouriteRule(self)
        return
    end
end

function XTemple2Rule:GetBubble()
    return self._Bubble
end

function XTemple2Rule:IsFavouriteRule()
    return self._RuleType == RULE.LIKE
end

local _RuleDictionary

---@param game XTemple2Game
function XTemple2Rule:Execute(game, grids, dictPath)
    local func = _RuleDictionary[self._RuleType]
    if func then
        local score = func(self, game, grids, dictPath)
        return score
    end
    _RuleDictionary[self._RuleType] = function()
        -- do nothing 报错只提示一次
    end
    XLog.Error("[XTemple2Rule] 规则没有对应实现:", self._RuleType)
end

function XTemple2Rule:GetParams1()
    return self._Params[1]
end

function XTemple2Rule:GetParams2()
    return self._Params[2]
end

function XTemple2Rule:GetParams3()
    return self._Params[3]
end

function XTemple2Rule:GetRuleType()
    return self._RuleType
end

function XTemple2Rule:GetId()
    return self._Id
end

function XTemple2Rule:GetExecutePriority()
    if self._RuleType == RULE.NEIGHBOUR_SOME_THING_WITH_SCORE or self._RuleType == RULE.NEIGHBOUR_NOTHING then
        return 3
    end
    if self._RuleType == RULE.NEIGHBOUR_DIFF_COLOR_GRID_MUL or self._RuleType == RULE.NEIGHBOUR_SAME_COLOR_GRID_MUL then
        return 2
    end
    return 1
end

function XTemple2Rule:GetNpcId()
    return self._NpcId
end

function XTemple2Rule:IsGlobal()
    return self._IsGlobal
end

function XTemple2Rule:SetIsGlobal(value)
    self._IsGlobal = value
end

function XTemple2Rule:GetIconRule()
    return self._IconRule
end

function XTemple2Rule:GetIconGrid()
    return self._IconGrid
end

---@param nextGrid XTemple2Grid
---@param queue XQueue
---@param grid XTemple2Grid
---@param countData XTemple2Rule1CountData
local function NextDifferentColor(nextGrid, queue, grid, countData)
    if nextGrid and nextGrid:IsValid() and nextGrid:IsValidColor() then
        local color = nextGrid:GetColor()
        if color > 0 then
            if nextGrid:IsSameColor(grid) then
                queue:Enqueue(nextGrid)
            elseif grid:IsValidColor() then
                countData.Count = countData.Count + 1
            end
        end
    end
end

_RuleDictionary = {
    ---@param rule XTemple2Rule
    ---@param game XTemple2Game
    ---@param grids XTemple2Grid[]
    [RULE.NEIGHBOUR_DIFF_COLOR_GRID_ADD] = function(rule, game, grids, dictPath)
        local map = game:GetMap()

        ---@type XTemple2Rule1CountData[][]
        local amountMap = {}

        ---@type XQueue
        local queue = XQueue.New()
        for i = 1, #grids do
            local rootGrid = grids[i]
            ---@class XTemple2Rule1CountData
            local countData = { Count = 0 }
            queue:Enqueue(rootGrid)
            while (queue:Count() > 0) do
                local grid = queue:Dequeue()
                local pos = grid:GetPosition()
                local x, y = pos.x, pos.y
                if amountMap[y] == nil or amountMap[y][x] == nil then
                    local up = map:GetGrid(x, y + 1)
                    local down = map:GetGrid(x, y - 1)
                    local left = map:GetGrid(x - 1, y)
                    local right = map:GetGrid(x + 1, y)

                    NextDifferentColor(up, queue, grid, countData)
                    NextDifferentColor(down, queue, grid, countData)
                    NextDifferentColor(left, queue, grid, countData)
                    NextDifferentColor(right, queue, grid, countData)

                    amountMap[y] = amountMap[y] or {}
                    amountMap[y][x] = amountMap[y][x] or countData
                end
            end
        end

        local score = rule:GetParams1()
        local totalScore = 0
        for y, line in pairs(amountMap) do
            for x, countData in pairs(line) do
                local grid = map:GetGrid(x, y)
                if grid then
                    if countData.Count > 0 then
                        local value = countData.Count * score
                        grid:AddRuleScore(value)
                        totalScore = totalScore + value
                    end
                else
                    XLog.Error("[XTemple2Rule] 规则计分有错误:" .. x .. y)
                end
            end
        end
        return totalScore
    end,

    ---@param rule XTemple2Rule
    ---@param game XTemple2Game
    ---@param grids XTemple2Grid[]
    [RULE.NEIGHBOUR_SAME_COLOR_GRID_ADD] = function(rule, game, grids, dictPath)
        local map = game:GetMap()

        ---@type {Count:number,Score:number}[][]
        local amountMap = {}

        ---@type XQueue
        local queue = XQueue.New()
        for i = 1, #grids do
            local rootGrid = grids[i]
            if rootGrid:IsValidColor() then
                local countData = { Count = 0 }
                queue:Enqueue(rootGrid)
                while (queue:Count() > 0) do
                    local grid = queue:Dequeue()
                    local pos = grid:GetPosition()
                    local x, y = pos.x, pos.y
                    if amountMap[y] == nil or amountMap[y][x] == nil then
                        local up = map:GetGrid(x, y + 1)
                        local down = map:GetGrid(x, y - 1)
                        local left = map:GetGrid(x - 1, y)
                        local right = map:GetGrid(x + 1, y)

                        if up and up:IsValid() and up:IsSameColor(grid) then
                            queue:Enqueue(up)
                        end

                        if down and down:IsValid() and down:IsSameColor(grid) then
                            queue:Enqueue(down)
                        end

                        if left and left:IsValid() and left:IsSameColor(grid) then
                            queue:Enqueue(left)
                        end

                        if right and right:IsValid() and right:IsSameColor(grid) then
                            queue:Enqueue(right)
                        end

                        amountMap[y] = amountMap[y] or {}
                        amountMap[y][x] = amountMap[y][x] or countData
                        countData.Count = countData.Count + 1
                    end
                end
            end
        end

        local score = rule:GetParams1()
        local totalScore = 0
        for y, line in pairs(amountMap) do
            for x, countData in pairs(line) do
                local grid = map:GetGrid(x, y)
                if grid then
                    local value = countData.Count * score
                    grid:AddRuleScore(value)
                    totalScore = totalScore + value
                else
                    XLog.Error("[XTemple2Rule] 规则计分有错误:" .. x .. y)
                end
            end
        end
        return totalScore
    end,

    ---@param rule XTemple2Rule
    ---@param game XTemple2Game
    ---@param grids XTemple2Grid[]
    [RULE.NEIGHBOUR_NOTHING] = function(rule, game, grids, dictPath)
        local totalScore = 0

        local score = rule:GetParams1()
        local map = game:GetMap()
        for i = 1, #grids do
            local grid = grids[i]
            local pos = grid:GetPosition()
            local x, y = pos.x, pos.y
            if dictPath[y] and dictPath[y][x] then
                local up = map:GetGrid(x, y + 1)
                local down = map:GetGrid(x, y - 1)
                local left = map:GetGrid(x - 1, y)
                local right = map:GetGrid(x + 1, y)

                if ((not up) or (not up:IsValid()) or up:IsSameOperationUid(grid))
                        and ((not down) or (not down:IsValid()) or down:IsSameOperationUid(grid))
                        and ((not left) or (not left:IsValid()) or left:IsSameOperationUid(grid))
                        and ((not right) or (not right:IsValid()) or right:IsSameOperationUid(grid)) then
                    grid:AddTaskScore(score)
                    totalScore = totalScore + score
                end
            end
        end

        return totalScore
    end,

    ---@param rule XTemple2Rule
    ---@param game XTemple2Game
    ---@param grids XTemple2Grid[]
    [RULE.NEIGHBOUR_SOME_THING_WITH_SCORE] = function(rule, game, grids, dictPath)
        local totalScore = 0
        local score = rule:GetParams1()

        local map = game:GetMap()
        for i = 1, #grids do
            local grid = grids[i]
            local pos = grid:GetPosition()
            local x, y = pos.x, pos.y
            if dictPath[y] and dictPath[y][x] then
                local up = map:GetGrid(x, y + 1)
                local down = map:GetGrid(x, y - 1)
                local left = map:GetGrid(x - 1, y)
                local right = map:GetGrid(x + 1, y)
                local needScore = rule:GetParams3()
                local needType = rule:GetParams2()
                if (up and up:GetType() == needType and up:GetRuleScore() >= needScore)
                        or (down and down:GetType() == needType and down:GetRuleScore() >= needScore)
                        or (left and left:GetType() == needType and left:GetRuleScore() >= needScore)
                        or (right and right:GetType() == needType and right:GetRuleScore() >= needScore)
                then
                    grid:AddTaskScore(score, rule)
                    totalScore = totalScore + score
                end
            end
        end

        return totalScore
    end,

    ---@param rule XTemple2Rule
    ---@param game XTemple2Game
    ---@param grids XTemple2Grid[]
    [RULE.NEIGHBOUR_DIFF_COLOR_GRID_MUL] = function(rule, game, grids, dictPath)
        local totalScore = 0

        local map = game:GetMap()
        for i = 1, #grids do
            local grid = grids[i]
            if grid:IsValidColor() then
                local pos = grid:GetPosition()
                local x, y = pos.x, pos.y
                local up = map:GetGrid(x, y + 1)
                local down = map:GetGrid(x, y - 1)
                local left = map:GetGrid(x - 1, y)
                local right = map:GetGrid(x + 1, y)
                if up and up:IsValid() and up:IsDiffColor(grid) then
                    local score = up:GetRuleScore()
                    up:SetRuleScore(score * 2)
                    totalScore = totalScore + score
                end
                if down and down:IsValid() and down:IsDiffColor(grid) then
                    local score = down:GetRuleScore()
                    down:SetRuleScore(score * 2)
                    totalScore = totalScore + score
                end
                if left and left:IsValid() and left:IsDiffColor(grid) then
                    local score = left:GetRuleScore()
                    left:SetRuleScore(score * 2)
                    totalScore = totalScore + score
                end
                if right and right:IsValid() and right:IsDiffColor(grid) then
                    local score = right:GetRuleScore()
                    right:SetRuleScore(score * 2)
                    totalScore = totalScore + score
                end
            end
        end

        return totalScore
    end,

    ---@param rule XTemple2Rule
    ---@param game XTemple2Game
    ---@param grids XTemple2Grid[]
    [RULE.NEIGHBOUR_SAME_COLOR_GRID_MUL] = function(rule, game, grids, dictPath)
        local totalScore = 0

        local map = game:GetMap()
        for i = 1, #grids do
            local grid = grids[i]
            if grid:IsValidColor() then
                local pos = grid:GetPosition()
                local x, y = pos.x, pos.y
                local up = map:GetGrid(x, y + 1)
                local down = map:GetGrid(x, y - 1)
                local left = map:GetGrid(x - 1, y)
                local right = map:GetGrid(x + 1, y)
                if up and up:IsValid() and up:IsSameColor(grid) then
                    local score = up:GetRuleScore()
                    up:SetRuleScore(score * 2)
                    totalScore = totalScore + score
                end
                if down and down:IsValid() and down:IsSameColor(grid) then
                    local score = down:GetRuleScore()
                    down:SetRuleScore(score * 2)
                    totalScore = totalScore + score
                end
                if left and left:IsValid() and left:IsSameColor(grid) then
                    local score = left:GetRuleScore()
                    left:SetRuleScore(score * 2)
                    totalScore = totalScore + score
                end
                if right and right:IsValid() and right:IsSameColor(grid) then
                    local score = right:GetRuleScore()
                    right:SetRuleScore(score * 2)
                    totalScore = totalScore + score
                end
            end
        end

        return totalScore
    end,

    [RULE.LIKE] = function()
        return 0
    end,
    [RULE.DISLIKE] = function()
        return 0
    end,
}

return XTemple2Rule