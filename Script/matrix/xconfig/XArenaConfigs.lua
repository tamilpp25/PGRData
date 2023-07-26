---
--- 竞技副本配置表
---
XArenaConfigs = XArenaConfigs or {}

--战区贡献道具的id
XArenaConfigs.CONTRIBUTESCORE_ID = 54

XArenaActivityStatus = {
    --game服和竞技服等待数据的时候用
    Loading = -1,
    --默认状态
    Default = 0,
    --休息状态
    Rest = 1,
    --战斗状态
    Fight = 2,
    --结束
    Over = 3,
}

--个人排行区域
XArenaPlayerRankRegion = {
    UpRegion = 1,       --晋级区
    KeepRegion = 2,     --保级区
    DownRegion = 3,     --降级区
}

--竞技副本通关评级
XArenaAppraiseType = {
    S = 1,
    A = 2,
    B = 3,
    C = 4,
    D = 5,
}
-- 英雄小队
XArenaConfigs.ArenaHeroLv = 6
 
XArenaConfigs.ArenaTimerName = "FubenArenaActivityTimer"
XArenaConfigs.SHOP_ID = CS.XGame.ClientConfig:GetInt("AreanShopId")

local TABLE_ARENA_BUFF_DETAIL = "Client/Fuben/Arena/ArenaAreaBuffDetails.tab"
local TABLE_ARENA_STAGE = "Client/Fuben/Arena/ArenaStage.tab"
local TABLE_ARENA_LEVEL = "Share/Fuben/Arena/ArenaLevel.tab"
local TABLE_CHALLENGE_AREA = "Share/Fuben/Arena/ChallengeArea.tab"
local TABLE_AREA_STAGE = "Share/Fuben/Arena/AreaStage.tab"
local TABLE_TEAM_RANK_REWARD = "Share/Fuben/Arena/TeamRankReward.tab"
local TABLE_MARK = "Share/Fuben/Arena/Mark.tab"

local ArenaRankBottomCount      --竞技排行基数
local ArenaClientStageTemplate  --競技客户端关卡表
local ArenaLevelTemplate        --竞技段位表
local ChallengeAreaTemplate     --挑战区域表
local AreaStageTemplate         --战区关卡配置表
local TeamRankRewardTemplate    --队伍排行奖励表
local MarkTemplate              --结算分数表
local BuffDetail                --Buff展示信息配置表

local MaxArenaLevel = 0                 --最大竞技段位
local PlayerLevelRangeToChallengeIds    --玩家等级段索引挑战配置列表
local MaxArenaStageCountPerArea = 0     --竞技战区最大关卡数
local MaxChallengeId = 0                --最大挑战区域Id

--私有方法定义
local InitChallengeAreaCfg
local InitArenaLevelCfg
local InitAreaStageTemplate

function XArenaConfigs.Init()
    ArenaRankBottomCount = CS.XGame.Config:GetInt("ArenaTeamRankShow")
    ArenaClientStageTemplate = XTableManager.ReadByIntKey(TABLE_ARENA_STAGE, XTable.XTableArenaStage, "StageId")
    ArenaLevelTemplate = XTableManager.ReadByIntKey(TABLE_ARENA_LEVEL, XTable.XTableArenaLevel, "Id")
    ChallengeAreaTemplate = XTableManager.ReadByIntKey(TABLE_CHALLENGE_AREA, XTable.XTableChallengeArea, "ChallengeId")
    AreaStageTemplate = XTableManager.ReadByIntKey(TABLE_AREA_STAGE, XTable.XTableAreaStage, "Id")
    TeamRankRewardTemplate = XTableManager.ReadByIntKey(TABLE_TEAM_RANK_REWARD, XTable.XTableTeamRankReward, "Id")
    MarkTemplate = XTableManager.ReadByIntKey(TABLE_MARK, XTable.XTableMark, "MarkId")
    BuffDetail = XTableManager.ReadByIntKey(TABLE_ARENA_BUFF_DETAIL,XTable.XTableArenaAreaBuffDetails,"Id")
    InitArenaLevelCfg()
    InitChallengeAreaCfg()
    InitAreaStageTemplate()
end

