---@class XFubenBossSingleConfigModel : XModel
local XFubenBossSingleConfigModel = XClass(XModel, "XFubenBossSingleConfigModel")

local BossSingleTableKey = {
    BossSingleChallengeFeature = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BossSingleChallengeFeatureGroup = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BossSingleChallengeGrade = {
        Identifier = "LevelType",
    },
    BossSingleGrade = {
        Identifier = "LevelType",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BossSingleGroup = {},
    BossSingleRankReward = {},
    BossSingleScoreReward = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BossSingleScoreRule = {},
    BossSingleSection = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BossSingleStage = {
        Identifier = "StageId",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BossSingleTrialGrade = {
        Identifier = "LevelType",
        CacheType = XConfigUtil.CacheType.Normal,
    },
}

function XFubenBossSingleConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("Fuben/BossSingle", BossSingleTableKey)
end

---@return XTableBossSingleChallengeFeature[]
function XFubenBossSingleConfigModel:GetBossSingleChallengeFeatureConfigs()
    return self._ConfigUtil:GetByTableKey(BossSingleTableKey.BossSingleChallengeFeature) or {}
end

---@return XTableBossSingleChallengeFeature
function XFubenBossSingleConfigModel:GetBossSingleChallengeFeatureConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BossSingleTableKey.BossSingleChallengeFeature, id, false) or {}
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeFeatureNameById(id)
    local config = self:GetBossSingleChallengeFeatureConfigById(id)

    return config.Name
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeFeatureDescById(id)
    local config = self:GetBossSingleChallengeFeatureConfigById(id)

    return config.Desc
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeFeatureIconById(id)
    local config = self:GetBossSingleChallengeFeatureConfigById(id)

    return config.Icon
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeFeatureTriangleBgById(id)
    local config = self:GetBossSingleChallengeFeatureConfigById(id)

    return config.TriangleBg
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeFeatureFightEventIdsById(id)
    local config = self:GetBossSingleChallengeFeatureConfigById(id)

    return config.FightEventIds
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeFeatureIsShowRecommendById(id)
    local config = self:GetBossSingleChallengeFeatureConfigById(id)

    return config.IsShowRecommend
end

---@return XTableBossSingleChallengeFeatureGroup[]
function XFubenBossSingleConfigModel:GetBossSingleChallengeFeatureGroupConfigs()
    return self._ConfigUtil:GetByTableKey(BossSingleTableKey.BossSingleChallengeFeatureGroup) or {}
end

---@return XTableBossSingleChallengeFeatureGroup
function XFubenBossSingleConfigModel:GetBossSingleChallengeFeatureGroupConfigById(id)
    return
        self._ConfigUtil:GetCfgByTableKeyAndIdKey(BossSingleTableKey.BossSingleChallengeFeatureGroup, id, false) or {}
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeFeatureGroupFeatureIdsById(id)
    local config = self:GetBossSingleChallengeFeatureGroupConfigById(id)

    return config.FeatureIds
end

---@return XTableBossSingleChallengeGrade[]
function XFubenBossSingleConfigModel:GetBossSingleChallengeGradeConfigs()
    return self._ConfigUtil:GetByTableKey(BossSingleTableKey.BossSingleChallengeGrade) or {}
end

---@return XTableBossSingleChallengeGrade
function XFubenBossSingleConfigModel:GetBossSingleChallengeGradeConfigByLevelType(levelType)
    return
        self._ConfigUtil:GetCfgByTableKeyAndIdKey(BossSingleTableKey.BossSingleChallengeGrade, levelType, false) or {}
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeGradeNeedLevelByLevelType(levelType)
    local config = self:GetBossSingleChallengeGradeConfigByLevelType(levelType)

    return config.NeedLevel
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeGradeNeedScoreByLevelType(levelType)
    local config = self:GetBossSingleChallengeGradeConfigByLevelType(levelType)

    return config.NeedScore
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeGradeLevelNameByLevelType(levelType)
    local config = self:GetBossSingleChallengeGradeConfigByLevelType(levelType)

    return config.LevelName
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeGradeLevelIconByLevelType(levelType)
    local config = self:GetBossSingleChallengeGradeConfigByLevelType(levelType)

    return config.LevelIcon
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeGradeBaseRankNumByLevelType(levelType)
    local config = self:GetBossSingleChallengeGradeConfigByLevelType(levelType)

    return config.BaseRankNum
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeGradeDistributeIdByLevelType(levelType)
    local config = self:GetBossSingleChallengeGradeConfigByLevelType(levelType)

    return config.DistributeId
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeGradeRankTimeIdByLevelType(levelType)
    local config = self:GetBossSingleChallengeGradeConfigByLevelType(levelType)

    return config.RankTimeId
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeGradeBossGroupIdByLevelType(levelType)
    local config = self:GetBossSingleChallengeGradeConfigByLevelType(levelType)

    return config.BossGroupId
end

function XFubenBossSingleConfigModel:GetBossSingleChallengeGradeRewardGroupIdByLevelType(levelType)
    local config = self:GetBossSingleChallengeGradeConfigByLevelType(levelType)

    return config.RewardGroupId
end

---@return XTableBossSingleGrade[]
function XFubenBossSingleConfigModel:GetBossSingleGradeConfigs()
    return self._ConfigUtil:GetByTableKey(BossSingleTableKey.BossSingleGrade) or {}
end

---@return XTableBossSingleGrade
function XFubenBossSingleConfigModel:GetBossSingleGradeConfigByLevelType(levelType)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BossSingleTableKey.BossSingleGrade, levelType, false) or {}
end

