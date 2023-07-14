XUiPanelVoiceSet = XClass(nil, "XUiPanelVoiceSet")

function XUiPanelVoiceSet:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.MyColor = CS.UnityEngine.Color()
    self:InitUi()
    self:InitPanelData()
    self:SetPanel()
    self:AddListener()
end

function XUiPanelVoiceSet:InitUi()
    local XUiBtnDownload = require("XUi/XUiDlcDownload/XUiBtnDownload")
    local beforeCb = handler(self, self.OnCheckDownloadBefore)
    self.OnRefreshJpTog = function(needDownload) 
        self:RefreshCvTog(self.TogRiwen, needDownload)
    end
    self.OnRefreshHkTog = function(needDownload)
        self:RefreshCvTog(self.TogXiangGang, needDownload)
    end
    self.OnRefreshEnTog = function(needDownload)
        self:RefreshCvTog(self.TogEnglish, needDownload)
    end
    ---@type XUiBtnDownload
    self.GirdBtnDownloadJp = XUiBtnDownload.New(self.BtnDownloadJP, beforeCb)
    ---@type XUiBtnDownload
    self.GirdBtnDownloadHk = XUiBtnDownload.New(self.BtnDownloadHK, beforeCb)
    ---@type XUiBtnDownload
    self.GridBtnDownloadEn = XUiBtnDownload.New(self.BtnDownloadEN, beforeCb)
    self.GirdBtnDownloadJp:Init(XDlcConfig.EntryType.CharacterVoice, 0, nil, handler(self, self.OnDownloadComplete))
    self.GirdBtnDownloadHk:Init(XDlcConfig.EntryType.CharacterVoice, 0, nil, handler(self, self.OnDownloadComplete))
    self.GridBtnDownloadEn:Init(XDlcConfig.EntryType.CharacterVoice, 0, nil, handler(self, self.OnDownloadComplete))

    self.BtnDownloadCN.gameObject:SetActiveEx(false)

    if not XDataCenter.UiPcManager.IsPc() and self.PanelMute then
        self.PanelMute.gameObject:SetActiveEx(false)
    end
    self.TogMute.isOn = CS.XStandaloneSettingHelper.MuteInBackground
end

function XUiPanelVoiceSet:AddListener()

    XUiHelper.RegisterClickEvent(self, self.TogRiwen, self.OnLanguageClick)
    XUiHelper.RegisterClickEvent(self, self.TogZhongWen, self.OnLanguageClick)
    XUiHelper.RegisterClickEvent(self, self.TogXiangGang, self.OnLanguageClick)
    if self.TogEnglish then
        XUiHelper.RegisterClickEvent(self, self.TogEnglish, self.OnLanguageClick)
    end
    XUiHelper.RegisterClickEvent(self, self.TogControl, self.OnTogControlClick)
    XUiHelper.RegisterClickEvent(self, self.TogMute, self.OnTogMuteClick)
    
    XUiHelper.RegisterClickEvent(self, self.FashionVoiceGuan, self.OnTogFashionVoiceClick)
    XUiHelper.RegisterClickEvent(self, self.FashionVoiceKai, self.OnTogFashionVoiceClick)

    XUiHelper.RegisterSliderChangeEvent(self, self.SliMusic, self.OnSliMusicValueChanged)
    XUiHelper.RegisterSliderChangeEvent(self, self.SliSound, self.OnSliSoundValueChanged)
    XUiHelper.RegisterSliderChangeEvent(self, self.SliCv, self.OnSliCvValueChanged)

    XUiHelper.RegisterClickEvent(self, self.BtnCanDown, self.OnBtnCanDownClick)
    XUiHelper.RegisterClickEvent(self, self.BtnDownload, self.OnBtnDownloadClick)
    XUiHelper.RegisterClickEvent(self, self.BtnUpdate, self.OnBtnUpdateClick)
end

function XUiPanelVoiceSet:OnLanguageClick()
    if (self.TogRiwen.isOn) then
        self.NewCvType = 1
    elseif (self.TogZhongWen.isOn) then
        self.NewCvType = 2
    elseif (self.TogXiangGang.isOn) then
        self.NewCvType = 3
    elseif self.TogEnglish and (self.TogEnglish.isOn) then
        self.NewCvType = 4
    end
    CS.XAudioManager.CvType = self.NewCvType
end

function XUiPanelVoiceSet:OnTogFashionVoiceClick()
    if (self.FashionVoiceGuan.isOn) then
        self.NewIsOpenFashionVoice = 0
    elseif (self.FashionVoiceKai.isOn) then
        self.NewIsOpenFashionVoice = 1
    end
    CS.XAudioManager.IsOpenFashionVoice = self.NewIsOpenFashionVoice
end

function XUiPanelVoiceSet:OnTogControlClick()
    self:SetTogControl(self.TogControl.isOn)
    if (self.TogControl.isOn) then
        self.NewControl = 1
    else
        self.NewControl = 2
    end
    self:SetVolume()
end

