XMoeWarConfig = XMoeWarConfig or {}

local tableInsert = table.insert
local tableSort = table.sort

local TABLE_MOEWAR_ACTIVITY = "Share/MoeWar/MoeWarActivity.tab"
local TABLE_MOEWAR_INIT_PAIR = "Share/MoeWar/MoeWarInitPair.tab"
local TABLE_MOEWAR_MAIL = "Share/MoeWar/MoeWarMail.tab"
local TABLE_MOEWAR_MATCH = "Share/MoeWar/MoeWarMatch.tab"
local TABLE_MOEWAR_PLAYER_GROUP = "Share/MoeWar/MoeWarPlayer.tab"
local TABLE_MOEWAR_VOTE_ITEM = "Share/MoeWar/MoeWarVoteItem.tab"
local TABLE_MOEWAR_PLAYER_CONFIG = "Client/MoeWar/MoeWarPlayerLocal.tab"
local TABLE_MOEWAR_TASK_GROUP = "Client/MoeWar/MoeWarTaskGroup.tab"
local TABLE_MOEWAR_RANK_GROUP = "Client/MoeWar/MoeWarRankGroup.tab"
local TABLE_MOEWAR_PREPARATION_ACTIVITY = "Share/MoeWar/Preparation/MoeWarPreparationActivity.tab"
local TABLE_MOEWAR_PREPARATION_ASSISTANCE = "Share/MoeWar/Preparation/MoeWarPreparationAssistance.tab"
local TABLE_MOEWAR_PREPARATION_GEAR = "Share/MoeWar/Preparation/MoeWarPreparationGear.tab"
local TABLE_MOEWAR_PREPARATION_HELPER = "Share/MoeWar/Preparation/MoeWarPreparationHelper.tab"
local TABLE_MOEWAR_PREPARATION_MATCH = "Share/MoeWar/Preparation/MoeWarPreparationMatch.tab"
local TABLE_MOEWAR_PREPARATION_QUESHION = "Share/MoeWar/Preparation/MoeWarPreparationQuestion.tab"
local TABLE_MOEWAR_PREPARATION_STAGE = "Share/MoeWar/Preparation/MoeWarPreparationStage.tab"
local TABLE_MOEWAR_PREPARATION_STAGE_TAG_LABEL = "Client/MoeWar/MoeWarPreparationStageTagLabel.tab"
local TABLE_MOEWAR_PREPARATION_STAGE_EVALUATION_LABEL = "Client/MoeWar/MoeWarPreparationStageEvaluationLabel.tab"
local TABLE_MOEWAR_ANIMATION = "Client/MoeWar/MoeWarAnimation.tab"
local TABLE_MOEWAR_ANIMATION_GROUP = "Client/MoeWar/MoeWarAnimationGroup.tab"
local TABLE_MOEWAR_ICON_CONFIG = "Client/MoeWar/MoeWarIconConfig.tab"
local TABLE_MOEWAR_ACTIVITY_CONFIG = "Client/MoeWar/MoeWarActivityConfig.tab"
local TABLE_MOEWAR_PARKOUR_STAGE = "Share/MoeWar/Parkour/MoeWarParkourStage.tab"
local TABLE_MOEWAR_PARKOUR_ACTIVITY = "Share/MoeWar/Parkour/MoeWarParkourActivity.tab"
local TABLE_MOEWAR_NAMEPLATE_CONFIG = "Client/MoeWar/MoeWarNameplateConfig.tab"
local TABLE_MOEWAR_NAMEPLATE_STORE = "Share/MoeWar/MoeWarNameplateStore.tab"
local TABLE_MOEWAR_CHARACTER_MOOD = "Client/MoeWar/MoeWarCharacterMood.tab"
local TABLE_MOEWAR_THANK = "Client/MoeWar/MoeWarThank.tab"
local TABLE_MOEWAR_SCHEDULE_TAB_GROUP = "Client/MoeWar/MoeWarScheduleTabGroup.tab"

local MoeWarActivity = {}
local MoeWarInitPair = {}
local MoeWarMail = {}
local MoeWarMatch = {}
local MoeWarPlayers = {}
local MoeWarGroups = {}
local MoeWarVoteItem = {}
local MoeWarPlayerCfg = {}
local MoeWarTaskGroup = {}
local MoeWarRankGroup = {}
local MoeWarAnimation = {}
local MoeWarAnimationGroup = {}
local MoeWarIconConfig = {}
local MoeWarActivityConfig = {}
local MoeWarScheduleTabGroup = {}

local DefaultActivityId = 1
local MoeWarPreparationActivity = {}
local MoeWarPreparationAssistance = {}
local MoeWarPreparationGear = {}
local MoeWarPreparationHelper = {}
local MoeWarPreparationMatch = {}
local MoeWarPreparationQuestion = {}
local MoeWarPreparationStage = {}
local MoeWarPreparationStageTagLabel = {}
local MoeWarPreparationStageEvaluationLabel = {}
local PreparationAssistanceEffectIdList = {}
local MoeWarCharacterMood = {}
local MoeWarThank = {}

local MoeWarParkourStage = {}
local MoeWarParkourActivity = {}
local MoeWarNameplateStore = {}
local MoeWarNameplateConfig = {}
local MoeWarRobotId2HelperId = {}


XMoeWarConfig.KEY_GROUP_TAB_INDEX = "MOE_WAR_GROUP_TAB_INDEX_KEY"
XMoeWarConfig.SKIP_KEY_PREFIX = "MOE_WAR_SKIP"
XMoeWarConfig.DEFAULT_SELECT_KEY_PREFIX ="MOE_WAR_DEFAULT_SELECT"
XMoeWarConfig.MOE_WAR_VOTE_ANIMATION_RECORD = "MOE_WAR_VOTE_ANIMATION_RECORD"
XMoeWarConfig.MAX_NAMEPLATE_BUY_COUNT = 1 --铭牌最大购买数量
XMoeWarConfig.KEY_PARKOUR_TEAM = "KEY_PARKOUR_TEAM"
XMoeWarConfig.ScheNameColor = {
    NORMAL = XUiHelper.Hexcolor2Color("1B1B1B"),
    WIN = XUiHelper.Hexcolor2Color("1B1B1B"),
}

XMoeWarConfig.ScheNumColor = {
    NORMAL = XUiHelper.Hexcolor2Color("6B6E6E"),
    WIN = XUiHelper.Hexcolor2Color("6B6E6E"),
}

XMoeWarConfig.RankIcon = {
    [1] = CS.XGame.ClientConfig:GetString("BabelTowerRankIcon1"),
    [2] = CS.XGame.ClientConfig:GetString("BabelTowerRankIcon2"),
    [3] = CS.XGame.ClientConfig:GetString("BabelTowerRankIcon3"),
}

