local XUiMaverick2ScoreResult = XLuaUiManager.Register(XLuaUi, "UiMaverick2ScoreResult")

function XUiMaverick2ScoreResult:OnAwake()
    self:InitButtons()
    self.PanelScoreInfo.gameObject:SetActiveEx(false)
end

function XUiMaverick2ScoreResult:OnStart(settle, oldScore, newScore, cb)
    self.StageId = settle.StageId

    -- 战斗花费时间
    local curFightResult = XMVCA.XFuben:GetCurFightResult()
    local costTime = (curFightResult.SettleFrame - curFightResult.PauseFrame - curFightResult.StartFrame) / CS.XFightConfig.FPS
    local h = XMath.ToMinInt(costTime / (60 * 60))
    local m = XMath.ToMinInt((costTime - h * (60 * 60)) / 60)
    local s = XMath.ToMinInt(costTime - h * (60 * 60) - m * 60)
    self.TxtCostTime.text = string.format("%02d:%02d:%02d", h, m, s)

    -- 刷新积分
    if newScore > oldScore then
        self.TxtPoint.text = CSXTextManagerGetText("MaverickStageScoreMax", newScore)
        self.TxtHighScore.text = CSXTextManagerGetText("MaverickStageHistoryScoreMax", newScore)
        self.PanelNewRecord.gameObject:SetActiveEx(true)
    else
        self.TxtPoint.text = newScore
        self.TxtHighScore.text = oldScore
        self.PanelNewRecord.gameObject:SetActiveEx(false)
    end

    -- 回调
    if cb then
        cb(newScore)
    end
end

function XUiMaverick2ScoreResult:InitButtons()
    XUiHelper.RegisterClickEvent(self, self.BtnExitFight, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnReFight, self.OnClickReEnterFight)
end

function XUiMaverick2ScoreResult:OnClickReEnterFight()
    self:Close()
    XDataCenter.Maverick2Manager.ReEnterFight()
end