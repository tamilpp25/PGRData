---@class XUiSettleWinSingleBoss : XLuaUi
---@field _Control XFubenBossSingleControl
local XUiSettleWinSingleBoss = XLuaUiManager.Register(XLuaUi, "UiSettleWinSingleBoss")

function XUiSettleWinSingleBoss:OnAwake()
    self:AutoAddListener()
end

function XUiSettleWinSingleBoss:OnStart(data)
    self:ShowPanel(data)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
end

function XUiSettleWinSingleBoss:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SAVE_NEW_RECORD, self.OnBtnLeftClick, self)
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    self:PlayAnimation("PanelBossSingleinfo")
    self:OnActivityEnd()
end

function XUiSettleWinSingleBoss:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SAVE_NEW_RECORD, self.OnBtnLeftClick, self)
    XDataCenter.AntiAddictionManager.EndFightAction()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
end

function XUiSettleWinSingleBoss:OnActivityEnd()
    self._Control:OnActivityEnd()
end

function XUiSettleWinSingleBoss:AutoAddListener()
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeftClick)
    self:RegisterClickEvent(self.BtnSave, self.OnBtnSaveClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
end

function XUiSettleWinSingleBoss:ShowPanel(data)
    self.IsClash = false
    self.PanelNewTag.gameObject.transform.localScale = CS.UnityEngine.Vector3.zero
    self.StageId = data.StageId
    self.IsSave = true

    local isChallenge = self._Control:IsBossSingleChallenge()
    local stageCfg = XMVCA.XFuben:GetStageCfg(data.StageId)
    local difficultName = self._Control:GetBossDifficultName(data.StageId)
    self.TxtDifficult.text = difficultName

    local settleData = data.SettleData
    local result = settleData.BossSingleFightResult

    local showLeftTime = result.MaxTimeScore
    self.PanelLeftTime.gameObject:SetActiveEx(showLeftTime > 0)

    local myTotalHistory = self:GetMyTotalHistory()
    local stageInfo = self._Control:GetBossStageInfo(data.StageId)
    local bossTotalScore = (stageInfo and stageInfo.Score or 0) + self._Control:GetBaseScoreByStageId(data.StageId)
    local bossLoseHpScore = stageInfo and stageInfo.BossLoseHpScore or 0
    local leftTimeScore = stageInfo and stageInfo.LeftTimeScore or 0
    local leftHpScore = stageInfo and stageInfo.LeftHpScore or 0
    local curBossTotalScore = self._Control:GetBossCurSettleScore(data.StageId, result.TotalScore)
    local curBossMaxScore = self._Control:GetBossMaxScoreByStageId(data.StageId)

    self.CurAllScore = result.TotalScore
    self.TxtBossAllLoseHpScore.text = XUiHelper.GetText("BossSingleAutoFightDesc10", result.MaxBossDamageScore)
    self.TxAlltLeftTimeScore.text = XUiHelper.GetText("BossSingleAutoFightDesc10", showLeftTime)
    self.TxtAllCharLeftHpScore.text = XUiHelper.GetText("BossSingleAutoFightDesc10", result.MaxHpScore)
    self.TxtHistoryScore2.gameObject:SetActiveEx(not isChallenge)
    self.TxtHistoryScoreDesc2.gameObject:SetActiveEx(not isChallenge)

    self.GameObject:SetActiveEx(true)
    -- 播放音效
    self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number)

    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    XUiHelper.Tween(time, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        local totalTimeText = XUiHelper.GetTime(math.floor(f * result.FightTime))
        local bossLoseHpText = math.floor(f * result.BossDamagePer) .. "%"
        local bossLoseHpScoreText = "+" .. math.floor(f * result.BossDamageScore)
        local leftTimeText = XUiHelper.GetTime(math.floor(f * result.TimeLeft))
        local leftTimeScoreText = "+" .. math.floor(f * result.TimeScore)
        local charLeftHpText = math.floor(f * result.HpLeftPer) .. "%"
        local charLeftHpScoreText = "+" .. math.floor(f * result.HpScore)
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
        if not isChallenge then
            self.TxtHistoryScore2.text = curSettleBossSocreText
        end

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
    self:RefreshButton(data)
end

function XUiSettleWinSingleBoss:SetDefaultText()
    self.TxtStageTime.text = XUiHelper.GetTime(0)
    self.TxtBossLoseHp.text = 0
    self.TxtBossLoseHpScore.text = "+" .. 0
    self.TxtLeftTime.text = XUiHelper.GetTime(0)
    self.TxtLeftTimeScore.text = "+" .. 0
    self.TxtCharLeftHp.text = 0
    self.TxtCharLeftHpScore.text = "+" .. 0
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
    if self.IsClash then
        self._Control:OpenChallengeSaveDialog(self.CharacterIds, self.CurAllScore, self.StageId, self.ClashMap)
    else
        if self.IsSave then
            XMVCA.XFubenBossSingle:RequestSaveScore(self.StageId, function(isTip)
                self:OnBtnLeftClick()
                if isTip then
                    XUiManager.TipText("BossSignleBufenTip", XUiManager.UiTipType.Tip)
                end
            end)
        else
            self:OnBtnLeftClick()
        end
    end
end

function XUiSettleWinSingleBoss:OnBtnCancelClick()
    local myTotalHistory = self:GetMyTotalHistory()

    if self.CurAllScore <= myTotalHistory then
        self._Control:SetIsUseSelectIndex(true)
        self:OnBtnLeftClick()
    else
        local titletext = XUiHelper.GetText("TipTitle")
        local contenttext = XUiHelper.GetText("BossSingleReslutDesc")
        XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, nil, function()
            self._Control:SetIsUseSelectIndex(true)
            self:OnBtnLeftClick()
        end)
    end
