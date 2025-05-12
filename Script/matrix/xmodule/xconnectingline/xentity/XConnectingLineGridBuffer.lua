---@class XConnectingLineGridBuffer
local XConnectingLineGridBuffer = XClass(nil, "XConnectingLineGridBuffer")

function XConnectingLineGridBuffer:Ctor()
    ---@type XConnectingLineGrid[]
    self._Grids = {}

    self._Line = {}

    self._LineColor = nil

    self._GridColor = nil
end

function XConnectingLineGridBuffer:Clear()
    for i = #self._Grids, 1, -1 do
        self._Grids[i] = nil
    end
    for i = #self._Line, 1, -1 do
        self._Line[i] = nil
    end
    self._LineColor = nil
end

---@param line XConnectingLineWire
function XConnectingLineGridBuffer:AddGridsByLine(line)
    local grids = line:GetGrids()
    for i = 1, #grids do
        local grid = grids[i]
        self._Grids[#self._Grids + 1] = grid
    end
    self._LineColor = line:GetColor()

    local headGrid = line:GetHead()
    if headGrid then
        self._GridColor = headGrid:GetColor()
    end
end

function XConnectingLineGridBuffer:RemoveAt(index)
    local grid = self._Grids[index]
    if grid then
        local copy = grid:Clone()
        copy:SetIsRemoved(true)
        self._Grids[index] = copy
    end
end

function XConnectingLineGridBuffer:GetGrids()
    return self._Grids
end

---@param grid XConnectingLineGrid
function XConnectingLineGridBuffer:_GetPos(grid, gridSize)
    local pos = grid:GetPosUI()
    return pos.X + gridSize.HalfX, pos.Y + gridSize.HalfY
end

function XConnectingLineGridBuffer:Draw(gridSize)
    local grids = self:GetGrids()
    local line2Add = {}
    for i = 1, #grids do
        local grid = grids[i]
        if grid then
            -- head不连头像
            if grid:IsAvatar() and i == 1 then
                -- do nothing

            elseif grid:IsRemoved() or (grid:IsAvatar() and i > 1) then
                -- 线断开 or tail连头像，取中点
                if #line2Add > 0 then
                    local lastPoint = line2Add[#line2Add]
                    local nextPointX, nextPointY = self:_GetPos(grid, gridSize)
                    local point = self:_GetMiddlePoint(lastPoint.X, lastPoint.Y, nextPointX, nextPointY)
                    line2Add[#line2Add + 1] = point
                    self._Line[#self._Line + 1] = line2Add
                    line2Add = {}
                end
            else
                local x, y = self:_GetPos(grid, gridSize)

                local lastGrid = grids[i - 1]
                if lastGrid and (lastGrid:IsRemoved() or lastGrid:IsAvatar()) then
                    local breakPointX, breakPointY = self:_GetPos(lastGrid, gridSize)
                    local breakPoint = self:_GetMiddlePoint(x, y, breakPointX, breakPointY)
                    line2Add[#line2Add + 1] = breakPoint
                end

                local point = { X = x, Y = y }
                line2Add[#line2Add + 1] = point
            end
        end
    end
    -- 加入最后的线
    if #line2Add > 0 then
        self._Line[#self._Line + 1] = line2Add
    end
end

function XConnectingLineGridBuffer:_GetMiddlePoint(x1, y1, x2, y2)
    return { X = (x1 + x2) / 2, Y = (y1 + y2) / 2 }
end

-- 三点成一直线
function XConnectingLineGridBuffer:_IsLine(p1, p2, p3)
    if p1.X == p2.X and p1.X == p3.X then
        return true
    end
    if p1.Y == p2.Y and p1.Y == p3.Y then
        return true
    end
    return false
end

function XConnectingLineGridBuffer:GetLine()
    return self._Line
end

function XConnectingLineGridBuffer:GetLineColor()
    return self._LineColor
end

function XConnectingLineGridBuffer:GetGridColor()
    return self._GridColor
end

function XConnectingLineGridBuffer:GetHeadGrid()
    return self._Grids[1]
end

function XConnectingLineGridBuffer:GetTailGrid()
    return self._Grids[#self._Grids]
end

function XConnectingLineGridBuffer:IsLinked()
    local headGrid = self:GetHeadGrid()
    local tailGrid = self:GetTailGrid()
    if headGrid and tailGrid and headGrid:IsCanLink(tailGrid) then
        return true
    end
    return false
end

return XConnectingLineGridBuffer
