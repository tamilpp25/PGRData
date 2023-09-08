XTransfiniteConfigs = XTransfiniteConfigs or {}
local XTransfiniteConfigs = XTransfiniteConfigs

XTransfiniteConfigs.StageType = {
    Normal = 1, --普通关
    Reward = 2, --奖励关
    Hidden = 3, --隐藏关
}

XTransfiniteConfigs.StageGroupType = {
    Normal = 1,
    Island = 2, --离群点
}

XTransfiniteConfigs.PeriodType = {
    None = 0,
    Activity = 1,
    Fight = 2,
    Result = 3,
}

XTransfiniteConfigs.StageStatus = {
    Lock = 1,
    Unlock = 2,
    Passed = 3,
}

XTransfiniteConfigs.GiftTabIndex = {
    Score = 1,
    Challenge = 2,
}

XTransfiniteConfigs.RewardState = {
    Lock = 1,
    Active = 2,
    Achieved = 3,
    Finish = 4,
}

---@class _RewardType
---@field PointsReward number 积分奖励
---@field AchievementReward number 成就奖励
local _RewardType = enum({
    PointsReward = 1,
    AchievementReward = 2,
})

XTransfiniteConfigs.RewardType = _RewardType

---@class _TaskTypeEnum
---@field Normal number 初级任务
---@field Senior number 高级任务
local _TaskTypeEnum = enum({
    Normal = 1, --初级任务
    Senior = 2, --初级任务
})

XTransfiniteConfigs.TaskTypeEnum = _TaskTypeEnum

---@class RegionType
---@field Normal number 初级组Id
---@field Senior number 高级组Id
local _RegionTypeEnum = enum({
    Normal = 1, --初级组Id
    Senior = 2, --高级组Id
})

---@class IslandSpecialStage
---@field FirstHideExtra number 隐藏特殊目标的关卡索引
---@field SecondHideExtra number 隐藏特殊目标的关卡索引
---@field ShowOtherExtra number 其他特殊目标的关卡索引
local _IslandSpecialStage = enum({
    FirstHideExtra = 11,
    SecondHideExtra = 12,
    ShowOtherExtra = 13,
})

XTransfiniteConfigs.RegionType = _RegionTypeEnum
XTransfiniteConfigs.IslandSpecialStage = _IslandSpecialStage

XTransfiniteConfigs.TeamId = 22
XTransfiniteConfigs.TeamTypeId = 160

---config:Activity,"Share/Fuben/Transfinite/TransfiniteActivity.tab",XTable.XTableTransfiniteActivity
---config:Island,"Share/Fuben/Transfinite/TransfiniteIsland.tab",XTable.XTableTransfiniteIsland
---config:Region,"Share/Fuben/Transfinite/TransfiniteRegion.tab",XTable.XTableTransfiniteRegion
---config:Rotate,"Share/Fuben/Transfinite/TransfiniteRotateGroup.tab",XTable.XTableTransfiniteRotateGroup
---config:Stage,"Share/Fuben/Transfinite/TransfiniteStage.tab",XTable.XTableTransfiniteStage
---config:StageGroup,"Share/Fuben/Transfinite/TransfiniteStageGroup.tab",XTable.XTableTransfiniteStageGroup
---config:Strengthen,"Share/Fuben/Transfinite/TransfiniteStrengthen.tab",XTable.XTableTransfiniteStrengthen
---config:Medal,"Client/Fuben/Transfinite/TransfiniteMedal.tab",XTable.XTableTransfiniteMedal

local Pairs = pairs

--region Activity
local _ConfigActivity
---@return XConfig
local function GetConfigActivity()
    if not _ConfigActivity then
        _ConfigActivity = XConfig.New("Share/Fuben/Transfinite/TransfiniteActivity.tab", XTable.XTableTransfiniteActivity, "Id")
    end
    return _ConfigActivity
end

local function GetActivity(id)
    local config = GetConfigActivity()
    return config:GetConfig(id)
end

function XTransfiniteConfigs.GetActivityTimeId(id)
    return GetActivity(id).TimeId