end

function XUiSettleWinSingleBoss:GetMyTotalHistory()
    -- 是否是试玩副本
    local isTrial = self._Control:IsBossSingleTrial()
    local score = 0
    if isTrial then
        local data = self._Control:GetBossSingleData()
        local stageData = data:GetBossSingleTrialStageInfoByStageId(self.StageId)

        score = stageData and stageData:GetScore() or 0
    else
        local stageData = XMVCA.XFuben:GetStageData(self.StageId)

        score = stageData and stageData.Score or 0
    end
    
    return score
end

function XUiSettleWinSingleBoss:RefreshButton(data)
    local isNormal = self._Control:IsBossSingleNormal()

    if isNormal then
        -- 体验版和凹分区隐藏体力文本提示
        self.BtnSave.transform:Find("Text").gameObject:SetActiveEx(isNormal)
    else
        local isChallenge = self._Control:IsBossSingleChallenge()

        self.BtnSave.transform:Find("Text").gameObject:SetActiveEx(isNormal)
        if isChallenge then
            local myTotalHistory = self:GetMyTotalHistory()
            local characterList = data.CharExp
            local challengeData = self._Control:GetBossSingleChallengeData()
            local characterIds = {}

            if self.CurAllScore <= myTotalHistory then
                self.IsSave = false
                self.BtnCancel.gameObject:SetActiveEx(false)
                self.BtnSave:SetNameByGroup(0, XUiHelper.GetText("BossSingleModeExit"))
            else
                local isClash = false
                local clashFeatureMap = {}

                if not XMVCA.XFubenBossSingle:GetRelieveTeamAstrict() then -- 先锋服解除编队限制
                    if not XTool.IsTableEmpty(characterList) then
                        for _, exp in pairs(characterList) do
                            table.insert(characterIds, exp.Id)
                            if challengeData:CheckCharacterClash(exp.Id) then
                                local feature = challengeData:GetClashFeature(exp.Id)

                                if feature and feature:GetStageId() ~= self.StageId then
                                    isClash = true
                                    clashFeatureMap[feature:GetFeatureId()] = feature
                                end
                            end
                        end
                    end
                end
                if isClash then
                    self.IsClash = isClash
                    self.ClashMap = clashFeatureMap
                    self.CharacterIds = characterIds
                else
                    self.BtnCancel.gameObject:SetActiveEx(false)
                    self.BtnSave:SetNameByGroup(0, XUiHelper.GetText("BossSingleModeSaveAndExit"))
                end
            end
        end
    end
end
