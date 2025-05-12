local TableKey = {
    ReformStage = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    ReformChapter = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    ReformMemberSource = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    ReformMemberGroup = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private, TableDefindName = "XTableReformGroup" },
    ReformStageDiff = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private, TableDefindName = "XTableReformStageDifficulty" },
    ReformEnemyGroup = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private, TableDefindName = "XTableReformGroup" },
    ReformEnemySource = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    ReformBuff = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    ReformEnemyTarget = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    ReformAffixSource = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    ReformAffixGroup = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal, TableDefindName = "XTableReformGroup" },
    ReformCfg = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    ReformClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
    ReformEnvGroup = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private, TableDefindName = "XTableReformGroup" },
    ReformEnv = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
    ReformRecommend = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Private, Identifier = "StageId" },
    ReformSubStage = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    ReformUseCharaGroup = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Private },
}

---@class XReformConfigModel : XModel
local XReformConfigModel = XClass(XModel, "XReformConfigModel")

function XReformConfigModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("Fuben/Reform", TableKey)
end

--region Local Function
function XReformConfigModel:GetStageCfgs()
    return self._ConfigUtil:GetByTableKey(TableKey.ReformStage)
end

function XReformConfigModel:GetChapterCfgs()
    return self._ConfigUtil:GetByTableKey(TableKey.ReformChapter)
end

function XReformConfigModel:GetMemberSourceCfgs()
    return self._ConfigUtil:GetByTableKey(TableKey.ReformMemberSource)
end

function XReformConfigModel:GetMemberGroupCfgs()
    return self._ConfigUtil:GetByTableKey(TableKey.ReformMemberGroup)
end

function XReformConfigModel:GetReformClientCfgs()
    return self._ConfigUtil:GetByTableKey(TableKey.ReformClientConfig)
end

---@param id number 关卡ID
---@return XTableReformStage 关卡配置
function XReformConfigModel:GetReformStageTableConfigById(id)
    local config = self:GetStageCfgs()
    id = self:GetRootStageId(id)
    return config[id]
end

---@param id number 章节ID
---@return XTableReformChapter 章节配置
function XReformConfigModel:GetReformChapterTableConfigById(id)
    local config = self:GetChapterCfgs()
    id = self:GetRootStageId(id)
    return config[id]
end

function XReformConfigModel:GetReformMemberSourceConfigById(id)
    local config = self:GetMemberSourceCfgs()
    return config[id]
end

function XReformConfigModel:GetReformMemberGroupConfigById(id)
    local config = self:GetMemberGroupCfgs()
    return config[id]
end

function XReformConfigModel:GetReformClientConfigByKey(key)
    local config = self:GetReformClientCfgs()
    return config[key]
end
--endregion

--region Init
function XReformConfigModel:GetStageConfig()
    return self:GetStageCfgs()
end

function XReformConfigModel:GetChapterConfig()
    return self:GetChapterCfgs()
end

function XReformConfigModel:GetReformMemberGroupConfig()
    return self:GetMemberGroupCfgs()
end

function XReformConfigModel:GetMemberSourceConfig()
    return self:GetMemberSourceCfgs()
end

function XReformConfigModel:GetReformClientConfig()
    return self:GetReformClientCfgs()
end
--endregiond

--region 压力值 <-> Star
function XReformConfigModel:GetStarMax(isHardMode)
    if isHardMode then
        return 2
    end
    return 3
end

function XReformConfigModel:GetStarHardMode()
    return 2
end

function XReformConfigModel:GetStarArray(stageId)
    return self:GetReformStageTableConfigById(stageId).StarNeedScore
end

function XReformConfigModel:GetStarByPressure(pressure, stageId)
    if not stageId then
        XLog.Error("[XReformConfigModel] GetStarByPressure stageId is nil")
        return 0
    end
    local stageArray = self:GetStarArray(stageId)
    for i = #stageArray, 1, -1 do
        if pressure >= stageArray[i] then
            return i
        end
    end
    return 0
end

function XReformConfigModel:GetPressureByStar(star, stageId)
    if not stageId then
        XLog.Error("[XReformConfigModel] GetPressureByStar stageId is nil")
        return 0
    end
    if star == 0 then
        return 0
    end
    local stageArray = self:GetStarArray(stageId)
    return stageArray[star] or 0
