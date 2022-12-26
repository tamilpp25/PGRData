local XUiFunbenKoroTutorial = XLuaUiManager.Register(XLuaUi, "UiFunbenKoroTutorial")
local XUiPanelFubenKoroStage = require("XUi/XUiNewChar/XUiPanelFubenKoroStage")

function XUiFunbenKoroTutorial:OnAwake()
    self:InitAutoScript()
    self.RedPointBtnChallengeId = XRedPointManager.AddRedPointEvent(self.BtnChallenge, self.RefreshBtnChallengeRedDot, self, {
            XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYCHALLENGERED,
        })
    self.RedPointBtnTeachingId = XRedPointManager.AddRedPointEvent(self.BtnTeaching, self.RefreshBtnTeachingRedDot, self, {
            XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYTEACHINGRED,
        })
    self.PanelRoot = self.PanelStageRoot.parent:Find("PanelRoot")
end

function XUiFunbenKoroTutorial:OnStart(actId)
    XLuaUiManager.SetMask(true)
    self:PlayAnimation("AnimSwitch", function()
        XLuaUiManager.SetMask(false)
    end)

    self.Id = actId
    self.CurPanelStage = XDataCenter.FubenNewCharActivityManager.GetKoroLastOpenPanel() or XFubenNewCharConfig.KoroPanelType.Normal
    self.ActivityCfg = XFubenNewCharConfig.GetDataById(self.Id)
    self.ActivityEndTime = XFunctionManager.GetEndTimeByTimeId(self.ActivityCfg.TimeId)
    self:InitPanel()
end

function XUiFunbenKoroTutorial:OnEnable()
    self:CheckRedPoint()
    self:SwitchPanelStage(self.CurPanelStage)
    self:StartActivityTimer()
end

function XUiFunbenKoroTutorial:OnDisable()
    self:CloseActivityTimer()
end

function XUiFunbenKoroTutorial:InitPanel()
    --self.TxtActivityName.text = self.ActivityCfg.Name
    self.FubenGo = self.PanelStageRoot:LoadPrefab(self.ActivityCfg.FubenPrefab)
    self.FubenGo.gameObject:SetActiveEx(false)
    self.PanelStageKoro = XUiPanelFubenKoroStage.New(self, self.FubenGo, self.ActivityCfg, XFubenNewCharConfig.KoroPanelType.Teaching)
    self.FubenChallengeGo = self.PanelChallengeStageRoot:LoadPrefab(self.ActivityCfg.FubenChallengePrefab)
    self.FubenChallengeGo.gameObject:SetActiveEx(false)
    self.PanelStageKoroChallenge = XUiPanelFubenKoroStage.New(self, self.FubenChallengeGo, self.ActivityCfg, XFubenNewCharConfig.KoroPanelType.Challenge)
end

--按钮红点
function XUiFunbenKoroTutorial:CheckRedPoint()
    XRedPointManager.Check(self.RedPointBtnChallengeId)
    XRedPointManager.Check(self.RedPointBtnTeachingId)
    self.BtnChapter:ShowReddot(false)
end

--活动时间的定时器开启与关闭
function XUiFunbenKoroTutorial:StartActivityTimer()
    local now = XTime.GetServerNowTimestamp()
    self.TxtDay.text = XUiHelper.GetTime(self.ActivityEndTime - now, XUiHelper.TimeFormatType.ACTIVITY)
    self:CloseActivityTimer()

    self.TimerId = XScheduleManager.ScheduleForever(function()
        self:RefreshActivityTime()
    end, XScheduleManager.SECOND, 0)
end