function XUiPanelVoiceSet:OnTogMuteClick()
    CS.XStandaloneSettingHelper.MuteInBackground = self.TogMute.isOn
end

function XUiPanelVoiceSet:SetTogControl(IsOn)
    if (IsOn) then
        self:ChangeObjsTansparent(1.0)
    else
        self:ChangeObjsTansparent(0.5)
    end
    self.SliMusic.interactable = IsOn
    self.SliSound.interactable = IsOn
    self.SliCv.interactable = IsOn
end


function XUiPanelVoiceSet:OnSliDownloadValueChanged()

end

function XUiPanelVoiceSet:OnBtnCanDownClick()

end

function XUiPanelVoiceSet:OnBtnUpdateClick()

end

function XUiPanelVoiceSet:OnSliMusicValueChanged()
    self.NewMusicVolume = self.SliMusic.value
    CS.XAudioManager.ChangeMusicVolume(self.SliMusic.value)
end

function XUiPanelVoiceSet:OnSliSoundValueChanged()
    self.NewSoundVolume = self.SliSound.value
    CS.XAudioManager.ChangeSoundVolume(self.SliSound.value)
end

function XUiPanelVoiceSet:OnSliCvValueChanged()
    self.NewCvVolume = self.SliCv.value
    CS.XAudioManager.ChangeCvVolume(self.SliCv.value)
end

function XUiPanelVoiceSet:InitPanelData()
    self.CvType = CS.XAudioManager.CvType
    self.MusicVolume = CS.XAudioManager.MusicVolume
    self.SoundVolume = CS.XAudioManager.SoundVolume
    self.CvVolume = CS.XAudioManager.CvVolume
    self.Control = CS.XAudioManager.Control
    self.IsOpenFashionVoice = CS.XAudioManager.IsOpenFashionVoice
    self.NewCvType = self.CvType
    self.NewCvVolume = self.CvVolume
    self.NewMusicVolume = self.MusicVolume
    self.NewSoundVolume = self.SoundVolume
    self.NewControl = self.Control
    self.NewIsOpenFashionVoice = self.IsOpenFashionVoice
end

function XUiPanelVoiceSet:ResetPanelData()
    CS.XAudioManager.ResetToDefault()
    self.NewCvType = CS.XAudioManager.CvType
    self.NewCvVolume = CS.XAudioManager.CvVolume
    self.NewMusicVolume = CS.XAudioManager.MusicVolume
    self.NewSoundVolume = CS.XAudioManager.SoundVolume
    self.NewControl = CS.XAudioManager.Control
    self.NewIsOpenFashionVoice = CS.XAudioManager.IsOpenFashionVoice
    self:ResetMute()
end

function XUiPanelVoiceSet:ResetMute()
    if XDataCenter.UiPcManager.IsPc() and self.PanelMute then
        self.TogMute.isOn = false
        CS.XStandaloneSettingHelper.MuteInBackground = self.TogMute.isOn
    end
end

function XUiPanelVoiceSet:SetPanel()
    self:SetVolume()
    self:SetTogControl(self.TogControl.isOn)

    self.SliMusic.value = self.NewMusicVolume
    self.SliSound.value = self.NewSoundVolume
    self.SliCv.value = self.NewCvVolume

    local isJP, isCN, isHk, isEN = self.NewCvType == 1, self.NewCvType == 2, self.NewCvType == 3, self.NewCvType == 4
    self.TogRiwen.isOn = isJP
    self.TogZhongWen.isOn = isCN
    self.TogXiangGang.isOn = isHk
    if self.TogEnglish then
        self.TogEnglish.isOn = isEN
    end
    
    self.FashionVoiceKai.isOn = self.NewIsOpenFashionVoice == 1
    self.FashionVoiceGuan.isOn = self.NewIsOpenFashionVoice ~= 1
    
    self.GirdBtnDownloadHk:RefreshView(self.OnRefreshHkTog)
    self.GirdBtnDownloadJp:RefreshView(self.OnRefreshJpTog)
    self.GridBtnDownloadEn:RefreshView(self.OnRefreshEnTog)
end

function XUiPanelVoiceSet:SetVolume()
    local XAManager = CS.XAudioManager
    if (self.NewControl == 2) then
        self.TogControl.isOn = false
        XAManager.ChangeMusicVolume(0)
        XAManager.ChangeSoundVolume(0)
        XAManager.ChangeCvVolume(0)
    else
        self.TogControl.isOn = true
        XAManager.ChangeMusicVolume(self.NewMusicVolume)
        XAManager.ChangeSoundVolume(self.NewSoundVolume)
        XAManager.ChangeCvVolume(self.NewCvVolume)
    end
end

