---@class XBlackRockChessPreparePiece : XEntity 友军布阵棋子
---@field _OwnControl XBlackRockChessControl 控制器
local XBlackRockChessPreparePiece = XClass(XEntity, "XBlackRockChessPreparePiece")

local XBlackRockChessManager = CS.XBlackRockChess.XBlackRockChessManager.Instance

function XBlackRockChessPreparePiece:OnInit(pieceId, configId)
    self._Id = pieceId
    self._ConfigId = configId
    self._PieceType = XEnumConst.BLACK_ROCK_CHESS.PIECE_TYPE.PARTNER
end

function XBlackRockChessPreparePiece:InitData(x, y, pieceState)
    self:SetPieceState(pieceState)
    if not self._Imp then
        local isAttack = function()
            return self:IsAttackAble()
        end
        self._Imp = XBlackRockChessManager:AddPartnerPiece(self._ConfigId, x, y)
        self._Imp.Id = self._Id
        self._Imp:RegisterLuaCallBack(handler(self, self.OnClick), handler(self, self.PrepareAttack), isAttack, handler(self, self.OnMoveEnd))
    end
end

function XBlackRockChessPreparePiece:SetPieceState(pieceState)
    self._PieceState = pieceState
end

function XBlackRockChessPreparePiece:IsAttackAble()
    return false
end

function XBlackRockChessPreparePiece:OnClick(isPreview)
    self:UpdatePieceTip(true)
end

function XBlackRockChessPreparePiece:UpdatePieceTip(isOpen)
    local isShowDown = self._PieceState == XEnumConst.BLACK_ROCK_CHESS.PARTNER_PIECE_STATE.GOINTO_BATTLE
     self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SELECT_PARTNER, self._ConfigId, self._Id, isShowDown, isOpen)
end

function XBlackRockChessPreparePiece:PrepareAttack(isAttack)

end

function XBlackRockChessPreparePiece:OnMoveEnd(col, row, isManual)
    self._OwnControl:PlaySound(XEnumConst.BLACK_ROCK_CHESS.CUE_ID.PIECE_MOVED)
    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_EXIT_MOVE)
end

function XBlackRockChessPreparePiece:UpdateHUD()
    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_PARTNER_HEAD_HUD, self._Id, self:GetIconFollow())
end

function XBlackRockChessPreparePiece:SwitchToSite(x, y)
    self._X = x
    self._Y = y
    self._PieceState = XEnumConst.BLACK_ROCK_CHESS.PARTNER_PIECE_STATE.SITE
    self:UpdatePieceTip()
end

function XBlackRockChessPreparePiece:SwitchToBattle(x, y)
    self._X = x
    self._Y = y
    self._PieceState = XEnumConst.BLACK_ROCK_CHESS.PARTNER_PIECE_STATE.GOINTO_BATTLE
    self:UpdatePieceTip()
end

function XBlackRockChessPreparePiece:GetIconFollow()
    if not self._Imp then
        return
    end
    return self._Imp.transform
end

function XBlackRockChessPreparePiece:GetConfigId()
    return self._ConfigId
end

function XBlackRockChessPreparePiece:GetId()
    return self._Id
end

function XBlackRockChessPreparePiece:GetMovedPoint()
    if not self._Imp then
        return CS.UnityEngine.Vector2Int.zero
    end
    return self._Imp.MovedPoint
end

function XBlackRockChessPreparePiece:LoadClashEffect()
    self._OwnControl:LoadClashEffect(self._Imp, self._ConfigId)
end

function XBlackRockChessPreparePiece:HideClashEffect()
    self._OwnControl:HideClashEffect(self._Imp, self._ConfigId)
end

function XBlackRockChessPreparePiece:OnRelease()
    XBlackRockChessManager:RemovePiece(self._Imp.MovedPoint, false)
    self._Imp:Destroy()
    self.Super.OnRelease(self)
end

return XBlackRockChessPreparePiece