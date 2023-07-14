---@class XTaikoMasterConfigs
XTaikoMasterConfigs = XTaikoMasterConfigs or {}

XTaikoMasterConfigs.MusicPlayerTextMovePauseInterval = 1
XTaikoMasterConfigs.MusicPlayerTextMoveSpeed = 70

XTaikoMasterConfigs.TeamId = 20
XTaikoMasterConfigs.TeamTypeId = 140
XTaikoMasterConfigs.Difficulty = {
    Easy = 1,
    Hard = 2
}
-- 排行榜默认困难，简单难度不排行
XTaikoMasterConfigs.DefaultRankDifficulty = XTaikoMasterConfigs.Difficulty.Hard
XTaikoMasterConfigs.SettingKey = {
    Appear = 1,
    Judge = 2
}
XTaikoMasterConfigs.Assess = {
    None = "None",
    A = "A",
    S = "S",
    SS = "SS",
    SSS = "SSS"
}

XTaikoMasterConfigs.SongState = {
    Lock = 1,
    JustUnlock = 2, --刚解锁，还未浏览过
    Browsed = 3 --已解锁，且浏览过
}

--region init
local ACTIVITY_TAB = "Share/Fuben/TaikoMaster/TaikoMasterActivity.tab"
local SCORE_TAB = "Share/Fuben/TaikoMaster/TaikoMasterScore.tab"
local SONG_TAB = "Share/Fuben/TaikoMaster/TaikoMasterSong.tab"
local SETTING_TAB = "Share/Fuben/TaikoMaster/TaikoMasterSetting.tab"
local ASSESS_TAB = "Client/Fuben/TaikoMaster/TaikoMasterAssess.tab"
local CHARACTER_TAB = "Share/Fuben/StageCharacterNpcId.tab"
local ActivityTab, ScoreTab, SongTab, SettingTab, AssessTab, CharacterTab
local function GetActivityTab()
    if not ActivityTab then
        ActivityTab = XTableManager.ReadByIntKey(ACTIVITY_TAB, XTable.XTableTaikoMasterActivity, "Id")
    end
    return ActivityTab
end
local function GetScoreTab()
    if not ScoreTab then
        ScoreTab = XTableManager.ReadByIntKey(SCORE_TAB, XTable.XTableTaikoMasterScore, "StageId")
    end
    return ScoreTab
end
local function GetSongTab()
    if not SongTab then
        SongTab = XTableManager.ReadByIntKey(SONG_TAB, XTable.XTableTaikoMasterSong, "SongId")
    end
    return SongTab
end
local function GetSettingTab()
    if not SettingTab then
        SettingTab = XTableManager.ReadByIntKey(SETTING_TAB, XTable.XTableTaikoMasterSetting, "Type")
    end
    return SettingTab
end
local function GetAssessTab()
    if not AssessTab then
        AssessTab = XTableManager.ReadByStringKey(ASSESS_TAB, XTable.XTableTaikoMasterAssess, "Assess")
    end
    return AssessTab
end
local function GetCharacterTab()
    if not CharacterTab then
        CharacterTab = XTableManager.ReadByIntKey(CHARACTER_TAB, XTable.XTableStageCharacterNpcId, "StageType")
    end
    return CharacterTab
end
function XTaikoMasterConfigs.Init()
end
local function GetActivityConfig(activityId)
    local config = GetActivityTab()[activityId]
    if not config then
        XLog.Error(
            "[XTaikoMasterConfigs] GetActivityConfig error:配置不存在，Id:" ..
                (activityId or "nil") .. " ,Path:" .. ACTIVITY_TAB
        )
    end
    return config
end
local function GetSongConfig(songId)
    return GetSongTab()[songId]
end
local function GetScoreConfig(stageId)
    local config = GetScoreTab()[stageId]
    if not config then
        XLog.Error("[XTaikoMasterConfigs] GetScoreConfig error:配置不存在，stageId:" .. stageId)
    end
    return config
end
--endregion

function XTaikoMasterConfigs.GetTimeLimitId(activityId)
    return GetActivityConfig(activityId).TimeId
end

function XTaikoMasterConfigs.GetTaskTimeLimitId(activityId)
    return GetActivityConfig(activityId).TaskTimeLimitId
end

function XTaikoMasterConfigs.GetTrainingStageId(activityId)
    return GetActivityConfig(activityId).TeachStageId
end

function XTaikoMasterConfigs.GetSettingStageId(activityId)
    return GetActivityConfig(activityId).SettingStageId
end

function XTaikoMasterConfigs.GetHelpId(activityId)
    return GetActivityConfig(activityId).HelpId
end

function XTaikoMasterConfigs.GetSongArray(activityId)
    return GetActivityConfig(activityId).SongId
end

function XTaikoMasterConfigs.GetDefaultBgm(activityId)
    return GetActivityConfig(activityId).MusicId
end

function XTaikoMasterConfigs.GetSettingAppearScale()
    return GetSettingTab()[XTaikoMasterConfigs.SettingKey.Appear].Offset
end

function XTaikoMasterConfigs.GetSettingJudgeScale()
    return GetSettingTab()[XTaikoMasterConfigs.SettingKey.Judge].Offset
