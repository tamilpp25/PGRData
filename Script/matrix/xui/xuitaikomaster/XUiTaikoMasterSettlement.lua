---@class XUiTaikoMasterSettlement:XLuaUi
---@field _Control XTaikoMasterControl
local XUiTaikoMasterSettlement = XLuaUiManager.Register(XLuaUi, "UiTaikoMasterSettlement")

function XUiTaikoMasterSettlement:Ctor()
    self._StageId = false
    self._IsEndFightAction = false
    self._AudioInfo = false
    self._NumberTimer = false
end

function XUiTaikoMasterSettlement:OnStart(...)
    self:RegisterBtnClick()
    self:Init(...)
end

function XUiTaikoMasterSettlement:OnDestroy()
    self:EndFightAction()
    self:StopNumberAudio()
    self:StopNumberTimer()
end

function XUiTaikoMasterSettlement:EndFightAction()
    if not self._IsEndFightAction then
        XDataCenter.AntiAddictionManager.EndFightAction()
    end
end

function XUiTaikoMasterSettlement:Init(data, historyScore, curHistoryScore)
    self._StageId = data.StageId
    local songId = self._Control:GetSongIdByStageId(self._StageId)
    local difficulty = self._Control:GetDifficulty(self._StageId)
    local result = data.SettleData.TaikoMasterSettleResult
    local score = result.Score or 0
    local assessImage = self._Control:GetAssessImageByScore(self._StageId, score)
    local uiData = self._Control:GetUiData()

    self.TxtNameNormal.text = self._Control:GetDifficultyText(difficulty)
    self.RImgCd:SetRawImage(uiData.SongUiDataDir[songId].SettlementImage)
    if assessImage then
        self.RImgClass:SetRawImage(assessImage)
        self.RImgClass.gameObject:SetActiveEx(true)
    else
        self.RImgClass.gameObject:SetActiveEx(false)
    end
    --完美连击
    if self._Control:CheckIsPerfectCombo(self._StageId, result.Perfect, result.Combo) then
        self.TxtNameNew2.gameObject:SetActiveEx(true)
        self.TxtNameNew2.text = XUiHelper.GetText("TaikoMasterComboPerfect")
    elseif self._Control:CheckIsFullCombo(self._StageId, result.Combo) then
        self.TxtNameNew2.gameObject:SetActiveEx(true)
        self.TxtNameNew2.text = XUiHelper.GetText("TaikoMasterComboFull")
    else
        self.TxtNameNew2.gameObject:SetActiveEx(false)
    end

    --region 数字滚动效果
    local perfect = result.Perfect or 0
    local great = result.Great or 0
    local combo = result.Combo or 0
    local accuracy = result.Accuracy or 0
    -- 播放音效
    self:PlayNumberAudio()
    local mathFloor = math.floor
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    self._NumberTimer =
        XUiHelper.Tween(
        time,
        function(f)
            self.TxtPrecisionNumber.text = string.format("%d%%", mathFloor(f * accuracy))
            self.TxtPerfectNumber.text = mathFloor(f * perfect)
            self.TxtGreatNumber.text = mathFloor(f * great)
            self.TxtNameGradeNumber.text = mathFloor(f * score)
            self.TxtComboNumber.text = mathFloor(f * combo)
        end,
        function()
            self.TxtPrecisionNumber.text = string.format("%d%%", accuracy)
            self.TxtPerfectNumber.text = perfect
            self.TxtGreatNumber.text = great
            self.TxtNameGradeNumber.text = score
            self.TxtComboNumber.text = combo
            self:StopNumberAudio()
            self._NumberTimer = false
        end
    )
    --endregion

    --历史最高得分(包括本次)
    self.TxtHighScoresNumber.text = curHistoryScore
    --新纪录
    local isNewRecord = (not historyScore and score > 0) or (score > (historyScore or 0))
    self.PanelNewTag.gameObject:SetActiveEx(false)
    if isNewRecord then
        self.Enable.gameObject:PlayTimelineAnimation(
            function()
                self.PanelNewTag.gameObject:SetActiveEx(true)
                self.PanelNewTag.gameObject:PlayTimelineAnimation()
            end
        )
    else
        self.Enable.gameObject:PlayTimelineAnimation()
    end
    if isNewRecord and difficulty == XEnumConst.TAIKO_MASTER.DIFFICULTY.HARD then
        --击败xx%的玩家
        local ranking, playerAmount = result.Ranking or 0, result.TotalCount or 0
        local defeatPercent
        if playerAmount == 0 then
            defeatPercent = 0
        elseif ranking == 0 or ranking == 1 then
            defeatPercent = 100
        else
            defeatPercent = math.floor((1 - ranking / playerAmount) * 100)
            defeatPercent = XMath.Clamp(defeatPercent, 0, 100)
        end
        if defeatPercent >= 50 then
            self.TxtNameBeat.gameObject:SetActiveEx(true)
            self.TxtNameBeat.text = XUiHelper.GetText("TaikoMasterDefeat", defeatPercent)
        else
            self.TxtNameBeat.gameObject:SetActiveEx(false)
        end
    else
        self.TxtNameBeat.gameObject:SetActiveEx(false)
    end
end

function XUiTaikoMasterSettlement:RegisterBtnClick()
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnBack)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnEncore)
end

function XUiTaikoMasterSettlement:OnBtnEncore()
    self:EndFightAction()
    self._Control:SetJustEnterStageId(self._StageId)
    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    fubenAgency:EnterFightByStageId(self._StageId, nil, false, 1, nil)
    XLuaUiManager.Remove(self.Name)
end

function XUiTaikoMasterSettlement:OnBtnBack()
    self._Control:SetJustPassedStageId(self._StageId)
    self:Close()
end

function XUiTaikoMasterSettlement:PlayNumberAudio()
    self._AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number)
end

function XUiTaikoMasterSettlement:StopNumberAudio()
    if self._AudioInfo then
        self._AudioInfo:Stop()
        self._AudioInfo = false
    end
end

function XUiTaikoMasterSettlement:StopNumberTimer()
    if self._NumberTimer then
        XScheduleManager.UnSchedule(self._NumberTimer)
        self._NumberTimer = false
    end
end

return XUiTaikoMasterSettlement
