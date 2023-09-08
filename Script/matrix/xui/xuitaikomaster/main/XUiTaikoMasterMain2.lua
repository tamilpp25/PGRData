local XUiTaikoMasterMainCdGrid = require("XUi/XUiTaikoMaster/Main/XUiTaikoMasterMainCdGrid")
local XUiPanelMusicSpectrum = require("XUi/XUiMusicPlayer/XUiPanelMusicSpectrum")
local CSXAudioManager = CS.XAudioManager

---@class XUiTaikoMasterMain2:XLuaUi
---@field _Control XTaikoMasterControl
local XUiTaikoMasterMain2 = XLuaUiManager.Register(XLuaUi, "UiTaikoMasterMain")

function XUiTaikoMasterMain2:OnStart(index)
    self._Control:UpdateUiData()
    self._Timer = false
    -- 音乐频谱
    self._SpectrumTimer = false
    self._SelectIndex = index or 1

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

function XUiTaikoMasterMain2:OnEnable()
    self:StartMusicSpectrumTimer()
    self:StartTimer()

    self:Refresh()
    self:AddEventListener()
    self:CheckRedPointTask()
end

function XUiTaikoMasterMain2:OnDisable()
    self:StopMusicSpectrumTimer()
    self:StopTimer()

    self:RemoveEventListener()
    self._IsEnable = false
end

function XUiTaikoMasterMain2:Refresh()
    self:RefreshStageList()
    self:_UpdateTime()
end

--region Ui - PanelAsset
function XUiTaikoMasterMain2:InitPanelAsset()
    if self.PanelSpecialTool then
        self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe(self._Control:GetPanelAssetItemList(), self.PanelSpecialTool, self)
    end
end
--endregion

--region Ui - AutoClose
function XUiTaikoMasterMain2:InitAutoClose()
    local uiData = self._Control:GetUiData()
    self:SetAutoCloseInfo(XFunctionManager.GetEndTimeByTimeId(uiData and uiData.TimeId), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiTaikoMasterMain2:StartTimer()
    if self._Timer then
        return
    end
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:_UpdateTime()
    end,
            XScheduleManager.SECOND)
end

function XUiTaikoMasterMain2:StopTimer()
    if not self._Timer then
        return
    end
    XScheduleManager.UnSchedule(self._Timer)
    self._Timer = false
end

function XUiTaikoMasterMain2:_UpdateTime()
    local uiData = self._Control:GetUiData()
    local currentTime = XTime.GetServerNowTimestamp()
    local remainTime = math.max(0, XFunctionManager.GetEndTimeByTimeId(uiData.TimeId) - currentTime)
    self.TxtRemainTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
end
--endregion

