local UiInited, LastBgmCueId
local PlayingCvInfo
local OldVolume = {}

local CSXAudioManager = CS.XAudioManager

local XMovieActionSoundPlay = XClass(XMovieActionBase, "XMovieActionSoundPlay")

function XMovieActionSoundPlay:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.SoundType = paramToNumber(params[1])
    self.CueId = paramToNumber(params[2])
    self.Volume = paramToNumber(params[3])
end

function XMovieActionSoundPlay:OnUiRootInit()
    if UiInited then return end
    UiInited = true

	OldVolume[XSoundManager.SoundType.CV] = XSoundManager.GetVolumeByType(XSoundManager.SoundType.CV)
	OldVolume[XSoundManager.SoundType.BGM] = XSoundManager.GetVolumeByType(XSoundManager.SoundType.BGM)
	OldVolume[XSoundManager.SoundType.Sound] = XSoundManager.GetVolumeByType(XSoundManager.SoundType.Sound)

    LastBgmCueId = XSoundManager.GetCurrentBgmCueId()
    CSXAudioManager.StopMusic()
end

function XMovieActionSoundPlay:OnUiRootDestroy()
    if not UiInited then return end
    UiInited = nil
    if OldVolume[XSoundManager.SoundType.CV] then
        XSoundManager.SetVolumeByType(OldVolume[XSoundManager.SoundType.CV], XSoundManager.SoundType.CV)
    end
    if OldVolume[XSoundManager.SoundType.BGM] then
        XSoundManager.SetVolumeByType(OldVolume[XSoundManager.SoundType.BGM], XSoundManager.SoundType.BGM)
    end
    if OldVolume[XSoundManager.SoundType.Sound] then
        XSoundManager.SetVolumeByType(OldVolume[XSoundManager.SoundType.Sound], XSoundManager.SoundType.Sound)
    end
    OldVolume = {}
    self:StopLastCv()
    CSXAudioManager.StopAll()
    XSoundManager.PlaySoundByType(LastBgmCueId, XSoundManager.SoundType.BGM)
end

function XMovieActionSoundPlay:OnRunning()

    CS.XTool.WaitForEndOfFrame(function()
        local soundType = self.SoundType

        local cueId = self.CueId
        if soundType == XSoundManager.SoundType.CV then
            self:StopLastCv()
            PlayingCvInfo = XSoundManager.PlaySoundByType(cueId, soundType)
        else
            XSoundManager.PlaySoundByType(cueId, soundType)
        end

        local volume = self.Volume
        if volume ~= 0 and CSXAudioManager.Control == 1 then
            XSoundManager.SetVolumeByType(volume, soundType)
        end
    end)
    
end

function XMovieActionSoundPlay:StopLastCv()
    if PlayingCvInfo then
        if PlayingCvInfo.Playing then
            PlayingCvInfo:Stop()
        end
        PlayingCvInfo = nil
    end
end

return XMovieActionSoundPlay