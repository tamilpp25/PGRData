local XBWSettingBase = require("XModule/XBigWorldSet/XSetting/XBWSettingBase")
local XBWSettingValue = require("XModule/XBigWorldSet/XSetting/XBWSettingValue")

---@class XBWAudioSetting : XBWSettingBase
local XBWAudioSetting = XClass(XBWSettingBase, "XBWAudioSetting")

function XBWAudioSetting:InitValue()
    self:_InitFashionVoiceValue()
    self:_InitMusicVolumeValue()
    self:_InitSoundVolumeValue()
    self:_InitVoiceVolumeValue()
    self:_InitCvTypeValue()
    self:_InitVolumeControlValue()
    self:_InitMuteInBackgroundValue()
end

function XBWAudioSetting:Reset()
    self._FashionVoiceValue:Reset()
    self._MusicVolumeValue:Reset()
    self._SoundVolumeValue:Reset()
    self._VoiceVolumeValue:Reset()
    self._CvTypeValue:Reset()
    self._VolumeControlValue:Reset()

    if self._MuteInBackgroundValue then
        self._MuteInBackgroundValue:Reset()
    end
end

function XBWAudioSetting:RestoreDefault()
    CS.XAudioManager.ResetToDefault()

    self:SetFashionVoiceValue(CS.XAudioManager.IsOpenFashionVoice)
    self:SetMusicVolumeValue(CS.XAudioManager.MusicVolume)
    self:SetSoundVolumeValue(CS.XAudioManager.SFXVolume)
    self:SetVoiceVolumeValue(CS.XAudioManager.VoiceVolume)
    self:SetCvTypeValue(CS.XAudioManager.CvType)
    self:SetVolumeControlValue(CS.XAudioManager.Control)

    if self._MuteInBackgroundValue then
        self._MuteInBackgroundValue:RestoreDefault()
    end
end

function XBWAudioSetting:SaveChange()
    local audioManager = CS.XAudioManager

    self._FashionVoiceValue:SaveChange()
    self._MusicVolumeValue:SaveChange()
    self._SoundVolumeValue:SaveChange()
    self._VoiceVolumeValue:SaveChange()
    self._CvTypeValue:SaveChange()
    self._VolumeControlValue:SaveChange()

    if self._MuteInBackgroundValue then
        self._MuteInBackgroundValue:SaveChange()
    end

    audioManager.CvType = self:GetCvTypeValue()
    audioManager.MusicVolume = self:GetMusicVolumeValue()
    audioManager.SoundVolume = self:GetSoundVolumeValue()
    audioManager.CvVolume = self:GetVoiceVolumeValue()
    audioManager.Control = self:GetVolumeControlValue()
    audioManager.IsOpenFashionVoice = self:GetFashionVoiceValue()
    audioManager.SaveChange()
end

function XBWAudioSetting:IsChanged()
    if self._FashionVoiceValue:IsChanged() then
        return true
    end
    if self._MusicVolumeValue:IsChanged() then
        return true
    end
    if self._SoundVolumeValue:IsChanged() then
        return true
    end
    if self._VoiceVolumeValue:IsChanged() then
        return true
    end
    if self._CvTypeValue:IsChanged() then
        return true
    end
    if self._VolumeControlValue:IsChanged() then
        return true
    end
    if self._MuteInBackgroundValue and self._MuteInBackgroundValue:IsChanged() then
        return true
    end

    return false
end

-- region Getter/Setter

function XBWAudioSetting:GetFashionVoiceValue()
    return self._FashionVoiceValue:GetValue()
end

function XBWAudioSetting:SetFashionVoiceValue(value)
    self._FashionVoiceValue:SetValue(value)
end

function XBWAudioSetting:GetMusicVolumeValue()
    return self._MusicVolumeValue:GetValue()
end

function XBWAudioSetting:SetMusicVolumeValue(value)
    self._MusicVolumeValue:SetValue(value)
end

function XBWAudioSetting:GetSoundVolumeValue()
    return self._SoundVolumeValue:GetValue()
end

function XBWAudioSetting:SetSoundVolumeValue(value)
    self._SoundVolumeValue:SetValue(value)
end

function XBWAudioSetting:GetVoiceVolumeValue()
    return self._VoiceVolumeValue:GetValue()
end

function XBWAudioSetting:SetVoiceVolumeValue(value)
    self._VoiceVolumeValue:SetValue(value)
end

function XBWAudioSetting:GetCvTypeValue()
    return self._CvTypeValue:GetValue()
end