function XUiFunbenKoroTutorial:RefreshActivityTime()
    local now = XTime.GetServerNowTimestamp()
    if now > self.ActivityEndTime then
        XUiManager.TipText("KoroCharacterActivityEnd")
        self:CloseActivityTimer()
        XLuaUiManager.RunMain()
        return
    end
    self.TxtDay.text = XUiHelper.GetTime(self.ActivityEndTime - now, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiFunbenKoroTutorial:CloseActivityTimer()
    if self.TimerId then
        XScheduleManager.UnSchedule(self.TimerId)
        self.TimerId = nil
    end
end

--切换到挑战界面或者教学关界面
function XUiFunbenKoroTutorial:SwitchPanelStage(panelStage)
    XDataCenter.FubenNewCharActivityManager.SetKoroLastOpenPanel(panelStage)
    if panelStage ~= XFubenNewCharConfig.KoroPanelType.Normal then
        self.PanelMain.gameObject:SetActiveEx(false)
        self.PanelSpine.gameObject:SetActiveEx(false)
        self.PanelRoot.gameObject:SetActiveEx(false)
        self.PanelEffect.gameObject:SetActiveEx(false)
        if panelStage == XFubenNewCharConfig.KoroPanelType.Teaching then
            self.PanelStageKoro:OnShow(panelStage)
        elseif panelStage == XFubenNewCharConfig.KoroPanelType.Challenge then
            self.PanelStageKoroChallenge:OnShow(panelStage)
        end
        self.CurPanelStage = panelStage
    else
        if self.PanelStageKoro:CheckCanClose() and self.PanelStageKoroChallenge:CheckCanClose() then
            self.PanelMain.gameObject:SetActiveEx(true)
            self.PanelSpine.gameObject:SetActiveEx(true)
            self.PanelRoot.gameObject:SetActiveEx(true)
            self.PanelEffect.gameObject:SetActiveEx(true)
            self.PanelStageKoro:OnHide()
            self.PanelStageKoroChallenge:OnHide()
            self.CurPanelStage = panelStage
            self:CheckRedPoint()
            XLuaUiManager.SetMask(true)
            self:PlayAnimation("AnimSwitch", function()
                XLuaUiManager.SetMask(false)
            end)
        end
    end
end

--按钮绑定事件
function XUiFunbenKoroTutorial:InitAutoScript()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnChapter.CallBack = function() self:OnBtnChapterClick() end
    self.BtnTeaching.CallBack = function() self:OnBtnTeachingClick() end
    self.BtnChallenge.CallBack = function() self:OnBtnChallengeClick() end
    self.BtnDetails.CallBack = function() self:OnBtnDetailsClick() end
    self.BtnCultivate.CallBack = function() self:OnBtnCultivateClick() end
    self.BtnObtain.CallBack = function() self:OnBtnObtainClick() end
end

function XUiFunbenKoroTutorial:OnBtnBackClick()
    if self.CurPanelStage == XFubenNewCharConfig.KoroPanelType.Normal then
        XDataCenter.FubenNewCharActivityManager.SetKoroLastOpenPanel(self.CurPanelStage)
        self:Close()
        return
    end
    self:SwitchPanelStage(XFubenNewCharConfig.KoroPanelType.Normal)
end

function XUiFunbenKoroTutorial:OnBtnMainUiClick()
    XDataCenter.FubenNewCharActivityManager.SetKoroLastOpenPanel(XFubenNewCharConfig.KoroPanelType.Normal)
    XLuaUiManager.RunMain()
end

function XUiFunbenKoroTutorial:OnBtnChapterClick()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipIdJZ)
end

function XUiFunbenKoroTutorial:OnBtnTeachingClick()
    self:SwitchPanelStage(XFubenNewCharConfig.KoroPanelType.Teaching)
end

function XUiFunbenKoroTutorial:OnBtnChallengeClick()
    self:SwitchPanelStage(XFubenNewCharConfig.KoroPanelType.Challenge)
end

function XUiFunbenKoroTutorial:OnBtnDetailsClick()
    XLuaUiManager.Open("UiCharacterDetail", self.ActivityCfg.CharacterId)
end

function XUiFunbenKoroTutorial:OnBtnCultivateClick()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipIdChar)
end

function XUiFunbenKoroTutorial:OnBtnObtainClick()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipIdDraw)
end

function XUiFunbenKoroTutorial:RefreshBtnChallengeRedDot(count)
    self.BtnChallenge:ShowReddot(count >= 0)
end

function XUiFunbenKoroTutorial:RefreshBtnTeachingRedDot(count)
    self.BtnTeaching:ShowReddot(count >= 0)
end
