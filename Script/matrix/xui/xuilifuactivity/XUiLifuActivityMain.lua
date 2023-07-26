local XUiLifuActivityMain = XLuaUiManager.Register(XLuaUi,"UiLifuActivityMain")
local XUiPanelFubenStage = require("XUi/XUiNewChar/WeiLa/XUiPanelFubenWeiLaStage")

function XUiLifuActivityMain:OnStart(actId,isOpenSkin)
    self.Id = actId
    self.ActivityCfg = XFubenNewCharConfig.GetDataById(self.Id)
    self.ActivityEndTime = XFunctionManager.GetEndTimeByTimeId(self.ActivityCfg.TimeId)
    if not self.CurPanelStage then
        self.CurPanelStage = XDataCenter.FubenNewCharActivityManager.GetKoroLastOpenPanel() or XFubenNewCharConfig.KoroPanelType.Normal
    end
    self.IsFirstIn = true and self.CurPanelStage == XFubenNewCharConfig.KoroPanelType.Normal
    self.RedPointBtnChallengeId = XRedPointManager.AddRedPointEvent(self.BtnChallenge, self.RefreshBtnChallengeRedDot, self, {
        XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYCHALLENGERED,
    })
    self.RedPointBtnTeachingId = XRedPointManager.AddRedPointEvent(self.BtnTeaching, self.RefreshBtnTeachingRedDot, self, {
        XRedPointConditions.Types.CONDITION_KOROMCHARACTIVITYTEACHINGRED,
    })
    
    self:InitPanel()
    self:RegisterButtonClick()
    if isOpenSkin and self.CurPanelStage == XFubenNewCharConfig.KoroPanelType.Normal then
        self:OnClickBtnPainting()
    else
        self:SwitchPanelStage(self.CurPanelStage)
    end
end

function XUiLifuActivityMain:OnEnable()
    self.EffectStandChange.gameObject:SetActiveEx(false)
    self.EffectStandBack.gameObject:SetActiveEx(false)
    self:CheckRedPoint()
    self:StartTimer()
end

function XUiLifuActivityMain:OnDisable()
    self:StopTimer()
end

function XUiLifuActivityMain:OnDestroy()
    XDataCenter.FubenNewCharActivityManager.SetKoroLastOpenPanel(XFubenNewCharConfig.KoroPanelType.Normal)
end

