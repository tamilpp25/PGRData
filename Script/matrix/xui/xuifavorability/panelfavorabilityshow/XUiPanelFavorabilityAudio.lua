local XUiGridLikeAudioItem=require("XUi/XUiFavorability/PanelFavorabilityShow/XUiGridLikeAudioItem")
local XUiPanelFavorabilityAudio = XClass(XUiNode, "XUiPanelFavorabilityAudio")

local CurrentAudioSchedule = nil
local loadGridComplete

function XUiPanelFavorabilityAudio:OnStart(uiRoot)
    self.UiRoot = uiRoot
    XTool.InitUiObject(self)

    self.GridLikeAudioItem.gameObject:SetActiveEx(false)
    self.PanelEmpty.gameObject:SetActiveEx(false)
    self.Content=self.SViewAudioList.transform:Find('Viewport/Content'):GetComponent('RectTransform')
end

function XUiPanelFavorabilityAudio:OnEnable()
    self._Control:SetDontStopCvContent(false)
    self:RefreshDatas()
end

function XUiPanelFavorabilityAudio:OnDisable()
    loadGridComplete = false
    --self.DynamicTableAudios:RecycleAllTableGrid()
end

function XUiPanelFavorabilityAudio:RefreshDatas()
    local currentCharacterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local audioDatas = XMVCA.XFavorability:GetCharacterVoiceById(currentCharacterId)

    self:UpdateAudioList(audioDatas)
end

-- [装载数据]
function XUiPanelFavorabilityAudio:UpdateAudioList(audioDatas)
    if not audioDatas then
        self.PanelEmpty.gameObject:SetActiveEx(true)
        self.TxtNoDataTip.text = CS.XTextManager.GetText("FavorabilityNoAudioData")
        self.AudioList = {}
    else
        self.PanelEmpty.gameObject:SetActiveEx(false)
        self:SortAudios(audioDatas)

        for k, v in pairs(audioDatas or {}) do
            if self.CurAudio and self.CurAudio.config.Id == v.config.Id then
                v.IsPlay = true
                self.CurAudio.Index = k
            else
                v.IsPlay = false
            end
        end
        self.AudioList = audioDatas
    end


    if not self.DynamicTableAudios then
        self.DynamicTableAudios = XDynamicTableNormal.New(self.SViewAudioList.gameObject)
        self.DynamicTableAudios:SetProxy(XUiGridLikeAudioItem,self.UiRoot)
        self.DynamicTableAudios:SetDelegate(self)
    end

    self.DynamicTableAudios:SetDataSource(self.AudioList)
    self.DynamicTableAudios:ReloadDataASync()
end

function XUiPanelFavorabilityAudio:SortAudios(audios)
    -- 已解锁，可解锁，未解锁
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    for _, audio in pairs(audios) do
        local isUnlock = self._Control:IsVoiceUnlock(characterId, audio.config.Id)
        local canUnlock = self._Control:CanVoiceUnlock(characterId, audio.config.Id)

        audio.priority = 2
        if not isUnlock then
            audio.priority = canUnlock and 1 or 3
        end
    end
    table.sort(audios, function(audioA, audioB)
        if audioA.priority == audioB.priority then
            return audioA.config.Id < audioB.config.Id
        else
            return audioA.priority < audioB.priority
        end
    end)
end

