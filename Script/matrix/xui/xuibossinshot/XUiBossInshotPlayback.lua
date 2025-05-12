---@class XUiBossInshotPlayback:XLuaUi
---@field private _Control XBossInshotControl
local XUiBossInshotPlayback = XLuaUiManager.Register(XLuaUi, "UiBossInshotPlayback")
local XUiGridPlayback = XClass(XUiNode, "XUiGridPlayback")

function XUiBossInshotPlayback:OnAwake()
    self:RegisterUiEvents()
    self.UiGridPlayback1 = XUiGridPlayback.New(self.GridPlayback1, self, 1)
    self.UiGridPlayback2 = XUiGridPlayback.New(self.GridPlayback2, self, 2)
end

function XUiBossInshotPlayback:OnStart(bossId, playbackData)
    self.BossId = bossId
    self.PlaybackData = playbackData
end

function XUiBossInshotPlayback:OnEnable()
    self:Refresh()
end

function XUiBossInshotPlayback:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
end

function XUiBossInshotPlayback:OnBtnCoverClick(index)
    self._Control:SavePlaybackData(self.BossId, index, self.PlaybackData)
    self:Refresh()
end

function XUiBossInshotPlayback:OnBtnSaveClick(index)
    self._Control:SavePlaybackData(self.BossId, index, self.PlaybackData)
    self:Refresh()
end

function XUiBossInshotPlayback:OnBtnPlayClick(index)
    -- 回放功能禁用
    local isShowPlayback = self._Control:GetIsShowPlayback()
    if not isShowPlayback then
        XUiManager.TipText("BossInshotPlaybackDisabledTips")
        return
    end
    
    -- 播放回放
    local playbackDatas = self._Control:GetPlaybackDatas(self.BossId)
    local data = playbackDatas[index]
    local stageCfg = XMVCA.XFuben:GetStageCfg(data.StageId)
    CS.XReplayManager.RunFight(data.FightDataPath, stageCfg.LoadingType)
end

function XUiBossInshotPlayback:OnBtnDeleteClick(index)
    local title = XUiHelper.GetText("TipTitle")
    local content = XUiHelper.GetText("BossInshotDeletePlaybackConfirm")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        self._Control:DeletePlaybackData(self.BossId, index)
        self:Refresh()
    end)
end

function XUiBossInshotPlayback:Refresh()
    local playbackDatas = self._Control:GetPlaybackDatas(self.BossId)
    local isSave = self.PlaybackData ~= nil
    self.UiGridPlayback1:Refresh(playbackDatas[1], isSave)
    self.UiGridPlayback2:Refresh(playbackDatas[2], isSave)
end

---------------------------------------- #region XUiGridPlayback ----------------------------------------

function XUiGridPlayback:OnStart(pos)
    self.Pos = pos
    self:RegisterUiEvents()
end

function XUiGridPlayback:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnCover, self.OnBtnCoverClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSave, self.OnBtnSaveClick)
    XUiHelper.RegisterClickEvent(self, self.BtnPlay, self.OnBtnPlayClick)
    XUiHelper.RegisterClickEvent(self, self.BtnDelete, self.OnBtnDeleteClick)
end

function XUiGridPlayback:OnBtnCoverClick()
    self.Parent:OnBtnCoverClick(self.Pos)
end

function XUiGridPlayback:OnBtnSaveClick()
    self.Parent:OnBtnSaveClick(self.Pos)
end

function XUiGridPlayback:OnBtnPlayClick()
    self.Parent:OnBtnPlayClick(self.Pos)
end

function XUiGridPlayback:OnBtnDeleteClick()
    self.Parent:OnBtnDeleteClick(self.Pos)
end

function XUiGridPlayback:Refresh(playbackData, isSave)
    local isShowPlayback = playbackData ~= nil
    self.Info.gameObject:SetActiveEx(isShowPlayback)
    self.Empty.gameObject:SetActiveEx(not isShowPlayback)
    if isShowPlayback then
        local icon = XMVCA.XCharacter:GetCharSmallHeadIcon(playbackData.CharacterId, true)
        self.RImgIcon:SetRawImage(icon)
        self.TextName.text = XMVCA.XCharacter:GetCharacterFullNameStr(playbackData.CharacterId)
        self.TextScore.text = playbackData.Score
        self.RImgScore:SetRawImage(playbackData.ScoreLevelIcon)
        local timeStr = XUiHelper.GetTime(playbackData.Time, XUiHelper.TimeFormatType.DAY_HOUR)
        self.TextTime.text = XUiHelper.GetText("BossInshotFightTime", timeStr)
    end

    self.BtnCover.gameObject:SetActiveEx(isSave and isShowPlayback)
    self.BtnSave.gameObject:SetActiveEx(isSave and not isShowPlayback)
    self.BtnPlay.gameObject:SetActiveEx(not isSave and isShowPlayback)
    self.BtnDelete.gameObject:SetActiveEx(not isSave and isShowPlayback)
end
---------------------------------------- #endregion XUiGridPlayback ----------------------------------------

return XUiBossInshotPlayback