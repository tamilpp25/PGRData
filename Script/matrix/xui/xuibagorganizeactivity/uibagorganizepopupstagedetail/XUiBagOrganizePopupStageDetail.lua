--- 关卡详情页，2.0弃用，界面逻辑相对独立，暂时不删除
---@class XUiBagOrganizePopupStageDetail: XLuaUi
---@field _Control XBagOrganizeActivityControl
local XUiBagOrganizePopupStageDetail = XLuaUiManager.Register(XLuaUi, 'UiBagOrganizePopupStageDetail')

function XUiBagOrganizePopupStageDetail:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.Close)
    self.BtnNext.CallBack = handler(self, self.OnStartClickEvent)
end

function XUiBagOrganizePopupStageDetail:OnEnable()
    self._StageId = self._Control:GetCurStageId()
    self:Refresh()
end

function XUiBagOrganizePopupStageDetail:Refresh()
    self.TxtTitle.text = self._Control:GetStageNameById(self._StageId)
    local maxScore = self._Control:GetStageMaxScoreById(self._StageId)
    
    local hasValidScore = XTool.IsNumberValid(maxScore)
    self.TxtNumScore.gameObject:SetActiveEx(hasValidScore)
    self.TxtNone.gameObject:SetActiveEx(not hasValidScore)
    
    if hasValidScore then
        self.TxtNumScore.text = XUiHelper.FormatText(self._Control:GetClientConfigText('BaseScoreLabel'), maxScore)
    end
    
end

function XUiBagOrganizePopupStageDetail:OnStartClickEvent()
    XMVCA.XBagOrganizeActivity:RequestBagOrganizeStart(self._StageId, function()
        self._Control:StartGameInit()
        self:Close()
        XLuaUiManager.Open('UiBagOrganizeGame', self._StageId)
    end)
end

return XUiBagOrganizePopupStageDetail