function XBWAudioSetting:SetCvTypeValue(value)
    self._CvTypeValue:SetValue(value)
end

function XBWAudioSetting:GetVolumeControlValue()
    return self._VolumeControlValue:GetValue()
end

function XBWAudioSetting:SetVolumeControlValue(value)
    self._VolumeControlValue:SetValue(value)
end

function XBWAudioSetting:GetMuteInBackgroundValue()
    if self._MuteInBackgroundValue then
        return self._MuteInBackgroundValue:GetValue()
    end

    return false
end

function XBWAudioSetting:SetMuteInBackgroundValue(value)
    if self._MuteInBackgroundValue then
        self._MuteInBackgroundValue:SetValue(value)
    end
end

-- endregion

-- region Init

function XBWAudioSetting:_InitFashionVoiceValue()
    local voiceValue = CS.XAudioManager.IsOpenFashionVoice

    if not self._FashionVoiceValue then
        ---@type XBWSettingValue
        self._FashionVoiceValue = XBWSettingValue.New(voiceValue, voiceValue)
        self._FashionVoiceValue:RegisterValueChangedEvent(function(value)
            CS.XAudioManager.IsOpenFashionVoice = value
        end)
    else
        self._FashionVoiceValue:Init(voiceValue, voiceValue)
    end
end

function XBWAudioSetting:_InitMusicVolumeValue()
    local volume = CS.XAudioManager.MusicVolume

    if not self._MusicVolumeValue then
        ---@type XBWSettingValue
        self._MusicVolumeValue = XBWSettingValue.New(volume, volume)
        self._MusicVolumeValue:RegisterValueChangedEvent(function(value)
            CS.XAudioManager.ChangeMusicVolume(value)
        end)
    else
        self._MusicVolumeValue:Init(volume, volume)
    end
end

function XBWAudioSetting:_InitSoundVolumeValue()
    local volume = CS.XAudioManager.SFXVolume

    if not self._SoundVolumeValue then
        ---@type XBWSettingValue
        self._SoundVolumeValue = XBWSettingValue.New(volume, volume)
        self._SoundVolumeValue:RegisterValueChangedEvent(function(value)
            CS.XAudioManager.ChangeSFXVolume(value)
        end)
    else
        self._SoundVolumeValue:Init(volume, volume)
    end
end

function XBWAudioSetting:_InitVoiceVolumeValue()
    local volume = CS.XAudioManager.VoiceVolume

    if not self._VoiceVolumeValue then
        ---@type XBWSettingValue
        self._VoiceVolumeValue = XBWSettingValue.New(volume, volume)
        self._VoiceVolumeValue:RegisterValueChangedEvent(function(value)
            CS.XAudioManager.ChangeVoiceVolume(value)
        end)
    else
        self._VoiceVolumeValue:Init(volume, volume)
    end
end

function XBWAudioSetting:_InitCvTypeValue()
    local cvType = CS.XAudioManager.CvType

    if not self._CvTypeValue then
        ---@type XBWSettingValue
        self._CvTypeValue = XBWSettingValue.New(cvType, cvType)
        self._CvTypeValue:RegisterValueChangedEvent(function(value)
            CS.XAudioManager.CvType = value
        end)
    else
        self._CvTypeValue:Init(cvType, cvType)
    end
end

function XBWAudioSetting:_InitVolumeControlValue()
    local volumeControl = CS.XAudioManager.Control

    if not self._VolumeControlValue then
        ---@type XBWSettingValue
        self._VolumeControlValue = XBWSettingValue.New(volumeControl, volumeControl)
        self._VolumeControlValue:RegisterValueChangedEvent(function(value)
            CS.XAudioManager.Control = value
            CS.XAudioManager.Mute(value == XEnumConst.BWSetting.VolumeControl.OFF)
        end)
    else
        self._VolumeControlValue:Init(volumeControl, volumeControl)
    end
end

function XBWAudioSetting:_InitMuteInBackgroundValue()
    if XDataCenter.UiPcManager.IsPc() then
        local muteInBackground = CS.XSettingHelper.MuteInBackground

        if not self._MuteInBackgroundValue then
            ---@type XBWSettingValue
            self._MuteInBackgroundValue = XBWSettingValue.New(false, muteInBackground)
            self._MuteInBackgroundValue:RegisterValueChangedEvent(function(value)
                CS.XSettingHelper.MuteInBackground = value
            end)
        else
            self._MuteInBackgroundValue:Init(false, muteInBackground)
        end
    end
end

-- endregion

return XBWAudioSetting