--region Ui - StageList
function XUiTaikoMasterMain2:InitStageList()
    ---@type XDynamicTableCurve
    self.DynamicTable = XDynamicTableCurve.New(self.PanelCdList)
    self.DynamicTable:SetProxy(XUiTaikoMasterMainCdGrid, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiTaikoMasterMain2:RefreshStageList()
    local usData = self._Control:GetUiData()
    local justEnterSongId = self._Control:GetJustEnterSongId()
    
    self._SongArray = usData.SongIdList
    self._SelectIndex = table.indexof(self._SongArray, justEnterSongId) or self._SelectIndex
    self.DynamicTable:SetDataSource(self._SongArray)
    self.DynamicTable:ReloadData(self._SelectIndex - 1)
    self.GridAlbum.gameObject:SetActiveEx(false)
    self:UpdateStageSelect()
end

---@param grid XUiTaikoMasterMainCdGrid
function XUiTaikoMasterMain2:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        index = index  % self.DynamicTable.Imp.TotalCount + 1
        grid:Refresh(self._SongArray[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        local startIndex = self.DynamicTable.Imp.StartIndex
        local selectIndex = startIndex % self.DynamicTable.Imp.TotalCount + 1
        self._SelectIndex = selectIndex
        self:UpdateStageSelect()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.DynamicTable.Imp:TweenToIndex(index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_BEGIN_DRAG then  
        self:StopAnimation("RoundEffectEnable", true, true)
        self:StopAnimation("RoundEffectLoop", true, true)
        self:StopAnimation("EffectEnable", true, true)
        self:StopAnimation("EffectLoop", true, true)
    end
end

function XUiTaikoMasterMain2:UpdateStageSelect()
    local startIndex = self.DynamicTable.Imp.StartIndex
    local songId = self._SongArray[self._SelectIndex]
    local uiData = self._Control:GetUiData()
    local songData = uiData.SongUiDataDir[songId]
    for i, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:UpdateSelect(i == startIndex)
    end
    if XTool.IsTableEmpty(songData) then
        return
    end
    self.TxtMusicName.text = songData.Name
    self.TxtComposer.text = songData.ComposerDesc
    self:PlayAnimSwitchCd()
end
--endregion

--region Ui - MusicBar
function XUiTaikoMasterMain2:InitMusicBar()
    ---@type XUiPanelMusicSpectrum
    self._BarMusic = XUiPanelMusicSpectrum.New(self.BarMusic)
    local bar2 = self.BarMusic2 or XUiHelper.Instantiate(self.BarMusic.gameObject, self.BarMusic.transform.parent)
    -----@type XUiPanelMusicSpectrum
    self._BarMusic2 = XUiPanelMusicSpectrum.New(bar2)
    self._BarMusic2:Reverse()
end

function XUiTaikoMasterMain2:StartMusicSpectrumTimer()
    if self._SpectrumTimer then
        return
    end
    local scheduleIntervalTime = CS.XGame.ClientConfig:GetInt("MusicPlayerSpectrumIntervalTime")
    self._SpectrumTimer = XScheduleManager.ScheduleForever(function()
        self:_UpdateMusicSpectrum()
    end, scheduleIntervalTime)
end

function XUiTaikoMasterMain2:StopMusicSpectrumTimer()
    if not self._SpectrumTimer then
        return
    end
    XScheduleManager.UnSchedule(self._SpectrumTimer)
    self._SpectrumTimer = false
end

function XUiTaikoMasterMain2:_UpdateMusicSpectrum()
    if CSXAudioManager.GetMusicVolume() > 0 then
        local spectrumData = CSXAudioManager.GetSpectrumLvData()
        self._BarMusic:UpdateSpectrum(spectrumData)
        self._BarMusic2:UpdateSpectrum(spectrumData)
    end
end
--endregion

--region Ui - RedPoint
function XUiTaikoMasterMain2:CheckRedPointTask()
    XRedPointManager.CheckOnce(
            self.OnCheckRedPointTask,
            self,
            {XRedPointConditions.Types.CONDITION_ACTIVITY_TAIKO_MASTER_TASK}
    )
end

function XUiTaikoMasterMain2:OnCheckRedPointTask(count)
    self.BtnTask:ShowReddot(count >= 0)
end

function XUiTaikoMasterMain2:CheckRedPointSongUnlock(songId)
    self.StageList:CheckRedPointSongUnlock(songId)
end
--endregion

--region Ui - Anim
function XUiTaikoMasterMain2:PlayAnimSwitchCd()
    local songId = self._SongArray[self._SelectIndex]
    local uiData = self._Control:GetUiData()
    if not self._IsEnable then
        self._IsEnable = true
        self.RImgBg:SetRawImage(uiData.SongUiDataDir[songId].CoverBg)
        self:_PlayAnimCDEnable()
    else
        self:PlayAnimationWithMask("BeijingDisable", function()
            self.RImgBg:SetRawImage(uiData.SongUiDataDir[songId].CoverBg)
            self:_PlayAnimCDEnable()
        end)
    end
end

function XUiTaikoMasterMain2:_PlayAnimCDEnable()
    self:PlayAnimation("BeijingEnable")
    self:PlayAnimation("EffectEnable", function()
        self:PlayAnimation("EffectLoop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)
    self:PlayAnimation("RoundEffectEnable", function()
        self:PlayAnimation("RoundEffectLoop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)
end
--endregion

--region Ui - BtnListener
function XUiTaikoMasterMain2:AddBtnListener()
    local uiData = self._Control:GetUiData()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    if uiData.HelpId then
        self:BindHelpBtn(self.BtnHelp, XHelpCourseConfig.GetHelpCourseTemplateById(uiData.HelpId).Function)
    end
    self:RegisterClickEvent(self.BtnTask, self.OpenUiTask)
    self:RegisterClickEvent(self.BtnTeaching, self.OpenUiTraining)

    self:RegisterClickEvent(self.PanelBtnTop, self.OpenUiRank)
    self:RegisterClickEvent(self.PanelBtnCalibrator, self.OpenUiSetting)
    self:RegisterClickEvent(self.BtnMatch, self.OpenBattleRoom)
end

function XUiTaikoMasterMain2:OpenBattleRoom()
    self._Control:UpdateUiSongUnLockData()
    local songId = self._SongArray[self._SelectIndex]
    local uiData = self._Control:GetUiData()
    if uiData.SongUnLockDir[songId] then
        self._Control:OpenBattleRoom(uiData.SongUiDataDir[songId].EasyStage)
    else
        self._Control:TipSongLock(songId)
    end
end

function XUiTaikoMasterMain2:OpenUiTask()
    XLuaUiManager.Open("UiTaikoMasterTask")
end

function XUiTaikoMasterMain2:OpenUiTraining()
    local stageId = self._Control:GetUiData().TeachStageId
    self._Control:OpenBattleRoom(stageId)
end

function XUiTaikoMasterMain2:OpenUiSetting()
    XLuaUiManager.Open("UiTaikoMasterSetting", true)
end

function XUiTaikoMasterMain2:OpenUiRank()
    XLuaUiManager.Open("UiTaikoMasterRank")
end
--endregion

--region Event
function XUiTaikoMasterMain2:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.CheckRedPointTask, self)
    XEventManager.AddEventListener(XEventId.EVENT_TAIKO_MASTER_SONG_BROWSED_UPDATE, self.CheckRedPointSongUnlock, self)
end

function XUiTaikoMasterMain2:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.CheckRedPointTask, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TAIKO_MASTER_SONG_BROWSED_UPDATE, self.CheckRedPointSongUnlock, self)
end
--endregion

return XUiTaikoMasterMain2