end

function XTransfiniteConfigs.GetActivityCycleSeconds(id)
    return GetActivity(id).CycleSeconds
end

function XTransfiniteConfigs.IsActivityValid(id)
    local config = GetConfigActivity()
    if config:TryGetConfig(id) then
        return true
    end
    return false
end

--endregion Activity

--region Task
local _ConfigTask
local function GetConfigTask()
    if not _ConfigTask then
        _ConfigTask = XConfig.New("Share/Fuben/Transfinite/TransfiniteTaskGroup.tab", XTable.XTableTransfiniteTaskGroup, "Id")
    end
    return _ConfigTask
end

local function GetTask(id)
    local config = GetConfigTask()
    return config:GetConfig(id)
end

function XTransfiniteConfigs.GetTaskTaskIds(id)
    return GetTask(id).TaskIds
end
--endregion Task

--region Island
local _ConfigIsland
local function GetConfigIsland()
    if not _ConfigIsland then
        _ConfigIsland = XConfig.New("Share/Fuben/Transfinite/TransfiniteIsland.tab", XTable.XTableTransfiniteIsland, "Id")
    end
    return _ConfigIsland
end

local function GetIsland(id)
    local config = GetConfigIsland()
    return config:GetConfig(id)
end

function XTransfiniteConfigs.GetIslandRegionId(id)
    return GetIsland(id).RegionId
end

function XTransfiniteConfigs.GetIslandStageGroupId(id)
    return GetIsland(id).StageGroupId
end

function XTransfiniteConfigs.GetIslandImage(id)
    return GetIsland(id).IslandImage
end

function XTransfiniteConfigs.GetIslandOrder(id)
    return GetIsland(id).Order
end
--endregion Island

--region Region
---@type XConfig
local _ConfigRegion
local function GetConfigRegion()
    if not _ConfigRegion then
        _ConfigRegion = XConfig.New("Share/Fuben/Transfinite/TransfiniteRegion.tab", XTable.XTableTransfiniteRegion, "RegionId")
    end
    return _ConfigRegion
end

local function GetRegion(id)
    local config = GetConfigRegion()
    return config:GetConfig(id)
end

function XTransfiniteConfigs.GetRegionRegionName(id)
    return GetRegion(id).RegionName
end

function XTransfiniteConfigs.GetRegionTimeId(id)
    return GetRegion(id).TimeId
end

function XTransfiniteConfigs.GetRegionMinLv(id)
    return GetRegion(id).MinLv
end

function XTransfiniteConfigs.GetRegionMaxLv(id)
    return GetRegion(id).MaxLv
end

function XTransfiniteConfigs.GetRegionRotateGroupId(id)
    return GetRegion(id).RotateGroupId
end

function XTransfiniteConfigs.GetRegionScoreRewardGroupId(id)
    return GetRegion(id).ScoreRewardGroupId
end

function XTransfiniteConfigs.GetRegionChallengeTaskGroupId(id)
    return GetRegion(id).TaskGroupId[1]
end

--function XTransfiniteConfigs.GetRegionScoreTaskGroupId(id)
--    return GetRegion(id).TaskGroupId[1]
--end

function XTransfiniteConfigs.GetRegionIslandId(id)
    return GetRegion(id).IslandId
end

function XTransfiniteConfigs.GetRegionIconLv(id)
    return GetRegion(id).IconLv
end

function XTransfiniteConfigs.GetRegionDisplayRewardIds(id)
    return GetRegion(id).RewardId
end

