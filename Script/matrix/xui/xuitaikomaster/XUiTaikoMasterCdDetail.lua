local XUiTaikoMasterFlowText = require("XUi/XUiTaikoMaster/XUiTaikoMasterFlowText")

---@class XUiTaikoMasterCdDetail:XUiNode
---@field _Control XTaikoMasterControl
local XUiTaikoMasterCdDetail = XClass(XUiNode, "XUiTaikoMasterCdDetail")

function XUiTaikoMasterCdDetail:OnStart()
    self._SongId = false
    self._Difficulty = false
    ---@type XUiTaikoMasterFlowText
    self._FlowText = XUiTaikoMasterFlowText.New(self.TxtMusicName, self.MaskMusicPlayer)
    self._TxtNameInitX = false
    self:RegisterButtonClick()
end

function XUiTaikoMasterCdDetail:OnEnable()
    self._Control:UpdateUiData()
    self._FlowText:Play()
end

function XUiTaikoMasterCdDetail:OnDisable()
    self._FlowText:Stop()
end

function XUiTaikoMasterCdDetail:KillFlowText()
    self._FlowText:Stop()
end

function XUiTaikoMasterCdDetail:PlayEnableAnimation()
    self.PanelCdDailyEnable.gameObject:PlayTimelineAnimation()
end

function XUiTaikoMasterCdDetail:RegisterButtonClick()
    local uiData = self._Control:GetUiData()
    XUiHelper.RegisterClickEvent(
        self,
        self.BtnPlay,
        function()
            local stageId = uiData and uiData:GetSongStageId(self._SongId, self._Difficulty)
            self._Control:OpenBattleRoom(stageId)
        end
    )
    XUiHelper.RegisterClickEvent(
        self,
        self.BtnEasy,
        function()
            self.QieHuan.gameObject:PlayTimelineAnimation()
            self:SetDifficulty(XEnumConst.TAIKO_MASTER.DIFFICULTY.EASY)
        end
    )
    XUiHelper.RegisterClickEvent(
        self,
        self.BtnHard,
        function()
            self.QieHuan.gameObject:PlayTimelineAnimation()
            self:SetDifficulty(XEnumConst.TAIKO_MASTER.DIFFICULTY.HARD)
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
    self._SongId = songId
    self._Difficulty = XEnumConst.TAIKO_MASTER.DIFFICULTY.EASY
    
    local songUiData = self._Control:GetUiData().SongUiDataDir[songId]
    if songUiData then
        self.RImgCd:SetRawImage(songUiData.Cover)
        self.RImgCdPan:SetRawImage(songUiData.Cover)
        self.TxtCi.text = songUiData.LyricistDesc
        self.TxtQu.text = songUiData.ComposerDesc
        self.TxtMusicName.text = songUiData.Name
    end
    self:RefreshDifficulty()
    self:RefreshDifficultyBtn()
end

function XUiTaikoMasterCdDetail:SetDifficulty(difficulty)
    self._Difficulty = difficulty
    self:RefreshDifficulty()
    self:RefreshDifficultyBtn()
end

function XUiTaikoMasterCdDetail:RefreshDifficultyBtn()
    if self._Difficulty == XEnumConst.TAIKO_MASTER.DIFFICULTY.HARD then
        self.BtnEasy:SetButtonState(CS.UiButtonState.Normal)
        self.BtnHard:SetButtonState(CS.UiButtonState.Select)
    elseif self._Difficulty == XEnumConst.TAIKO_MASTER.DIFFICULTY.EASY then
        self.BtnEasy:SetButtonState(CS.UiButtonState.Select)
        self.BtnHard:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiTaikoMasterCdDetail:RefreshDifficulty()
    ---@type XTaikoMasterSongPlayUiData
    local songPlayData
    if self._Difficulty == XEnumConst.TAIKO_MASTER.DIFFICULTY.EASY then
        songPlayData = self._Control:GetUiData().SongEasyPlayDataDir[self._SongId]
    else
        songPlayData = self._Control:GetUiData().SongHardPlayDataDir[self._SongId]
    end
    
    if not songPlayData or songPlayData.MyAssess == XEnumConst.TAIKO_MASTER.ASSESS.NONE then
        local emptyStr = XUiHelper.GetText("TaikoMasterEmpty")
        self.TxtScore.text = emptyStr
        self.TxtAccuracy.text = emptyStr
        self.TxtCombo.text = emptyStr
        self.ImgCdTag.gameObject:SetActiveEx(false)
        self.TxtGreat.gameObject:SetActiveEx(false)
        self.TxtPerfect.gameObject:SetActiveEx(false)
    else
        self.TxtScore.text = songPlayData.MyScore
        self.TxtAccuracy.text = string.format("%d%%", songPlayData.MyAccuracy)
        self.TxtCombo.text = songPlayData.MyCombo
        self.ImgCdTag.gameObject:SetActiveEx(true)
        self.RImgClass:SetRawImage(songPlayData.AssessImage)
        
        if songPlayData.IsPerfectCombo then
            self.TxtGreat.gameObject:SetActiveEx(false)
            self.TxtPerfect.gameObject:SetActiveEx(true)
            if self.TxtPerfect.gameObject.activeInHierarchy then
                self.TxtPerfectEnable.gameObject:PlayTimelineAnimation()
            end
        else
            self.TxtGreat.gameObject:SetActiveEx(songPlayData.IsFullCombo)
            self.TxtPerfect.gameObject:SetActiveEx(false)
        end
    end
end

function XUiTaikoMasterCdDetail:GetRectTransform()
    return self.Transform
end

return XUiTaikoMasterCdDetail
