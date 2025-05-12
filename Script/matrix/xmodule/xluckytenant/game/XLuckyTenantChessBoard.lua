---@class XLuckyTenantChessBoard
local XLuckyTenantChessBoard = XClass(nil, "XLuckyTenantChessBoard")

function XLuckyTenantChessBoard:Ctor()
    ---@type XLuckyTenantPiece[]
    self._Pieces = {}
    --- 正在计算的分数
    self._Score4Position = {}
    --- 已经执行的分数
    self._Score4PositionImplemented = {}
    self._Column = 0
    self._Row = 0
    self._PiecesAmount = 0
end

---@param config XTable.XTableLuckyTenantStage
function XLuckyTenantChessBoard:Init(config)
    local column = config.Column
    local row = config.Row
    self._Column = column
    self._Row = row
    self._PiecesAmount = column * row
    for y = 1, row do
        for x = 1, column do
            local index = self:GetIndex(x, y)
            self._Pieces[index] = false
            self._Score4Position[index] = 0
            self._Score4PositionImplemented[index] = 0
        end
    end
end

function XLuckyTenantChessBoard:GetIndex(x, y)
    return (y - 1) * self._Column + x
end

function XLuckyTenantChessBoard:GetXY(index)
    local x = (index - 1) % self._Column + 1
    local y = math.ceil(index / self._Column)
    return x, y
end

function XLuckyTenantChessBoard:ClearEveryTurn()
    for i = 1, #self._Pieces do
        local piece = self._Pieces[i]
        if piece then
            piece:ClearEveryTurn()
            self._Pieces[i] = false
        end
    end
    for i = 1, #self._Score4Position do
        self._Score4Position[i] = 0
    end
    for i = 1, #self._Score4PositionImplemented do
        self._Score4PositionImplemented[i] = 0
    end
end

function XLuckyTenantChessBoard:SetPieceByIndex(piece, index, x, y)
    local pieceOnPos = self._Pieces[index]
    if pieceOnPos then
        if pieceOnPos ~= piece then
            pieceOnPos:ResetPosition()
            XMVCA.XLuckyTenant:Print("用", piece:GetName(), "替换了棋盘上的棋子", pieceOnPos:GetName(), ",他的位置是(" .. tostring(x) .. "," .. tostring(y) .. ")")
        end
    end
    self._Pieces[index] = piece
    if not x or not y then
        x, y = self:GetXY(index)
    end
    piece:SetPosition(x, y)
    return true
end

---@param piece XLuckyTenantPiece
function XLuckyTenantChessBoard:SetPieceByPosition(piece, x, y)
    if x > self._Column or y > self._Row then
        XLog.Error("[XLuckyTenantChessBoard] 设置棋子位置超出棋盘大小")
        return false
    end
    local index = self:GetIndex(x, y)
    return self:SetPieceByIndex(piece, index, x, y)
end

---@param bag XLuckyTenantBag
function XLuckyTenantChessBoard:SetTestCase(game, model, bag, testCase)
    self:ClearEveryTurn()

    local usedPiece = {}
    for i = 1, #testCase do
        local pieceId = testCase[i]
        if pieceId ~= 0 then
            local piece = bag:FindPiece(pieceId, usedPiece)
            if not piece or usedPiece[piece:GetUid()] then
                --piece = bag:NewPiece(model, pieceId)
                local isSuccess
                isSuccess, piece = game:AddNewPieceToBag(model, pieceId)
                if isSuccess then
                    XMVCA.XLuckyTenant:Print("[XLuckyTenantChessBoard] 作弊获得棋子:" .. piece:GetName())
                end
            end
            usedPiece[piece:GetUid()] = true
            local x, y = self:GetXY(i)
            self:SetPieceByPosition(piece, x, y)
        end
    end
end

