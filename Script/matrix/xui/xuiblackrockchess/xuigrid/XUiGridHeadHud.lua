
local XUiGridHud = require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHud")
---@class XUiGridHeadHud : XUiGridHud 3D头像
---@field GridHead XUiGridHeadCommon
local XUiGridHeadHud = XClass(XUiGridHud, "XUiGridHeadHud")

function XUiGridHeadHud:OnStart()
    self.GridHead = self.GridHead or require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHeadCommon").New(self.Transform, self.Parent)
    self:SetScale(CS.XBlackRockChess.XBlackRockChessManager.Instance:GetDistanceRatio())
end

function XUiGridHeadHud:OnDisable()
    if self.GridHead then
        self.GridHead:Close()
    end
end

function XUiGridHeadHud:BindTarget(target, offset, pieceId, bossId, pieceType)
    XUiGridHud.BindTarget(self, target, offset)
    self.PieceId = pieceId
    self.BossId = bossId

    if XTool.IsNumberValid(pieceId) then
        if pieceType == 1 then
            self._PieceType = XEnumConst.BLACK_ROCK_CHESS.PIECE_TYPE.PARTNER
        else
            self._PieceType = XEnumConst.BLACK_ROCK_CHESS.PIECE_TYPE.ENEMY
        end
        self.GridHead:SetPieceType(self._PieceType)
    end
end

function XUiGridHeadHud:RefreshView()
    if not self.GridHead then
        return
    end
    if self.PieceId then
        if self._PieceType == XEnumConst.BLACK_ROCK_CHESS.PIECE_TYPE.PARTNER then
            self.GridHead:RefreshPartnerPrepareView(self.PieceId)
        else
            self.GridHead:RefreshView(self.PieceId)
        end
        self.GameObject.name = string.format("Piece_%s", self.PieceId)
    end
    if self.BossId then
        self.GridHead:RefreshBossView(self.BossId)
        self.GameObject.name = string.format("Boss_%s", self.BossId)
    end
end

function XUiGridHeadHud:SetTarget(state)
    if not self.GridHead then
        return
    end
    self.GridHead:SetTarget(state)
end

function XUiGridHeadHud:PreviewDamage(damage)
    if not self.GridHead then
        return
    end
    self.GridHead:PreviewDamage(damage)
end

return XUiGridHeadHud