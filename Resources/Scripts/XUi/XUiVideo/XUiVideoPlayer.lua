local XUiVideoPlayer = XLuaUiManager.Register(XLuaUi, "UiVideoPlayer")

function XUiVideoPlayer:OnAwake()
    self.VideoPlayerUgui.ActionEnded = handler(self, self.LoopPointReached)
    self.IsPause = false
    self.BtnAuto.CallBack = function() self:Pause() end
    self.BtnSkip.CallBack = function() self:Stop() end
end


function XUiVideoPlayer:OnStart(movieId, closeCb, needAuto, needSkip)
    self.MovieId = movieId
    self.CloseCb = closeCb
    if needAuto == nil then
        needAuto = true
    end
    if needSkip == nil then
        needSkip = true
    end
    local config = XVideoConfig.GetMovieById(self.MovieId)
    self.VideoPlayerUgui:SetVideoFromRelateUrl(config.VideoUrl)
    self.VideoPlayerUgui:Play()

    self.BtnAuto.gameObject:SetActiveEx(needAuto)
    self.BtnSkip.gameObject:SetActiveEx(needSkip)

    XDataCenter.VideoManager.SetVideoPlayer(self.VideoPlayerUgui)
end

function XUiVideoPlayer:OnDestroy()

    XDataCenter.VideoManager.Stop()

    if self.CloseCb then
        self.CloseCb()
    end
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