XMoeWarConfig.ScheduleIcon = {
    [1] = CS.XGame.ClientConfig:GetString("MoeWarScheduleIcon1"),
    [2] = CS.XGame.ClientConfig:GetString("MoeWarScheduleIcon2"),
    [3] = CS.XGame.ClientConfig:GetString("MoeWarScheduleIcon3"),
}

XMoeWarConfig.MatchType = {
    Voting = 1, --投票期
    Publicity = 2, --公示期
}

XMoeWarConfig.SessionType = {
    -- 海选期 27进24
    GameInAudition = 0,
    -- 第一轮投票期 24进18
    FirstRoundVoting = 1,
    -- 失败周投票期上半场 18进12
    FailWeekVotingUp = 2,
    -- 失败周投票期下半场 12进6
    FailWeekVotingDown = 3,
    -- 半决赛 6进3
    Game6In3 = 4,
    -- 总决赛 3进1
    Game3In1 = 5, 
}

XMoeWarConfig.SessionName = {
    "Game24In12",
    "Game12In6",
    "Game6In3",
    "Game3In1",
}

XMoeWarConfig.WarSituationType = {
    Default = 0,        --默认
    WinGroup = 1,       --战胜组
    FailGroup = 2,      --失败组
    WeedOut = 3,        --淘汰
}

XMoeWarConfig.RankType = {
    Daily = 1,
    Player = 2,
}

XMoeWarConfig.EventType = {
    Open = 1,
    Change = 2,
    VoteChange = 3,
}

XMoeWarConfig.MailType = {
    LastDay = 1,
    ResultOut = 2,
    VoteStart = 3,
    VoteEnd = 4,
}

XMoeWarConfig.SubTagType = {
    Top = 0, --顶部
    Mid = 1, --中间
    Btm = 2, --底部
    All = 3, --唯一
}

XMoeWarConfig.TaskType = {
    Daily = 1, --每日任务
    Normal = 2, --累计任务
}

XMoeWarConfig.ActionType = {
    Intro = 1,
    Thank = 2,
}

--帮手状态
XMoeWarConfig.PreparationHelperStatus = {
    NotCommunicating = 0, --未通讯
    Communicating = 1, --通讯中
    CommunicationEnd = 2, --通讯结束
    RecruitFinish = 3, --已招募
    RecruitFinishAndCommunicating = 4,  --已招募并通讯中
}

--场外援助效果类型
XMoeWarConfig.PreparationAssistanceEffectType = {
    Null = 0, --空
    MaxCount = 1, --援助上限
    ExcludeWrongAnswer = 2, --排除错误选项
    RecoveryTime = 3, --恢复间隔
    HelperDuration = 4, --增加帮手时长
}

--招募答题信息类型
XMoeWarConfig.RecruitMsgType = {
    MyMsg = 1,
    OtherMsg = 2,
    MyNo = 3,
    MyYes = 4,
    Line = 5,
    GiftThank = 6,  --赠礼回复
}

--问题类型
XMoeWarConfig.QuestionType = {
    QuestionStart = 1, --开局问候
    RandomQuestion = 2, --随机问题
    RecruitRight = 3, --招募成功结语
    RecruitLose = 4, --招募失败结语
}

--赛事筹备开启状态
XMoeWarConfig.MatchState = {
    ["NotOpen"] = 1,    --未开启
    ["Open"] = 2,       --开启中
    ["Over"] = 3,       --已结束
}

--跑酷小游戏关卡状态
XMoeWarConfig.ParkourGameState = {
    Unopened = 1, --未开启
    Opening  = 2, --开启中
    Over     = 3, --已结束
}

--跑酷积分结算Key
XMoeWarConfig.ParkourSettleResultKey = {
    --总积分
    TotalScore   = "TotalScore",
    --移动积分
    MoveScore    = "MoveScore",
    --收集积分
    CollectScore = "CollectScore",
    --移动距离
    MoveDistance = "MoveDistance",
    --跑酷当日可获得票数
    DailyReward  = "DailyReward",
}

local InitPreparationAssistanceEffectIdList = function()
    local cfg = {}
    for effectId, v in pairs(MoeWarPreparationAssistance) do
        tableInsert(cfg, v)
    end
    tableSort(cfg, function(a, b)
        if a.Order ~= b.Order then
            return a.Order < b.Order
        end
        return a.EffectId < b.EffectId
    end)
    for _, v in pairs(cfg) do
        tableInsert(PreparationAssistanceEffectIdList, v.EffectId)
    end
end

