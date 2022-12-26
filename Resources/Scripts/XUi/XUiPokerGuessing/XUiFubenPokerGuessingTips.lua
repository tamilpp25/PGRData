local XUiFubenPokerGuessingTips = XLuaUiManager.Register(XLuaUi,"UiFubenPokerGuessingTips")

function XUiFubenPokerGuessingTips:OnStart()
    self:RegisterButtonEvent()
    self:Refresh()
end

function XUiFubenPokerGuessingTips:RegisterButtonEvent()
    self.BtnEnd.CallBack = function() self:OnClickBtnEnd() end
    self.BtnContinue.CallBack = function() self:OnClickBtnContinue() end
    self.BtnNo.CallBack = function() self:OnClickBtnNo() end
    self.BtnYes.CallBack = function() self:OnClickBtnYes() end
end

function XUiFubenPokerGuessingTips:Refresh()
    local currStatus = XDataCenter.PokerGuessingManager.GetCurrGameStatus()
    if currStatus == XPokerGuessingConfig.GameStatus.Victory then
        self.PanelNormal.gameObject:SetActiveEx(true)
        self.PanelEnd.gameObject:SetActiveEx(false)
        self.TxtTitle1.text = CS.XTextManager.GetText("PokerGuessingVictory")
        self.TxtTitle2.text = CS.XTextManager.GetText("PokerGuessingVictoryEng")
    elseif currStatus == XPokerGuessingConfig.GameStatus.Failed then
        self.PanelNormal.gameObject:SetActiveEx(true)
        self.PanelEnd.gameObject:SetActiveEx(false)
        self.TxtTitle1.text = CS.XTextManager.GetText("PokerGuessingFailed")
        self.TxtTitle2.text = CS.XTextManager.GetText("PokerGuessingFailedEng")
    elseif currStatus == XPokerGuessingConfig.GameStatus.VictoryAndLibraryEmpty then
        self.PanelNormal.gameObject:SetActiveEx(false)
        self.PanelEnd.gameObject:SetActiveEx(true)
        self.TxtTitle1.text = CS.XTextManager.GetText("PokerGuessingVictory")
        self.TxtTitle2.text = CS.XTextManager.GetText("PokerGuessingVictoryEng")
    end
    self:RefreshPanel()
end

function XUiFubenPokerGuessingTips:RefreshPanel()
    self.TxtLeftScore.text = XDataCenter.PokerGuessingManager.GetOldScore()
    self.TxtRightScore.text = XDataCenter.PokerGuessingManager.GetCurrentScore()
    self.TxtEndLeftScore.text = XDataCenter.PokerGuessingManager.GetOldScore()
    self.TxtEndRightScore.text = XDataCenter.PokerGuessingManager.GetCurrentScore()
    self.Prompt.text = CS.XTextManager.GetText("PokerGuessingEmptyLibrayText")
end

function XUiFubenPokerGuessingTips:OnClickBtnEnd()
    XDataCenter.PokerGuessingManager.IsContinueGuessRequest(false)
    self:Close()
end

function XUiFubenPokerGuessingTips:OnClickBtnContinue()
    XDataCenter.PokerGuessingManager.IsContinueGuessRequest(true)
    self:Close()
end

function XUiFubenPokerGuessingTips:OnClickBtnNo()
    XDataCenter.PokerGuessingManager.IsContinueGuessRequest(false)
    self:Close()
end

function XUiFubenPokerGuessingTips:OnClickBtnYes()
    XDataCenter.PokerGuessingManager.IsContinueGuessRequest(true)
    self:Close()
end


return XUiFubenPokerGuessingTips
