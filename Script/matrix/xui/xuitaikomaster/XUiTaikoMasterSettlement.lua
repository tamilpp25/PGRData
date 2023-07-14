---@class XUiTaikoMasterSettlement:XLuaUi
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

function XUiTaikoMasterSettlement:Init(data, historyScore)
    local stageId = data.StageId
    self._StageId = stageId
    local songId = XTaikoMasterConfigs.GetSongIdByStageId(stageId)
    -- self.StageName.text = XTaikoMasterConfigs.GetSongName(songId)
    self.TxtNameNormal.text = XTaikoMasterConfigs.GetDifficultyTextByStageId(stageId)
    self.RImgCd:SetRawImage(XTaikoMasterConfigs.GetSongSettlementImage(songId))
    local result = data.SettleData.TaikoMasterSettleResult
    local score = result.Score or 0
    local assessImage = XTaikoMasterConfigs.GetAssessImageByScore(stageId, score)
    if assessImage then
        self.RImgClass:SetRawImage(assessImage)
        self.RImgClass.gameObject:SetActiveEx(true)
    else
        self.RImgClass.gameObject:SetActiveEx(false)
    end
    local difficulty = XTaikoMasterConfigs.GetDifficulty(stageId)
    --完美连击
    if XDataCenter.TaikoMasterManager.IsPerfectCombo(songId, difficulty, result.Perfect, result.Combo) then
        self.TxtNameNew2.gameObject:SetActiveEx(true)
        self.TxtNameNew2.text = XUiHelper.GetText("TaikoMasterComboPerfect")
    elseif XDataCenter.TaikoMasterManager.IsFullCombo(songId, difficulty, result.Combo) then
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
    local bestScore = XDataCenter.TaikoMasterManager.GetMyScoreByStage(stageId)
    self.TxtHighScoresNumber.text = bestScore
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
    if isNewRecord and difficulty == XTaikoMasterConfigs.Difficulty.Hard then
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
    local stageId = self._StageId
    local stageConfig = XDataCenter.FubenManager.GetStageCfg(stageId)
    local team = XDataCenter.TaikoMasterManager.GetXTeam()
    local teamId = team:GetId()
    local isAssist = false
    local challengeCount = 1
    XDataCenter.FubenManager.EnterFight(
        stageConfig,
        teamId,
        isAssist,
        challengeCount,
        nil,
        function()
            if XLuaUiManager.IsUiShow(self.Name) then
                XLuaUiManager.Close(self.Name)
            end
        end
    )
end

function XUiTaikoMasterSettlement:OnBtnBack()
    XDataCenter.TaikoMasterManager.SetJustPassedStageId(self._StageId)
    self:Close()
end

function XUiTaikoMasterSettlement:PlayNumberAudio()
    self._AudioInfo = CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiSettle_Win_Number)
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
