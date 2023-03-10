local tonumber = tonumber
local tableInsert = table.insert
local tableSort = table.sort
local mathCeil = math.ceil
local ipairs = ipairs
local pairs = pairs
local stringSplit = string.Split
local CSXTextManagerGetText = CS.XTextManager.GetText
local IsNumberValid = XTool.IsNumberValid

local TABLE_ACTIVITY_PATH = "Share/Fuben/Stronghold/StrongholdActivity.tab"
local TABLE_COMMON_CONFIG_PATH = "Share/Fuben/Stronghold/StrongholdCfg.tab"
local TABLE_ENDURANCE_PATH = "Share/Fuben/Stronghold/StrongholdEndurance.tab"
local TABLE_CHPATER_PATH = "Share/Fuben/Stronghold/StrongholdChapter.tab"
local TABLE_GROUP_PATH = "Share/Fuben/Stronghold/StrongholdGroup.tab"
local TABLE_REWARD_PATH = "Share/Fuben/Stronghold/StrongholdReward.tab"
local TABLE_PLUGIN_PATH = "Share/Fuben/Stronghold/StrongholdPlugin.tab"
local TABLE_ELECTRICTEAM_PATH = "Share/Fuben/Stronghold/StrongholdTeamElectric.tab"
local TABLE_ELECTRIC_PATH = "Share/Fuben/Stronghold/StrongholdElectric.tab"
local TABLE_BUFF_PATH = "Share/Fuben/Stronghold/StrongholdBuff.tab"
local TABLE_SUPPORT_PATH = "Share/Fuben/Stronghold/StrongholdSupport.tab"
local TABLE_ROBOT_GROUP_PATH = "Share/Fuben/Stronghold/StrongholdRobotGroup.tab"
local TABLE_BOWRROW_PATH = "Share/Fuben/Stronghold/StrongholdBorrowCost.tab"
local TABLE_STRONGHOLD_GROUP_ELEMENT_PATH = "Client/Fuben/Stronghold/StrongholdGroupElement.tab"
local TABLE_LEVEL_PATH = "Share/Fuben/Stronghold/StrongholdLevel.tab"
local TABLE_RUNE_PATH = "Share/Fuben/Stronghold/StrongholdRune.tab"
local TABLE_SUB_RUNE_PATH = "Share/Fuben/Stronghold/StrongholdSubRune.tab"

local ActivityTemplate = {}
local CommonConfig = {}
local EnduranceConfig = {}
local ChapterConfig = {}
local GroupConfig = {}
local RewardConfig = {}
local LevelIdToRewardIdsDic = {}
local PluginConfig = {}
local TeamAbilityExtraElectricList = {}
local ElectricConfig = {}
local BuffConfig = {}
local SupportConfig = {}
local RobotGroupConfig = {}
local BorrowCostConfig = {}
local StrongholdGroupElementConfig = {}
local StrongholdLevelConfig = {}
local StrongholdRuneConfig = {}
local StrongholdSubRuneConfig = {}

local DefaultActivityId = 1
local ActivityIdList = {} --??????Id????????????????????????

XStrongholdConfigs = XStrongholdConfigs or {}

local InitActivityConfig = function()
    ActivityTemplate = XTableManager.ReadByIntKey(TABLE_ACTIVITY_PATH, XTable.XTableStrongholdActivity, "Id")

    for activityId, config in pairs(ActivityTemplate) do
        tableInsert(ActivityIdList, activityId)
    end

    tableSort(ActivityIdList, function(aId, bId)
        return aId > bId --????????????
    end)

    DefaultActivityId = ActivityIdList[1]
end

local InitElectricTeamConfig = function()
    local templates = XTableManager.ReadByStringKey(TABLE_ELECTRICTEAM_PATH, XTable.XTableStrongholdTeamElectric, "Id")

    for _, template in pairs(templates) do
        local config = {
            Ability = template.Id,
            Electric = template.ElectricEnerge,
        }
        tableInsert(TeamAbilityExtraElectricList, config)
    end

    tableSort(TeamAbilityExtraElectricList, function(a, b)
        return a.Ability < b.Ability
    end)
