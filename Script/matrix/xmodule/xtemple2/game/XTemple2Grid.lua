local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")
local GRID_TYPE = XTemple2Enum.GRID
--不用二进制, 是为了保留配置表的可读性
local GRID_ROTATE_LEFT_SHIFT = 10000000

---@class XTemple2Grid
local XTemple2Grid = XClass(nil, "XTemple2Grid")

function XTemple2Grid:Ctor()
    ---@type XLuaVector2
    self._Position = XLuaVector2.New()
    self._Score = 0
    self._Color = XTemple2Enum.COLOR.RED
    self._Id = 0
    self._IsCanRotate = false
    self._IsRotateChangeAnchorPoint = false
    self._Rotation = 0
    self._Rule = false
    self._Icon = false
    self._Icon90 = false
    self._Icon180 = false
    self._Icon270 = false
    self._Prefab = false

    self._Type = 0

    self._OperationUid = 0

    self._RuleScore = 0

    -- 任务得分：满足条件，且在路过时生效
    self._TaskScore = 0
    ---@type XTemple2Rule[]
    self._TaskRule = {}
end

function XTemple2Grid:GetScore()
    return self._Score
end

function XTemple2Grid:GetId()
    return self._Id
end

function XTemple2Grid:GetEncodeInfo()
    local info = self:GetRotation() * GRID_ROTATE_LEFT_SHIFT + self:GetId()
    return math.floor(info)
end

--不用二进制, 是为了保留配置表的可读性
function XTemple2Grid:SetEncodeInfo(info)
    local id = info % GRID_ROTATE_LEFT_SHIFT
    self:SetId(id)

    local rotation = (info - id) / GRID_ROTATE_LEFT_SHIFT
    self:SetRotation(rotation)
end

function XTemple2Grid:SetRotation(value)
    self._Rotation = value
end

---@param config XTableTemple2Grid
function XTemple2Grid:SetConfig(config)
    self._Icon = config.Icon
    self._Prefab = config.Prefab

    local isCanRotate = config.RotateIcon == 1
    self._Icon90 = config.RotationIcon90
    if self._Icon90 and self._Icon90 ~= "" then
        isCanRotate = true
        self._IsRotateChangeAnchorPoint = true
    else
        self._Icon90 = false
    end
    self._Icon180 = config.RotationIcon180
    if self._Icon180 and self._Icon180 ~= "" then
        isCanRotate = true
        self._IsRotateChangeAnchorPoint = true
    else
        self._Icon180 = false
    end
    self._Icon270 = config.RotationIcon270
    if self._Icon270 and self._Icon270 ~= "" then
        isCanRotate = true
        self._IsRotateChangeAnchorPoint = true
    else
        self._Icon270 = false
    end

    self._Id = config.Id
    self._IsCanRotate = isCanRotate
    self._Rule = config.Rule
    self._Type = config.Type
    self._Color = config.Color
    self._Score = config.Score
end

function XTemple2Grid:IsRotateChangeAnchorPoint()
    return self._IsRotateChangeAnchorPoint
end

function XTemple2Grid:IsEmpty()
    return self._Id <= 0
end

function XTemple2Grid:IsObstacle()
    return self._Id == 1
end

function XTemple2Grid:SetPosition(x, y)
    self._Position.x = x
    self._Position.y = y
end

function XTemple2Grid:GetPosition()
    return self._Position
end

function XTemple2Grid:SetId(id)
    self._Id = id
end

function XTemple2Grid:GetIcon()
    local rotation = self:GetRotation()
    if rotation == 90 and self._Icon90 then
        return self._Icon90
    end
    if rotation == 180 and self._Icon180 then
        return self._Icon180
    end
    if rotation == 270 and self._Icon270 then
        return self._Icon270
    end
    return self._Icon
end

function XTemple2Grid:GetRotation()
    return self._Rotation
end

function XTemple2Grid:GetRule()
    return self._Rule
end

function XTemple2Grid:GetIsCanRotate()
    return self._IsCanRotate
end

function XTemple2Grid:GetColor()
    return self._Color
end

function XTemple2Grid:IsValidColor()
    return self._Color > 0
end

