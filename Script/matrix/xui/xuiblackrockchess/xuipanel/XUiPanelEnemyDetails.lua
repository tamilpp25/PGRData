
---@class XUiPanelEnemyDetails : XUiNode
---@field _Control XBlackRockChessControl
---@field GridHeadUi XUiGridHeadCommon
local XUiPanelEnemyDetails = XClass(XUiNode, "XUiPanelEnemyDetails")

function XUiPanelEnemyDetails:OnStart()
    self.GridHeadUi = self.GridHeadUi or require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHeadCommon").New(self.GridHead, self.Parent)
    --self.TxtDetails2 = self.TxtDetails2 or self.Transform:FindTransform("TxtDetails2"):GetComponent("Text")
    self.GridHeadUi.TxtDetails = self.TxtDetails
    --self.GridHeadUi.TxtDetails2 = self.TxtDetails2
    self.GridHeadUi.TxtMoveCd = self.TxtMoveCd
    self.GridHeadUi.TxtName = self.TxtName
    self:InitCb()
end

function XUiPanelEnemyDetails:OnEnable()
    if self.GridHeadUi then
        self.GridHeadUi:Open()
    end
end

function XUiPanelEnemyDetails:OnDisable()
    if self.GridHeadUi then
        self.GridHeadUi:Close()
    end
end

function XUiPanelEnemyDetails:RefreshView(pieceId)
    if not self.GridHeadUi then
        return
    end
    self.PieceId = pieceId or self.PieceId
    if not XTool.IsNumberValid(self.PieceId) then
        self:Close()
        return
    end
    self.GridHeadUi:RefreshView(self.PieceId)
end

function XUiPanelEnemyDetails:InitCb()
    self.BtnClose.CallBack = function() 
        self:Close()
    end
end

return XUiPanelEnemyDetails