end

function XTaikoMasterConfigs.GetSongCoverImage(songId)
    return GetSongTab()[songId].CoverImage
end

function XTaikoMasterConfigs.GetSongSettlementImage(songId)
    return GetSongTab()[songId].SettlementImage
end

function XTaikoMasterConfigs.GetSongName(songId)
    return GetSongTab()[songId].Title
end

function XTaikoMasterConfigs.GetSongMusicId(songId)
    return GetSongTab()[songId].MusicId
end

function XTaikoMasterConfigs.GetSongDesc(songId)
    local config = GetSongConfig(songId)
    return config.Description1, config.Description2
end

function XTaikoMasterConfigs.GetActivityTimeId(activityId)
    return GetActivityConfig(activityId).TimeId
end

function XTaikoMasterConfigs.GetStageId(songId, difficulty)
    if difficulty == XTaikoMasterConfigs.Difficulty.Hard then
        return GetSongConfig(songId).HardStageId
    end
    if difficulty == XTaikoMasterConfigs.Difficulty.Easy then
        return GetSongConfig(songId).EasyStageId
    end
    return GetSongConfig(songId).EasyStageId
end

--按时解锁
function XTaikoMasterConfigs.GetSongTimeId(songId)
    return GetSongConfig(songId).TimeId
end

local _StageId2SongId = false
function XTaikoMasterConfigs.GetSongIdByStageId(stageId)
    if not _StageId2SongId then
        _StageId2SongId = {}
        for songId, config in pairs(GetSongTab()) do
            _StageId2SongId[config.EasyStageId] = songId
            _StageId2SongId[config.HardStageId] = songId
        end
    end
    return _StageId2SongId[stageId]
end

function XTaikoMasterConfigs.GetDifficulty(stageId)
    local songId = XTaikoMasterConfigs.GetSongIdByStageId(stageId)
    local songConfig = GetSongConfig(songId)
    if songConfig then
        if songConfig.HardStageId == stageId then
            return XTaikoMasterConfigs.Difficulty.Hard
        end
        if songConfig.EasyStageId == stageId then
            return XTaikoMasterConfigs.Difficulty.Easy
        end
    end
    return XTaikoMasterConfigs.Difficulty.Easy
end

function XTaikoMasterConfigs.GetDifficultyText(difficulty)
    if difficulty == XTaikoMasterConfigs.Difficulty.Hard then
        return XUiHelper.GetText("TaikoMasterDifficulty")
    end
    if difficulty == XTaikoMasterConfigs.Difficulty.Easy then
        return XUiHelper.GetText("TaikoMasterEasy")
    end
    return XUiHelper.GetText("TaikoMasterEasy")
end

function XTaikoMasterConfigs.GetDifficultyTextByStageId(stageId)
    local difficulty = XTaikoMasterConfigs.GetDifficulty(stageId)
    return XTaikoMasterConfigs.GetDifficultyText(difficulty)
end

-- 评价：A,S,SS,SSS...
function XTaikoMasterConfigs.GetAssess(stageId, score)
    local config = GetScoreConfig(stageId)
    if not config then
        return XTaikoMasterConfigs.Assess.None
    end
    local assess = XTaikoMasterConfigs.Assess.None
    for i = 1, #config.JudgeScore do
        local s = config.JudgeScore[i]
        if score >= s then
            assess = config.JudgeName[i]
        else
            break
        end
    end
    return assess
end

function XTaikoMasterConfigs.GetAssessImage(assess)
    local config = GetAssessTab()[assess]
    if not config then
        return false
    end
    return config.Image
end

function XTaikoMasterConfigs.GetAssessImageByScore(stageId, score)
    return XTaikoMasterConfigs.GetAssessImage(XTaikoMasterConfigs.GetAssess(stageId, score))
end

function XTaikoMasterConfigs.GetMaxScore(stageId)
    return GetScoreConfig(stageId).ProgressScore
end

function XTaikoMasterConfigs.GetFullCombo(stageId)
    return GetScoreConfig(stageId).Hit
end

function XTaikoMasterConfigs.GetPerfectCombo(stageId)
    return GetScoreConfig(stageId).Perfect
end

function XTaikoMasterConfigs.GetActivityName(activityId)
    return GetActivityConfig(activityId).Name
end

function XTaikoMasterConfigs.GetActivityBackground(activityId)
    return GetActivityConfig(activityId).BannerBg
end

function XTaikoMasterConfigs.GetDefaultActivityId()
    for i, v in pairs(GetActivityTab()) do
        return i
    end
    return false
end

function XTaikoMasterConfigs.GetSaveKey(songId)
    return "XTaikoMaster" .. XPlayer.Id .. songId
end

function XTaikoMasterConfigs.GetCharacterIdByNpcId(npcId)
    local tab = GetCharacterTab()[XDataCenter.FubenManager.StageType.TaikoMaster]
    if not tab then
        return false
    end
    for i = 1, #tab.NpcId do
        if tab.NpcId[i] == npcId then
            return tab.CharacterId[i]
        end
    end
    return false
end
