local DefaultRoleIcon = CS.XGame.ClientConfig:GetString("TRPGNotTargetDefaultRoleIcon")
local Second = 500
local TRPGPanelTaskEnableTime = CS.XGame.ClientConfig:GetFloat("TRPGPanelTaskEnableTime")
local TRPGPanelTaskDisableTime = CS.XGame.ClientConfig:GetFloat("TRPGPanelTaskDisableTime")
local CSXScheduleManagerScheduleForever = XScheduleManager.ScheduleForever
local CSXScheduleManagerUnSchedule = XScheduleManager.UnSchedule
local PlayAnimaState = {
    Stop = 0,
    AnimaOne = 1,
    AnimaTwo = 2,
    AnimaThree = 3,
    AnimaFour = 4,
    ShowNewPanel = 5
}

--当前的任务引导
local XUiTRPGPanelTask = XClass(nil, "XUiTRPGPanelTask")

function XUiTRPGPanelTask:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.EndTimeSecond = 0
    self.CurrPlayAnimaState = PlayAnimaState.Stop
    self.IsPlaying = false
    self.PlayAnimaPauseTime = 0     --动画播完一个后等待一段时间再播下一个

    self:InitUi()
    self:AutoAddListener()
    self:Refresh()
end

function XUiTRPGPanelTask:AddEventListeners()
    XEventManager.AddEventListener(XEventId.EVENT_TRPG_UPDATE_TARGET, self.Refresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_MOVIE_BEGIN, self.SetNewTargetTime, self)
    XEventManager.AddEventListener(XEventId.EVENT_MOVIE_END, self.Refresh, self)
end

function XUiTRPGPanelTask:Delete()
    XDataCenter.TRPGManager.ClearNewTargetTime()
end

function XUiTRPGPanelTask:OnEnable()
    self.RootUi:PlayAnimation("PanelTaskEnable")
    self:AddEventListeners()
    self:Refresh()
end

function XUiTRPGPanelTask:OnDisable()
    self:RePlayAnima()
    XEventManager.RemoveEventListener(XEventId.EVENT_TRPG_UPDATE_TARGET, self.Refresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MOVIE_BEGIN, self.SetNewTargetTime, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MOVIE_END, self.Refresh, self)
end

function XUiTRPGPanelTask:InitUi()
    self.Text = XUiHelper.TryGetComponent(self.Transform, "PanelNormal/Text", "Text")
    self.Btn = XUiHelper.TryGetComponent(self.Transform, "Btn", "XUiButton")
    self.TxtTask = XUiHelper.TryGetComponent(self.Transform, "PanelNormal/TxtTask", "Text")
    self.RImgIcon = XUiHelper.TryGetComponent(self.Transform, "PanelNormal/RImgIcon", "RawImage")
    self.ImgIcon = XUiHelper.TryGetComponent(self.Transform, "PanelNormal/Text/ImgIcon", "Image")
    self.ImgEmpty = XUiHelper.TryGetComponent(self.Transform, "PanelNormal/ImgEmpty")
    self.TxtNone = XUiHelper.TryGetComponent(self.Transform, "PanelNormal/ImgEmpty/TxtNone", "Text")
    self.PanelNew = XUiHelper.TryGetComponent(self.Transform, "PanelNormal/PanelNew")
    self.Effect = XUiHelper.TryGetComponent(self.Transform, "Effect")
    self.PanelNormal = XUiHelper.TryGetComponent(self.Transform, "PanelNormal")
    self.PanelComplete = XUiHelper.TryGetComponent(self.Transform, "PanelComplete")

    if self.PanelNew then
        self.PanelNew.gameObject:SetActiveEx(false)
    end
end

function XUiTRPGPanelTask:AutoAddListener()
    if self.Btn then
        XUiHelper.RegisterClickEvent(self, self.Btn, self.OnBtnTaskClick)
    end
end

