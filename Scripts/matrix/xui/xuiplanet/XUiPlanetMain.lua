local XUiPlanetMain = XLuaUiManager.Register(XLuaUi, "UiPlanetMain")

function XUiPlanetMain:OnAwake()
    self:AddBtnClickListener()
end

function XUiPlanetMain:OnStart()
    XDataCenter.PlanetManager.CloseLoading()
    if not XDataCenter.PlanetManager.CheckMainIsExit() then
        XDataCenter.PlanetManager.ResumeMainScene(function()
            XDataCenter.PlanetManager.GetPlanetMainScene():UpdateCameraInMain()
        end)
    end
    self.ViewModel = XDataCenter.PlanetManager.GetViewModel()

    XDataCenter.PlanetManager.SceneOpen(XPlanetConfigs.SceneOpenReason.UiPlanetMain)
    self:BindViewModelPropertiesToObj(XDataCenter.PlanetManager.GetStageData(), function()
        self:RefreshGameBtn()
    end, "_StageId")
end

function XUiPlanetMain:OnEnable()
    self:PlayAnimationWithMask("Enable", function()
        self:PlayAnimation("Loop",nil,nil,CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)
    self.PlanetMainScene = XDataCenter.PlanetManager.GetPlanetMainScene()
    self.PlanetMainScene:UpdateCameraInMain()
    self.PlanetMainScene:ResetTeam()
    self.TimeRefreshTimer = XScheduleManager.ScheduleForever(handler(self, self.RefreshTime), XScheduleManager.SECOND, 0)

    self:RefreshTime()
    self:RefreshGameBtn()
    self:RefreshTalentBtn()
    self:RefreshBtnRedpoint()
end

function XUiPlanetMain:OnDisable()
    self:StopRefreshTime()
end

function XUiPlanetMain:OnRelease()
    self.Super.OnRelease(self)
    XDataCenter.PlanetManager.OnRelease()
end

function XUiPlanetMain:OnDestroy()
    XDataCenter.PlanetManager.SceneRelease(XPlanetConfigs.SceneOpenReason.UiPlanetMain)
end


--region UI刷新
function XUiPlanetMain:RefreshGameBtn()
    if not self.ViewModel then
        self.BtnEnter1.gameObject:SetActiveEx(true)
        self.BtnEnter2.gameObject:SetActiveEx(false)
        return
    end
    self.BtnEnter1.gameObject:SetActiveEx(not XDataCenter.PlanetManager.IsInGame())
    self.BtnEnter2.gameObject:SetActiveEx(XDataCenter.PlanetManager.IsInGame())
end

function XUiPlanetMain:RefreshTalentBtn()
    self.BtnHome:SetDisable(not self.ViewModel:CheckStageIsPass(XPlanetConfigs.GetTalentUnLockStage()))
end

function XUiPlanetMain:RefreshBtnRedpoint()
    -- 必须要先请求商店信息 才能检测红点。请求前先判断能否获取信息
    XDataCenter.PlanetManager.RefreshShopInfo(function ()
        self.BtnShop:ShowReddot(XDataCenter.PlanetManager.CheckShopRedPoint())
    end, true)
    self.BtnTask:ShowReddot(XDataCenter.PlanetManager.CheckTaskRedPoint())
    self.BtnHome:ShowReddot(XDataCenter.PlanetManager.CheckTalentRedPoint())
    self.BtnEnter1:ShowReddot(XDataCenter.PlanetManager.CheckChapterOpenRedPoint())
    self.BtnEnter2:ShowReddot(XDataCenter.PlanetManager.CheckChapterOpenRedPoint())
end

function XUiPlanetMain:RefreshTime()
    local endTime = self.ViewModel:GetEndTime()
    local nowTime = XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.PLANET_RUNNING)
end

function XUiPlanetMain:StopRefreshTime()
    if self.TimeRefreshTimer then
        XScheduleManager.UnSchedule(self.TimeRefreshTimer)
    end
    self.TimeRefreshTimer = nil
end
--endregion


--region 按钮绑定
function XUiPlanetMain:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnTask, self.OnBtnTaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnShop, self.OnBtnShopClick)
    XUiHelper.RegisterClickEvent(self, self.BtnHome, self.OnBtnHomeClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter1, self.OnBtnStartGameClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter2, self.OnBtnContinueGameClick)

    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, XPlanetConfigs.GetHelpKey())
end

function XUiPlanetMain:OnBtnShopClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        return
    end

    XDataCenter.PlanetManager.RefreshShopInfo(function ()
        XLuaUiManager.Open("UiPlanetPropertyShop")
    end)
end

function XUiPlanetMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiPlanetPropertyTask")
end

function XUiPlanetMain:OnBtnHomeClick()
    if self.ViewModel:CheckStageIsPass(XPlanetConfigs.GetTalentUnLockStage()) then
        XLuaUiManager.Open("UiPlanetHomeland")
    else
        local stageName = XPlanetStageConfigs.GetStageFullName(XPlanetConfigs.GetTalentUnLockStage())
        XUiManager.TipError(XUiHelper.GetText("PlanetRunningTalentCardLock", stageName))
    end
end

function XUiPlanetMain:OnBtnStartGameClick()
    XDataCenter.PlanetManager.ClearChapterOpenRedPoint()
    XLuaUiManager.Open("UiPlanetChapter")
end

function XUiPlanetMain:OnBtnContinueGameClick()
    XDataCenter.PlanetManager.ClearChapterOpenRedPoint()
    XDataCenter.PlanetManager.ContinueStage("UiPlanetBattleMain")
end
--endregion