end

local InitRewardConfig = function()
    RewardConfig = XTableManager.ReadByIntKey(TABLE_REWARD_PATH, XTable.XTableStrongholdReward, "Id")

    local levelId
    for id, config in pairs(RewardConfig) do
        levelId = config.LevelId

        local rewardIds = LevelIdToRewardIdsDic[levelId]
        if not rewardIds then
            rewardIds = {}
            LevelIdToRewardIdsDic[levelId] = rewardIds
        end

        tableInsert(rewardIds, id)
    end
end

function XStrongholdConfigs.Init()
    CommonConfig = XTableManager.ReadByStringKey(TABLE_COMMON_CONFIG_PATH, XTable.XTableStrongholdCfg, "Key")
    EnduranceConfig = XTableManager.ReadByIntKey(TABLE_ENDURANCE_PATH, XTable.XTableStrongholdEndurance, "Id")
    ChapterConfig = XTableManager.ReadByIntKey(TABLE_CHPATER_PATH, XTable.XTableStrongholdChapter, "Id")
    GroupConfig = XTableManager.ReadByIntKey(TABLE_GROUP_PATH, XTable.XTableStrongholdGroup, "Id")
    PluginConfig = XTableManager.ReadByIntKey(TABLE_PLUGIN_PATH, XTable.XTableStrongholdPlugin, "Id")
    ElectricConfig = XTableManager.ReadByIntKey(TABLE_ELECTRIC_PATH, XTable.XTableStrongholdElectric, "Id")
    BuffConfig = XTableManager.ReadByIntKey(TABLE_BUFF_PATH, XTable.XTableStrongholdBuff, "Id")
    SupportConfig = XTableManager.ReadByIntKey(TABLE_SUPPORT_PATH, XTable.XTableStrongholdSupport, "Id")
    RobotGroupConfig = XTableManager.ReadByIntKey(TABLE_ROBOT_GROUP_PATH, XTable.XTableStrongholdRobotGroup, "Id")
    BorrowCostConfig = XTableManager.ReadByIntKey(TABLE_BOWRROW_PATH, XTable.XTableStrongholdBorrowCost, "Id")
    StrongholdGroupElementConfig = XTableManager.ReadByIntKey(TABLE_STRONGHOLD_GROUP_ELEMENT_PATH, XTable.XTableStrongholdGroupElement, "StageIdGroupIndex")
    StrongholdLevelConfig = XTableManager.ReadByIntKey(TABLE_LEVEL_PATH, XTable.XTableStrongholdLevel, "Id")
    StrongholdRuneConfig = XTableManager.ReadByIntKey(TABLE_RUNE_PATH, XTable.XTableStrongholdRune, "Id")
    StrongholdSubRuneConfig = XTableManager.ReadByIntKey(TABLE_SUB_RUNE_PATH, XTable.XTableStrongholdSubRune, "Id")

    InitActivityConfig()
    InitElectricTeamConfig()
    InitRewardConfig()
end

-----------------?????????????????? begin--------------------
--????????????????????????example:{1, 10} ???????????????????????????10???????????????id???10????????????????????????id???1?????????
local function GetActivityConfig(activityId)
    activityId = IsNumberValid(activityId) and activityId or DefaultActivityId

    local circleId = 0
    for _, configId in ipairs(ActivityIdList) do
        if configId <= activityId then
            circleId = configId
            break
        end
    end

    local config = ActivityTemplate[circleId]
    if not config then
        XLog.Error("XStrongholdConfigs GetActivityConfig error:???????????????, activityId: " .. activityId .. ", ????????????: " .. TABLE_ACTIVITY_PATH)
        return
    end

    return config
end

function XStrongholdConfigs.GetActivityFightAutoBeginSeconds(activityId)
    local config = GetActivityConfig(activityId)
    return config.AutoBeginSeconds
end

function XStrongholdConfigs.GetActivityFightContinueSeconds(activityId)
    local config = GetActivityConfig(activityId)
    return config.FightContinueSeconds
