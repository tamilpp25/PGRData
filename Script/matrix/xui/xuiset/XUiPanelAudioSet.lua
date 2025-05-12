---@class XUiPanelAudioSet : XUiNode
local XUiPanelAudioSet = XClass(XUiNode, "XUiPanelAudioSet")

function XUiPanelAudioSet:OnStart()
    self.MyColor = CS.UnityEngine.Color()
    self:InitUi()
    self:InitPanelData()
    self:SyncCacheNewAudioDataToUi()
    self:AddListener()
end

function XUiPanelAudioSet:OnEnable()
    self:ShowPanel()
end

function XUiPanelAudioSet:OnDisable()
    self:HidePanel()
end

function XUiPanelAudioSet:OnGetLuaEvents()
    return {
        XEventId.EVENT_SUBPACKAGE_COMPLETE
    }
end

function XUiPanelAudioSet:OnNotify(evt, ...)
    if evt == XEventId.EVENT_SUBPACKAGE_COMPLETE then
        self:RefreshBtndownload()
    end
end

function XUiPanelAudioSet:InitUi()
    self.BtnDownloadCN.gameObject:SetActiveEx(false)

    if not XDataCenter.UiPcManager.IsPc() and self.PanelMute then
        self.PanelMute.gameObject:SetActiveEx(false)
    end
    self.TogMute.isOn = CS.XSettingHelper.MuteInBackground
end

function XUiPanelAudioSet:AddListener()
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

function XUiPanelAudioSet:OnLanguageClick()
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

function XUiPanelAudioSet:OnTogFashionVoiceClick()
    if (self.FashionVoiceGuan.isOn) then
        self.NewIsOpenFashionVoice = 0
    elseif (self.FashionVoiceKai.isOn) then
        self.NewIsOpenFashionVoice = 1
    end
    CS.XAudioManager.IsOpenFashionVoice = self.NewIsOpenFashionVoice
end

function XUiPanelAudioSet:OnTogControlClick()
    self:SetTogControl(self.TogControl.isOn)
    if (self.TogControl.isOn) then
        self.NewControl = 1
    else
        self.NewControl = 2
    end
    CS.XAudioManager.Control = self.NewControl
end

function XUiPanelAudioSet:OnTogMuteClick()
    CS.XSettingHelper.MuteInBackground = self.TogMute.isOn
end

function XUiPanelAudioSet:SetTogControl(IsOn)
    if (IsOn) then
        self:ChangeObjsTansparent(1.0)
    else
        self:ChangeObjsTansparent(0.5)
    end
    self.SliMusic.interactable = IsOn
    self.SliSound.interactable = IsOn
    self.SliCv.interactable = IsOn
end

function XUiPanelAudioSet:OnSliDownloadValueChanged()
end

function XUiPanelAudioSet:OnBtnCanDownClick()
end

function XUiPanelAudioSet:OnBtnUpdateClick()
end

function XUiPanelAudioSet:OnSliMusicValueChanged()
    self.NewMusicVolume = self.SliMusic.value
    CS.XAudioManager.ChangeMusicVolume(self.SliMusic.value)
end

function XUiPanelAudioSet:OnSliSoundValueChanged()
    self.NewSoundVolume = self.SliSound.value
    CS.XAudioManager.ChangeSFXVolume(self.SliSound.value)
end

function XUiPanelAudioSet:OnSliCvValueChanged()
    self.NewCvVolume = self.SliCv.value
    CS.XAudioManager.ChangeVoiceVolume(self.SliCv.value)
end

function XUiPanelAudioSet:InitPanelData()
    -- 进入设置界面，先缓存当前数据，用作最后保存检查时比较
    -- 先将两个的值设为一样，这样退出不会触发差异检测
    self:SyncMngData2OldData()
    self:SyncOldData2NewData()
end

function XUiPanelAudioSet:ResetPanelData()
    -- 将设置值设定为默认值（注意这个方法不是还原，而是也会改变数据的方法，会和old数据有差异
    CS.XAudioManager.ResetToDefault()
    self:SyncMngData2NewData()
    self:ResetPCTogMute()
end

function XUiPanelAudioSet:ResetPCTogMute()
    if XDataCenter.UiPcManager.IsPc() and self.PanelMute then
        self.TogMute.isOn = false
        CS.XSettingHelper.MuteInBackground = self.TogMute.isOn
    end
end

-- 将音频数据同步到ui上，一般在初次进入和恢复默认（跳变修改数据）后调用
function XUiPanelAudioSet:SyncCacheNewAudioDataToUi()
    self.TogControl.isOn = self.NewControl == 1
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

function XUiPanelAudioSet:ShowPanel()
    self.IsShow = true
    
    local yuYanBaoObject = self.Transform:Find("Yuyanbao")

    if yuYanBaoObject then
        yuYanBaoObject.gameObject:SetActive(false)
    end

    self:InitPanelData()
    self:SyncCacheNewAudioDataToUi()
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

function XUiPanelAudioSet:CheckNeedDownloadSource()
    return 0
