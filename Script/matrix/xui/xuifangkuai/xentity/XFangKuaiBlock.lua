---@class XFangKuaiBlock 方块基础数据
---@field _Id number 唯一Id
---@field _BlockId number 方块Id
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
---@field _HitTimes number 方块受击次数
local XFangKuaiBlock = XClass(nil, "XFangKuaiBlock")

function XFangKuaiBlock:Ctor()
    self._HeadGrid = CS.UnityEngine.Vector2(0, 0)
    self._TailGrid = CS.UnityEngine.Vector2(0, 0)
end

function XFangKuaiBlock:InitDataByServer(stageId, blockData)
    self:SetId(blockData.Id)
    self:SetBlockId(blockData.BlockId)
    self:SetTotalLen(blockData.Length)
    self:SetLen(blockData.Length)
    self:SetDirection(blockData.Direction)
    self:SetItemId(blockData.ItemId)
    self:SetBlockType(blockData.Type)
    self:SetColor(blockData.Color)
    self:SetScore()
    self:SetGrid(blockData.X, blockData.Y)
    self:SetHitTimes(blockData.HitCount)

    local stageConfig = XMVCA.XFangKuai:GetStageConfig(stageId)
    self._MaxW = stageConfig.SizeX
    self._MaxH = stageConfig.SizeY
end

---@param blockData XFangKuaiBlock
function XFangKuaiBlock:CopyBlockData(id, len, pos, blockData, itemId)
    self:SetId(id)
    self:SetBlockId(blockData:GetBlockId())
    self:SetTotalLen(len)
    self:SetLen(len)
    self:SetDirection(blockData:GetDirection())
    self:SetItemId(itemId)
    self:SetBlockType(blockData:GetBlockType())
    self:SetColor(blockData:GetColor())
    self:SetScore()
    self:SetGrid(pos.x, pos.y)
    self:SetHitTimes(blockData:GetHitTimes())
    self._MaxW = blockData:GetMaxWidth()
    self._MaxH = blockData:GetMaxHeight()
end

---设置棋盘大小
function XFangKuaiBlock:SetContentSize(maxW, maxH)
    self._MaxW = maxW
    self._MaxH = maxH
end

function XFangKuaiBlock:SetId(id)
    self._Id = id
end

function XFangKuaiBlock:GetId()
    return self._Id
end

function XFangKuaiBlock:SetGrid(x, y)
    self._HeadGrid = CS.UnityEngine.Vector2(x, y)
    self._TailGrid = CS.UnityEngine.Vector2(x + self._TotalLen - 1, y)
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

function XFangKuaiBlock:SetLen(curLen)
    self._CurLen = curLen
end

function XFangKuaiBlock:GetLen()
    return self._CurLen
end

function XFangKuaiBlock:SetTotalLen(totalLen)
    self._TotalLen = totalLen
end

function XFangKuaiBlock:GetTotalLen()
    return self._TotalLen
end

function XFangKuaiBlock:SetItemId(itemId)
    self._ItemId = itemId
end

-- 道具不会附着在BOSS上
function XFangKuaiBlock:GetItemId()
    return self._ItemId
end

function XFangKuaiBlock:SetColor(colorId)
    self._ColorId = colorId
end

function XFangKuaiBlock:GetColor()
    return self._ColorId
end

-- 如果策划配置方向0 则为随机方向 可能为0或1 不能直接去读表 要通过BlockId拿到配置表里的Direction
function XFangKuaiBlock:SetDirection(dir)
    self._Dir = dir
end

function XFangKuaiBlock:GetDirection()
    return self._Dir
end

function XFangKuaiBlock:SetBlockType(blockType)
    self._BlockType = blockType
end

function XFangKuaiBlock:GetBlockType()
    return self._BlockType
end

function XFangKuaiBlock:SetScore()
    self._Score = XMVCA.XFangKuai:GetBlockPoint(self._BlockType, self._TotalLen)
end

