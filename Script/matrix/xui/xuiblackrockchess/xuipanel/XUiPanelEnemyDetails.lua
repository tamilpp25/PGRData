
---@class XUiPanelEnemyDetails : XUiNode
---@field _Control XBlackRockChessControl
---@field GridHeadUi XUiGridHeadCommon
local XUiPanelEnemyDetails = XClass(XUiNode, "XUiPanelEnemyDetails")

function XUiPanelEnemyDetails:OnStart()
    self.GridHeadUi = self.GridHeadUi or require("XUi/XUiBlackRockChess/XUiGrid/XUiGridHeadCommon").New(self.GridHead, self.Parent)
    self.GridHeadUi.TxtDetails = self.TxtDetails
    self.GridHeadUi.TxtMoveCd = self.TxtMoveCd
    self.GridHeadUi.TxtName = self.TxtName
    self.GridHeadUi.TxtUnknown = self.TxtUnknown
    self.GridHeadUi.RImgBuff = self.RImgBuff
    self.GridHeadUi.RImgMove = self.RImgMove
    self.GridHeadUi.ImgTarget = self.ImgTarget
    self.GridHeadUi.PanelBuff = self.PanelBuff
    self.GridHeadUi.TxtHp = self.TxtHp
    self.GridHeadUi.ImgStar = self.ImgStar
    self:InitCb()
end

function XUiPanelEnemyDetails:OnEnable()
    if self.GridHeadUi then
        self.GridHeadUi:Open()
    end
    self._Control:SetEnemySelect(true)
end

function XUiPanelEnemyDetails:OnDisable()
    if self.GridHeadUi then
        self.GridHeadUi:Close()
    end
    self._Control:SetEnemySelect(false)
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
        --self:Close()
        self:OnBtnCloseClick()
    end
end

function XUiPanelEnemyDetails:OnBtnCloseClick()
    local pieceInfo = self._Control:GetChessEnemy():GetPieceInfo(self.PieceId)
    pieceInfo:GetImp():OnClick()
end


return XUiPanelEnemyDetails