function XFubenBossSingleConfigModel:GetBossSingleGradeTypeByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.GradeType
end

function XFubenBossSingleConfigModel:GetBossSingleGradeOfflineByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.Offline
end

function XFubenBossSingleConfigModel:GetBossSingleGradeMinPlayerLevelByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.MinPlayerLevel
end

function XFubenBossSingleConfigModel:GetBossSingleGradeMaxPlayerLevelByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.MaxPlayerLevel
end

function XFubenBossSingleConfigModel:GetBossSingleGradePreLevelByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.PreLevel
end

function XFubenBossSingleConfigModel:GetBossSingleGradeNeedScoreByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.NeedScore
end

function XFubenBossSingleConfigModel:GetBossSingleGradeIconByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.Icon
end

function XFubenBossSingleConfigModel:GetBossSingleGradeLevelNameByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.LevelName
end

function XFubenBossSingleConfigModel:GetBossSingleGradeHideBossOpenByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.HideBossOpen
end

function XFubenBossSingleConfigModel:GetBossSingleGradeChallengeCountByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.ChallengeCount
end

function XFubenBossSingleConfigModel:GetBossSingleGradeWeekChallengeCountByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.WeekChallengeCount
end

function XFubenBossSingleConfigModel:GetBossSingleGradeStaminaCountByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.StaminaCount
end

function XFubenBossSingleConfigModel:GetBossSingleGradeBaseRankNumByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.BaseRankNum
end

function XFubenBossSingleConfigModel:GetBossSingleGradeDistributeIdByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.DistributeId
end

function XFubenBossSingleConfigModel:GetBossSingleGradeGroupIdByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.GroupId
end

function XFubenBossSingleConfigModel:GetBossSingleGradeRankTimeIdByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.RankTimeId
end

function XFubenBossSingleConfigModel:GetBossSingleGradeRewardGroupIdByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.RewardGroupId
end

function XFubenBossSingleConfigModel:GetBossSingleGradeAfreshIdByLevelType(levelType)
    local config = self:GetBossSingleGradeConfigByLevelType(levelType)

    return config.AfreshId
end

---@return XTableBossSingleGroup[]
function XFubenBossSingleConfigModel:GetBossSingleGroupConfigs()
    return self._ConfigUtil:GetByTableKey(BossSingleTableKey.BossSingleGroup) or {}