function XMoeWarConfig.Init()
    MoeWarActivity = XTableManager.ReadByIntKey(TABLE_MOEWAR_ACTIVITY, XTable.XTableMoeWarActivity, "Id")
    MoeWarInitPair = XTableManager.ReadByIntKey(TABLE_MOEWAR_INIT_PAIR, XTable.XTableMoeWarInitPair, "Id")
    MoeWarMail = XTableManager.ReadByIntKey(TABLE_MOEWAR_MAIL, XTable.XTableMoeWarMail, "Id")
    MoeWarMatch = XTableManager.ReadByIntKey(TABLE_MOEWAR_MATCH, XTable.XTableMoeWarMatch, "Id")
    MoeWarPlayers = XTableManager.ReadByIntKey(TABLE_MOEWAR_PLAYER_GROUP, XTable.XTableMoeWarPlayer, "Id")
    MoeWarVoteItem = XTableManager.ReadByIntKey(TABLE_MOEWAR_VOTE_ITEM, XTable.XTableMoeWarVoteItem, "No")
    MoeWarPlayerCfg = XTableManager.ReadByIntKey(TABLE_MOEWAR_PLAYER_CONFIG, XTable.XTableMoeWarPlayerLocal, "Id")
    MoeWarTaskGroup = XTableManager.ReadByIntKey(TABLE_MOEWAR_TASK_GROUP, XTable.XTableMoeWarTaskGroup, "Id")
    MoeWarRankGroup = XTableManager.ReadByIntKey(TABLE_MOEWAR_RANK_GROUP, XTable.XTableMoeRankGroup, "RankType")
    MoeWarPreparationActivity = XTableManager.ReadByIntKey(TABLE_MOEWAR_PREPARATION_ACTIVITY, XTable.XTableMoeWarPreparationActivity, "Id")
    MoeWarPreparationAssistance = XTableManager.ReadByIntKey(TABLE_MOEWAR_PREPARATION_ASSISTANCE, XTable.XTableMoeWarPreparationAssistance, "EffectId")
    MoeWarPreparationGear = XTableManager.ReadByIntKey(TABLE_MOEWAR_PREPARATION_GEAR, XTable.XTableMoeWarPreparationGear, "Id")
    MoeWarPreparationHelper = XTableManager.ReadByIntKey(TABLE_MOEWAR_PREPARATION_HELPER, XTable.XTableMoeWarPreparationHelper, "Id")
    MoeWarPreparationMatch = XTableManager.ReadByIntKey(TABLE_MOEWAR_PREPARATION_MATCH, XTable.XTableMoeWarPreparationMatch, "Id")
    MoeWarPreparationQuestion = XTableManager.ReadByIntKey(TABLE_MOEWAR_PREPARATION_QUESHION, XTable.XTableMoeWarPreparationQuestion, "Id")
    MoeWarPreparationStage = XTableManager.ReadByIntKey(TABLE_MOEWAR_PREPARATION_STAGE, XTable.XTableMoeWarPreparationStage, "StageId")
    MoeWarPreparationStageTagLabel = XTableManager.ReadByIntKey(TABLE_MOEWAR_PREPARATION_STAGE_TAG_LABEL, XTable.XTableMoeWarPreparationStageTagLabel, "Id")
    MoeWarPreparationStageEvaluationLabel = XTableManager.ReadByIntKey(TABLE_MOEWAR_PREPARATION_STAGE_EVALUATION_LABEL, XTable.XTableMoeWarPreparationStageEvaluationLabel, "ReachNum")
    MoeWarIconConfig = XTableManager.ReadByIntKey(TABLE_MOEWAR_ICON_CONFIG,XTable.XTableMoeWarIconConfig,"Id")
    MoeWarActivityConfig = XTableManager.ReadByIntKey(TABLE_MOEWAR_ACTIVITY_CONFIG,XTable.XTableMoeWarActivityConfig,"Id")
    MoeWarAnimation = XTableManager.ReadByIntKey(TABLE_MOEWAR_ANIMATION, XTable.XTableMoeWarAnimation, "Id")
    MoeWarAnimationGroup = XTableManager.ReadByIntKey(TABLE_MOEWAR_ANIMATION_GROUP, XTable.XTableMoeWarAnimationGroup, "Id")
    MoeWarParkourStage = XTableManager.ReadByIntKey(TABLE_MOEWAR_PARKOUR_STAGE, XTable.XTableMoeWarParkourStage, "Id")
    MoeWarParkourActivity = XTableManager.ReadByIntKey(TABLE_MOEWAR_PARKOUR_ACTIVITY, XTable.XTableMoeWarParkourActivity, "Id")
    MoeWarNameplateConfig = XTableManager.ReadByIntKey(TABLE_MOEWAR_NAMEPLATE_CONFIG, XTable.XTableMoeWarMoeWarNameplateConfig, "Id")
    MoeWarNameplateStore = XTableManager.ReadByIntKey(TABLE_MOEWAR_NAMEPLATE_STORE, XTable.XTableMoeWarNameplateStore, "NameplateId")
    MoeWarCharacterMood = XTableManager.ReadByIntKey(TABLE_MOEWAR_CHARACTER_MOOD, XTable.XTableMoeWarCharacterMood, "Id")
    MoeWarThank = XTableManager.ReadByIntKey(TABLE_MOEWAR_THANK, XTable.XTableMoeWarThank, "Id")
    MoeWarScheduleTabGroup = XTableManager.ReadByIntKey(TABLE_MOEWAR_SCHEDULE_TAB_GROUP,XTable.XTableMoeWarScheduleTabGroup,"Id")
    for _, v in pairs(MoeWarPlayers) do
        if not MoeWarGroups[v.Group] then
            MoeWarGroups[v.Group] = {}
        end
        tableInsert(MoeWarGroups[v.Group], v)
    end

    for id, cfg in pairs(MoeWarPreparationHelper) do
        MoeWarRobotId2HelperId[cfg.RobotId] = id
    end
    
    InitPreparationAssistanceEffectIdList()
end

function XMoeWarConfig.GetPlayers()
    return MoeWarPlayers
end

function XMoeWarConfig.GetPlayerGroup(id)
    return MoeWarPlayers[id].Group
end

function XMoeWarConfig.GetGroups()
    return MoeWarGroups
end

function XMoeWarConfig.GetRankGroups()
    return MoeWarRankGroup
end

function XMoeWarConfig.GetRankGroupByType(type)
    return MoeWarRankGroup[type]
end

function XMoeWarConfig.GetGroupById(id)
    return MoeWarGroups[id]
end

function XMoeWarConfig.GetScheduleTabGroup()
    return MoeWarScheduleTabGroup
end

function XMoeWarConfig.GetPlayerCfg(id)
    local template = MoeWarPlayerCfg[id]
    if not template then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetPlayerCfg", "MoeWarPlayerCfg", TABLE_MOEWAR_PLAYER_CONFIG, "Id", tostring(id))
        return
    end
    return template
end

function XMoeWarConfig.GetActTemplates()
    return MoeWarActivity
end

function XMoeWarConfig.GetActivityTemplateById(id)
    id = id or DefaultActivityId
    if not MoeWarActivity[id] then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetActivityTemplateById", "MoeWarActivity", TABLE_MOEWAR_ACTIVITY, "Id", tostring(id))
        return
    end
    return MoeWarActivity[id]
end

function XMoeWarConfig.GetInitPair(id)
    return MoeWarInitPair[id]
end

function XMoeWarConfig.GetMail(id)
    return MoeWarMail[id]
end
function XMoeWarConfig.GetInitPairsByGroupId(groupId)
    local tempList = {}
    for k, v in pairs(MoeWarInitPair) do
        if v.GroupId == groupId then
            tableInsert(tempList, v)
        end
    end
    return tempList
end

function XMoeWarConfig.GetMatch(id)
    return MoeWarMatch[id]
end

function XMoeWarConfig.GetMatchCfgs()
    return MoeWarMatch
end

function XMoeWarConfig.GetVoteItems()
    return MoeWarVoteItem
end

function XMoeWarConfig.GetVoteItemById(id)
    return MoeWarVoteItem[id]
end

function XMoeWarConfig.GetVoteByItemId(ItemId)
    return MoeWarVoteItem[ItemId]
end

function XMoeWarConfig.GetTaskGroupCount()
    return #MoeWarTaskGroup
end

function XMoeWarConfig.GetTaskType(id)
    if not MoeWarTaskGroup[id] then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetTaskType", "MoeWarTaskGroup", TABLE_MOEWAR_TASK_GROUP, "Id", tostring(id))
        return
    end
    return MoeWarTaskGroup[id].Type
end