--isNotPlayNewAnima：XUiTRPGTaskTip主动切换目标不播放新目标动画
function XUiTRPGPanelTask:Refresh(isNotPlayNewAnima)
    if self:CheckStopRefresh() then return end

    local currTargetLinkId = XDataCenter.TRPGManager.GetCurrTargetLinkId()
    local targetLinkIsFinish = XDataCenter.TRPGManager.GetTargetLinkIsFinish(currTargetLinkId)
    local currTargetId = XDataCenter.TRPGManager.GetCurrTargetId()
    if self.Text then
        if targetLinkIsFinish then
            self.Text.text = ""
        else
            self.Text.text = XTRPGConfigs.GetTargetName(currTargetId)
        end
    end

    local targetDesc = XTRPGConfigs.GetTargetDesc(currTargetId)
    if self.TxtTask then
        if targetLinkIsFinish then
            self.TxtTask.text = ""
        else
            self.TxtTask.text = targetDesc
        end
    end

    if self.ImgEmpty then
        if targetLinkIsFinish then
            if self.TxtNone then
                self.TxtNone.text = targetDesc
            end
            self.ImgEmpty.gameObject:SetActiveEx(true)
        else
            self.ImgEmpty.gameObject:SetActiveEx(false)
        end
    end

    --角色头像
    if self.RImgIcon then
        local areaIconPath = XTRPGConfigs.GetTargetAreaIcon(currTargetId)
        if areaIconPath and "" ~= areaIconPath then
            self.RImgIcon:SetRawImage(areaIconPath)
        else
            self.RImgIcon:SetRawImage(DefaultRoleIcon)
        end
    end

    --卡牌图标
    if self.ImgIcon and self.RootUi then
        local cardIconPath = XTRPGConfigs.GetTargetCardIcon(currTargetId)
        if cardIconPath then
            self.RootUi:SetUiSprite(self.ImgIcon, cardIconPath)
            self.ImgIcon.gameObject:SetActiveEx(true)
        else
            self.ImgIcon.gameObject:SetActiveEx(false)
        end
    end

    self:RefreshPanelNew(isNotPlayNewAnima)
end

function XUiTRPGPanelTask:RefreshPanelNew(isNotPlayNewAnima)
    local isPlayNewAnima, endTimeSecond = self:GetIsPlayNewAnima()
    if isPlayNewAnima and not isNotPlayNewAnima then
        self:PlayNewAnima(endTimeSecond)
    end
end

function XUiTRPGPanelTask:PlayNewAnima(endTimeSecond)
    if self:CheckStopRefresh() then
        return
    end

    self:RePlayAnima()
    self.Timer = CSXScheduleManagerScheduleForever(function()
        self:RefreshNew(endTimeSecond)
    end, Second, 0)
    self:PlayOneAnima()
end

function XUiTRPGPanelTask:RefreshNew(endTimeSecond)
    if self.IsPlaying then
        return
    end

    local nowTime = XTime.GetServerNowTimestamp()
    if nowTime < self.PlayAnimaPauseTime then
        return
    end

    if self.CurrPlayAnimaState == PlayAnimaState.AnimaTwo then
        self:PlayTwoAnima()
    elseif self.CurrPlayAnimaState == PlayAnimaState.AnimaThree then
        self:PlayThreeAnima()
    elseif self.CurrPlayAnimaState == PlayAnimaState.AnimaFour then
        self:PlayFourAnima()
    elseif self.CurrPlayAnimaState == PlayAnimaState.ShowNewPanel then
        self:RefreshNewTag(endTimeSecond)
    end
end

function XUiTRPGPanelTask:PlayOneAnima()
    if self:CheckStopRefresh() then
        return
    end
    if self.RootUi then
        self:SetIsPlaying(true)
        self.RootUi:PlayAnimation("PanelTaskDisable", function()
            self:SetIsPlaying(false)
            self:SetCurrPlayAnimaState(PlayAnimaState.AnimaTwo)
        end)
    end
end

function XUiTRPGPanelTask:PlayTwoAnima()
    if self:CheckStopRefresh() then
        return
    end
    self:PanelNormalSwitchComplete(true)
    self:ShowEffect(true)
    if self.RootUi then
        self:SetIsPlaying(true)
        self.RootUi:PlayAnimation("PanelTaskEnable", function()
            self:SetAnimaPauseTime(TRPGPanelTaskEnableTime)
            self:SetIsPlaying(false)
            self:SetCurrPlayAnimaState(PlayAnimaState.AnimaThree)
        end)
    end
