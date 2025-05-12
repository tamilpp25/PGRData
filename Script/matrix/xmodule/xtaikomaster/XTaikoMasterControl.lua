---@class XTaikoMasterControl : XControl
---@field private _Model XTaikoMasterModel
local XTaikoMasterControl = XClass(XControl, "XTaikoMasterControl")

local RequestProto = {
    RequestGetRankInfo = "TaikoMasterGetRankInfoRequest", -- 获取排行信息
    RequestModifyOffset = "TaikoMasterModifyOffsetRequest"
}

function XTaikoMasterControl:OnInit()
    ---@type table
    self._StageId2SongId = nil
end

function XTaikoMasterControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XTaikoMasterControl:RemoveAgencyEvent()

end

function XTaikoMasterControl:OnRelease()
    self._StageId2SongId = nil
end

--region Server
function XTaikoMasterControl:RequestRankData(songId, cb)
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.RequestGetRankInfo,
            {StageId = self._Model:GetSongCfgStageId(songId, XEnumConst.TAIKO_MASTER.DEFAULT_RANK_DIFFICULTY)},
            function(result)
                if result.Code ~= XCode.Success then
                    return
                end
                self._Model:SetRankData(songId, result)
                self:UpdateUiData()
                if cb then cb() end
            end)
end

function XTaikoMasterControl:RequestSaveSetting(appearScale, judgeScale)
    XNetwork.CallWithAutoHandleErrorCode(RequestProto.RequestModifyOffset,
            {AppearOffset = appearScale, JudgeOffset = judgeScale},
            function(result)
                if result.Code ~= XCode.Success then
                    return
                end
                self._Model:SetSetting(appearScale, judgeScale)
                self:UpdateUiData()
            end
    )
end
--endregion

--region Ui
function XTaikoMasterControl:TipSongLock(songId)
    XUiManager.TipErrorWithKey("TaikoMasterLock", self:GetSongLockDesc(songId))
end

function XTaikoMasterControl:GetSongLockDesc(songId)
    local timeId = self._Model:GetSongCfgTimeId(songId)
    local endTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local timeTxt = os.date("%Y/%m/%d %H:%M", endTime)
    return timeTxt
end

function XTaikoMasterControl:HandleActivityEnd()
    XLuaUiManager.RunMain()
    XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
end

function XTaikoMasterControl:OpenBattleRoom(stageId)
    if not XTool.IsNumberValid(stageId) then
        return
    end
    XLuaUiManager.Open("UiTaikoMasterBattleRoom", stageId)
end

function XTaikoMasterControl:OpenUiRoleSelect(pos)
    XLuaUiManager.Open("UiTaikoMasterRoleSelect", pos)
end
--endregion

--region Check
function XTaikoMasterControl:CheckIsFullCombo(stageId, combo)
    return self._Model:CheckIsFullCombo(stageId, combo)
end

function XTaikoMasterControl:CheckIsPerfectCombo(stageId, perfect, combo)
    return self._Model:CheckIsPerfectCombo(stageId, perfect, combo)
end
--endregion

--region Music
function XTaikoMasterControl:PlayDefaultBgm()
    self:_PlaySong(self._Model:GetDefaultMusicId())
end

function XTaikoMasterControl:PlaySong(songId)
    local cueId = self._Model:GetSongCfgMusicId(songId)
    self:_PlaySong(cueId)
end

function XTaikoMasterControl:_PlaySong(cueId)
    CS.XAudioManager.PlayMusicWithAnalyzer(cueId)
end
--endregion

--region CacheData
function XTaikoMasterControl:SetSongBrowsed4RedDot(songId)
    self._Model:SetSongBrowsed4RedDot(songId)
end
--endregion

--region UiData
function XTaikoMasterControl:SetJustPassedStageId(stageId)
    self._Model:SetJustPassedStageId(stageId)
end

function XTaikoMasterControl:SetJustEnterStageId(stageId)
    self._Model:SetJustEnterStageId(stageId)
end

function XTaikoMasterControl:GetPanelAssetItemList()
    return {XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.Coin}