end
--endregion

--region ClientTable
function XReformConfigModel:GetDisplayTaskIds()
    local config = self:GetReformClientConfigByKey("TaskRewardDisplay")

    if not config then
        return
    end

    return config.Values
end
--endregion

--region StageTable
function XReformConfigModel:GetStageConfigById(id)
    return self:GetReformStageTableConfigById(id)
end

function XReformConfigModel:GetStageUnlockStageIdById(id)
    local config = self:GetReformStageTableConfigById(id)
    return config.UnlockStageId
end

function XReformConfigModel:GetStageOpenTimeById(id)
    local config = self:GetReformStageTableConfigById(id)
    return config.OpenTimeId
end

function XReformConfigModel:GetStageFullPointById(id)
    local config = self:GetReformStageTableConfigById(id)
    return config.FullPoint
end

function XReformConfigModel:GetStageGoalDescById(id)
    local config = self:GetReformStageTableConfigById(id)
    return config.StageGoalDesc
end

function XReformConfigModel:GetStageGoalDifficultyById(id)
    local config = self:GetReformStageTableConfigById(id)
    return config.Difficulty
end

function XReformConfigModel:GetStageDifficultyId(stageId)
    return self:GetReformStageTableConfigById(stageId).StageDiff[1]
end

function XReformConfigModel:GetStageName(id)
    return self:GetReformStageTableConfigById(id).Name
end

function XReformConfigModel:GetStageRecommendCharacterIds(id)
    return self:GetReformStageTableConfigById(id).RecommendCharacterIds
end

function XReformConfigModel:IsStageValid(id)
    local config = self:GetReformStageTableConfigById(id)
    return config and true or false
end

function XReformConfigModel:GetStageRecommendCharacterGroupIdById(id)
    local config = self:GetReformStageTableConfigById(id)

    return config.RecommendCharacterGroupId
end

function XReformConfigModel:GetStagePressureEasy(id)
    local config = self:GetReformStageTableConfigById(id)
    return config.PressureEasy
end

function XReformConfigModel:GetStagePressureHard(id)
    local config = self:GetReformStageTableConfigById(id)
    return config.PressureHard
end
--endregion

--region ChapterTable
function XReformConfigModel:GetChapterDescById(id)
    local config = self:GetReformChapterTableConfigById(id)

    return config.ChapterDesc
end

function XReformConfigModel:GetChapterOpenTimeById(id)
    local config = self:GetReformChapterTableConfigById(id)
    return config.OpenTime
end

function XReformConfigModel:GetChapterOrderById(id)
    local config = self:GetReformChapterTableConfigById(id)
    return config.Order
end

function XReformConfigModel:GetChapterEventIDById(id)
    local config = self:GetReformChapterTableConfigById(id)

    return config.ChapterEventId
end

function XReformConfigModel:GetChapterEventDescById(id)
    local config = self:GetReformChapterTableConfigById(id)

    return config.ChapterEventDesc
end

function XReformConfigModel:GetChapterStageIdById(id)
    local config = self:GetReformChapterTableConfigById(id)
    return config.ChapterStageId
end

function XReformConfigModel:GetChapterImageById(id)
    local config = self:GetReformChapterTableConfigById(id)
    return config.Img, config.ImgRed
end
--endregion

--region MemberGroupTable
function XReformConfigModel:GetMemberGroupSubIdsById(id)
    local config = self:GetReformMemberGroupConfigById(id)

    return config.SubId
end

function XReformConfigModel:GetMemberGroupRecommendDescById(id)
    local config = self:GetReformMemberGroupConfigById(id)

    return config.Des
end
--endregion

--region MemberSourceTable
function XReformConfigModel:GetMemberSourceRobotIdById(id)
    local config = self:GetReformMemberSourceConfigById(id)

    return config.RobotId
end

function XReformConfigModel:GetMemberSourceStarLevelById(id)
    local config = self:GetReformMemberSourceConfigById(id)

    return config.StarLevel
end

function XReformConfigModel:GetMemberSourceAddScoreById(id)
    local config = self:GetReformMemberSourceConfigById(id)

    return config.AddScore
end

function XReformConfigModel:GetMemebrSourceTargetIdsById(id)
    local config = self:GetReformMemberSourceConfigById(id)

    return config.TargetId
end