function XMoeWarConfig.GetTaskName(id)
    if not MoeWarTaskGroup[id] then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetTaskName", "MoeWarTaskGroup", TABLE_MOEWAR_TASK_GROUP, "Id", tostring(id))
        return
    end
    return MoeWarTaskGroup[id].Name
end

function XMoeWarConfig.GetTaskGroupId(id)
	if not MoeWarTaskGroup[id] then
		XLog.ErrorTableDataNotFound("XMoeWarConfig.GetTaskName", "MoeWarTaskGroup", TABLE_MOEWAR_TASK_GROUP, "Id", tostring(id))
		return
	end
	return MoeWarTaskGroup[id].Group
end

function XMoeWarConfig.GetIconList(sessionId)
    if not MoeWarIconConfig[sessionId] then
        return
    end
    return MoeWarIconConfig[sessionId].IconList
end

function XMoeWarConfig.GetActivityTimeId(id)
    local template = XMoeWarConfig.GetActivityTemplateById(id)
    return template.ActivityTimeId
end

function XMoeWarConfig.GetActivityName(id)
    local template = XMoeWarConfig.GetActivityTemplateById(id)
    return template.Name
end

function XMoeWarConfig.GetActivityBg(id)
    local template = XMoeWarConfig.GetActivityTemplateById(id)
    return template.Background
end

function XMoeWarConfig.GetGachaSkipId()
    return MoeWarActivityConfig[1].GachaSkipId
end

function XMoeWarConfig.GetRewardSkipId()
    return MoeWarActivityConfig[1].RewardSkipId
end

function XMoeWarConfig.GetWebUrl()
    return MoeWarActivityConfig[1].WebUrl
end

function XMoeWarConfig.GetBeginStoryId()
    return MoeWarActivityConfig[1].BeginStoryId
end

function XMoeWarConfig.GetShowItems()
    return MoeWarActivityConfig[1].ShowItem
end

function XMoeWarConfig.GetMainHelpId()
    return MoeWarActivityConfig[1].MainHelpId
end
function XMoeWarConfig.GetVoteHelpId()
    return MoeWarActivityConfig[1].VoteHelpId
end
---------MoeWarPreparationActivity begin---------
local GetPreparationActivity = function(id)
    local template = MoeWarPreparationActivity[id]
    if not template then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetMoeWarPreparationActivity", "MoeWarPreparationActivity", TABLE_MOEWAR_PREPARATION_ACTIVITY, "Id", tostring(id))
        return
    end
    return template
end

function XMoeWarConfig.GetPreparationDefaultActivityId()
    return MoeWarPreparationActivity[1] and MoeWarPreparationActivity[1].Id
end

function XMoeWarConfig.GetPreparationActivityIdInTime(isGetDefaultActivityId)
    local nowTime = XTime.GetServerNowTimestamp()
    local lastOverEndTime = 0
    local defaultActivityId
    for _, v in pairs(MoeWarPreparationActivity) do
        if XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
            return v.Id
        end

        --活动没有开启返回最新已结束的活动id
        if isGetDefaultActivityId then
            local endTime = XFunctionManager.GetEndTimeByTimeId(v.TimeId)
            if nowTime >= endTime and endTime > lastOverEndTime then
                lastOverEndTime = endTime
                defaultActivityId = v.Id
            end
        elseif nowTime < XFunctionManager.GetStartTimeByTimeId(v.TimeId) then
            return v.Id
        end
    end
    return defaultActivityId
end

function XMoeWarConfig.GetPreparationActivityTimeId(id)
    local config = GetPreparationActivity(id)
    return config.TimeId
end

function XMoeWarConfig.GetPreparationActivityMatchIds(id)
    local config = GetPreparationActivity(id)
    local matchIds = {}
    for _, matchId in ipairs(config.MatchIds) do
        if matchId > 0 then
            tableInsert(matchIds, matchId)
        end
    end
    return matchIds
end

function XMoeWarConfig.GetPreparationActivityMaxStageCount(id)
    local config = GetPreparationActivity(id)
    return config.MaxStageCount
end

function XMoeWarConfig.GetPreparationActivityStageRecoveryTime(id)
    local config = GetPreparationActivity(id)
    return config.StageRecoveryTime
end

function XMoeWarConfig.GetPreparationActivityPreparationGears(id)
    local config = GetPreparationActivity(id)
    return config.PreparationGears
end

function XMoeWarConfig.GetPreparationActivityPrePreparationGear(id, preparationGearId)
    local preparationGears = XMoeWarConfig.GetPreparationActivityPreparationGears(id)
    for i, gearId in ipairs(preparationGears) do
        if gearId == preparationGearId then
            return preparationGears[i - 1]
        end
    end
end

function XMoeWarConfig.GetPreparationActivityName(id)
    local config = GetPreparationActivity(id)
    return config.Name
end

function XMoeWarConfig.GetPreparationActivityRedminNum(id)
    local config = GetPreparationActivity(id)
    return config.RedminNum
end

function XMoeWarConfig.GetPreparationActivityGiftAmount(id)
    local config = GetPreparationActivity(id)
    return config.GiftAmount
end
---------MoeWarPreparationActivity end-----------
---------MoeWarPreparationAssistance begin---------
local GetMoeWarPreparationAssistance = function(id)
    local template = MoeWarPreparationAssistance[id]
    if not template then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetMoeWarPreparationAssistance", "MoeWarPreparationAssistance", TABLE_MOEWAR_PREPARATION_ASSISTANCE, "Id", tostring(id))
        return
    end
    return template
end

local GetPreparationAssistanceIsShowInList = function(id)
    local config = GetMoeWarPreparationAssistance(id)
    return config.IsShowInList
end

function XMoeWarConfig.GetPreparationAssistanceSupportMaxCount()
    local voteItemId
    local level = 0
    local maxCount = 0
    for _, v in pairs(MoeWarPreparationAssistance) do
        if v.EffectType == XMoeWarConfig.PreparationAssistanceEffectType.MaxCount then
            voteItemId = XDataCenter.MoeWarManager.GetSupportVoteItemCount(v.VoteItemId)
            if voteItemId >= v.VoteItemCount and v.Level > level then
                level = v.Level
                maxCount = v.Param
            end
        end
    end
    return maxCount
end

function XMoeWarConfig.GetPreparationAssistanceAllDifferVoteItemId()
    local allDifferVoteItemIdDic = {}
    local allDifferVoteItemIdList = {}
    for _, v in pairs(MoeWarPreparationAssistance) do
        if not allDifferVoteItemIdDic[v.VoteItemId] then
            allDifferVoteItemIdDic[v.VoteItemId] = true
            tableInsert(allDifferVoteItemIdList, v.VoteItemId)
        end
    end
    return allDifferVoteItemIdList
