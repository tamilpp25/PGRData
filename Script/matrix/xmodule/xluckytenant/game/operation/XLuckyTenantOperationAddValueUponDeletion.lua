local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XLuckyTenantOperation = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperation")

---@class XLuckyTenantOperationAddValueUponDeletion:XLuckyTenantOperation
local XLuckyTenantOperationAddValueUponDeletion = XClass(XLuckyTenantOperation, "XLuckyTenantOperationAddValueUponDeletion")

function XLuckyTenantOperationAddValueUponDeletion:Ctor()
    self._Type = XLuckyTenantEnum.Operation.SetValueUponDeletion
    self._PieceUid = 0
    self._Value = 0
end

---@param piece XLuckyTenantPiece
function XLuckyTenantOperationAddValueUponDeletion:SetData(piece, value)
    self._PieceUid = piece:GetUid()
    self._Value = value
    XMVCA.XLuckyTenant:Print("设置消除分:", piece:GetName(), value)
end

---@param animationGroup XLuckyTenantAnimationGroup
function XLuckyTenantOperationAddValueUponDeletion:Do(model, game, animationGroup)
    local piece = game:GetBag():GetPiece(self._PieceUid)
    if piece then
        piece:SetValueUponDeletion(piece:GetValueUponDeletion() + self._Value)
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
end

return XLuckyTenantOperationAddValueUponDeletion