function XReformConfigModel:GetMemebrSourceFightEventIdsById(id)
    local config = self:GetReformMemberSourceConfigById(id)

    return config.FightEventId
end
--endregion

--region Stage
function XReformConfigModel:GetConfigMobGroup()
    return self._ConfigUtil:GetByTableKey(TableKey.ReformEnemyGroup)
end

function XReformConfigModel:GetStageDifficulty(difficultyId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ReformStageDiff, difficultyId)
end

function XReformConfigModel:GetStageDifficultyByStage(stageId)
    local difficultyId = self:GetStageDifficultyId(stageId)
    return self:GetStageDifficulty(difficultyId)
end

function XReformConfigModel:GetMobGroup(mobGroupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ReformEnemyGroup, mobGroupId)
end

function XReformConfigModel:GetMobSource(mobSourceId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ReformEnemySource, mobSourceId)
end

---@return XReformMobGroupData[]
function XReformConfigModel:GetStageMobGroup(stageId)
    local result = {}

    -- 第x波怪
    local mobGroupIdArray = self:GetStageDifficultyByStage(stageId).ReformEnemys
    for i = 1, #mobGroupIdArray do
        local mobGroupId = mobGroupIdArray[i]
        local mobGroup = self:GetMobGroup(mobGroupId).SubId

        -- 第x波怪 第x格
        --local mobGroupArray = {}
        --for j = 1, #mobGroup do
        local mobSourceId = mobGroup[1]
        local mobIdArray = self:GetMobSource(mobSourceId).TargetId
        --mobGroupArray[j] = mobIdArray
        --end

        ---@class XReformMobGroupData
        local data = {
            MobArray = mobIdArray,
            MobSourceId = mobGroup,
            MobGroupId = mobGroupId,
            MobAmount = #mobGroup
        }

        result[#result + 1] = data
    end

    -- [第X波][可选mob数组]
    return result
end
--endregion

--region buff
---@type XConfig
function XReformConfigModel:GetConfigBuff()
    return self._ConfigUtil:GetByTableKey(TableKey.ReformBuff)
end

function XReformConfigModel:GetBuff(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ReformBuff, id)
end

function XReformConfigModel:GetBuffName(id)
    return self:GetBuff(id).Name
end

function XReformConfigModel:GetBuffIcon(id)
    return self:GetBuff(id).Icon
end

function XReformConfigModel:GetBuffDesc(id)
    return self:GetBuff(id).Desc
end

function XReformConfigModel:GetBuffPressure(id)
    return self:GetBuff(id).SubScore
end
--endregion

--region mob
function XReformConfigModel:GetMob(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ReformEnemyTarget, id)
end

function XReformConfigModel:GetMobName(id)
    return self:GetMob(id).Name
end

function XReformConfigModel:GetMobPressure(id)
    return self:GetMob(id).AddScore
end

function XReformConfigModel:GetMobIcon(id)
    return self:GetMob(id).HeadIcon
end

function XReformConfigModel:GetMobAffixGroupId(id)
    return self:GetMob(id).AffixGroupId
end

function XReformConfigModel:GetMobAffixMaxCount(id)
    return self:GetMob(id).AffixMaxCount
end

function XReformConfigModel:GetMobLabel(id)
    return self:GetMob(id).Label
end

function XReformConfigModel:GetMobLevel(id)
    return self:GetMob(id).ShowLevel
end

function XReformConfigModel:GetMobNpcId(id)
    return self:GetMob(id).NpcId
end

function XReformConfigModel:GetMobIsHardMode(id)
    local condition = self:GetMob(id).Condition
    return condition and condition > 0
end
--endregion

--region affix 词缀 buff for mob
function XReformConfigModel:GetAffix(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ReformAffixSource, id)
end

function XReformConfigModel:GetAffixName(id)
    return self:GetAffix(id).Name
end

function XReformConfigModel:GetAffixIcon(id)
    return self:GetAffix(id).Icon
end

function XReformConfigModel:GetAffixSimpleDesc(id)
    return self:GetAffix(id).SimpleDes
end

function XReformConfigModel:GetAffixDesc(id)
    return self:GetAffix(id).Des
end

function XReformConfigModel:GetAffixIsHardMode(id)
    local condition = self:GetAffix(id).Condition
    return condition and condition > 0
end

---@param mob XReform2ndMob
---@param affix2Check XReform2ndAffix
function XReformConfigModel:CheckAffixMutex(mob, affix2Check)
    local mutexId2Check = self:GetAffixMutexId(affix2Check:GetId())
    if mutexId2Check == 0 or mutexId2Check == nil then
        return false
    end
    local affixList = mob:GetAffixList()
    for i = 1, #affixList do
        local affix = affixList[i]
        local mutexId = self:GetAffixMutexId(affix:GetId())
        if mutexId2Check == mutexId then
            return true
        end
    end
    return false
end

function XReformConfigModel:IsMutexAffix(id)
    return self:GetAffixMutexId(id) ~= 0
end

function XReformConfigModel:GetAffixMutexId(id)
    return self:GetAffix(id).MutexId
end

function XReformConfigModel:IsAffixValid(id)
    return self:GetAffix(id) and true or false
end

function XReformConfigModel:GetAffixPressure(id)
    return self:GetAffix(id).AddScore
end
--endregion

--region group
function XReformConfigModel:GetAffixGroup(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ReformAffixGroup, id)
end

function XReformConfigModel:GetAffixGroupByGroupId(id)
    return self:GetAffixGroup(id).SubId
end
--endregion

--region activity
function XReformConfigModel:GetActivity(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ReformCfg, id)
end

function XReformConfigModel:GetActivityHelpKey1(id)
    return self:GetActivity(id).HelpName
end

function XReformConfigModel:GetActivityHelpKey2(id)
    return self:GetActivity(id).ScoreHelpName
end

function XReformConfigModel:GetActivityOpenTimeId(id)
    if id == 0 then
        return 0
    end
    return self:GetActivity(id).OpenTimeId
end

function XReformConfigModel:GetActivityName(id)
    return self:GetActivity(id).Name
end

function XReformConfigModel:GetActivityBannerIcon(id)
    return self:GetActivity(id).BannerIcon
end

function XReformConfigModel:IsActivityExist(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ReformAffixGroup, id, true) and true or false
end

function XReformConfigModel:GetActivityDefaultId()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.ReformAffixGroup)
    for i, config in pairs(configs) do
        return config.Id
    end
    return false