end

function XUiPanelAudioSet:HidePanel()
    self.IsShow = false
end

function XUiPanelAudioSet:CheckDataIsChange()
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

function XUiPanelAudioSet:SaveChange()
    self:SyncNewData2MngData()
    self:SyncMngData2OldData()
    self:SyncOldData2NewData()
    CS.XAudioManager.SaveChange()
    
    local dict = {}
    dict["music_volume"] = math.floor(self.MusicVolume * 100)
    dict["sound_volume"] = math.floor(self.SoundVolume * 100)
    dict["cv_volume"] = math.floor(self.CvVolume * 100)
    dict["cv_type"] = self.CvType
    dict["control"] = self.Control == 1
    dict["is_open_fashion_voice"] = self.IsOpenFashionVoice == 1
    XDataCenter.SetManager.SystemSettingBuriedPoint(dict)
end

function XUiPanelAudioSet:CancelChange()
    self:SyncOldData2MngData()
    CS.XAudioManager.SaveChange()
end

-- 将manager的数据同步old缓存组数据
function XUiPanelAudioSet:SyncMngData2OldData()
    self.CvType = CS.XAudioManager.CvType
    self.MusicVolume = CS.XAudioManager.MusicVolume
    self.SoundVolume = CS.XAudioManager.SFXVolume
    self.CvVolume = CS.XAudioManager.VoiceVolume
    self.Control = CS.XAudioManager.Control
    self.IsOpenFashionVoice = CS.XAudioManager.IsOpenFashionVoice
end

-- 将manager数据同步给新缓存数据
-- 建议每次操作完ui后或mng数据有更改后调用
function XUiPanelAudioSet:SyncMngData2NewData()
    self.NewCvType = CS.XAudioManager.CvType
    self.NewMusicVolume = CS.XAudioManager.MusicVolume
    self.NewSoundVolume = CS.XAudioManager.SFXVolume
    self.NewCvVolume = CS.XAudioManager.VoiceVolume
    self.NewControl = CS.XAudioManager.Control
    self.NewIsOpenFashionVoice = CS.XAudioManager.IsOpenFashionVoice
end

-- 将旧缓存数据同步给manager数据
function XUiPanelAudioSet:SyncOldData2MngData()
    local XAudioManager = CS.XAudioManager
    XAudioManager.CvType = self.CvType
    XAudioManager.MusicVolume = self.MusicVolume
    XAudioManager.SFXVolume = self.SoundVolume
    XAudioManager.VoiceVolume = self.CvVolume
    CS.XAudioManager.SyncCacheVolumeToRealVolume() -- 因为恢复的是缓存值，因此需要同步到真实的音量
    XAudioManager.Control = self.Control
    XAudioManager.IsOpenFashionVoice = self.IsOpenFashionVoice
end

-- 将旧缓存数据同步给新缓存数据
function XUiPanelAudioSet:SyncOldData2NewData()
    self.NewCvType = self.CvType
    self.NewCvVolume = self.CvVolume
    self.NewMusicVolume = self.MusicVolume
    self.NewSoundVolume = self.SoundVolume
    self.NewControl = self.Control
    self.NewIsOpenFashionVoice = self.IsOpenFashionVoice
end

-- 将新缓存数据同步给manager数据
function XUiPanelAudioSet:SyncNewData2MngData()
    local XAudioManager = CS.XAudioManager
    XAudioManager.CvType = self.NewCvType
    XAudioManager.MusicVolume = self.NewMusicVolume
    XAudioManager.SFXVolume = self.NewSoundVolume
    XAudioManager.VoiceVolume = self.NewCvVolume
    XAudioManager.Control = self.NewControl
    XAudioManager.IsOpenFashionVoice = self.NewIsOpenFashionVoice
end

function XUiPanelAudioSet:ResetToDefault()
    self:ResetPanelData()
    self:SyncCacheNewAudioDataToUi()
end

function XUiPanelAudioSet:ChangeObjsTansparent(alpha)
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

function XUiPanelAudioSet:RefreshBtndownload()
    self.BtnDownloadEN.gameObject:SetActiveEx(not XMVCA.XSubPackage:CheckCvDownload(XEnumConst.CV_TYPE.EN))
    self.BtnDownloadHK.gameObject:SetActiveEx(not XMVCA.XSubPackage:CheckCvDownload(XEnumConst.CV_TYPE.HK))
    self.BtnDownloadCN.gameObject:SetActiveEx(not XMVCA.XSubPackage:CheckCvDownload(XEnumConst.CV_TYPE.CN))
    self.BtnDownloadJP.gameObject:SetActiveEx(not XMVCA.XSubPackage:CheckCvDownload(XEnumConst.CV_TYPE.JPN))
end

function XUiPanelAudioSet:OnBtnDownloadClick(btn, cyType)
    if XMVCA.XSubPackage:CheckSubpackageByCvType(cyType) then
        btn.gameObject:SetActiveEx(false)
        return
    end
end

return XUiPanelAudioSet