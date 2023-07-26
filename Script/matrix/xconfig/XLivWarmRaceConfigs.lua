local tableInsert = table.insert
local tableSort = table.sort

local TABLE_ACTIVITY_PATH = "Share/Fuben/RunGame/RunGameActivity.tab"
local TABLE_GROUP_PATH = "Share/Fuben/RunGame/RunGameGroup.tab"
local TABLE_STAGE_PATH = "Client/Fuben/RunGame/RunGameStage.tab"
local TABLE_CHALLENGE_TARGET_PATH = "Share/Fuben/RunGame/RunGameChallengeTarget.tab"
local ActivityTemplates = {}
local GroupTemplates = {}
local StageTemplates = {}
local ChallengeTargetTemplates = {}

local GroupIdList = {}
local StageIdList = {}
local ChallengeTargetIdList = {}

local DefaultActivityId = 1

XLivWarmRaceConfigs = XLivWarmRaceConfigs or {}

XLivWarmRaceConfigs.MaxStarCount = 3

local InitLivWarmRaceActivityId = function()
    for activityId, config in pairs(ActivityTemplates) do
        if XTool.IsNumberValid(config.TimeId) then
            DefaultActivityId = activityId
            break
        end
        DefaultActivityId = activityId
    end
end

local InitLivWarmRaceIdList = function(idList, templates)
    for id in pairs(templates) do
        tableInsert(idList, id)
    end
    tableSort(idList, function(a, b)
        return a < b
    end)
end

function XLivWarmRaceConfigs.Init()
    ActivityTemplates = XTableManager.ReadByIntKey(TABLE_ACTIVITY_PATH, XTable.XTableRunGameActivity, "Id")
    GroupTemplates = XTableManager.ReadByIntKey(TABLE_GROUP_PATH, XTable.XTableRunGameGroup, "GroupId")
    StageTemplates = XTableManager.ReadByIntKey(TABLE_STAGE_PATH, XTable.XTableRunGameStage, "StageId")
    ChallengeTargetTemplates = XTableManager.ReadByIntKey(TABLE_CHALLENGE_TARGET_PATH, XTable.XTableRunGameChallengeTarget, "Id")

    InitLivWarmRaceActivityId()
    InitLivWarmRaceIdList(GroupIdList, GroupTemplates)
    InitLivWarmRaceIdList(StageIdList, StageTemplates)
    InitLivWarmRaceIdList(ChallengeTargetIdList, ChallengeTargetTemplates)
end

-----------------LivWarmRaceActivity 活动相关 begin-----------------------
local GetLivWarmRaceActivityConfig = function(id)
    local config = ActivityTemplates[id]
    if not config then
        XLog.ErrorTableDataNotFound("XLivWarmRaceConfigs.GetLivWarmRaceActivityConfig", "ActivityTemplates", TABLE_ACTIVITY_PATH, "Id", id)
        return
    end
    return config
end

function XLivWarmRaceConfigs.SetDefaultActivityId(activityId)
    local config = GetLivWarmRaceActivityConfig(activityId)
    if not config then
        return
    end
    DefaultActivityId = activityId
end

function XLivWarmRaceConfigs.GetActivityId()
    return DefaultActivityId
end

function XLivWarmRaceConfigs.GetActivityTimeId()
    local config = GetLivWarmRaceActivityConfig(DefaultActivityId)
    return config.TimeId
end

function XLivWarmRaceConfigs.GetActivityConsumeId()
    local config = GetLivWarmRaceActivityConfig(DefaultActivityId)
    return config.ConsumeId
end

function XLivWarmRaceConfigs.GetActivityConsumeCount()
    local config = GetLivWarmRaceActivityConfig(DefaultActivityId)
    return config.ConsumeCount
end

function XLivWarmRaceConfigs.GetActivityGroupIds()
    local config = GetLivWarmRaceActivityConfig(DefaultActivityId)
    return config.GroupIds
end

function XLivWarmRaceConfigs.GetActivityFinalStageId()
    local config = GetLivWarmRaceActivityConfig(DefaultActivityId)
    return config.FinalStageId
end

function XLivWarmRaceConfigs.GetActivityFinalStageModel()
    local config = GetLivWarmRaceActivityConfig(DefaultActivityId)
    return config.FinalStageModel
end

