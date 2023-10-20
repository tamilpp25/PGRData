XFubenUnionKillConfigs = XTool.GetNoneSenseTable()

--local SHARE_UNION_ACTIVITY = "Share/Fuben/UnionKill/UnionKillActivity.tab"
--local SHARE_UNION_EVENT_STAGE = "Share/Fuben/UnionKill/UnionKillEventStage.tab"
--local SHARE_UNION_RANK_REWARD = "Share/Fuben/UnionKill/UnionKillRankReward.tab"
local SHARE_UNION_SCORE_RULE = "Share/Fuben/UnionKill/UnionKillScoreRule.tab"
--local SHARE_UNION_SECTION = "Share/Fuben/UnionKill/UnionKillSection.tab"
--local SHARE_UNION_WEATHER = "Share/Fuben/UnionKill/UnionKillWeather.tab"
--local SHARE_UNION_RANK_LEVEL = "Share/Fuben/UnionKill/UnionKillRankLevel.tab"
--
--
--local CLIENT_UNION_ACTIVITY = "Client/Fuben/UnionKill/UnionKillActivityDetails.tab"
--local CLIENT_UNION_WEATHER = "Client/Fuben/UnionKill/UnionKillWeatherDetails.tab"
--local CLIENT_UNION_SECTION = "Client/Fuben/UnionKill/UnionKillSectionDetails.tab"
--local CLIENT_UNION_EVENT = "Client/Fuben/UnionKill/UnionKillEventDetails.tab"
--
--local UnionActivity = {}
--local UnionEventStage = {}
--local UnionRankReward = {}
--local UnionScoreRule = {}
--local UnionSection = {}
--local UnionWeather = {}
--local UnionRankLevel = {}
--
--local UnionActivityConfig = {}
--local UnionWeatherConfig = {}
--local UnionSectionConfig = {}
--local UnionEventConfig = {}



XFubenUnionKillConfigs.UnionRoomPlayerState = {
    Normal = 0, --正常、未准备
    Ready = 1, --准备
    Select = 2, --编辑队伍
    Fight = 3   --战斗中
}

XFubenUnionKillConfigs.UnionRoomState = {
    Normal = 0,
    Fight = 1, -- 战斗
    Settle = 2, -- 结算
    Close = 3, -- 关闭
}

XFubenUnionKillConfigs.UnionKillStageType = {
    EventStage = 1, -- 事件关
    BossStage = 2, -- boss关
    TrialStage = 3, -- 试炼关
}
XFubenUnionKillConfigs.UnionKillCharType = {
    Own = 1, -- 自己拥有标记
    Share = 2, -- 共享角色标记
}
XFubenUnionKillConfigs.UnionRankType = {
    ThumbsUp = 1, -- 点赞排名
    KillNumber = 2                                  -- 歼敌排名
}
XFubenUnionKillConfigs.LeaveReason = {
    LeaveTeam = 1, -- 离开队伍
    LeaveFight = 2, -- 离开战斗
    TimeOver = 3, -- 战斗事件结束
    KickOut = 4, -- 被踢
    Offline = 5, -- 离线
    Logout = 6, -- 登出
}
XFubenUnionKillConfigs.TipsMessageType = {
    Praise = 1, -- 点赞
    FightBrrow = 2, -- 我借用了玩家的xxx,
    ResultBorrow = 3, -- 点赞
    LeaveStage = 4, -- 离开关卡
}

XFubenUnionKillConfigs.ActivityChangeType = {
    None = 0,
    ActivityOpen = 1, -- 活动开启
    ActivityClose = 2, -- 活动结束
    SectionChange = 3, -- 章节改变
    WeatherChange = 4, -- 天气改变
}

XFubenUnionKillConfigs.NotShowToday = "UnionKillTipsNotShowToday"
XFubenUnionKillConfigs.FirstShowHelp = "UnionKillTipsFirstShowHelp"

XFubenUnionKillConfigs.MaxTeamCount = 4             -- 队伍人数
XFubenUnionKillConfigs.MaxCharacterCount = 3        -- 出站人数
XFubenUnionKillConfigs.PraiseInterval = CS.XGame.ClientConfig:GetInt("UnionPraiseInterval")          -- 点赞界面倒计时
XFubenUnionKillConfigs.RankRequestInterval = CS.XGame.ClientConfig:GetInt("UnionRankRequestInterval")     -- 排名请求间隔
XFubenUnionKillConfigs.AllReadyCount = CS.XGame.ClientConfig:GetInt("UnionAllReadyInterval")

-- 测试用-以后改为读表
XFubenUnionKillConfigs.PraiseWords = "UnionTipPraise"
-- 类型1， 0对应参数PlayerId, 1对应CharacterId
XFubenUnionKillConfigs.FightBorrowMine = "UnionTipsFightBorrow"
XFubenUnionKillConfigs.FightBorrowOthers = "UnionTipsBorrowOthers"
-- 类型2, playerId对应是谁说的话，ShareCharacterInfos对应用了哪个角色
XFubenUnionKillConfigs.RefreshHighestPoint = "UnionTipHighestPoint"
-- 类型3， 0对应PlyaerId
--local DefaultActivityId = 0

