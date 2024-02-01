local XUiPanelMusicSpectrum = require("XUi/XUiMusicPlayer/XUiPanelMusicSpectrum")
local CSXAudioManager = CS.XAudioManager

---@class XUiTaikoMasterMain:XLuaUi
---@field _Control XTaikoMasterControl
local XUiTaikoMasterMain = XLuaUiManager.Register(XLuaUi, "UiTaikoMasterMain")

function XUiTaikoMasterMain:OnStart()
    self._Control:UpdateUiData()
    self._Timer = false
    ---@type XUiTaikoMasterCdList
    self.StageList = false
    -- 音乐频谱
    self._SpectrumTimer = false
    ---@type XUiPanelMusicSpectrum
    self._BarMusic1 = false
    ---@type XUiPanelMusicSpectrum
    self._BarMusic2 = false

    if self.PanelBtnTop then
        self.PanelBtnTop.gameObject:SetActiveEx(false)
    end
    if self.PanelBtnCalibrator then
        self.PanelBtnCalibrator.gameObject:SetActiveEx(false)
    end
    
    self:InitPanelAsset()
    self:InitStageList()
    self:InitMusicBar()
    self:InitAutoClose()
    self:AddBtnListener()
end

function XUiTaikoMasterMain:OnEnable()
    self:StartMusicSpectrumTimer()
    self:StartTimer()
    
    self:Refresh()
    self:AddEventListener()
    self:CheckRedPointTask()
end

function XUiTaikoMasterMain:OnDisable()
    self:StopMusicSpectrumTimer()
    self:StopTimer()
    
    self:RemoveEventListener()
end

function XUiTaikoMasterMain:Refresh()
    local uiData = self._Control:GetUiData()
    local justPassedStageId = self._Control:GetJustPassedStageId()
    local hasSelectSong = false
    -- 从校准关出来，重新打开校准界面
    if justPassedStageId == uiData.SettingStageId then
        if not XLuaUiManager.IsUiShow("UiTaikoMasterSetting") then
            XLuaUiManager.Open("UiTaikoMasterSetting", false)
        end
    else
        if justPassedStageId then
            hasSelectSong = true
        end
        self:SelectStage(justPassedStageId)
    end
    if not self.StageList:GetSelectedSongId() then
        self._Control:PlayDefaultBgm()
    end
    self:_UpdateTime()
end

--region Ui - PanelAsset
function XUiTaikoMasterMain:InitPanelAsset()
    if self.PanelSpecialTool then
        self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.Coin }, self.PanelSpecialTool, self)
    end
end
--endregion

--region Ui - AutoClose
function XUiTaikoMasterMain:InitAutoClose()
    local uiData = self._Control:GetUiData()
    self:SetAutoCloseInfo(XFunctionManager.GetEndTimeByTimeId(uiData and uiData.TimeId), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiTaikoMasterMain:StartTimer()
    if self._Timer then
        return
    end
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:_UpdateTime()
    end,
    XScheduleManager.SECOND)
end

function XUiTaikoMasterMain:StopTimer()
    if not self._Timer then
        return
    end
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
end

function XUiTaikoMasterMain:_UpdateTime()
    local uiData = self._Control:GetUiData()
    local currentTime = XTime.GetServerNowTimestamp()
    local remainTime = math.max(0, XFunctionManager.GetEndTimeByTimeId(uiData.TimeId) - currentTime)
    self.TxtRemainTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
end
--endregion

--region Ui - StageList
function XUiTaikoMasterMain:InitStageList()
    local XUiTaikoMasterStageList = require("XUi/XUiTaikoMaster/XUiTaikoMasterStageList")
    self.StageList = XUiTaikoMasterStageList.New(self.Transform, self)
end

function XUiTaikoMasterMain:SelectStage(stageId)
    if stageId then
        self.StageList:SelectStage(stageId)
    end
end

function XUiTaikoMasterMain:SelectStageByIndex(index)
    self.StageList:Select(index)
end
--endregion

--region Ui - MusicBar
function XUiTaikoMasterMain:InitMusicBar()
    local barMusic = self.BarMusic
    local imgBarMusic = self.ImgMusic
    self._BarMusic1 = XUiPanelMusicSpectrum.New(barMusic)
    self._BarMusic1:CreateImgBar(imgBarMusic)
    self._BarMusic1:Reverse()
    self._BarMusic2 = XUiPanelMusicSpectrum.New(barMusic)
    self._BarMusic2:CreateImgBar(CS.UnityEngine.Object.Instantiate(imgBarMusic, imgBarMusic.transform.parent))
end

function XUiTaikoMasterMain:StartMusicSpectrumTimer()
    if self._SpectrumTimer then
        return
    end
    local scheduleIntervalTime = CS.XGame.ClientConfig:GetInt("MusicPlayerSpectrumIntervalTime")
    self._SpectrumTimer = XScheduleManager.ScheduleForever(function() 
        self:_UpdateMusicSpectrum()
    end, scheduleIntervalTime)
end

function XUiTaikoMasterMain:StopMusicSpectrumTimer()
    if not self._SpectrumTimer then
        return
    end
    XScheduleManager.UnSchedule(self._SpectrumTimer)
    self._SpectrumTimer = false
end

function XUiTaikoMasterMain:_UpdateMusicSpectrum()
    local songId = self.StageList and self.StageList:GetSelectedSongId()
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

--region Ui - RedPoint
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

--region Ui - BtnListener
function XUiTaikoMasterMain:AddBtnListener()
    local uiData = self._Control:GetUiData()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    if uiData.HelpId then
        self:BindHelpBtn(self.BtnHelp, XHelpCourseConfig.GetHelpCourseTemplateById(uiData.HelpId).Function)
    end
    self:RegisterClickEvent(self.PanelBtnTask, self.OpenUiTask)
    self:RegisterClickEvent(self.PanelBtnTeaching, self.OpenUiTraining)
    self:RegisterClickEvent(self.ButtonCloseDetail, self.CloseDetail)
    
    self:RegisterClickEvent(self.PanelBtnTop, self.OpenUiRank)
    self:RegisterClickEvent(self.PanelBtnCalibrator, self.OpenUiSetting)
end

function XUiTaikoMasterMain:CloseDetail()
    if self.StageList:GetSelectedSongId() then
        self:SelectStageByIndex(false)
    end
end

function XUiTaikoMasterMain:OpenUiTask()
    XLuaUiManager.Open("UiTaikoMasterTask")
end

function XUiTaikoMasterMain:OpenUiTraining()
    local stageId = self._Control:GetUiData().TeachStageId
    self._Control:OpenBattleRoom(stageId)
end

function XUiTaikoMasterMain:OpenUiSetting()
    XLuaUiManager.Open("UiTaikoMasterSetting", true)
end

function XUiTaikoMasterMain:OpenUiRank()
    XLuaUiManager.Open("UiTaikoMasterRank")
end
--endregion

--region Event
function XUiTaikoMasterMain:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_TAIKO_MASTER_STAGE_SELECT, self.SelectStageByIndex, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.CheckRedPointTask, self)
    XEventManager.AddEventListener(XEventId.EVENT_TAIKO_MASTER_SONG_BROWSED_UPDATE, self.CheckRedPointSongUnlock, self)
end

function XUiTaikoMasterMain:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_TAIKO_MASTER_STAGE_SELECT, self.SelectStageByIndex, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.CheckRedPointTask, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TAIKO_MASTER_SONG_BROWSED_UPDATE, self.CheckRedPointSongUnlock, self)
end
--endregion

return XUiTaikoMasterMain
