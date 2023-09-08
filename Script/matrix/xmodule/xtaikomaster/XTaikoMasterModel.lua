local XTaikoMasterUiData = require("XModule/XTaikoMaster/XEntity/UiData/XTaikoMasterUiData")
local XTaikoMasterTeam = require("XModule/XTaikoMaster/XEntity/XTaikoMasterTeam")
local XTaikoMasterInfo = require("XModule/XTaikoMaster/XEntity/XTaikoMasterInfo")
local TableKey = {
    TaikoMasterActivity = { Identifier = "Id", CacheType = XConfigUtil.CacheType.Normal },
    TaikoMasterScore = {Identifier = "StageId"},
    TaikoMasterSetting = {Identifier = "Type"},
    TaikoMasterSong = {Identifier = "SongId", CacheType = XConfigUtil.CacheType.Normal },
    TaikoMasterAssess = {DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Assess", ReadFunc = XConfigUtil.ReadType.String},
}

---@class XTaikoMasterModel : XModel
local XTaikoMasterModel = XClass(XModel, "XTaikoMasterModel")
function XTaikoMasterModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Fuben/TaikoMaster", TableKey)
    ---@type XTaikoMasterInfo
    self._ActivityData = XTaikoMasterInfo.New()
    ---@type XTaikoMasterUiData
    self._UiData = XTaikoMasterUiData.New()
    self._JustPassedStageId = 0
    self._JustEnterStageId = 0
end

function XTaikoMasterModel:ResetAll()
    if self._ActivityData then
        self._ActivityData:Reset()
    end
    self._ActivityData = nil
    self._JustPassedStageId = 0
    ---@type XTaikoMasterTeam
    self._Team = nil
    self._UiData = nil
end

function XTaikoMasterModel:ClearPrivate()
    self._UiData = nil
end

--region Rpc
function XTaikoMasterModel:NotifyTaikoMasterData(data)
    if not self._ActivityData then
        self._ActivityData = XTaikoMasterInfo.New()
    end
    self._ActivityData:SetData(data)
    if self:_CheckIsNotActivity() then
        self._ActivityData:SetActivityId(self:GetDefaultActivityId())
    end
end
--endregion

----------public start----------
--region Checker
function XTaikoMasterModel:CheckIsFunctionOpen(isTip)
    if isTip then
        XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.TaikoMaster)
    end
    return XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.TaikoMaster)
end

function XTaikoMasterModel:CheckIsActivityOpen()
    if self:_CheckIsNotActivity() then
        return false
    end
    return XFunctionManager.CheckInTimeByTimeId(self:GetActivityCfgTimeId(self._ActivityData:GetActivityId()), false)
end

function XTaikoMasterModel:CheckCdUnlockRedPoint(songId)
    if songId then
        return self:GetSongState4RedDot(songId) == XEnumConst.TAIKO_MASTER.SONG_STATE.JUST_UNLOCK
    end
    local songArray = self:GetSongList()
    for i = 1, #songArray do
        if self:GetSongState4RedDot(songArray[i]) == XEnumConst.TAIKO_MASTER.SONG_STATE.JUST_UNLOCK then
            return true
        end
    end
    return false
end

function XTaikoMasterModel:CheckIsFullCombo(stageId, combo)
    if self:_CheckIsNotActivity() then
        return false
    end
    if not XTool.IsNumberValid(stageId) then
        return false
    end
    return combo >= self:GetScoreCfgFullCombo(stageId)
end

function XTaikoMasterModel:CheckIsPerfectCombo(stageId, perfect, combo)
    if self:_CheckIsNotActivity() then
        return false
    end
    if not XTool.IsNumberValid(stageId) then
        return false
    end
    return perfect >= self:GetScoreCfgPerfectCombo(stageId) and self:CheckIsFullCombo(stageId, combo)
end
--endregion

--region ActivityData
function XTaikoMasterModel:HandleWinData(stageId, data)
    if self:_CheckIsNotActivity() then
        return
    end
    self._ActivityData:HandleWinData(stageId, data)
end

function XTaikoMasterModel:SetSetting(appearScale, judgeScale)
    if self:_CheckIsNotActivity() then
        return
    end
    return self._ActivityData:SetSetting(appearScale, judgeScale)
end

function XTaikoMasterModel:SetRankData(songId, rankData)
    if self:_CheckIsNotActivity() then
        return
    end
    return self._ActivityData:SetRankData(songId, rankData)
end

