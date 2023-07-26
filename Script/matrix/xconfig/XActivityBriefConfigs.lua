local TABLE_ACTIVITY_PATH = "Client/ActivityBrief/ActivityBrief.tab"
local TABLE_ACTIVITY_SHOP = "Client/ActivityBrief/ActivityBriefShop.tab"
local TABLE_ACTIVITY_SHOP_GOODS_SORT = "Client/ActivityBrief/ActivityBriefShopGoodsSort.tab"
local TABLE_ACTIVITY_TASK = "Client/ActivityBrief/ActivityBriefTask.tab"
local TABLE_ACTIVITY_GROUP_PATH = "Client/ActivityBrief/ActivityBriefGroup.tab"
local TABLE_ACTIVITY_SPECIAL = "Client/ActivityBrief/SpecialActivity.tab"
local TABLE_ACTIVITY_Story = "Share/ActivityBrief/ActivityBriefStory.tab"

local ParseToTimestamp = XTime.ParseToTimestamp

local ActivityTemplates = {}
local ActivityShopTemplates = {}
local ActivityShopGoodsSortTemplates = {}
local ActivityTaskTemplates = {}
local ActivityGroupTemplates = {}
local SpecialActivityTemplates = {}
local ActivityStoryTemplates = {}
local SkipIdToRedPointConditionsDic = {}
local SkipIdToRedPointParamDic = {}

XActivityBriefConfigs = XActivityBriefConfigs or {}

-- 活动名称Id（有需要新增，勿删改！注意与TABLE_ACTIVITY_GROUP_PATH路径表同步）
XActivityBriefConfigs.ActivityGroupId = {
    MainLine = 1, --主线活动
    Branch = 2, --支线活动
    BossSingle = 3, --单机Boss活动(超难关)
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
    Expedition = 49, --虚像地平线
    SameColorGame = 50, --三消游戏
    AreaWar = 51, --全服对决
    SuperSmashBros = 52, --超限乱斗
    TeachingSkin = 53, --教学关内涂装试玩
    Maverick = 54, --射击玩法 异构阵线 孤胆枪手
    MemorySave = 55, --意识营救战
    Theatre = 56, --肉鸽玩法
    DoomsDay = 57, --免疫之城
    PivotCombat = 58, --Sp战力验证
    Escape = 59, --大逃杀玩法
    FubenShortStory = 60, --故事集
    DoubleTowers = 61, --动作塔防
    SecondActivityBriefShop = 62, --活动商店
    SecondBriefPanel = 63, --副面板
    GuildWar = 64, --工会战
    GoldenMiner = 65, --黄金矿工
    QiGuan = 66, --春节七关
    TaikoMaster = 67, -- 音游小游戏
    MultiDim = 68, -- 多维挑战
    Festival = 69, -- 节日剧情 端午节
    GuildBoss = 70, -- 拟真围剿
    TwoSideTower = 71, -- 正逆塔
    QixiFestival = 73, --节日剧情 七夕节
    BiancaTheatre = 74, --肉鸽2.0
    MoonFestival = 75, --节日剧情 中秋节
    CharacterTower = 76, --角色塔(本我回廊)
    Rift = 77,  --战双大秘境
    ColorTable = 78, -- 调色板战争
    BrilliantWalk = 79, -- 光辉同行
    FubenAwareness = 80, -- 意识公约(危机公约)
    Restaurant = 81, -- 春节餐厅(战双餐厅)
    YuanXiao2023 = 82, -- 特训关 2023元宵
    SpringFestival = 83, -- 节日剧情 春节
}
--跳转id
XActivityBriefConfigs.SkipId =
{
    LivWarmExtActivity = 11767, --丽芙宣发活动
    LivWarmRace = 20097,    --二周年预热-赛跑小游戏
    Doomsday = 82050, --免疫之城
    NewYearLuck = 20112, --元旦奖券小游戏
    BodyCombineGame = 20118, --接头霸王（哈卡玛预热小游戏）
    AccumulateConsume = 20120, --累消活动
    WhiteValentine = 20133, --白情活动
    InvertCardGame = 20134, --翻牌小游戏（二期）
    MineSweepingGame = 20140, --扫雷小游戏
    Puzzle = 20149, --拼图
}

