XGuildBossConfig = XGuildBossConfig or {}

local TABLE_GUILDBOSS_STAGEINFO = "Client/Guild/Boss/GuildStageInfo.tab"
local TABLE_GUILDBOSS_BUFF = "Client/Guild/Boss/GuildBossStageBuff.tab"
local TABLE_GUILDBOSS_LEVEL = "Share/Guild/Boss/GuildBossLevel.tab"
local TABLE_GUILDBOSS_HP_REWAED = "Share/Guild/Boss/GuildBossHpReward.tab"
local TABLE_GUILDBOSS_SCORE_REWAED = "Share/Guild/Boss/GuildBossScoreReward.tab"
local TABLE_GUILDBOSS_RANK_REWAED = "Share/Guild/Boss/GuildBossRankReward.tab"
local TABLE_GUILDBOSS_DATA= "Share/Guild/Boss/GuildBossData.tab"
local TABLE_GUILDBOSS_STAGE_ROBOT = "Share/Guild/Boss/GuildBossStageRobot.tab"
local TABLE_GUILDBOSS_FIGHT_STYLE = "Share/Guild/Boss/GuildBossFightStyle.tab" --nzwjV3 作战风格
local TABLE_GUILDBOSS_FIGHT_STYLE_SKILL = "Share/Guild/Boss/GuildBossFightStyleSkill.tab" --nzwjV3 风格技能子表
local TABLE_GUILD_TASK_GROUP_PATH = "Client/Guild/GuildTaskGroup.tab"



local GuildBossStageInfos = {}
local GuildBossBuffs = {}
local GuildBossLevels = {}
local GuildBossHpRewards = {}
local GuildBossScoreRewards = {}
local GuildBossRankRewards = {}
local GuildBossData = {}
local GuildBossStageRobot = {}
local GuildBossFightStyle = {}
local GuildBossFightStyleSkill = {}
local GuildTaskGroup = {}
local GuildTaskList

local HpRewardIdList = {}
local RankRewardIdList = {}
local RankRewardId2Index = {}
local AllRegularRobotIdDic = {} -- 固定机器人字典，key = robotId
local AllStyleSkillsDic = {} -- 风格技能，根据风格类型分类 key = styleId

--参考Share\Guild\Boss\GuildBossData.tab
GuildBossLevelType = {
    Low = 1,
    High = 2,
    Boss = 3,
}

GuildBossRewardType = {
    Disable = 1, --未达到不能领取
    Available = 2, --达到了还未领取
    Acquired = 3, --已获取
}

GuildBossStyleSkillChangeType = {
    Active = 1,  --激活技能
    Unistall = 2, --卸载技能
    Reset = 3, --重置所有技能
}

GuildTaskType = {
    --Boss积分
    BossScore = 1,
    --Boss血量
    BossHp = 2
}

function XGuildBossConfig.Init()
    GuildBossStageInfos = XTableManager.ReadAllByIntKey(TABLE_GUILDBOSS_STAGEINFO, XTable.XTableGuildBossStageInfo, "Id")
    GuildBossBuffs = XTableManager.ReadByIntKey(TABLE_GUILDBOSS_BUFF, XTable.XTableGuildBossBuff, "Id")
    GuildBossLevels = XTableManager.ReadByIntKey(TABLE_GUILDBOSS_LEVEL, XTable.XTableGuildBossLevel, "Level")
    GuildBossHpRewards = XTableManager.ReadByIntKey(TABLE_GUILDBOSS_HP_REWAED, XTable.XTableGuildBossHpReward, "Id")
    GuildBossScoreRewards = XTableManager.ReadByIntKey(TABLE_GUILDBOSS_SCORE_REWAED, XTable.XTableGuildBossScoreReward, "Id")
    GuildBossRankRewards = XTableManager.ReadByIntKey(TABLE_GUILDBOSS_RANK_REWAED, XTable.XTableGuildBossRankReward, "Id")
    GuildBossData = XTableManager.ReadByIntKey(TABLE_GUILDBOSS_DATA, XTable.XTableGuildBossData, "Id")
    GuildBossStageRobot = XTableManager.ReadByIntKey(TABLE_GUILDBOSS_STAGE_ROBOT, XTable.XTableGuildBossStageRobot, "Id")
    GuildBossFightStyle = XTableManager.ReadByIntKey(TABLE_GUILDBOSS_FIGHT_STYLE, XTable.XTableGuildBossFightStyle, "Id")
    GuildBossFightStyleSkill = XTableManager.ReadByIntKey(TABLE_GUILDBOSS_FIGHT_STYLE_SKILL, XTable.XTableGuildBossFightStyleSkill, "Id")
    GuildTaskGroup = XTableManager.ReadByIntKey(TABLE_GUILD_TASK_GROUP_PATH, XTable.XTableGuildTaskGroup, "GroupId")

    for _, v in ipairs(GuildBossHpRewards) do
        table.insert(HpRewardIdList, v.Id)
    end
    for i, v in ipairs(GuildBossRankRewards) do
        RankRewardId2Index[v.Id] = i
        table.insert(RankRewardIdList, v.Id)
    end
    for _, v in pairs(GuildBossData) do
        for _, robotGroupId in pairs(v.FixedRobot) do --fixedRobot为固定机器人
            local robotGroup = GuildBossStageRobot[robotGroupId]
            for _, robotId in pairs(robotGroup.RobotId) do
                AllRegularRobotIdDic[robotId] = robotGroup
            end
        end
    end
    for k, v in pairs(GuildBossFightStyleSkill) do
        if not AllStyleSkillsDic[v.Style] then
            AllStyleSkillsDic[v.Style] = {}
        end
        AllStyleSkillsDic[v.Style][v.Id] = v      
    end
