local TABLE_ACTIVITY_PATH = "Client/ActivityBrief/ActivityBrief.tab"
local TABLE_ACTIVITY_SHOP = "Client/ActivityBrief/ActivityBriefShop.tab"
local TABLE_ACTIVITY_TASK = "Client/ActivityBrief/ActivityBriefTask.tab"
local TABLE_ACTIVITY_GROUP_PATH = "Client/ActivityBrief/ActivityBriefGroup.tab"
local TABLE_ACTIVITY_SPECIAL = "Client/ActivityBrief/SpecialActivity.tab"
local TABLE_ACTIVITY_Story = "Share/ActivityBrief/ActivityBriefStory.tab"

local ParseToTimestamp = XTime.ParseToTimestamp

local ActivityTemplates = {}
local ActivityShopTemplates = {}
local ActivityTaskTemplates = {}
local ActivityGroupTemplates = {}
local SpecialActivityTemplates = {}
local ActivityStoryTemplates = {}
local SkipIdToRedPointConditionsDic = {}

XActivityBriefConfigs = XActivityBriefConfigs or {}

-- 活动名称Id（有需要新增，勿删改！）
XActivityBriefConfigs.ActivityGroupId = {
    MainLine = 1, --主线活动
    Branch = 2, --支线活动
    BossSingle = 3, --单机Boss活动
    BossOnline = 4, --联机Boss活动
    Prequel = 5, --间章故事-角色A
    BabelTower = 6, --巴别塔
    RougueLike = 7, --爬塔
    RepeatChallenge = 8, --复刷关
    ArenaOnline = 9, --区域联机
    UnionKill = 10, --狙击战
    ShortStories = 11, --短篇故事
    Prequel2 = 12, --间章故事-角色B
    Labyrinth = 13, --迷宫
    Society = 14, --公会
    Resource = 15, --资源
    BigWar = 16, --大作战
    Extra = 17, --番外-普通
    WorldBoss = 18, --世界Boss
    Expedition = 19, --自走棋
    FubenBossSingle = 20, --幻痛囚笼
    ActivityBriefShop = 21, --活动商店
    Extra2 = 22, --番外-隐藏
    MaintainerAction = 23, --大富翁
    RpgTower = 24, --RPG玩法
    ActivityDrawCard = 25, --活动抽卡
    TRPGMainLine = 26, --终焉福音-主线跑团活动
    NewCharActivity = 27, -- 新角色教学活动
    FubenActivityTrial = 28, -- 试玩关
    ShiTu = 29, -- 师徒系统
    Nier = 30, -- 尼尔玩法
    Pokemon = 31, -- 口袋战双
    Pursuit = 32, -- 追击玩法
    StrongHold = 33, --超级据点
    Simulate = 34, -- 模拟战
    Partner = 35, --伙伴系统
    MoeWar = 38, --萌战
    PetCard = 39, --宠物抽卡
    PetTrial = 40, --新宠物活动
    PokerGuessing = 41, --翻牌小游戏
    Hack = 42, --骇客
    RpgMaker = 43, --端午活动
    Reform = 44, --改造玩法
    CoupleCombat = 45, --双人同行
    SuperTower = 46, --超级爬塔
    SummerSeries = 47, --夏活系列关
    KillZone = 48, --杀戮无双
}

local InitSkipIdToRedPointConditionsDic = function()
    SkipIdToRedPointConditionsDic[11739] = {XRedPointConditions.Types.CONDITION_GUARD_CAMP_RED}
    SkipIdToRedPointConditionsDic[80011] = {XRedPointConditions.Types.CONDITION_WHITEVALENTINE2021_ENTRYRED}
    SkipIdToRedPointConditionsDic[11753] = {XRedPointConditions.Types.CONDITION_FINGERGUESSING_TASK}
    SkipIdToRedPointConditionsDic[11757] = {XRedPointConditions.Types.CONDITION_MOVIE_ASSEMBLE_01}
    SkipIdToRedPointConditionsDic[11759] = {XRedPointConditions.Types.CONDITION_MINSWEEPING_RED}
    SkipIdToRedPointConditionsDic[11761] = {XRedPointConditions.Types.CONDITION_FASHION_STORY_HAVE_STAGE}
    SkipIdToRedPointConditionsDic[81103] = {XRedPointConditions.Types.CONDITION_RPG_MAKER_GAME_RED}
    SkipIdToRedPointConditionsDic[1400008] = {XRedPointConditions.Types.CONDITION_SLOTMACHINE_RED}
    SkipIdToRedPointConditionsDic[1400009] = {XRedPointConditions.Types.CONDITION_SLOTMACHINE_REDL}