-- 面板类型
XActivityBriefConfigs.PanelType = {
    Main = 1,           -- 主面板
    Second = 2,         -- 副面板
}

-- v1.31 特殊入场动效播放检测类型
XActivityBriefConfigs.EnterAniCheckType = {
    None = 0,           -- 本期无特殊入场动画
    OnlyFirst = 1,      -- 活动期间内首次打开
    EveryDay = 2,       -- 活动期间内每天首次打开
    EveryLogin = 3,     -- 活动期间内每次登录首次打开
}

-- v2.0 活动面板添加
XActivityBriefConfigs.BgType = {
    Spine = 1,          -- Spine动画
    Scene = 2,          -- Scene TimeLine动画
    Video = 3,          -- 视频动画
    TimeLine = 4,       -- Ui TimeLine动画
}

local ActivityRedPointType = {
    None = 0, -- 无红点
    Normal = 1, -- 不带参数红点
    Special = 2, --  带参数红点
}

local InitSkipIdToRedPointConditionsDic = function()
    -- V1.31该方法添加红点已废弃,请在SpecialActivity.tab配置里添加对应活动的红点
    SkipIdToRedPointConditionsDic[11739] = {XRedPointConditions.Types.CONDITION_GUARD_CAMP_RED}
    SkipIdToRedPointConditionsDic[80011] = {XRedPointConditions.Types.CONDITION_WHITEVALENTINE2021_ENTRYRED}
    SkipIdToRedPointConditionsDic[11753] = {XRedPointConditions.Types.CONDITION_FINGERGUESSING_TASK}
    SkipIdToRedPointConditionsDic[11757] = {XRedPointConditions.Types.CONDITION_MOVIE_ASSEMBLE_01}
    SkipIdToRedPointConditionsDic[11761] = {XRedPointConditions.Types.CONDITION_FASHION_STORY_HAVE_STAGE}
    SkipIdToRedPointConditionsDic[81103] = {XRedPointConditions.Types.CONDITION_RPG_MAKER_GAME_RED}
    SkipIdToRedPointConditionsDic[20091] = {XRedPointConditions.Types.CONDITION_LIV_WARM_ACTIVITY}
    SkipIdToRedPointConditionsDic[20107] = {XRedPointConditions.Types.CONDITION_DICEGAME_RED}
    SkipIdToRedPointConditionsDic[20147] = {XRedPointConditions.Types.CONDITION_ACTIVITY_DRAGON_BOAT_FESTIVAL}
    SkipIdToRedPointConditionsDic[20156] = {XRedPointConditions.Types.CONDITION_SUMMER_SIGNIN_ACTIVITY}
    SkipIdToRedPointConditionsDic[XActivityBriefConfigs.SkipId.LivWarmExtActivity] = {XRedPointConditions.Types.CONDITION_LIV_WARM_EXT_ACTIVITY}
    SkipIdToRedPointConditionsDic[XActivityBriefConfigs.SkipId.LivWarmRace] = {XRedPointConditions.Types.CONDITION_LIV_WARM_RACE_REWARD}
    SkipIdToRedPointConditionsDic[XActivityBriefConfigs.SkipId.Doomsday] = {XRedPointConditions.Types.XRedPointConditionDoomsdayActivity}
    SkipIdToRedPointConditionsDic[XActivityBriefConfigs.SkipId.NewYearLuck] = {XRedPointConditions.Types.CONDITION_NEW_YEAR_LUCK_RULE_RED}
    SkipIdToRedPointConditionsDic[XActivityBriefConfigs.SkipId.BodyCombineGame] = {XRedPointConditions.Types.CONDITION_BODYCOMBINEGAME_MAIN}
    SkipIdToRedPointConditionsDic[XActivityBriefConfigs.SkipId.AccumulateConsume] = {XRedPointConditions.Types.CONDITION_CONSUME_ACTIVITY}
    SkipIdToRedPointConditionsDic[XActivityBriefConfigs.SkipId.WhiteValentine] = {XRedPointConditions.Types.CONDITION_ACTIVITY_WHITE_VALENTINE}
    SkipIdToRedPointConditionsDic[XActivityBriefConfigs.SkipId.InvertCardGame] = {XRedPointConditions.Types.CONDITION_INVERTCARDGAME_RED}
    SkipIdToRedPointConditionsDic[XActivityBriefConfigs.SkipId.MineSweepingGame] = {XRedPointConditions.Types.CONDITION_MINSWEEPING_RED}
    SkipIdToRedPointConditionsDic[XActivityBriefConfigs.SkipId.Puzzle] = {XRedPointConditions.Types.CONDITION_DRAG_PUZZLE_GAME_SWITCH}
    
    -- 读取配置
    for _, config in pairs(SpecialActivityTemplates) do
        if config.ActivityType == ActivityRedPointType.None then
            goto CONTINUE
        end

        if config.RedPointConditions then
            SkipIdToRedPointConditionsDic[config.SkipId] = {config.RedPointConditions}
        end

        if config.ActivityType == ActivityRedPointType.Special then
            if config.Param then
                SkipIdToRedPointParamDic[config.SkipId] = config.Param
            end
        end
        
        :: CONTINUE ::
    end
