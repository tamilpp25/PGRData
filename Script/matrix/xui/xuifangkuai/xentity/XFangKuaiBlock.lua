---@class XFangKuaiBlock 方块基础数据
---@field _Control XFangKuaiControl
---@field _Id number 唯一Id
---@field _ItemId number 方块中包含的道具Id
---@field _CurLen number 当前长度
---@field _TotalLen number 初始长度
---@field _Dir number 方块朝向（朝左朝右通过Scale.x=-1解决 只影响BOSS变短）
---@field _HeadGrid table 头部坐标（索引从1开始 不受_Dir影响 左头右尾）
---@field _TailGrid table 尾部坐标（索引从1开始 不受_Dir影响 左头右尾）
---@field _MaxW number 棋盘水平方向格子数
---@field _MaxH number 棋盘垂直方向格子数
---@field _Score number 方块分数
---@field _BlockType number 方块类型
---@field _ColorId number 颜色值
local XFangKuaiBlock = XClass(nil, "XFangKuaiBlock")

function XFangKuaiBlock:Ctor(control)
    self._Control = control
    self._HeadGrid = CS.UnityEngine.Vector2(0, 0)
    self._TailGrid = CS.UnityEngine.Vector2(0, 0)
end

function XFangKuaiBlock:InitData(stageId, blockData)
    self._Id = blockData.Id
    self._TotalLen = blockData.Length
    self._CurLen = blockData.Length
    self._Dir = blockData.Direction
    self._ItemId = blockData.ItemId
    self._BlockType = blockData.Type
    self._ColorId = blockData.Color
    self._Score = self._Control:GetBlockPoint(self._BlockType, self._TotalLen)
    self._HeadGrid = CS.UnityEngine.Vector2(blockData.X + 1, blockData.Y + 1)
    self._TailGrid = CS.UnityEngine.Vector2(self._HeadGrid.x + self._TotalLen - 1, self._HeadGrid.y)

    local stageConfig = self._Control:GetStageConfig(stageId)
    self._MaxW = stageConfig.SizeX
    self._MaxH = stageConfig.SizeY
end

---@param blockData XFangKuaiBlock
function XFangKuaiBlock:CopyBlockData(id, len, pos, blockData, itemId)
    self._Id = id
    self._TotalLen = len
    self._CurLen = len
    self._Dir = blockData:GetDirection()
    self._ItemId = itemId
    self._BlockType = blockData:GetBlockType()
    self._ColorId = blockData:GetColor()
    self._Score = self._Control:GetBlockPoint(self._BlockType, self._TotalLen)
    self._HeadGrid = pos
    self._TailGrid = CS.UnityEngine.Vector2(pos.x + self._TotalLen - 1, pos.y)
    self._MaxW = blockData:GetMaxWidth()
    self._MaxH = blockData:GetMaxHeight()
end

---设置棋盘大小
function XFangKuaiBlock:SetContentSize(maxW, maxH)
    self._MaxW = maxW
    self._MaxH = maxH
end

function XFangKuaiBlock:GetId()
    return self._Id
end

function XFangKuaiBlock:GetHeadGrid()
    return self._HeadGrid
end

function XFangKuaiBlock:GetTailGrid()
    return self._TailGrid
end

function XFangKuaiBlock:GetMaxWidth()
    return self._MaxW
end

function XFangKuaiBlock:GetMaxHeight()
    return self._MaxH
end

function XFangKuaiBlock:GetLen()
    return self._CurLen
end

function XFangKuaiBlock:GetTotalLen()
    return self._TotalLen
end

-- 道具不会附着在BOSS上
function XFangKuaiBlock:GetItemId()
    return self._ItemId
end

function XFangKuaiBlock:GetColor()
    return self._ColorId
end

function XFangKuaiBlock:GetDirection()
    return self._Dir
end

function XFangKuaiBlock:GetBlockType()
    return self._BlockType
end