function XUiLifuActivityMain:InitPanel()
    self.FubenGo = self.PanelStageRoot:LoadPrefab(self.ActivityCfg.FubenPrefab)
    self.FubenGo.gameObject:SetActiveEx(false)
    self.PanelStageKoro = XUiPanelFubenStage.New(self, self.FubenGo, self.ActivityCfg, XFubenNewCharConfig.KoroPanelType.Teaching)
    self.FubenChallengeGo = self.PanelChallengeStageRoot:LoadPrefab(self.ActivityCfg.FubenChallengePrefab)
    self.FubenChallengeGo.gameObject:SetActiveEx(false)
    self.PanelStageKoroChallenge = XUiPanelFubenStage.New(self, self.FubenChallengeGo, self.ActivityCfg, XFubenNewCharConfig.KoroPanelType.Challenge)
    local root = self.UiModelGo.transform
    self.SkinAnim = root:FindTransform("QieHuan1"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    self.MainAnim = root:FindTransform("QieHuan2"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    self.DetailAnim = root:FindTransform("BgQieHuan1"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    self.DetailBackAnim = root:FindTransform("BgQieHuan2"):GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    self.EffectStandChange = root:FindTransform("Effect")
    self.EffectStandBack = root:FindTransform("Effect2")
end

function XUiLifuActivityMain:RegisterButtonClick()
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    self.BtnProfile.CallBack = function() self:OnClickBtnProfile() end
    self.BtnObtain.CallBack = function() self:OnClickBtnObtain() end
    self.BtnTeaching.CallBack = function() self:OnClickBtnTeaching() end
    self.BtnChallenge.CallBack = function() self:OnClickBtnChallenge() end
    self.BtnChapter.CallBack = function() self:OnClickBtnChapter() end
    self.BtnCultivate.CallBack = function() self:OnClickBtnCultivate() end
    self.BtnPainting.CallBack = function() self:OnClickBtnPainting() end
end

function XUiLifuActivityMain:StartTimer()
    local now = XTime.GetServerNowTimestamp()
    self.TxtDay.text = XUiHelper.GetTime(self.ActivityEndTime - now, XUiHelper.TimeFormatType.ACTIVITY)
    self:StopTimer()

    self.TimerId = XScheduleManager.ScheduleForever(function()
        self:RefreshActivityTime()
    end, XScheduleManager.SECOND, 0)
end

function XUiLifuActivityMain:StopTimer()
    if self.TimerId then
        XScheduleManager.UnSchedule(self.TimerId)
        self.TimerId = nil
    end
end

function XUiLifuActivityMain:RefreshActivityTime()
    local now = XTime.GetServerNowTimestamp()
    if now > self.ActivityEndTime then
        XUiManager.TipText("KoroCharacterActivityEnd")
        self:StopTimer()
        XScheduleManager.ScheduleOnce(function()
            --XLuaUiManager.RunMain()
        end,500)
        return
    end
    self.TxtDay.text = XUiHelper.GetTime(self.ActivityEndTime - now, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiLifuActivityMain:SwitchPanelStage(panelStage)
    XDataCenter.FubenNewCharActivityManager.SetKoroLastOpenPanel(panelStage)
    if panelStage ~= XFubenNewCharConfig.KoroPanelType.Normal then
        self.PanelMain.gameObject:SetActiveEx(false)
        if panelStage == XFubenNewCharConfig.KoroPanelType.Teaching then
            self.PanelStageKoro:OnShow(panelStage)
            self.DetailAnim:Play()
        elseif panelStage == XFubenNewCharConfig.KoroPanelType.Challenge then
            self.PanelStageKoroChallenge:OnShow(panelStage)
            self.DetailAnim:Play()
        elseif panelStage == XFubenNewCharConfig.KoroPanelType.Skin then
            XLuaUiManager.Open("UiLifuActivitySingleDetail", self.ActivityCfg.SkinTrialStageId, self.ActivityCfg.SkinDrawSkipId)
            self.SkinAnim.gameObject:PlayTimelineAnimation(function() 
                XLuaUiManager.SetMask(false)
            end,function()
                XLuaUiManager.SetMask(true)
            end,CS.UnityEngine.Playables.DirectorWrapMode.None)
        end
        self.CurPanelStage = panelStage
    else
        if self.PanelStageKoro:CheckCanClose() and self.PanelStageKoroChallenge:CheckCanClose() then
            self.PanelMain.gameObject:SetActiveEx(true)
            self.PanelStageKoro:OnHide()
            self.PanelStageKoroChallenge:OnHide()

            if XLuaUiManager.IsUiShow("UiLifuActivitySingleDetail") then
                XLuaUiManager.Close("UiLifuActivitySingleDetail")
                self.MainAnim.gameObject:PlayTimelineAnimation(function()
                    XLuaUiManager.SetMask(false)
                end,function()
                    XLuaUiManager.SetMask(true)
                end,CS.UnityEngine.Playables.DirectorWrapMode.None)            
            else
                if not self.IsFirstIn then
                    self.DetailBackAnim:Play()              
                end
            end
            self.IsFirstIn = false
            self.CurPanelStage = panelStage
            self:CheckRedPoint()
        end
    end
end

function XUiLifuActivityMain:OnClickBtnProfile()
    XLuaUiManager.Open("UiCharacterDetail", self.ActivityCfg.CharacterId)
end

function XUiLifuActivityMain:OnClickBtnCultivate()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipIdChar)
end

function XUiLifuActivityMain:OnClickBtnObtain()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipIdDraw)
end

function XUiLifuActivityMain:OnClickBtnTeaching()
    self:SwitchPanelStage(XFubenNewCharConfig.KoroPanelType.Teaching)
end

function XUiLifuActivityMain:OnClickBtnChallenge()
    self:SwitchPanelStage(XFubenNewCharConfig.KoroPanelType.Challenge)
end

function XUiLifuActivityMain:OnClickBtnBack()
    if self.CurPanelStage == XFubenNewCharConfig.KoroPanelType.Normal then
        XDataCenter.FubenNewCharActivityManager.SetKoroLastOpenPanel(self.CurPanelStage)
        self:Close()
        return
    end
    self.EffectStandChange.gameObject:SetActiveEx(false)
    self.EffectStandBack.gameObject:SetActiveEx(false)
    self:SwitchPanelStage(XFubenNewCharConfig.KoroPanelType.Normal)
end

function XUiLifuActivityMain:OnClickBtnMainUi()
    XDataCenter.FubenNewCharActivityManager.SetKoroLastOpenPanel(XFubenNewCharConfig.KoroPanelType.Normal)
    XLuaUiManager.RunMain()
end

function XUiLifuActivityMain:OnClickBtnChapter()
    XFunctionManager.SkipInterface(self.ActivityCfg.SkipIdJZ)
end

function XUiLifuActivityMain:OnClickBtnPainting()
    self:SwitchPanelStage(XFubenNewCharConfig.KoroPanelType.Skin)
end

function XUiLifuActivityMain:CheckRedPoint()
    XRedPointManager.Check(self.RedPointBtnChallengeId)
    XRedPointManager.Check(self.RedPointBtnTeachingId)
    self.BtnChapter:ShowReddot(false)
end

function XUiLifuActivityMain:RefreshBtnChallengeRedDot(count)
    self.BtnChallenge:ShowReddot(count >= 0)
end

function XUiLifuActivityMain:RefreshBtnTeachingRedDot(count)
    self.BtnTeaching:ShowReddot(count >= 0)
end

function XUiLifuActivityMain:OnReleaseInst()
    return self.CurPanelStage
end

function XUiLifuActivityMain:OnResume(currPanelStage)
    self.CurPanelStage = currPanelStage
end

return XUiLifuActivityMain