end

function XMoeWarConfig.GetPreparationAssistanceVoteItemId(id)
    local config = GetMoeWarPreparationAssistance(id)
    return config.VoteItemId
end

function XMoeWarConfig.GetPreparationAssistanceVoteItemCount(id)
    local config = GetMoeWarPreparationAssistance(id)
    return config.VoteItemCount
end

function XMoeWarConfig.GetPreparationAssistanceTitle(id)
    local config = GetMoeWarPreparationAssistance(id)
    return config.Title
end

function XMoeWarConfig.GetPreparationAssistanceDesc(id)
    local config = GetMoeWarPreparationAssistance(id)
    return config.Desc
end

function XMoeWarConfig.GetPreparationAssistanceEffectIdList(isNotShowInList)
    if isNotShowInList then
        local effectIdList = {}
        local isShowInList
        for _, effectId in ipairs(PreparationAssistanceEffectIdList) do
            isShowInList = GetPreparationAssistanceIsShowInList(effectId)
            if isShowInList == 1 then
                tableInsert(effectIdList, effectId)
            end
        end
        return effectIdList
    end

    return PreparationAssistanceEffectIdList
end

function XMoeWarConfig.GetPreparationAssistanceEffectType(id)
    local config = GetMoeWarPreparationAssistance(id)
    return config.EffectType
end

function XMoeWarConfig.GetPreparationAssistanceParam(id)
    local config = GetMoeWarPreparationAssistance(id)
    return config.Param
end

function XMoeWarConfig.GetPreparationAssistanceLevel(id)
    local config = GetMoeWarPreparationAssistance(id)
    return config.Level
end
---------MoeWarPreparationAssistance end-----------
---------MoeWarPreparationGear begin---------
local GetMoeWarPreparationGear = function(id)
    local template = MoeWarPreparationGear[id]
    if not template then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetMoeWarPreparationGear", "MoeWarPreparationGear", TABLE_MOEWAR_PREPARATION_GEAR, "Id", tostring(id))
        return
    end
    return template
end

function XMoeWarConfig.GetPreparationGearNeedCount(id)
    local config = GetMoeWarPreparationGear(id)
    return config.NeedCount
end

function XMoeWarConfig.GetPreparationGearShowRewardId(id)
    local config = GetMoeWarPreparationGear(id)
    return config.ShowRewardId
end

function XMoeWarConfig.GetPreparationGearMaxNeedCount(activityId)
    local gears = XMoeWarConfig.GetPreparationActivityPreparationGears(activityId)
    local maxNeedCount = 0
    local needCount
    for _, gearId in ipairs(gears) do
        needCount = XMoeWarConfig.GetPreparationGearNeedCount(gearId)
        if needCount > maxNeedCount then
            maxNeedCount = needCount
        end
    end
    return maxNeedCount
end
---------MoeWarPreparationGear end-----------
---------MoeWarPreparationHelper begin---------
local GetMoeWarPreparationHelper = function(id)
    local template = MoeWarPreparationHelper[id]
    if not template then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetMoeWarPreparationHelper", "MoeWarPreparationHelper", TABLE_MOEWAR_PREPARATION_HELPER, "Id", tostring(id))
        return
    end
    return template
end

function XMoeWarConfig.GetMoeWarPreparationHelperRobotId(id)
    local config = GetMoeWarPreparationHelper(id)
    return config.RobotId
end

function XMoeWarConfig.GetMoeWarPreparationHelperLabelIds(id)
    local config = GetMoeWarPreparationHelper(id)
    return config.LabelIds
end

function XMoeWarConfig.GetMoeWarPreparationHelperTotalQuestionCount(id)
    local questionCounts = XMoeWarConfig.GetMoeWarPreparationHelperQuestionCounts(id)
    local questionBankIds = XMoeWarConfig.GetMoeWarPreparationHelperQuestionBankIds(id)
    local totalCount = 0
    local questionBankIdCount
    local realQuestionCount
    for i, questionCount in ipairs(questionCounts) do
        questionBankIdCount = XMoeWarConfig.GetPreparationQuestionBankIdCount(questionBankIds[i])
        realQuestionCount = questionBankIdCount < questionCount and questionBankIdCount or questionCount
        totalCount = totalCount + realQuestionCount
    end
    return totalCount
end

function XMoeWarConfig.GetMoeWarPreparationCommunicateConsumeCount(id)
    local config = GetMoeWarPreparationHelper(id)
    return config.CommunicateConsumeCount
end

function XMoeWarConfig.GetCharacterFullNameByHelperId(helperId)
    local robotId = XMoeWarConfig.GetMoeWarPreparationHelperRobotId(helperId)
    local characterId = XRobotManager.GetCharacterId(robotId)
    return XCharacterConfigs.GetCharacterFullNameStr(characterId)
end

function XMoeWarConfig.GetMoeWarPreparationHelperQuestionCounts(id)
    local config = GetMoeWarPreparationHelper(id)
    return config.QuestionCounts
end

function XMoeWarConfig.GetMoeWarPreparationHelperQuestionBankIds(id)
    local config = GetMoeWarPreparationHelper(id)
    return config.QuestionBankIds
end

function XMoeWarConfig.GetMoeWarPreparationHelperCirleIcon(id)
    local config = GetMoeWarPreparationHelper(id)
    return config.CirleIcon
end

function XMoeWarConfig.GetHelperIdByRobotId(robotId)
    return MoeWarRobotId2HelperId[robotId]
end

function XMoeWarConfig.GetPreparationHelperMoodUpLimit(id)
    local config = GetMoeWarPreparationHelper(id)
    local moodUpLimit = config.MoodUpLimit
    return XTool.IsNumberValid(moodUpLimit) and moodUpLimit or 1
end

function XMoeWarConfig.GetPreparationHelperGiftRecoveryMood(id)
    local config = GetMoeWarPreparationHelper(id)
    return config.GiftRecoveryMood
end

function XMoeWarConfig.GetPreparationHelperDefaultLock(id)
    if not XTool.IsNumberValid(id) then
        return false
    end
    local config = GetMoeWarPreparationHelper(id)
    return XTool.IsNumberValid(config.DefaultLock)
end

function XMoeWarConfig.GetPreparationHelperThankId(id)
    local config = GetMoeWarPreparationHelper(id)
    return config.ThankId
end

---------MoeWarPreparationHelper end-----------
---------MoeWarPreparationMatch begin---------
local GetMoeWarPreparationMatch = function(id)
    local template = MoeWarPreparationMatch[id]
    if not template then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetMoeWarPreparationMatch", "MoeWarPreparationMatch", TABLE_MOEWAR_PREPARATION_MATCH, "Id", tostring(id))
        return
    end
    return template
