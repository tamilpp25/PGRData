local XUiPlanetLoading = XLuaUiManager.Register(XLuaUi, "UiPlanetLoading")

function XUiPlanetLoading:OnAwake()
    self:InitObj()
end

function XUiPlanetLoading:OnStart(openCb, closeCb)
    self.OpenCb = openCb
    self.CloseCb = closeCb
    XDataCenter.PlanetManager.SceneOpen(XPlanetConfigs.SceneOpenReason.UiPlanetLoading)
end

function XUiPlanetLoading:OnEnable()
    self:PlayAnimationWithMask("Enable", function()
        self:PlayAnimation("Loop",nil,nil,CS.UnityEngine.Playables.DirectorWrapMode.Loop)
        if self.LoadingAnim.state ~= CS.Playable.PlayState.Playing and self.LoadingAnim.time <= self.LoadingAnim.duration then
            self.LoadingAnim.time = 0
            self.LoadingAnim:Play()
        end
        self:StartWaitLoading()
    end)
end

function XUiPlanetLoading:OnDisable()
end

function XUiPlanetLoading:OnDestroy()
    XDataCenter.PlanetManager.SceneRelease(XPlanetConfigs.SceneOpenReason.UiPlanetLoading)
end

function XUiPlanetLoading:InitObj()
    self.Timer = nil
    self.LoadingAnim = self.Transform:Find("Animation/Loading"):GetComponent("PlayableDirector")
end

function XUiPlanetLoading:StartWaitLoading()
    self:StopWaitLoading()
    local isInLoad = false
    self.Timer = XScheduleManager.ScheduleForever(function()
        if XDataCenter.PlanetManager.GetIsSceneLoad() then
            self:StopWaitLoading()
            --self.LoadingAnim.time = self.LoadingAnim.duration
            self:OnClose()
            return
        end
        if self.LoadingAnim.time > self.LoadingAnim.duration and not isInLoad then
            if self.OpenCb then
                self.OpenCb()
            end
            isInLoad = true
        else
            self.LoadingAnim.time = self.LoadingAnim.time + CS.UnityEngine.Time.deltaTime * 3
        end
    end, 0, 0)
end

function XUiPlanetLoading:StopWaitLoading()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
    end
    self.Timer = nil
end

function XUiPlanetLoading:OnClose()
    self:PlayAnimationWithMask("Disable", function()
        if self.CloseCb then
            self.CloseCb()
        end
    end)
end