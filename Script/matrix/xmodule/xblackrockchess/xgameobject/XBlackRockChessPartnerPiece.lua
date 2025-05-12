local XBlackRockChessPiece = require("XModule/XBlackRockChess/XGameObject/XBlackRockChessPiece")

---@class XBlackRockChessPartnerPiece : XBlackRockChessPiece 友军棋子
local XBlackRockChessPartnerPiece = XClass(XBlackRockChessPiece, "XBlackRockChessPiece")

function XBlackRockChessPartnerPiece:SetImp(imp, isEnterFight)
    self._Imp = imp
    self._Imp.Id = self._Id
    self._Imp:UpdateData(self._AttackedTimes)
    self:ApplyBuff()
    local isAttack = function()
        return self:IsAttackAble()
    end
    self._Imp:RegisterLuaCallBack(handler(self, self.OnClick), handler(self, self.PrepareAttack), isAttack, handler(self, self.OnMoveEnd))
    self._Imp:InitAnimator(self._OwnControl:GetPieceController())
    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_PARTNER_HEAD_HUD, self._Id, self:GetIconFollow())
end

function XBlackRockChessPartnerPiece:UpdatePreview()
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    if self:IsPartnerPreview() then
        self._OwnControl:LoadVirtualEffect(self._Imp, self._ConfigId)
        CS.XBlackRockChess.XBlackRockChessManager.Instance:PartnerPiece2Virtual(self._Imp)
    else
        self._OwnControl:HideVirtualEffect(self._Imp, self._ConfigId)
        CS.XBlackRockChess.XBlackRockChessManager.Instance:PartnerVirtual2Piece(self._Imp)
    end
end

function XBlackRockChessPartnerPiece:IsAttackAble()
    if not self:IsPartner() or self:IsPartnerPreview() then
        return false
    end
    if not self:IsAlive() then -- 是否存活
        return false
    end
    if self:IsDizzy() then -- 是否眩晕
        return false
    end
    if self:IsPossessed() then -- 是否被附身
        return false
    end
    return true
end

--- 是否能攻击该敌方棋子（为false则一定不攻击）
---@param piece XBlackRockChessPiece
function XBlackRockChessPartnerPiece:CheckAttack(piece)
    if not self._Imp then
        return false
    end
    -- 我方棋子是不是能发起攻击
    if not self:IsAttackAble() then
        return false
    end
    -- 敌方棋子是否在攻击范围内
    if not self._Imp:CheckAttack(piece:GetCurrentPoint()) then
        return false
    end
    return true
end

--- 是否愿意攻击该敌方棋子（没有退路时会攻击）
---@param piece XBlackRockChessPiece
function XBlackRockChessPartnerPiece:IsWillingAttack(piece)
    -- 敌方是否有特殊buff
    local avoidBuffIds = self:GetAvoidBuff()
    for _, buffId in pairs(avoidBuffIds) do
        if piece:IsExistBuff(buffId) then
            return false
        end
    end
    if self:GetPieceType() == XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.PAWN then
        return true
    end
    -- 我方血量是否比敌方高
    return self:GetHp() + self:GetAtkLift() >= piece:GetHp()
end

function XBlackRockChessPartnerPiece:GetAvoidBuff()
    return self._OwnControl:GetPartnerPieceById(self._ConfigId).AvoidBuffIds
end

function XBlackRockChessPartnerPiece:GetAtkLift()
    return self._OwnControl:GetPartnerPieceById(self._ConfigId).AtkLife
end

function XBlackRockChessPartnerPiece:GetLiveCd()
    return self._LiveCd
end

--- 找到一个不会被攻击的格子（有血量判定）
function XBlackRockChessPartnerPiece:SearchPartnerSaftPoint()
    return self._Imp:SearchPartnerSaftPoint()
end

function XBlackRockChessPartnerPiece:SearchPartnerByPoint(point)
    return self._Imp:SearchPartnerByPoint(point)
end

--- 是否被附身
function XBlackRockChessPartnerPiece:IsPossessed()
    local actor = self._OwnControl:GetMasterRole()
    if actor then
        local actorPoint = actor:GetMovedPoint()
        local piecePoint = self:GetMovedPoint()
        return actorPoint.x == piecePoint.x and actorPoint.y == piecePoint.y
    end
    return false
end

function XBlackRockChessPartnerPiece:SetPossessed(bo)
    if XTool.UObjIsNil(self._Imp) then
        return
    end
    self._Imp:SetPossessed(bo)
end

---获取友方提供的融合buff
function XBlackRockChessPartnerPiece:GetBlendBuffIds()
    return self._OwnControl:GetPartnerPieceById(self._ConfigId).CharacterBuffIds
end

--- 能否升变
function XBlackRockChessPartnerPiece:IsPromotion()
    if not self._Imp then
        return false
    end
    local chessType = self._OwnControl:GetPartnerPieceById(self._ConfigId).Type
    if chessType ~= XEnumConst.BLACK_ROCK_CHESS.CHESS_TYPE.PAWN then
        return false
    end
    return self._Imp:IsReachBottom() and not XTool.IsTableEmpty(self._OwnControl:GetPromotionPartnerPieceIds(self._ConfigId))
end

-- 升变
function XBlackRockChessPartnerPiece:Promotion()
    local pieceIds = self._OwnControl:GetPromotionPartnerPieceIds(self._ConfigId)
    local pieceId = pieceIds[math.random(1, #pieceIds)]
    local movedPoint = self:GetMovedPoint()
    local x, y = movedPoint.x, movedPoint.y
    --移除旧棋子
    self._Imp:Destroy()
    --添加新棋子
    local imp = CS.XBlackRockChess.XBlackRockChessManager.Instance:AddPartnerPiece(pieceId, x, y)
    self._OldConfigId = self._ConfigId
    self._ConfigId = pieceId
    self._IsPromotion = true
    self:SetImp(imp)

    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_PARTNER_HEAD_HUD, self._Id, self:GetIconFollow())
end

---敌方棋子转变为友方临时棋子
---@param liveCd number 存活时间
function XBlackRockChessPartnerPiece:TransformPiece(imp, liveCd, hp)
    self._X = imp.MovedPoint.x
    self._Y = imp.MovedPoint.y
    self._MemberType = XEnumConst.BLACK_ROCK_CHESS.CHESS_MEMBER_TYPE.PARTNERPIECE
    self._MoveCd = self._OwnControl:GetPartnerPieceMoveCd(self._ConfigId)
    self:SetHp(hp)
    self._ExtraMaxLife = hp -- 临时友方棋子比较特殊 血量都是别人的 本身没有
    self._AttackedTimes = 0
    self._ReinforceId = 0
    self._ConfigId = imp.ConfigId
    self._LiveCd = liveCd
    self._IsTemp = true
    self:SetImp(imp)
    self._Imp:UpdateData(self._AttackedTimes)
    self._OwnControl:GetChessEnemy():ProcessPieceEffect()
    self._OwnControl:DispatchEvent(XEventId.EVENT_BLACK_ROCK_CHESS_SHOW_PARTNER_HEAD_HUD, self._Id, self:GetIconFollow())
end

return XBlackRockChessPartnerPiece