end

function XMoeWarConfig.GetPreparationMatchTimeId(id)
    local config = GetMoeWarPreparationMatch(id)
    return config.TimeId
end

function XMoeWarConfig.GetPreparationMatchHelperIds(id)
    local config = GetMoeWarPreparationMatch(id)
    return config.HelperIds
end

function XMoeWarConfig.GetPreparationMatchName(id)
    local config = GetMoeWarPreparationMatch(id)
    return config.Name
end

function XMoeWarConfig.GetPreparationCurrOpenMatchId()
    local timeId
    for _, v in pairs(MoeWarPreparationMatch) do
        timeId = XMoeWarConfig.GetPreparationMatchTimeId(v.Id)
        if XFunctionManager.CheckInTimeByTimeId(timeId) then
            return v.Id
        end
    end
end

function XMoeWarConfig.IsFillPreparationStageLabel(stageLableId, helperId)
    if not stageLableId or (not helperId or helperId == 0) then
        return false
    end
    local helperLabelIds = XMoeWarConfig.GetMoeWarPreparationHelperLabelIds(helperId)
    for index, helperLabelId in ipairs(helperLabelIds) do
        if stageLableId == helperLabelId then
            return true
        end
    end
    return false
end

function XMoeWarConfig.GetPreparationMatchNumText(id)
    local config = GetMoeWarPreparationMatch(id)
    return config.NumText or ""
end
---------MoeWarPreparationMatch end-----------
---------MoeWarPreparationQuestion begin---------
local GetMoeWarPreparationQuestion = function(id)
    local template = MoeWarPreparationQuestion[id]
    if not template then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetMoeWarPreparationQuestion", "MoeWarPreparationQuestion", TABLE_MOEWAR_PREPARATION_QUESHION, "Id", tostring(id))
        return
    end
    return template
end

function XMoeWarConfig.GetPreparationQuestionAnswers(id)
    local config = GetMoeWarPreparationQuestion(id)
    return config.Answers
end

function XMoeWarConfig.GetPreparationQuestionAnswer(id, index)
    local questionAnswers = XMoeWarConfig.GetPreparationQuestionAnswers(id)
    return questionAnswers and questionAnswers[index]
end

function XMoeWarConfig.GetPreparationQuestionPreChatId(id)
    local config = GetMoeWarPreparationQuestion(id)
    return config.PreChatId
end

function XMoeWarConfig.GetPreparationQuestionIdListByType(helperId, questionType)
    local questionIdList = {}
    for _, v in pairs(MoeWarPreparationQuestion) do
        if v.HelperId == helperId and v.Type == questionType then
            tableInsert(questionIdList, v.Id)
        end
    end

    local questionSortIdList = {}
    local questionIdDic = {}
    local preChatId
    local isStop = false
    while not isStop do
        isStop = true
        for i, id in ipairs(questionIdList) do
            preChatId = XMoeWarConfig.GetPreparationQuestionPreChatId(id)
            if preChatId == 0 or questionIdDic[preChatId] then
                tableInsert(questionSortIdList, id)
                questionIdDic[id] = true
                table.remove(questionIdList, i)
                isStop = false
                break
            end
        end
    end
    return questionSortIdList
end

function XMoeWarConfig.GetPreparationQuestionType(id)
    local config = GetMoeWarPreparationQuestion(id)
    return config.Type
end

function XMoeWarConfig.GetPreparationQuestion(id)
    local config = GetMoeWarPreparationQuestion(id)
    return config.Question
end

function XMoeWarConfig.GetPreparationQuestionRightReply(id)
    local config = GetMoeWarPreparationQuestion(id)
    return config.RightReply
end

function XMoeWarConfig.GetPreparationQuestionWrongReply(id)
    local config = GetMoeWarPreparationQuestion(id)
    return config.WrongReply
end

function XMoeWarConfig.GetPreparationQuestionChat(id)
    local config = GetMoeWarPreparationQuestion(id)
    return config.Chat or ""
end

function XMoeWarConfig.GetPreparationQuestionChatReply(id)
    local config = GetMoeWarPreparationQuestion(id)
    return config.ChatReply
end

function XMoeWarConfig.GetPreparationQuestionHelperIcon(id)
    local config = GetMoeWarPreparationQuestion(id)
    return config.HelperIcon
end

function XMoeWarConfig.GetPreparationQuestionId(helperId, questionType)
    for _, v in pairs(MoeWarPreparationQuestion) do
        if v.HelperId == helperId and questionType == v.Type then
            return v.Id
        end
    end
end

function XMoeWarConfig.GetPreparationQuestionBankIdCount(bankId)
    local count = 0
    for _, v in pairs(MoeWarPreparationQuestion) do
        if v.BankId == bankId then
            count = count + 1
        end
    end
    return count
end

function XMoeWarConfig.GetPreparationQuestionHelperName(id)
    local config = GetMoeWarPreparationQuestion(id)
    return config.HelperName
end
---------MoeWarPreparationQuestion end-----------
---------MoeWarPreparationStage begin---------
local GetMoeWarPreparationStage = function(id)
    local template = MoeWarPreparationStage[id]
    if not template then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetMoeWarPreparationStage", "MoeWarPreparationStage", TABLE_MOEWAR_PREPARATION_STAGE, "Id", tostring(id))
        return
    end
    return template
end

--筹备关卡界面的基本奖励
function XMoeWarConfig.GetPreparationStageShowBaseRewardId(id)
    local config = GetMoeWarPreparationStage(id)
    return config.ShowBaseRewardId
end

function XMoeWarConfig.GetPreparationStageLabelIds(id)
    local config = GetMoeWarPreparationStage(id)
    local labelIds = {}
    for i, labelId in ipairs(config.LabelIds or {}) do
        if labelId > 0 then
            tableInsert(labelIds, labelId)
        end
    end
    return labelIds
end

function XMoeWarConfig.GetPreparationStageExtraRewardCount(stageId, showExtraRewardIdsIndex)
    local showExtraRewardIds = XMoeWarConfig.GetPreparationStageShowExtraRewardIds(stageId)
    local rewardId = showExtraRewardIds[showExtraRewardIdsIndex]
    if not rewardId then
        return 0
    end

    local rewardList = XRewardManager.GetRewardList(rewardId)
    return rewardList[1].Count
end

function XMoeWarConfig.GetPreparationStageShowExtraRewardIds(stageId)
    local config = GetMoeWarPreparationStage(stageId)
    return config.ShowExtraRewardIds
end

