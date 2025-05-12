---@class XTheatre4ChapterData
local XTheatre4ChapterData = XClass(nil, "XTheatre4ChapterData")

function XTheatre4ChapterData:Ctor()
    -- 地图组
    self.MapGroup = 0
    -- 地图id
    self.MapId = 0
    -- 一般格子
    ---@type table<number, XTheatre4Grid> key:格子id value:格子数据 id规则是 100 * 100 + PosX * 100 + PosY
    self.Grids = {}
    -- 生成精英怪数量
    self.EliteCount = 0
    -- 结算类型
    self.IsPass = false
    -- 最大可回溯天数
    self.MaxTracebackDays = 0
end

-- 服务端通知
function XTheatre4ChapterData:NotifyChapterData(data)
    self.MapGroup = data.MapGroup or 0
    self.MapId = data.MapId or 0
    self:UpdateGrids(data.Grids, true)
    self.EliteCount = data.EliteCount or 0
    self.IsPass = data.IsPass or false
    self.MaxTracebackDays = data.MaxTracebackDays or 0
end

function XTheatre4ChapterData:UpdateGrids(data, isAdd)
    if not data then
        return
    end
    for _, v in pairs(data) do
        if isAdd then
            self:AddGrid(v)
        else
            self:UpdateGrid(v)
        end
    end
end

-- 添加格子数据
function XTheatre4ChapterData:AddGrid(data)
    if not data then
        return
    end
    local gridId = self:GetGridId(data.PosX, data.PosY)
    ---@type XTheatre4Grid
    local grid = self.Grids[gridId]
    if not grid then
        grid = require("XModule/XTheatre4/XEntity/XTheatre4Grid").New()
        self.Grids[gridId] = grid
    end
    grid:NotifyGridData(data)
end

-- 更新格子数据 不添加新的格子
function XTheatre4ChapterData:UpdateGrid(data)
    if not data then
        return
    end
    local gridId = self:GetGridId(data.PosX, data.PosY)
    ---@type XTheatre4Grid
    local grid = self.Grids[gridId]
    if grid then
        grid:NotifyGridData(data)
    end
end

-- 获取格子id
function XTheatre4ChapterData:GetGridId(posX, posY)
    return 100 * 100 + posX * 100 + posY
end

-- 获取地图组
function XTheatre4ChapterData:GetMapGroup()
    return self.MapGroup
end

-- 获取地图id
function XTheatre4ChapterData:GetMapId()
    return self.MapId
end

-- 获取格子数据
---@return XTheatre4Grid
function XTheatre4ChapterData:GetGridData(gridId)
    return self.Grids[gridId] or nil
end

-- 获取所有格子数据
---@return table<number, XTheatre4Grid>
function XTheatre4ChapterData:GetAllGridData()
    return self.Grids
end

-- 检查是否通关
function XTheatre4ChapterData:CheckIsPass()
    return self.IsPass
end

-- 获取格子id列表
---@return number[]
function XTheatre4ChapterData:GetGridIds()
    local gridIds = {}
    for k, _ in pairs(self.Grids) do
        table.insert(gridIds, k)
    end
    return gridIds
end

-- 获取所有格子id列表 [y][x] = gridId
---@return table<number, table<number, number>>
function XTheatre4ChapterData:GetGridPosIds()
    local gridIds = {}
    for _, grid in pairs(self.Grids) do
        local posX, posY = grid:GetGridPos()
        if not gridIds[posY] then
            gridIds[posY] = {}
        end
        gridIds[posY][posX] = grid:GetGridId()
    end
    return gridIds
end

-- 获取所有boss格子数据
---@return XTheatre4Grid[]
function XTheatre4ChapterData:GetAllBossGridData()
    local bossGrids = {}
    for _, grid in pairs(self.Grids) do
        if grid:IsGridTypeBoss() then
            table.insert(bossGrids, grid)
        end
    end
    return bossGrids
end

-- 获取Boss惩罚倒计时
function XTheatre4ChapterData:GetBossPunishCountdown()
    local bossGrids = self:GetAllBossGridData()
    if XTool.IsTableEmpty(bossGrids) then
        return -1
    end
    -- 每个boss都有倒计时直接取第一个
    return bossGrids[1]:GetGridPunishCountdown()
end

function XTheatre4ChapterData:GetMaxTracebackDays()
    return self.MaxTracebackDays
end

return XTheatre4ChapterData
