local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")
local RULE = XTempleEnumConst.RULE
local GRID = XTempleEnumConst.GRID
local TIME_OF_DAY = XTempleEnumConst.TIME_OF_DAY
local RuleDict = require("XEntity/XTemple/Rule/XTempleRuleDictionary")
local LEFT_SHIFT_POSITION_X = 10

---@field _OwnControl XTempleGameControl
---@class XTempleRule:XEntity
local XTempleRule = XClass(XEntity, "XTempleRule")

function XTempleRule:Ctor()
    self._Type = 0
    self._Params = nil
    self._Id = 0
    self._RewardScore = 0
    self._ActiveTime = 0
    self._Name = nil

    self._IsActive = false

    self._IsHide = false

    self._IsMark = false

    self._TempExecuted = {}
    self._Executed = {}

    self._Score = 0

    --数量最多那条规则, 目标地块数量发生变化后才显示分数
    self._TypeAmountDict = nil
end

function XTempleRule:SetId(id)
    self._Id = id
end

function XTempleRule:SetType(type)
    self._Type = type
end

function XTempleRule:SetData(data)
    self._Type = data.Type
    self._Params = data.Params
    self._Id = data.Id
    self._RewardScore = data.Score
    self._ActiveTime = data.TimeOfDay
    self._Name = data.Name
    self:SetIsHide(data.IsHide == 1)
end

function XTempleRule:GetId()
    return self._Id
end

function XTempleRule:GetType()
    return self._Type
end

function XTempleRule:GetData4Edit()
    local params = {}
    for i = 1, #self._Params do
        params[i] = self._Params[i]
    end
    return {
        Type = self._Type,
        Params = params,
        Id = self._Id,
        Score = self._RewardScore,
        TimeOfDay = self._ActiveTime,
        Name = self._Name,
        IsHide = self._IsHide and 1 or 0,
    }
end

function XTempleRule:GetGridNameByType(type)
    if not type then
        return "nil"
    end
    return self._OwnControl:GetGridName(type)
    --return type
end

function XTempleRule:GetEditorAmountOptions()
    local array = {}
    local value = {}
    for i = 1, 10 do
        array[i] = i
        value[i - 1] = i
    end
    return array, value
end

