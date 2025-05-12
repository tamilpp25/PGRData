local XConnectingLineGrid = require("XModule/XConnectingLine/XEntity/XConnectingLineGrid")
local XConnectingLineWire = require("XModule/XConnectingLine/XEntity/XConnectingLineWire")
local XConnectingLineGridBuffer = require("XModule/XConnectingLine/XEntity/XConnectingLineGridBuffer")

---@class XConnectingLineGame
local XConnectingLineGame = XClass(nil, "XConnectingLineGame")

function XConnectingLineGame:Ctor()
    self._StageId = 0

    -- column = x, row = y
    ---@type XConnectingLineGrid[][]
    self._Map = {}
    self._AvatarAmount = 0
    self._GridAmount = 0

    self._GridUiSize = { X = 0, Y = 0, HalfX = 0, HalfY = 0 }
    self._BoardCount = { Column = 0, Row = 0 }
    self._DragOffset = { X = 0, Y = 0 }

    ---@type XConnectingLineWire[]
    self._LineOnBoard = {}

    ---@type XConnectingLineWire
    self._LinePainting = nil

    ---@type XConnectingLineGridBuffer[]
    self._BufferLine = {}
    self._BufferLineSize = 0

    self._ConnectingHoleCd = 3
    self._ConnectingHoleLastTimestamp = 0
    self._ConnectingHoleMusicCd = 0.5
    self._ConnectingHoleMusicLastTimestamp =0
    
    self._HasRequested = false
end

function XConnectingLineGame:SetGridSize(x, y)
    self._GridUiSize.X = x
    self._GridUiSize.Y = y
    self._GridUiSize.HalfX = x / 2
    self._GridUiSize.HalfY = y / 2
end

function XConnectingLineGame:SetDragOffset(x, y)
    self._DragOffset.X = x
    self._DragOffset.Y = y
end

function XConnectingLineGame:GetGridSize()
    return self._GridUiSize
end

function XConnectingLineGame:SetStageId(stageId)
    self._StageId = stageId
end

function XConnectingLineGame:InitGrids(gridsConfig, avatarConfig)
    for i = 1, XEnumConst.CONNECTING_LINE.MAX_COLUMN do
        local id = self._StageId * 100 + i
        local config = gridsConfig[id]
        if config then
            self:_InitRow(config, avatarConfig)
        else
            break
        end
    end
    if #self._Map == 0 then
        for i, config in pairs(gridsConfig) do
            if config.StageId == self._StageId then
                self:_InitRow(config, avatarConfig)
            end
        end
    end

    local row, column
    column = #self._Map
    -- 认为总是正方形，如果出现异形，需要配置列长度
    row = column
    self._BoardCount.Row = row
    self._BoardCount.Column = column

    self:InitGridAmount()
    self:InitAvatarCount()

    if column > XEnumConst.CONNECTING_LINE.MAX_COLUMN then
        XLog.Error("[XConnectingLineGame] MAX_COLUMN 这个常量有用来计算, 配置的最大行数已经超过此常量", column)
    end
end

---@param configGrid XTableConnectingLineGrid
---@param configAvatar XTableConnectingLineHead[]
function XConnectingLineGame:_InitRow(configGrid, configAvatar)
    local row = configGrid.Row
    local columnArray = configGrid.Column
    for column = 1, #columnArray do
        self._Map[column] = self._Map[column] or {}
        local grid = self._Map[column][row]
        if not grid then
            grid = XConnectingLineGrid.New()
            self._Map[column][row] = grid
        end
        local avatarId = columnArray[column]
        grid:SetAvatarId(avatarId)
        grid:SetPos(column, row)

        local avatar = configAvatar[avatarId]
        if avatarId > 0 then
            grid:SetAvatarIcon(avatar.HeadPic)
            grid:SetColor(avatar.Color)
            grid:SetHeadBg(avatar.GridHeadBg)
            grid:SetGridBg(avatar.GridBg)
            grid:SetLineColor(avatar.LineColor)
        elseif grid:IsHole() then
            grid:SetAvatarIcon(avatar.HeadPic)
        end
    end
end