function XMoeWarConfig.GetPreparationStageShowExtraRewardId(stageId, index)
    local config = GetMoeWarPreparationStage(stageId)
    local showExtraRewardIds = config.ShowExtraRewardIds
    return showExtraRewardIds[index]
end

function XMoeWarConfig.GetPreparationStageShowExtraRewardName(stageId, showExtraRewardIdsIndex)
    local showExtraRewardIds = XMoeWarConfig.GetPreparationStageShowExtraRewardIds(stageId)
    for index, showExtraRewardId in ipairs(showExtraRewardIds) do
        if index == showExtraRewardIdsIndex then
            local rewards = XRewardManager.GetRewardList(showExtraRewardId)
            local templateId = rewards[1] and rewards[1].TemplateId
            return (templateId and templateId > 0 and XGoodsCommonManager.GetGoodsName(templateId)) or ""
        end
    end
    return ""
end

--获得满足条件的数量
function XMoeWarConfig.GetPreparationFillConditionCount(stageId, helperId)
    local labelIds = XMoeWarConfig.GetPreparationStageLabelIds(stageId)
    local fillConditionCount = 0
    for _, stageLabelId in ipairs(labelIds) do
        if XMoeWarConfig.IsFillPreparationStageLabel(stageLabelId, helperId) then
            fillConditionCount = fillConditionCount + 1
        end
    end
    return fillConditionCount
end

--获得心情消耗
function XMoeWarConfig.GetStageCostMoodNum(stageId, helperId)
    local fillConditionCount = XMoeWarConfig.GetPreparationFillConditionCount(stageId, helperId)
    local config = GetMoeWarPreparationStage(stageId)
    if not config then
        return 0
    end

    local levelCostMoodNums = config.LabelCostMoodNums
    return levelCostMoodNums[fillConditionCount] or config.BaseCostMoodNum
end

--通讯次数奖励
function XMoeWarConfig.GetPreparationStageShowSpecialRewardId(id)
    local config = GetMoeWarPreparationStage(id)
    return config.ShowSpecialRewardId
end

--筹备界面每个关卡的奖励
function XMoeWarConfig.GetPreparationStageShowAllRewardId(id)
    local config = GetMoeWarPreparationStage(id)
    return config.ShowAllRewardId
end
---------MoeWarPreparationStage end-----------
---------MoeWarPreparationStageTagLabel begin---------
local GetPreparationStageTagLabel = function(id)
    local template = MoeWarPreparationStageTagLabel[id]
    if not template then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetMoeWarPreparationStageTagLabel", "MoeWarPreparationStageTagLabel", TABLE_MOEWAR_PREPARATION_STAGE_TAG_LABEL, "Id", tostring(id))
        return
    end
    return template
end

function XMoeWarConfig.GetPreparationStageTagLabelById(id)
    local config = GetPreparationStageTagLabel(id)
    return config.TagLabel
end
---------MoeWarPreparationStageTagLabel end-----------
---------MoeWarPreparationStageEvaluationLabel begin----------
local GetPreparationStageEvaluationLabel = function(id)
    local template = MoeWarPreparationStageEvaluationLabel[id]
    if not template then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetMoeWarPreparationStageEvaluationLabel", "MoeWarPreparationStageEvaluationLabel", TABLE_MOEWAR_PREPARATION_STAGE_EVALUATION_LABEL, "ReachNum", tostring(id))
        return
    end
    return template
end

function XMoeWarConfig.GetPreparationStageEvaluationEvaluatioLabel(reachNum)
    local config = GetPreparationStageEvaluationLabel(reachNum)
    return config.EvaluatioLabel
end
---------MoeWarPreparationStageEvaluationLabel end------------
---------------------场景动画相关 begin--------------------
local function GetAnimationGroupConfig(groupId)
    local config = MoeWarAnimationGroup[groupId]
    if not config then
        XLog.Error("XMoeWarConfig GetAnimationGroupConfig error:配置不存在, groupId: " .. groupId .. ", 配置路径: " .. TABLE_MOEWAR_ANIMATION_GROUP)
        return
    end
    return config
end

--返回PlayerLocal表中配置的AnimationGroupIds
function XMoeWarConfig.GetAllAnimationGroupIds()
    local animationGroupIds = {}
    for _, v in pairs(MoeWarPlayerCfg) do
        for _, winAnimGroupId in ipairs(v.WinAnimGroupId) do
            table.insert(animationGroupIds, winAnimGroupId)
        end
        for _, loseAnimGroupId in ipairs(v.LoseAnimGroupId) do
            table.insert(animationGroupIds, loseAnimGroupId)
        end
    end
    return animationGroupIds
end

function XMoeWarConfig.GetAnimationIds(groupId)
    local animationIds = {}

    local config = GetAnimationGroupConfig(groupId)
    for _, animationId in ipairs(config.AnimationId) do
        if XTool.IsNumberValid(animationId) then
            tableInsert(animationIds, animationId)
        end
    end

    return animationIds
end

function XMoeWarConfig.GetAnimationGroupInitModelName(groupId)
    local config = GetAnimationGroupConfig(groupId)
    return config.InitModelName
end

function XMoeWarConfig.GetAnimationGroupInitAnim(groupId)
    local config = GetAnimationGroupConfig(groupId)
    return config.InitAnim
end

local function GetAnimationConfig(animationId)
    local config = MoeWarAnimation[animationId]
    if not config then
        XLog.Error("XMoeWarConfig GetAnimationConfig error:配置不存在, animationId: " .. animationId .. ", 配置路径: " .. TABLE_MOEWAR_ANIMATION)
        return
    end
    return config
end

function XMoeWarConfig.GetAnimationModelName(animationId)
    local config = GetAnimationConfig(animationId)
    return config.ModelName
end

function XMoeWarConfig.GetAnimationAnimName(animationId)
    local config = GetAnimationConfig(animationId)
    return config.AnimName
end

function XMoeWarConfig.GetAnimationSpeed(animationId)
    local config = GetAnimationConfig(animationId)
    return config.Speed
end

function XMoeWarConfig.GetAnimationTotalDistance(groupId)
    local animationIds = XMoeWarConfig.GetAnimationIds(groupId)
    local totalDistance = 0
    for _, animationId in ipairs(animationIds) do
        totalDistance = totalDistance + XMoeWarConfig.GetAnimationDistance(animationId)
    end
    return totalDistance
end

function XMoeWarConfig.GetAnimationDistance(animationId)
    local config = GetAnimationConfig(animationId)
    return config.Distance
end

function XMoeWarConfig.GetAnimationRoleEffect(animationId)
    local config = GetAnimationConfig(animationId)
    return config.RoleEffect, config.RoleEffectRoot
end

