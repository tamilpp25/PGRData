local XTemple2Grid = require("XModule/XTemple2/Game/XTemple2Grid")
local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")

---@class XTemple2Block
local XTemple2Block = XClass(nil, "XTemple2Block")

function XTemple2Block:Ctor()
    ---@type XTemple2Grid[][]
    self._Grids = {}

    self._Id = 0

    ---@type XLuaVector2
    self._AnchorPosition = false

    ---@type XLuaVector2
    self._Position = false

    self._Rotation = 0

    self._Name = false

    self._TypeName = false

    --self._TempRotation = {}

    self._EffectiveTimes = 0
    self._CurrentEffectiveTimes = 0

    -- true代表非喜好地块；false代表未初始化；number代表喜好该地块的npc
    self._FavouriteNpcId = false

    self._Color = false

    self._NoRotate = 0
end

function XTemple2Block:SetId(id)
    self._Id = id
    if XMain.IsEditorDebug then
        if type(id) == "number" then
            if id > 32767 or id < 0 then
                XLog.Error("[XTemple2Block] id在服务端保存为short，已溢出:", id)
            end
        end
    end
end

function XTemple2Block:SetNoRotate(value)
    self._NoRotate = value
end

function XTemple2Block:GetId()
    return self._Id
end

function XTemple2Block:SetGrids(grids)
    self._Grids = grids
    self._AnchorPosition = false

    -- 旋转后可能出现空的格子, 必须填满
    self:FillUpEmptyGrids(self._Grids, self:GetColumnAmount(), self:GetRowAmount())

    -- 规则地块不自动删除空行
    --self:DeleteEmptyLine()
    self:MarkAnchorPosition()
end

function XTemple2Block:DeleteEmptyYBegin()
    local isEmpty = true
    local y = 1
    for x = 1, self:GetColumnAmount() do
        local grid = self:GetGrid(x, y)
        if grid and not grid:IsEmpty() then
            isEmpty = false
            break
        end
    end
    if isEmpty then
        for x = 1, self:GetColumnAmount() do
            if #self._Grids[x] >= y then
                table.remove(self._Grids[x], y)
            end
        end
        return true
    end
    return false
end

function XTemple2Block:DeleteEmptyXBegin()
    local isEmpty = true
    local x = 1
    for y = 1, self:GetRowAmount() do
        local grid = self:GetGrid(x, y)
        if grid and not grid:IsEmpty() then
            isEmpty = false
            break
        end
    end
    if isEmpty then
        if #self._Grids >= x then
            table.remove(self._Grids, x)
        else
            return false
        end
        return true
    end
    return false
end

function XTemple2Block:DeleteEmptyYEnd()
    local isEmpty = true
    local y = self:GetRowAmount()
    for x = 1, self:GetColumnAmount() do
        local grid = self:GetGrid(x, y)
        if grid and not grid:IsEmpty() then
            isEmpty = false
            break
        end
    end
    if isEmpty then
        for x = 1, self:GetColumnAmount() do
            if #self._Grids[x] >= y then
                table.remove(self._Grids[x], y)
            end
        end
        return true
    end
    return false
end

function XTemple2Block:DeleteEmptyXEnd()
    local isEmpty = true
    local x = self:GetColumnAmount()
    for y = 1, self:GetRowAmount() do
        local grid = self:GetGrid(x, y)
        if grid and not grid:IsEmpty() then
            isEmpty = false
            break
        end
    end
    if isEmpty then
        if #self._Grids >= x then
            table.remove(self._Grids, x)
        else
            return false
        end
        return true
    end
    return false
end

function XTemple2Block:DeleteEmptyLine()
    for i = 1, self:GetRowAmount() do
        if not self:DeleteEmptyYBegin() then
            break
        end
    end
    for i = 1, self:GetRowAmount() do
        if not self:DeleteEmptyYEnd() then
            break
        end
    end
    for i = 1, self:GetColumnAmount() do
        if not self:DeleteEmptyXBegin() then
            break
        end
    end
    for i = 1, self:GetColumnAmount() do
        if not self:DeleteEmptyXEnd() then
            break
        end
    end