end

---@return XTableBossSingleGroup
function XFubenBossSingleConfigModel:GetBossSingleGroupConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BossSingleTableKey.BossSingleGroup, id, false) or {}
end

function XFubenBossSingleConfigModel:GetBossSingleGroupGroupIconById(id)
    local config = self:GetBossSingleGroupConfigById(id)

    return config.GroupIcon
end

function XFubenBossSingleConfigModel:GetBossSingleGroupGroupNameById(id)
    local config = self:GetBossSingleGroupConfigById(id)

    return config.GroupName
end

function XFubenBossSingleConfigModel:GetBossSingleGroupSectionIdById(id)
    local config = self:GetBossSingleGroupConfigById(id)

    return config.SectionId
end

---@return XTableBossSingleRankReward[]
function XFubenBossSingleConfigModel:GetBossSingleRankRewardConfigs()
    return self._ConfigUtil:GetByTableKey(BossSingleTableKey.BossSingleRankReward) or {}
end

---@return XTableBossSingleRankReward
function XFubenBossSingleConfigModel:GetBossSingleRankRewardConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BossSingleTableKey.BossSingleRankReward, id, false) or {}
end

function XFubenBossSingleConfigModel:GetBossSingleRankRewardLevelTypeById(id)
    local config = self:GetBossSingleRankRewardConfigById(id)

    return config.LevelType
end

function XFubenBossSingleConfigModel:GetBossSingleRankRewardMinRankById(id)
    local config = self:GetBossSingleRankRewardConfigById(id)

    return config.MinRank
end

function XFubenBossSingleConfigModel:GetBossSingleRankRewardMaxRankById(id)
    local config = self:GetBossSingleRankRewardConfigById(id)

    return config.MaxRank
end

function XFubenBossSingleConfigModel:GetBossSingleRankRewardMailIDById(id)
    local config = self:GetBossSingleRankRewardConfigById(id)

    return config.MailID
end

function XFubenBossSingleConfigModel:GetBossSingleRankRewardRankIconById(id)
    local config = self:GetBossSingleRankRewardConfigById(id)

    return config.RankIcon
end

function XFubenBossSingleConfigModel:GetBossSingleRankRewardRewardGroupIdById(id)
    local config = self:GetBossSingleRankRewardConfigById(id)

    return config.RewardGroupId
end

---@return XTableBossSingleScoreReward[]
function XFubenBossSingleConfigModel:GetBossSingleScoreRewardConfigs()
    return self._ConfigUtil:GetByTableKey(BossSingleTableKey.BossSingleScoreReward) or {}
end

---@return XTableBossSingleScoreReward
function XFubenBossSingleConfigModel:GetBossSingleScoreRewardConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BossSingleTableKey.BossSingleScoreReward, id, false) or {}
end

function XFubenBossSingleConfigModel:GetBossSingleScoreRewardLevelTypeById(id)
    local config = self:GetBossSingleScoreRewardConfigById(id)

    return config.LevelType
end

function XFubenBossSingleConfigModel:GetBossSingleScoreRewardScoreById(id)
    local config = self:GetBossSingleScoreRewardConfigById(id)

    return config.Score
end

function XFubenBossSingleConfigModel:GetBossSingleScoreRewardRewardIdById(id)
    local config = self:GetBossSingleScoreRewardConfigById(id)

    return config.RewardId
end

function XFubenBossSingleConfigModel:GetBossSingleScoreRewardRewardGroupIdById(id)
    local config = self:GetBossSingleScoreRewardConfigById(id)

    return config.RewardGroupId
end

---@return XTableBossSingleScoreRule[]
function XFubenBossSingleConfigModel:GetBossSingleScoreRuleConfigs()
    return self._ConfigUtil:GetByTableKey(BossSingleTableKey.BossSingleScoreRule) or {}
end

