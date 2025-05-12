local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableCurve = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableCurve")
local XUiSpecialTrainMusic = XLuaUiManager.Register(XLuaUi,"UiSpecialTrainMusic")
local XUiGridMusicPlayer = require("XUi/XUiMusicPlayer/XUiGridMusicPlayer")
local CSXAudioManager = CS.XAudioManager
local ScheduleIntervalTime = CS.XGame.ClientConfig:GetInt("MusicPlayerSpectrumIntervalTime")
local XUiPanelMusicSpectrum = require("XUi/XUiMusicPlayer/XUiPanelMusicSpectrum")

function XUiSpecialTrainMusic:OnStart(selectIndex)
    self.ActivityConfig = XFubenSpecialTrainConfig.GetActivityConfigById(XDataCenter.FubenSpecialTrainManager.GetCurActivityId())
    self.EndTime = XFunctionManager.GetEndTimeByTimeId(self.ActivityConfig.TimeId)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_MATCH_TIMEOUT, self.OnMatchTimeout,self)
    self.PanelAssetComponent = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:InitDynamicTable()
    self.HelpDataFunc = function () return self:GetHelpDataFunc() end
    self:BindHelpBtnNew(self.BtnHelp, self.HelpDataFunc)
    self.SelectedIndex = selectIndex or 1
    self.IsHellMode = false
    self.IsFirstHandleSelect = true
    self.PanelSpectrumList = {
        XUiPanelMusicSpectrum.New(self.PanelLeftBar),
    }
    self.CurMusicVolume = CSXAudioManager.GetMusicVolume()
    self:SetupDynamicTable()
    self:RegisterButton()
end

function XUiSpecialTrainMusic:OnEnable()
    self:UpdateSelect(self.SelectedIndex)
    self.PlayableDirectorFrontEffectEnable.transform:PlayTimelineAnimation(function(isFinish) self:OnPlayFrontEffectEnableFinish(isFinish) end)
    self.PanelFrontEffect.gameObject:SetActiveEx(true)
    self:RefreshRedPoint()
    self:StartTimer()
end

function XUiSpecialTrainMusic:OnDisable()
    self:StopTimer()
    if self.ScheduleId then
        XScheduleManager.UnSchedule(self.ScheduleId)
        self.ScheduleId = nil
    end
    CSXAudioManager.StopMusicWithAnalyzer()
end

function XUiSpecialTrainMusic:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_ENTER_ROOM, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.OnCancelMatch, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_MATCH_TIMEOUT, self.OnMatchTimeout,self)
end

function XUiSpecialTrainMusic:OnGetEvents()
    return {
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiSpecialTrainMusic:OnNotify(event,...)
    if event == XEventId.EVENT_FINISH_TASK
            or event == XEventId.EVENT_TASK_SYNC then
        self:RefreshRedPoint()
    end
end

function XUiSpecialTrainMusic:RegisterButton()
    self.BtnBack.CallBack = function()
        if XDataCenter.RoomManager.Matching then
            XDataCenter.RoomManager.CancelMatch(function()
                self:Close()
            end)
        else
            self:Close()
        end
    end
    self.BtnMainUi.CallBack = function() 
        XLuaUiManager.RunMain()
    end
    self.BtnCreateRoom.CallBack = function() 
        self:OnClickBtnCreateRoom()
    end
    self.BtnMatch.CallBack = function() 
        self:OnClickBtnMatch()
    end
    self.BtnTask.CallBack = function() 
        self:OnClickBtnTask()
    end
    self.BtnPattern.CallBack = function() 
        self:OnClickBtnPattern()
    end
end

function XUiSpecialTrainMusic:InitDynamicTable()
    ---@type XDynamicTableCurve
    self.DynamicTable = XDynamicTableCurve.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridMusicPlayer)
    self.DynamicTable:SetDelegate(self)
end

function XUiSpecialTrainMusic:SetupDynamicTable()
    self.DynamicTableDataList = XDataCenter.FubenSpecialTrainManager.GetStagesByActivityId(self.ActivityConfig.Id)
    self.StageId = self.DynamicTableDataList[self.SelectedIndex]
    self.DynamicTable:SetDataSource(self.DynamicTableDataList)
    self.DynamicTable:ReloadData()
end

