local XFubenBossSingleConfigModel = require("XModule/XFubenBossSingle/XFubenBossSingleConfigModel")
local XBossSingleRankData = require("XModule/XFubenBossSingle/XData/XBossSingleRankData")
local XBossSingle = require("XModule/XFubenBossSingle/XEntity/XBossSingle")
local XBossSingleTrialStageMap = require("XModule/XFubenBossSingle/XData/XBossSingleTrialStageMap")
local XBossSingleChallenge = require("XModule/XFubenBossSingle/XEntity/XBossSingleChallenge")

---@class XFubenBossSingleModel : XFubenBossSingleConfigModel
local XFubenBossSingleModel = XClass(XFubenBossSingleConfigModel, "XFubenBossSingleModel")

function XFubenBossSingleModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self:_InitTableKey()
    self._AutoFightCount = CS.XGame.Config:GetInt("BossSingleAutoFightCount")
    self._AutoFightNewCount = CS.XGame.Config:GetInt("BossSingleAutoFightNewCount")
    self._AutoFightRebate = CS.XGame.Config:GetInt("BossSingleAutoFightRebate")
    self._RelieveFubenBossSingleTeamAstrict = CS.XGame.Config:GetInt("RelieveFubenBossSingleTeamAstrict")
    self._MaxRankCount = CS.XGame.ClientConfig:GetInt("BossSingleMaxRanCount")

    self._ResetCountDownName = "SingleBossReset"
    self._MaxSpecialNumber = 3
    self._MaxTeamCharacterMember = 3
    self._ChallengeRecordCD = 1200

    self._ScoreRewardMap = nil
    self._RankRewardMap = nil
    self._BossSectionInfoMap = nil
    self._BossSectionConfigMap = nil

    self._FightStageType = XEnumConst.BossSingle.StageType.Normal

    ---@type XBossSingle
    self._BossSingle = XBossSingle.New()
    ---@type XBossSingleTrialStageMap
    self._BossSingleTrialStageMap = XBossSingleTrialStageMap.New()
    ---@type XBossSingleChallenge
    self._BossSingleChallenge = XBossSingleChallenge.New()

    ---@type table<number, XBossSingleRankData>
    self._RankDataCache = {}
    ---@type table<number, table<number, XBossSingleRankData>>
    self._BossRankDataCache = {}
    ---@type table<number, XBossSingleRankData>
    self._ChallengeRankDataCache = {}

    self._CurrentSelectIndex = 0
    self._CurrentFeatureId = 0
    self._IsUseSelectIndex = false
end

function XFubenBossSingleModel:ClearPrivate()
    -- 这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XFubenBossSingleModel:ResetAll()
    -- 这里执行重登数据清理
    -- XLog.Error("重登数据清理")
    self._ScoreRewardMap = nil
    self._RankRewardMap = nil
    self._BossSectionInfoMap = nil
    self._BossSectionConfigMap = nil

    self._RankDataCache = {}
    self._BossRankDataCache = {}

    self._CurrentSelectIndex = 0
end

function XFubenBossSingleModel:GetScoreRewardMap()
    if not self._ScoreRewardMap then
        local scoreConfigs = self:GetBossSingleScoreRewardConfigs()

        self._ScoreRewardMap = {}
        for _, config in pairs(scoreConfigs) do
            if self._ScoreRewardMap[config.LevelType] then
                table.insert(self._ScoreRewardMap[config.LevelType], config)
            else
                self._ScoreRewardMap[config.LevelType] = {}
                table.insert(self._ScoreRewardMap[config.LevelType], config)
            end
        end
        for _, scoreList in pairs(self._ScoreRewardMap) do
            table.sort(scoreList, function(first, second)
                if first.Score ~= second.Score then
                    return first.Score < second.Score
                end

                return first.Id < second.Id
            end)
        end
    end

    return self._ScoreRewardMap
end

function XFubenBossSingleModel:GetRankRewardMap()
    if not self._RankRewardMap then
        local rankConfigs = self:GetBossSingleRankRewardConfigs()

        self._RankRewardMap = {}
        for _, config in pairs(rankConfigs) do
            if self._RankRewardMap[config.LevelType] then
                table.insert(self._RankRewardMap[config.LevelType], config)
            else
                self._RankRewardMap[config.LevelType] = {}
                table.insert(self._RankRewardMap[config.LevelType], config)
            end
        end
        for _, rankList in pairs(self._RankRewardMap) do
            table.sort(rankList, function(first, second)
                return first.Id < second.Id
            end)
        end
    end

    return self._RankRewardMap
end

