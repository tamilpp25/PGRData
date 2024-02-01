---@class XUiGridFangKuaiChapter : XUiNode
---@field Parent XUiFangKuaiMain
---@field _Control XFangKuaiControl
local XUiGridFangKuaiChapter = XClass(XUiNode, "XUiGridFangKuaiChapter")

function XUiGridFangKuaiChapter:OnStart()
    XUiHelper.RegisterClickEvent(self, self.GridChapter, self.OnClickChapter)
    XUiHelper.RegisterClickEvent(self, self.BtnAbandon, self.OnClickAbandon)
end

---@param stageConfig XTableFangKuaiStage
function XUiGridFangKuaiChapter:Update(stageConfig)
    self._StageId = stageConfig.Id
    self._IsPlaying = self._Control:IsStagePlaying(self._StageId)
    self._IsUnlock, self._CondStr = self._Control:IsStageTimeUnlock(self._StageId)
    if self._IsUnlock then
        self._IsUnlock, self._CondStr = self._Control:IsPreStagePass(self._StageId)
    end

    local score = self._Control:GetStageRecordScore(self._StageId)
    if XTool.IsNumberValid(score) and not self._IsPlaying and self._IsUnlock then
        self.PanelScore.gameObject:SetActiveEx(true)
        local gradeIcon = self._Control:GetStageRankIcon(self._StageId, score)
        self.RImgRankA:SetRawImage(gradeIcon)
        self.TxtScore.text = score
    else
        self.PanelScore.gameObject:SetActiveEx(false)
    end

    self.GridChapter:SetRawImage(stageConfig.Icon)
    self.GridChapter:SetButtonState(self._IsUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.TxtCondition.text = XUiHelper.GetText("FangKuaiStageCondition", self._CondStr)

    self.PanelOngoing.gameObject:SetActiveEx(self._IsPlaying)
    self.Effect.gameObject:SetActiveEx(self._IsPlaying)
    self.TxtName.text = (self._IsPlaying or not self._IsUnlock) and "" or stageConfig.Name

    local isRed = self._Control:CheckStageRedPoint(self._StageId)
    self.GridChapter:ShowReddot(isRed)
end

function XUiGridFangKuaiChapter:OnClickChapter()
    if not self._IsUnlock then
        XUiManager.TipError(XUiHelper.GetText("FangKuaiStageCondition2", self._CondStr))
        return
    end
    if self._IsPlaying then
        self._Control:RecordStage(XEnumConst.FangKuai.RecordUiType.Main, XEnumConst.FangKuai.RecordButtonType.Continue, self._StageId)
        self._Control:EnterGame(self._StageId)
        return
    end
    if self._Control:IsOtherPlaying(self._StageId) then
        XUiManager.TipError(XUiHelper.GetText("FangKuaiOtherPlaying"))
        return
    end
    XLuaUiManager.Open("UiFangKuaiChapterDetail", self._StageId)
end

function XUiGridFangKuaiChapter:OnClickAbandon()
    self._Control:OpenTip(nil, XUiHelper.GetText("FangKuaiAbandonTip"), function()
        self._Control:RecordStage(XEnumConst.FangKuai.RecordUiType.Main, XEnumConst.FangKuai.RecordButtonType.GiveUp, self._StageId)
        self._Control:FangKuaiStageSettleRequest(self._StageId, function()
            self.Parent:UpdateChapter()
        end)
    end)
end

return XUiGridFangKuaiChapter