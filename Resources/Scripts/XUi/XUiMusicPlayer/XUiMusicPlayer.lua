--
-- Author: wujie
-- Note: 播放器的专辑界面
local XUiMusicPlayer = XLuaUiManager.Register(XLuaUi, "UiMusicPlayer")

local XUiGridMusicPlayer = require("XUi/XUiMusicPlayer/XUiGridMusicPlayer")
local XUiPanelMusicSpectrum = require("XUi/XUiMusicPlayer/XUiPanelMusicSpectrum")

local ScheduleIntervalTime = CS.XGame.ClientConfig:GetInt("MusicPlayerSpectrumIntervalTime")
local CSXAudioManager = CS.XAudioManager

function XUiMusicPlayer:OnAwake()
    self.PanelSpectrumList = {
        XUiPanelMusicSpectrum.New(self.PanelLeftBar),
        XUiPanelMusicSpectrum.New(self.PanelRightBar),
    }

    self:InitDynamicTable()
    self:AutoAddListener()
end

function XUiMusicPlayer:OnStart(closeCallback)
    self.CloseCallback = closeCallback
    self.IsFirstHandleSelect = true

    CSXAudioManager.StopAll()

    self.CurMusicVolume = CSXAudioManager.GetMusicVolume()
    self.DynamicTableDataList = XMusicPlayerConfigs.GetAlbumIdList()

    local uiMainNeedPlayedAlbumId = XDataCenter.MusicPlayerManager.GetUiMainNeedPlayedAlbumId()
    for index, id in ipairs(self.DynamicTableDataList) do
        if id == uiMainNeedPlayedAlbumId then
            self.SelectedIndex = index
            break
        end
    end
    if not self.SelectedIndex then
        self.SelectedIndex = 1
    end
end

function XUiMusicPlayer:OnEnable()
    self:UpdateDynamicTable()
    self:UpdateSelect(self.SelectedIndex)
    self.PlayableDirectorFrontEffectEnable.transform:PlayTimelineAnimation(function(isFinish) self:OnPlayFrontEffectEnableFinish(isFinish) end)
    self.PanelFrontEffect.gameObject:SetActiveEx(true)
end

function XUiMusicPlayer:OnDisable()
    if self.ScheduleId then
        XScheduleManager.UnSchedule(self.ScheduleId)
        self.ScheduleId = nil
    end
    CSXAudioManager.StopMusicWithAnalyzer()
    CSXAudioManager.PlayMusic(CSXAudioManager.UiMainNeedPlayedBgmCueId)
end

function XUiMusicPlayer:AutoAddListener()
    self.BtnBack.CallBack = function() self:OnClose() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
    self.BtnChange.CallBack = function() self:OnBtnChangeClick() end
end

function XUiMusicPlayer:InitDynamicTable()
    self.DynamicTable = XDynamicTableCurve.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridMusicPlayer)
    self.DynamicTable:SetDelegate(self)
end

function XUiMusicPlayer:UpdateDynamicTable()
    self.DynamicTableDataList = self.DynamicTableDataList or {}
    self.DynamicTable:SetDataSource(self.DynamicTableDataList)
    self.DynamicTable:ReloadData(#self.DynamicTableDataList > 0 and (self.SelectedIndex - 1) or -1)
end

function XUiMusicPlayer:UpdateAlbumContent(id)
    local template = XMusicPlayerConfigs.GetAlbumTemplateById(id)
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
    if XDataCenter.MusicPlayerManager.GetUiMainNeedPlayedAlbumId() == id then
        self.BtnChange.gameObject:SetActiveEx(false)
        self.ImgChangeDisable.gameObject:SetActiveEx(true)
    else
        self.BtnChange.gameObject:SetActiveEx(true)
        self.ImgChangeDisable.gameObject:SetActiveEx(false)
    end
end

function XUiMusicPlayer:UpdateSpectrum(id)
    local template = XMusicPlayerConfigs.GetAlbumTemplateById(id)
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

function XUiMusicPlayer:UpdateSelect(index)
    local id = self.DynamicTableDataList[index]
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

--事件相关------------------------------------>>>
function XUiMusicPlayer:OnClose()
    if self.CloseCallback then
        self.CloseCallback()
        self.CloseCallback = nil
    end
    self:Close()
end

function XUiMusicPlayer:OnBtnMainUiClick()
    if self.CloseCallback then
        self.CloseCallback()
        self.CloseCallback = nil
    end
    XLuaUiManager.RunMain()
end

function XUiMusicPlayer:OnBtnChangeClick()
    local selelctedId = self.DynamicTableDataList[self.SelectedIndex]
    if selelctedId == XDataCenter.MusicPlayerManager.GetUiMainNeedPlayedAlbumId() then return end
    XDataCenter.MusicPlayerManager.ChangeUiMainAlbumId(selelctedId)
    self.BtnChange.gameObject:SetActiveEx(false)
    self.ImgChangeDisable.gameObject:SetActiveEx(true)
    XUiManager.TipError(CS.XTextManager.GetText("MusicPlayerAlbumSetSuccess"))
end

function XUiMusicPlayer:OnPlayFrontEffectEnableFinish(isFinish)
    if not isFinish then return end
    self.PlayableDirectorFrontEffectLoop:Evaluate()
    self.PlayableDirectorFrontEffectLoop:Play()
end

function XUiMusicPlayer:OnPlayBgEffectEnableFinish(isFinish)
    if not isFinish then return end
    self.PlayableDirectorBgEffectLoop:Evaluate()
    self.PlayableDirectorBgEffectLoop:Play()
end

function XUiMusicPlayer:OnPlayBgImgDisableFinish(isFinish, bgPath)
    if not isFinish then return end
    self.RImgBg:SetRawImage(bgPath)
    self.PlayableDirectorBgImgEnable.gameObject:SetActiveEx(true)
    self.PlayableDirectorBgImgEnable.transform:PlayTimelineAnimation()
end

function XUiMusicPlayer:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        index = index % self.DynamicTable.Imp.TotalCount + 1
        local id = self.DynamicTableDataList[index]
        grid:Refresh(id)
        grid:UpdateSelect(false)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_TWEEN_OVER then
        local startIndex = self.DynamicTable.Imp.StartIndex
        local selectIndex = startIndex % self.DynamicTable.Imp.TotalCount + 1
        if self.SelectedIndex ~= selectIndex then
            self.SelectedIndex = selectIndex
            self:UpdateSelect(selectIndex)
        end

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
--事件相关------------------------------------<<<