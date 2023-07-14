--工会boss战斗结算页面
local XUiGuildBossFightResult = XLuaUiManager.Register(XLuaUi, "UiGuildBossFightResult")

function XUiGuildBossFightResult:OnAwake()
    self.BtnExitFight.CallBack = function() self:OnBtnExitFightClick() end
    self.BtnSave.CallBack = function() self:OnBtnSaveClick() end
end

function XUiGuildBossFightResult:OnStart(data)
    self.StageId = data.StageId
    local guildBossStageInfo = XGuildBossConfig.GetBossStageInfo(data.StageId)
    self.Data = data.GuildBossFightResult
    self.TxtTile.text = guildBossStageInfo.Name
    self.TxtRemainHpScoreMax.text = CS.XTextManager.GetText("ArenaMaxSingleScore", self.Data.HpMaxScore)
    self.PanelNewRecord.gameObject:SetActiveEx(self.Data.TotalScore > self.Data.TotalHighScore)

    --总积分以及历史最高
    self.TxtPoint.text = CS.XTextManager.GetText("ArenaMaxAllScore", self.Data.TotalScore)
    self.TxtHighScore.text = CS.XTextManager.GetText("ArenaMaxAllHistoryScore", self.Data.TotalHighScore)
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")

    -- 通关时间
    local costTime = XUiHelper.GetTime(self.Data.UseTime, XUiHelper.TimeFormatType.SHOP)
    self.TxtCostTime.text = costTime

    self.TweenAnim = XUiHelper.Tween(time, function(f)
        --伤害量
        self.TxtDamage.text = math.floor(f * self.Data.Damage)
        self.TxtDamageScore.text = '+' .. math.floor(f * self.Data.DamageScore)

        --剩余血量
        self.TxtRemainHp.text = math.floor(f * self.Data.HpLeftPer) .. "%"
        self.TxtRemainHpScore.text = '+' .. math.floor(f * self.Data.HpScore)

        --参与积分
        self.TxtAddScore.text = '+' .. math.floor(f * self.Data.Base)

        --总积分以及历史最高
        self.TxtPoint.text = math.floor(f * self.Data.TotalScore)
        self.TxtHighScore.text = math.floor(f * self.Data.TotalHighScore)

    end, nil)

    XDataCenter.GuildBossManager.SetNeedUpdateStageInfo(true)
end

function XUiGuildBossFightResult:OnDestroy()
    if self.TweenAnim then
        XScheduleManager.UnSchedule(self.TweenAnim)
        self.TweenAnim = nil
    end
end

function XUiGuildBossFightResult:OnBtnExitFightClick()
    if XDataCenter.GuildManager.GetGuildId() <= 0 then
        XUiManager.TipMsg(CS.XTextManager.GetText("GuildKickOutByAdministor"))
        XLuaUiManager.RunMain()
    else
        self:Close()
    end
end

function XUiGuildBossFightResult:OnBtnSaveClick()
    XDataCenter.GuildBossManager.GuildBossUploadRequest(self.StageId, function() self:Close() end)
end