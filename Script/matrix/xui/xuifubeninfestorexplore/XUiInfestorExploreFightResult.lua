local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiInfestorExploreFightResult = XLuaUiManager.Register(XLuaUi, "UiInfestorExploreFightResult")

function XUiInfestorExploreFightResult:OnAwake()
    self:AutoAddListener()
end

function XUiInfestorExploreFightResult:OnStart(stageId, result, isNewScore)
    self.StageId = stageId

    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    self.TxtTile.text = stageCfg.Name

    local SetMaxTextDesc = function(text, ponit)
        if ponit > 0 then
            text.text = CSXTextManagerGetText("ArenaMaxSingleScore", ponit)
        else
            text.text = CSXTextManagerGetText("ArenaMaxSingleNoScore")
        end
    end
    SetMaxTextDesc(self.TxtHitSocreMax, result.DamageMaxScore)
    SetMaxTextDesc(self.TxtRemainHpScoreMax, result.HpMaxScore)
    SetMaxTextDesc(self.TxtRemainTimeScoreMax, result.UseTimeMaxScore)

    self.PanelNewRecord.gameObject:SetActiveEx(isNewScore)

    local result = result
    local bossSingleAnimaTime = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    -- 播放音效
    self.AudioInfo = CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiSettle_Win_Number)
    XUiHelper.Tween(bossSingleAnimaTime, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        local time = result.UseTime

        -- 歼敌奖励
        local hitCombo = math.floor(f * result.Damage)
        local hitScore = '+' .. math.floor(f * result.DamageScore)
        self.TxtHitCombo.text = hitCombo
        self.TxtHitScore.text = hitScore

        -- 我方血量
        local remainHp = math.floor(f * result.HpLeftPer) .. "%"
        local remainHpScore = '+' .. math.floor(f * result.HpScore)
        self.TxtRemainHp.text = remainHp
        self.TxtRemainHpScore.text = remainHpScore

        -- 剩余时间
        local remainTime = XUiHelper.GetTime(math.floor(f * time), XUiHelper.TimeFormatType.SHOP)
        local remainTimeSacore = '+' .. math.floor(f * result.UseTimeScore)
        self.TxtRemainTime.text = remainTime
        self.TxtRemainTimeScore.text = remainTimeSacore

        -- 通关时间
        local costTime = XUiHelper.GetTime(math.floor(f * time), XUiHelper.TimeFormatType.SHOP)
        self.TxtCostTime.text = costTime

        -- 当前总分
        local point = math.floor(f * result.TotalScore)
        self.TxtPoint.text = point

        -- 历史最高分
        local highScore = math.floor(f * result.TotalHighScore)
        self.TxtHighScore.text = highScore
    end, function()
        self:StopAudio()
    end)
end

function XUiInfestorExploreFightResult:AutoAddListener()
    self.BtnReFight.CallBack = function() self:OnClickBtnReFight() end
    self.BtnExitFight.CallBack = function() self:OnClickBtnExitFight() end
end

function XUiInfestorExploreFightResult:OnClickBtnReFight()
    self:Close()
    XLuaUiManager.Open("UiNewRoomSingle", self.StageId)
end

function XUiInfestorExploreFightResult:OnClickBtnExitFight()
    self:Close()
end

function XUiInfestorExploreFightResult:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end