end

function XGuildBossConfig.GetGuildStyleSkillByStyle(styleId)
    return AllStyleSkillsDic[styleId]
end

function XGuildBossConfig.GetGuildBossFightStyle()
    return GuildBossFightStyle
end

function XGuildBossConfig.GetGuildBossFightStyleSkill()
    return GuildBossFightStyleSkill
end

-- 所有的固定机器人
function XGuildBossConfig.GetAllRegularRobot()
    return AllRegularRobotIdDic
end

function XGuildBossConfig.GetBossStageInfos()
    return GuildBossStageInfos
end

function XGuildBossConfig.GetBossStageInfo(id)
    local info = GuildBossStageInfos[id]
    if info == nil then
        XLog.Error("表GuildStageInfo.tab中找不到Id：" .. id)
    end
    return info
end

--获取所有难度数据
function XGuildBossConfig.GetBossLevel()
    return GuildBossLevels
end

--获取buff信息
function XGuildBossConfig.GetBuff(id)
    local info = GuildBossBuffs[id]
    if info == nil then
        XLog.Error("GuildBossStageBuff.tab中找不到Id：" .. id)
    end
    return info
end

--获取总分奖励信息
function XGuildBossConfig.ScoreRewards()
    return GuildBossScoreRewards
end

--获取bossHp奖励信息
function XGuildBossConfig.HpRewards()
    return GuildBossHpRewards
end

function XGuildBossConfig.GetZeroHpRewardId()
    for _, cfg in pairs(GuildBossHpRewards or {}) do
        if cfg.HpPercent == 0 then
            local timeId = cfg.TimeId
            return XFunctionManager.CheckInTimeByTimeId(timeId) and cfg.NewRewardId or cfg.RewardId
        end
    end
    return 0
end

function XGuildBossConfig.GeHpRewardIdList()
    return HpRewardIdList
end

function XGuildBossConfig.GetHpPercent(id)
    return GuildBossHpRewards[id].HpPercent
end

-- 获取排名奖励配置
function XGuildBossConfig.GeRankRewardIdList()
    return RankRewardIdList
end

function XGuildBossConfig.GetRankRewards()
    return GuildBossRankRewards
end

function XGuildBossConfig.GetRankRewardId(id)
    return GuildBossRankRewards[id].RewardId
end

-- 获取排名显示文本
-- 返回'1%'  或 '1%-5%'
function XGuildBossConfig.GetRankPercentName(id)
    local index = RankRewardId2Index[id]
    local name = GuildBossRankRewards[id].Percent .. "%"
    if index > 1 then
        local lastId = RankRewardIdList[index - 1]
        name = GuildBossRankRewards[lastId].Percent .. "%-" .. name
    end
    return name
end

function XGuildBossConfig.GetTaskList()
    if GuildTaskList then
        return GuildTaskList
    end
    local list = {}
    for groupId, cfg in pairs(GuildTaskGroup) do
        local dataFunc = XGuildBossConfig[cfg.TaskDataKey]
        if not dataFunc then
            XLog.Error("[XGuildBossConfig.GetTaskList] 获取公会任务数据失败, DataKey = "..cfg.TaskDataKey)
            return
        end
        local taskData = dataFunc()
        local taskType = cfg.TaskType
        for id, data in pairs(taskData) do
            table.insert(list, {
                TaskId = id,
                Target = data.Score or data.HpPercent,
                TimeId = data.TimeId or -1,
                GroupId = groupId,
                SkipId = cfg.SkipId,
                Desc = cfg.Desc,
                Title = cfg.Title,
                TaskType = taskType
            })
        end
    end
    GuildTaskList = list
    return GuildTaskList
end 