local XUiAnniversaryMain=XLuaUiManager.Register(XLuaUi,'UiAnniversaryMain')

--region 生命周期
function XUiAnniversaryMain:OnAwake()
    self.BtnSignin.CallBack=handler(self,self.OnSignInClickEvent)
    self.BtnResearch.CallBack=handler(self,self.OnResearchClickEvent)
    self.BtnFourteenDay.CallBack=handler(self,self.OnFourteenDayClickEvent)
    self.BtnMemory.CallBack=handler(self,self.OnMemoryClickEvent)
    self.Btn1stRecharge.CallBack=handler(self,self.On1stRechargeClickEvent)
    self.BtnReview.CallBack=handler(self,self.OnReviewClickEvent)
    self.BtnClose.CallBack=function() self:Close() end
end

function XUiAnniversaryMain:OnStart()
    self:RefreshBtnState()
end

--endregion

--region 界面更新
function XUiAnniversaryMain:RefreshBtnState()
    self.BtnSignin:SetButtonState(self._Control:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.SignIn) and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnResearch:SetButtonState(self._Control:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.AnniversaryDraw) and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnFourteenDay:SetButtonState(self._Control:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.DayDraw) and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnMemory:SetButtonState(self._Control:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.RepeatChallenge) and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnReview:SetButtonState(self._Control:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.Review) and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.Btn1stRecharge:SetButtonState(self._Control:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.FirstRecharge) and CS.UiButtonState.Normal or CS.UiButtonState.Disable)

end

--endregion

--region 事件
function XUiAnniversaryMain:OnSignInClickEvent()
    --打开签到界面
    local isOpen,desc=self._Control:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.SignIn)
    if isOpen then
        self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.SignIn)
    else
        XUiManager.TipMsg(desc)
    end
end

function XUiAnniversaryMain:OnResearchClickEvent()
    --跳转到角色抽卡界面
    local isOpen,desc=self._Control:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.AnniversaryDraw)
    if isOpen then
        self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.AnniversaryDraw)

    else
        XUiManager.TipMsg(desc)
    end
end

function XUiAnniversaryMain:OnFourteenDayClickEvent()
    --跳转到每日一抽
    local isOpen,desc=self._Control:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.DayDraw)
    if isOpen then
        self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.DayDraw)

    else
        XUiManager.TipMsg(desc)
    end
end

function XUiAnniversaryMain:OnMemoryClickEvent()
    --跳转到复刷关
    local isOpen,desc=self._Control:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.RepeatChallenge)
    if isOpen then
        self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.RepeatChallenge)

    else
        XUiManager.TipMsg(desc)
    end
end

function XUiAnniversaryMain:On1stRechargeClickEvent()
    --首冲
    local isOpen,desc=self._Control:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.FirstRecharge)
    if isOpen then
        self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.FirstRecharge)

    else
        XUiManager.TipMsg(desc)
    end
end

function XUiAnniversaryMain:OnReviewClickEvent()
    --跳转到周年回顾
    local isOpen,desc=self._Control:JudgeCanOpen(XEnumConst.Anniversary.ActivityType.Review)
    --todo:仅测试基本UI，正式测数据需要走下面的请求回调逻辑
    if true then
        self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.Review)
        return
    end
    if isOpen then
        XDataCenter.ReviewActivityManager.GetReviewData(function()
            self._Control:SkipToActivity(XEnumConst.Anniversary.ActivityType.Review)
        end)
    else
        XUiManager.TipMsg(desc)
    end
end
--endregion

return XUiAnniversaryMain