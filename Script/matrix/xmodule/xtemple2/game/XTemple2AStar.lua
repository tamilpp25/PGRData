---@class XTemple2AStar
local XTemple2AStar = XClass(nil, "XTemple2AStar")

function XTemple2AStar:Ctor()
end

---@param map XTemple2Map
function XTemple2AStar:GetPath(map, startPos, endPos)
    if not startPos then
        return false
    end
    if not endPos then
        return false
    end

    ---@type XTemple2AStarGridData[]
    local openList = {}
    ---@type XTemple2AStarGridData[]
    local closeList = {}

    local G = 0
    local H = self:GetH(startPos, endPos)
    ---@class XTemple2AStarGridData
    local startGridData = {
        ---@type XLuaVector2
        Pos = startPos,
        ---@type XTemple2AStarGridData
        Parent = nil,
        -- 实际代价
        G = G,
        -- 估计代价
        H = H,
        F = H + G,
    }
    openList[#openList + 1] = startGridData

    ---@type XTemple2AStarGridData
    local targetGridData = false
    for i = 1, 1000 do
        local gridData = openList[1]
        table.remove(openList, 1)

        if not gridData then
            --XLog.Warning("[XTemple2AStar] 寻路失败")
            break
        end

        if gridData.Pos:EqualVector(endPos) then
            targetGridData = gridData
            break
        end

        local x = gridData.Pos.x
        local y = gridData.Pos.y
        --顺序：右 下 左 上（因为相同F的插入逻辑，导致nextStep逆序）
        self:NextStep(x, y + 1, map, endPos, gridData, openList, closeList)
        self:NextStep(x - 1, y, map, endPos, gridData, openList, closeList)
        self:NextStep(x, y - 1, map, endPos, gridData, openList, closeList)
        self:NextStep(x + 1, y, map, endPos, gridData, openList, closeList)
        closeList[#closeList + 1] = gridData
    end

    if targetGridData then
        local path = {}
        local currentGridData = targetGridData
        for i = 1, 1000 do
            if not currentGridData then
                break
            end
            path[#path + 1] = currentGridData.Pos
            currentGridData = currentGridData.Parent
        end

        -- 逆序
        for i = 1, #path / 2 do
            local toSwap = #path - i + 1
            path[i], path[toSwap] = path[toSwap], path[i]
        end
        return path
    end
    return false
end

---@param list XTemple2AStarGridData[]
function XTemple2AStar:IsOnList(list, x, y)
    for i = 1, #list do
        local openGridData = list[i]
        if openGridData.Pos.x == x and openGridData.Pos.y == y then
            return true, i
        end
    end
    return false
end

---@param openList XTemple2AStarGridData[]
---@param map XTemple2Map
function XTemple2AStar:NextStep(x, y, map, endPos, parentData, openList, closeList)
    local childGrid = map:GetGrid(x, y)
    if not childGrid then
        return
    end

    -- 终点认为是可走的
    if not (x == endPos.x and y == endPos.y) then
        if not childGrid:IsCanWalk() then
            return
        end
    end

    local childData = self:GetGridData(map, x, y, endPos, parentData)

    local isOnOpenList, openListIndex = self:IsOnList(openList, x, y)
    local isOnCloseList, closeListIndex = self:IsOnList(closeList, x, y)
    if not isOnOpenList and not isOnCloseList then
        self:InsertionSort(openList, childData)

    elseif isOnOpenList then
        local repeatOpenData = openList[openListIndex]
        if childData.F < repeatOpenData.F then
            repeatOpenData.Parent = childData.Parent
            repeatOpenData.G = childData.G
            repeatOpenData.H = childData.H
            repeatOpenData.F = childData.F
            -- 重新排序
            table.remove(openList, openListIndex)
            self:InsertionSort(openList, repeatOpenData)
        end
    else
        local repeatCloseData = closeList[closeListIndex]
        if childData.F < repeatCloseData.F then
            table.remove(closeList, closeListIndex)
            self:InsertionSort(openList, childData)
        end
    end
end

---@param openList XTemple2AStarGridData[]
---@param childData XTemple2AStarGridData
function XTemple2AStar:InsertionSort(openList, childData)
    -- 插入排序
    local index = #openList + 1
    for i = 1, #openList do
        local data = openList[i]
        if childData.F < data.F then
            index = 1
        end
    end
    table.insert(openList, index, childData)
end

---@param map XTemple2Map
---@param parent XTemple2AStarGridData
function XTemple2AStar:GetGridData(map, x, y, endPos, parent)
    local grid = map:GetGrid(x, y)
    local currentPos = grid:GetPosition():Clone()   --clone 防止生成path后,grid坐标发生变化
    local H = self:GetH(currentPos, endPos)
    local G = parent.G + 1

    ---@type XTemple2AStarGridData
    local startGridData = {
        ---@type XLuaVector2
        Pos = currentPos,
        ---@type XTemple2AStarGridData
        Parent = parent,
        G = G,
        H = H,
        F = H + G,
    }
    return startGridData
end

-- 估计代价
function XTemple2AStar:GetH(startPos, endPos)
    local y = endPos.y - startPos.y
    local x = endPos.x - startPos.x
    return math.abs(x) + math.abs(y)
end

return XTemple2AStar