end

function XStrongholdConfigs.GetActivityFightTotalDay(activityId)
    local seconds = XStrongholdConfigs.GetActivityFightContinueSeconds(activityId)
    return mathCeil(seconds / 86400)
end

function XStrongholdConfigs.GetActivityOneCycleSeconds(activityId)
    local config = GetActivityConfig(activityId)
    return config.OneCycleSeconds
end

function XStrongholdConfigs.GetActivityDefaultOpenTime()
    local config = GetActivityConfig(DefaultActivityId)
    local timeId = config.OpenTimeId
    if not IsNumberValid(timeId) then return 0 end
    return XFunctionManager.GetStartTimeByTimeId(timeId)
end

function XStrongholdConfigs.GetActivityDefaultEndTime()
    local openTime = XStrongholdConfigs.GetActivityDefaultOpenTime()
    return openTime + XStrongholdConfigs.GetActivityOneCycleSeconds(DefaultActivityId)
end
-----------------?????????????????? end--------------------
-----------------???????????? begin--------------------
local function GetEnduranceConfig(day)
    local config = EnduranceConfig[day]
    if not config then
        XLog.Error("XStrongholdConfigs GetEnduranceConfig error:???????????????, day: " .. day .. ", ????????????: " .. TABLE_ENDURANCE_PATH)
        return
    end
    return config
end

function XStrongholdConfigs.GetMaxEndurance(curDay, levelId)
    if not IsNumberValid(curDay) then
        return 0
    end

    local maxEndurance = 0
    local enduracnce, config
    for day = 1, curDay do
        config = GetEnduranceConfig(day)
        enduracnce = config.Endurance[levelId] or 0
        maxEndurance = maxEndurance + enduracnce
    end
    return maxEndurance
end
-----------------???????????? end--------------------
-----------------???????????? begin--------------------
local function GetChapterConfig(chapterId)
    local config = ChapterConfig[chapterId]
    if not config then
        XLog.Error("XStrongholdConfigs GetChapterConfig error:???????????????, chapterId: " .. chapterId .. ", ????????????: " .. TABLE_CHPATER_PATH)
        return
    end
    return config
end

local function GetGroupConfig(groupId)
    local config = GroupConfig[groupId]
    if not config then
        XLog.Error("XStrongholdConfigs GetGroupConfig error:???????????????, groupId: " .. groupId .. ", ????????????: " .. TABLE_GROUP_PATH)
        return
    end
    return config
end

function XStrongholdConfigs.GetNextChapterId(chapterId)
    local nextChapterId = chapterId + 1
    local chapterIds = XStrongholdConfigs.GetAllChapterIds()
    local chapterCount = #chapterIds
    if nextChapterId > chapterCount then return end
    return nextChapterId
end

function XStrongholdConfigs.GetGroupIds(chapterId)
    local groupIds = {}

    local config = GetChapterConfig(chapterId)
    for _, groupId in ipairs(config.GroupId) do
        if IsNumberValid(groupId) then
            tableInsert(groupIds, groupId)
        end
    end

    return groupIds
end

function XStrongholdConfigs.GetAllGroupIds()
    local groupIds = {}

    local chapterIds = XStrongholdConfigs.GetAllChapterIds()
    for _, chapterId in pairs(chapterIds) do
        local config = GetChapterConfig(chapterId)
        for _, groupId in ipairs(config.GroupId) do
            if IsNumberValid(groupId) then
                tableInsert(groupIds, groupId)
            end
        end
    end

    return groupIds
end

