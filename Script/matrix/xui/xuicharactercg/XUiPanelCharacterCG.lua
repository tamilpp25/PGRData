---@class XUiPanelCharacterCG : XUiNode
---@field _IsPlayPerform boolean 是否播放CG结束/打断表现
---@field _IsReplaying boolean CG是否正在重新播放
local XUiPanelCharacterCG = XClass(XUiNode, "XUiPanelCharacterCG")

function XUiPanelCharacterCG:OnStart()
end

function XUiPanelCharacterCG:InitLoadVideoPlayerPrefab()
    if not XTool.UObjIsNil(self.VideoPlayer) then
        return
    end

    self.VideoPlayer = XDataCenter.VideoManager.LoadVideoPlayerUguiWithPrefab(self.VideoPlayerRoot)
    -- 目前CG的制作规格
    if not XTool.UObjIsNil(self.VideoPlayer) then
        self.VideoPlayer.AspectRatioFitterInst.aspectRatio = 2796 / 1290
        self.VideoPlayerRawImg = self.VideoPlayer:GetComponent(typeof(CS.UnityEngine.UI.RawImage))
        self.VideoPlayerRawImg.enabled = false
    end
end

function XUiPanelCharacterCG:OnEnable()
    self:InitLoadVideoPlayerPrefab()

    self:HideCGMask()
    -- 异形屏适配 延迟执行
    local safeAreaContentPane = self.Parent.Transform:Find("SafeAreaContentPane")
    if XTool.UObjIsNil(safeAreaContentPane) then
        XLog.Error("找不到SafeAreaContentPane节点 无法进行异形屏适配")
    else
        XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(safeAreaContentPane) then
                return
            end
            local offsetMax = safeAreaContentPane.offsetMax
            local offsetMin = safeAreaContentPane.offsetMin
            self.PanelVideo.offsetMax = Vector2(-offsetMax.x, -offsetMax.y)
            self.PanelVideo.offsetMin = Vector2(-offsetMin.x, -offsetMin.y)
        end, 1)
    end
    if self.Effect then
        self.Effect.gameObject:SetActiveEx(false)
    end
end

function XUiPanelCharacterCG:OnDisable()
    self._IsPlayPerform = false
    self._IsReplaying = false
    self:CloseClickMask()
end

function XUiPanelCharacterCG:OnDestroy()
    self:RemoveEffectTimer()
    self:RemoveReplayTimer()
    self:CloseClickMask()
end

--region Event

function XUiPanelCharacterCG:OnCGPlay()
    -- 等VideoPlay资源准备完毕 准备播放后才显示RawImage 否则界面上会有一瞬间显示灰色
    self.VideoPlayerRawImg.enabled = true
    self:CloseClickMask()
end

function XUiPanelCharacterCG:OnCGStop()
    if self._IsPlayPerform then
        self:PlayStopPerform()
    elseif not self._IsReplaying then
        self:HideCGMask()
    end
end

--endregion

function XUiPanelCharacterCG:PlayCG(id)
    self:InitLoadVideoPlayerPrefab()

    self:ShowCGMask() -- 加载CG资源需要一点时间 先打开黑色模板挡住场景
    self:Open()

    self.VideoPlayer:SetInfoByVideoId(id)
    self.VideoPlayerRawImg.enabled = false
    self.VideoPlayer:Prepare()

    self._IsPlayPerform = true
end

function XUiPanelCharacterCG:HideCG()
    self._IsPlayPerform = false
    self:StopCG()
    self:Close()
end

---@param isPerform boolean 是否播放CG停止特效
function XUiPanelCharacterCG:StopCG(isPerform, callBack)
    self:RemoveReplayTimer()
    self:CloseClickMask()

    if isPerform then
        self:PlayStopPerform(callBack)
        return
    end

    if self:IsCGPlaying() then
        self.VideoPlayer:Stop()
    end

    self:HideCGMask()

    if callBack then
        callBack()
    end
end

function XUiPanelCharacterCG:PlayStopPerform(callBack)
    if not self.Effect then
        XLog.Error("Effect节点不存在")
        return
    end
    if self:IsCGPlaying() then
        self.VideoPlayer:Pause()
    end

    self:RemoveEffectTimer()

    self._IsPlayPerform = false
    self.Effect.gameObject:SetActiveEx(false)
    self.Effect.gameObject:SetActiveEx(true)
    self:OpenClickMask() -- 播过场表现时屏蔽点击
    self._EffectTimer = XScheduleManager.ScheduleOnce(function()
        self.VideoPlayer:Stop()
        self:HideCGMask()
        self:CloseClickMask()
        self._IsPlayPerform = false
        if callBack then
            callBack()
        end
    end, 280)