---@param bag XLuckyTenantBag
function XLuckyTenantChessBoard:SetPieces(bag)
    self:ClearEveryTurn()

    local pieces = bag:GetPieces()
    local piecesToEnter1 = {}
    for i, piece in pairs(pieces) do
        piecesToEnter1[#piecesToEnter1 + 1] = piece
    end
    local piecesToEnter2 = {}
    for i = 1, self._PiecesAmount do
        local remaining = #piecesToEnter1
        if remaining > 0 then
            local index = math.random(1, remaining)
            local piece = piecesToEnter1[index]
            table.remove(piecesToEnter1, index)
            piecesToEnter2[#piecesToEnter2 + 1] = piece
        end
    end
    -- 为什么位置也要随机？ 因为希望不按顺序填充
    local posToEnter = {}
    for i = 1, self._PiecesAmount do
        posToEnter[#posToEnter + 1] = i
    end
    for i = 1, #piecesToEnter2 do
        ---@type XLuckyTenantPiece
        local piece = piecesToEnter2[i]
        local index = math.random(1, #posToEnter)
        local pos = posToEnter[index]
        table.remove(posToEnter, index)
        self._Pieces[pos] = piece
        local x, y = self:GetXY(pos)
        piece:SetPosition(x, y)
    end
    XMVCA.XLuckyTenant:Print("设置棋盘结束")
end

---@return XLuckyTenantPiece
function XLuckyTenantChessBoard:GetPieceByPosition(x, y)
    if x > self._Column then
        return false
    end
    if x < 1 then
        return false
    end
    if y > self._Row then
        return false
    end
    if y < 1 then
        return false
    end
    local index = self:GetIndex(x, y)
    return self._Pieces[index]
end

---@return XLuckyTenantPiece
function XLuckyTenantChessBoard:GetPieceByIndex(index)
    return self._Pieces[index]
end

function XLuckyTenantChessBoard:DeletePieceByUid(uid)
    for i = 1, #self._Pieces do
        local piece = self._Pieces[i]
        if piece and piece:GetUid() == uid then
            self._Pieces[i] = false
            break
        end
    end
end

function XLuckyTenantChessBoard:GetNeighbours(x, y, table)
    local grid1 = self:GetPieceByPosition(x - 1, y + 1)
    local grid2 = self:GetPieceByPosition(x, y + 1)
    local grid3 = self:GetPieceByPosition(x + 1, y + 1)
    local grid4 = self:GetPieceByPosition(x - 1, y)
    local grid5 = self:GetPieceByPosition(x + 1, y)
    local grid6 = self:GetPieceByPosition(x - 1, y - 1)
    local grid7 = self:GetPieceByPosition(x, y - 1)
    local grid8 = self:GetPieceByPosition(x + 1, y - 1)
    table[1] = grid1 or false
    table[2] = grid2 or false
    table[3] = grid3 or false
    table[4] = grid4 or false
    table[5] = grid5 or false
    table[6] = grid6 or false
    table[7] = grid7 or false
    table[8] = grid8 or false
end

function XLuckyTenantChessBoard:Delete(x, y)
    local index = self:GetIndex(x, y)
    if x > self._Column then
        XLog.Error("[XLuckyTenantChessBoard] 删除错误:" .. x, "/" .. "y")
        return
    end
    if x <= 0 then
        XLog.Error("[XLuckyTenantChessBoard] 删除错误:" .. x, "/" .. "y")
        return
    end
    if y > self._Column then
        XLog.Error("[XLuckyTenantChessBoard] 删除错误:" .. x, "/" .. "y")
        return
    end
    if y <= 0 then
        XLog.Error("[XLuckyTenantChessBoard] 删除错误:" .. x, "/" .. "y")
        return
    end
    if index > self._PiecesAmount then
        XLog.Error("[XLuckyTenantChessBoard] 删除错误:" .. x, "/" .. "y")
        return
    end
    self._Pieces[index] = false
end

---@return XLuckyTenantPiece[]
function XLuckyTenantChessBoard:GetPieces()
    return self._Pieces
end

-- 从左上角开始的数组
function XLuckyTenantChessBoard:GetPositionTranspose()
    local positions = {}
    for y = self._Row, 1, -1 do
        for x = 1, self._Column do
            local index = self:GetIndex(x, y)
            positions[#positions + 1] = index
        end
    end
    return positions
end

function XLuckyTenantChessBoard:GetColumn()
    return self._Column
end

function XLuckyTenantChessBoard:GetRow()
    return self._Row
end

function XLuckyTenantChessBoard:SetPositionScore(index, score)
    self._Score4Position[index] = score
end

function XLuckyTenantChessBoard:GetPositionScore(index)
    return self._Score4Position[index] or 0
end

-- 如果格子上的棋子被删除，或者变化成其他棋子后，它所存储的分数，设为已执行分数
function XLuckyTenantChessBoard:SetPositionScoreImplemented(index, score)
    self._Score4Position[index] = score
end

function XLuckyTenantChessBoard:AddPositionScoreImplemented(index, score)
    self._Score4Position[index] = score
end

function XLuckyTenantChessBoard:GetPositionScoreImplemented(index)
    local score1 = self._Score4Position[index] or 0
    local score2 = self._Score4PositionImplemented[index] or 0
    return score1 + score2
end

function XLuckyTenantChessBoard:AddPieceToChessBoard(piece)
    for y = self._Row, 1, -1 do
        for x = 1, self._Column do
            if not self:GetPieceByPosition(x, y) then
                self:SetPieceByPosition(piece, x, y)
                return
            end
        end
    end
end

function XLuckyTenantChessBoard:GetEncodeMessage()
    local pieces = self._Pieces
    local message = {}
    for i = 1, #pieces do
        local piece = pieces[i]
        if piece then
            message[i] = piece:GetUid()
        else
            message[i] = 0
        end
    end
    return message
end

return XLuckyTenantChessBoard