---@return XTableBossSingleScoreRule
function XFubenBossSingleConfigModel:GetBossSingleScoreRuleConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BossSingleTableKey.BossSingleScoreRule, id, false) or {}
end

function XFubenBossSingleConfigModel:GetBossSingleScoreRuleBaseScoreById(id)
    local config = self:GetBossSingleScoreRuleConfigById(id)

    return config.BaseScore
end

function XFubenBossSingleConfigModel:GetBossSingleScoreRuleBossLoseHpById(id)
    local config = self:GetBossSingleScoreRuleConfigById(id)

    return config.BossLoseHp
end

function XFubenBossSingleConfigModel:GetBossSingleScoreRuleBossLoseHpScoreById(id)
    local config = self:GetBossSingleScoreRuleConfigById(id)

    return config.BossLoseHpScore
end

function XFubenBossSingleConfigModel:GetBossSingleScoreRuleBossTotalHpById(id)
    local config = self:GetBossSingleScoreRuleConfigById(id)

    return config.BossTotalHp
end

function XFubenBossSingleConfigModel:GetBossSingleScoreRuleLeftTimeById(id)
    local config = self:GetBossSingleScoreRuleConfigById(id)

    return config.LeftTime
end

function XFubenBossSingleConfigModel:GetBossSingleScoreRuleLeftTimeScoreById(id)
    local config = self:GetBossSingleScoreRuleConfigById(id)

    return config.LeftTimeScore
end

function XFubenBossSingleConfigModel:GetBossSingleScoreRuleCharLeftHpById(id)
    local config = self:GetBossSingleScoreRuleConfigById(id)

    return config.CharLeftHp
end

function XFubenBossSingleConfigModel:GetBossSingleScoreRuleCharLeftHpSocreById(id)
    local config = self:GetBossSingleScoreRuleConfigById(id)

    return config.CharLeftHpSocre
end

---@return XTableBossSingleSection[]
function XFubenBossSingleConfigModel:GetBossSingleSectionConfigs()
    return self._ConfigUtil:GetByTableKey(BossSingleTableKey.BossSingleSection) or {}
end

---@return XTableBossSingleSection
function XFubenBossSingleConfigModel:GetBossSingleSectionConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BossSingleTableKey.BossSingleSection, id, false) or {}
end

function XFubenBossSingleConfigModel:GetBossSingleSectionSectionIdById(id)
    local config = self:GetBossSingleSectionConfigById(id)

    return config.SectionId
end

function XFubenBossSingleConfigModel:GetBossSingleSectionDescById(id)
    local config = self:GetBossSingleSectionConfigById(id)

    return config.Desc
end

function XFubenBossSingleConfigModel:GetBossSingleSectionBossHeadIconById(id)
    local config = self:GetBossSingleSectionConfigById(id)

    return config.BossHeadIcon
end

function XFubenBossSingleConfigModel:GetBossSingleSectionPriorityById(id)
    local config = self:GetBossSingleSectionConfigById(id)

    return config.Priority
end

function XFubenBossSingleConfigModel:GetBossSingleSectionAfreshIdById(id)
    local config = self:GetBossSingleSectionConfigById(id)

    return config.AfreshId
end

function XFubenBossSingleConfigModel:GetBossSingleSectionStageIdById(id)
    local config = self:GetBossSingleSectionConfigById(id)

    return config.StageId
end

function XFubenBossSingleConfigModel:GetBossSingleSectionActivityTimeIdById(id)
    local config = self:GetBossSingleSectionConfigById(id)

    return config.ActivityTimeId
end

function XFubenBossSingleConfigModel:GetBossSingleSectionActivityTagById(id)
    local config = self:GetBossSingleSectionConfigById(id)

    return config.ActivityTag
end

function XFubenBossSingleConfigModel:GetBossSingleSectionSwitchTimeIdById(id)
    local config = self:GetBossSingleSectionConfigById(id)

    return config.SwitchTimeId
end