-- [监听动态列表事件]
function XUiPanelFavorabilityAudio:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.AudioList[index]
        if data ~= nil then
            grid:OnRefresh(self.AudioList[index], index)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if self.CurAudio and self.AudioList[index] then
            if self.CurAudio.config.Id == self.AudioList[index].config.Id and self.CurrentPlayAudio and self.CurAudio.IsPlay then
                self.CurAudio.IsPlay = false
                grid:OnRefresh(self.CurAudio, index)
                self:UnScheduleAudio()
                return
            end
        end
        self:OnAudioClick(self.AudioList[index], grid, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        loadGridComplete = true
        if self.Content then
            self.Content.anchoredPosition=Vector2(self.Content.anchoredPosition.x,0)
        end
    end
end

function XUiPanelFavorabilityAudio:ResetPlayStatus(index)
    for k, v in pairs(self.AudioList) do
        v.IsPlay = (k == index)
        local grid = self.DynamicTableAudios:GetGridByIndex(k)
        if grid then
            grid:OnRefresh(v, k)
        end
    end
end

function XUiPanelFavorabilityAudio:UpdateGrids()
    for i = 1, #self.AudioList do
        local grid = self.DynamicTableAudios:GetGridByIndex(i)
        if grid then
            grid:UpdatePlayStatus()
        end
    end
end

-- [音频按钮点击事件]
function XUiPanelFavorabilityAudio:OnAudioClick(clickAudio, grid, index)
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    local isUnlock = self._Control:IsVoiceUnlock(characterId, clickAudio.config.Id)
    local canUnlock = self._Control:CanVoiceUnlock(characterId, clickAudio.config.Id)

    if isUnlock or canUnlock then
        if canUnlock and not isUnlock then
            XMVCA.XFavorability:OnUnlockCharacterVoice(characterId, clickAudio.config.Id,true)
            grid:HideRedDot()
            XEventManager.DispatchEvent(XEventId.EVENT_FAVORABILITY_AUDIOUNLOCK)
        end
        --如果语音打断了动作，则播放打断特效
        self.UiRoot:SetWhetherPlayChangeActionEffect(true)
        self:UnScheduleAudio()
        self:ResetPlayStatus(index)
        local isFinish = false
        local progress = 0
        local updateCount = 0

        self.CurAudio = clickAudio
        self.CurAudio.Index = index

        --语音播放完后，isFinish还是处于false(progress未能达到阈值)，就会调用回调
        
        self.CurrentPlayAudio = CS.XAudioManager.PlayCvWithCvType(clickAudio.config.CvId, self.Parent.CvType, function()
        if not isFinish then
            isFinish = true
            local clickGrid = self:FindClickGrid() or grid
            if not clickGrid then
                XLog.Error("XUiPanelFavorabilityAudio:OnAudioClick函数错误：clickGrid不能为空")
                return
            end
            self:UnScheduleAudio(clickAudio, clickGrid)
        end
        end)
        
        self.UiRoot:PlayCvContent(clickAudio.config.CvId, self.Parent.CvType)
        self.NotFreeze=true
        self.UiRoot:SetWhetherPlayChangeActionEffect(false)         --重置播放打断特效标志
        self.UiRoot.SignBoard:SetPlayingAudio(true)                 --正在播放语音页签下语音，播放新动作时要播放打断特效

        CurrentAudioSchedule = XScheduleManager.ScheduleForever(function()
            if self.NotFreeze then
                self.UiRoot:PauseCvContent()
                self.NotFreeze=false
            end
            local clickGrid = self:FindClickGrid() or grid
            if not clickGrid then
                XLog.Error("XUiPanelFavorabilityAudio:OnAudioClick函数错误：clickGrid不能为空")
                return
            end

            if self.CurrentPlayAudio.Done then
                if self.CurrentPlayAudio.Duration <= 0 then
                    return
                end

                progress = self.CurrentPlayAudio.Time / self.CurrentPlayAudio.Duration
                if progress >= 1 then
                    progress = 1
                    isFinish = true
                end

                if clickGrid:GetAudioDataId() == clickAudio.config.Id then
                    clickGrid:UpdateProgress(progress)
                    clickGrid:UpdateMicroAlpha(updateCount)
                end
                updateCount = updateCount + 1
            end

            if not self.CurrentPlayAudio or isFinish then
                self:UnScheduleAudio(clickAudio, clickGrid)
            end
        end, 20)
    else
        XUiManager.TipMsg(clickAudio.config.ConditionDescript)
    end
end

-- [用于寻找当前播放语音所在的Grid]
function XUiPanelFavorabilityAudio:FindClickGrid()
    local clickGrid
    if loadGridComplete then
        --找到点击的index所在的Grid
        clickGrid = self.DynamicTableAudios:GetGridByIndex(self.CurAudio.Index)
    end
    return clickGrid
end

function XUiPanelFavorabilityAudio:UnScheduleAudio(clickAudio,clickGrid)
    self.UiRoot.SignBoard:SetPlayingAudio(false)    --停止播放语音页签下语音，播放新动作时不用播放打断特效
    if CurrentAudioSchedule then
        XScheduleManager.UnSchedule(CurrentAudioSchedule)
        CurrentAudioSchedule = nil
    end

    if self.CurrentPlayAudio then
        self.CurAudio = nil
        self.CurrentPlayAudio:Stop()
        self.CurrentPlayAudio = nil
        if not self._Control:GetDontStopCvContent() then
            self.UiRoot:StopCvContent()
        end
    end

    if clickAudio and clickGrid then
        clickAudio.IsPlay = false
        if clickGrid:GetAudioDataId() == clickAudio.config.Id then
            clickGrid:UpdatePlayStatus()
            clickGrid:UpdateProgress(0)
        end
    end
    self.UiRoot:ResumeCvContent()
end

function XUiPanelFavorabilityAudio:SetViewActive(isActive)
    self:UnScheduleAudio()

    if isActive then
        self:Open()
    else
        self:Close()
    end
end

function XUiPanelFavorabilityAudio:OnSelected(isSelected)
    if isSelected then
        self:Open()
    else
        self:Close()
    end
end


return XUiPanelFavorabilityAudio