end

function XActivityBriefConfigs.Init()
    ActivityTemplates = XTableManager.ReadByIntKey(TABLE_ACTIVITY_PATH, XTable.XTableBriefActivity, "Id")
    ActivityShopTemplates= XTableManager.ReadByIntKey(TABLE_ACTIVITY_SHOP, XTable.XTableActivityBriefShop, "Id")
    ActivityShopGoodsSortTemplates= XTableManager.ReadByIntKey(TABLE_ACTIVITY_SHOP_GOODS_SORT, XTable.XTableActivityBriefShopGoodsSort, "Id")
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

---v1.27 活动面板优化:根据活动主题主副面板Id和SpineIndex获取SpinePath
---@param panelType integer
---@param index integer
---@return string
function XActivityBriefConfigs.GetSpinePathByType(panelType, index)
    local config = ActivityTemplates[panelType]
    return config.SpinePath[index] or ""
end

---v1.27 活动面板优化:根据活动主题主副面板Id获取当前的 SpinePath List
---@param panelType integer
---@return table
function XActivityBriefConfigs.GetSpinePathList(panelType)
    local config = ActivityTemplates[panelType]
    return config.SpinePath or {}
end

function XActivityBriefConfigs.GetActivityBgType(panelType)
    local config = ActivityTemplates[panelType]
    if XTool.IsTableEmpty(config) then return nil end
    return config.BgType or nil
end

---v2.2 根据活动主题主副面板Id第一次播放完动画是否默认选择跳过动画
---@param panelType integer
---@return boolean
function XActivityBriefConfigs.GetIsAfterFirstAnimSetSkip(panelType)
    local config = ActivityTemplates[panelType]
    if XTool.IsTableEmpty(config) then return false end
    return XTool.IsNumberValid(config.IsAfterFirstAnimSetSkip)
end

---v1.29 活动面板:根据活动主题主副面板Id获取当前的 Main3DBg
---@param panelType integer
---@return string|nil
function XActivityBriefConfigs.GetMain3DBgPath(panelType)
    local config = ActivityTemplates[panelType]
    if XTool.IsTableEmpty(config) then return nil end
    return config.Main3DBg or nil
end

---v1.31 根据活动主题主副面板Id获取当前的 Main3DBgModel
---@param panelType integer
---@return string|nil
function XActivityBriefConfigs.GetMain3DBgModelPath(panelType)
    local config = ActivityTemplates[panelType]
    if XTool.IsTableEmpty(config) then return nil end
    return config.Main3DBgModel or nil
