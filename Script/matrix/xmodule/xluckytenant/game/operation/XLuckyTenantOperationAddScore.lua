local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XLuckyTenantOperation = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperation")

---@class XLuckyTenantOperationAddScore:XLuckyTenantOperation
local XLuckyTenantOperationAddScore = XClass(XLuckyTenantOperation, "XLuckyTenantOperationAddScore")

function XLuckyTenantOperationAddScore:Ctor()
    self._Type = XLuckyTenantEnum.Operation.Score
    self._Score = 0
    self._X = 0
    self._Y = 0
end

function XLuckyTenantOperationAddScore:SetData(x, y, score)
    -- 纪录坐标，播放动画时使用
    self._X = x
    self._Y = y
    self._Score = score
end

---@param animationGroup XLuckyTenantAnimationGroup
function XLuckyTenantOperationAddScore:Do(model, game, animationGroup)
    game:SetScoreThisRound(game:GetScoreThisRound() + self._Score)

    if self._X and self._Y then
        self._SourcePosition = game:GetChessboard():GetIndex(self._X, self._Y)
    end
    animationGroup:SetAnimation({
        Type = XLuckyTenantEnum.Animation.Shake,
        Position = self._SourcePosition,
    })
    animationGroup:SetAnimation({
        Type = XLuckyTenantEnum.Animation.GetScore,
        Position = self._SourcePosition,
        Value = self._Score
    })

    return true
end

return XLuckyTenantOperationAddScore
