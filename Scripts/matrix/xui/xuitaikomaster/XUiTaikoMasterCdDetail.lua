local XUiTaikoMasterFlowText = require("XUi/XUiTaikoMaster/XUiTaikoMasterFlowText")

---@class XUiTaikoMasterCdDetail
local XUiTaikoMasterCdDetail = XClass(nil, "XUiTaikoMasterCdDetail")

function XUiTaikoMasterCdDetail:Ctor(ui)
    self.Transform = ui
    XTool.InitUiObject(self)
    self._SongId = false
    self._Difficulty = false
    ---@type XUiTaikoMasterFlowText
    self._FlowText = XUiTaikoMasterFlowText.New(self.TxtMusicName, self.MaskMusicPlayer)
    self._TxtNameInitX = false
    self:RegisterButtonClick()
end

function XUiTaikoMasterCdDetail:KillFlowText()
    self._FlowText:Stop()
end

function XUiTaikoMasterCdDetail:PlayEnableAnimation()
    self.PanelCdDailyEnable.gameObject:PlayTimelineAnimation()
end

function XUiTaikoMasterCdDetail:IsActive()
    return self.Transform.gameObject.activeInHierarchy
end

function XUiTaikoMasterCdDetail:SetActiveEx(isEnable)
    self.Transform.gameObject:SetActiveEx(isEnable)
    if isEnable then
        self._FlowText:Play()
    else
        self._FlowText:Stop()
    end
end

function XUiTaikoMasterCdDetail:RegisterButtonClick()
    XUiHelper.RegisterClickEvent(
        self,
        self.BtnPlay,
        function()
            local stageId = XTaikoMasterConfigs.GetStageId(self._SongId, self._Difficulty)
            XDataCenter.TaikoMasterManager.OpenUiRoom(stageId)
        end
    )
    XUiHelper.RegisterClickEvent(
        self,
        self.BtnEasy,
        function()
            self.QieHuan.gameObject:PlayTimelineAnimation()
            self:SetDifficulty(XTaikoMasterConfigs.Difficulty.Easy)
        end
    )
    XUiHelper.RegisterClickEvent(
        self,
        self.BtnHard,
        function()
            self.QieHuan.gameObject:PlayTimelineAnimation()
            self:SetDifficulty(XTaikoMasterConfigs.Difficulty.Hard)
        end
    )
    XUiHelper.RegisterClickEvent(
        self,
        self.ButtonDetail,
        function()
            XEventManager.DispatchEvent(XEventId.EVENT_TAIKO_MASTER_STAGE_SELECT, false)
        end
    )
end

function XUiTaikoMasterCdDetail:Refresh(songId)
    local coverImage = XTaikoMasterConfigs.GetSongCoverImage(songId)
    self._SongId = songId
    local coverImage = XTaikoMasterConfigs.GetSongCoverImage(songId)
    self.RImgCd:SetRawImage(coverImage)
    self.RImgCdPan:SetRawImage(coverImage)
    local desc1, desc2 = XTaikoMasterConfigs.GetSongDesc(songId)
    self.TxtCi.text = desc1
    self.TxtQu.text = desc2
    self.TxtMusicName.text = XTaikoMasterConfigs.GetSongName(songId)
    self._Difficulty = XTaikoMasterConfigs.Difficulty.Easy
    self:RefreshDifficulty()
    self:RefreshDifficultyBtn()
end

function XUiTaikoMasterCdDetail:SetDifficulty(difficulty)
    self._Difficulty = difficulty
    self:RefreshDifficulty()
    self:RefreshDifficultyBtn()
end

function XUiTaikoMasterCdDetail:RefreshDifficultyBtn()
    if self._Difficulty == XTaikoMasterConfigs.Difficulty.Hard then
        self.BtnEasy:SetButtonState(CS.UiButtonState.Normal)
        self.BtnHard:SetButtonState(CS.UiButtonState.Select)
    elseif self._Difficulty == XTaikoMasterConfigs.Difficulty.Easy then
        self.BtnEasy:SetButtonState(CS.UiButtonState.Select)
        self.BtnHard:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiTaikoMasterCdDetail:RefreshDifficulty()
    local songId = self._SongId
    local assess = XDataCenter.TaikoMasterManager.GetMyAssess(self._SongId, self._Difficulty)
    if assess == XTaikoMasterConfigs.Assess.None then
        local emptyStr = XUiHelper.GetText("TaikoMasterEmpty")
        self.TxtScore.text = emptyStr
        self.TxtAccuracy.text = emptyStr
        self.TxtCombo.text = emptyStr
        self.ImgCdTag.gameObject:SetActiveEx(false)
    else
        self.TxtScore.text = XDataCenter.TaikoMasterManager.GetMyScoreBySong(songId, self._Difficulty)
        local accuracy = XDataCenter.TaikoMasterManager.GetMyAccuracyBySong(self._SongId, self._Difficulty)
        self.TxtAccuracy.text = string.format("%d%%", accuracy)
        self.TxtCombo.text = XDataCenter.TaikoMasterManager.GetMyComboBySong(self._SongId, self._Difficulty)
        self.ImgCdTag.gameObject:SetActiveEx(true)
        self.RImgClass:SetRawImage(XTaikoMasterConfigs.GetAssessImage(assess))
    end
    local isPerfectCombo = XDataCenter.TaikoMasterManager.IsPerfectCombo(self._SongId, self._Difficulty)
    if isPerfectCombo then
        self.TxtGreat.gameObject:SetActiveEx(false)
        self.TxtPerfect.gameObject:SetActiveEx(true)
        if self.TxtPerfect.gameObject.activeInHierarchy then
            self.TxtPerfectEnable.gameObject:PlayTimelineAnimation()
        end
    else
        self.TxtGreat.gameObject:SetActiveEx(XDataCenter.TaikoMasterManager.IsFullCombo(self._SongId, self._Difficulty))
        self.TxtPerfect.gameObject:SetActiveEx(false)
    end
end

function XUiTaikoMasterCdDetail:GetRectTransform()
    return self.Transform
end

return XUiTaikoMasterCdDetail