--runwayIndex：场景上的跑道下标
function XMoeWarConfig.GetAnimationSceneEffect(animationId, runwayIndex)
    local config = GetAnimationConfig(animationId)
    local sceneEffectRoot = config.SceneEffectRoot
    return config.SceneEffect, not string.IsNilOrEmpty(sceneEffectRoot) and string.format(sceneEffectRoot, runwayIndex)
end

XMoeWarConfig.ReloadAnimationConfigs = function()
    MoeWarAnimation = XTableManager.ReadByIntKey(TABLE_MOEWAR_ANIMATION, XTable.XTableMoeWarAnimation, "Id")
    MoeWarAnimationGroup = XTableManager.ReadByIntKey(TABLE_MOEWAR_ANIMATION_GROUP, XTable.XTableMoeWarAnimationGroup, "Id")
end
---------------------场景动画相关 end--------------------


--region   ------------------跑酷小游戏相关 start-------------------

local GetParkourActivity = function(id)
    local cfg = MoeWarParkourActivity[id]
    if not cfg then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetParkourActivity", "MoeWarParkourActivity", TABLE_MOEWAR_PARKOUR_ACTIVITY, "Id", id)
        return
    end
    return cfg
end

function XMoeWarConfig.GetParkourActivityId(useDefault)
    local timeOfNow = XTime.GetServerNowTimestamp()
    local activityId = 0
    local lastOverEndTime = 0
    for id, cfg in pairs(MoeWarParkourActivity) do
        if XFunctionManager.CheckInTimeByTimeId(cfg.TimeId) then
            return id
        end

        if useDefault then
            local timeOfEnd = XFunctionManager.GetEndTimeByTimeId(cfg.TimeId)
            if timeOfNow >= timeOfEnd and timeOfEnd > lastOverEndTime then
                activityId = cfg.Id
                lastOverEndTime = timeOfEnd
            end
        end
    end
    return activityId
end

local GetParkourTimeId = function (id)
    local cfg = GetParkourActivity(id)
    return cfg.TimeId
end

function XMoeWarConfig.GetParkourStageList(id)
    local cfg = GetParkourActivity(id)
    return cfg.StageId
end

function XMoeWarConfig.GetParkourRewardId(id)
    local cfg = GetParkourActivity(id)
    return cfg.RewardId
end

function XMoeWarConfig.GetParkourTeachStageId(id)
    local cfg = GetParkourActivity(id)
    return cfg.TeachStageId
end 

function XMoeWarConfig.GetParkourStartTime(id)
    local timeId = GetParkourTimeId(id)
    return XFunctionManager.GetStartTimeByTimeId(timeId)
end

function XMoeWarConfig.GetParkourEndTime(id)
    local timeId = GetParkourTimeId(id)
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XMoeWarConfig.GetParkourStageTemplate(stageId)
    local template = MoeWarParkourStage[stageId]
    if not template then
        XLog.ErrorTableDataNotFound("XMoeWarConfig.GetParkourStageTemplate", "MoeWarParkourStage", TABLE_MOEWAR_PARKOUR_STAGE, "StageId", stageId)
        return
    end
    return template
end

function XMoeWarConfig.GetParkourDailyMaxReward(id)
    local cfg = GetParkourActivity(id)
    return cfg.DailyMaxReward
end

--endregion------------------跑酷小游戏相关 finish------------------

--region   ------------------铭牌商城相关 start-------------------

function XMoeWarConfig.GetMoeWarNameplateList()
    return MoeWarNameplateConfig
end

function XMoeWarConfig.GetMoeWarNameplateCostItemId(nameplateId)
    local cfg = MoeWarNameplateStore[nameplateId]
    return cfg and cfg.CostItemId or 0
end

function XMoeWarConfig.GetMoeWarNameplateCostItemCount(nameplateId)
    local cfg = MoeWarNameplateStore[nameplateId]
    return cfg and cfg.CostItemCount or 0
end

function XMoeWarConfig.GetPreNameplateId(nameplateId)
    local cfg = MoeWarNameplateStore[nameplateId]
    return cfg and cfg.PreNameplateId or 0
end

function XMoeWarConfig.GetNameplateItemName(nameplateId)
    local cfg = MoeWarNameplateStore[nameplateId]
    return cfg and cfg.ItemName or ""
end

--endregion------------------铭牌商城相关 finish------------------


---------------------心情显示相关 begin------------------
local GetCharacterMoodConfig = function(id)
    local config = MoeWarCharacterMood[id]
    if not config then
        XLog.Error("XMoeWarConfig GetAnimationConfig error:配置不存在, id: " .. id .. ", 配置路径: " .. TABLE_MOEWAR_CHARACTER_MOOD)
        return
    end
    return config
end

local IsInitCharacterMood = false
local CharacterMoodIdList = {}
local InitCharacterMood = function()
    if IsInitCharacterMood then
        return
    end

    for id in pairs(MoeWarCharacterMood) do
        tableInsert(CharacterMoodIdList, id)
    end
    tableSort(CharacterMoodIdList, function(idA, idB)
        local valueA = XMoeWarConfig.GetCharacterMoodMinValue(idA)
        local valueB = XMoeWarConfig.GetCharacterMoodMinValue(idB)
        return valueA > valueB
    end)

    IsInitCharacterMood = true
end

function XMoeWarConfig.GetCharacterMoodId(moodValue)
    InitCharacterMood()
    if moodValue then
        local minValue
        for _, id in ipairs(CharacterMoodIdList) do
            minValue = XMoeWarConfig.GetCharacterMoodMinValue(id)
            if moodValue > minValue then
                return id
            end
        end
    end
    return CharacterMoodIdList[#CharacterMoodIdList]
end

function XMoeWarConfig.GetCharacterMoodMinValue(id)
    local config = GetCharacterMoodConfig(id)
    return config.MoodMinValue
end

function XMoeWarConfig.GetCharacterMoodColor(id)
    local config = GetCharacterMoodConfig(id)
    return XUiHelper.Hexcolor2Color(config.Color)
end

function XMoeWarConfig.GetCharacterMoodIcon(id)
    local config = GetCharacterMoodConfig(id)
    return config.Icon
end
---------------------心情显示相关 end--------------------
---------------------赠礼回复相关 begin------------------
local GetThankConfig = function(id)
    local config = MoeWarThank[id]
    if not config then
        XLog.Error("XMoeWarConfig GetThankConfig error:配置不存在, id: " .. id .. ", 配置路径: " .. TABLE_MOEWAR_THANK)
        return
    end
    return config
end

function XMoeWarConfig.GetThankText(id)
    local config = GetThankConfig(id)
    return config.Text
end
---------------------赠礼回复相关 end--------------------