InitArenaLevelCfg = function()
    for _, cfg in pairs(ArenaLevelTemplate) do
        if MaxArenaLevel < cfg.Id then
            MaxArenaLevel = cfg.Id
        end
    end
end

InitChallengeAreaCfg = function()
    PlayerLevelRangeToChallengeIds = {}

    local tempMap = {}
    local tempTypeId = 0

    for id, cfg in pairs(ChallengeAreaTemplate) do
        if id > MaxChallengeId then
            MaxChallengeId = id
        end
        local typeId = tempMap[cfg.MinLv]
        if not typeId then
            typeId = tempTypeId + 1
            tempMap[cfg.MinLv] = typeId
            tempTypeId = typeId
        end

        local map = PlayerLevelRangeToChallengeIds[typeId]
        if not map then
            map = {}
            PlayerLevelRangeToChallengeIds[typeId] = map
        end

        map[id] = cfg
    end
end

InitAreaStageTemplate = function()
    for _, cfg in pairs(AreaStageTemplate) do
        if MaxArenaStageCountPerArea < #cfg.StageId then
            MaxArenaStageCountPerArea = #cfg.StageId
        end
    end
end

local GetChallengeCfgMapById = function(challengeId)
    for _, map in ipairs(PlayerLevelRangeToChallengeIds) do
        local cfg = map[challengeId]
        if cfg then
            return map
        end
    end

    return nil
end

local SortChallenge = function(a, b)
    return a.ArenaLv < b.ArenaLv
end

local SorTeamRankReward = function(a, b)
    return a.MinRank < b.MinRank
end

-- 获取个人排行区文字
function XArenaConfigs.GetRankRegionText(rankRegion)
    if rankRegion == XArenaPlayerRankRegion.UpRegion then
        return CS.XTextManager.GetText("ArenaActivityUpRegion")
    elseif rankRegion == XArenaPlayerRankRegion.DownRegion then
        return CS.XTextManager.GetText("ArenaActivityDownRegion")
    else
        return CS.XTextManager.GetText("ArenaActivityKeepRegion")
    end
end

-- 获取个人排行区文字带颜色
function XArenaConfigs.GetRankRegionColorText(rankRegion)
    if rankRegion == XArenaPlayerRankRegion.UpRegion then
        return CS.XTextManager.GetText("ArenaActivityUpRegionColor")
    elseif rankRegion == XArenaPlayerRankRegion.DownRegion then
        return CS.XTextManager.GetText("ArenaActivityDownRegionColor")
    else
        return CS.XTextManager.GetText("ArenaActivityKeepRegionColor")
    end
end

-- 获取个人排行区描述
function XArenaConfigs.GetRankRegionDescText(rankRegion, challengeCfg)
    if rankRegion == XArenaPlayerRankRegion.UpRegion then
        return CS.XTextManager.GetText("ArenaActivityUpRegionDesc", 1, challengeCfg.DanUpRank)
    elseif rankRegion == XArenaPlayerRankRegion.DownRegion then
        return CS.XTextManager.GetText("ArenaActivityDownRegionDesc", challengeCfg.DanKeepRank + 1, challengeCfg.DanDownRank)
    else
        return CS.XTextManager.GetText("ArenaActivityKeepRegionDesc", challengeCfg.DanUpRank + 1, challengeCfg.DanKeepRank)
    end
end

-- 获取个人排行不升段位描述
function XArenaConfigs.GetRankNotRegionDescText(rankRegion)
    if rankRegion == XArenaPlayerRankRegion.UpRegion then
        return CS.XTextManager.GetText("ArenaActivityNotUpRegionDesc")
    elseif rankRegion == XArenaPlayerRankRegion.DownRegion then
        return CS.XTextManager.GetText("ArenaActivityNotDownRegionDesc")
    else
        return CS.XTextManager.GetText("ArenaActivityNotKeepRegionDesc")
    end
end

-- 获取个人排行区奖励id
function XArenaConfigs.GetRankRegionRewardId(rankRegion, challengeCfg)
    if rankRegion == XArenaPlayerRankRegion.UpRegion then
        return challengeCfg.UpRewardId
    elseif rankRegion == XArenaPlayerRankRegion.DownRegion then
        return challengeCfg.DownRewardId
    else
        return challengeCfg.KeepRewardId
    end
