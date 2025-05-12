local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XLuckyTenantOperation = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperation")

---@class XLuckyTenantOperationDeletePiece:XLuckyTenantOperation
local XLuckyTenantOperationDeletePiece = XClass(XLuckyTenantOperation, "XLuckyTenantOperationDeletePiece")

function XLuckyTenantOperationDeletePiece:Ctor()
    self._Type = XLuckyTenantEnum.Operation.DeletePiece
    self._X = 0
    self._Y = 0
    self._From = 0
    self._FromUid = 0
    self._To = 0
    self._Desc = false
end

---@param skill XLuckyTenantChessSkill
---@param pieceToDelete XLuckyTenantPiece
---@param from XLuckyTenantPiece
function XLuckyTenantOperationDeletePiece:SetData(x, y, from, skill, pieceToDelete, sourcePosition)
    self._X = x
    self._Y = y
    local piece = skill:GetPiece()
    self._From = from:GetId()
    self._FromUid = from:GetUid()
    if sourcePosition then
        self._SourcePosition = sourcePosition
    end
    self._To = pieceToDelete:GetId()
    local desc = from:GetName() .. "," .. skill:GetDesc()
    self._Desc = desc
    XMVCA.XLuckyTenant:Print("消除棋子:", pieceToDelete:GetName(), string.format("他的位置是(%s,%s)", self._X, self._Y), "分数是：", piece:GetValueIncludingTemp() + piece:GetValueUponDeletion(), ", 技能来自:", desc)
end

---@param animationGroup XLuckyTenantAnimationGroup
---@param proxy XLuckyTenantOperationProxy
function XLuckyTenantOperationDeletePiece:Do(model, game, animationGroup, proxy)
    local piece = game:GetChessboard():GetPieceByPosition(self._X, self._Y)
    if piece then
        local position1 = self._SourcePosition
        animationGroup:SetAnimation({
            Type = XLuckyTenantEnum.Animation.Shake,
            Position = position1,
        })
        local position2 = piece:GetPositionIndex(game)
        if position1 ~= position2 then
            animationGroup:SetAnimation({
                Type = XLuckyTenantEnum.Animation.Shake,
                Position = position2,
            })
        end

        local value = piece:GetValueIncludingTemp() + piece:GetValueUponDeletion()
        animationGroup:SetAnimation({
            Type = XLuckyTenantEnum.Animation.GetScore,
            Position = piece:GetPositionIndex(game),
            Value = value,
        })
        animationGroup:SetAnimation({
            Type = XLuckyTenantEnum.Animation.DeletePiece,
            Position = piece:GetPositionIndex(game),
        })

        -- 从棋盘上删除, 但是背包里保留, 直至运算结束
        game:DeletePieceOnChessboard(self._X, self._Y)
        proxy:AddToDelete(piece)

        local score = game:GetScoreThisRound()
        game:SetScoreThisRound(score + value)
    end
    return true
end

function XLuckyTenantOperationDeletePiece:GetFrom()
    return self._From
end

function XLuckyTenantOperationDeletePiece:GetTo()
    return self._To
end

function XLuckyTenantOperationDeletePiece:GetFromUid()
    return self._FromUid
end

return XLuckyTenantOperationDeletePiece
