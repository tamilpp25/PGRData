local XUiPanelMusicSpectrum = require("XUi/XUiMusicPlayer/XUiPanelMusicSpectrum")
local CSXAudioManager = CS.XAudioManager

---@class XUiTaikoMasterMain:XLuaUi
local XUiTaikoMasterMain = XLuaUiManager.Register(XLuaUi, "UiTaikoMasterMain")

--region init
function XUiTaikoMasterMain:Ctor()
    self._Timer = false
    ---@type XUiTaikoMasterStageList
    self.StageList = false
    -- 音乐频谱
    self._SpectrumTimer = false
    ---@type XUiPanelMusicSpectrum
    self._BarMusic1 = false
    ---@type XUiPanelMusicSpectrum
    self._BarMusic2 = false
end

function XUiTaikoMasterMain:OnStart()
    self:RegisterButtonClick()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.Coin)
    local XUiTaikoMasterStageList = require("XUi/XUiTaikoMaster/XUiTaikoMasterStageList")
    self.StageList = XUiTaikoMasterStageList.New(self)

    local barMusic = self.BarMusic
    local imgBarMusic = self.ImgMusic
    self._BarMusic1 = XUiPanelMusicSpectrum.New(barMusic)
    self._BarMusic1:CreateImgBar(imgBarMusic)
    self._BarMusic1:Reverse()
    self._BarMusic2 = XUiPanelMusicSpectrum.New(barMusic)
    self._BarMusic2:CreateImgBar(CS.UnityEngine.Object.Instantiate(imgBarMusic, imgBarMusic.transform.parent))
end

function XUiTaikoMasterMain:OnEnable()
    self:CheckRedPointTask()
    self:StartTimer()
    self:StartSpectrumTimer()
    XEventManager.AddEventListener(XEventId.EVENT_TAIKO_MASTER_STAGE_SELECT, self._Select, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.CheckRedPointTask, self)
    XEventManager.AddEventListener(XEventId.EVENT_TAIKO_MASTER_SONG_BROWSED_UPDATE, self.CheckRedPointSongUnlock, self)

    local justPassedStageId = XDataCenter.TaikoMasterManager.GetJustPassedStageId()
    local hasSelectSong = false
    -- 从校准关出来，重新打开校准界面
    if XDataCenter.TaikoMasterManager.IsSettingStageId(justPassedStageId) then
        if not XLuaUiManager.IsUiShow("UiTaikoMasterSetting") then
            XLuaUiManager.Open("UiTaikoMasterSetting", false)
        end
    else
        if justPassedStageId then
            hasSelectSong = true
        end
        self:SelectStage(justPassedStageId)
    end
    if not self.StageList:GetSelectedSong() then
        XDataCenter.TaikoMasterManager.PlayDefaultBgm()
    end
    self.StageList:OnEnable(hasSelectSong)
end

function XUiTaikoMasterMain:SelectStage(stageId)
    if stageId then
        self.StageList:SelectStage(stageId)
    end
end

function XUiTaikoMasterMain:OnDisable()
    self:StopTimer()
    self:StopSpectrumTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_TAIKO_MASTER_STAGE_SELECT, self._Select, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.CheckRedPointTask, self)
    XEventManager.RemoveEventListener(
        XEventId.EVENT_TAIKO_MASTER_SONG_BROWSED_UPDATE,
        self.CheckRedPointSongUnlock,
        self
    )
    self.StageList:OnDisable()
end

function XUiTaikoMasterMain:OnDestroy()
    self.StageList:OnDestroy()
end
--endregion

--region click
function XUiTaikoMasterMain:RegisterButtonClick()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, XDataCenter.TaikoMasterManager.GetHelpKey())
    self:RegisterClickEvent(self.PanelBtnTask, self.OpenUiTask)
    self:RegisterClickEvent(self.PanelBtnTeaching, self.OpenUiTraining)
    self:RegisterClickEvent(self.PanelBtnCalibrator, self.OpenUiSetting)
    self:RegisterClickEvent(self.PanelBtnTop, self.OpenUiRank)
    self:RegisterClickEvent(self.ButtonCloseDetail, self.CloseDetail)
end

function XUiTaikoMasterMain:CloseDetail()
    if self.StageList:GetSelectedSong() then
        self:_Select(false)
    end
end

function XUiTaikoMasterMain:OpenUiTask()
    XLuaUiManager.Open("UiTaikoMasterTask")
end

function XUiTaikoMasterMain:OpenUiTraining()
    local stageId = XDataCenter.TaikoMasterManager.GetTrainingStageId()
    XDataCenter.TaikoMasterManager.OpenUiRoom(stageId)
end

function XUiTaikoMasterMain:OpenUiSetting()
    XLuaUiManager.Open("UiTaikoMasterSetting", true)
end

function XUiTaikoMasterMain:OpenUiRank()
    XLuaUiManager.Open("UiTaikoMasterRank")
end

function XUiTaikoMasterMain:_Select(index)
    self.StageList:Select(index)
end
--endregion

--region 剩余时间
function XUiTaikoMasterMain:StartTimer()
    if self._Timer then
        return
    end
    if not self:UpdateTime() then
        return
    end
    self._Timer =
        XScheduleManager.ScheduleForever(
        function()
            self:UpdateTime()
        end,
        XScheduleManager.SECOND
    )
end

function XUiTaikoMasterMain:StopTimer()
    if not self._Timer then
        return
    end
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
end

function XUiTaikoMasterMain:UpdateTime()
    local remainTime = XDataCenter.TaikoMasterManager.GetActivityRemainTime()
    if remainTime <= 0 then
        self:Close()
        XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        return false
    end
    self.TxtRemainTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
    return true
end
--endregion

--region music
function XUiTaikoMasterMain:StartSpectrumTimer()
    if self._SpectrumTimer then
        return
    end
    local scheduleIntervalTime = CS.XGame.ClientConfig:GetInt("MusicPlayerSpectrumIntervalTime")
    self._SpectrumTimer =
        XScheduleManager.ScheduleForever(
        function()
            self:UpdateSpectrum()
        end,
        scheduleIntervalTime
    )
end

function XUiTaikoMasterMain:StopSpectrumTimer()
    if not self._SpectrumTimer then
        return
    end
    XScheduleManager.UnSchedule(self._SpectrumTimer)
    self._SpectrumTimer = false
end

function XUiTaikoMasterMain:UpdateSpectrum()
    local songId = self.StageList:GetSelectedSong()
    if not songId then
        return
    end
    if CSXAudioManager.GetMusicVolume() > 0 then
        local spectrumData = CSXAudioManager.GetSpectrumLvData()
        self._BarMusic1:UpdateSpectrum(spectrumData)
        self._BarMusic2:UpdateSpectrum(spectrumData)
    end
end
--endregion

--region red point
function XUiTaikoMasterMain:CheckRedPointTask()
    XRedPointManager.CheckOnce(
        self.OnCheckRedPointTask,
        self,
        {XRedPointConditions.Types.CONDITION_ACTIVITY_TAIKO_MASTER_TASK}
    )
end

function XUiTaikoMasterMain:OnCheckRedPointTask(count)
    self.PanelBtnTask:ShowReddot(count >= 0)
end

function XUiTaikoMasterMain:CheckRedPointSongUnlock(songId)
    self.StageList:CheckRedPointSongUnlock(songId)
end
--endregion

return XUiTaikoMasterMain