function XTaikoMasterModel:GetActivityTimeId()
    if self:_CheckIsNotActivity() then
        return 0
    end
    return self:GetActivityCfgTimeId(self._ActivityData:GetActivityId())
end

function XTaikoMasterModel:GetMyScore(stageId)
    if self:_CheckIsNotActivity() then
        return 0, false
    end
    return self._ActivityData:GetMyScore(stageId)
end
--endregion

--region UiData
function XTaikoMasterModel:GetTaskUiData()
    if self:_CheckIsNotActivity() then
        return {}
    end
    local taskTimeLimitId = self:GetActivityCfgTaskTimeLimitId(self._ActivityData:GetActivityId())
    local taskGroupCfg = taskTimeLimitId ~= 0 and XTaskConfig.GetTimeLimitTaskCfg(taskTimeLimitId)
    local taskIdList = taskGroupCfg and taskGroupCfg.TaskId or {}
    local taskList = XDataCenter.TaskManager.GetTaskIdListData(taskIdList, true)
    return taskList
end

function XTaikoMasterModel:GetDailyTaskUiData()
    if self:_CheckIsNotActivity() then
        return {}
    end
    local taskTimeLimitId = self:GetActivityCfgTaskTimeLimitId(self._ActivityData:GetActivityId())
    local taskGroupCfg = taskTimeLimitId ~= 0 and XTaskConfig.GetTimeLimitTaskCfg(taskTimeLimitId)
    local taskIdList = taskGroupCfg and taskGroupCfg.DayTaskId or {}
    local taskList = XDataCenter.TaskManager.GetTaskIdListData(taskIdList, true)
    return taskList
end

function XTaikoMasterModel:GetDefaultMusicId()
    local musicId = 0
    if self:_CheckIsNotActivity() then
        return musicId
    end
    musicId = self:GetActivityCfgMusicId(self._ActivityData:GetActivityId())
    return musicId
end

function XTaikoMasterModel:GetFinishSongCount()
    local result = 0
    local easyStageId, hardStageId
    if self:_CheckIsNotActivity() then
        return result
    end
    for _, songId in pairs(self:GetSongList()) do
        easyStageId = self:GetSongCfgEasyStageId(songId)
        hardStageId = self:GetSongCfgHardStageId(songId)
        if self._ActivityData:GetStageData(easyStageId) or self._ActivityData:GetStageData(hardStageId) then
            result = result + 1
        end
    end
    return result
end

function XTaikoMasterModel:GetSongList()
    local result = {}
    if self:_CheckIsNotActivity() then
        return result
    end
    return self:GetActivityCfgSongList(self._ActivityData:GetActivityId())
end

---@return XTaikoMasterUiData
function XTaikoMasterModel:GetUiData()
    if not self._UiData then
        self:UpdateUiData()
    end
    return self._UiData
end

function XTaikoMasterModel:UpdateUiData()
    if not self._UiData then
        self._UiData = XTaikoMasterUiData.New()
    end
    if self._ActivityData then
        self._UiData.HelpId = self:GetActivityCfgHelpKey(self._ActivityData:GetActivityId())
        self._UiData.TimeId = self:GetActivityTimeId()
        self._UiData.TaskList = self:GetTaskUiData()
        self._UiData.DailyTaskList = self:GetDailyTaskUiData()
        self._UiData.SongIdList = self:GetSongList()
        self._UiData.SongUnLockDir = self:_GetSongUnlockDir()
        self._UiData.SongUiDataDir = self:_GetSongUiData()
        self._UiData.SongEasyPlayDataDir = self:_GetSongPlayData(XEnumConst.TAIKO_MASTER.DIFFICULTY.EASY)
        self._UiData.SongHardPlayDataDir = self:_GetSongPlayData(XEnumConst.TAIKO_MASTER.DIFFICULTY.HARD)
        self._UiData.RankDataDir = self:_GetRankData()
        self._UiData.TeachStageId = self:GetActivityCfgTeachStageId(self._ActivityData:GetActivityId())
        self._UiData.SettingStageId = self:GetActivityCfgSettingStageId(self._ActivityData:GetActivityId())
        self._UiData.SettingAppearScale = self._ActivityData:GetSettingAppearScale()
        self._UiData.SettingJudgeScale = self._ActivityData:GetSettingJudgeScale()
    end
end

