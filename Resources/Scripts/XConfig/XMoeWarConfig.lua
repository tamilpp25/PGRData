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


XMoeWarConfig.KEY_GROUP_TAB_INDEX = "MOE_WAR_GROUP_TAB_INDEX_KEY"
XMoeWarConfig.SKIP_KEY_PREFIX = "MOE_WAR_SKIP"
XMoeWarConfig.DEFAULT_SELECT_KEY_PREFIX ="MOE_WAR_DEFAULT_SELECT"
XMoeWarConfig.MOE_WAR_VOTE_ANIMATION_RECORD = "MOE_WAR_VOTE_ANIMATION_RECORD"
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
    Game24In12 = 1,
    Game12In6 = 2,
    Game6In3 = 3,
    Game3In1 = 4,
}

XMoeWarConfig.SessionName = {
    "Game24In12",
    "Game12In6",
    "Game6In3",
    "Game3In1",
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
    Line = 5
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
    for _, v in ipairs(MoeWarPlayers) do
        if not MoeWarGroups[v.Group] then
            MoeWarGroups[v.Group] = {}
        end
        tableInsert(MoeWarGroups[v.Group], v)
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

function XMoeWarConfig.GetAnimationDistance(animationId)
    local config = GetAnimationConfig(animationId)
    return config.Distance
end

function XMoeWarConfig.GetAnimationRoleEffect(animationId)
    local config = GetAnimationConfig(animationId)
    return config.RoleEffect, config.RoleEffectRoot
end

function XMoeWarConfig.GetAnimationSceneEffect(animationId)
    local config = GetAnimationConfig(animationId)
    return config.SceneEffect, config.SceneEffectRoot
end

XMoeWarConfig.ReloadAnimationConfigs = function()
    MoeWarAnimation = XTableManager.ReadByIntKey(TABLE_MOEWAR_ANIMATION, XTable.XTableMoeWarAnimation, "Id")
    MoeWarAnimationGroup = XTableManager.ReadByIntKey(TABLE_MOEWAR_ANIMATION_GROUP, XTable.XTableMoeWarAnimationGroup, "Id")
end
---------------------场景动画相关 end--------------------
