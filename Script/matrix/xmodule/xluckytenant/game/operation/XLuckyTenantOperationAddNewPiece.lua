local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XLuckyTenantOperation = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperation")

---@class XLuckyTenantOperationAddNewPiece:XLuckyTenantOperation
local XLuckyTenantOperationAddNewPiece = XClass(XLuckyTenantOperation, "XLuckyTenantOperationAddNewPiece")

function XLuckyTenantOperationAddNewPiece:Ctor()
    self._Type = XLuckyTenantEnum.Operation.AddNewPieceToBag
    self._PieceId = 0
    self._X = false
    self._Y = false
    self._Desc = false
end

---@param proxy XLuckyTenantOperationProxy
function XLuckyTenantOperationAddNewPiece:SetData(pieceId, x, y, proxy)
    if not pieceId then
        XLog.Error("[XLuckyTenantOperationAddNewPiece] 新增棋子错误:" .. tostring(pieceId))
    end
    self._PieceId = pieceId
    self._X = x
    self._Y = y
    if proxy then
        local skill = proxy.Skill
        local piece = skill:GetPiece()
        if piece then
            local px, py = piece:GetPosition()
            self._Desc = piece:GetName() .. "(" .. px .. "," .. py .. ")" .. ":技能id:" .. skill:GetId() .. "," .. skill:GetDesc()
        else
            self._Desc = "释放者已死: 技能id:" .. skill:GetId() .. "," .. skill:GetDesc()
        end
    end
end

---@param animationGroup XLuckyTenantAnimationGroup
function XLuckyTenantOperationAddNewPiece:Do(model, game, animationGroup)
    if not self._PieceId then
        XLog.Error("[XLuckyTenantOperationAddNewPiece] 新增棋子错误:" .. tostring(self._PieceId))
        return
    end
    local isSuccess, piece = game:AddNewPieceToBag(model, self._PieceId)
    if isSuccess then
        if piece then
            piece:SetHideRound()
        end
        animationGroup:SetAnimation({
            Type = XLuckyTenantEnum.Animation.Shake,
            Position = self._SourcePosition,
        })

        if piece:IsPiece() then
            local pieceName = model:GetLuckyTenantChessNameById(self._PieceId)
            if self._X and self._Y and (not game:GetChessboard():GetPieceByPosition(self._X, self._Y)) then
                game:GetChessboard():SetPieceByPosition(piece, self._X, self._Y)
            else
                game:GetChessboard():AddPieceToChessBoard(piece)
                self._X, self._Y = piece:GetPosition()
            end
            local x, y = piece:GetPosition()
            XMVCA.XLuckyTenant:Print("生成棋子：", pieceName, "位置是(", x, y, ")技能来自:", self._Desc)

            piece:SetHideRound()
            animationGroup:SetAnimation({
                Type = XLuckyTenantEnum.Animation.AddPiece,
                Position = game:GetChessboard():GetIndex(self._X, self._Y),
                PieceUiData = piece:GetUiData(model, game),
            })
        else
            local pieceName = model:GetLuckyTenantChessNameById(self._PieceId)
            XMVCA.XLuckyTenant:Print("获得道具：", pieceName, "技能来自: ", self._Desc)
        end
    end
    return isSuccess
end

return XLuckyTenantOperationAddNewPiece