function XTaikoMasterModel:UpdateUiSongUnLockData()
    if not self._UiData then
        self._UiData = XTaikoMasterUiData.New()
    end
    if self._ActivityData then
        self._UiData.SongUnLockDir = self:_GetSongUnlockDir()
    end
end

function XTaikoMasterModel:UpdateUiTaskData()
    if not self._UiData then
        self._UiData = XTaikoMasterUiData.New()
    end
    if self._ActivityData then
        self._UiData.TaskList = self:GetTaskUiData()
        self._UiData.DailyTaskList = self:GetDailyTaskUiData()
    end
end
--endregion

--region CacheData
function XTaikoMasterModel:GetSongState4RedDot(songId)
    local key = self:_GetSaveKey(songId)
    local data = XSaveTool.GetData(key)
    if data then
        return data
    end
    if self:_CheckSongIsUnLock(songId) then
        return XEnumConst.TAIKO_MASTER.SONG_STATE.JUST_UNLOCK
    else
        return XEnumConst.TAIKO_MASTER.SONG_STATE.LOCK
    end
end

function XTaikoMasterModel:SetSongBrowsed4RedDot(songId)
    local key = self:_GetSaveKey(songId)
    local data = XSaveTool.GetData(key)
    if not data then
        XSaveTool.SaveData(key, XEnumConst.TAIKO_MASTER.SONG_STATE.BROWSED)
        XEventManager.DispatchEvent(XEventId.EVENT_TAIKO_MASTER_SONG_BROWSED_UPDATE, songId)
    end
end

function XTaikoMasterModel:SetJustPassedStageId(stageId)
    self._JustPassedStageId = stageId
end

function XTaikoMasterModel:GetJustPassedStageId()
    local stageId = self._JustPassedStageId
    self._JustPassedStageId = false
    return stageId
end

function XTaikoMasterModel:SetJustEnterStageId(stageId)
    self._JustEnterStageId = stageId
end

function XTaikoMasterModel:GetJustEnterStageId()
    return self._JustEnterStageId
end

function XTaikoMasterModel:GetJustEnterSongId()
    if not XTool.IsNumberValid(self._JustEnterStageId) then
        return 0
    end
    for _, songId in ipairs(self:GetSongList()) do
        if self:GetSongCfgEasyStageId(songId) == self._JustEnterStageId 
                or self:GetSongCfgHardStageId(songId) == self._JustEnterStageId then
            return songId
        end
    end
    return 0
end
--endregion

--region Team
function XTaikoMasterModel:GetCharacterList()
    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    return fubenAgency:GetStageTypeRobot(XEnumConst.FuBen.StageType.TaikoMaster)
end

---@return XTaikoMasterTeam
function XTaikoMasterModel:GetTeam()
    if not self._Team then
        self._Team = XTaikoMasterTeam.New(self._ActivityData:GetActivityId())
        self._Team:Copy(self._Team:GetCacheTeam())
    end
    return self._Team
end
--endregion
----------public end----------

----------private start----------
--region Checker
function XTaikoMasterModel:_CheckIsNotActivity()
    if not self._ActivityData then
        return true
    end
    if not XTool.IsNumberValid(self._ActivityData:GetActivityId()) then
        return true
    end
    return false
end

function XTaikoMasterModel:_CheckSongIsUnLock(songId)
    return XFunctionManager.CheckInTimeByTimeId(self:GetSongCfgTimeId(songId), true)
end
--endregion

--region UiData
function XTaikoMasterModel:_GetSongUnlockDir()
    local result = {}
    if self:_CheckIsNotActivity() then
        return result
    end
    for _, songId in ipairs(self:GetSongList()) do
        result[songId] = self:_CheckSongIsUnLock(songId)
    end
    return result
end

---@return XTaikoMasterSongUiData[]
function XTaikoMasterModel:_GetSongUiData()
    ---@type XTaikoMasterSongUiData[]
    local result = {}
    if self:_CheckIsNotActivity() then
        return result
    end
    for _, songId in ipairs(self:GetSongList()) do
        if not result[songId] then
            result[songId] = {}
        end
        result[songId].Name = self:GetSongCfgName(songId)
        result[songId].Cover = self:GetSongCfgCover(songId)
        result[songId].CoverBg = self:GetSongCfgCoverBg(songId)
        result[songId].LyricistDesc = self:GetSongCfgLyricistDesc(songId)
        result[songId].ComposerDesc = self:GetSongCfgComposerDesc(songId)
        result[songId].SettlementImage = self:GetSongCfgSettlementImage(songId)
        result[songId].EasyStage = self:GetSongCfgEasyStageId(songId)
        result[songId].HardStage = self:GetSongCfgHardStageId(songId)
    end
    return result
