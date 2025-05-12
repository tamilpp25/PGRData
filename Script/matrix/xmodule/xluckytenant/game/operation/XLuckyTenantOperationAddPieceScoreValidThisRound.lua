local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XLuckyTenantOperation = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperation")

---@class XLuckyTenantOperationAddPieceScoreValidThisRound:XLuckyTenantOperation
local XLuckyTenantOperationAddPieceScoreValidThisRound = XClass(XLuckyTenantOperation, "XLuckyTenantOperationAddPieceScoreValidThisRound")

function XLuckyTenantOperationAddPieceScoreValidThisRound:Ctor()
    self._Type = XLuckyTenantEnum.Operation.Score
    self._Score = 0
    self._Uid = 0
end

function XLuckyTenantOperationAddPieceScoreValidThisRound:SetData(uid, score)
    self._Uid = uid
    self._Score = score
end

---@param animationGroup XLuckyTenantAnimationGroup
function XLuckyTenantOperationAddPieceScoreValidThisRound:Do(model, game, animationGroup)
    local piece = game:GetBag():GetPiece(self._Uid)
    if piece then
        piece:AddScoreValidThisRound(self._Score)

        animationGroup:SetAnimation({
            Type = XLuckyTenantEnum.Animation.Shake,
            Position = self._SourcePosition,
        })
        animationGroup:SetAnimation({
            Type = XLuckyTenantEnum.Animation.Shake,
            Position = piece:GetPositionIndex(game),
        })
        animationGroup:SetAnimation({
            Type = XLuckyTenantEnum.Animation.AddScore,
            Position = piece:GetPositionIndex(game),
            PieceUiData = piece:GetUiData(model, game)
        })
        return true
    end
    XLog.Error("[XLuckyTenantOperationAddPieceScoreValidThisRound] 设置分数失败:" .. tostring(self._Uid))
    return false
end

return XLuckyTenantOperationAddPieceScoreValidThisRound
