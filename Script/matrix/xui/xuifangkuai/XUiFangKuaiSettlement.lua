---@class XUiFangKuaiSettlement : XLuaUi 结算弹框
---@field _Control XFangKuaiControl
local XUiFangKuaiSettlement = XLuaUiManager.Register(XLuaUi, "UiFangKuaiSettlement")

function XUiFangKuaiSettlement:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.OnClickBack)
    self:RegisterClickEvent(self.BtnBack, self.OnClickBack)
    self:RegisterClickEvent(self.BtnRePlay, self.OnClickRePlay)
end

function XUiFangKuaiSettlement:OnStart(stageId, closeCallBack, restartCallBack)
    local settleData = self._Control:GetCurStageSettleData()
    local maxRound = self._Control:GetStageConfig(stageId).MaxRound
    local isNormal = self._Control:IsStageNormal(stageId)
    self.TxtDamage.text = settleData.Point
    self.RankIcon:SetRawImage(self._Control:GetStageRankIcon(stageId, settleData.Point))
    self.NewRecord.gameObject:SetActiveEx(settleData.IsNewRecord)
    self.BtnRePlay.gameObject:SetActiveEx(XLuaUiManager.IsUiShow("UiFangKuaiFight"))
    self.TxtRound.text = settleData.Round
    self.TxtRankMax.gameObject:SetActiveEx(not isNormal and settleData.Round >= maxRound)
    self._CloseCallBack = closeCallBack
    self._RestartCallBack = restartCallBack
end

function XUiFangKuaiSettlement:OnClickRePlay()
    self:Close()
    if self._RestartCallBack then
        self._RestartCallBack()
    end
end

function XUiFangKuaiSettlement:OnClickBack()
    self:Close()
    if self._CloseCallBack then
        self._CloseCallBack()
    end
end

return XUiFangKuaiSettlement