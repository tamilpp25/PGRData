-- 其实应该命名作 XConnectingLineLine, 但是叠词词, 就改成wire()
---@class XConnectingLineWire
local XConnectingLineWire = XClass(nil, "XConnectingLineWire")

function XConnectingLineWire:Ctor()
    ---@type XConnectingLineGrid[]
    self._Grids = {}

    self._CrossCode = 0
    self._IsDirtyCrossCode = true
end

function XConnectingLineWire:GetHead()
    return self._Grids[1]
end

---@return XConnectingLineGrid
function XConnectingLineWire:GetTail()
    return self._Grids[#self._Grids]
end

-- 倒数第二个节点
function XConnectingLineWire:GetLastButOne()
    return self._Grids[#self._Grids - 1]
end

function XConnectingLineWire:SetHead(grid)
    self._Grids[1] = grid
    self._IsDirtyCrossCode = true
end

function XConnectingLineWire:DoLink(grid)
    self._Grids[#self._Grids + 1] = grid
    self._IsDirtyCrossCode = true
end

function XConnectingLineWire:UndoLink()
    if #self._Grids > 1 then
        self._Grids[#self._Grids] = nil
        self._IsDirtyCrossCode = true
    end
end

function XConnectingLineWire:IsComplete()
    local head = self:GetHead()
    if not head then
        return false
    end
    local tail = self:GetTail()
    return head:IsCanLink(tail)
end

---@param line XConnectingLineWire
function XConnectingLineWire:IsCross(line)
    local code1 = self:GetCode4CrossCheck()
    local code2 = line:GetCode4CrossCheck()
    local cross = code1 & code2
    return cross ~= 0
end

function XConnectingLineWire:GetCode4CrossCheck()
    if self._IsDirtyCrossCode then
        local code = 0
        for i = 1, #self._Grids do
            local grid = self._Grids[i]
            local pos = grid:GetPos()
            code = code | 1 << (pos.X * XEnumConst.CONNECTING_LINE.MAX_COLUMN + pos.Y)
        end
        self._CrossCode = code
        self._IsDirtyCrossCode = false
    end
    return self._CrossCode
end

function XConnectingLineWire:GetGrids()
    return self._Grids
end

function XConnectingLineWire:GetGrid(index)
    return self._Grids[index]
end

---@param grid XConnectingLineGrid
function XConnectingLineWire:IsInclude(grid)
    for i = 1, #self._Grids do
        local gridInclude = self._Grids[i]
        if gridInclude:Equals(grid) then
            return true
        end
    end
    return false
end

function XConnectingLineWire:IsCanLink(grid)
    return self:GetHead():IsCanLink(grid)
end

function XConnectingLineWire:GetColor()
    return self:GetHead():GetLineColor()
end

return XConnectingLineWire