function XFangKuaiBlock:GetScore()
    return self._Score
end

function XFangKuaiBlock:IsBoss()
    return self:GetBlockType() == XEnumConst.FangKuai.BlockType.Boss
end

---方块方向是否朝左
function XFangKuaiBlock:IsFacingLeft()
    return self._Dir == 1
end

function XFangKuaiBlock:IsSingleItemBlock()
    return XTool.IsNumberValid(self._ItemId) and self._TotalLen == 1
end

function XFangKuaiBlock:UpdatePos(posX, posY)
    posX = posX or self._HeadGrid.x
    posY = posY or self._HeadGrid.y
    self._HeadGrid.x = posX
    self._HeadGrid.y = posY
    self._TailGrid.x = self:CalculateTailPos(posX)
    self._TailGrid.y = posY
end

function XFangKuaiBlock:UpdateLen(len)
    self._CurLen = len
    if self:IsFacingLeft() then
        self._TailGrid = CS.UnityEngine.Vector2(self._HeadGrid.x + len - 1, self._HeadGrid.y)
    else
        self._HeadGrid = CS.UnityEngine.Vector2(self._TailGrid.x - len + 1, self._TailGrid.y)
    end
    self._Score = self._Control:GetBlockPoint(self._BlockType, self._CurLen)
end

function XFangKuaiBlock:CalculateTailPos(gridX)
    return gridX + self._CurLen - 1
end

---获取距离目标的距离
function XFangKuaiBlock:GetDistanceX(gridY)
    return math.abs(self._HeadGrid.x - gridY)
end

---获取距离目标的距离
function XFangKuaiBlock:GetDistanceY(gridY)
    return math.abs(self._HeadGrid.y - gridY)
end

function XFangKuaiBlock:CheckMoveUp()
    return self._HeadGrid.y < self._MaxH
end

function XFangKuaiBlock:GetNextUpGrid(num)
    num = num or 1
    return self._HeadGrid.y + num
    --return math.min(self._MaxH, self._HeadGrid.y + num)
end

---获取方块占用的所有格子
function XFangKuaiBlock:GetOccupyGrids()
    local occupy = {}
    for i = self._HeadGrid.x, self._TailGrid.x do
        table.insert(occupy, { x = i, y = self._HeadGrid.y })
    end
    return occupy
end

---方块是否在有效区域内
function XFangKuaiBlock:IsOnEffectiveArea()
    return self._HeadGrid.y >= 1 and self._HeadGrid.y <= self._MaxH
end

---获取方块下方的所有格子
function XFangKuaiBlock:GetAllGridDown()
    local drop = {}
    for y = self._HeadGrid.y - 1, 1, -1 do
        local grids = {}
        for x = self._HeadGrid.x, self._TailGrid.x do
            table.insert(grids, { x = x, y = y })
        end
        table.insert(drop, grids)
    end
    return drop
end

function XFangKuaiBlock:GetDropFinalGridY(needDropLayer)
    return math.max(1, self._HeadGrid.y - needDropLayer)
end

function XFangKuaiBlock:CheckData(serviceData)
    if self._CurLen ~= serviceData.Length then
        return string.format("Id = %s Length %s %s", self._Id, self._CurLen, serviceData.Length)
    end
    if self._Dir ~= serviceData.Direction then
        return string.format("Id = %s Direction %s %s", self._Id, self._Dir, serviceData.Direction)
    end
    if self._HeadGrid.x ~= serviceData.X + 1 or self._HeadGrid.y ~= serviceData.Y + 1 then
        return string.format("Id = %s Position %s %s %s %s", self._Id, self._HeadGrid.x, serviceData.X + 1, self._HeadGrid.y, serviceData.Y + 1)
    end
    if self._ItemId ~= serviceData.ItemId then
        return string.format("Id = %s ItemId %s %s", self._Id, self._ItemId, serviceData.ItemId)
    end
    return nil
end

return XFangKuaiBlock