---@class XArenaConfigModel : XModel
local XArenaConfigModel = XClass(XModel, "XArenaConfigModel")

local ArenaTableKey = {
    ArenaLevel = {},
    AreaStage = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    ChallengeArea = {
        Identifier = "ChallengeId",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    Mark = {
        Identifier = "MarkId",
    },
    ArenaStage = {
        DirPath = XConfigUtil.DirectoryType.Client,
        CacheType = XConfigUtil.CacheType.Normal,
        Identifier = "StageId",
    },
    ArenaAreaBuffDetails = {
        DirPath = XConfigUtil.DirectoryType.Client,
    },
    ArenaGroupFightEvent = {},
}

function XArenaConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("Fuben/Arena", ArenaTableKey)
end

---@return XTableArenaLevel[]
function XArenaConfigModel:GetArenaLevelConfigs()
    return self._ConfigUtil:GetByTableKey(ArenaTableKey.ArenaLevel) or {}
end

---@return XTableArenaLevel
function XArenaConfigModel:GetArenaLevelConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ArenaTableKey.ArenaLevel, id, false) or {}
end

function XArenaConfigModel:GetArenaLevelNameById(id)
    local config = self:GetArenaLevelConfigById(id)

    return config.Name
end

function XArenaConfigModel:GetArenaLevelIconById(id)
    local config = self:GetArenaLevelConfigById(id)

    return config.Icon
end

function XArenaConfigModel:GetArenaLevelWordIconById(id)
    local config = self:GetArenaLevelConfigById(id)

    return config.WordIcon
end

---@return XTableAreaStage[]
function XArenaConfigModel:GetAreaStageConfigs()
    return self._ConfigUtil:GetByTableKey(ArenaTableKey.AreaStage) or {}
end

---@return XTableAreaStage
function XArenaConfigModel:GetAreaStageConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ArenaTableKey.AreaStage, id, false) or {}
end

function XArenaConfigModel:GetAreaStageNameById(id)
    local config = self:GetAreaStageConfigById(id)

    return config.Name
end

function XArenaConfigModel:GetAreaStageBuffNameById(id)
    local config = self:GetAreaStageConfigById(id)

    return config.BuffName
end

function XArenaConfigModel:GetAreaStageBuffIdById(id)
    local config = self:GetAreaStageConfigById(id)

    return config.BuffId
end

function XArenaConfigModel:GetAreaStageBuffDescById(id)
    local config = self:GetAreaStageConfigById(id)

    return config.BuffDesc
end

function XArenaConfigModel:GetAreaStageStageIdById(id)
    local config = self:GetAreaStageConfigById(id)

    return config.StageId
end

function XArenaConfigModel:GetAreaStageActiveAutoFightStageStrById(id)
    local config = self:GetAreaStageConfigById(id)

    return config.ActiveAutoFightStageStr
end

function XArenaConfigModel:GetAreaStageMarkIdById(id)
    local config = self:GetAreaStageConfigById(id)

    return config.MarkId
end

function XArenaConfigModel:GetAreaStageAutoFightById(id)
    local config = self:GetAreaStageConfigById(id)

    return config.AutoFight
end

function XArenaConfigModel:GetAreaStageDescById(id)
    local config = self:GetAreaStageConfigById(id)

    return config.Desc
end

function XArenaConfigModel:GetAreaStageRegionById(id)
    local config = self:GetAreaStageConfigById(id)

    return config.Region
end

---@return XTableChallengeArea[]
function XArenaConfigModel:GetChallengeAreaConfigs()
    return self._ConfigUtil:GetByTableKey(ArenaTableKey.ChallengeArea) or {}
end

---@return XTableChallengeArea
function XArenaConfigModel:GetChallengeAreaConfigByChallengeId(challengeId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ArenaTableKey.ChallengeArea, challengeId, false) or {}
end

function XArenaConfigModel:GetChallengeAreaNameByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.Name
end

function XArenaConfigModel:GetChallengeAreaArenaLvByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.ArenaLv
end

function XArenaConfigModel:GetChallengeAreaIgnoreByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.Ignore
end

function XArenaConfigModel:GetChallengeAreaMinLvByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.MinLv
end

function XArenaConfigModel:GetChallengeAreaMaxLvByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.MaxLv
end

function XArenaConfigModel:GetChallengeAreaDistributeIdByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.DistributeId
end

function XArenaConfigModel:GetChallengeAreaJoinNumByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.JoinNum
end

function XArenaConfigModel:GetChallengeAreaDanUpRankByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.DanUpRank
end

function XArenaConfigModel:GetChallengeAreaDanKeepRankByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.DanKeepRank
end

function XArenaConfigModel:GetChallengeAreaDanDownRankByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.DanDownRank
end

function XArenaConfigModel:GetChallengeAreaUpRewardIdByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.UpRewardId
end

function XArenaConfigModel:GetChallengeAreaKeepRewardIdByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.KeepRewardId
end

function XArenaConfigModel:GetChallengeAreaDownRewardIdByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.DownRewardId
end

function XArenaConfigModel:GetChallengeAreaDayUnlockNumByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.DayUnlockNum
end

function XArenaConfigModel:GetChallengeAreaWeekEndUnlockNumByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.WeekEndUnlockNum
end

function XArenaConfigModel:GetChallengeAreaAreaIdByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.AreaId
end

function XArenaConfigModel:GetChallengeAreaAreaIdGroupByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.AreaIdGroup
end

function XArenaConfigModel:GetChallengeAreaBaseTeamRankByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.BaseTeamRank
end

function XArenaConfigModel:GetChallengeAreaDifShowRateByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.DifShowRate
end

function XArenaConfigModel:GetChallengeAreaAvgScoreByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.AvgScore
end