end

---@return XTaikoMasterSongPlayUiData[]
---@param difficulty number XEnumConst.TAIKO_MASTER.DIFFICULTY
function XTaikoMasterModel:_GetSongPlayData(difficulty)
    ---@type XTaikoMasterSongPlayUiData[]
    local result = {}
    if self:_CheckIsNotActivity() then
        return result
    end
    for _, songId in ipairs(self:GetSongList()) do
        if not result[songId] then result[songId] = {} end
        local stageId = self:GetSongCfgStageId(songId, difficulty)
        local score, isPassed = self._ActivityData:GetMyScore(stageId)

        result[songId].MyScore = score
        result[songId].MyCombo = self._ActivityData:GetMyCombo(stageId)
        result[songId].MyAccuracy = self._ActivityData:GetMyAccuracy(stageId)
        result[songId].MyPerfect = self._ActivityData:GetMyPerfect(stageId)
        result[songId].MyAssess = isPassed and self:GetScoreCfgAssess(stageId, score) or XEnumConst.TAIKO_MASTER.ASSESS.NONE
        result[songId].MyComboUnderMaxScore = self._ActivityData:GetMyComboUnderMaxScore()
        result[songId].MyAccuracyUnderMaxScore = self._ActivityData:GetMyAccuracyUnderMaxScore()
        result[songId].AssessImage = result[songId].MyAssess ~= XEnumConst.TAIKO_MASTER.ASSESS.NONE and self:GetAssessCfgImage(result[songId].MyAssess)
        result[songId].IsFullCombo = self:CheckIsFullCombo(stageId, result[songId].MyCombo)
        result[songId].IsPerfectCombo = self:CheckIsPerfectCombo(stageId, result[songId].MyPerfect, result[songId].MyCombo)
    end
    return result
end

---@return XTaikoMasterRankUiData[]
function XTaikoMasterModel:_GetRankData()
    ---@type XTaikoMasterRankUiData[]
    local result = {}
    if self:_CheckIsNotActivity() then
        return result
    end
    for songId, rankData in ipairs(self._ActivityData:GetRankData()) do
        if not result[songId] then result[songId] = {} end
        result[songId].MyRank = rankData.Ranking
        result[songId].TotalCount = rankData.TotalCount
        result[songId].RankPlayerInfoList = rankData.RankPlayerInfoList
    end
    return result
end
--endregion

--region CacheData
function XTaikoMasterModel:_GetSaveKey(key)
    return "XTaikoMaster" .. XPlayer.Id .. key
end
--endregion
----------private end----------


----------config start----------
--region Activity
function XTaikoMasterModel:GetDefaultActivityId()
    local result = 0
    local path = self._ConfigUtil:GetPathByTableKey(TableKey.TaikoMasterActivity)
    ---@type XTableTaikoMasterActivity[]
    local cfgList = self._ConfigUtil:Get(path)
    if XTool.IsTableEmpty(cfgList) then
        return result
    end
    for _, cfg in ipairs(cfgList) do
        if XTool.IsNumberValid(cfg.TimeId) and XFunctionManager.CheckInTimeByTimeId(cfg.TimeId, false) then
            result = cfg.Id
        end
    end
    return result
end

---@return XTableTaikoMasterActivity
function XTaikoMasterModel:GetActivityCfg(activityId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TaikoMasterActivity, activityId)
end

function XTaikoMasterModel:GetActivityCfgTeachStageId(activityId)
    local cfg = self:GetActivityCfg(activityId)
    return cfg and cfg.TeachStageId
end

function XTaikoMasterModel:GetActivityCfgSettingStageId(activityId)
    local cfg = self:GetActivityCfg(activityId)
    return cfg and cfg.SettingStageId
end

function XTaikoMasterModel:GetActivityCfgTimeId(activityId)
    local cfg = self:GetActivityCfg(activityId)
    return cfg and cfg.TimeId
end

function XTaikoMasterModel:GetActivityCfgHelpKey(activityId)
    local cfg = self:GetActivityCfg(activityId)
    return cfg and cfg.HelpId
end

function XTaikoMasterModel:GetActivityCfgMusicId(activityId)
    local cfg = self:GetActivityCfg(activityId)
    return cfg and cfg.MusicId
end