function XFubenBossSingleModel:GetBossSectionInfoMap()
    if not self._BossSectionInfoMap then
        self:__InitBossSection()
    end

    return self._BossSectionInfoMap
end

function XFubenBossSingleModel:GetBossSectionConfigMap()
    if not self._BossSectionConfigMap then
        self:__InitBossSection()
    end

    return self._BossSectionConfigMap
end

function XFubenBossSingleModel:GetBossSectionInfoById(sectionId)
    local afreshId = self:GetBossSingleData():GetBossSingleAfreshId()
    local infoMap = self:GetBossSectionInfoMap()

    return infoMap[afreshId][sectionId]
end

function XFubenBossSingleModel:GetRankRewardConfigByLevelType(levelType)
    local rewardMap = self:GetRankRewardMap()

    return rewardMap[levelType]
end

function XFubenBossSingleModel:GetScoreRewardConfigByLevelType(levelType)
    local scoreMap = self:GetScoreRewardMap()

    return scoreMap[levelType]
end

function XFubenBossSingleModel:GetBossSectionConfigIdBySectionId(sectionId)
    local sectionMap = self:GetBossSectionConfigMap()
    local afreshId = self:GetBossSingleData():GetBossSingleAfreshId()

    return sectionMap[sectionId][afreshId]
end

function XFubenBossSingleModel:GetAutoFightCount()
    return self._AutoFightCount
end

function XFubenBossSingleModel:GetAutoFightNewCount()
    return self._AutoFightNewCount
end

function XFubenBossSingleModel:GetAutoFightRebate()
    return self._AutoFightRebate
end

function XFubenBossSingleModel:GetRelieveTeamAstrict()
    return self._RelieveFubenBossSingleTeamAstrict
end

function XFubenBossSingleModel:GetMaxRankCount()
    return self._MaxRankCount
end

function XFubenBossSingleModel:GetResetCountDownName()
    return self._ResetCountDownName
end

function XFubenBossSingleModel:GetMaxSpecialNumber()
    return self._MaxSpecialNumber
end

function XFubenBossSingleModel:GetMaxTeamCharacterMember()
    return self._MaxTeamCharacterMember
end

function XFubenBossSingleModel:GetChallengeRecordCD()
    return self._ChallengeRecordCD
end

function XFubenBossSingleModel:SetFightStageType(value)
    self._FightStageType = value
end

function XFubenBossSingleModel:GetFightStageType()
    return self._FightStageType
end

function XFubenBossSingleModel:UpdateBossSingleData(data)
    self._BossSingle:SetBossSingleData(data)
end

function XFubenBossSingleModel:UpdateBossSingleSelfRankInfo(data)
    self._BossSingle:SetSelfRankInfo(data)
end

function XFubenBossSingleModel:SetChooseAbleBossListMap(value)
    self._BossSingle:SetChooseAbleBossListMap(value)
end

function XFubenBossSingleModel:SetEnterBossInfo(bossId, bossLevel)
    self._BossSingle:SetEnterBossId(bossId)
    self._BossSingle:SetEnterBossLevel(bossLevel)
end

function XFubenBossSingleModel:SetCurrentFeatureId(value)
    self._CurrentFeatureId = value
end

function XFubenBossSingleModel:GetCurrentFeatureId()
    return self._CurrentFeatureId or 0
end

---@return XBossSingle
function XFubenBossSingleModel:GetBossSingleData()
    return self._BossSingle
end

function XFubenBossSingleModel:UpdateBossSingleChallenge()
    local bossSingle = self:GetBossSingleData()

    if bossSingle:CheckHasChallengeData() then
        self._BossSingleChallenge:SetDataWithBossSingleData(bossSingle)
    end
end

function XFubenBossSingleModel:UpdateChallengeSelfRankInfo(data)
    self._BossSingleChallenge:SetSelfRankInfo(data)
end

---@return XBossSingleChallenge
function XFubenBossSingleModel:GetBossSingleChallengeData()
    return self._BossSingleChallenge
end

function XFubenBossSingleModel:UpdateTrailStageMap()
    self._BossSingleTrialStageMap:ClearAll()

    if not self._BossSingle:IsBossSingleEmpty() then
        local trialGradeConfigs = self:GetBossSingleTrialGradeConfigs()

        for _, value in pairs(trialGradeConfigs) do
            --- 拿到所有体验关boss，遍历体验关boss的stage 叠加分数
            for _, sectionId in pairs(value.SectionId) do
                local bossId = self:GetBossSectionConfigIdBySectionId(sectionId)
                local sectionConfig = self:GetBossSingleSectionConfigById(bossId)
                local totalScore = 0
                local stageIds = sectionConfig.StageId

                for i, stageId in pairs(stageIds) do
                    local info = self._BossSingle:GetBossSingleTrialStageInfoByStageId(stageId)

                    if info then
                        totalScore = totalScore + info:GetScore()
                    end
                    self._BossSingleTrialStageMap:AddPreStageId(stageId, stageIds[i - 1])
                end
                self._BossSingleTrialStageMap:AddTotalScore(sectionId, totalScore)
            end
        end
    end