end

function XActivityBriefConfigs.Init()
    ActivityTemplates = XTableManager.ReadByIntKey(TABLE_ACTIVITY_PATH, XTable.XTableBriefActivity, "Id")
    ActivityShopTemplates= XTableManager.ReadByIntKey(TABLE_ACTIVITY_SHOP, XTable.XTableActivityBriefShop, "Id")
    ActivityTaskTemplates= XTableManager.ReadByIntKey(TABLE_ACTIVITY_TASK, XTable.XTableActivityBriefTask, "Id")
    ActivityGroupTemplates = XTableManager.ReadByIntKey(TABLE_ACTIVITY_GROUP_PATH, XTable.XTableActivityBriefGroup, "Id")
    SpecialActivityTemplates = XTableManager.ReadByIntKey(TABLE_ACTIVITY_SPECIAL, XTable.XTableSpecialActivity, "Id")
    ActivityStoryTemplates = XTableManager.ReadByIntKey(TABLE_ACTIVITY_Story, XTable.XTableActivityBriefStory, "Id")

    InitSkipIdToRedPointConditionsDic()
end

function XActivityBriefConfigs.GetActivityBeginTime()
    local config = XActivityBriefConfigs.GetActivityConfig()
    return XFunctionManager.GetStartTimeByTimeId(config.TimeId)
end

function XActivityBriefConfigs.GetActivityEndTime()
    local config = XActivityBriefConfigs.GetActivityConfig()
    return XFunctionManager.GetEndTimeByTimeId(config.TimeId)
end

function XActivityBriefConfigs.GetActivityConfig()
    return ActivityTemplates[1]
end

function XActivityBriefConfigs.GetActivityModels()
    local config = XActivityBriefConfigs.GetActivityConfig()
    return config.UIModelId or {}
end

function XActivityBriefConfigs.GetSpinePath(index)
    local config = XActivityBriefConfigs.GetActivityConfig()
    return config.SpinePath[index] or ""
end

function XActivityBriefConfigs.GetActivityEntrySkipId(id)
    return SpecialActivityTemplates[id].SkipId
end

function XActivityBriefConfigs.GetAllActivityEntryConfig()
    return SpecialActivityTemplates
end

function XActivityBriefConfigs.GetActivityShopByInfoId(id)
    return ActivityShopTemplates[id]
end

function XActivityBriefConfigs.GetActivityTaskByInfoId(id)
    return ActivityTaskTemplates[id]
end

function XActivityBriefConfigs.GetActivityGroupConfig(groupId)
    local groupConfig = ActivityGroupTemplates[groupId]
    if not groupConfig then
        XLog.ErrorTableDataNotFound("XActivityBriefConfigs.GetActivityGroupConfig",
        "根据groupId获取的配置表项", TABLE_ACTIVITY_GROUP_PATH, "groupId", tostring(groupId))
        return
    end
    return groupConfig
end

function XActivityBriefConfigs.TestOpenActivity()
    local newTemplate = {}
    for id, template in pairs(ActivityTemplates) do
        if id ~= 1 then
            newTemplate[id] = template
        else
            newTemplate[id] = XTool.Clone(template)
            newTemplate[id].TimeId = 24
        end
    end
    ActivityTemplates = newTemplate
end

function XActivityBriefConfigs.GetTableActivityPath()
    return TABLE_ACTIVITY_PATH
end

function XActivityBriefConfigs.GetActivityStoryConfig()
    return ActivityStoryTemplates
end

function XActivityBriefConfigs.GetActivityBriefGroup(id)
    local config = XActivityBriefConfigs.GetActivityGroupConfig(id)
    return config.Name
end

function XActivityBriefConfigs.GetRedPointConditionsBySkipId(skipId)
    return skipId and SkipIdToRedPointConditionsDic[skipId]
end