function XFangKuaiBlock:GetScore()
    return self._Score
end

function XFangKuaiBlock:SetBlockId(blockId)
    self._BlockId = blockId
end

function XFangKuaiBlock:GetBlockId()
    return self._BlockId
end

function XFangKuaiBlock:SetHitTimes(times)
    self._HitTimes = times or 0
end

function XFangKuaiBlock:GetHitTimes()
    return self._HitTimes
end

function XFangKuaiBlock:SetMaxSize(stageId)
    local stageConfig = XMVCA.XFangKuai:GetStageConfig(stageId)
    self._MaxW = stageConfig.SizeX
    self._MaxH = stageConfig.SizeY
end

function XFangKuaiBlock:IsBoss()
    return self._BlockType == XEnumConst.FangKuai.BlockType.BossWane or
            self._BlockType == XEnumConst.FangKuai.BlockType.BossHit or
            self._BlockType == XEnumConst.FangKuai.BlockType.BossFission
end

---方块方向是否朝左
function XFangKuaiBlock:IsFacingLeft()
    return self._Dir == 1
end

function XFangKuaiBlock:IsSingleItemBlock()
    return XTool.IsNumberValid(self._ItemId) and self._TotalLen == 1
end

function XFangKuaiBlock:IsMaxHitTimes()
    return self._HitTimes >= self:GetMaxHitTimes()
end

function XFangKuaiBlock:GetMaxHitTimes()
    local maxHitTimes = XMVCA.XFangKuai:GetBlockConfig(self._BlockId).MaxHitTimes
    if not XTool.IsNumberValid(maxHitTimes) then
        return 1 -- 没配置则默认最大次数为1
    end
    return maxHitTimes
end

function XFangKuaiBlock:UpdatePos(posX, posY)
    posX = posX or self._HeadGrid.x
    posY = posY or self._HeadGrid.y
    self._HeadGrid.x = posX
    self._HeadGrid.y = posY
    self._TailGrid.x = self:CalculateTailPos(posX)
    self._TailGrid.y = posY
end

---@param isHead boolean 是否朝头部方向增长/缩短，默认朝尾部
function XFangKuaiBlock:UpdateLen(len, isHead)
    self._CurLen = len
    local isLeft = self:IsFacingLeft()
    if (isLeft and not isHead) or (not isLeft and isHead) then
        self._TailGrid = CS.UnityEngine.Vector2(self._HeadGrid.x + len - 1, self._HeadGrid.y)
    else
        self._HeadGrid = CS.UnityEngine.Vector2(self._TailGrid.x - len + 1, self._TailGrid.y)
    end
    self._Score = XMVCA.XFangKuai:GetBlockPoint(self._BlockType, self._CurLen)
end

-- offsetX和offsetY为正数表示往右（后面）偏移，负数表示往左（前面）偏移
-- 外部不需要管方块朝向，认为都是朝左就行
function XFangKuaiBlock:UpdateLenAndOffset(len, offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    if not self:IsFacingLeft() then
        offsetX = -offsetX
        offsetY = -offsetY
    end

    self:UpdateLen(len)
    self._HeadGrid.x = self._HeadGrid.x + offsetX
    self._HeadGrid.y = self._HeadGrid.y + offsetY
    self._TailGrid.x = self._TailGrid.x + offsetX
    self._TailGrid.y = self._TailGrid.y + offsetY
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

function XFangKuaiBlock:GetServerData(gridY)
    local data = {}
    data.Id = self._Id
    data.BlockId = self._BlockId
    data.Type = self._BlockType
    data.X = math.floor(self._HeadGrid.x)
    data.Y = gridY or math.floor(self._HeadGrid.y) -- 底部预览方块比较特殊
    data.Length = self._CurLen
    data.Color = self._ColorId
    data.Direction = self._Dir
    data.ItemId = self._ItemId or 0
    data.HitCount = self._HitTimes
    return data
end

return XFangKuaiBlock