local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XLuckyTenantOperation = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperation")

---@class XLuckyTenantOperationTransformPiece:XLuckyTenantOperation
local XLuckyTenantOperationTransformPiece = XClass(XLuckyTenantOperation, "XLuckyTenantOperationTransformPiece")

function XLuckyTenantOperationTransformPiece:Ctor()
    self._Type = XLuckyTenantEnum.Operation.TransformPiece
    self._PieceUid = 0
    self._PieceIdToTransform = 0
end

function XLuckyTenantOperationTransformPiece:SetData(uid, pieceIdToTransform)
    self._PieceUid = uid
    self._PieceIdToTransform = pieceIdToTransform
end

---@param animationGroup XLuckyTenantAnimationGroup
function XLuckyTenantOperationTransformPiece:Do(model, game, animationGroup)
    local bag = game:GetBag()
    local piece = bag:GetPiece(self._PieceUid)
    if not piece then
        XMVCA.XLuckyTenant:Print("[XLuckyTenantOperationTransformPiece] 要变形的棋子已经不存在了:" .. tostring(self._PieceUid))
        return false
    end
    local config = model:GetLuckyTenantChessConfigById(self._PieceIdToTransform)
    if not config then
        XMVCA.XLuckyTenant:Print("[XLuckyTenantOperationTransformPiece] 要变形的棋子配置不存在" .. tostring(self._PieceIdToTransform))
        return
    end
    piece:SetConfigButRetainPositionAndUid(config)

    animationGroup:SetAnimation({
        Type = XLuckyTenantEnum.Animation.Shake,
        Position = self._SourcePosition,
    })
    animationGroup:SetAnimation({
        Type = XLuckyTenantEnum.Animation.SetPiece,
        Position = piece:GetPositionIndex(game),
        PieceUiData = piece:GetUiData(model, game)
    })

    return true
end

return XLuckyTenantOperationTransformPiece
