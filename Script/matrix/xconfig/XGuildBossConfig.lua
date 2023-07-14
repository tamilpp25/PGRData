XGuildBossConfig = XGuildBossConfig or {}

local TABLE_GUILDBOSS_STAGEINFO = "Client/Guild/Boss/GuildStageInfo.tab"
local TABLE_GUILDBOSS_BUFF = "Client/Guild/Boss/GuildBossStageBuff.tab"
local TABLE_GUILDBOSS_LEVEL = "Share/Guild/Boss/GuildBossLevel.tab"
local TABLE_GUILDBOSS_HP_REWAED = "Share/Guild/Boss/GuildBossHpReward.tab"
local TABLE_GUILDBOSS_SCORE_REWAED = "Share/Guild/Boss/GuildBossScoreReward.tab"
local TABLE_GUILDBOSS_RANK_REWAED = "Share/Guild/Boss/GuildBossRankReward.tab"


local GuildBossStageInfos = {}
local GuildBossBuffs = {}
local GuildBossLevels = {}
local GuildBossHpRewards = {}
local GuildBossScoreRewards = {}
local GuildBossRankRewards = {}

local HpRewardIdList = {}
local RankRewardIdList = {}
local RankRewardId2Index = {}

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

function XGuildBossConfig.Init()
    GuildBossStageInfos = XTableManager.ReadAllByIntKey(TABLE_GUILDBOSS_STAGEINFO, XTable.XTableGuildBossStageInfo, "Id")
    GuildBossBuffs = XTableManager.ReadByIntKey(TABLE_GUILDBOSS_BUFF, XTable.XTableGuildBossBuff, "Id")
    GuildBossLevels = XTableManager.ReadByIntKey(TABLE_GUILDBOSS_LEVEL, XTable.XTableGuildBossLevel, "Level")
    GuildBossHpRewards = XTableManager.ReadByIntKey(TABLE_GUILDBOSS_HP_REWAED, XTable.XTableGuildBossHpReward, "Id")
    GuildBossScoreRewards = XTableManager.ReadByIntKey(TABLE_GUILDBOSS_SCORE_REWAED, XTable.XTableGuildBossScoreReward, "Id")
    GuildBossRankRewards = XTableManager.ReadByIntKey(TABLE_GUILDBOSS_RANK_REWAED, XTable.XTableGuildBossRankReward, "Id")

    for _, v in ipairs(GuildBossHpRewards) do
        table.insert(HpRewardIdList, v.Id)
    end
    for i, v in ipairs(GuildBossRankRewards) do
        RankRewardId2Index[v.Id] = i
        table.insert(RankRewardIdList, v.Id)
    end
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