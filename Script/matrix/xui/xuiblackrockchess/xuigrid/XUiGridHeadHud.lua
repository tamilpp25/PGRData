
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


function XUiGridHeadHud:BindTarget(target, offset, pieceId)
    XUiGridHud.BindTarget(self, target, offset)
    self.PieceId = pieceId
end

function XUiGridHeadHud:RefreshView()
    if not self.GridHead then
        return
    end
    self.GridHead:RefreshView(self.PieceId)
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