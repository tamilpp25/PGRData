local XUiVideoPlayer = XLuaUiManager.Register(XLuaUi, "UiVideoPlayer")

function XUiVideoPlayer:OnAwake()
    self.VideoPlayerUgui.ActionEnded = handler(self, self.LoopPointReached)
    self.IsPause = false
    self.BtnAuto.CallBack = function() self:Pause() end
    self.BtnSkip.CallBack = function() self:Stop() end
    self.BtnMask.CallBack = function() self:OnClickBtnMask() end
    self.DisplayTime = 0
    self.DisplayTimeConfig = CS.XGame.ClientConfig:GetInt("UiVideoPlayerDisplayTime")
end


function XUiVideoPlayer:OnStart(movieId, closeCb, needAuto, needSkip)
    self.MovieId = movieId
    self.CloseCb = closeCb
    if needAuto == nil then
        needAuto = false
    end
    if needSkip == nil then
        needSkip = false
    end

    local config = XVideoConfig.GetMovieById(self.MovieId)
    if config.Width ~= 0 and config.Height ~= 0 then
        self.VideoPlayerUgui:SetAspectRatio(config.Width / config.Height)
    end

    local url = XDataCenter.UiPcManager.IsPc() and config.VideoUrlPc or config.VideoUrl
    self.VideoPlayerUgui:SetVideoFromRelateUrl(url)
    self.VideoPlayerUgui:Play()

    if XDataCenter.UiPcManager.IsPc() then
        self.BtnAuto.gameObject:SetActiveEx(true)
        self.BtnSkip.gameObject:SetActiveEx(true)
    else
        self.BtnAuto.gameObject:SetActiveEx(needAuto)
        self.BtnSkip.gameObject:SetActiveEx(needSkip)
    end

    XDataCenter.VideoManager.SetVideoPlayer(self.VideoPlayerUgui)
    self.TimerId = XScheduleManager.ScheduleForever(handler(self, self.OnTimer), XScheduleManager.SECOND, 0)
end

function XUiVideoPlayer:OnDestroy()

    XDataCenter.VideoManager.Stop()
    XScheduleManager.UnSchedule(self.TimerId)
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiVideoPlayer:OnTimer()
    if self.DisplayTime <= 0 then
        return
    end
    self.DisplayTime = self.DisplayTime - 1
    if not XDataCenter.UiPcManager.IsPc() then
        if self.DisplayTime <= 0 then
            self:PlayAnimation("UiDisable")
        end
    end
end

function XUiVideoPlayer:OnClickBtnMask()
    if not XDataCenter.UiPcManager.IsPc() then
        if self.DisplayTime <= 0 then
            self:PlayAnimation("UiEnable")
        end
    end
    self.DisplayTime = self.DisplayTimeConfig
end

function XUiVideoPlayer:LoopPointReached()
    XDataCenter.VideoManager.Stop()

    XScheduleManager.ScheduleOnce(function()
        self:Close()
    end, 0)
end


function XUiVideoPlayer:Stop()
    self.VideoPlayerUgui:Stop()
    self:Close()
end


function XUiVideoPlayer:Pause()
    self.IsPause = not self.IsPause
    if self.IsPause then
        self.VideoPlayerUgui:Pause()
    else
        self.VideoPlayerUgui:Resume()
    end
end