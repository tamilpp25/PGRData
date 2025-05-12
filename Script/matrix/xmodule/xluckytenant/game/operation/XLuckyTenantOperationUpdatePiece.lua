local XLuckyTenantEnum = require("XModule/XLuckyTenant/Game/XLuckyTenantEnum")
local XLuckyTenantOperation = require("XModule/XLuckyTenant/Game/Operation/XLuckyTenantOperation")

---@class XLuckyTenantOperationUpdatePiece:XLuckyTenantOperation
local XLuckyTenantOperationUpdatePiece = XClass(XLuckyTenantOperation, "XLuckyTenantOperationUpdatePiece")

function XLuckyTenantOperationUpdatePiece:Ctor()
    self._Type = XLuckyTenantEnum.Operation.Update
    self._PieceUid = false
    self._SkillId = 0
    self._Round = 0
end

--只更新回合数
---@param piece XLuckyTenantPiece
function XLuckyTenantOperationUpdatePiece:SetData(piece, skillId, round)
    self._PieceUid = piece:GetUid()
    self._SkillId = skillId
    self._Round = round
end

---@param animationGroup XLuckyTenantAnimationGroup
function XLuckyTenantOperationUpdatePiece:Do(model, game, animationGroup)
    if not self._PieceUid then
        XLog.Error("[XLuckyTenantOperationUpdatePiece] 更新棋子错误:" .. tostring(self._PieceUid))
        return
    end
    local piece = game:GetBag():GetPiece(self._PieceUid)
    if piece then
        local position = piece:GetPositionIndex(game)
        --local uiData = piece:GetUiData(model, game)
        -- 生效的回合, 隐藏回合数
        local round, skill = piece:GetSkillEffectRemainingTurns(model)
        if skill then
            if skill:GetId() == self._SkillId then
                if self._Round <= 0 then
                    self._Round = false
                    piece:SetHideRound()
                end

                animationGroup:SetAnimation({
                    Type = XLuckyTenantEnum.Animation.SetPiece,
                    Position = position,
                    PieceUiData = {
                        JustChangeRound = self._Round
                    }
                })
            end
        end
        return true
    end
    XMVCA.XLuckyTenant:Error("更新棋子数据失败:", self._PieceUid)
    return false
end

return XLuckyTenantOperationUpdatePiece
