local XUiSettleWinSingleBoss = XLuaUiManager.Register(XLuaUi, "UiSettleWinSingleBoss")

function XUiSettleWinSingleBoss:OnAwake()
    self:AutoAddListener()
end

function XUiSettleWinSingleBoss:OnStart(data)
    self:ShowPanel(data)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
end

function XUiSettleWinSingleBoss:OnEnable()
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    self:PlayAnimation("PanelBossSingleinfo")
    self:OnActivityEnd()
end

function XUiSettleWinSingleBoss:OnDestroy()
    XDataCenter.AntiAddictionManager.EndFightAction()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
end

function XUiSettleWinSingleBoss:OnActivityEnd()
    XDataCenter.FubenBossSingleManager.OnActivityEnd()
end

function XUiSettleWinSingleBoss:AutoAddListener()
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick)
    self:RegisterClickEvent(self.BtnSave, self.OnBtnSaveClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
end

function XUiSettleWinSingleBoss:ShowPanel(data)
    self.PanelNewTag.gameObject.transform.localScale = CS.UnityEngine.Vector3.zero
    self.StageId = data.StageId

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(data.StageId)
    local difficultName = XDataCenter.FubenBossSingleManager.GetBossDifficultName(data.StageId)
    self.TxtDifficult.text = difficultName

    local settleData = data.SettleData
    local result = settleData.BossSingleFightResult

    local showLeftTime = result.MaxTimeScore
    self.PanelLeftTime.gameObject:SetActiveEx(showLeftTime > 0)


    local myTotalHistory = self:GetMyTotalHistory()
    local stageInfo = XDataCenter.FubenBossSingleManager.GetBossStageInfo(data.StageId)
    local bossTotalScore = stageInfo and stageInfo.Score or 0
    local bossLoseHpScore = stageInfo and stageInfo.BossLoseHpScore or 0
    local leftTimeScore = stageInfo and stageInfo.LeftTimeScore or 0
    local leftHpScore = stageInfo and stageInfo.LeftHpScore or 0
    local curBossTotalScore = XDataCenter.FubenBossSingleManager.GetBossCurSettleScore(data.StageId, result.TotalScore)
    local curBossMaxScore = XDataCenter.FubenBossSingleManager.GetBossMaxScoreByStageId(data.StageId)

    self.CurAllScore = result.TotalScore
    self.TxtBossAllLoseHpScore.text = CS.XTextManager.GetText("BossSingleAutoFightDesc10", result.MaxBossDamageScore)
    self.TxAlltLeftTimeScore.text = CS.XTextManager.GetText("BossSingleAutoFightDesc10", showLeftTime)
    self.TxtAllCharLeftHpScore.text = CS.XTextManager.GetText("BossSingleAutoFightDesc10", result.MaxHpScore)

    self.GameObject:SetActiveEx(true)
    -- 播放音效
    self.AudioInfo = CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiSettle_Win_Number)

    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    XUiHelper.Tween(time, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        local totalTimeText = XUiHelper.GetTime(math.floor(f * result.FightTime))
        local bossLoseHpText = math.floor(f * result.BossDamagePer) .. "%"
        local bossLoseHpScoreText = '+' .. math.floor(f * result.BossDamageScore)
        local leftTimeText = XUiHelper.GetTime(math.floor(f * result.TimeLeft))
        local leftTimeScoreText = '+' .. math.floor(f * result.TimeScore)
        local charLeftHpText = math.floor(f * result.HpLeftPer) .. "%"
        local charLeftHpScoreText = '+' .. math.floor(f * result.HpScore)
        local allScoreText = math.floor(f * result.TotalScore)
        local historyScoreText = math.floor(f * myTotalHistory) .. "/" .. bossTotalScore
        local curSettleBossSocreText = math.floor(f * curBossTotalScore) .. "/" .. curBossMaxScore

        self.TxtStageTime.text = totalTimeText
        self.TxtBossLoseHp.text = bossLoseHpText
        self.TxtBossLoseHpScore.text = bossLoseHpScoreText
        self.TxtLeftTime.text = leftTimeText
        self.TxtLeftTimeScore.text = leftTimeScoreText
        self.TxtCharLeftHp.text = charLeftHpText
        self.TxtCharLeftHpScore.text = charLeftHpScoreText
        self.TxtAllScore.text = allScoreText
        self.TxtHistoryScore.text = historyScoreText
        self.TxtHistoryScore2.text = curSettleBossSocreText

    end, function()
        if XTool.UObjIsNil(self.Transform) or XTool.UObjIsNil(self.PanelNewTag) then
            return
        end

        
        local tmpMyTotalHistory = self:GetMyTotalHistory()

        if self.CurAllScore > tmpMyTotalHistory then
            self.PanelNewTag.gameObject.transform.localScale = CS.UnityEngine.Vector3.one
            self.PanelNewTag.gameObject:PlayTimelineAnimation()
        end

        self:StopAudio()
    end)

    -- 体验版隐藏体力文本提示
    local isTrial = XDataCenter.FubenBossSingleManager.GetIsBossSingleTrial()
    self.BtnSave.transform:Find("Text").gameObject:SetActive(not isTrial)
end

function XUiSettleWinSingleBoss:SetDefaultText()
    self.TxtStageTime.text = XUiHelper.GetTime(0)
    self.TxtBossLoseHp.text = 0
    self.TxtBossLoseHpScore.text = '+' .. 0
    self.TxtLeftTime.text = XUiHelper.GetTime(0)
    self.TxtLeftTimeScore.text = '+' .. 0
    self.TxtCharLeftHp.text = 0
    self.TxtCharLeftHpScore.text = '+' .. 0
    self.TxtAllScore.text = 0
    self.TxtHistoryScore.text = 0
    self.TxtHistoryScore2.text = 0
end

function XUiSettleWinSingleBoss:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end

function XUiSettleWinSingleBoss:OnBtnLeftClick()
    self:StopAudio()
    XLuaUiManager.Close("UiSettleWinSingleBoss")
    XTipManager.Execute()
end

function XUiSettleWinSingleBoss:OnBtnSaveClick()
    XDataCenter.FubenBossSingleManager.SaveScore(self.StageId, function(isTip)
        self:OnBtnLeftClick()
        if isTip then
            XUiManager.TipText("BossSignleBufenTip", XUiManager.UiTipType.Tip)
        end
    end)
end

function XUiSettleWinSingleBoss:OnBtnCancelClick()
    local myTotalHistory = self:GetMyTotalHistory()

    if self.CurAllScore <= myTotalHistory then
        self:OnBtnLeftClick()
    else
        local titletext = CS.XTextManager.GetText("TipTitle")
        local contenttext = CS.XTextManager.GetText("BossSingleReslutDesc")
        XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, nil, function()
            self:OnBtnLeftClick()
        end)
    end
end

function XUiSettleWinSingleBoss:GetMyTotalHistory()
    -- 是否是试玩副本
    local isTrial = XDataCenter.FubenBossSingleManager.GetIsBossSingleTrial()
    local stageData
    if isTrial then
        stageData = XDataCenter.FubenBossSingleManager.GetTrialStageInfo(self.StageId)
    else
        stageData = XDataCenter.FubenManager.GetStageData(self.StageId)
    end
    return stageData and stageData.Score or 0
end