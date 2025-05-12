---@class XUiFpsGameMain : XLuaUi 活动主界面
---@field _Control XFpsGameControl
local XUiFpsGameMain = XLuaUiManager.Register(XLuaUi, "UiFpsGameMain")

function XUiFpsGameMain:OnAwake()
    self.BtnStart.CallBack = handler(self, self.OnBtnStartClick)
    self.BtnEasy.CallBack = handler(self, self.OnBtnEasyClick)
    self.BtnHard.CallBack = handler(self, self.OnBtnHardClick)
    self.BtnHandbook.CallBack = handler(self, self.OnBtnHandbookClick)
    self.BtnExit.CallBack = handler(self, self.Close)
    self.BtnAboutUs.CallBack = handler(self, self.OnBtnAboutUsClick)
end

function XUiFpsGameMain:OnStart()
    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        local gameTime = endTime - XTime.GetServerNowTimestamp()
        self.TxtTime.text = XUiHelper.GetTime(gameTime, XUiHelper.TimeFormatType.ACTIVITY)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end, nil, 0)

    local isShowUnity = not self._Control:IsEnterMainPanel()
    self.BtnStart.gameObject:SetActiveEx(isShowUnity)
    self.PanelMenu.gameObject:SetActiveEx(not isShowUnity)
    self.TxtNum.text = self._Control:GetClientConfigById("Version")
    if isShowUnity then
        self:PlayAnimationWithMask("Start")
        local UiModelObjs = {}
        XUiHelper.InitUiClass(UiModelObjs, self.UiModelGo.transform)
        UiModelObjs.Enable:Play()
    end
end

function XUiFpsGameMain:OnEnable()
    self:ChallengeCountDown()
    self.BtnEasy:ShowReddot(self._Control:IsChapterRewardGain(XEnumConst.FpsGame.Story))
    -- 进度
    local cur, all = self._Control:GetProgress(XEnumConst.FpsGame.Story)
    self.BtnEasy:SetNameByGroup(1, string.format("%s%%", math.floor(cur / all * 100)))
    cur, all = self._Control:GetProgress(XEnumConst.FpsGame.Challenge)
    self.BtnHard:SetNameByGroup(1, string.format("%s%%", math.floor(cur / all * 100)))
    if self._Control:IsEnterMainPanel() then
        self:PlayAnimationWithMask("Enable")
    end
    self._Control:SetEnterMainPanel()
end

function XUiFpsGameMain:OnDestroy()
    self:RemoveTimer()
end

function XUiFpsGameMain:ChallengeCountDown()
    self:RemoveTimer()
    local challengeTime = self._Control:GetChapterOpenTime(XEnumConst.FpsGame.Challenge) - XTime.GetServerNowTimestamp()
    self._IsChallengeOpen = challengeTime <= 0
    if self._IsChallengeOpen then
        if self._Control:CheckChapterOpen(XEnumConst.FpsGame.Challenge, false) then
            self.BtnHard:SetButtonState(CS.UiButtonState.Normal)
            self.BtnHard:ShowReddot(self._Control:IsChapterRewardGain(XEnumConst.FpsGame.Challenge) or not XSaveTool.GetData("FpsGameHardReddot"))
        else
            self.BtnHard:SetButtonState(CS.UiButtonState.Disable)
            self.BtnHard:ShowReddot(false)
        end
    else
        self.BtnHard:SetButtonState(CS.UiButtonState.Disable)
        self.BtnHard:ShowReddot(false)
        self._ChallengeTimer = XScheduleManager.ScheduleOnce(handler(self, self.ChallengeCountDown), challengeTime)
    end
end

function XUiFpsGameMain:RemoveTimer()
    if self._ChallengeTimer then
        XScheduleManager.UnSchedule(self._ChallengeTimer)
        self._ChallengeTimer = nil
    end
end

function XUiFpsGameMain:OnBtnStartClick()
    self.BtnStart.gameObject:SetActiveEx(false)
    self.PanelMenu.gameObject:SetActiveEx(true)
end

function XUiFpsGameMain:OnBtnEasyClick()
    if self._Control:CheckChapterOpen(XEnumConst.FpsGame.Story, true) then
        self._Control:SetTriggerEnableCameraAnim()
        XLuaUiManager.Open("UiFpsGameChapter", XEnumConst.FpsGame.Story)
    end
end

function XUiFpsGameMain:OnBtnHardClick()
    if self._Control:CheckChapterOpen(XEnumConst.FpsGame.Challenge, true) then
        self._Control:SetTriggerEnableCameraAnim()
        XSaveTool.SaveData("FpsGameHardReddot", true)
        XLuaUiManager.Open("UiFpsGameChapter", XEnumConst.FpsGame.Challenge)
    end
end

function XUiFpsGameMain:OnBtnHandbookClick()
    XLuaUiManager.Open("UiFpsGameChooseWeapon")
end

function XUiFpsGameMain:OnBtnAboutUsClick()
    XLuaUiManager.Open("UiFpsGameAboutUs")
end

return XUiFpsGameMain