end

function XActivityBriefConfigs.GetSpecialEnterAnimName(panelType)
    local config = ActivityTemplates[panelType]
    if XTool.IsTableEmpty(config) then return nil end
    return config.SpecialEnterAnimName or nil
end

---v1.31 根据活动主题主副面板Id获取当前的 EnterAniCheckType
---@param panelType integer
---@return integer
function XActivityBriefConfigs.GetEnterAniCheckType(panelType)
    local config = ActivityTemplates[panelType]
    if XTool.IsTableEmpty(config) then return XActivityBriefConfigs.EnterAniCheckType.None end
    return config.EnterAniCheckType or XActivityBriefConfigs.EnterAniCheckType.None
end

function XActivityBriefConfigs.GetEnterAnimName(panelType)
    local config = ActivityTemplates[panelType]
    if XTool.IsTableEmpty(config) then return nil end
    return config.EnterAnimName or nil
end

function XActivityBriefConfigs.GetLoopAnimName(panelType)
    local config = ActivityTemplates[panelType]
    if XTool.IsTableEmpty(config) then return nil end
    return config.LoopAnimName or nil
end

function XActivityBriefConfigs.GetVideoEnterSoundCueId(panelType)
    local config = ActivityTemplates[panelType]
    if XTool.IsTableEmpty(config) then return nil end
    return config.VideoEnterSoundCueId or nil
end

function XActivityBriefConfigs.GetVideoLoopSoundCueId(panelType)
    local config = ActivityTemplates[panelType]
    if XTool.IsTableEmpty(config) then return nil end
    return config.VideoLoopSoundCueId or nil
end

---v1.27 活动面板优化:根据活动主题主副面板Id获取当前的 GroupId List
---@param panelType integer
---@return table
function XActivityBriefConfigs.GetGroupIdList(panelType)
    local config = ActivityTemplates[panelType]
    return config.GroupIdList or {}
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

function XActivityBriefConfigs.GetActivityShopGoodsSortById(id)
    return ActivityShopGoodsSortTemplates[id]
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

---v1.27 活动面板优化:根据活动GroupId获取该Btn点击事件绑定函数名
---@param groupId integer
---@return string|nil
function XActivityBriefConfigs.GetActivityGroupBtnInitMethodName(groupId)
    local groupConfig = ActivityGroupTemplates[groupId]
    if not groupConfig then
        XLog.ErrorTableDataNotFound("XActivityBriefConfigs.GetActivityGroupBtnInitMethodName",
        "根据groupId获取的配置表项", TABLE_ACTIVITY_GROUP_PATH, "groupId", tostring(groupId))
        return
    end
    return groupConfig.BtnInitMethodName or nil
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

function XActivityBriefConfigs.GetRedPointParamBySkipId(skipId)
    return skipId and SkipIdToRedPointParamDic[skipId]
end

function XActivityBriefConfigs.GetActivityBriefGroupTimeId(groupId)
    local config = XActivityBriefConfigs.GetActivityGroupConfig(groupId)
    return config and config.TimeId or 0
end

function XActivityBriefConfigs.GetActivityBriefGroupIsRemindWhenOpen(groupId)
    local config = XActivityBriefConfigs.GetActivityGroupConfig(groupId)
    return config and config.IsRemindWhenOpen or 0
end

function XActivityBriefConfigs.GetActivityBriefGroupRemindPriority(groupId)
    local config = XActivityBriefConfigs.GetActivityGroupConfig(groupId)
    return config and config.RemindPriority or 0
end

function XActivityBriefConfigs.GetActivityBriefGroupTagCondition(groupId)
    local config = XActivityBriefConfigs.GetActivityGroupConfig(groupId)
    return config and config.TagCondition or ""
end

function XActivityBriefConfigs.GetActivityBriefGroupTagOffset(groupId)
    local config = XActivityBriefConfigs.GetActivityGroupConfig(groupId)
    return config and config.TagOffset or 0
end