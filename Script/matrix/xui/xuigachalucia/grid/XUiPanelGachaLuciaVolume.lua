---@class XUiPanelGachaLuciaVolume : XUiNode 露西亚卡池音量调节
---@field Parent XUiGachaLuciaMain
local XUiPanelGachaLuciaVolume = XClass(XUiNode, "XUiPanelGachaLuciaVolume")

local XAudioManager = CS.XAudioManager
local Key = "GachaLuciaVolumeInit"

function XUiPanelGachaLuciaVolume:OnStart()
    self._YellowValue = tonumber(XGachaConfigs.GetClientConfig("LuciaVolumeValue"))
    self._InitWaitTime = tonumber(XGachaConfigs.GetClientConfig("LuciaVolumeInitWaitTime"))
    self._ClickWaitTime = tonumber(XGachaConfigs.GetClientConfig("LuciaVolumeClickWaitTime"))
    
    self.BtnActiveVolume.CallBack = handler(self, self.OnBtnActiveVolumeClick)
    XUiHelper.RegisterSliderChangeEvent(self, self.Slider, self.OnSlideValueChanged)
end

function XUiPanelGachaLuciaVolume:OnDestroy()
    self:RemoveTimer()
end

function XUiPanelGachaLuciaVolume:OnSlideValueChanged()
    XAudioManager.Mute(false)
    XAudioManager.ChangeMusicVolume(self.Slider.value)
    XAudioManager.ChangeSFXVolume(self.Slider.value)
    XAudioManager.ChangeVoiceVolume(self.Slider.value)

    self:ChangeTipColorImg()
    self:TweenClick()
end

function XUiPanelGachaLuciaVolume:ChangeTipColorImg()
    if not CS.XAudioManager.CheckAudioCanPlayLevel() then
        self.ImgRed.gameObject:SetActiveEx(true)
        self.ImgYellow.gameObject:SetActiveEx(false)
        self.ImgGreen.gameObject:SetActiveEx(false)
    elseif self.Slider.value <= self._YellowValue then
        self.ImgRed.gameObject:SetActiveEx(false)
        self.ImgYellow.gameObject:SetActiveEx(true)
        self.ImgGreen.gameObject:SetActiveEx(false)
    else
        self.ImgRed.gameObject:SetActiveEx(false)
        self.ImgYellow.gameObject:SetActiveEx(false)
        self.ImgGreen.gameObject:SetActiveEx(true)
    end
end

function XUiPanelGachaLuciaVolume:PlayStart()
    self:Open()

    local musicVolume = XLuaAudioManager.GetCategoriesVolumeByType(XLuaAudioManager.SoundType.Music)
    local sfxVolume = XLuaAudioManager.GetCategoriesVolumeByType(XLuaAudioManager.SoundType.SFX)
    local voiceVolume = XLuaAudioManager.GetCategoriesVolumeByType(XLuaAudioManager.SoundType.Voice)
    self.Slider.value = math.min(musicVolume, sfxVolume, voiceVolume)
    self:ChangeTipColorImg()

    local isInit = not XSaveTool.GetData(Key)
    if isInit then
        self:ShowSlider()
        self:TweenInit()
    else
        self.PanelSlider.gameObject:SetActiveEx(false)
    end

    XSaveTool.SaveData(Key, true)
end

function XUiPanelGachaLuciaVolume:PlayEnd()
    -- 重置用户最后设置的音量
    XLuaAudioManager.ResetSystemAudioVolume()
    self:HideAll(true)
end

function XUiPanelGachaLuciaVolume:HideAll(isTween)
    self:RemoveTimer()
    if isTween then
        self:PlayHideSliderTween(true)
    else
        self.PanelSlider.gameObject:SetActiveEx(false)
        self:Close()
    end
end

function XUiPanelGachaLuciaVolume:PlayHideSliderTween(isCloseView)
    if self.PanelSlider.gameObject.activeSelf then
        self.Parent:PlayAnimation("PanelVolumeDisable", function()
            self.PanelSlider.gameObject:SetActiveEx(false)
            if isCloseView then
                self:Close()
            end
        end)
    else
        if isCloseView then
            self:Close()
        end
    end
end

function XUiPanelGachaLuciaVolume:ShowSlider()
    self.Parent:PlayAnimation("PanelVolumeEnable")
    self.PanelSlider.gameObject:SetActiveEx(true)
end

function XUiPanelGachaLuciaVolume:TweenInit()
    self:RemoveTimer()
    self._Timer = XScheduleManager.ScheduleOnce(function()
        self:PlayHideSliderTween()
    end, self._InitWaitTime)
end

function XUiPanelGachaLuciaVolume:TweenClick()
    self:RemoveTimer()
    self._Timer = XScheduleManager.ScheduleOnce(function()
        self:PlayHideSliderTween()
    end, self._ClickWaitTime)
end

function XUiPanelGachaLuciaVolume:RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiPanelGachaLuciaVolume:OnBtnActiveVolumeClick()
    if self.PanelSlider.gameObject.activeSelf then
        return
    end
    self:ShowSlider()
    self:TweenClick()
end

return XUiPanelGachaLuciaVolume