function XFubenBossSingleConfigModel:GetBossSingleSectionTeamBuffIdById(id)
    local config = self:GetBossSingleSectionConfigById(id)

    return config.TeamBuffId
end

---@return XTableBossSingleStage[]
function XFubenBossSingleConfigModel:GetBossSingleStageConfigs()
    return self._ConfigUtil:GetByTableKey(BossSingleTableKey.BossSingleStage) or {}
end

---@return XTableBossSingleStage
function XFubenBossSingleConfigModel:GetBossSingleStageConfigByStageId(stageId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BossSingleTableKey.BossSingleStage, stageId, false) or {}
end

function XFubenBossSingleConfigModel:GetBossSingleStageModelIdByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.ModelId
end

function XFubenBossSingleConfigModel:GetBossSingleStageBossNameByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.BossName
end

function XFubenBossSingleConfigModel:GetBossSingleStageScoreByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.Score
end

function XFubenBossSingleConfigModel:GetBossSingleStagePreFullScoreByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.PreFullScore
end

function XFubenBossSingleConfigModel:GetBossSingleStageBossLoseHpScoreByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.BossLoseHpScore
end

function XFubenBossSingleConfigModel:GetBossSingleStageLeftTimeScoreByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.LeftTimeScore
end

function XFubenBossSingleConfigModel:GetBossSingleStageLeftHpScoreByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.LeftHpScore
end

function XFubenBossSingleConfigModel:GetBossSingleStageDifficultyTypeByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.DifficultyType
end

function XFubenBossSingleConfigModel:GetBossSingleStageDifficultyDescByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.DifficultyDesc
end

function XFubenBossSingleConfigModel:GetBossSingleStageDifficultyDescEnByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.DifficultyDescEn
end

function XFubenBossSingleConfigModel:GetBossSingleStageAutoFightByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.AutoFight
end

function XFubenBossSingleConfigModel:GetBossSingleStageFightCharCountByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.FightCharCount
end

function XFubenBossSingleConfigModel:GetBossSingleStageOpenConditionByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.OpenCondition
end

function XFubenBossSingleConfigModel:GetBossSingleStageBuffDetailsIdByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.BuffDetailsId
end

function XFubenBossSingleConfigModel:GetBossSingleStageFeaturesIdByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.FeaturesId
end

function XFubenBossSingleConfigModel:GetBossSingleStageSkillTitleByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.SkillTitle
end

function XFubenBossSingleConfigModel:GetBossSingleStageSkillDescByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.SkillDesc
end

function XFubenBossSingleConfigModel:GetBossSingleStageAttackNameByStageId(stageId)
    local config = self:GetBossSingleStageConfigByStageId(stageId)

    return config.AttackName
end

---@return XTableBossSingleTrialGrade[]
function XFubenBossSingleConfigModel:GetBossSingleTrialGradeConfigs()
    return self._ConfigUtil:GetByTableKey(BossSingleTableKey.BossSingleTrialGrade) or {}
end

---@return XTableBossSingleTrialGrade
function XFubenBossSingleConfigModel:GetBossSingleTrialGradeConfigByLevelType(levelType)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BossSingleTableKey.BossSingleTrialGrade, levelType, false) or {}
end

function XFubenBossSingleConfigModel:GetBossSingleTrialGradeLevelNameByLevelType(levelType)
    local config = self:GetBossSingleTrialGradeConfigByLevelType(levelType)

    return config.LevelName
end

function XFubenBossSingleConfigModel:GetBossSingleTrialGradeSectionIdByLevelType(levelType)
    local config = self:GetBossSingleTrialGradeConfigByLevelType(levelType)

    return config.SectionId
end

function XFubenBossSingleConfigModel:GetBossSingleTrialGradeOrderByLevelType(levelType)
    local config = self:GetBossSingleTrialGradeConfigByLevelType(levelType)

    return config.Order
end

return XFubenBossSingleConfigModel
