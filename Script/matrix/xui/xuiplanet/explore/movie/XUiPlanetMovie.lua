-- 行星剧情界面
local XUiPlanetMovie = XLuaUiManager.Register(XLuaUi, "UiPlanetMovie")

function XUiPlanetMovie:OnAwake()
    self:InitButton()
end

function XUiPlanetMovie:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnSkipDialog, self.OnBtnSkipDialogClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipClick)
end

function XUiPlanetMovie:OnStart(movieId, changeDialogCb, closeCb)
    self.MovieId = movieId
    self.ChangeDialogCb = changeDialogCb
    self.CloseCb = closeCb
    self.MovieInfo = XPlanetExploreConfigs.GetMovieInfoById(movieId)
    self.CurTalkIndex = 0
end

function XUiPlanetMovie:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_REQUEST_STOP_MOVIE, self.Close, self)
    self:OnBtnSkipDialogClick()
end

function XUiPlanetMovie:RefreshDialog()
    self.TxtName.text = self.MovieInfo[self.CurTalkIndex].Name
    self.Timer = XUiHelper.ShowCharByTypeAnimation(self.TxtWords, self.MovieInfo[self.CurTalkIndex].TalkText, 10, nil, function ()
        self.Timer = nil
    end)
end

-- 点击对话框 快速对话
function XUiPlanetMovie:OnBtnSkipDialogClick()
    -- 如果还在打字机就先播完打字机
    if self.Timer then
        self:StopTimer()
        self.TxtWords.text = self.MovieInfo[self.CurTalkIndex].TalkText
        return
    end

    -- 如果是最后一个对话内容 则直接关闭
    if self.CurTalkIndex >= #self.MovieInfo then
        self:Close()
        return
    end
    self.CurTalkIndex = self.CurTalkIndex + 1
    -- 切换后刷新
    self:RefreshDialog()
    if self.ChangeDialogCb then
        self.ChangeDialogCb(self.MovieInfo, self.CurTalkIndex)
    end
end

function XUiPlanetMovie:OnBtnSkipClick()
    self:Close()
end

function XUiPlanetMovie:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiPlanetMovie:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_REQUEST_STOP_MOVIE, self.Close, self)
end

function XUiPlanetMovie:OnDestroy()
    self:StopTimer()
    if self.CloseCb then
        self.CloseCb()
    end
end