function XUiSpecialTrainMusic:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        index = index  % self.DynamicTable.Imp.TotalCount + 1
        local id = XFubenSpecialTrainConfig.GetAlbumIdByStageId(self.DynamicTableDataList[index])
        grid:Refresh(XFubenSpecialTrainConfig.GetSpecialTrainAlbum(id))
        grid:UpdateSelect(false)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        local startIndex = self.DynamicTable.Imp.StartIndex
        local selectIndex = startIndex % self.DynamicTable.Imp.TotalCount + 1
        self.SelectedIndex = selectIndex
        self:UpdateSelect(selectIndex)
        self.StageId = self.DynamicTableDataList[self.SelectedIndex]
        self.PlayableDirectorFrontEffectEnable.gameObject:SetActiveEx(false)
        self.PlayableDirectorFrontEffectLoop:Stop()

        self.PanelFrontEffect.gameObject:SetActiveEx(true)
        self.PlayableDirectorFrontEffectEnable.gameObject:SetActiveEx(true)
        self.PlayableDirectorFrontEffectEnable.transform:PlayTimelineAnimation(function(isFinish) self:OnPlayFrontEffectEnableFinish(isFinish) end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.DynamicTable.Imp:TweenToIndex(index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_BEGIN_DRAG then
        self.PlayableDirectorFrontEffectEnable.gameObject:SetActiveEx(false)
        self.PlayableDirectorFrontEffectLoop:Stop()
        self.PanelFrontEffect.gameObject:SetActiveEx(false)
    end
end

function XUiSpecialTrainMusic:UpdateSelect(index)
    local id = XFubenSpecialTrainConfig.GetAlbumIdByStageId(self.DynamicTableDataList[index])
    self:UpdateAlbumContent(id)
    if self.CurMusicVolume ~= 0 then
        self:UpdateSpectrum(id)
    end
    local startIndex = self.DynamicTable.Imp.StartIndex
    for idx, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:UpdateSelect(idx == startIndex)
    end

    self.PlayableDirectorBgEffectEnable.gameObject:SetActiveEx(false)
    self.PlayableDirectorBgEffectLoop:Stop()

    self.PlayableDirectorBgEffectEnable.gameObject:SetActiveEx(true)
    self.PlayableDirectorBgEffectEnable.transform:PlayTimelineAnimation(function(isFinish) self:OnPlayBgEffectEnableFinish(isFinish) end)
end

function XUiSpecialTrainMusic:UpdateAlbumContent(id)
    local template = XFubenSpecialTrainConfig.GetSpecialTrainAlbum(id)
    if self.IsFirstHandleSelect then
        self.RImgBg:SetRawImage(template.Bg)
        self.IsFirstHandleSelect = nil
    else
        self.PlayableDirectorBgImgDisable.gameObject:SetActiveEx(false)
        self.PlayableDirectorBgImgEnable.gameObject:SetActiveEx(false)

        self.PlayableDirectorBgImgDisable.gameObject:SetActiveEx(true)
        self.PlayableDirectorBgImgDisable.transform:PlayTimelineAnimation(function(isFinish) self:OnPlayBgImgDisableFinish(isFinish, template.Bg) end)
    end

    self.TxtMusicName.text = template.Name
    self.TxtComposer.text = template.Composer
end

function XUiSpecialTrainMusic:UpdateSpectrum(id)
    local template = XFubenSpecialTrainConfig.GetSpecialTrainAlbum(id)
    CSXAudioManager.PlayMusicWithAnalyzer(template.CueId)
    if self.ScheduleId then
        XScheduleManager.UnSchedule(self.ScheduleId)
        self.ScheduleId = nil
    end
    self.ScheduleId = XScheduleManager.ScheduleForever(function()
        local spectrumData = CSXAudioManager.GetSpectrumLvData()
        for _, panel in ipairs(self.PanelSpectrumList) do
            panel:UpdateSpectrum(spectrumData)
        end
    end, ScheduleIntervalTime, 0)
end

function XUiSpecialTrainMusic:OnClickBtnMain()
    XLuaUiManager.RunMain()
end

function XUiSpecialTrainMusic:OnClickBtnBack()
    if XDataCenter.RoomManager.Matching then
        XDataCenter.RoomManager.CancelMatch(function()
            self:Close()
        end)
    else
        self:Close()
    end
end

function XUiSpecialTrainMusic:OnClickBtnMatch()
    local stageId = self.StageId
    if self.IsHellMode then
        stageId = XFubenSpecialTrainConfig.GetHellStageId(self.StageId)
    end
    XDataCenter.RoomManager.Match(stageId,function()
        self:OnBeginMatch()
        XLuaUiManager.Open("UiOnLineMatching",stageId)
    end)
end

function XUiSpecialTrainMusic:OnClickBtnCreateRoom()
    if self.IsHellMode then
        XDataCenter.RoomManager.CreateRoom(XFubenSpecialTrainConfig.GetHellStageId(self.StageId))
    else
        XDataCenter.RoomManager.CreateRoom(self.StageId)
    end
end

function XUiSpecialTrainMusic:OnClickBtnTask()
    XLuaUiManager.Open("UiSpecialTrainMusicTask")
end

function XUiSpecialTrainMusic:OnBeginMatch()
    self.Mask.gameObject:SetActiveEx(true)
end

function XUiSpecialTrainMusic:OnCancelMatch()
    self.Mask.gameObject:SetActiveEx(false)
end

function XUiSpecialTrainMusic:OnMatchTimeout()
    self:OnCancelMatch()
    XUiManager.DialogTip(CS.XTextManager.GetText("SpecialTrainMusicMatchTipTitle"),CS.XTextManager.GetText("SpecialTrainMusicMatchTipContent"),XUiManager.DialogType.Normal,function() 
        self:OnCancelMatch()
    end,function()
        XDataCenter.RoomManager.MatchRoomByStageTypeRequest(XDataCenter.FubenManager.StageType.SpecialTrainMusic,function() 
            self:OnBeginMatch()
            XLuaUiManager.Open("UiOnLineMatching")
        end)
    end)
end

function XUiSpecialTrainMusic:OnClickBtnPattern()
    self.IsHellMode = self.BtnPattern:GetToggleState()
end

function XUiSpecialTrainMusic:StartTimer()
    if self.Timer then
        self:StopTimer()
    end

    self.Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.TxtTime) then
            self:StopTimer()
            return
        end
        
        local now = XTime.GetServerNowTimestamp()
        if now >= self.EndTime then
            self:StopTimer()
            XUiManager.TipText("CommonActivityEnd")
            XLuaUiManager.RunMain()
            return
        end
        
        local timeDesc = XUiHelper.GetTime(self.EndTime - now, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.text = timeDesc 
    end, XScheduleManager.SECOND)
end

function XUiSpecialTrainMusic:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiSpecialTrainMusic:OnPlayFrontEffectEnableFinish(isFinish)
    if not isFinish then return end
    self.PlayableDirectorFrontEffectLoop:Evaluate()
    self.PlayableDirectorFrontEffectLoop:Play()
end

function XUiSpecialTrainMusic:OnPlayBgEffectEnableFinish(isFinish)
    if not isFinish then return end
    self.PlayableDirectorBgEffectLoop:Evaluate()
    self.PlayableDirectorBgEffectLoop:Play()
end

function XUiSpecialTrainMusic:OnPlayBgImgDisableFinish(isFinish, bgPath)
    if not isFinish then return end
    self.RImgBg:SetRawImage(bgPath)
    self.PlayableDirectorBgImgEnable.gameObject:SetActiveEx(true)
    self.PlayableDirectorBgImgEnable.transform:PlayTimelineAnimation()
end

function XUiSpecialTrainMusic:GetHelpDataFunc()
    local helpIds = {}
    local chapterConfig = XFubenSpecialTrainConfig.GetChapterConfigById(self.ActivityConfig.ChapterIds[1])
    for _, var in ipairs(chapterConfig.HelpId) do
        table.insert(helpIds, var)
    end

    if not helpIds then
        return
    end

    local helpConfigs = {}
    for i = 1, #helpIds do
        helpConfigs[i] = XHelpCourseConfig.GetHelpCourseTemplateById(helpIds[i])
    end

    return helpConfigs
end

function XUiSpecialTrainMusic:RefreshRedPoint()
    local isShowRedDot = XDataCenter.FubenSpecialTrainManager.CheckTaskAchieved()
    self.BtnTask:ShowReddot(isShowRedDot)
end

return XUiSpecialTrainMusic