function XLivWarmRaceConfigs.GetActivityName()
    local config = GetLivWarmRaceActivityConfig(DefaultActivityId)
    return config.Name
end

function XLivWarmRaceConfigs.GetAllRobotId()
    local groupIds = XLivWarmRaceConfigs.GetActivityGroupIds()
    local robotIdList = {}
    for _, groupId in ipairs(groupIds) do
        table.insert(robotIdList, XLivWarmRaceConfigs.GetGroupRobotId(groupId))
    end
    return robotIdList
end
-----------------LivWarmRaceActivity 活动相关 end-----------------------

-----------------LivWarmRaceGroup 关卡组 begin-----------------------
local GetLivWarmRaceGroupConfig = function(id)
    local config = GroupTemplates[id]
    if not config then
        XLog.ErrorTableDataNotFound("XLivWarmRaceConfigs.GetLivWarmRaceGroupConfig", "GroupTemplates", TABLE_GROUP_PATH, "Id", id)
        return
    end
    return config
end

function XLivWarmRaceConfigs.GetGroupName(id)
    local config = GetLivWarmRaceGroupConfig(id)
    return config.Name
end

function XLivWarmRaceConfigs.GetGroupPrefab(id)
    local config = GetLivWarmRaceGroupConfig(id)
    return config.Prefab
end

function XLivWarmRaceConfigs.GetGroupStageIds(id)
    local config = GetLivWarmRaceGroupConfig(id)
    return config.StageIds
end

function XLivWarmRaceConfigs.GetGroupRoleHead(id)
    local config = GetLivWarmRaceGroupConfig(id)
    return config.RoleHead
end

function XLivWarmRaceConfigs.GetGroupRoleName(id)
    local config = GetLivWarmRaceGroupConfig(id)
    return config.RoleName
end

function XLivWarmRaceConfigs.GetGroupRobotId(id)
    local config = GetLivWarmRaceGroupConfig(id)
    return config.RobotId
end
-----------------LivWarmRaceGroup 关卡组 end-----------------------

-----------------LivWarmRaceStage 关卡 begin-----------------------
local GetLivWarmRaceStageConfig = function(id)
    local config = StageTemplates[id]
    if not config then
        XLog.ErrorTableDataNotFound("XLivWarmRaceConfigs.GetLivWarmRaceStageConfig", "StageTemplates", TABLE_STAGE_PATH, "Id", id)
        return
    end
    return config
end

function XLivWarmRaceConfigs.GetStageIdList()
    return StageIdList
end

function XLivWarmRaceConfigs.GetStagePrefab(id)
    local config = GetLivWarmRaceStageConfig(id)
    return config.Prefab
end

function XLivWarmRaceConfigs.GetStageMonsterHead(id)
    local config = GetLivWarmRaceStageConfig(id)
    return config.MonsterHead
end

function XLivWarmRaceConfigs.GetStageNotOpenName(id)
    local config = GetLivWarmRaceStageConfig(id)
    return config.NotOpenName
end
-----------------LivWarmRaceStage 关卡 end-----------------------

-----------------LivWarmRaceChallegneTarget 目标 begin-----------------------
local GetLivWarmRaceChallegneTargetConfig = function(id)
    local config = ChallengeTargetTemplates[id]
    if not config then
        XLog.ErrorTableDataNotFound("XLivWarmRaceConfigs.GetLivWarmRaceChallegneTargetConfig", "ChallengeTargetTemplates", TABLE_CHALLENGE_TARGET_PATH, "Id", id)
        return
    end
    return config
end

function XLivWarmRaceConfigs.GetChallengeTargetIdList()
    return ChallengeTargetIdList
end

function XLivWarmRaceConfigs.GetChallengeTargetTotalStarCount()
    local totalCount = 0
    for _, id in ipairs(ChallengeTargetIdList) do
        totalCount = math.max(totalCount, XLivWarmRaceConfigs.GetChallegneTarget(id))
    end
    return totalCount
end

function XLivWarmRaceConfigs.GetChallegneTarget(id)
    local config = GetLivWarmRaceChallegneTargetConfig(id)
    return config.Target
end

function XLivWarmRaceConfigs.GetChallegneTargetRewardId(id)
    local config = GetLivWarmRaceChallegneTargetConfig(id)
    return config.RewardId
end
-----------------LivWarmRaceChallegneTarget 目标 end-----------------------