end

---@param map XTemple2Map
function XTemple2Block:SetGridsFromMap(map)
    local grids = {}
    for y = 1, map:GetRowAmount() do
        for x = 1, map:GetColumnAmount() do
            local grid = map:GetGrid(x, y)
            grids[x] = grids[x] or {}
            grids[x][y] = grid:Clone()
        end
    end
    self:SetGrids(grids)
end

function XTemple2Block:FillUpEmptyGrids(grids, x, y)
    for j = 1, y do
        for i = 1, x do
            local grid = grids[i][j]
            if not grid then
                grids[i][j] = XTemple2Grid.New()
                grid:SetPosition(i, j)
            end
        end
    end
end

local function GetClampAngle(angle)
    if angle < 0 then
        angle = angle + 360
    end
    return angle % 360
end

function XTemple2Block:Rotate90()
    if self._NoRotate == 1 then
        return
    end
    self._Rotation = GetClampAngle(self._Rotation + 90)
    self:UpdateAnchorPoint()
    self._Grids = self:_GetRotation90(self._Grids)
end

function XTemple2Block:UpdateAnchorPoint()
    local anchorPoint = self:GetAnchorPosition()
    local xAmount = self:GetColumnAmount()
    local anchorX = anchorPoint.x
    local anchorY = anchorPoint.y
    local x, y = self:_GetRotation90Position(anchorX, anchorY, xAmount)
    anchorPoint.x = x
    anchorPoint.y = y
    --XLog.Error(string.format("(%s,%s) -> (%s,%s)", anchorX, anchorY, x, y))
end

function XTemple2Block:_GetRotation90Position(i, j, xAmount)
    local x = j
    local y = i
    y = xAmount - y + 1
    return x, y
end

---@param grids XTemple2Grid[][]
function XTemple2Block:_GetRotation90(grids)
    local rotation = {}
    local yAmount = self:GetRowAmount()
    local xAmount = self:GetColumnAmount()
    local maxX = 0
    local maxY = 0
    for j = 1, yAmount do
        for i = 1, xAmount do
            local grid = grids[i][j]
            local x, y = self:_GetRotation90Position(i, j, xAmount)
            rotation[x] = rotation[x] or {}
            rotation[x][y] = grid
            grid:SetRotation(self._Rotation)
            if x > maxX then
                maxX = x
            end
            if y > maxY then
                maxY = y
            end
        end
    end
    -- 旋转后x和y对调
    self:FillUpEmptyGrids(rotation, maxX, maxY)
    return rotation
end

---@param map XTempleMap
function XTemple2Block:FindShapeInMap(map, rule)
    local isFind = false
    local executedGrids = nil

    local blockX = self:GetColumnAmount()
    local blockY = self:GetRowAmount()

    for j = 1, map:GetRowAmount() do
        for i = 1, map:GetColumnAmount() do
            if self:CheckShape(map, i, j, i + blockX - 1, j + blockY - 1) then
                executedGrids = self:CollectShapeGrids(map, i, j, i + blockX - 1, j + blockY - 1)
                isFind = true
                break
            end
            --end
        end

        if isFind then
            break
        end
    end

    return isFind, executedGrids
end