end

function XTaikoMasterControl:GetJustPassedStageId()
    return self._Model:GetJustPassedStageId()
end

function XTaikoMasterControl:GetJustEnterSongId()
    return self._Model:GetJustEnterSongId()
end

function XTaikoMasterControl:GetSongIdByStageId(stageId)
    if not self._StageId2SongId then
        self._StageId2SongId = {}
        for _, songId in pairs(self._Model:GetSongList()) do
            local config = self._Model:GetSongCfg(songId)
            self._StageId2SongId[config.EasyStageId] = songId
            self._StageId2SongId[config.HardStageId] = songId
        end
    end
    return self._StageId2SongId[stageId]
end

function XTaikoMasterControl:GetDifficulty(stageId)
    local songId = self:GetSongIdByStageId(stageId)
    local songConfig = self._Model:GetSongCfg(songId)
    if songConfig then
        if songConfig.HardStageId == stageId then
            return XEnumConst.TAIKO_MASTER.DIFFICULTY.HARD
        end
        if songConfig.EasyStageId == stageId then
            return XEnumConst.TAIKO_MASTER.DIFFICULTY.EASY
        end
    end
    return XEnumConst.TAIKO_MASTER.DIFFICULTY.EASY
end

function XTaikoMasterControl:GetDifficultyText(difficulty)
    if difficulty == XEnumConst.TAIKO_MASTER.DIFFICULTY.HARD then
        return XUiHelper.GetText("TaikoMasterDifficulty")
    end
    if difficulty == XEnumConst.TAIKO_MASTER.DIFFICULTY.EASY then
        return XUiHelper.GetText("TaikoMasterEasy")
    end
    return XUiHelper.GetText("TaikoMasterEasy")
end

function XTaikoMasterControl:GetSettingAppearScale()
    return self._Model:GetSettingCfg(XEnumConst.TAIKO_MASTER.SETTING_KEY.APPEAR).Offset
end

function XTaikoMasterControl:GetSettingJudgeScale()
    return self._Model:GetSettingCfg(XEnumConst.TAIKO_MASTER.SETTING_KEY.JUDGE).Offset
end

function XTaikoMasterControl:GetAssessImageByScore(stageId, score)
    local assess = self._Model:GetScoreCfgAssess(stageId, score)
    return self._Model:GetAssessCfgImage(assess)
end

function XTaikoMasterControl:GetStagePositionNum(stageId)
    return self._Model:GetScoreCfgPositionNum(stageId) or XEnumConst.TAIKO_MASTER.STAGE_DEFAULT_ROLE_COUNT
end

---@return XTaikoMasterUiData
function XTaikoMasterControl:GetUiData()
    return self._Model:GetUiData()
end

function XTaikoMasterControl:UpdateUiData()
    self._Model:UpdateUiData()
end

function XTaikoMasterControl:UpdateUiSongUnLockData()
    self._Model:UpdateUiSongUnLockData()
end

function XTaikoMasterControl:UpdateUiTaskData()
    self._Model:UpdateUiTaskData()
end
--endregion

--region Team
---@return number[] robotIdList
function XTaikoMasterControl:GetCharacterIdList()
    return self._Model:GetCharacterList()
end

---@return XTaikoMasterTeam
function XTaikoMasterControl:GetTeam()
    return self._Model:GetTeam()
end

---@return XTaikoMasterTeam
function XTaikoMasterControl:GetIsInTeam(robotId)
    return self._Model:GetTeam():CheckIsInTeam(robotId)
end

function XTaikoMasterControl:SetEntityPos(index, robotId, isWithSave)
    self._Model:GetTeam():SetEntityPos(index, robotId, isWithSave)
end

function XTaikoMasterControl:SetTeamByStage(stageId)
    local positionNum = self:GetStagePositionNum(stageId)
    self._Model:GetTeam():SetTeamByNum(positionNum)
end

function XTaikoMasterControl:SwitchTeamPos(index, targetIndex)
    self._Model:GetTeam():SwitchTeamPos(index, targetIndex)
end
--endregion

return XTaikoMasterControl