function XTempleRule:GetEditGridOptions()
    local gridSorted = {}
    local allGrid = self._OwnControl:GetAllGrid()
    for _, config in pairs(allGrid) do
        gridSorted[#gridSorted + 1] = config.Id
    end
    table.sort(gridSorted, function(a, b)
        return a < b
    end)

    local array = {}
    local value = {}
    for i = 1, #gridSorted do
        local id = gridSorted[i]
        local index = #array + 1
        array[index] = self._OwnControl:GetGridName(id)
        value[index - 1] = id
    end
    return array, value
end

function XTempleRule:GetEditOptions()
    self:MakeParamsWritable()
    local t = RuleDict[self:GetType()]
    if t then
        return t.EditorGetOption(self, t)
    end
    return {}
end

function XTempleRule:GetRuleText()
    return self._OwnControl:GetRuleText(self._Type)
end

function XTempleRule:GetText()
    local t = RuleDict[self._Type]
    if not t then
        return ""
    end
    return t.GetText(self)
end

function XTempleRule:GetShapeBlockId()
    return self._Params[1]
end

function XTempleRule:SetShapeBlockId(blockId)
    self:MakeParamsWritable()
    self._Params[1] = blockId
end

function XTempleRule:MakeParamsWritable()
    if getmetatable(self._Params) then
        local params = {}
        for i = 1, #self._Params do
            params[i] = self._Params[i]
        end
        self._Params = params
    end
end

function XTempleRule:GetName()
    return self._Name
end

function XTempleRule:SetName(name)
    self._Name = name
end

function XTempleRule:GetParams()
    return self._Params
end

function XTempleRule:IsExpire(time)
    if not time then
        return true
    end
    if self:GetActiveTime() < time:GetBinCode() then
        return true
    end
    return false
end

---@param map XTempleMap
---@param time XTempleTimeOfDay
---@return boolean, number, XTempleGrid[]
function XTempleRule:Execute(map, time, isPreview)
    --if previewTime then
    --    -- 预览: 之后能得分也显示
    --    if not self:IsActive() and self:GetActiveTime() < previewTime:GetBinCode() then
    --        return 0
    --    end
    --else
    --    if not self:IsActive() then
    --        return 0
    --    end
    --end
    if not time then
        return 0
    end
    --if isPreview then
    if self:IsExpire(time) then
        return self._HistoryScore
    end
    --end

    local t = RuleDict[self._Type]
    if not t then
        return 0
    end

    local func = t.Execute
    if not func then
        return 0
    end
    self._TempExecuted = {}
    local score = func(self, map)
    self._HistoryScore = score
    return score
end

function XTempleRule:GetRewardScore()
    return self._RewardScore
end

function XTempleRule:IsActive()
    return self._IsActive
end

function XTempleRule:SetIsActive(value)
    self._IsActive = value
end

---@param timeOfDay XTempleTimeOfDay
function XTempleRule:IsRuleActive(timeOfDay)
    if not timeOfDay then
        return false
    end
    if timeOfDay:IsTimeActive(self._ActiveTime) then
        return true
    end
    return false
end

---@param timeOfDay XTempleTimeOfDay
function XTempleRule:GetTextTimeOfDay(timeOfDay)
    local textTable = {}
    for i = TIME_OF_DAY.BEGIN + 1, TIME_OF_DAY.END - 1 do
        local time = 1 << (i - 1)
        if self._ActiveTime & time ~= 0 then
            local text = self._OwnControl:GetTimeOfDayName(i)
            local isActive = timeOfDay and timeOfDay:IsTimeActive(time)
            ---@class XTempleUiDataTime
            local t = {
                Text = text,
                --Icon = isActive and self._OwnControl:GetTimeOfDayIconOn(i) or self._OwnControl:GetTimeOfDayIconOff(i),
                IsActive = isActive,
            }
            textTable[#textTable + 1] = t
        end
    end
    return textTable
end

function XTempleRule:GetTime4Edit()
    local array = {}
    for i = TIME_OF_DAY.BEGIN + 1, TIME_OF_DAY.END - 1 do
        local time = 1 << (i - 1)
        if self._ActiveTime & time ~= 0 then
            array[#array + 1] = i
        end
    end
    return array
end

function XTempleRule:GetActiveTime()
    return self._ActiveTime
end

function XTempleRule:GetIsHide()
    return self._IsHide
end

function XTempleRule:SetIsHide(value)
    self._IsHide = value
end

---@param grids XTempleGrid[]
function XTempleRule:FindInGrids(grids, type)
    for i = 1, #grids do
        local grid = grids[i]
        if grid:IsType(type) then
            return true
        end
    end
    return false
end

---@param grids XTempleGrid[]
function XTempleRule:IsSurroundByEmpty(grids)
    if #grids == 0 then
        return false
    end
    for i = 1, #grids do
        local grid = grids[i]
        if not grid:IsEmpty() then
            return false
        end
    end
    return true
end

---@param grids XTempleGrid[]
function XTempleRule:IsSurroundBySomeGrids(grids)
    if #grids == 0 then
        return false
    end
    for i = 1, #grids do
        local grid = grids[i]
        if grid:IsEmpty() then
            return false
        end
    end
    return true
end

---@param grids XTempleGrid[]
function XTempleRule:IsSurroundByGrids1(grids, type1)
    if #grids == 0 then
        return false
    end
    for i = 1, #grids do
        local grid = grids[i]
        if grid:GetType() ~= type1 then
            return false
        end
    end
    return true
end

---@param grids XTempleGrid[]
function XTempleRule:IsSurroundByGrids2(grids, type1, type2)
    if #grids == 0 then
        return false
    end
    for i = 1, #grids do
        local grid = grids[i]
        local type = grid:GetType()
        if type ~= type1 and
                type ~= type2
        then
            return false
        end
    end
    return true
end

---@param grids XTempleGrid[]
function XTempleRule:IsSurroundByGrids3(grids, type1, type2, type3)
    if #grids == 0 then
        return false
    end
    for i = 1, #grids do
        local grid = grids[i]
        local type = grid:GetType()
        if type ~= type1 and
                type ~= type2 and
                type ~= type3
        then
            return false
        end
    end
    return true
end

---@param grid XTempleGrid
---@param map XTempleMap
function XTempleRule:IsGridOnMapEdge(grid, map)
    local position = grid:GetPosition()
    if position.x == 1 then
        return true
    end
    if position.y == 1 then
        return true
    end
    if position.x == map:GetColumnAmount() then
        return true
    end
    if position.y == map:GetRowAmount() then
        return true
    end
    return false
end

--- 满足正方形
---@param grid XTempleGrid
---@param map XTempleMap
function XTempleRule:IsGridsMatchSquare(grid, map, gridType, size)
    local position = grid:GetPosition()
    local x = position.x
    local y = position.y

    if not map:IsPositionMathGridType(x, y, gridType) then
        return
    end

    -- 右上
    if map:_IsGridsMatchSquare(x, y, map, gridType, size) then
        return true
    end

    -- 左上
    if map:_IsGridsMatchSquare(x - size + 1, y, map, gridType, size) then
        return true
    end

    -- 右下
    if map:_IsGridsMatchSquare(x, y - size + 1, map, gridType, size) then
        return true
    end

    -- 左下
    if map:_IsGridsMatchSquare(x - size + 1, y - size + 1, map, gridType, size) then
        return true
    end

    return false
end

---@param map XTempleMap
function XTempleRule:_IsGridsMatchSquare(x, y, map, gridType, size)
    local isMatch = true
    for j = 0, size - 1 do
        for i = 0, size - 1 do
            if not map:IsPositionMathGridType(x + i, y + j, gridType) then
                isMatch = false
                break
            end
        end
    end
    if isMatch then
        local grids = {}
        for j = 0, size - 1 do
            for i = 0, size - 1 do
                grids[#grids + 1] = map:GetGrid(x + i, y + j)
            end
        end
        return true, grids
    end
    return false
end

---@param grid XTempleGrid
---@param map XTempleMap
---@return boolean, XTempleGrid[]
function XTempleRule:IsGridCommunity(grid, map, amount)
    amount = amount or self._OwnControl:GetGridCommunityAmount()
    local linkGrids = map:FindLinkGrids(grid, grid:GetType())
    if #linkGrids >= amount then
        return true, linkGrids
    end
    return false
end

function XTempleRule:GetEditorOption4Grid(value)
    local optionArray, valueArray = self:GetEditGridOptions()
    return {
        DropDown = optionArray,
        Value = valueArray,
        Selected = self._OwnControl:GetDropdownValue(value, valueArray),
    }
end

function XTempleRule:GetEditorOptionArray4Grid(amount, ruleTable)
    local t = {}
    for i = 1, amount do
        t[i] = self:GetEditorOption4Grid(self._Params[i])
    end
    local lastOption = t[ruleTable.KeyParamsIndex or amount]
    if lastOption then
        lastOption.IsKeyParams = true
    end
    return t
end

---@param grid XTempleGrid
function XTempleRule:SetGridExecuted(grid)
    local position = grid:GetPosition()
    local id = (position.x << LEFT_SHIFT_POSITION_X) + position.y
    self._TempExecuted[id] = true
end

function XTempleRule:SetGridsExecuted(grids)
    for i = 1, #grids do
        self:SetGridExecuted(grids[i])
    end
end

---@param grid XTempleGrid
function XTempleRule:IsGridExecuted(grid)
    local position = grid:GetPosition()
    local id = (position.x << LEFT_SHIFT_POSITION_X) + position.y
    if self._Executed[id] then
        return true
    end
    return self._TempExecuted[id]
end

function XTempleRule:SetScore(score)
    self._Score = score
end

function XTempleRule:GetScore()
    return self._Score
end

function XTempleRule:IsGridsExecuted(grids)
    for i = 1, #grids do
        if self:IsGridExecuted(grids[i]) then
            return false
        end
    end
end

function XTempleRule:SetLineExecuted(isX, line)
    self._TempExecuted["Line" .. line .. isX] = true
end

function XTempleRule:IsLineExecuted(isX, line)
    if self._TempExecuted["Line" .. line .. isX] then
        return true
    end
    return self._TempExecuted["Line" .. line .. isX]
end

function XTempleRule:SetSelfExecuted()
    self._TempExecuted["Rule"] = true
end

function XTempleRule:IsSelfExecuted()
    if self._TempExecuted["Rule"] then
        return true
    end
    self._TempExecuted["Rule"] = true
end

function XTempleRule:GetEditorOptionLine(param)
    local optionArray = {
        XUiHelper.GetText("TempleRow"),
        XUiHelper.GetText("TempleColumn"),
    }
    return {
        DropDown = optionArray,
        Value = { [0] = 0, [1] = 1 },
        Selected = param or XTempleEnumConst.LINE.COLUMN,
    }
end

function XTempleRule:GetLineStr(param)
    if param == 0 then
        return XUiHelper.GetText("TempleRow")
    end
    return XUiHelper.GetText("TempleColumn")
end

function XTempleRule:GetParamsGridType(index)
    local id = self._Params[index]
    if id then
        local type = self._OwnControl:GetGridType(id)
        return type
    end
end

function XTempleRule:GetParamsGridId(index)
    return self._Params[index]
end

function XTempleRule:GetKeyParams()
    local ruleTable = RuleDict[self:GetType()]
    local index = ruleTable.KeyParamsIndex
    if not index then
        index = #self._Params
    end
    return self._Params[index]
end

function XTempleRule:SaveExecutedRecord()
    for gridId, v in pairs(self._TempExecuted) do
        self._Executed[gridId] = true
    end
end

return XTempleRule