end

---@return XBossSingleTrialStageMap
function XFubenBossSingleModel:GetBossSingleTrialStageMap()
    return self._BossSingleTrialStageMap
end

function XFubenBossSingleModel:GetTrialPreStageId(stageId)
    local stageMap = self:GetBossSingleTrialStageMap()

    return stageMap:GetPreStageIdByStageId(stageId)
end

function XFubenBossSingleModel:GetTrialTotalScore(sectionId)
    local stageMap = self:GetBossSingleTrialStageMap()

    return stageMap:GetTotalScoreBySectionId(sectionId)
end

function XFubenBossSingleModel:UpdateRankDataCache(levelType, data)
    local cache = self._RankDataCache[levelType]

    if cache then
        cache:SetData(data)
    else
        self._RankDataCache[levelType] = XBossSingleRankData.New(data)
    end
end

---@return XBossSingleRankData
function XFubenBossSingleModel:GetRankDataCacheByLevelType(levelType)
    return self._RankDataCache[levelType]
end

function XFubenBossSingleModel:UpdateBossRankDataCache(levelType, bossId, data)
    local cache = nil

    if self._BossRankDataCache[levelType] then
        cache = self._BossRankDataCache[levelType][bossId]
    end

    if cache then
        cache:SetData(data)
    else
        self._BossRankDataCache[levelType] = self._BossRankDataCache[levelType] or {}
        self._BossRankDataCache[levelType][bossId] = XBossSingleRankData.New(data)
    end
end

---@return XBossSingleRankData
function XFubenBossSingleModel:GetBossRankDataCacheByTypeAndBossId(levelType, bossId)
    if self._BossRankDataCache[levelType] then
        return self._BossRankDataCache[levelType][bossId]
    end

    return nil
end

function XFubenBossSingleModel:UpdateChallengeRankDataCache(stageId, data)
    local cache = self._ChallengeRankDataCache[stageId]

    if cache then
        cache:SetData(data)
    else
        self._ChallengeRankDataCache[stageId] = XBossSingleRankData.New(data)
    end
end

function XFubenBossSingleModel:GetChallengeRankDataCacheByStageId(stageId)
    return self._ChallengeRankDataCache[stageId]
end

function XFubenBossSingleModel:__InitBossSection()
    local sectionConfigs = self:GetBossSingleSectionConfigs()

    self._BossSectionInfoMap = {}
    self._BossSectionConfigMap = {}
    for id, sectionConfig in pairs(sectionConfigs) do
        local sectionId = sectionConfig.SectionId
        local afreshId = sectionConfig.AfreshId

        self._BossSectionConfigMap[sectionConfig.SectionId] = self._BossSectionConfigMap[sectionConfig.SectionId] or {}
        self._BossSectionConfigMap[sectionConfig.SectionId][sectionConfig.AfreshId] = id
        
        self._BossSectionInfoMap[afreshId] = self._BossSectionInfoMap[afreshId] or {}
        self._BossSectionInfoMap[afreshId][sectionId] = {}
        for _, stageId in pairs(sectionConfig.StageId) do
            table.insert(self._BossSectionInfoMap[afreshId][sectionId], self:GetBossSingleStageConfigByStageId(stageId))
        end
    end
    for _, info in pairs(self._BossSectionInfoMap) do
        for _, stageConfigs in pairs(info) do
            table.sort(stageConfigs, function(first, second)
                if first.DifficultyType ~= second.DifficultyType then
                    return first.DifficultyType < second.DifficultyType
                end
                
                return first.StageId < second.StageId
            end)
        end
    end
end

function XFubenBossSingleModel:GetCurrentSelectIndex()
    return self._CurrentSelectIndex
end

function XFubenBossSingleModel:SetCurrentSelectIndex(value)
    self._CurrentSelectIndex = value
end

function XFubenBossSingleModel:GetIsUseSelectIndex()
    return self._IsUseSelectIndex
end

function XFubenBossSingleModel:SetIsUseSelectIndex(value)
    self._IsUseSelectIndex = value
end

return XFubenBossSingleModel