function XTransfiniteConfigs.GetAllRegion()
    local configs = GetConfigRegion():GetConfigs()
    local result = {}
    for i = 1, #configs do
        local config = configs[i]
        result[#result + 1] = config.RegionId
    end
    return result
end
--endregion Region

--region Rotate
local _ConfigRotate
local function GetConfigRotate()
    if not _ConfigRotate then
        _ConfigRotate = XConfig.New("Share/Fuben/Transfinite/TransfiniteRotateGroup.tab", XTable.XTableTransfiniteRotateGroup, "RotateGroupId")
    end
    return _ConfigRotate
end

local function GetRotate(id)
    local config = GetConfigRotate()
    return config:GetConfig(id)
end

function XTransfiniteConfigs.GetRotateStageGroupId(id)
    return GetRotate(id).StageGroupId
end
--endregion Rotate

--region Stage
---@type XConfig
local _ConfigStage
local function GetConfigStage()
    if not _ConfigStage then
        _ConfigStage = XConfig.New("Share/Fuben/Transfinite/TransfiniteStage.tab", XTable.XTableTransfiniteStage, "StageId")
    end
    return _ConfigStage
end

local function GetStage(id)
    local config = GetConfigStage()
    return config:GetConfig(id)
end

function XTransfiniteConfigs.IsStageExist(stageId)
    local config = GetConfigStage()
    if config:TryGetConfig(stageId) then
        return true
    end
    return false
end

function XTransfiniteConfigs.GetAllStageConfig()
    return GetConfigStage():GetConfigs()
end

function XTransfiniteConfigs.GetStageStageType(id)
    return GetStage(id).StageType
end

function XTransfiniteConfigs.GetStageStageName(id)
    return GetStage(id).StageName
end

function XTransfiniteConfigs.GetStageConditionId(id)
    return GetStage(id).ConditionId
end

function XTransfiniteConfigs.GetStageStrengthenId(id)
    return GetStage(id).StrengthenId
end

function XTransfiniteConfigs.GetStageImg(id)
    return GetStage(id).Img
end

function XTransfiniteConfigs.GetStageScore(id)
    return GetStage(id).Score
end

function XTransfiniteConfigs.GetStageExtraTimeLimit(id)
    return GetStage(id).ExtraTimeLimit
end

function XTransfiniteConfigs.GetStageExtraScore(id)
    return GetStage(id).ExtraScore
end

function XTransfiniteConfigs.GetStageExtraDec(id)
    return GetStage(id).ExtraDec
end

function XTransfiniteConfigs.GetStageBossModel(id)
    return GetStage(id).Model
end
--endregion Stage

--region StageGroup
local _ConfigStageGroup
local function GetConfigStageGroup()
    if not _ConfigStageGroup then
        _ConfigStageGroup = XConfig.New("Share/Fuben/Transfinite/TransfiniteStageGroup.tab", XTable.XTableTransfiniteStageGroup, "StageGroupId")
    end
    return _ConfigStageGroup
end

local function GetStageGroup(id)
    local config = GetConfigStageGroup()
    return config:GetConfig(id)
end

function XTransfiniteConfigs.GetStageGroupStageId(id)
    return GetStageGroup(id).StageId
end

function XTransfiniteConfigs.GetStageGroupStrengthenId(id)
    return GetStageGroup(id).StrengthenId
end

function XTransfiniteConfigs.GetStageGroupName(id)
    return GetStageGroup(id).Name
end

function XTransfiniteConfigs.GetStageGroupImg(id)
    return GetStageGroup(id).Img
end

function XTransfiniteConfigs.GetStageGroupType(id)
    return GetStageGroup(id).Type
end
--endregion StageGroup

--region Strengthen
local _ConfigStrengthen
local function GetConfigStrengthen()
    if not _ConfigStrengthen then
        _ConfigStrengthen = XConfig.New("Share/Fuben/Transfinite/TransfiniteStrengthen.tab", XTable.XTableTransfiniteStrengthen, "StrengthenId")
    end
    return _ConfigStrengthen
end

local function GetStrengthen(id)
    local config = GetConfigStrengthen()
    return config:GetConfig(id)
end

function XTransfiniteConfigs.GetStrengthenTitle(id)
    return GetStrengthen(id).Title
end

function XTransfiniteConfigs.GetStrengthenDes(id)
    return GetStrengthen(id).Des
end

function XTransfiniteConfigs.GetStrengthenImg(id)
    return GetStrengthen(id).Img
end

function XTransfiniteConfigs.GetStrengthenType(id)
    return GetStrengthen(id).Type
end
--endregion Strengthen

--region Medal
local _ConfigMedal
local function GetConfigMedal()
    if not _ConfigMedal then
        _ConfigMedal = XConfig.New("Client/Fuben/Transfinite/TransfiniteMedal.tab", XTable.XTableTransfiniteMedal, "Id")
    end
    return _ConfigMedal
end

local function GetMedal(id)
    local config = GetConfigMedal()
    return config:GetConfig(id)
end

function XTransfiniteConfigs.GetMedalTime(id)
    return GetMedal(id).Time
end

function XTransfiniteConfigs.GetMedalIcon(id)
    return GetMedal(id).Icon
end

function XTransfiniteConfigs.GetMedalName(id)
    return GetMedal(id).Name
end

function XTransfiniteConfigs.GetMedalDesc(id)
    return GetMedal(id).Desc
end

function XTransfiniteConfigs.GetMedalIdByTime(time)
    local configs = GetConfigMedal():GetConfigs()
    local timeMedal = math.huge
    local medalId
    for id, config in pairs(configs) do
        local timeConfig = config.Time
        if timeConfig == 0 then
            timeConfig = math.huge
        end
        if time < timeConfig and timeConfig < timeMedal then
            timeMedal = timeConfig
            medalId = id
        end
    end
    if medalId then
        return medalId
    end

    -- time = 0，表示超出时间
    for id, config in pairs(configs) do
        if config.Time == 0 then
            return config.Id
        end
    end

    -- 任意取一个配置
    for id, config in pairs(configs) do
        return config.Id
    end
    return 1
end
--endregion Medal

--region Achievement
local _AchievementDic = nil

local function GetAchievementDic()
    if not _AchievementDic then
        local achievementCfgs = XTableManager.ReadByIntKey("Share/Fuben/Transfinite/TransfiniteAchievement.tab", XTable.XTableTransfiniteAchievement, "Id")

        _AchievementDic = {}
        for id, config in Pairs(achievementCfgs) do
            local stageGroupIds = config.StageGroupId

            for i, stageGroupId in Pairs(stageGroupIds) do
                _AchievementDic[stageGroupId] = _AchievementDic[stageGroupId] or {}
                _AchievementDic[stageGroupId][id] = config
            end
        end
    end

    return _AchievementDic
end

---@param id number
---@alias XTransfiniteAchievementConfig { Id:number, Type:number, StageGroupId:number[] }
---@return table<number, XTransfiniteAchievementConfig>
function XTransfiniteConfigs.GetAchievementListByStageGroupId(id)
    local achievementDic = GetAchievementDic()
    return achievementDic[id] or {}
end
--endregion

--region ScoreReward
local _ConfigScoreRewardGroup
local function GetConfigScoreRewardGroup()
    if not _ConfigScoreRewardGroup then
        _ConfigScoreRewardGroup = XConfig.New("Share/Fuben/Transfinite/TransfiniteScoreRewardGroup.tab", XTable.XTableTransfiniteScoreRewardGroup, "Id")
    end
    return _ConfigScoreRewardGroup
end

function XTransfiniteConfigs.GetScoreArray(regionId)
    local rewardGroupId = XTransfiniteConfigs.GetRegionScoreRewardGroupId(regionId)
    local config = GetConfigScoreRewardGroup():GetConfig(rewardGroupId)
    return config.Score, config.RewardId
end

function XTransfiniteConfigs.GetScoreReward(regionId, score)
    local rewardGroupId = XTransfiniteConfigs.GetRegionScoreRewardGroupId(regionId)
    local config = GetConfigScoreRewardGroup():GetConfig(rewardGroupId)
    if not config then
        return 0
    end
    local scoreArray = config.Score
    local index = 1
    for i = 1, #scoreArray do
        if score < scoreArray[i] then
            break
        end
        index = index + 1
    end
    local rewardIdArray = config.RewardId
    return rewardIdArray[index] or 0
end

--endregion