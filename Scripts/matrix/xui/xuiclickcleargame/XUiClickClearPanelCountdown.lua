local textManager = CS.XTextManager

local PanelStage = {
    Playing = 1,
    Pause = 2,
}

local XUiClickClearPanelCountdown = XClass(nil, "XUiClickClearPanelCountdown")

function XUiClickClearPanelCountdown:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
end

function XUiClickClearPanelCountdown:Show()
    self.GameObject:SetActiveEx(true)
    self:RefreshUi()
    self.Stage = PanelStage.Pause
end

function XUiClickClearPanelCountdown:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiClickClearPanelCountdown:RefreshUi()
    local gameInfo = XDataCenter.XClickClearGameManager.GetGameInfo()
    self.TextCountdown.text = string.format("%.2f", gameInfo.RemainTime)
end

function XUiClickClearPanelCountdown:OnGamePlaying()
    local gameInfo = XDataCenter.XClickClearGameManager.GetGameInfo()
    self.FullTime = gameInfo.RemainTime
    if self.FullTime <= 0 then
        XDataCenter.XClickClearGameManager.SetGameStateAccount(false)
        self.Stage = PanelStage.Pause
        return
    end
    self.AnimaTimer = XUiHelper.Tween(self.FullTime, function(f) return self:OnUpdate(f) end, function() self:TimeOverCallBack() end)
    self.Stage = PanelStage.Playing
end

function XUiClickClearPanelCountdown:OnGamePause(isCostTime)
    if isCostTime then
        self.IsInCostTime = isCostTime
        XUiManager.TipError(textManager.GetText("ClickClearGameTouchWrongHeadTip"))
    end
    self.Stage = PanelStage.Pause
end

function XUiClickClearPanelCountdown:OnUpdate(f)
    if self.Stage == PanelStage.Pause then
        return true
    end

    local remainTime = self.FullTime - f * self.FullTime
    if remainTime < 0 then
        remainTime = 0
    end
    XDataCenter.XClickClearGameManager.SetRemainTime(remainTime)
    local timeStr = string.format("%.2f", remainTime)
    self.TextCountdown.text = timeStr
end

function XUiClickClearPanelCountdown:TimeOverCallBack()
    if self.Stage == PanelStage.Pause then
        if self.FullTime <= 0 then
            XDataCenter.XClickClearGameManager.SetGameStateAccount(false)
            return
        end

        if self.IsInCostTime then
            self:OnGamePlaying()
            self.IsInCostTime = false
            return
        end

        return
    end

    XDataCenter.XClickClearGameManager.SetGameStateAccount(false)
    self.Stage = PanelStage.Pause
end

return XUiClickClearPanelCountdown