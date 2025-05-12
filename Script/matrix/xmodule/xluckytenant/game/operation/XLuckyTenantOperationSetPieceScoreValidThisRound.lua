local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XLuckyTenantOperation = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperation")

---@class XLuckyTenantOperationSetPieceScoreValidThisRound:XLuckyTenantOperation
local XLuckyTenantOperationSetPieceScoreValidThisRound = XClass(XLuckyTenantOperation, "XLuckyTenantOperationSetPieceScoreValidThisRound")

function XLuckyTenantOperationSetPieceScoreValidThisRound:Ctor()
    self._Type = XLuckyTenantEnum.Operation.Score
    self._Score = 0
    self._Uid = 0
end

function XLuckyTenantOperationSetPieceScoreValidThisRound:SetData(uid, score, skill)
    self._Uid = uid
    self._Score = score
    XMVCA.XLuckyTenant:Print("设置棋子分数：" .. score, "技能来自:", skill:GetDesc())
end

---@param animationGroup XLuckyTenantAnimationGroup
function XLuckyTenantOperationSetPieceScoreValidThisRound:Do(model, game, animationGroup)
    local piece = game:GetBag():GetPiece(self._Uid)
    if piece then
        piece:SetScoreValidThisRound(self._Score)

        animationGroup:SetAnimation({
            Type = XLuckyTenantEnum.Animation.Shake,
            Position = self._SourcePosition,
        })
        animationGroup:SetAnimation({
            Type = XLuckyTenantEnum.Animation.AddScore,
            Position = piece:GetPositionIndex(game),
            PieceUiData = piece:GetUiData(model, game)
        })

        return true
    end
    XLog.Error("[XLuckyTenantOperationSetPieceScoreValidThisRound] 设置分数失败:" .. tostring(self._Uid))
    return false
end

return XLuckyTenantOperationSetPieceScoreValidThisRound
