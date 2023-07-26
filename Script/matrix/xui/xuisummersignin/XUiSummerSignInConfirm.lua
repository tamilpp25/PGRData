local XUiSummerSignInConfirm = XLuaUiManager.Register(XLuaUi, "UiSummerSignInConfirm")

function XUiSummerSignInConfirm:OnAwake()
    self:RegisterUiEvents()
end

function XUiSummerSignInConfirm:OnStart()
    
end

function XUiSummerSignInConfirm:Refresh(messageId, cancelCb)
    self.MessageId = messageId
    self.CancelCb = cancelCb
    self:RefreshView()
end

function XUiSummerSignInConfirm:RefreshView()
    if self.TxtTitle then
        self.TxtTitle.text = XPlayer.Name or ""
    end
    local teamName =  XSummerSignInConfigs.GetTeamName(self.MessageId)
    local msg = XUiHelper.GetText("SummerSignInChoseMessage", teamName)
    self.Message.text = XUiHelper.ConvertLineBreakSymbol(msg)
end

function XUiSummerSignInConfirm:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBgClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnBlue, self.OnBtnBlueClick)
end

function XUiSummerSignInConfirm:OnBtnCloseClick()
    self:Close()
    if self.CancelCb then
        self.CancelCb()
    end
end

function XUiSummerSignInConfirm:OnBtnBlueClick()
    -- 签到
    XDataCenter.SummerSignInManager.SummerSignInRequest(self.MessageId, function(rewardGoodsList)
        self:Close()
        XLuaUiManager.Open("UiSummerSignInTips", self.MessageId, true, self.CancelCb)
    end)
end

return XUiSummerSignInConfirm