function XTaikoMasterModel:GetActivityCfgSongList(activityId)
    local cfg = self:GetActivityCfg(activityId)
    return cfg and cfg.SongId
end

function XTaikoMasterModel:GetActivityCfgTaskTimeLimitId(activityId)
    local cfg = self:GetActivityCfg(activityId)
    return cfg and cfg.TaskTimeLimitId
end
--endregion

--region Score
---@return XTableTaikoMasterScore
function XTaikoMasterModel:GetScoreCfg(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TaikoMasterScore, stageId)
end

function XTaikoMasterModel:GetScoreCfgMaxScore(stageId)
    local cfg = self:GetScoreCfg(stageId)
    return cfg and cfg.ProgressScore
end

function XTaikoMasterModel:GetScoreCfgFullCombo(stageId)
    local cfg = self:GetScoreCfg(stageId)
    return cfg and cfg.Hit
end

function XTaikoMasterModel:GetScoreCfgPerfectCombo(stageId)
    local cfg = self:GetScoreCfg(stageId)
    return cfg and cfg.Perfect
end

function XTaikoMasterModel:GetScoreCfgAssess(stageId, score)
    local cfg = self:GetScoreCfg(stageId)
    if not cfg then
        return XEnumConst.TAIKO_MASTER.ASSESS.NONE
    end
    local assess = XEnumConst.TAIKO_MASTER.ASSESS.NONE
    for i = 1, #cfg.JudgeScore do
        local s = cfg.JudgeScore[i]
        if score >= s then
            assess = cfg.JudgeName[i]
        else
            break
        end
    end
    return assess
end

function XTaikoMasterModel:GetScoreCfgPositionNum(stageId)
    local cfg = self:GetScoreCfg(stageId)
    return cfg and cfg.PositionNum
end
--endregion

--region Setting
---@return XTableTaikoMasterSetting
function XTaikoMasterModel:GetSettingCfg(type)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TaikoMasterSetting, type)
end
--endregion

--region Song
---@return XTableTaikoMasterSong
function XTaikoMasterModel:GetSongCfg(songId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TaikoMasterSong, songId)
end

function XTaikoMasterModel:GetSongCfgTimeId(songId)
    local cfg = self:GetSongCfg(songId)
    return cfg and cfg.TimeId
end

function XTaikoMasterModel:GetSongCfgName(songId)
    local cfg = self:GetSongCfg(songId)
    return cfg and cfg.Title
end

function XTaikoMasterModel:GetSongCfgLyricistDesc(songId)
    local cfg = self:GetSongCfg(songId)
    return cfg and cfg.Description1
end

function XTaikoMasterModel:GetSongCfgComposerDesc(songId)
    local cfg = self:GetSongCfg(songId)
    return cfg and cfg.Description2
end

function XTaikoMasterModel:GetSongCfgSettlementImage(songId)
    local cfg = self:GetSongCfg(songId)
    return cfg and cfg.SettlementImage
end

function XTaikoMasterModel:GetSongCfgCover(songId)
    local cfg = self:GetSongCfg(songId)
    return cfg and cfg.CoverImage
end

function XTaikoMasterModel:GetSongCfgCoverBg(songId)
    local cfg = self:GetSongCfg(songId)
    return cfg and cfg.CoverBgImage
end

function XTaikoMasterModel:GetSongCfgMusicId(songId)
    local cfg = self:GetSongCfg(songId)
    return cfg and cfg.MusicId
end

function XTaikoMasterModel:GetSongCfgEasyStageId(songId)
    local cfg = self:GetSongCfg(songId)
    return cfg and cfg.EasyStageId
end

function XTaikoMasterModel:GetSongCfgHardStageId(songId)
    local cfg = self:GetSongCfg(songId)
    return cfg and cfg.HardStageId
end

function XTaikoMasterModel:GetSongCfgStageId(songId, difficulty)
    if difficulty == XEnumConst.TAIKO_MASTER.DIFFICULTY.EASY then
        return self:GetSongCfgEasyStageId(songId)
    else
        return self:GetSongCfgHardStageId(songId)
    end
end
--endregion

--region Assess
---@return XTableTaikoMasterAssess
function XTaikoMasterModel:GetAssessCfg(assess)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.TaikoMasterAssess, assess)
end

function XTaikoMasterModel:GetAssessCfgImage(assess)
    local cfg = self:GetAssessCfg(assess)
    return cfg and cfg.Image
end
--endregion
----------config end----------


return XTaikoMasterModel