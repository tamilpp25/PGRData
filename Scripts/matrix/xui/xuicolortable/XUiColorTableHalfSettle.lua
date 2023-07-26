local XUiColorTableHalfSettle = XLuaUiManager.Register(XLuaUi,"UiColorTableHalfSettle")

function XUiColorTableHalfSettle:OnAwake()
    self:_AddBtnListener()
end

function XUiColorTableHalfSettle:OnStart(isSpecialWin, isLose, callback, giveUpCb, rebootCb)
    self.IsSpecailWin = isSpecialWin
    self.IsLose = isLose
    self.CallBack = callback
    self.GiveUpCb = giveUpCb
    self.ReBootCb = rebootCb

    self:Refresh()
end

function XUiColorTableHalfSettle:Refresh()
    local winConditionId = XDataCenter.ColorTableManager.GetGameManager():GetGameData():GetWinConditionId()
    local mapId = XDataCenter.ColorTableManager.GetGameManager():GetGameData():GetMapId()
    local txtColor = XColorTableConfigs.GetHaflSettleTxtColor(self.IsSpecailWin)
    local tipTxtColor = XColorTableConfigs.GetHaflSettleTipTxtColor(self.IsSpecailWin)

    if self.IsLose then
        local isReboot = XTool.IsNumberValid(XColorTableConfigs.GetMapRebootable(mapId))
        self.BtnEnter.gameObject:SetActiveEx(false)
        self.BtnGiveUp.gameObject:SetActiveEx(true)
        self.BtnReboot.gameObject:SetActiveEx(isReboot)
        self.TxtInfo.text = XUiHelper.GetText("ColorTableSettleLoseTitle")
        self.TxtTips.text = isReboot and XUiHelper.ReadTextWithNewLine("ColorTableSettleLoseTip") or XUiHelper.ReadTextWithNewLine("ColorTableSettleHardLoseTip")
    else
        self.BtnEnter.gameObject:SetActiveEx(true)
        self.BtnGiveUp.gameObject:SetActiveEx(false)
        self.BtnReboot.gameObject:SetActiveEx(false)
        self.TxtTips.gameObject:SetActiveEx(not XDataCenter.ColorTableManager.GetGameManager():GetGameData():CheckIsFirstGuideStage())
        self.TxtInfo.text = XUiHelper.GetText("ColorTableSettleWinTitle", txtColor, XColorTableConfigs.GetWinConditionName(winConditionId))
        self.TxtTips.text = XUiHelper.ReadTextWithNewLine("ColorTableSettleWinTip", tipTxtColor)
    end

    self.RImgBg01:SetRawImage(XColorTableConfigs.GetHaflSettleBgIcon(self.IsSpecailWin, self.IsLose))
    self.RImgWin:SetRawImage(XColorTableConfigs.GetHalfSettleTitleIcon(self.IsSpecailWin, self.IsLose))
end


-- private
----------------------------------------------------------------

function XUiColorTableHalfSettle:_AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnEnter, self._OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGiveUp, self._OnBtnGiveUpClick)
    XUiHelper.RegisterClickEvent(self, self.BtnReboot, self._OnBtnRebootClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self._OnBtnCloseClick)
end

function XUiColorTableHalfSettle:_OnBtnCloseClick()
    self:Close()
    if self.CallBack then
        self.CallBack()
    end
end

function XUiColorTableHalfSettle:_OnBtnGiveUpClick()
    self:Close()
    if self.GiveUpCb then
        self.GiveUpCb()
    end
end

function XUiColorTableHalfSettle:_OnBtnRebootClick()
    self:Close()
    if self.ReBootCb then
        self.ReBootCb()
    end
end

----------------------------------------------------------------