end

-- 是否是最大竞技段位
function XArenaConfigs.IsMaxArenaLevel(level)
    return level >= MaxArenaLevel
end

function XArenaConfigs.GetMaxChallengeCfg()
    return XArenaConfigs.GetChallengeArenaCfgById(MaxChallengeId)
end

-- 获取竞技副本评级文字
function XArenaConfigs.GetArenaFightAppraiseText(appraiseType)
    if appraiseType == XArenaAppraiseType.S then
        return "S"
    elseif appraiseType == XArenaAppraiseType.A then
        return "A"
    elseif appraiseType == XArenaAppraiseType.B then
        return "B"
    elseif appraiseType == XArenaAppraiseType.C then
        return "C"
    elseif appraiseType == XArenaAppraiseType.D then
        return "D"
    end
end

-- 获取竞技队伍排行榜统计基数
function XArenaConfigs.GetArenaRankBottomCount()
    return ArenaRankBottomCount
end

-- 获取竞技段位配置表
function XArenaConfigs.GetArenaLevelCfgByLevel(level)
    return ArenaLevelTemplate[level]
end

-- 获取竞技段位配置表
function XArenaConfigs.GetArenaStageConfig(stageId)
    local t = ArenaClientStageTemplate[stageId]
    if not t then
        XLog.ErrorTableDataNotFound("XArenaConfigs.GetArenaStageConfig", "根据stageId获取的配置表项", TABLE_ARENA_STAGE, "stageId", tostring(stageId))
        return nil
    end
    return t
end

-- 获取竞技挑战配置表
function XArenaConfigs.GetChallengeArenaCfgById(challengeId)
    return ChallengeAreaTemplate[challengeId]
end

-- 获取竞技挑战配置列表
function XArenaConfigs.GetChallengeCfgListById(challengeId)
    local list = {}

    local map = GetChallengeCfgMapById(challengeId)
    if map then
        for _, cfg in pairs(map) do
            table.insert(list, cfg)
        end
        table.sort(list, SortChallenge)
    end
    return list
end

-- 获取竞技挑战最高等级
function XArenaConfigs.GetChallengeMaxArenaLevel(challengeId)
    local maxArenalLevel = 0

    local map = GetChallengeCfgMapById(challengeId)
    if map then
        for _, cfg in pairs(map) do
            if cfg.ArenaLv > maxArenalLevel then
                maxArenalLevel = cfg.ArenaLv
            end
        end
    end

    return maxArenalLevel
end

function XArenaConfigs.GetArenaStageCfg()
    return AreaStageTemplate
end

-- 获取竞技区域关卡配置
function XArenaConfigs.GetArenaAreaStageCfgByAreaId(areaId)
    return AreaStageTemplate[areaId]
end

-- 获取竞技战区最大关卡数量
function XArenaConfigs.GetTheMaxStageCountOfArenaArea()
    return MaxArenaStageCountPerArea
end

-- 获取竞技队伍排行奖励配置列表
function XArenaConfigs.GetTeamRankRewardCfgList(challengeId)
    local list = {}
    for _, cfg in pairs(TeamRankRewardTemplate) do
        if cfg.ChallengeId == challengeId then
            table.insert(list, cfg)
        end
    end

    if #list > 2 then
        table.sort(list, SorTeamRankReward)
    end

    return list
end

-- 获取竞技队伍排行奖励配置
function XArenaConfigs.GetTeamRankRewardCfgById(id)
    return TeamRankRewardTemplate[id]
end

-- 获取竞技结算分数配置
function XArenaConfigs.GetMarkCfgById(id)
    return MarkTemplate[id]
end

-- 获取最大分数
function XArenaConfigs.GetMarkMaxPointById(id)
    return MarkTemplate[id].MaxPoint
end

-- 获取竞技章节名字以及副本名字
function XArenaConfigs.GetChapterAndStageName(areaId, stageId)
    local chapterName = AreaStageTemplate[areaId].Name
    local stageName = XDataCenter.FubenManager.GetStageCfg(stageId).Name
    return chapterName, stageName
end

-- 获取Buff客户端展示信息配置
function XArenaConfigs.GetArenaBuffCfg(buffId)
    return BuffDetail[buffId]
end 