--function XFubenUnionKillConfigs.Init()
--UnionActivity = XTableManager.ReadByIntKey(SHARE_UNION_ACTIVITY, XTable.XTableUnionKillActivity, "Id")
--UnionEventStage = XTableManager.ReadByIntKey(SHARE_UNION_EVENT_STAGE, XTable.XTableUnionKillEventStage, "Id")
--UnionRankReward = XTableManager.ReadByIntKey(SHARE_UNION_RANK_REWARD, XTable.XTableUnionKillRankReward, "Id")
--UnionScoreRule = XTableManager.ReadByIntKey(SHARE_UNION_SCORE_RULE, XTable.XTableUnionKillScoreRule, "Id")
--UnionSection = XTableManager.ReadByIntKey(SHARE_UNION_SECTION, XTable.XTableUnionKillSection, "Id")
--UnionWeather = XTableManager.ReadByIntKey(SHARE_UNION_WEATHER, XTable.XTableUnionKillWeather, "Id")
--UnionRankLevel = XTableManager.ReadByIntKey(SHARE_UNION_RANK_LEVEL, XTable.XTableUnionKillRankLevel, "Id")
--
--UnionActivityConfig = XTableManager.ReadByIntKey(CLIENT_UNION_ACTIVITY, XTable.XTableUnionKillActivityDetails, "Id")
--UnionWeatherConfig = XTableManager.ReadByIntKey(CLIENT_UNION_WEATHER, XTable.XTableUnionKillWeatherDetails, "Id")
--UnionSectionConfig = XTableManager.ReadByIntKey(CLIENT_UNION_SECTION, XTable.XTableUnionKillSectionDetails, "Id")
--UnionEventConfig = XTableManager.ReadByIntKey(CLIENT_UNION_EVENT, XTable.XTableUnionKillEventDetails, "Id")
--
--for activityId, config in pairs(UnionActivity) do
--    if XTool.IsNumberValid(config.TimeId) then
--        DefaultActivityId = activityId
--        break
--    end
--    DefaultActivityId = activityId--若全部过期，取最后一行配置作为默认下次开启的活动ID
--end
--end

