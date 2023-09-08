---@class XUiGridChessHead : XUiNode
---@field _Control XBlackRockChessControl
local XUiGridChessHead = XClass(XUiNode, "XUiGridChessHead")

local KingType = CS.XBlackRockChess.XChessPieceType.King:GetHashCode()

function XUiGridChessHead:OnStart()
    local parent = self.RImgHead.transform.parent
    self.EffectSmoke = parent:FindTransform("PanelEffectSmoke")
    self.EffectBlood = parent:FindTransform("PanelEffectBlood")
    self.EffectLight = parent:FindTransform("PanelEffectLight")
    
    self.EffectBlood.gameObject:SetActiveEx(false)
    self.EffectLight.gameObject:SetActiveEx(false)
end

function XUiGridChessHead:ShowChess(chessIndex)
    local config = self._Control:GetHandbookChessConfigByIndex(chessIndex)
    self.RImgHead:SetRawImage(config.HeadIcon)
    self.TxtLeftRound.text = config.Interval
    self._MaxBloodGridCount = self._Control:GetMaxBloodGridCount()
    if XTool.IsNumberValid(self._MaxBloodGridCount) then
        self.ImgHp1Bar.fillAmount = math.min(1, config.Hp / self._MaxBloodGridCount)
    end
    local showSecond = config.Hp > self._MaxBloodGridCount
    self.ImgHp1BarPreview.gameObject:SetActiveEx(false)
    self.ImgHp2BarPreview.gameObject:SetActiveEx(false)
    self.ImgHp2Bar.gameObject:SetActiveEx(showSecond)
    self.PanelDead.gameObject:SetActiveEx(false)
    self.ImgTarget.gameObject:SetActiveEx(false)
    self.PanelBuff.gameObject:SetActiveEx(false)
    self.RImgAttack.gameObject:SetActiveEx(false)

    if showSecond then
        self.ImgHp2Bar.fillAmount = math.min(1, (config.Hp - self._MaxBloodGridCount) / self._MaxBloodGridCount)
    end

    if self.EffectSmoke then
        self.EffectSmoke.gameObject:SetActiveEx(config.Type == KingType)
    end
end

return XUiGridChessHead