function XArenaConfigModel:GetChallengeAreaMinScoreByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.MinScore
end

function XArenaConfigModel:GetChallengeAreaDanUpRankCostContributeScoreByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.DanUpRankCostContributeScore
end

function XArenaConfigModel:GetChallengeAreaContributeScoreByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.ContributeScore
end

function XArenaConfigModel:GetChallengeAreaTaskIdByChallengeId(challengeId)
    local config = self:GetChallengeAreaConfigByChallengeId(challengeId)

    return config.TaskId
end

---@return XTableMark[]
function XArenaConfigModel:GetMarkConfigs()
    return self._ConfigUtil:GetByTableKey(ArenaTableKey.Mark) or {}
end

---@return XTableMark
function XArenaConfigModel:GetMarkConfigByMarkId(markId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ArenaTableKey.Mark, markId, false) or {}
end

function XArenaConfigModel:GetMarkMinPointByMarkId(markId)
    local config = self:GetMarkConfigByMarkId(markId)

    return config.MinPoint
end

function XArenaConfigModel:GetMarkMaxPointByMarkId(markId)
    local config = self:GetMarkConfigByMarkId(markId)

    return config.MaxPoint
end

function XArenaConfigModel:GetMarkEnemyHpPointByMarkId(markId)
    local config = self:GetMarkConfigByMarkId(markId)

    return config.EnemyHpPoint
end

function XArenaConfigModel:GetMarkMaxEnemyHpPointByMarkId(markId)
    local config = self:GetMarkConfigByMarkId(markId)

    return config.MaxEnemyHpPoint
end

function XArenaConfigModel:GetMarkMyHpPointByMarkId(markId)
    local config = self:GetMarkConfigByMarkId(markId)

    return config.MyHpPoint
end

function XArenaConfigModel:GetMarkMaxMyHpPointByMarkId(markId)
    local config = self:GetMarkConfigByMarkId(markId)

    return config.MaxMyHpPoint
end

function XArenaConfigModel:GetMarkTimePointByMarkId(markId)
    local config = self:GetMarkConfigByMarkId(markId)

    return config.TimePoint
end

function XArenaConfigModel:GetMarkMaxTimePointByMarkId(markId)
    local config = self:GetMarkConfigByMarkId(markId)

    return config.MaxTimePoint
end

function XArenaConfigModel:GetMarkNpcGroupPointByMarkId(markId)
    local config = self:GetMarkConfigByMarkId(markId)

    return config.NpcGroupPoint
end

function XArenaConfigModel:GetMarkMaxNpcGroupPointByMarkId(markId)
    local config = self:GetMarkConfigByMarkId(markId)

    return config.MaxNpcGroupPoint
end

---@return XTableArenaStage[]
function XArenaConfigModel:GetArenaStageConfigs()
    return self._ConfigUtil:GetByTableKey(ArenaTableKey.ArenaStage) or {}
end

---@return XTableArenaStage
function XArenaConfigModel:GetArenaStageConfigByStageId(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ArenaTableKey.ArenaStage, stageId, true) or {}
end

function XArenaConfigModel:GetArenaStageDifficuIocnByStageId(stageId)
    local config = self:GetArenaStageConfigByStageId(stageId)

    return config.DifficuIocn
end

function XArenaConfigModel:GetArenaStageNameByStageId(stageId)
    local config = self:GetArenaStageConfigByStageId(stageId)

    return config.Name
end

function XArenaConfigModel:GetArenaStageBgIconSmallByStageId(stageId)
    local config = self:GetArenaStageConfigByStageId(stageId)

    return config.BgIconSmall
end

function XArenaConfigModel:GetArenaStageBgIconBigByStageId(stageId)
    local config = self:GetArenaStageConfigByStageId(stageId)

    return config.BgIconBig
end

function XArenaConfigModel:GetArenaStageMarkIdByStageId(stageId)
    local config = self:GetArenaStageConfigByStageId(stageId)

    return config.MarkId
end

---@return XTableArenaAreaBuffDetails[]
function XArenaConfigModel:GetArenaAreaBuffDetailsConfigs()
    return self._ConfigUtil:GetByTableKey(ArenaTableKey.ArenaAreaBuffDetails) or {}
end

---@return XTableArenaAreaBuffDetails
function XArenaConfigModel:GetArenaAreaBuffDetailsConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ArenaTableKey.ArenaAreaBuffDetails, id, false) or {}
end

function XArenaConfigModel:GetArenaAreaBuffDetailsNameById(id)
    local config = self:GetArenaAreaBuffDetailsConfigById(id)

    return config.Name
end

function XArenaConfigModel:GetArenaAreaBuffDetailsBuffBgById(id)
    local config = self:GetArenaAreaBuffDetailsConfigById(id)

    return config.BuffBg
end

function XArenaConfigModel:GetArenaAreaBuffDetailsDescById(id)
    local config = self:GetArenaAreaBuffDetailsConfigById(id)

    return config.Desc
end

function XArenaConfigModel:GetArenaAreaBuffDetailsIconById(id)
    local config = self:GetArenaAreaBuffDetailsConfigById(id)

    return config.Icon
end

---@return XTableArenaGroupFightEvent[]
function XArenaConfigModel:GetArenaGroupFightEventConfigs()
    return self._ConfigUtil:GetByTableKey(ArenaTableKey.ArenaGroupFightEvent) or {}
end

---@return XTableArenaGroupFightEvent
function XArenaConfigModel:GetArenaGroupFightEventConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ArenaTableKey.ArenaGroupFightEvent, id, false) or {}
end

function XArenaConfigModel:GetArenaGroupFightEventsById(id)
    local config = self:GetArenaGroupFightEventConfigById(id)

    return config.FightEvents
end

return XArenaConfigModel
