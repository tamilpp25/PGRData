---@class XUiPanelVoiceSet : XUiNode
local XUiPanelVoiceSet = XClass(XUiNode, "XUiPanelVoiceSet")

function XUiPanelVoiceSet:OnStart()
    self.MyColor = CS.UnityEngine.Color()
    self:InitUi()
    self:InitPanelData()
    self:SetPanel()
    self:AddListener()
end

function XUiPanelVoiceSet:OnEnable()
    self:ShowPanel()
end

function XUiPanelVoiceSet:OnDisable()
    self:HidePanel()
end

function XUiPanelVoiceSet:OnGetLuaEvents()
    return {
        XEventId.EVENT_SUBPACKAGE_COMPLETE
    }
end

function XUiPanelVoiceSet:OnNotify(evt, ...)
    if evt == XEventId.EVENT_SUBPACKAGE_COMPLETE then
        self:RefreshBtndownload()
    end
end

function XUiPanelVoiceSet:InitUi()

    self.BtnDownloadCN.gameObject:SetActiveEx(false)

    if not XDataCenter.UiPcManager.IsPc() and self.PanelMute then
        self.PanelMute.gameObject:SetActiveEx(false)
    end
    self.TogMute.isOn = CS.XSettingHelper.MuteInBackground
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
    
    self.BtnDownloadCN.CallBack = function() 
        self:OnBtnDownloadClick(self.BtnDownloadCN, XEnumConst.CV_TYPE.CN)
    end

    self.BtnDownloadHK.CallBack = function()
        self:OnBtnDownloadClick(self.BtnDownloadHK, XEnumConst.CV_TYPE.HK)
    end

    self.BtnDownloadEN.CallBack = function()
        self:OnBtnDownloadClick(self.BtnDownloadEN, XEnumConst.CV_TYPE.EN)
    end

    self.BtnDownloadJP.CallBack = function()
        self:OnBtnDownloadClick(self.BtnDownloadJP, XEnumConst.CV_TYPE.JPN)
    end
end

function XUiPanelVoiceSet:OnLanguageClick()
    local oldCv = self.NewCvType
    if (self.TogRiwen.isOn) then
        self.NewCvType = 1
    elseif (self.TogZhongWen.isOn) then
        self.NewCvType = 2
    elseif (self.TogXiangGang.isOn) then
        self.NewCvType = 3
    elseif self.TogEnglish and (self.TogEnglish.isOn) then
        self.NewCvType = 4
    end

    if not XMVCA.XSubPackage:CheckSubpackageByCvType(self.NewCvType) then
        self.NewCvType = oldCv
        self.TogRiwen.isOn = self.NewCvType == XEnumConst.CV_TYPE.JPN
        self.TogZhongWen.isOn = self.NewCvType == XEnumConst.CV_TYPE.CN
        self.TogXiangGang.isOn = self.NewCvType == XEnumConst.CV_TYPE.HK
        self.TogEnglish.isOn = self.NewCvType == XEnumConst.CV_TYPE.EN
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
    CS.XSettingHelper.MuteInBackground = self.TogMute.isOn
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
        CS.XSettingHelper.MuteInBackground = self.TogMute.isOn
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
    
    local yuYanBaoObject = self.Transform:Find("Yuyanbao")

    if yuYanBaoObject then
        yuYanBaoObject.gameObject:SetActive(false)
    end

    self:InitPanelData()
    self:SetPanel()
    self:RefreshBtndownload()
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

function XUiPanelVoiceSet:RefreshBtndownload()
    self.BtnDownloadEN.gameObject:SetActiveEx(not XMVCA.XSubPackage:CheckCvDownload(XEnumConst.CV_TYPE.EN))
    self.BtnDownloadHK.gameObject:SetActiveEx(not XMVCA.XSubPackage:CheckCvDownload(XEnumConst.CV_TYPE.HK))
    self.BtnDownloadCN.gameObject:SetActiveEx(not XMVCA.XSubPackage:CheckCvDownload(XEnumConst.CV_TYPE.CN))
    self.BtnDownloadJP.gameObject:SetActiveEx(not XMVCA.XSubPackage:CheckCvDownload(XEnumConst.CV_TYPE.JPN))
end

function XUiPanelVoiceSet:OnBtnDownloadClick(btn, cyType)
    if XMVCA.XSubPackage:CheckSubpackageByCvType(cyType) then
        btn.gameObject:SetActiveEx(false)
        return
    end
end

return XUiPanelVoiceSet