end

function XUiPanelCharacterCG:IsCGShow()
    if XTool.UObjIsNil(self.VideoPlayer) then
        return false
    end

    return self.PanelVideo.gameObject.activeSelf
end

---当CG正在播放时返回True
---@return boolean
function XUiPanelCharacterCG:IsCGPlaying()
    if XTool.UObjIsNil(self.VideoPlayer) then
        return false
    end

    return self:IsCGShow() and self.VideoPlayer and self.VideoPlayer:IsPlaying()
end

---当CG正在加载或者播放时返回True
function XUiPanelCharacterCG:IsCGExist()
    local status = self:GetStatus()
    return self:IsCGShow() and (status ~= CS.CriWare.CriMana.Player.Status.Dechead and
            status ~= CS.CriWare.CriMana.Player.Status.Stop and
            status ~= CS.CriWare.CriMana.Player.Status.Error and
            status ~= CS.CriWare.CriMana.Player.Status.PlayEnd
        )
end

function XUiPanelCharacterCG:IsCGPause()
    return self:IsCGShow() and self.VideoPlayer:IsPaused()
end

function XUiPanelCharacterCG:ChangeCGState(pause)
    if self:IsCGPlaying() then
        if pause then
            self.VideoPlayer:Pause()
        else
            self.VideoPlayer:Resume()
        end
    end
end

function XUiPanelCharacterCG:ReplayCG()
    if not self:IsCGShow() then
        return
    end

    self._IsPlayPerform = false
    self._IsReplaying = true
    self:ShowCGMask()

    local fun = function()
        local status = self:GetStatus()
        if status == CS.CriWare.CriMana.Player.Status.Stop then
            self:OpenClickMask(1000) -- CG加载时屏蔽点击
            self._IsReplaying = false
        end
    end
    self.VideoPlayer.ActionStopped = function ()
        fun()
        self.VideoPlayer.ActionStopped = nil
    end

    self.VideoPlayer:RePlay()
    self._IsPlayPerform = true
end

function XUiPanelCharacterCG:RemoveEffectTimer()
    if self._EffectTimer then
        XScheduleManager.UnSchedule(self._EffectTimer)
        self._EffectTimer = nil
    end
end

function XUiPanelCharacterCG:RemoveReplayTimer()
    if self._ReplayTimer then
        XScheduleManager.UnSchedule(self._ReplayTimer)
        self._ReplayTimer = nil
    end
end

function XUiPanelCharacterCG:RemoveMaskTimer()
    if self._MaskTimer then
        XScheduleManager.UnSchedule(self._MaskTimer)
        self._MaskTimer = nil
    end
end

---在视频加载和播过场表现时屏蔽点击
---@param time number 加个保底 避免视频因为未知原因未播放时 屏蔽点击一直存在
function XUiPanelCharacterCG:OpenClickMask(time)
    XLuaUiManager.SetMask(true, "UiPanelCharacterCG")
    self:RemoveMaskTimer()
    if XTool.IsNumberValid(time) then
        self._MaskTimer = XScheduleManager.ScheduleOnce(function()
            self:CloseClickMask()
        end, time)
    end
end

function XUiPanelCharacterCG:CloseClickMask()
    self:RemoveMaskTimer()
    if XLuaUiManager.IsMaskShow("UiPanelCharacterCG") then
        XLuaUiManager.SetMask(false, "UiPanelCharacterCG")
    end
end

function XUiPanelCharacterCG:ShowCGMask()
    if self.CGMask then
        self.CGMask.gameObject:SetActiveEx(true)
    end
end

function XUiPanelCharacterCG:HideCGMask()
    if self.CGMask then
        self.CGMask.gameObject:SetActiveEx(false)
    end
end

function XUiPanelCharacterCG:GetStatus()
    if XTool.UObjIsNil(self.VideoPlayer) then
        return
    end

    return self.VideoPlayer.VideoPlayerInst.player.status
end

function XUiPanelCharacterCG:IsLanguagePreparing()
    return self.VideoPlayer.IsLanguagePreparing
end

return XUiPanelCharacterCG