end
--endregion

--region Environment
function XReformConfigModel:GetReformEnvGroup(envGroupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ReformEnvGroup, envGroupId).SubId
end

function XReformConfigModel:GetEnvironment(envId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ReformEnv, envId)
end

function XReformConfigModel:GetEnvironmentName(envId)
    return self:GetEnvironment(envId).Name
end

function XReformConfigModel:GetEnvironmentIcon(envId)
    return self:GetEnvironment(envId).Icon
end

function XReformConfigModel:GetEnvironmentAddScore(envId)
    return self:GetEnvironment(envId).AddScore
end

function XReformConfigModel:GetEnvironmentDesc(envId)
    return self:GetEnvironment(envId).Des
end

function XReformConfigModel:GetEnvironmentTextIcon(envId)
    return self:GetEnvironment(envId).TextIcon
end
--endregion

function XReformConfigModel:GetReformRecommend(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ReformRecommend, stageId)
    local result = {
        Affix = {}
    }
    result.Mob = config.Mob
    for i = 1, #config.Affix do
        local t = string.Split(config.Affix[i], "|")
        for j = 1, #t do
            t[j] = tonumber(t[j])
        end
        result.Affix[i] = t
    end
    return result
end

function XReformConfigModel:GetConfigSubStage()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.ReformSubStage)
    return configs
end

function XReformConfigModel:GetRootStageId(stageId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ReformSubStage, stageId, true)
    if config then
        return config.RootStage
    end
    return stageId
end

function XReformConfigModel:GetStagePlayerAmountLimitDefault(stageId)
    local config = self:GetStageConfigById(stageId)
    return config.PlayerAmountLimitDefault
end

function XReformConfigModel:GetStagePlayerAmountLimitAffix(stageId)
    local config = self:GetStageConfigById(stageId)
    return config.PlayerAmountLimitAffix
end

function XReformConfigModel:GetStagePlayerAmountLimit(stageId)
    return self:GetStageConfigById(stageId).PlayerAmountLimit
end

function XReformConfigModel:GetReformUseCharaGroup(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ReformUseCharaGroup, id)
end

return XReformConfigModel