---@param operation XConnectingLineOperation
function XConnectingLineGame:Execute(operation)
    -- 按下
    if operation.Type == XEnumConst.CONNECTING_LINE.OPERATION_TYPE.POINT_DOWN then
        local grid = self:FindGridExcludeEmpty(operation:GetPos())
        if not grid then
            return
        end
        if grid:IsAvatar() then
            self._LinePainting = XConnectingLineWire.New()
            self._LinePainting:SetHead(grid)
        end
        self:UpdateBuffer()
        return
    end

    -- 划动
    if operation.Type == XEnumConst.CONNECTING_LINE.OPERATION_TYPE.POINT_MOVE then
        local linePainting = self._LinePainting
        if not linePainting then
            return
        end
        local mousePos = operation:GetPos()
        local grid = self:FindGridByUiPos(mousePos)
        -- 找不到格子
        if not grid then
            return
        end

        -- 还在一个格子里, 忽略
        local tailGrid = linePainting:GetTail()
        if grid:Equals(tailGrid) then
            return
        end

        --region 根据角度猜测，目标格子
        local lastPos = tailGrid:GetPos()
        --local gridSize = self._GridUiSize
        local lastPosUi = tailGrid:GetPosUI()
        local lastX, lastY = lastPosUi.X, lastPosUi.Y

        local x, y = mousePos.X - lastX, mousePos.Y - lastY
        local angle = math.atan(y, x) / math.pi * 180
        angle = math.floor(angle)
        angle = angle % 360

        local possiblePos = { X = lastPos.X, Y = lastPos.Y }
        if angle > 45 and angle < 135 then
            -- 向上
            possiblePos.Y = possiblePos.Y - 1
        elseif angle > 135 and angle < 225 then
            -- 向左
            possiblePos.X = possiblePos.X - 1
        elseif angle > 225 and angle < 315 then
            -- 向下
            possiblePos.Y = possiblePos.Y + 1
        else
            -- 向右
            possiblePos.X = possiblePos.X + 1
        end
        local possibleGrid = self:GetGrid(possiblePos.X, possiblePos.Y)
        if possibleGrid then
            grid = possibleGrid
        end
        if grid and grid:IsHole() then
            local currentTime = XTime.GetServerNowTimestamp()
            if currentTime - self._ConnectingHoleLastTimestamp > self._ConnectingHoleCd then
                XUiManager.TipText("ConnectingLineHole")
                self._ConnectingHoleLastTimestamp = currentTime
                self._ConnectingHoleMusicLastTimestamp = currentTime
            else
                if currentTime - self._ConnectingHoleMusicLastTimestamp > self._ConnectingHoleMusicCd then
                    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Tip_small)
                    self._ConnectingHoleMusicLastTimestamp = currentTime
                end
            end
            return
        end
        --endregion

        -- 连到上一个路过节点，撤回
        local gridLastButOne = linePainting:GetLastButOne()
        if grid:Equals(gridLastButOne) then
            linePainting:UndoLink(grid)
            self:UpdateBuffer()
            return
        end

        -- 已经连好
        if linePainting:IsComplete() then
            return
        end

        -- 连到非相邻点, 无事发生
        if not grid:IsNeighbour(tailGrid) then
            return
        end

        -- 连到已经添加的点，无事发生
        if linePainting:IsInclude(grid) then
            return
        end

        -- bug 可以打斜连到头像
        -- 连到头像
        if grid:IsAvatar() then
            -- 连到能成线的节点
            if linePainting:IsCanLink(grid) then
                linePainting:DoLink(grid)
                self:UpdateBuffer()
                return
            end

            -- 连到不能成线的节点
            return
        end

        -- 连到空节点, 连接
        if grid:IsEmpty() then
            linePainting:DoLink(grid)
            self:UpdateBuffer()
            return
        end

        XLog.Error("[XConnectingLineGame] undefined state on PointerMoving")
        return
    end

    -- 松手
    if operation.Type == XEnumConst.CONNECTING_LINE.OPERATION_TYPE.POINT_UP then
        local linePainting = self._LinePainting
        if not linePainting then
            return
        end
        self:LogLine(linePainting)

        if linePainting:IsComplete() then
            -- 检测冲突, 移除已添加的线
            local isRemoveExistLine = false
            for i = #self._LineOnBoard, 1, -1 do
                local line = self._LineOnBoard[i]
                if line:IsCross(linePainting) then
                    table.remove(self._LineOnBoard, i)
                    isRemoveExistLine = true
                end
            end

            self:AddLine(linePainting)
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XEnumConst.CONNECTING_LINE.COMPLETE_LINE_SOUND)
            if isRemoveExistLine then
                XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_BUBBLE, XEnumConst.CONNECTING_LINE.BUBBLE.CONNECT_CHANGE)
            else
                XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_BUBBLE, XEnumConst.CONNECTING_LINE.BUBBLE.CONNECT_SUCCESS)
            end
        else
            XEventManager.DispatchEvent(XEventId.EVENT_CONNECTING_LINE_BUBBLE, XEnumConst.CONNECTING_LINE.BUBBLE.CONNECT_FAIL)
        end
        self._LinePainting = nil
        self:UpdateBuffer()
        return
    end
