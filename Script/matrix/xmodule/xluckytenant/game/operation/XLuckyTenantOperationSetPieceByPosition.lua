local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XLuckyTenantOperation = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperation")

---@class XLuckyTenantOperationSetPieceByPosition:XLuckyTenantOperation
local XLuckyTenantOperationSetPieceByPosition = XClass(XLuckyTenantOperation, "XLuckyTenantOperationSetPieceByPosition")

function XLuckyTenantOperationSetPieceByPosition:Ctor()
    self._Type = XLuckyTenantEnum.Operation.SetPieceByPosition
    self._X = 0
    self._Y = 0
    self._UidOnBag = 0
end

function XLuckyTenantOperationSetPieceByPosition:SetData(x, y, uidOnBag)
    self._X = x
    self._Y = y
    self._UidOnBag = uidOnBag
end

---@param animationGroup XLuckyTenantAnimationGroup
function XLuckyTenantOperationSetPieceByPosition:Do(model, game, animationGroup)
    local bag = game:GetBag()
    local pieceOnBag = bag:GetPiece(self._UidOnBag)
    if not pieceOnBag then
        XLog.Error("[XLuckyTenantOperationSetPieceByPosition] 替换：包里没找到对应的棋子")
        return false
    end
    local chessboard = game:GetChessboard()
    local isSuccess = chessboard:SetPieceByPosition(pieceOnBag, self._X, self._Y)

    if isSuccess then
        animationGroup:SetAnimation({
            Type = XLuckyTenantEnum.Animation.Shake,
            Position = self._SourcePosition,
        })
        animationGroup:SetAnimation({
            Type = XLuckyTenantEnum.Animation.AddPiece,
            Position = game:GetChessboard():GetIndex(pieceOnBag:GetPosition()),
        })
        --animationGroup:SetAnimation({
        --    Type = XLuckyTenantEnum.Animation.Shake,
        --    Position = game:GetChessboard():GetIndex(pieceOnBag:GetPosition()),
        --}, 1)
    end

    return isSuccess
end

return XLuckyTenantOperationSetPieceByPosition