---@param grid XTemple2Grid
function XTemple2Grid:CloneFromGrid(grid)
    --if grid:GetId() == 1004 then
    --    print("复制:" .. self._Position.x .. "/" .. self._Position.y .. ":" .. grid:GetRotation())
    --end
    self._Rotation = grid:GetRotation()
    self._Id = grid:GetId()
    -- 坐标不复制
    --self._Position:UpdateByVector(grid:GetPosition())
    self._Score = grid:GetScore()
    self._Color = grid:GetColor()
    self._IsCanRotate = grid:GetIsCanRotate()
    self._Rule = grid:GetRule()
    self._Icon = grid._Icon
    self._Icon90 = grid._Icon90
    self._Icon180 = grid._Icon180
    self._Icon270 = grid._Icon270
    self._IsRotateChangeAnchorPoint = grid._IsRotateChangeAnchorPoint
    self._Type = grid:GetType()
    self._Prefab = grid:GetPrefab()
end

function XTemple2Grid:GetPrefab()
    return self._Prefab
end

function XTemple2Grid:GetType()
    return self._Type
end

function XTemple2Grid:SetEmpty()
    self._Rotation = 0
    self._Id = 0
    self._Score = 0
    self._Color = 0
    self._IsCanRotate = false
    self._Rule = false
    self._Icon = false
    self._Icon90 = false
    self._Icon180 = false
    self._Icon270 = false
    self._Prefab = false
    self._Type = 0
    self._RuleScore = 0
    self._TaskScore = 0
    self._IsRotateChangeAnchorPoint = false
    self._TaskRule = {}
end

function XTemple2Grid:Clone()
    local grid = XTemple2Grid.New()
    grid:CloneFromGrid(self)
    return grid
end

function XTemple2Grid:IsCanWalk()
    return self._Type == 0 or self._Type == GRID_TYPE.ENTRANCE or self._Type == GRID_TYPE.EXIT
end

function XTemple2Grid:IsStartPoint()
    return self._Type == GRID_TYPE.ENTRANCE
end

function XTemple2Grid:IsEndPoint()
    return self._Type == GRID_TYPE.EXIT
end

---@param grid XTemple2Grid
function XTemple2Grid:IsSameColor(grid)
    return self._Color == grid:GetColor()
end

function XTemple2Grid:IsDifferentColor(grid)
    return self._Color ~= grid:GetColor()
end

---@param grid XTemple2Grid
function XTemple2Grid:IsDiffColor(grid)
    return self._Color ~= grid:GetColor()
end

function XTemple2Grid:SetRuleScore(value)
    self._RuleScore = value
end

function XTemple2Grid:AddRuleScore(value)
    self._RuleScore = self._RuleScore + value
end

function XTemple2Grid:GetRuleScore()
    return self._RuleScore
end

function XTemple2Grid:AddTaskRule(rule)
    self._TaskRule[#self._TaskRule + 1] = rule
end

function XTemple2Grid:AddTaskScore(value)
    self._TaskScore = self._TaskScore + value
end

function XTemple2Grid:GetTaskScore()
    return self._TaskScore
end

function XTemple2Grid:IsHasTask()
    return self._TaskScore > 0
end

---@param grid XTemple2Grid
function XTemple2Grid:IsSameType(grid)
    return self:GetType() == grid:GetType()
end

function XTemple2Grid:IsValid()
    return self._Type > 0 and self._Type ~= GRID_TYPE.ENTRANCE and self._Type ~= GRID_TYPE.EXIT and self._Type ~= GRID_TYPE.OBSTACLE
end

function XTemple2Grid:SetOperationUid(uid)
    self._OperationUid = uid
end

function XTemple2Grid:GetOperationUid()
    return self._OperationUid
end

---@param grid XTemple2Grid
function XTemple2Grid:IsSameOperationUid(grid)
    return self._OperationUid == grid:GetOperationUid()
end

function XTemple2Grid:GetTaskRule()
    return self._TaskRule
end

function XTemple2Grid:ResetScore()
    self._RuleScore = self._Score
    self._TaskScore = 0
    for i, v in pairs(self._TaskRule) do
        self._TaskRule[i] = nil
    end
end

function XTemple2Grid:GetTotalScore()
    local taskScore = self:GetTaskScore()
    local ruleScore = self:GetRuleScore()
    return taskScore + ruleScore
end

function XTemple2Grid:GetTotalScoreExceptBaseScore()
    return self:GetTotalScore() - self:GetScore()
end

return XTemple2Grid