end

---@return XConnectingLineGrid
function XConnectingLineGame:FindGridByUiPos(position)
    local column = math.ceil(math.abs(position.X) / self._GridUiSize.X)
    local row = math.ceil(math.abs(position.Y) / self._GridUiSize.Y)
    return self:GetGrid(column, row)
end

function XConnectingLineGame:IsEmptyGrid(x, y)
    return false
end

function XConnectingLineGame:FindGridExcludeEmpty(position)
    local grid = self:FindGridByUiPos(position)
    if grid then
        if grid:IsHole() then
            return nil
        end
    end
    return grid
end

function XConnectingLineGame:AddLine(line)
    self._LineOnBoard[#self._LineOnBoard + 1] = line
end

function XConnectingLineGame:_GetBuffer(index)
    local buffer = self._BufferLine[index]
    if not buffer then
        buffer = XConnectingLineGridBuffer.New()
        self._BufferLine[index] = buffer
    end
    return buffer
end

function XConnectingLineGame:UpdateBuffer()
    -- 清空上次的缓存
    local buffSize = 0
    for i = 1, #self._BufferLine do
        local buffer = self._BufferLine[i]
        buffer:Clear()
    end

    -- 已画好的线 
    for i = 1, #self._LineOnBoard do
        local line = self._LineOnBoard[i]
        buffSize = buffSize + 1
        local buffer = self:_GetBuffer(buffSize)
        buffer:AddGridsByLine(line, self._GridUiSize)
    end

    -- 有正在画的线
    local linePainting = self._LinePainting
    if linePainting then
        -- 用正在画的线 创建map
        local mapPainting = {}
        local gridsPainting = linePainting:GetGrids()
        for i = 1, #gridsPainting do
            local grid = gridsPainting[i]
            local index = self:GetReducedIndex(grid)
            mapPainting[index] = true
        end

        -- 用map删掉相交的部分
        for i = 1, #self._LineOnBoard do
            local line = self._LineOnBoard[i]
            local buffer = self:_GetBuffer(i)

            if linePainting:IsCross(line) then
                local grids = buffer:GetGrids()
                for j = 1, #grids do
                    local grid = grids[j]
                    local index = self:GetReducedIndex(grid)
                    if mapPainting[index] then
                        buffer:RemoveAt(j)
                    end
                end
            end
        end

        -- 添加 正在画的线
        buffSize = buffSize + 1
        self._BufferLineSize = buffSize
        local bufferPainting = self:_GetBuffer(buffSize)
        bufferPainting:AddGridsByLine(self._LinePainting)
    end

    -- 刷新buffer的点坐标
    for i = 1, buffSize do
        local buffer = self._BufferLine[i]
        buffer:Draw(self._GridUiSize)
    end
end

-- 二维数组下标 => 一维数组下标
---@param grid XConnectingLineGrid
function XConnectingLineGame:GetReducedIndex(grid)
    local pos = grid:GetPos()
    return pos.X * self._BoardCount.Row + pos.Y
end

function XConnectingLineGame:GetBuffer()
    return self._BufferLine
end

---@param line XConnectingLineWire
function XConnectingLineGame:LogLine(line)
    local grids = line:GetGrids()
    local str = ""
    for i = 1, #grids do
        local grid = grids[i]
        local pos = grid:GetPos()
        str = str .. "{" .. pos.X .. "," .. pos.Y .. "},"
    end
end

function XConnectingLineGame:LogBuffer()
    local str = ""
    for i = 1, #self._BufferLine do
        local buffer = self._BufferLine[i]
        local lines = buffer:GetLine()
        for j = 1, #lines do
            local line = lines[j]
            for k = 1, #line do
                local point = line[k]
                str = str .. string.format("{%s, %s}, ", point.X, point.Y)
            end
            str = str .. "\n"
        end
    end
    print(str)
end

function XConnectingLineGame:LogMap()
    -- 为了与配置表一致, 直观, 所以要翻转
    local inverse = {}
    for column, grids in pairs(self._Map) do
        for row, grid in pairs(grids) do
            inverse[row] = inverse[row] or {}
            inverse[row][column] = grid
        end
    end

    local str = ""
    for row = #inverse, 1, -1 do
        local grids = inverse[row]
        for j = 1, #grids do
            local grid = grids[j]
            local id = grid:GetAvatarId()
            str = str .. id .. "\t"
        end
        str = str .. "\n"
    end

    print(str)
end

function XConnectingLineGame:GetAvatarMap()
    return self._Map
end

function XConnectingLineGame:GetFinishState()
    local linkCount = #self._LineOnBoard
    -- 秒通
    --if linkCount > 0 then
    --    return XEnumConst.CONNECTING_LINE.FINISH_STATE.PERFECT_COMPLETE
    --end

    if linkCount >= self._AvatarAmount then

        -- 因为线不可重叠, 所以 完美通关: 线穿过的格子数量 = 格子数量
        local gridOnBoardAmount = 0
        for i = 1, #self._LineOnBoard do
            local line = self._LineOnBoard[i]
            local grids = line:GetGrids()
            gridOnBoardAmount = gridOnBoardAmount + #grids
        end
        if gridOnBoardAmount == self._GridAmount then
            return XEnumConst.CONNECTING_LINE.FINISH_STATE.PERFECT_COMPLETE
        end

        return XEnumConst.CONNECTING_LINE.FINISH_STATE.COMPLETE
    end
    return XEnumConst.CONNECTING_LINE.FINISH_STATE.UN_COMPLETE
end

function XConnectingLineGame:InitAvatarCount()
    local avatarIdDict = {}
    for column = 1, #self._Map do
        local grids = self._Map[column]
        for j = 1, #grids do
            local grid = grids[j]
            if grid:IsAvatar() then
                local avatarId = grid:GetAvatarId()
                avatarIdDict[avatarId] = true
            end
        end
    end
    local avatarCount = 0
    for id, avatarId in pairs(avatarIdDict) do
        avatarCount = avatarCount + 1
    end
    self._AvatarAmount = avatarCount
end

function XConnectingLineGame:InitGridAmount()
    self._GridAmount = self._BoardCount.Row * self._BoardCount.Column

    -- 空洞不算
    for column, grids in pairs(self._Map) do
        for row, grid in pairs(grids) do
            if grid:IsHole() then
                self._GridAmount = self._GridAmount - 1
            end
        end
    end
end

function XConnectingLineGame:GetLinkedAmount()
    return #self._LineOnBoard
end

function XConnectingLineGame:GetAvatarAmount()
    return self._AvatarAmount
end

function XConnectingLineGame:GetLightGridAmount()
    local gridOnBoardAmount = 0
    for i = 1, #self._LineOnBoard do
        local line = self._LineOnBoard[i]
        local grids = line:GetGrids()
        gridOnBoardAmount = gridOnBoardAmount + #grids
    end
    return gridOnBoardAmount
end

function XConnectingLineGame:GetGridAmount()
    return self._GridAmount
end

function XConnectingLineGame:GetColumn()
    return self._BoardCount.Column
end

function XConnectingLineGame:GetGrid(x, y)
    if self._Map[x] then
        return self._Map[x][y]
    end
    return false
end

function XConnectingLineGame:GetGridExcludeEmpty()

end

function XConnectingLineGame:GetConnectedAvatarMap()
    local bufferList = self:GetBuffer()
    local dictLight = {}
    for i = 1, #bufferList do
        local buffer = bufferList[i]
        local headGrid = buffer:GetHeadGrid()
        local tailGrid = buffer:GetTailGrid()
        headGrid:GetPos()
        dictLight[headGrid:GetAvatarId()] = true
        dictLight[tailGrid:GetAvatarId()] = true
    end
    return dictLight
end

function XConnectingLineGame:ClearBoard()
    self._BufferLine = {}
    self._LineOnBoard = {}
    self._LinePainting = nil
    for column, grids in pairs(self._Map) do
        for row, grid in pairs(grids) do
            grid:SetAvatarId(0)
        end
    end
end

function XConnectingLineGame:SetHasRequested(value)
    self._HasRequested = value
end

function XConnectingLineGame:HasRequested()
    return self._HasRequested
end

return XConnectingLineGame