function XUiPanelVoiceSet:ShowPanel()
    self.IsShow = true
    self.GameObject:SetActive(true)
    
    local yuYanBaoObject = self.Transform:Find("Yuyanbao")

    if yuYanBaoObject then
        yuYanBaoObject.gameObject:SetActive(false)
    end

    self:InitPanelData()
    self:SetPanel()
    -- if (self:CheckNeedDownloadSource()==0) then
    --     -- self.BtnCanDown.gameObject:SetActive(false)
    --     -- self.BtnDownloaded.gameObject:SetActive(true)
    --     -- self.PanelDownload.gameObject:SetActive(false)

    --     self.BtnCanDown.gameObject:SetActive(false)
    --     self.BtnDownloaded.gameObject:SetActive(false)
    --     self.PanelDownload.gameObject:SetActive(false)

    -- end
end

function XUiPanelVoiceSet:CheckNeedDownloadSource()
    return 0
end

function XUiPanelVoiceSet:HidePanel()
    self.IsShow = false
    self.GameObject:SetActive(false)
end

function XUiPanelVoiceSet:CheckDataIsChange()
    if (self.NewCvType ~= self.CvType) then
        return true
    end
    if (self.NewCvVolume ~= self.CvVolume) then
        return true
    end
    if (self.NewMusicVolume ~= self.MusicVolume) then
        return true
    end
    if (self.NewSoundVolume ~= self.SoundVolume) then
        return true
    end
    if (self.NewControl ~= self.Control) then
        return true
    end
    if (self.NewIsOpenFashionVoice ~= self.IsOpenFashionVoice) then
        return true
    end

    return false
end

function XUiPanelVoiceSet:SaveChange()
    -- local XAManager = CS.XAudioManager
    self.CvType = self.NewCvType
    self.MusicVolume = self.NewMusicVolume
    self.SoundVolume = self.NewSoundVolume
    self.CvVolume = self.NewCvVolume
    self.Control = self.NewControl
    self.IsOpenFashionVoice = self.NewIsOpenFashionVoice
    self:SaveAudioManagerData()
    
    local dict = {}
    dict["music_volume"] = math.floor(self.MusicVolume * 100)
    dict["sound_volume"] = math.floor(self.SoundVolume * 100)
    dict["cv_volume"] = math.floor(self.CvVolume * 100)
    dict["cv_type"] = self.CvType
    dict["control"] = self.Control == 1
    dict["is_open_fashion_voice"] = self.IsOpenFashionVoice == 1
    XDataCenter.SetManager.SystemSettingBuriedPoint(dict)
end

function XUiPanelVoiceSet:CancelChange()
    self.NewCvType = self.CvType
    self.NewCvVolume = self.CvVolume
    self.NewMusicVolume = self.MusicVolume
    self.NewSoundVolume = self.SoundVolume
    self.NewControl = self.Control
    self.NewIsOpenFashionVoice = self.IsOpenFashionVoice
    self:SetVolume()
    self:SaveAudioManagerData()
end

function XUiPanelVoiceSet:SaveAudioManagerData()
    local XAManager = CS.XAudioManager
    XAManager.CvType = self.NewCvType
    XAManager.MusicVolume = self.NewMusicVolume
    XAManager.SoundVolume = self.NewSoundVolume
    XAManager.CvVolume = self.NewCvVolume
    XAManager.Control = self.NewControl
    XAManager.IsOpenFashionVoice = self.NewIsOpenFashionVoice
    XAManager.SaveChange()
end

function XUiPanelVoiceSet:ResetToDefault()
    self:ResetPanelData()
    self:SetPanel()
end

function XUiPanelVoiceSet:ChangeObjsTansparent(alpha)
    self.MyColor.a = alpha

    self.TxtMusic.color = self.MyColor
    self.ImgMusicON.color = self.MyColor
    self.ImgMusicOFF.color = self.MyColor
    self.ImgMusicFill.color = self.MyColor

    self.TxtSound.color = self.MyColor
    self.ImgSoundON.color = self.MyColor
    self.ImgSoundOFF.color = self.MyColor
    self.ImgSoundFill.color = self.MyColor

    self.TxtYinliang.color = self.MyColor
    self.ImgYinliangON.color = self.MyColor
    self.ImgYinliangOFF.color = self.MyColor
    self.ImgYinliangFill.color = self.MyColor
end

function XUiPanelVoiceSet:OnDownloadComplete()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.GirdBtnDownloadJp:RefreshView(self.OnRefreshJpTog)
    self.GirdBtnDownloadHk:RefreshView(self.OnRefreshHkTog)
    self.GridBtnDownloadEn:RefreshView(self.OnRefreshEnTog)
end 

function XUiPanelVoiceSet:OnCheckDownloadBefore()
    local isRunning = CS.XFight.IsRunning
    if isRunning then
        XUiManager.TipText("DlcDownloadVoiceTipInFight")
        return false
    end
    return true
end

--- 刷新Cv类型的单选框样式
---@param toggle UnityEngine.UI.Toggle
---@param needDownload boolean 是否需要分包下载
--------------------------
function XUiPanelVoiceSet:RefreshCvTog(toggle, needDownload)
    if XTool.UObjIsNil(toggle) or XTool.UObjIsNil(self.GameObject) then
        return
    end
    if not toggle.targetGraphic then
        return
    end
    toggle.targetGraphic.gameObject:SetActiveEx(not needDownload)
end