--function XFubenUnionKillConfigs.GetUnionActivityById(id)
--    local activityTemplate = UnionActivity[id]
--    if not activityTemplate then
--        XLog.ErrorTableDataNotFound("XFubenUnionKillConfigs.GetUnionActivityById", "UnionKillActivity", SHARE_UNION_ACTIVITY, "Id", tostring(id))
--        return
--    end
--    return activityTemplate
--end
--
--function XFubenUnionKillConfigs.GetUnionActivityConfigById(id)
--    local activityConfig = UnionActivityConfig[id]
--    if not activityConfig then
--        XLog.ErrorTableDataNotFound("XFubenUnionKillConfigs.GetUnionActivityConfigById",
--        "UnionKillActivityDetails", CLIENT_UNION_ACTIVITY, "Id", tostring(id))
--        return
--    end
--    return activityConfig
--end
--
--function XFubenUnionKillConfigs.GetUnionEventStageById(id)
--    local eventStageTemplate = UnionEventStage[id]
--    if not eventStageTemplate then
--        XLog.ErrorTableDataNotFound("XFubenUnionKillConfigs.GetUnionEventStageById",
--        "UnionKillEventStage", SHARE_UNION_EVENT_STAGE, "Id", tostring(id))
--        return
--    end
--    return eventStageTemplate
--end
--
--function XFubenUnionKillConfigs.GetUnionEventConfigById(id)
--    local eventConfig = UnionEventConfig[id]
--    if not eventConfig then
--        XLog.ErrorTableDataNotFound("XFubenUnionKillConfigs.GetUnionEventConfigById", "UnionKillEventDetails", CLIENT_UNION_EVENT, "Id", tostring(id))
--        return
--    end
--    return eventConfig
--end
--
--function XFubenUnionKillConfigs.GetUnionRankRewardById(id)
--    local rankRewardTemplate = UnionRankReward[id]
--    if not rankRewardTemplate then
--        XLog.ErrorTableDataNotFound("XFubenUnionKillConfigs.GetUnionRankRewardById",
--        "UnionKillRankReward", SHARE_UNION_RANK_REWARD, "Id", tostring(id))
--        return
--    end
--    return rankRewardTemplate
--end
--
--function XFubenUnionKillConfigs.GetUnionRewardListByLevel(rankLevel)
--    local rankRewards = {}
--    for _, rankReward in pairs(UnionRankReward) do
--        if rankReward.LevelId == rankLevel then
--            table.insert(rankRewards, {
--                Id = rankReward.Id,
--                MinRank = rankReward.MinRank,
--                MaxRank = rankReward.MaxRank,
--                MailId = rankReward.MailId,
--                RankIcon = rankReward.RankIcon,
--            })
--        end
--    end
--
--    table.sort(rankRewards, function(rank1, rank2)
--        return rank1.MinRank < rank2.MinRank
--    end)
--    return rankRewards
--end
--
--function XFubenUnionKillConfigs.GetUnionScoreRuleById(id)
--    local scoreRuleTemplate = UnionScoreRule[id]
--    if not scoreRuleTemplate then
--        XLog.ErrorTableDataNotFound("XFubenUnionKillConfigs.GetUnionScoreRuleById", "UnionKillScoreRule", SHARE_UNION_SCORE_RULE, "Id", tostring(id))
--        return
--    end
--    return scoreRuleTemplate
--end
--
--function XFubenUnionKillConfigs.GetUnionSectionById(id)
--    local sectionTemplate = UnionSection[id]
--    if not sectionTemplate then
--        XLog.ErrorTableDataNotFound("XFubenUnionKillConfigs.GetUnionSectionById", "UnionKillSection", SHARE_UNION_SECTION, "Id", tostring(id))
--        return
--    end
--    return sectionTemplate
--end
--
--function XFubenUnionKillConfigs.GetUnionSectionConfigById(id)
--    local sectionConfig = UnionSectionConfig[id]
--    if not sectionConfig then
--        XLog.ErrorTableDataNotFound("XFubenUnionKillConfigs.GetUnionSectionConfigById",
--        "UnionKillSectionDetails", CLIENT_UNION_SECTION, "Id", tostring(id))
--        return
--    end
--    return sectionConfig
--end
--
--function XFubenUnionKillConfigs.GetUnionWeatherById(id)
--    local weatherTemplate = UnionWeather[id]
--    if not weatherTemplate then
--        XLog.ErrorTableDataNotFound("XFubenUnionKillConfigs.GetUnionWeatherById", "UnionKillWeather", SHARE_UNION_WEATHER, "Id", tostring(id))
--        return
--    end
--    return weatherTemplate
--end
--
--function XFubenUnionKillConfigs.GetUnionWeatherConfigById(id)
--    local weatherConfig = UnionWeatherConfig[id]
--    if not weatherConfig then
--        XLog.ErrorTableDataNotFound("XFubenUnionKillConfigs.GetUnionWeatherConfigById",
--        "UnionKillWeatherDetails", CLIENT_UNION_WEATHER, "Id", tostring(id))
--        return
--    end
--    return weatherConfig
--end
--
--function XFubenUnionKillConfigs.GetUnionRankLevelById(id)
--    local levelTemplate = UnionRankLevel[id]
--    if not levelTemplate then
--        XLog.ErrorTableDataNotFound("XFubenUnionKillConfigs.GetUnionRankLevelById", "UnionKillRankLevel", SHARE_UNION_RANK_LEVEL, "Id", tostring(id))
--        return
--    end
--    return levelTemplate
--end
--
--function XFubenUnionKillConfigs.GetAllRankLevel()
--    return UnionRankLevel
--end
--
--function XFubenUnionKillConfigs.GetUnionActivityTimes(activityId)
--    local activityTemplate = XFubenUnionKillConfigs.GetUnionActivityById(activityId)
--    if not activityTemplate then return nil, nil end
--    return XFunctionManager.GetTimeByTimeId(activityTemplate.TimeId)
--end
--
--function XFubenUnionKillConfigs.GetUnionSectionTimes(sectionId)
--    local sectionTemplate = XFubenUnionKillConfigs.GetUnionSectionById(sectionId)
--    if not sectionTemplate then return nil, nil end
--    return XFunctionManager.GetTimeByTimeId(sectionTemplate.TimeId)
--end
--
---- 该玩法是否处于活动时间内
--function XFubenUnionKillConfigs.UnionKillInActivity(activityId)
--    local beginTime, EndTime = XFubenUnionKillConfigs.GetUnionActivityTimes(activityId)
--    return XFubenUnionKillConfigs.Between2Stamp(beginTime, EndTime)
--end
--
---- 每轮是否处于活动时间内
--function XFubenUnionKillConfigs.UnionKillInSectionTime(sectionId)
--    local beginTime, EndTime = XFubenUnionKillConfigs.GetUnionSectionTimes(sectionId)
--    return XFubenUnionKillConfigs.Between2Stamp(beginTime, EndTime)
--end
--
---- 是否在两个时间内
--function XFubenUnionKillConfigs.Between2Stamp(beginTime, endTime)
--    if not beginTime or not endTime then return false end
--
--    local now = XTime.GetServerNowTimestamp()
--    return now >= beginTime and now <= endTime
--end
--
--function XFubenUnionKillConfigs.GetUnionDefaultActivityId()
--    return DefaultActivityId
--end