---@param map XTempleMap
---@param rule XTempleRule
function XTemple2Block:CollectShapeGrids(map, beginX, beginY, endX, endY)
    local result = {}
    for j = beginY, endY do
        for i = beginX, endX do
            local gridX = i - beginX + 1
            local gridY = j - beginY + 1
            local gridOnBlock = self:GetGrid(gridX, gridY)
            if gridOnBlock and (not gridOnBlock:IsEmpty()) then
                local gridOnMap = map:GetGrid(i, j)
                if gridOnMap:IsSameShape(gridOnBlock) then
                    result[#result + 1] = gridOnMap
                end
            end
        end
    end
    return result
end

---@param map XTempleMap
---@param rule XTempleRule
function XTemple2Block:CheckShape(map, beginX, beginY, endX, endY)
    for j = beginY, endY do
        for i = beginX, endX do
            local gridX = i - beginX + 1
            local gridY = j - beginY + 1
            local gridOnBlock = self:GetGrid(gridX, gridY)
            if gridOnBlock and (not gridOnBlock:IsEmpty()) then
                local gridOnMap = map:GetGrid(i, j)
                if not gridOnMap then
                    return false
                end
                if not gridOnMap:IsSameShape(gridOnBlock) then
                    return false
                end
                if not gridOnMap:IsSameRotation(gridOnBlock) then
                    return false
                end
            end
        end
    end
    return true
end

---@return XTemple2Grid
function XTemple2Block:GetGrid(x, y)
    if not self._Grids[x] then
        return nil
    end
    return self._Grids[x][y]
end

---@return number y的最大值
function XTemple2Block:GetRowAmount()
    local max = 0
    for i = 1, #self._Grids do
        local value = #self._Grids[i]
        if value > max then
            max = value
        end
    end
    return max
end

---@return number x的最大值
function XTemple2Block:GetColumnAmount()
    return #self._Grids
end

function XTemple2Block:MarkAnchorPosition()
    self:GetAnchorPosition()
end

function XTemple2Block:GetAnchorPosition()
    if self._AnchorPosition == false then
        self._AnchorPosition = XLuaVector2.New()
        self._AnchorPosition.x = XMath.ToInt(self:GetColumnAmount() / 2)
        self._AnchorPosition.y = XMath.ToInt(self:GetRowAmount() / 2)
    end
    return self._AnchorPosition
end

function XTemple2Block:SetPositionXY(x, y)
    if not self._Position then
        self._Position = XLuaVector2.New(x, y)
        return true
    end
    if self._Position.x ~= x
            or self._Position.y ~= y then
        self._Position.x = x
        self._Position.y = y
        return true
    end
    return false
end

function XTemple2Block:SetPosition(position)
    if not self._Position then
        self._Position = XLuaVector2.New()
    end
    self._Position:UpdateByVector(position)
end

function XTemple2Block:GetPosition()
    return self._Position
end

function XTemple2Block:Clone()
    ---@type XTemple2Block
    local block = XTemple2Block.New()

    local grids = {}
    for j = 1, self:GetRowAmount() do
        for i = 1, self:GetColumnAmount() do
            grids[i] = grids[i] or {}
            local grid = self:GetGrid(i, j)
            if grid then
                grids[i][j] = grid:Clone()
            end
        end
    end
    block._Grids = grids
    block._AnchorPosition = block:GetAnchorPosition():Clone()

    block._Id = self._Id
    if self._Position then
        block._Position = self._Position:Clone()
    end
    block._Rotation = self:GetRotation()
    block._NoRotate = self:GetNoRotate()
    return block
end

function XTemple2Block:GetRotation()
    return self._Rotation
end

function XTemple2Block:SetRotation(rotation)
    if self._NoRotate == 1 then
        return
    end
    if self:GetRotation() == rotation then
        return
    end
    -- 最多转4次
    for i = 1, 4 do
        if self:GetRotation() == rotation then
            return
        end
        self:Rotate90()
    end
    --local offset = self._Rotation - rotation
    --offset = GetClampAngle(offset)
    --local rotateAmount = math.floor(offset / 90)
    --for i = 1, rotateAmount do
    --    self:Rotate90()
    --end
    --self._Rotation = rotation
end

function XTemple2Block:SetName(name)
    self._Name = name
end

function XTemple2Block:SetTypeName(typeName)
    self._TypeName = typeName
end

function XTemple2Block:GetName()
    return self._Name or ""
end

function XTemple2Block:GetGrids()
    return self._Grids
end

---@param block XTemple2Block
function XTemple2Block:Equals(block)
    if not block then
        return false
    end
    if self:GetId() == block:GetId() then
        return true
    end
    return false
end

function XTemple2Block:GetTypeName()
    return self._TypeName or ""
end

function XTemple2Block:GetEffectiveTimes()
    return self._EffectiveTimes
end

function XTemple2Block:SetEffectiveTimes(value)
    self._EffectiveTimes = value or 0
end

function XTemple2Block:IncreaseCurrentEffectiveTimes()
    self._CurrentEffectiveTimes = self._CurrentEffectiveTimes + 1
    self._CurrentEffectiveTimes = math.min(self._CurrentEffectiveTimes, self._EffectiveTimes)
end

function XTemple2Block:DecreaseCurrentEffectiveTimes()
    self._CurrentEffectiveTimes = self._CurrentEffectiveTimes - 1
    self._CurrentEffectiveTimes = math.max(self._CurrentEffectiveTimes, 0)
end

function XTemple2Block:IsHasEffectiveTimes()
    if self._EffectiveTimes <= 0 then
        return true
    end
    return self._CurrentEffectiveTimes < self._EffectiveTimes
end

function XTemple2Block:GetRemainEffectiveTimes()
    return math.max(self._EffectiveTimes - self._CurrentEffectiveTimes, 0)
end

---@return number, number@有效面积
function XTemple2Block:GetValidSize()
    local column = self:GetColumnAmount()
    local row = self:GetRowAmount()
    local maxX, maxY = 0, 0
    local minX, minY = column, row
    for x = 1, column do
        for y = 1, row do
            local grid = self:GetGrid(x, y)
            if grid and not grid:IsEmpty() then
                if x > maxX then
                    maxX = x
                end
                if y > maxY then
                    maxY = y
                end
                if x < minX then
                    minX = x
                end
                if y < minY then
                    minY = y
                end
            end
        end
    end
    return maxY, minY, minX, maxX
end

function XTemple2Block:GetNpcId()
    return self._FavouriteNpcId
end

function XTemple2Block:IsFavouriteBlock()
    return self._FavouriteNpcId and true or false
end

---@param model XTemple2Model
function XTemple2Block:InitFavouriteNpcId(model)
    local row = self:GetRowAmount()
    local column = self:GetColumnAmount()
    for y = 1, column do
        for x = 1, row do
            local grid = self:GetGrid(x, y)
            local rules = grid:GetRule()
            if rules then
                for i = 1, #rules do
                    local ruleId = rules[i]
                    ---@type XTable.XTableTemple2Rule
                    local ruleConfig = model:GetRule(ruleId)
                    if not ruleConfig then
                        self._FavouriteNpcId = false
                        XLog.Error("[XTemple2Block] 规则不存在:", ruleId)
                        return false
                    end
                    if ruleConfig.RuleType == XTemple2Enum.RULE.LIKE then
                        local npcId = ruleConfig.NpcId
                        self._FavouriteNpcId = npcId
                    end
                end
            end
        end
    end
end

---@param game XTemple2Game
function XTemple2Block:CheckIsSelected4FavouriteRule(game)
    if self._FavouriteNpcId == false then
        return true
    end
    local npcId = game:GetNpcId()
    return self._FavouriteNpcId == npcId
end

function XTemple2Block:GetColor()
    if self._Color == false then
        local row = self:GetRowAmount()
        local column = self:GetColumnAmount()
        for y = 1, row do
            for x = 1, column do
                local grid = self:GetGrid(x, y)
                if grid:IsValidColor() then
                    self._Color = grid:GetColor()
                    return self._Color
                end
            end
        end
        self._Color = 0
    end
    return self._Color
end

function XTemple2Block:GetNoRotate()
    return self._NoRotate
end

return XTemple2Block
