---@class XUiBagOrganizePopupSettlement:XLuaUi
---@field _Control XBagOrganizeActivityControl
---@field _GameControl XBagOrganizeActivityGameControl
local XUiBagOrganizePopupSettlement = XLuaUiManager.Register(XLuaUi, 'UiBagOrganizePopupSettlement')

function XUiBagOrganizePopupSettlement:OnAwake()
    self.BtnLeave.CallBack = handler(self, self.ReturnToStage)
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.ReturnToStage)
    self.BtnNext.CallBack = handler(self, self.NextStage)
end

function XUiBagOrganizePopupSettlement:OnStart(stageId, totalScore, settleData)
    self._StageId = stageId
    self._SettleData = settleData
    self._CurTotalScore = totalScore
    self._GameControl = self._Control:GetGameControl()
    self:Refresh()
end

function XUiBagOrganizePopupSettlement:Refresh()
    -- 判断当前章节是否有下一关
    self._HasNextStage, self._NextStageId = self._Control:CheckHasNextStage()
    self.BtnNext.gameObject:SetActiveEx(self._HasNextStage)
    -- 刷新分数
    self.TxtScore.text = XUiHelper.FormatText(self._Control:GetClientConfigText('BaseScoreLabel'), self._CurTotalScore)
    self.TagNew.gameObject:SetActiveEx(self._SettleData.IsNewRecord)
    -- 显示评级
    local iconUrl = self._Control:GetScoreLevelIconByStageIdAndScore(self._StageId, self._CurTotalScore)
    self.RankRImg:SetRawImage(iconUrl)
end

function XUiBagOrganizePopupSettlement:ReturnToStage()
    self:Close()
    self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_END_GAME)
end

function XUiBagOrganizePopupSettlement:NextStage()
    XMVCA.XBagOrganizeActivity:RequestBagOrganizeStart(self._NextStageId, function()
        self._Control:SetCurStageId(self._NextStageId)
        self._GameControl:DispatchEvent(XMVCA.XBagOrganizeActivity.EventIds.EVENT_NEXT_STAGE_GAME)
        self:Close()
    end)
end

return XUiBagOrganizePopupSettlement