local XUiVideoPlayer = XLuaUiManager.Register(XLuaUi, "UiVideoPlayer")
local XInputManager = CS.XInputManager
local XOperationType = CS.XInputManager.XOperationType
local XOperationClickType = CS.XOperationClickType
local ToInt32 = CS.System.Convert.ToInt32
local XInputMapId = CS.XInputMapId

function XUiVideoPlayer:OnAwake()
    if XDataCenter.UiPcManager.IsPc() then
        self.BtnAuto = self.Transform:Find("SafeAreaContentPane/BtnAuto/BtnAutoPC"):GetComponent("XUiButton")
        self.BtnSkip = self.Transform:Find("SafeAreaContentPane/BtnSkip/BtnSkipPC"):GetComponent("XUiButton")

        self.BtnAuto:GetComponentInChildren(typeof(CS.XUiPc.XUiPcCustomKey)):SetKey(XInputMapId.Video, XInputMapId.System, ToInt32(CS.XVideoOperationKey.Pause), XOperationType.Video)
        self.BtnSkip:GetComponentInChildren(typeof(CS.XUiPc.XUiPcCustomKey)):SetKey(XInputMapId.Video, XInputMapId.System, ToInt32(CS.XVideoOperationKey.Stop), XOperationType.Video)
    end
    
    self.VideoPlayerUgui.ActionEnded = handler(self, self.LoopPointReached)
    self.IsPause = false
    self.BtnAuto.CallBack = function() self:Pause() end
    self.BtnSkip.CallBack = function() self:Stop() end
    self.BtnMask.CallBack = function() self:OnClickBtnMask() end
    self.DisplayTime = 0
    self.DisplayTimeConfig = CS.XGame.ClientConfig:GetInt("UiVideoPlayerDisplayTime")
    self.OnClick = function(inputDevice, key, type, operationType)
        if type == XOperationClickType.KeyDown then
            if key == ToInt32(CS.XVideoOperationKey.Pause) then
                self:Pause()
                if self.IsPause then
                    self.BtnAuto.ButtonState = CS.UiButtonState.Select
                else
                    self.BtnAuto.ButtonState = CS.UiButtonState.Normal
                end
            end
            if key == ToInt32(CS.XVideoOperationKey.Stop) then
                self:Stop()
            end     
        end
    end
end

-- data传值支持以下两种方式
--  id（配置VideoConfig.tab中id）
--  {VideoUrl, Width, Height}
function XUiVideoPlayer:OnStart(data, closeCb, needAuto, needSkip)
    self.CloseCb = closeCb
    --暂时用不到这个功能
    --if needAuto == nil then
    --    needAuto = false
    --end
    --if needSkip == nil then
    --    needSkip = false
    --end

    local movieId = data
    local videoUrl
    local width = 0
    local height = 0

    if type(data) == "table" then
        videoUrl = data.VideoUrl
        self.VideoPlayerUgui:SetVideoUrl(videoUrl)
    else
        local config = XVideoConfig.GetMovieById(movieId)
        width = config.Width
        height = config.Height
        self.VideoPlayerUgui:SetInfoByVideoId(movieId)
    end

    self.VideoPlayerUgui:Play()
    self.BtnAuto.gameObject:SetActiveEx(true)
    self.BtnSkip.gameObject:SetActiveEx(true)

    self.TimerId = XScheduleManager.ScheduleForever(handler(self, self.OnTimer), XScheduleManager.SECOND, 0)
end

function XUiVideoPlayer:OnEnable()
    XInputManager.SetCurInputMap(XOperationType.Video)
    XInputManager.RegisterOnClick(XOperationType.Video, self.OnClick)
end

function XUiVideoPlayer:OnDisable()
    XInputManager.UnregisterOnClick(XOperationType.Video, self.OnClick)
    XInputManager.SetCurInputMap(XInputManager.BeforeInputMapID)
end

function XUiVideoPlayer:OnDestroy()
    if self.VideoPlayerUgui then
        self.VideoPlayerUgui:Stop()
    end
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
    if self.DisplayTime <= 0 then
        self:PlayAnimation("UiDisable")
    end
end

function XUiVideoPlayer:OnClickBtnMask()
    if self.DisplayTime <= 0 then
        self:PlayAnimation("UiEnable")
    end
    self.DisplayTime = self.DisplayTimeConfig
end

function XUiVideoPlayer:LoopPointReached()
    self.VideoPlayerUgui:Stop()

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