function XStrongholdConfigs.GetChapterName(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.Name or ""
end

function XStrongholdConfigs.GetChapterBg(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.Bg or ""
end

function XStrongholdConfigs.GetChapterPrefabPath(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.Prefab or ""
end

function XStrongholdConfigs.GetChapterFirstGroupId(chapterId)
    local config = GetChapterConfig(chapterId)
    return config.GroupId and config.GroupId[1] or 0
end

--???????????????????????????
function XStrongholdConfigs.IsChapterLastGroupId(groupId)
    local chapterIds = XStrongholdConfigs.GetAllChapterIds()
    for _, chapterId in pairs(chapterIds) do
        local groupIds = XStrongholdConfigs.GetGroupIds(chapterId)
        if groupId == groupIds[#groupIds] then
            return true
        end
    end
    return false
end

function XStrongholdConfigs.GetChapterLastGroupId(chapterId)
    local groupIds = XStrongholdConfigs.GetGroupIds(chapterId)
    return groupIds[#groupIds]
end

--????????????Id
function XStrongholdConfigs.GetChapterIdByGroupId(groupId)
    if not IsNumberValid(groupId) then return end
    local chapterIds = XStrongholdConfigs.GetAllChapterIds()
    for _, chapterId in pairs(chapterIds) do
        local groupIds = XStrongholdConfigs.GetGroupIds(chapterId)
        for _, inGroupId in pairs(groupIds) do
            if inGroupId == groupId then
                return chapterId
            end
        end
    end
    XLog.Error("XStrongholdConfigs.GetChapterIdByGroupId error: ???????????????Id??????????????????, groupId: " .. groupId .. ", ???????????????" .. TABLE_CHPATER_PATH)
end

function XStrongholdConfigs.GetGroupPreGroupId(groupId)
    local config = GetGroupConfig(groupId)
    return config.PreId or 0
end

function XStrongholdConfigs.GetGroupOrder(groupId)
    local config = GetGroupConfig(groupId)
    return config.Order or ""
end

function XStrongholdConfigs.GetGroupName(groupId)
    local config = GetGroupConfig(groupId)
    return config.Name or ""
end

function XStrongholdConfigs.GetGroupPrefabPath(groupId)
    local config = GetGroupConfig(groupId)
    return config.Prefab or ""
end

function XStrongholdConfigs.GetGroupIconBg(groupId)
    local config = GetGroupConfig(groupId)
    return config.IconBg
end

function XStrongholdConfigs.GetGroupIconBoss(groupId)
    local config = GetGroupConfig(groupId)
    return config.IconBoss
end

--??????????????????BUFF(????????????)
function XStrongholdConfigs.GetGroupBaseBuffIds(groupId, activityId)
    local buffIds = {}

    local activityBuffNum
    local activityBuffIndex
    local activityBuffIds = {}

    local config = GetGroupConfig(groupId)
    for _, buffIdStr in pairs(config.BaseBuffId) do

        activityBuffIds = stringSplit(buffIdStr, "|")
        activityBuffNum = activityBuffNum or #activityBuffIds
        activityBuffIndex = activityBuffIndex or (activityId % activityBuffNum)
        activityBuffIndex = activityBuffIndex == 0 and activityBuffNum or activityBuffIndex

        local buffId = tonumber(activityBuffIds[activityBuffIndex])
        if buffId > 0 then
            tableInsert(buffIds, buffId)
        end

    end

    return buffIds
end

--??????????????????BUFF(?????????????????????????????????????????????)
function XStrongholdConfigs.GetGroupBossBuffIds(groupId, activityId)
    local buffIds = {}

    local activityBuffNum
    local activityBuffIndex
    local activityBuffIds = {}

    local config = GetGroupConfig(groupId)
    for _, buffIdStr in pairs(config.StageBuffId) do

        activityBuffIds = stringSplit(buffIdStr, "|")
        activityBuffNum = activityBuffNum or #activityBuffIds
        activityBuffIndex = activityBuffIndex or (activityId % activityBuffNum)
        activityBuffIndex = activityBuffIndex == 0 and activityBuffNum or activityBuffIndex

        local buffId = tonumber(activityBuffIds[activityBuffIndex])
        if buffId > 0 then
            tableInsert(buffIds, buffId)
        end

    end

    return buffIds
end

function XStrongholdConfigs.CheckHasGroupBossBuffId(groupId, activityId)
    local buffIds = XStrongholdConfigs.GetGroupBossBuffIds(groupId, activityId)
    for _, buffId in pairs(buffIds) do
        if buffId > 0 then
            return true
        end
    end
    return false
end

--?????????????????????????????????????????????Id
function XStrongholdConfigs.GetGroupFinishRelatedId(groupId)
    local groupIds = {}

    local config = GetGroupConfig(groupId)
    for _, groupId in pairs(config.FinishRelatedId) do
        if groupId > 0 then
            tableInsert(groupIds, groupId)
        end
    end

    return groupIds
end

function XStrongholdConfigs.GetGroupCostEndurance(groupId)
    local config = GetGroupConfig(groupId)
    return config.Endurance
end

function XStrongholdConfigs.GetGroupRewardId(groupId, activityId)
    local config = GetGroupConfig(groupId)
    return config.RewardId[activityId]
end

function XStrongholdConfigs.GetGroupDetailBg(groupId)
    local config = GetGroupConfig(groupId)
    return config.DetailBg
end

function XStrongholdConfigs.GetGroupDetailDesc(groupId)
    local config = GetGroupConfig(groupId)
    return config.DetailDesc
end

function XStrongholdConfigs.GetGroupRequireTeamMemberNum(groupId, teamId)
    local requireTeamMemberNum = XStrongholdConfigs.GetMaxTeamMemberNum()
    if groupId then
        local config = GetGroupConfig(groupId)
        requireTeamMemberNum = config.TeamMember[teamId] or 0
    end
    return requireTeamMemberNum
end

--?????????????????????????????????????????????
function XStrongholdConfigs.GetGroupCanUseRobotIds(groupId, characterType, levelId)
    local config = GetGroupConfig(groupId)
    local roubotGroupId = config.RobotGroup[levelId]
    return XStrongholdConfigs.GetRobotGroupRobotIds(roubotGroupId, characterType)--???????????????????????????????????????
end

function XStrongholdConfigs.GetGroupStageIdGroupIndex(groupId, stageId)
    local config = GetGroupConfig(groupId)
    local stageIdGroupList = config.StageIdGroup
    local stageIds
    for index, stageIdGroup in ipairs(stageIdGroupList) do
        stageIds = string.Split(stageIdGroup)
        for _, stageIdStr in pairs(stageIds) do
            if stageId == tonumber(stageIdStr) then
                return index
            end
        end
    end
end
-----------------???????????? end--------------------
-----------------???????????? begin--------------------
local function GetBuffConfig(buffId)
    local config = BuffConfig[buffId]
    if not config then
        XLog.Error("XStrongholdConfigs GetBuffConfig error:???????????????, buffId: " .. buffId .. ", ????????????: " .. TABLE_BUFF_PATH)
        return
    end
    return config
end

function XStrongholdConfigs.GetBuffIcon(buffId)
    local config = GetBuffConfig(buffId)
    return config.Icon
end

function XStrongholdConfigs.GetBuffName(buffId)
    local config = GetBuffConfig(buffId)
    return config.Name
end

function XStrongholdConfigs.GetBuffDesc(buffId)
    local config = GetBuffConfig(buffId)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

function XStrongholdConfigs.GetBuffConditionId(buffId)
    local config = GetBuffConfig(buffId)
    return config.Condition[1]
end

function XStrongholdConfigs.CheckBuffHasCondition(buffId)
    local conditionId = XStrongholdConfigs.GetBuffConditionId(buffId)
    return conditionId and conditionId > 0
end
-----------------???????????? end--------------------
-----------------???????????? begin--------------------
local function GetSupportConfig(supportId)
    local config = SupportConfig[supportId]
    if not config then
        XLog.Error("XStrongholdConfigs GetSupportConfig error:???????????????, supportId: " .. supportId .. ", ????????????: " .. TABLE_SUPPORT_PATH)
        return
    end
    return config
end

function XStrongholdConfigs.GetSupportConditionIds(supportId)
    local conditionIds = {}
    local config = GetSupportConfig(supportId)
    for _, conditionId in pairs(config.Condition) do
        if conditionId > 0 then
            tableInsert(conditionIds, conditionId)
        end
    end
    return conditionIds
end

function XStrongholdConfigs.GetSupportRequireAbility(supportId)
    local config = GetSupportConfig(supportId)
    return config.RequireAbility
end

function XStrongholdConfigs.GetSupportBuffIds(supportId)
    local buffIds = {}
    local config = GetSupportConfig(supportId)
    for _, buffId in pairs(config.BuffId) do
        if buffId > 0 then
            tableInsert(buffIds, buffId)
        end
    end
    return buffIds
end
-----------------???????????? end--------------------
-----------------???????????????????????? begin--------------------
local function GetRewardConfig(rewardId)
    local config = RewardConfig[rewardId]
    if not config then
        XLog.Error("XStrongholdConfigs GetRewardConfig error:???????????????, rewardId: " .. rewardId .. ", ????????????: " .. TABLE_REWARD_PATH)
        return
    end
    return config
end

local function CheckRewardOffline(rewardId)
    local config = GetRewardConfig(rewardId)
    return IsNumberValid(config.Offline)
end

function XStrongholdConfigs.GetAllRewardIds(levelId)
    local ids = {}
    local rewardIds = LevelIdToRewardIdsDic[levelId] or {}
    for _, id in pairs(rewardIds) do
        if not CheckRewardOffline(id) then
            tableInsert(ids, id)
        end
    end
    return ids
end

function XStrongholdConfigs.GetRewardDesc(rewardId)
    local config = GetRewardConfig(rewardId)
    return config.Desc or ""
end

function XStrongholdConfigs.GetRewardSkipId(rewardId)
    local config = GetRewardConfig(rewardId)
    return config.SkipId
end

function XStrongholdConfigs.GetRewardConditionId(rewardId)
    local config = GetRewardConfig(rewardId)
    return config.Condition
end

function XStrongholdConfigs.GetRewardGoodsId(rewardId)
    local config = GetRewardConfig(rewardId)
    return config.RewardId
end
-----------------???????????????????????? end--------------------
-----------------???????????? begin--------------------
local MAX_TEAM_NUM = 5--??????????????????
function XStrongholdConfigs.GetMaxTeamNum()
    return MAX_TEAM_NUM
end

local MAX_TEAM_MEMBER_NUM = 3--????????????????????????
function XStrongholdConfigs.GetMaxTeamMemberNum()
    return MAX_TEAM_MEMBER_NUM
end

local function GetRobotGroupConfig(roubotGroupId)
    local config = RobotGroupConfig[roubotGroupId]
    if not config then
        XLog.Error("XStrongholdConfigs GetRobotGroupConfig error:???????????????, roubotGroupId: " .. roubotGroupId .. ", ????????????: " .. TABLE_ROBOT_GROUP_PATH)
        return
    end
    return config
end

function XStrongholdConfigs.GetRobotGroupRobotIds(roubotGroupId, characterType)
    local robotIds = {}
    local config = GetRobotGroupConfig(roubotGroupId)

    local num, index
    local robotIds = {}
    for _, robotId in pairs(config.RobotId) do
        if IsNumberValid(characterType) then
            local robotType = XRobotManager.GetRobotCharacterType(robotId)
            if robotType == characterType then
                tableInsert(robotIds, robotId)
            end
        else
            tableInsert(robotIds, robotId)
        end
    end
    return robotIds
end


local function GetBorrowCostConfig(times)
    local config = BorrowCostConfig[times]
    if not config then
        XLog.Error("XStrongholdConfigs GetBorrowCostConfig error:???????????????, times: " .. times .. ", ????????????: " .. TABLE_BOWRROW_PATH)
        return
    end
    return config
end

function XStrongholdConfigs.GetBorrowCostItemInfo(times)
    times = times + 1

    local maxTimes = XStrongholdConfigs.GetBorrowMaxTimes()
    times = times > maxTimes and maxTimes or times

    local config = GetBorrowCostConfig(times)
    return config.ItemId, config.ItemCount
end

function XStrongholdConfigs.GetBorrowMaxTimes()
    return #BorrowCostConfig
end
-----------------???????????? end--------------------
-----------------???????????? begin--------------------
local function GetPluginConfig(pluginId)
    local config = PluginConfig[pluginId]
    if not config then
        XLog.Error("XStrongholdConfigs GetPluginConfig error:???????????????, pluginId: " .. pluginId .. ", ????????????: " .. TABLE_PLUGIN_PATH)
        return
    end
    return config
end

function XStrongholdConfigs.GetPluginIds()
    local pluginIds = {}
    for pluginId in ipairs(PluginConfig) do
        tableInsert(pluginIds, pluginId)
    end
    return pluginIds
end

function XStrongholdConfigs.GetPluginUseElectric(pluginId)
    local config = GetPluginConfig(pluginId)
    return config.UseElectric
end

function XStrongholdConfigs.GetPluginAddAbility(pluginId)
    local config = GetPluginConfig(pluginId)
    return config.FightAbility
end

function XStrongholdConfigs.GetPluginIcon(pluginId)
    local config = GetPluginConfig(pluginId)
    return config.Icon
end

function XStrongholdConfigs.GetPluginName(pluginId)
    local config = GetPluginConfig(pluginId)
    return config.Name
end

function XStrongholdConfigs.GetPluginDesc(pluginId)
    local config = GetPluginConfig(pluginId)
    return config.Desc
end

function XStrongholdConfigs.GetPluginCountLimit(pluginId)
    local config = GetPluginConfig(pluginId)
    return IsNumberValid(config.CountLimit) and config.CountLimit or XMath.IntMax()
end
-----------------???????????? end--------------------
-----------------???????????? begin--------------------
local function GetElectricConfig(day)
    local config = ElectricConfig[day]
    if not config then
        return
    end
    return config
end

function XStrongholdConfigs.GetElectricAdd(day, levelId)
    local config = GetElectricConfig(day)
    return config and config.ElectricEnerge and config.ElectricEnerge[levelId] or 0
end

function XStrongholdConfigs.GetTeamAbilityExtraElectricList()
    return XTool.Clone(TeamAbilityExtraElectricList)
end

function XStrongholdConfigs.GetTeamAbilityToExtraElectric(totalAbility)
    local extraElectric = 0
    for _, config in ipairs(TeamAbilityExtraElectricList) do
        if totalAbility > config.Ability then
            extraElectric = config.Electric
        end
    end
    return extraElectric
end

local ElectricIcon = CS.XGame.ClientConfig:GetString("StrongholdElectricIcon")
function XStrongholdConfigs.GetElectricIcon()
    return ElectricIcon
end

function XStrongholdConfigs.GetElectricIdList()
    local electricIdList = {}
    for id in pairs(ElectricConfig) do
        tableInsert(electricIdList, id)
    end
    return electricIdList
end
-----------------???????????? end--------------------
-----------------???????????? begin--------------------
function XStrongholdConfigs.GetCommonConfig(key)
    local config = CommonConfig[key]
    if not config then
        XLog.Error("XStrongholdConfigs.GetCommonConfig error:???????????????, key: " .. key .. ", ????????????: " .. TABLE_COMMON_CONFIG_PATH)
        return
    end
    return config.Value or 0
end

--????????????
function XStrongholdConfigs.GetActivityName()
    return CSXTextManagerGetText("StrongholdActivityName")
end
-----------------???????????? end--------------------
-----------------?????????????????????????????? begin--------------------
local function GetStrongholdGroupElement(stageIdGroupIndex)
    local template = StrongholdGroupElementConfig[stageIdGroupIndex]
    if not template then
        XLog.ErrorTableDataNotFound("XStrongholdConfigs.GetStrongholdGroupElement", "StrongholdGroupElement", TABLE_STRONGHOLD_GROUP_ELEMENT_PATH, "StageIdGroupIndex", tostring(stageIdGroupIndex))
        return
    end
    return template
end

function XStrongholdConfigs.GetStrongholdGroupElementGridTitleBg(stageIdGroupIndex)
    local config = GetStrongholdGroupElement(stageIdGroupIndex)
    return config.GridTitleBg
end
-----------------?????????????????????????????? end----------------------
-----------------???????????? begin--------------------
XStrongholdConfigs.LevelType = {
    Choosable = 0, --?????????
    Normal = 1, --?????????
    Medium = 2, --?????????
    High = 3, --?????????
}

local function GetLevelConfig(levelId)
    local config = StrongholdLevelConfig[levelId]
    if not config then
        XLog.Error("XStrongholdConfigs GetLevelConfig error:???????????????, levelId: " .. levelId .. ", ????????????: " .. TABLE_LEVEL_PATH)
        return
    end
    return config
end

function XStrongholdConfigs.GetLevelName(levelId)
    local config = GetLevelConfig(levelId)
    return config.Name
end

function XStrongholdConfigs.GetLevelLimit(levelId)
    local config = GetLevelConfig(levelId)
    return config.MinLevel, config.MaxLevel
end

function XStrongholdConfigs.GetLevelIcon(levelId)
    local config = GetLevelConfig(levelId)
    return config.Icon
end

function XStrongholdConfigs.GetLevelInitElectricEnergy(levelId)
    local config = GetLevelConfig(levelId)
    return config.InitElectricEnergy
end

function XStrongholdConfigs.GetLevelInitEndurance(levelId)
    local config = GetLevelConfig(levelId)
    return config.InitEndurance
end

function XStrongholdConfigs.GetAllChapterIds()
    local ids = {}

    local levelId = XDataCenter.StrongholdManager.GetLevelId()
    if not IsNumberValid(levelId) then return ids end

    local config = GetLevelConfig(levelId)
    for id in ipairs(config.Chapter) do
        if IsNumberValid(id) then
            tableInsert(ids, id)
        end
    end
    return ids
end
-----------------???????????? end--------------------
-----------------?????? begin--------------------
local function GetRuneConfig(runeId)
    local config = StrongholdRuneConfig[runeId]
    if not config then
        XLog.Error("XStrongholdConfigs GetRuneConfig error:???????????????, runeId: " .. runeId .. ", ????????????: " .. TABLE_RUNE_PATH)
        return
    end
    return config
end

local function GetSubRuneConfig(subRuneId)
    local config = StrongholdSubRuneConfig[subRuneId]
    if not config then
        XLog.Error("XStrongholdConfigs GetSubRuneConfig error:???????????????, subRuneId: " .. subRuneId .. ", ????????????: " .. TABLE_SUB_RUNE_PATH)
        return
    end
    return config
end

function XStrongholdConfigs.GetRuneName(runeId)
    local config = GetRuneConfig(runeId)
    return config.Name or ""
end

function XStrongholdConfigs.GetRuneIcon(runeId)
    local config = GetRuneConfig(runeId)
    return config.Icon or ""
end

function XStrongholdConfigs.GetRuneDesc(runeId)
    local config = GetRuneConfig(runeId)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end

function XStrongholdConfigs.GetRuneBrief(runeId)
    local config = GetRuneConfig(runeId)
    return config.Brief or ""
end

function XStrongholdConfigs.GetRuneColor(runeId)
    local config = GetRuneConfig(runeId)
    return XUiHelper.Hexcolor2Color(config.Color)
end

function XStrongholdConfigs.GetSubRuneIds(runeId)
    local subRuneIds = {}
    local config = GetRuneConfig(runeId)
    for _, subRuneId in ipairs(config.SubRuneId) do
        if XTool.IsNumberValid(subRuneId) then
            tableInsert(subRuneIds, subRuneId)
        end
    end
    return subRuneIds
end

function XStrongholdConfigs.GetSubRuneName(subRuneId)
    local config = GetSubRuneConfig(subRuneId)
    return config.Name or ""
end

function XStrongholdConfigs.GetSubRuneIcon(subRuneId)
    local config = GetSubRuneConfig(subRuneId)
    return config.Icon or ""
end

function XStrongholdConfigs.GetSubRuneDesc(subRuneId)
    local config = GetSubRuneConfig(subRuneId)
    return XUiHelper.ConvertLineBreakSymbol(config.Desc)
end
-----------------?????? end--------------------