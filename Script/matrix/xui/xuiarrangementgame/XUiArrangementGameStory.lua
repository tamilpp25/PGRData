---@field _Control XArrangementGameControl
---@class XUiArrangementGameStory : XLuaUi
local XUiArrangementGameStory = XLuaUiManager.Register(XLuaUi, "UiArrangementGameStory")

function XUiArrangementGameStory:OnAwake()
    self:InitButton()
end

function XUiArrangementGameStory:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnPlay, self.OnBtnPlayClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPause, self.OnBtnPlayClick)
end

function XUiArrangementGameStory:OnStart(gameMusicId, isShowConfirm)
    self.GameMusicId = gameMusicId

    XLuaAudioManager.StopCurrentBGM()
    local allGameMusicConfig = XMVCA.XArrangementGame:GetModelArrangementGameMusic()
    self.GameMusicConfig = allGameMusicConfig[gameMusicId]
    self:RefreshUiShow()
    self.BtnConfirm.gameObject:SetActiveEx(isShowConfirm)
end

function XUiArrangementGameStory:RefreshUiShow()
    self.ImgBar.fillAmount = 0
    local checkShow2Condition = XMVCA.XMusicGameActivity:CheckShow2Condition(self.GameMusicId)
    self.RImgEnding:SetRawImage(checkShow2Condition and self.GameMusicConfig.ResBgSp or self.GameMusicConfig.ResBg)
    self.TxtDetail.text = checkShow2Condition and self.GameMusicConfig.ResTextSp or self.GameMusicConfig.ResText
    self.TitleName.text = checkShow2Condition and self.GameMusicConfig.NameSp or self.GameMusicConfig.Name

    -- 选项合集
    local allSelectionConfig = self._Control:GetModelArrangementGameSelection()
    for i = 1, #self.GameMusicConfig.Selections, 1 do
        local selectionId = self.GameMusicConfig.Selections[i]
        local selectionConfig = allSelectionConfig[selectionId]
        local text = self["SelectionText"..i]
        text.text = selectionConfig.Name
    end

    -- 时间
    local duration = CS.XAudioManager.GetCueTemplate(self.GameMusicConfig.ResCueId).Duration
    self.TxtTotalTime.text = XUiHelper.GetTime(duration/1000, XUiHelper.TimeFormatType.MINUTE_SECOND)
end

function XUiArrangementGameStory:OnBtnPlayClick()
    if self.CurMusicInfo then
        if not self.CurMusicInfo.Pausing then
            self.CurMusicInfo:Pause()
            self.BtnPlay.gameObject:SetActiveEx(true)
            self.BtnPause.gameObject:SetActiveEx(false)
        else
            self.CurMusicInfo:Resume()
            self.BtnPlay.gameObject:SetActiveEx(false)
            self.BtnPause.gameObject:SetActiveEx(true)
        end
        return
    end

    local updateFun = function ()
        if not self.CurMusicInfo then
            return
        end

        if XTool.UObjIsNil(self.GameObject) then
            return
        end

        local allDuration = self.CurMusicInfo.Duration
        local curTime =  XMath.Clamp(self.CurMusicInfo.Time, 0, allDuration)
        self.ImgBar.fillAmount = curTime / allDuration
        self.TxtTime.text = XUiHelper.GetTime(curTime/1000, XUiHelper.TimeFormatType.MINUTE_SECOND)
    end

    local finCb = function ()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        
        self.BtnPlay.gameObject:SetActiveEx(true)
        self.BtnPause.gameObject:SetActiveEx(false)
        self.CurMusicInfo = nil
    end

    self.BtnPlay.gameObject:SetActiveEx(false)
    self.BtnPause.gameObject:SetActiveEx(true)
    self.CurMusicInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, self.GameMusicConfig.ResCueId, true, finCb, updateFun)
end

function XUiArrangementGameStory:OnDestroy()
    if self.CurMusicInfo then
        self.CurMusicInfo:Stop()
    end
end

return XUiArrangementGameStory
