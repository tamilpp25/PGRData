---@class XUiGridFangKuaiStageGroup : XUiNode
---@field Parent XUiFangKuaiChapter
---@field _Control XFangKuaiControl
local XUiGridFangKuaiStageGroup = XClass(XUiNode, "XUiGridFangKuaiStageGroup")

function XUiGridFangKuaiStageGroup:OnStart(stageGroupId, chapterId)
    self._ChapterId = chapterId
    self._StageGroup = self._Control:GetStageGroupConfig(stageGroupId)
    self._SimpleColor = self._Control:GetClientConfig("SimpleStageScoreColor")
    self._DiffcultColor = self._Control:GetClientConfig("DiffcultStageScoreColor")

    self.GridChapter.CallBack = handler(self, self.OnClickChapter)
    self.BtnAbandon.CallBack = handler(self, self.OnClickAbandon)
end

function XUiGridFangKuaiStageGroup:Update()
    self._PlayingStageId = nil
    if self._Control:IsStagePlaying(self._StageGroup.SimpleStageId) then
        self._PlayingStageId = self._StageGroup.SimpleStageId
    elseif self._Control:IsStagePlaying(self._StageGroup.DiffcultStageId) then
        self._PlayingStageId = self._StageGroup.DiffcultStageId
    end

    self._IsPlaying = XTool.IsNumberValid(self._PlayingStageId)
    self._IsUnlock, self._CondStr = self._Control:IsStageGroupTimeUnlock(self._StageGroup.Id)
    if self._IsUnlock then
        if XTool.IsNumberValid(self._StageGroup.SimpleStageId) then
            self._IsUnlock, self._CondStr = self._Control:IsPreStagePass(self._StageGroup.SimpleStageId)
        elseif XTool.IsNumberValid(self._StageGroup.DiffcultStageId) then
            self._IsUnlock, self._CondStr = self._Control:IsPreStagePass(self._StageGroup.DiffcultStageId)
        end
    end

    local simpleScore = self._Control:GetMaxScore(self._StageGroup.SimpleStageId)
    local simpleRound = self._Control:GetMaxRound(self._StageGroup.SimpleStageId)
    local diffcultScore = self._Control:GetMaxScore(self._StageGroup.DiffcultStageId)
    local diffcultRound = self._Control:GetMaxRound(self._StageGroup.DiffcultStageId)
    local score = math.max(simpleScore, diffcultScore)
    local isSimpleStage = simpleScore > diffcultScore
    if XTool.IsNumberValid(score) and not self._IsPlaying and self._IsUnlock then
        self.PanelScore.gameObject:SetActiveEx(true)
        local gradeIcon = self._Control:GetStageRankIcon(isSimpleStage and self._StageGroup.SimpleStageId or self._StageGroup.DiffcultStageId, score)
        self.RImgRankA:SetRawImage(gradeIcon)
        self.TxtScore.text = string.format("<color=%s>%s</color>", isSimpleStage and self._SimpleColor or self._DiffcultColor, score)
        self.TxtRound.text = math.max(simpleRound, diffcultRound)
    else
        self.PanelScore.gameObject:SetActiveEx(false)
    end

    self.GridChapter:SetRawImage(self._StageGroup.Icon)
    self.GridChapter:SetButtonState(self._IsUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.TxtCondition.text = self._CondStr

    self.PanelOngoing.gameObject:SetActiveEx(self._IsPlaying)
    --self.Effect.gameObject:SetActiveEx(self._IsPlaying)
    self.TxtName.text = self._IsPlaying and "" or self._StageGroup.Name

    local isRed = self._Control:CheckStageGroupRedPoint(self._StageGroup.Id)
    self.GridChapter:ShowReddot(isRed)
end

function XUiGridFangKuaiStageGroup:OnClickChapter()
    if not self._IsUnlock then
        XUiManager.TipError(self._CondStr)
        return
    end
    if self._IsPlaying then
        self._Control:RecordStage(XEnumConst.FangKuai.RecordUiType.Main, XEnumConst.FangKuai.RecordButtonType.Continue, self._PlayingStageId)
        self._Control:EnterGame(self._PlayingStageId)
        return
    end
    if self._Control:IsOtherPlaying(self._PlayingStageId, self._ChapterId) then
        XUiManager.TipError(XUiHelper.GetText("FangKuaiOtherPlaying2"))
        return
    end
    XLuaUiManager.Open("UiFangKuaiChapterDetail", self._StageGroup.Id)
end

function XUiGridFangKuaiStageGroup:OnClickAbandon()
    self._Control:OpenTip(nil, XUiHelper.GetText("FangKuaiAbandonTip"), function()
        self._Control:RecordStage(XEnumConst.FangKuai.RecordUiType.Main, XEnumConst.FangKuai.RecordButtonType.GiveUp, self._PlayingStageId)
        self._Control:FangKuaiStageSettleRequest(self._PlayingStageId, XEnumConst.FangKuai.Settle.GiveUp, function()
            self.Parent:UpdateChapter()
        end)
    end)
end

function XUiGridFangKuaiStageGroup:PlayChapterAnim()
    self:PlayAnimationWithMask("GridChapterEnable")
end

return XUiGridFangKuaiStageGroup