end

function XUiTRPGPanelTask:PlayThreeAnima()
    if self:CheckStopRefresh() then
        return
    end

    if self.RootUi then
        self:SetIsPlaying(true)
        self.RootUi:PlayAnimation("PanelTaskDisable", function()
            self:SetAnimaPauseTime(TRPGPanelTaskDisableTime)
            self:ShowEffect(false)
            self:SetIsPlaying(false)
            self:SetCurrPlayAnimaState(PlayAnimaState.AnimaFour)
        end)
    end
end

function XUiTRPGPanelTask:PlayFourAnima()
    if self:CheckStopRefresh() then
        return
    end
    if self.RootUi then
        self:PanelNormalSwitchComplete(false)
        self:ShowEffect(true)
        self:SetCurrPlayAnimaState(PlayAnimaState.ShowNewPanel)
        self.RootUi:PlayAnimation("PanelTaskEnable")
    end
end

function XUiTRPGPanelTask:GetIsPlayNewAnima()
    self.EndTimeSecond = XDataCenter.TRPGManager.GetTaskPanelNewShowTime()
    local newTargetTime = XDataCenter.TRPGManager.GetNewTargetTime()
    local now = XTime.GetServerNowTimestamp()
    local endTimeSecond = newTargetTime > 0 and newTargetTime + now or self.EndTimeSecond
    return now < endTimeSecond, endTimeSecond
end

function XUiTRPGPanelTask:RefreshNewTag(endTimeSecond)
    local now = XTime.GetServerNowTimestamp()
    if now >= endTimeSecond then
        self:ShowNew(false)
        self:StopTimer()

        XDataCenter.TRPGManager.ClearNewTargetTime()
        return
    end
    self:ShowNew(true)
end

function XUiTRPGPanelTask:StopTimer()
    if self.Timer then
        CSXScheduleManagerUnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiTRPGPanelTask:OnBtnTaskClick()
    XLuaUiManager.Open("UiTRPGTaskTip")
end

function XUiTRPGPanelTask:SetNewTargetTime()
    self:StopTimer()
    local nowTime = XTime.GetServerNowTimestamp()
    if nowTime < self.EndTimeSecond then
        XDataCenter.TRPGManager.SetNewTargetTime(self.EndTimeSecond - nowTime)
    end
    self:ShowNew(false)
end

function XUiTRPGPanelTask:ShowNew(isShow)
    if self.PanelNew then
        self.PanelNew.gameObject:SetActiveEx(isShow)
    end
    self:ShowEffect(isShow)
end

function XUiTRPGPanelTask:ShowEffect(isShow)
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(isShow)
    end
end

function XUiTRPGPanelTask:CheckStopRefresh()
    if XTool.UObjIsNil(self.GameObject) or not self.GameObject.activeInHierarchy or XDataCenter.MovieManager.IsPlayingMovie() then
        self:RePlayAnima()
        return true
    end
    return false
end

function XUiTRPGPanelTask:PanelNormalSwitchComplete(isShowComplete)
    if self.PanelNormal then
        self.PanelNormal.gameObject:SetActiveEx(not isShowComplete)
    end
    if self.PanelComplete then
        self.PanelComplete.gameObject:SetActiveEx(isShowComplete)
    end
end

function XUiTRPGPanelTask:SetCurrPlayAnimaState(animaState)
    self.CurrPlayAnimaState = animaState
end

function XUiTRPGPanelTask:SetIsPlaying(isPlaying)
    self.IsPlaying = isPlaying
end

function XUiTRPGPanelTask:SetAnimaPauseTime(pauseTime)
    local nowTime = XTime.GetServerNowTimestamp()
    self.PlayAnimaPauseTime = nowTime + pauseTime
end

function XUiTRPGPanelTask:RePlayAnima()
    self:StopTimer()
    self:ShowNew(false)
    self:SetCurrPlayAnimaState(PlayAnimaState.Stop)
    self:SetIsPlaying(false)
    self:PanelNormalSwitchComplete(false)
end

return XUiTRPGPanelTask