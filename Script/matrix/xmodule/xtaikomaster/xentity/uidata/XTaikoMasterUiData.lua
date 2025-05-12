---@class XTaikoMasterSongUiData
---@field Name string
---@field LyricistDesc string 作词描述
---@field ComposerDesc string 作曲描述
---@field Cover string
---@field CoverBg string 模糊背景
---@field SettlementImage string
---@field EasyStage number
---@field HardStage number

---@class XTaikoMasterSongPlayUiData
---@field MyAssess string
---@field MyScore number
---@field MyAccuracy number
---@field MyAccuracyUnderMaxScore number
---@field MyCombo number
---@field MyComboUnderMaxScore number
---@field AssessImage string
---@field IsPerfectCombo boolean
---@field IsFullCombo boolean

---@class XTaikoMasterRankUiData
---@field MyRank number
---@field TotalCount number
---@field RankPlayerInfoList XTaikoMasterRankPlayerInfo[]

---@class XTaikoMasterRankPlayerInfo
---@field Name string
---@field HeadPortraitId number
---@field HeadFrameId number
---@field Score number
---@field Combo number
---@field Accuracy number

---@class XTaikoMasterUiData
local XTaikoMasterUiData = XClass(nil, "XTaikoMasterUiData")

function XTaikoMasterUiData:Ctor()
    --Activity
    ---@type string
    self.HelpId = false
    self.TimeId = 0
    --Task
    self.TaskList = {}
    self.DailyTaskList = {}
    --Song
    self.SongIdList = {}
    self.SongUnLockDir = {}
    ---@type XTaikoMasterSongUiData[] key = SongId
    self.SongUiDataDir = {}
    ---@type XTaikoMasterSongPlayUiData[] key = SongId
    self.SongEasyPlayDataDir = {}
    ---@type XTaikoMasterSongPlayUiData[] key = SongId
    self.SongHardPlayDataDir = {}
    --Rank
    ---@type XTaikoMasterRankUiData[] key = SongId
    self.RankDataDir = {}
    --Stage
    self.TeachStageId = 0
    self.SettingStageId = 0
    --Setting
    self.SettingAppearScale = 0
    self.SettingJudgeScale = 0
end

function XTaikoMasterUiData:CheckSongUnLock(songId)
    return self.SongUnLockDir[songId]
end

---@param difficulty number XEnumConst.TAIKO_MASTER.DIFFICULTY
function XTaikoMasterUiData:GetSongStageId(songId, difficulty)
    if difficulty == XEnumConst.TAIKO_MASTER.DIFFICULTY.EASY then
        return self.SongUiDataDir[songId].EasyStage
    else
        return self.SongUiDataDir[songId].HardStage
    end
end

return XTaikoMasterUiData