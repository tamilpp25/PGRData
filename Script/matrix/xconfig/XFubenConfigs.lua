local CSXGameClientConfig = CS.XGame.ClientConfig
local CSXTextManagerGetText = CS.XTextManager.GetText

XFubenConfigs = XConfigCenter.CreateTableConfig(XFubenConfigs, "XFubenConfigs", "Fuben")
--=============
--配置表枚举
--TableName : 表名，对应需要读取的表的文件名字，不写即为枚举的Key字符串
--TableDefindName : 表定于名，默认同表名
--ReadFuncName : 读取表格的方法，默认为ReadByIntKey
--ReadKeyName : 读取表格的主键名，默认为Id
--DirType : 读取的文件夹类型XConfigCenter.DirectoryType，默认是Share
--LogKey : GetCfgByIdKey方法idKey找不到时所输出的日志信息，默认是唯一Id
--=============
XFubenConfigs.TableKey = enum({
    FubenActivity = {},
    FubenTabConfig = { DirType = XConfigCenter.DirectoryType.Client },
    FubenSecondTag = { DirType = XConfigCenter.DirectoryType.Client },
    FubenStoryLine = { DirType = XConfigCenter.DirectoryType.Client },
    FubenActivityTimeTips = { DirType = XConfigCenter.DirectoryType.Client },
    FubenCollegeBanner = {},
    FubenClientConfig = { ReadKeyName = "Key", ReadFuncName = "ReadByStringKey", DirType = XConfigCenter.DirectoryType.Client },
    StageVoiceTip = { ReadKeyName = "StageId", DirType = XConfigCenter.DirectoryType.Client},
})

local TABLE_STAGE = "Share/Fuben/Stage.tab"
local TABLE_STAGE_TYPE = "Share/Fuben/StageType.tab"
local TABLE_MULTICHALLENGE_STAGE = "Share/Fuben/MultiChallengeStage.tab"
local TABLE_STAGE_TRANSFORM = "Share/Fuben/StageTransform.tab"
local TABLE_STAGE_LEVEL_CONTROL = "Share/Fuben/StageLevelControl.tab"
local TABLE_STAGE_MULTIPLAYER_LEVEL_CONTROL = "Share/Fuben/StageMultiplayerLevelControl.tab"
local TABLE_FLOP_REWARD = "Share/Fuben/FlopReward.tab"
local TABLE_STAGE_FIGHT_CONTROL = "Share/Fuben/StageFightControl.tab" --副本战力限制表
local TABLE_CHALLENGE_BANNER = "Share/Fuben/FubenChallengeBanner.tab"
local TABLE_ACTIVITY_SORTRULE = "Client/Fuben/ActivitySortRule/ActivitySortRule.tab"
local TABLE_FUBENFEATURES = "Client/Fuben/FubenFeatures.tab" -- 特性展示表
local TABLE_STAGE_CHARACTERLIMIT = "Share/Fuben/StageCharacterLimit.tab" -- 角色类型限制buff
local TABLE_BOSS_TEAMBUFF = "Share/Fuben/StageTeamBuff.tab"
local TABLE_STAGE_FIGHT_EVENT_DETAILS = "Client/Fuben/StageFightEventDetails.tab"
local TABLE_STAGE_FIGHT_EVENT = "Share/Fuben/StageFightEvent.tab"
local TABLE_SETTLE_LOST_TIP = "Client/Fuben/SettleLoseTip.tab"  -- 失败结算界面提示
local TABLE_STAGE_RECOMMEND_PATH = "Client/Fuben/StageRecommend.tab"  -- 关卡推荐表
local TABLE_STAGE_MIX_CHARACTER_LIMIT_BUFF_PATH = "Client/Fuben/StageMixCharacterLimitBuff.tab"  -- 关卡混合buff提示
local TABLE_STAGE_STEP_SKIP = "Client/Fuben/StageStepSkip.tab"  -- 关卡步骤跳过
local TABLE_STAGE_GAME_PLAY_DESC = "Client/Fuben/StageGamePlayDesc.tab" -- 暂停界面玩法说明
local TABLE_STAGE_GAME_PLAY_DESC_SHEET = "Client/Fuben/StageGamePlayDescSheet.tab" -- 暂停界面玩法说明子页签
local TABLE_STAGE_SETTLE_SPECIAL_SOUND = "Client/Fuben/StageSettleSpecialSound.tab" -- 结算界面特殊Sound

local StageCfg = {}
local StageTransformCfg = {}
local StageMultiplayerLevelControlCfg = {}
local FlopRewardTemplates = {}
local StageFightControlCfg = {}
local FubenChallengeBanners = {}
local ActivitySortRules = {}
local FubenFeatures = {}
local MultiChallengeConfigs = {}
local FubenNewChallenge
local StageCharacterLimitBuffConfig = {}
local TeamBuffCfg = {}
local TeamBuffMaxCountDic = {}
local StageFightEvent = {}
local StageFightEventDetails = {}
local SettleLoseTipCfg = {}
local StageRecommendConfigs = {}
local StageTypeConfigs = {}
local StageCharacterLimitBuffDic = {}
local StageStepSkipConfigs = {}
local StageGamePlayDesc = {}
local StageGamePlayDescSheet = {}
local StageSettleSpecialSoundCfg = {}

--对应Stage表的StageType，注意和FubenManager的StageType区分
XFubenConfigs.STAGETYPE_COMMON = 0
XFubenConfigs.STAGETYPE_FIGHT = 1
XFubenConfigs.STAGETYPE_STORY = 2
XFubenConfigs.STAGETYPE_STORYEGG = 3
XFubenConfigs.STAGETYPE_FIGHTEGG = 4

XFubenConfigs.FUBENTYPE_NORMAL = 0
XFubenConfigs.FUBENTYPE_PREQUEL = 1

XFubenConfigs.ROOM_MAX_WORLD = CSXGameClientConfig:GetInt("MultiplayerRoomRowMaxWorld")
XFubenConfigs.ROOM_WORLD_TIME = CSXGameClientConfig:GetInt("MultiplayerRoomWorldTime")

XFubenConfigs.CharacterLimitType = {
    All = 0, --构造体/感染体
    Normal = 1, --构造体
    Isomer = 2, --感染体
    IsomerDebuff = 3, --构造体/感染体(Debuff) [AKA:低浓度区]
    NormalDebuff = 4, --构造体(Debuff)/感染体 [AKA:重灾区]
}

XFubenConfigs.MainLineMoveOpenTime = 0.3
XFubenConfigs.MainLineMoveCloseTime = 0.7
XFubenConfigs.MainLineWaitTime = 500
XFubenConfigs.ExtralLineMoveOpenTime = 0.3
XFubenConfigs.ExtralLineMoveCloseTime = 0.5
XFubenConfigs.ExtralLineWaitTime = 650
XFubenConfigs.DebugOpenOldMainUi = false

XFubenConfigs.AISuggestType = {
    All = 0, -- 无
    Robot = 1, -- 推荐使用角色
}

XFubenConfigs.StepSkipType = {
    SettleLose = 1, -- 失败结算
}

XFubenConfigs.ChapterType = {
    MainLine = 0,
    TOWER = 1,
    YSHTX = 2,
    EMEX = 3,
    DJHGZD = 4,
    BossSingle = 5,
    Urgent = 6,
    BossOnline = 7,
    Resource = 8,
    Trial = 9, --意识营救战
    ARENA = 10,
    Explore = 11, --探索(黄金之涡)
    ActivtityBranch = 12, --活动支线副本
    ActivityBossSingle = 13, --活动单挑BOSS
    Practice = 14, --教学关卡
    GZTX = 15, --日常構造體特訓
    XYZB = 16, --日常稀有裝備
    TPCL = 17, --日常突破材料
    ZBJY = 18, --日常裝備經驗
    LMDZ = 19, --日常螺母大戰
    JNQH = 20, --日常技能强化
    Christmas = 21, --节日活动-圣诞节
    BriefDarkStream = 22, --活动-极地暗流
    ActivityBabelTower = 23, --巴别塔计划
    FestivalNewYear = 24, --新年活动
    RepeatChallenge = 25, --复刷本
    RogueLike = 26, --爬塔
    FoolsDay = 27, --愚人节活动
    Assign = 28, -- 边界公约
    ChinaBoatPreheat = 29, --中国船预热
    ArenaOnline = 30, -- 合众战局
    UnionKill = 31, --列阵
    SpecialTrain = 32, --特训关
    InfestorExplore = 33, -- 感染体玩法
    Expedition = 34, -- 虚像地平线
    WorldBoss = 35, --世界Boss
    RpgTower = 36, --兵法蓝图
    MaintainerAction = 37, --大富翁
    NewCharAct = 38, -- 新角色教学
    Pokemon = 39, --口袋战双
    NieR = 40, --尼尔玩法
    ChessPursuit = 41, --追击玩法
    SpringFestivalActivity = 42, --春节活动
    SimulatedCombat = 43, --模拟作战
    Stronghold = 44, --超级据点
    MoeWar = 45, --萌战
    Reform = 46, --改造玩法
    PartnerTeaching = 47, --宠物教学
    FZJQH = 48, --日常辅助机强化
    PokerGuessing = 49, --翻牌猜大小
    Hack = 50, --骇入玩法
    FashionStory = 51, --涂装剧情活动
    KillZone = 52, --杀戮无双
    SuperTower = 53, --超级爬塔
    CoupleCombat = 54, --双人下场玩法玩法
    SameColor = 55, -- 三消游戏
    SuperSmashBros = 56, --超限乱斗
    AreaWar = 57, -- 全服决战
    MemorySave = 58, -- 周年意识营救战
    Maverick = 59, -- 射击玩法
    Theatre = 60, --肉鸽玩法
    NewYearLuck = 61,--春节奖券小游戏
    Escape = 62, --大逃杀玩法
    PivotCombat = 63, --SP枢纽作战
    DoubleTowers = 64, --动作塔防
    GoldenMiner = 65, --黄金矿工
    RpgMakerGame = 66, --推箱子小游戏
    MultiDim = 67, -- 多维挑战
    TaikoMaster = 68, --音游
    TwoSideTower = 69, --正逆塔
    Doomsday = 70, --模拟经营
    Bfrt = 71, --据点
    Experiment = 72, --试玩关
    Daily = 73, -- 日常
    ExtralChapter = 74, -- 外篇旧闻
    Festival = 75,   -- 活动记录
    ShortStory = 76, -- 浮点纪实
    Prequel = 77,   -- 间章旧闻
    CharacterFragment = 78, -- 角色碎片
    Activity = 79, -- 活动归纳整理
    Course = 80, -- v1.30 考级
    BiancaTheatre = 81, --肉鸽2.0
    Rift = 82, --战双大秘境
    CharacterTower = 83, --本我回廊（角色塔）
    ColorTable = 84, -- 调色板战争
    BrilliantWalk = 85, --光辉同行
    DlcHunt = 86,   -- Dlc
    Maverick2 = 87, -- 异构阵线2.0
    Maze = 88, -- 情人节活动2023
    PlanetRunning = 89, 
    CerberusGame = 90,
    Transfinite = 91, -- 超限连战
    Theatre3 = 92, -- 肉鸽3.0
}

function XFubenConfigs.Init()
    StageCfg = XTableManager.ReadAllByIntKey(TABLE_STAGE, XTable.XTableStage, "StageId")
    MultiChallengeConfigs = XTableManager.ReadByIntKey(TABLE_MULTICHALLENGE_STAGE, XTable.XTableMultiChallengeStage, "Id")
    StageMultiplayerLevelControlCfg = XTableManager.ReadAllByIntKey(TABLE_STAGE_MULTIPLAYER_LEVEL_CONTROL, XTable.XTableStageMultiplayerLevelControl, "Id")
    StageTransformCfg = XTableManager.ReadByIntKey(TABLE_STAGE_TRANSFORM, XTable.XTableStageTransform, "Id")
    --TowerSectionCfg = XTableManager.ReadByIntKey(TABLE_TOWER_SECTION, XTable.XTableTowerSection, "Id")
    FlopRewardTemplates = XTableManager.ReadByIntKey(TABLE_FLOP_REWARD, XTable.XTableFlopReward, "Id")
    StageFightControlCfg = XTableManager.ReadByIntKey(TABLE_STAGE_FIGHT_CONTROL, XTable.XTableStageFightControl, "Id")
    ActivitySortRules = XTableManager.ReadByIntKey(TABLE_ACTIVITY_SORTRULE, XTable.XTableActivitySortRule, "Id")
    FubenFeatures = XTableManager.ReadByIntKey(TABLE_FUBENFEATURES, XTable.XTableFubenFeatures, "Id")
    StageCharacterLimitBuffConfig = XTableManager.ReadByIntKey(TABLE_STAGE_CHARACTERLIMIT, XTable.XTableFubenStageCharacterLimit, "Id")
    StageFightEvent = XTableManager.ReadByIntKey(TABLE_STAGE_FIGHT_EVENT, XTable.XTableStageFightEvent, "StageId")
    StageFightEventDetails = XTableManager.ReadByIntKey(TABLE_STAGE_FIGHT_EVENT_DETAILS, XTable.XTableStageFightEventDetails, "Id")
    SettleLoseTipCfg = XTableManager.ReadByIntKey(TABLE_SETTLE_LOST_TIP, XTable.XTableSettleLoseTip, "Id")
    StageRecommendConfigs = XTableManager.ReadByIntKey(TABLE_STAGE_RECOMMEND_PATH, XTable.XTableStageRecommend, "StageId")
    StageTypeConfigs = XTableManager.ReadByIntKey(TABLE_STAGE_TYPE, XTable.XTableStageType, "Id")
    StageStepSkipConfigs= XTableManager.ReadByIntKey(TABLE_STAGE_STEP_SKIP, XTable.XTableStageStepSkip, "StageId")
    StageGamePlayDesc =
        XTableManager.ReadByIntKey(TABLE_STAGE_GAME_PLAY_DESC, XTable.XTableStageGamePlayDesc, "StageType")
    StageGamePlayDescSheet =
        XTableManager.ReadByIntKey(TABLE_STAGE_GAME_PLAY_DESC_SHEET, XTable.XTableStageGamePlayDescSheet, "Id")

    TeamBuffCfg = XTableManager.ReadByIntKey(TABLE_BOSS_TEAMBUFF, XTable.XTableStageTeamBuff, "Id")
    for id, v in pairs(TeamBuffCfg) do
        local maxCount = 0
        for _, buffId in ipairs(v.BuffId) do
            if buffId > 0 then
                maxCount = maxCount + 1
            end
        end
        TeamBuffMaxCountDic[id] = maxCount
    end

    local banners = XTableManager.ReadByIntKey(TABLE_CHALLENGE_BANNER, XTable.XTableFubenChallengeBanner, "Id")
    for _, v in pairs(banners) do
        FubenChallengeBanners[v.Type] = v
    end

    local characterLimitBuffConfigs = XTableManager.ReadByIntKey(TABLE_STAGE_MIX_CHARACTER_LIMIT_BUFF_PATH, XTable.XTableStageMixCharacterLimitBuff, "CharacterLimitType")
    for limitType, config in pairs(characterLimitBuffConfigs) do
        StageCharacterLimitBuffDic[limitType] = StageCharacterLimitBuffDic[limitType] or {}
        for _, buffInfo in ipairs(config.BuffInfos) do
            local info = string.Split(buffInfo, "|")
            local diffCount = tonumber(info[1])
            local rightCount = tonumber(info[2])
            local buffDescNoColor = tostring(info[3])
            local buffDescWithColor = tostring(info[4])
            local tmpDic = StageCharacterLimitBuffDic[limitType][diffCount] or {}
            tmpDic[rightCount] = {
                BuffNoColor = buffDescNoColor,
                BuffWithColor = buffDescWithColor
            }
            StageCharacterLimitBuffDic[limitType][diffCount] = tmpDic
        end
    end

    StageSettleSpecialSoundCfg = XTableManager.ReadByIntKey(TABLE_STAGE_SETTLE_SPECIAL_SOUND, XTable.XTableStageSettleSpecialSound, "StageId")
end

local function GetStageCfg(stageId, ignoreError)
    local config = StageCfg[stageId]
    if not config and not ignoreError then
        XLog.Error("XFubenConfigs.GetStageCfgs Error: StageId: " .. stageId)
        return
    end
    return config
end

local function GetTeamBuffCfg(teamBuffId)
    local config = TeamBuffCfg[teamBuffId]
    if not config then
        XLog.Error("XFubenConfigs.GetTeamBuffCfg Error: teamBuffId: " .. teamBuffId)
        return
    end
    return config
end

local function GetSettleLoseTipCfg(settleLoseTipId)
    local config = SettleLoseTipCfg[settleLoseTipId]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XFubenConfigs.GetSettleLoseTipCfg",
            "失败提示",
            TABLE_SETTLE_LOST_TIP,
            "Id",
            tostring(settleLoseTipId))
        return {}
    end
    return config
end

function XFubenConfigs.GetStageCfgs()
    return StageCfg
end

function XFubenConfigs.GetBuffDes(buffId)
    local fightEventCfg = buffId and buffId ~= 0 and CS.XNpcManager.GetFightEventTemplate(buffId)
    return fightEventCfg and fightEventCfg.Description or ""
end

function XFubenConfigs.GetStageLevelControlCfg()
    local config = XTableManager.ReadAllByIntKey(TABLE_STAGE_LEVEL_CONTROL, XTable.XTableStageLevelControl, "Id")
    return config
end

function XFubenConfigs.GetStageMultiplayerLevelControlCfg()
    return StageMultiplayerLevelControlCfg
end

function XFubenConfigs.GetStageMultiplayerLevelControlCfgById(id)
    return StageMultiplayerLevelControlCfg[id]
end

function XFubenConfigs.GetStageTransformCfg()
    return StageTransformCfg
end

function XFubenConfigs.GetFlopRewardTemplates()
    return FlopRewardTemplates
end

function XFubenConfigs.GetActivitySortRules()
    return ActivitySortRules
end

function XFubenConfigs.GetFeaturesById(id)
    local t = FubenFeatures[id]
    if not t then
        XLog.ErrorTableDataNotFound("XFubenConfigs.GetFeaturesById", "FubenFeatures", TABLE_FUBENFEATURES, "Id", tostring(id))
        return nil
    end
    return t
end

function XFubenConfigs.GetActivityPriorityByActivityIdAndType(activityId, type)
    for _, v in pairs(ActivitySortRules) do
        if v.Type == type
            and (not not XTool.IsNumberValid(activityId)
                or not XTool.IsNumberValid(v.Activity)
                or v.ActivityId == activityId) then
            return v.Priority
        end
    end
    return 0
end

function XFubenConfigs.GetStageFightControl(id)
    for _, v in pairs(StageFightControlCfg) do
        if v.Id == id then
            return v
        end
    end
    return nil
end

function XFubenConfigs.IsKeepPlayingStory(stageId)
    local targetCfg = StageCfg[stageId]
    if not targetCfg or not targetCfg.KeepPlayingStory then
        return false
    end
    return targetCfg.KeepPlayingStory == 1
end

function XFubenConfigs.GetChapterBannerByType(bannerType)
    return FubenChallengeBanners[bannerType] or {}
end

function XFubenConfigs.InitNewChallengeConfigs()
    FubenNewChallenge = {}
    for _, v in pairs(FubenChallengeBanners) do
        if v.ShowNewStartTime and v.ShowNewEndTime then
            local timeNow = XTime.GetServerNowTimestamp()
            local startTime = XTime.ParseToTimestamp(v.ShowNewStartTime)
            local endTime = XTime.ParseToTimestamp(v.ShowNewEndTime)
            if endTime and timeNow <= endTime then
                table.insert(FubenNewChallenge, v)
            end
            if startTime > endTime then
                XLog.Error("新挑战活动配置有误，起始时间晚于结束时间，表路径：" .. TABLE_CHALLENGE_BANNER .. " 问题Id :" .. tostring(v.Id))
            end
        end
    end
    return FubenNewChallenge
end

function XFubenConfigs.GetNewChallengeConfigs() -- 获取新挑战玩法数据
    return FubenNewChallenge or XFubenConfigs.InitNewChallengeConfigs()
end

function XFubenConfigs.GetNewChallengeConfigById(id) -- 根据Id取得FubenChallengeBanner配置
    for i in pairs(FubenChallengeBanners) do
        if FubenChallengeBanners[i].Id == id then
            return FubenChallengeBanners[i]
        end
    end
    return nil
end

function XFubenConfigs.GetNewChallengeConfigsLength() -- 获取新活动数量
    local config = XFubenConfigs.GetNewChallengeConfigs()
    return #config
end

function XFubenConfigs.GetNewChallengeFunctionId(index)
    local config = XFubenConfigs.GetNewChallengeConfigs()
    return config[index].FunctionId
end

function XFubenConfigs.GetNewChallengeId(index) -- 根据索引获取新挑战活动的Id
    local config = XFubenConfigs.GetNewChallengeConfigs()
    return config[index].Id
end

function XFubenConfigs.GetNewChallengeStartTimeStamp(index)
    local config = XFubenConfigs.GetNewChallengeConfigs()
    return XTime.ParseToTimestamp(config[index].ShowNewStartTime)
end

function XFubenConfigs.GetNewChallengeEndTimeStamp(index)
    local config = XFubenConfigs.GetNewChallengeConfigs()
    return XTime.ParseToTimestamp(config[index].ShowNewEndTime)
end

function XFubenConfigs.IsNewChallengeStartByIndex(index) -- 根据索引获取新挑战时段是否已经开始
    return XFubenConfigs.GetNewChallengeStartTimeStamp(index) <= XTime.GetServerNowTimestamp()
end

function XFubenConfigs.IsNewChallengeStartById(id) -- 根据挑战活动Id获取新挑战时段是否已经开始
    if not id then return false end
    local cfg = XFubenConfigs.GetNewChallengeConfigById(id)
    if not cfg or not cfg.ShowNewStartTime then return false end
    return XTime.ParseToTimestamp(cfg.ShowNewStartTime) <= XTime.GetServerNowTimestamp()
end

function XFubenConfigs.GetMultiChallengeStageConfigs()
    return MultiChallengeConfigs
end

function XFubenConfigs.GetTableStagePath()
    return TABLE_STAGE
end

--副本上阵角色类型限制相关:
local ROOM_CHARACTER_LIMIT_CONFIGS = {
    [XFubenConfigs.CharacterLimitType.Normal] = {
        Name = CSXTextManagerGetText("CharacterTypeLimitNameNormal"),
        ImageTeamEdit = CSXGameClientConfig:GetString("TeamCharacterTypeNormalLimitImage"),
        ImageSelectCharacter = CSXGameClientConfig:GetString("TeamRequireCharacterNormalImage"),
        TextTeamEdit = CSXTextManagerGetText("TeamCharacterTypeNormalLimitText"),
        TextSelectCharacter = CSXTextManagerGetText("TeamRequireCharacterNormalText"),
        TextChapterLimit = CSXTextManagerGetText("ChapterCharacterTypeLimitNormal"),
        TextTeamEditDefault = CSXTextManagerGetText("TeamCharacterTypeNormalLimitText"),
    },
    [XFubenConfigs.CharacterLimitType.Isomer] = {
        Name = CSXTextManagerGetText("CharacterTypeLimitNameIsomer"),
        ImageTeamEdit = CSXGameClientConfig:GetString("TeamCharacterTypeIsomerLimitImage"),
        ImageSelectCharacter = CSXGameClientConfig:GetString("TeamRequireCharacterIsomerImage"),
        TextTeamEdit = CSXTextManagerGetText("TeamCharacterTypeIsomerLimitText"),
        TextSelectCharacter = CSXTextManagerGetText("TeamRequireCharacterIsomerText"),
        TextChapterLimit = CSXTextManagerGetText("ChapterCharacterTypeLimitIsomer"),
        TextTeamEditDefault = CSXTextManagerGetText("TeamCharacterTypeIsomerLimitText"),
    },
    [XFubenConfigs.CharacterLimitType.IsomerDebuff] = {
        Name = CSXTextManagerGetText("CharacterTypeLimitNameIsomerDebuff"),
        ImageTeamEdit = CSXGameClientConfig:GetString("TeamCharacterTypeIsomerDebuffLimitImage"),
        ImageSelectCharacter = CSXGameClientConfig:GetString("TeamRequireCharacterIsomerDebuffImage"),
        TextTeamEdit = function(buffDict) return CSXTextManagerGetText(buffDict.BuffNoColor) end,
        TextTeamEditDefault = CSXTextManagerGetText("TeamCharacterTypeIsomerDebuffLimitDefaultText"),
        TextSelectCharacter = function(buffDict) return CSXTextManagerGetText(buffDict.BuffWithColor) end,
        TextSelectCharacterDefault = CSXTextManagerGetText("TeamRequireCharacterIsomerDebuffDefaultText"),
        TextChapterLimit = function(buffDes) return CSXTextManagerGetText("ChapterCharacterTypeLimitIsomerDebuff", buffDes) end,
    },
    [XFubenConfigs.CharacterLimitType.NormalDebuff] = {
        Name = CSXTextManagerGetText("CharacterTypeLimitNameNormalDebuff"),
        ImageTeamEdit = CSXGameClientConfig:GetString("TeamCharacterTypeNormalDebuffLimitImage"),
        ImageSelectCharacter = CSXGameClientConfig:GetString("TeamRequireCharacterNormalDebuffImage"),
        TextTeamEdit = function(buffDict) return CSXTextManagerGetText(buffDict.BuffNoColor) end,
        TextTeamEditDefault = CSXTextManagerGetText("TeamCharacterTypeNormalDebuffLimitDefaultText"),
        TextSelectCharacter = function(buffDict) return CSXTextManagerGetText(buffDict.BuffWithColor) end,
        TextSelectCharacterDefault = CSXTextManagerGetText("TeamRequireCharacterNormalDebuffDefaultText"),
        TextChapterLimit = function(buffDes) return CSXTextManagerGetText("ChapterCharacterTypeLimitNormalDebuff", buffDes) end,
    },
}

local function GetStageCharacterLimitConfig(characterLimitType)
    return ROOM_CHARACTER_LIMIT_CONFIGS[characterLimitType]
end

function XFubenConfigs.GetStageCharacterLimitType(stageId)
    return GetStageCfg(stageId).CharacterLimitType
end

function XFubenConfigs.GetStageCareerSuggestTypes(stageId)
    local result = {}
    local content = GetStageCfg(stageId).CareerSuggestType
    if content == nil then return result end
    for _, v in ipairs(string.Split(content, "|")) do
        if v ~= "0" then
            table.insert(result, tonumber(v))
        end
    end
    return result
end

function XFubenConfigs.GetStageAISuggestType(stageId)
    return GetStageCfg(stageId).AISuggestType
end

function XFubenConfigs.GetStageCharacterLimitBuffId(stageId)
    local limitBuffId = GetStageCfg(stageId).LimitBuffId
    return XFubenConfigs.GetLimitShowBuffId(limitBuffId)
end

function XFubenConfigs.GetLimitShowBuffId(limitBuffId)
    local config = StageCharacterLimitBuffConfig[limitBuffId]
    local buffIds = config and config.BuffId
    return buffIds and buffIds[1] or 0
end

function XFubenConfigs.IsStageCharacterLimitConfigExist(characterLimitType)
    return GetStageCharacterLimitConfig(characterLimitType) and true
end

-- 编队界面限制角色类型Icon
function XFubenConfigs.GetStageCharacterLimitImageTeamEdit(characterLimitType)
    local config = GetStageCharacterLimitConfig(characterLimitType)
    if not config then return "" end
    return config.ImageTeamEdit
end

-- 编队界面限制角色类型文本
function XFubenConfigs.GetStageCharacterLimitTextTeamEdit(characterLimitType, characterType, buffId)
    local config = GetStageCharacterLimitConfig(characterLimitType)
    if not config then return "" end

    --local text = config.TextTeamEdit
    local defaultText = config.TextTeamEditDefault
    if not defaultText then
        return ""
    end

    local defaultCharacterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
    if characterType and characterType ~= defaultCharacterType then
        --if type(text) == "function" then
            local buffDes = XFubenConfigs.GetBuffDes(buffId)
            return buffDes
        --end
    else
        return defaultText
    end

    return ""
end

function XFubenConfigs.GetStageMixCharacterLimitTips(characterLimitType, characterTypes, isColorText)
    if isColorText == nil then isColorText = false end
    local config = GetStageCharacterLimitConfig(characterLimitType)
    if not config then return "" end
    local text = isColorText and config.TextSelectCharacter or config.TextTeamEdit
    local defaultText = isColorText and config.TextSelectCharacterDefault or config.TextTeamEditDefault
    local defaultCharacterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
    local diffCount = 0 -- 与建议上阵的差异数量
    local rightCount = 0 -- 对应的数量
    for _, value in ipairs(characterTypes) do
        if value ~= defaultCharacterType then
            diffCount = diffCount + 1
        else
            rightCount = rightCount + 1
        end
    end
    local configDic = XFubenConfigs.GetCharacterLimitBuffDic(characterLimitType)
    if configDic == nil then return defaultText end
    local buffDict = {}
    if configDic[diffCount] and configDic[diffCount][rightCount] then
        buffDict = configDic[diffCount][rightCount]
    end
    if buffDict == nil or XTool.IsTableEmpty(buffDict) then
        return defaultText
    end
    if type(text) == "function" then
        return text(buffDict)
    else
        return defaultText
    end
end

-- 选人界面限制角色类型Icon
function XFubenConfigs.GetStageCharacterLimitImageSelectCharacter(characterLimitType)
    local config = GetStageCharacterLimitConfig(characterLimitType)
    if not config then return "" end
    return config.ImageSelectCharacter
end

-- 选人界面限制角色类型文本
function XFubenConfigs.GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, buffId)
    local config = GetStageCharacterLimitConfig(characterLimitType)
    if not config then return "" end

    --local text = config.TextSelectCharacter
    local defaultText = config.TextSelectCharacterDefault
    if not defaultText then
        return ""
    end

    local defaultCharacterType = XDataCenter.FubenManager.GetDefaultCharacterTypeByCharacterLimitType(characterLimitType)
    if characterType ~= defaultCharacterType then
        --if type(text) == "function" then
        --    if not XTool.IsNumberValid(buffId) then
        --        return defaultText
        --    end

            local buffDes = XFubenConfigs.GetBuffDes(buffId)
            return buffDes
        --end
    else
        return defaultText
    end

    return ""
end

-- 限制角色类型分区名称文本
function XFubenConfigs.GetStageCharacterLimitName(characterLimitType)
    local config = GetStageCharacterLimitConfig(characterLimitType)
    if not config then return "" end
    return config.Name
end

-- 章节选人界面限制角色类型文本
function XFubenConfigs.GetChapterCharacterLimitText(characterLimitType, buffId)
    local config = GetStageCharacterLimitConfig(characterLimitType)
    if not config then return "" end

    local text = config.TextChapterLimit
    if type(text) == "function" then
        local buffDes = XFubenConfigs.GetBuffDes(buffId)
        return text(buffDes)
    end
    return text
end

function XFubenConfigs.IsCharacterFitTeamBuff(teamBuffId, characterId)
    if not teamBuffId or teamBuffId <= 0 then return false end
    if not characterId or characterId <= 0 then return false end

    local config = GetTeamBuffCfg(teamBuffId)

    local initQuality = characterId and characterId > 0 and XMVCA.XCharacter:GetCharMinQuality(characterId)
    if not initQuality or initQuality <= 0 then return false end

    for _, quality in pairs(config.Quality) do
        if initQuality == quality then
            return true
        end
    end

    return false
end

function XFubenConfigs.GetTeamBuffFitCharacterCount(teamBuffId, characterIds)
    local config = GetTeamBuffCfg(teamBuffId)

    local fitCount = 0

    local checkDic = {}
    for _, quality in pairs(config.Quality) do
        checkDic[quality] = true
    end

    for _, characterId in pairs(characterIds) do
        local initQuality = characterId > 0 and XMVCA.XCharacter:GetCharMinQuality(characterId)
        fitCount = checkDic[initQuality] and fitCount + 1 or fitCount
    end

    return fitCount
end

function XFubenConfigs.GetTeamBuffMaxBuffCount(teamBuffId)
    return TeamBuffMaxCountDic[teamBuffId] or 0
end

function XFubenConfigs.GetTeamBuffOnIcon(teamBuffId)
    local config = GetTeamBuffCfg(teamBuffId)
    return config.OnIcon
end

function XFubenConfigs.GetTeamBuffOffIcon(teamBuffId)
    local config = GetTeamBuffCfg(teamBuffId)
    return config.OffIcon
end

function XFubenConfigs.GetTeamBuffTitle(teamBuffId)
    local config = GetTeamBuffCfg(teamBuffId)
    return config.Title
end

function XFubenConfigs.GetTeamBuffDesc(teamBuffId)
    local config = GetTeamBuffCfg(teamBuffId)
    return string.gsub(config.Desc, "\\n", "\n")
end

-- 根据符合初始品质要求的characterId列表获取对应的同调加成buffId
function XFubenConfigs.GetTeamBuffShowBuffId(teamBuffId, characterIds)
    local config = GetTeamBuffCfg(teamBuffId)
    local fitCount = XFubenConfigs.GetTeamBuffFitCharacterCount(teamBuffId, characterIds)
    return config.BuffId[fitCount]
end

-- 根据关卡ID查找关卡词缀列表
function XFubenConfigs.GetStageFightEventByStageId(stageId)
    if not StageFightEvent[stageId] then
        XLog.ErrorTableDataNotFound(
            "XFubenConfigs.GetStageFightEventByStageId",
            "通用关卡词缀数据",
            TABLE_STAGE_FIGHT_EVENT,
            "StageId",
            tostring(stageId)
        )
        return {}
    end
    return StageFightEvent[stageId]
end
-- 根据ID查找词缀详细
function XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(eventId)
    if not StageFightEventDetails[eventId] then
        XLog.ErrorTableDataNotFound(
            "XFubenConfigs.GetStageFightEventDetailsByStageFightEventId",
            "通用关卡词缀数据",
            TABLE_STAGE_FIGHT_EVENT_DETAILS,
            "Id",
            tostring(eventId)
        )
        return nil
    end
    return StageFightEventDetails[eventId]
end

---
--- 获取 失败提示描述 数组
function XFubenConfigs.GetTipDescList(settleLoseTipId)
    local cfg = GetSettleLoseTipCfg(settleLoseTipId)
    return cfg.TipDesc
end

---
--- 获取 失败提示跳转Id 数组
function XFubenConfigs.GetSkipIdList(settleLoseTipId)
    local cfg = GetSettleLoseTipCfg(settleLoseTipId)
    return cfg.SkipId
end

--获取关卡推荐角色类型（构造体/感染体）
function XFubenConfigs.GetStageRecommendCharacterType(stageId)
    local config = StageRecommendConfigs[stageId]
    if not config then return end

    local value = config.CharacterType
    return value ~= 0 and value or nil
end

--获取关卡推荐角色元素属性（物理/火/雷/冰/暗）
function XFubenConfigs.GetStageRecommendCharacterElement(stageId)
    local config = StageRecommendConfigs[stageId]
    if not config then return end

    local value = config.CharacterElement
    return value ~= 0 and value or nil
end

--是否为关卡推荐角色
function XFubenConfigs.IsStageRecommendCharacterType(stageId, Id)
    local characterId = XRobotManager.GetCharacterId(Id)
    local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
    local recommendType = XFubenConfigs.GetStageRecommendCharacterType(stageId)
    local element = XMVCA.XCharacter:GetCharacterElement(characterId)
    local recommendElement = XFubenConfigs.GetStageRecommendCharacterElement(stageId) or 0
    --(废弃)特殊逻辑：如果为授格者，一定是推荐(废弃)
    --if characterType == XCharacterConfigs.CharacterType.Isomer and recommendType == characterType then
    --    return true
    --end

    --为【SP区】优先上阵独域角色
    if (recommendType == XCharacterConfigs.CharacterType.Sp) and 
        (characterType == XCharacterConfigs.CharacterType.Isomer or characterType == XCharacterConfigs.CharacterType.Sp) then
        return true
    end

    --特殊逻辑：当关卡推荐元素为0时推荐所有该角色类型（构造体/授格者）的构造体
    --（此处兼容之前废弃的《授格者一定推荐的特殊逻辑》，StageRecommend配置中的授格者类型下推荐属性都是0，故兼容）
    return XTool.IsNumberValid(recommendType) and
    recommendType == characterType and
    (element == recommendElement or recommendElement == 0)
end

function XFubenConfigs.GetStageName(stageId, ignoreError)
    local config = GetStageCfg(stageId, ignoreError)
    return config and config.Name or ""
end

function XFubenConfigs.GetStageDescription(stageId, ignoreError)
    local config = GetStageCfg(stageId, ignoreError)
    return config and config.Description or ""
end

function XFubenConfigs.GetStageType(stageId)
    local config = GetStageCfg(stageId)
    return config and config.StageType or ""
end

---
--- 关卡图标
function XFubenConfigs.GetStageIcon(stageId)
    local config = GetStageCfg(stageId)
    return (config or {}).Icon
end

---
--- 三星条件描述数组
function XFubenConfigs.GetStarDesc(stageId)
    local config = GetStageCfg(stageId)
    return (config or {}).StarDesc
end

---
--- 关卡首通奖励
function XFubenConfigs.GetFirstRewardShow(stageId)
    local config = GetStageCfg(stageId)
    return (config or {}).FirstRewardShow
end

---
--- 关卡非首通奖励
function XFubenConfigs.GetFinishRewardShow(stageId)
    local config = GetStageCfg(stageId)
    return (config or {}).FinishRewardShow
end

---
--- 获得战前剧情ID
function XFubenConfigs.GetBeginStoryId(stageId)
    local config = GetStageCfg(stageId)
    return (config or {}).BeginStoryId
end

---
--- 获得战后剧情ID
function XFubenConfigs.GetEndStoryId(stageId)
    local config = GetStageCfg(stageId)
    return (config or {}).EndStoryId
end

---
--- 获得前置关卡id
function XFubenConfigs.GetPreStageId(stageId)
    local config = GetStageCfg(stageId)
    return (config or {}).PreStageId
end

function XFubenConfigs.GetStageTypeCfg(stageId)
    local config = StageTypeConfigs[stageId]
    if not config then
        return
    end
    return config
end

---
--- 活动特殊关卡配置机器人列表获取
function XFubenConfigs.GetStageTypeRobot(stageType)
    local config = XFubenConfigs.GetStageTypeCfg(stageType)
    return (config or {}).RobotId
end

function XFubenConfigs.IsAllowRepeatChar(stageType)
    local config = XFubenConfigs.GetStageTypeCfg(stageType)
    return (config or {}).MatchCharIdRepeat
end

function XFubenConfigs.GetCharacterLimitBuffDic(limitType)
    return StageCharacterLimitBuffDic[limitType]
end
-----------------------关卡步骤跳过相关------------------------
function XFubenConfigs.GetStepSkipListByStageId(stageId)
    return StageStepSkipConfigs[stageId] and StageStepSkipConfigs[stageId].SkipStep
end

function XFubenConfigs.CheckStepIsSkip(stageId, stepSkipType)
    local skipList = XFubenConfigs.GetStepSkipListByStageId(stageId)
    for _,skip in pairs(skipList or {}) do
        if skip == stepSkipType then
            return true
        end
    end
    return false
end

--region 暂停界面uiSet，显示可配置的玩法说明
local function GetStageGamePlayDesc(stageType)
    return StageGamePlayDesc[stageType]
end
function XFubenConfigs.HasStageGamePlayDesc(stageType)
    return GetStageGamePlayDesc(stageType) and true or false
end
function XFubenConfigs.GetStageGamePlayBtnVisible(stageType)
    return GetStageGamePlayDesc(stageType)
end
function XFubenConfigs.GetStageGamePlayTitle(stageType)
    if XFubenConfigs.HasStageGamePlayDesc(stageType) then
        return GetStageGamePlayDesc(stageType).Title
    end
end
local StageGamePlayDataSource = false
function XFubenConfigs.GetStageGamePlayDescDataSource(stageType)
    if not StageGamePlayDataSource then
        StageGamePlayDataSource = {}
        for id, cfg in pairs(StageGamePlayDescSheet) do
            local stageType = cfg.StageType
            StageGamePlayDataSource[stageType] = StageGamePlayDataSource[stageType] or {}
            local classified = StageGamePlayDataSource[stageType]
            classified[#classified + 1] = cfg
        end
    end
    return StageGamePlayDataSource[stageType] or {}
end

function XFubenConfigs.GetFubenActivityConfigByManagerName(value)
    local activityConfigs = XFubenConfigs.GetAllConfigs(XFubenConfigs.TableKey.FubenActivity)
    for _, config in ipairs(activityConfigs) do
        if config.ManagerName == value then
            return config
        end
    end
    return {}
end

function XFubenConfigs.GetSecondTagConfigsByFirstTagId(firstTagId)
    local configs = XFubenConfigs.GetAllConfigs(XFubenConfigs.TableKey.FubenSecondTag)
    local result = {}
    for _, config in ipairs(configs) do
        if config.FirstTagId == firstTagId then
            table.insert(result, config)
        end
    end
    table.sort(result, function (tagConfigA, tagConfigB)
        return tagConfigA.Order and tagConfigB.Order and (tagConfigA.Order < tagConfigB.Order)
    end)
    return result
end

function XFubenConfigs.GetSecondTagConfigById(id)
    local configs = XFubenConfigs.GetAllConfigs(XFubenConfigs.TableKey.FubenSecondTag)
    return configs[id]
end

function XFubenConfigs.GetCollegeChapterBannerByType(chapterType)
    local configs = XFubenConfigs.GetAllConfigs(XFubenConfigs.TableKey.FubenCollegeBanner)
    for _, config in ipairs(configs) do
        if config.Type == chapterType then
            return config
        end
    end
end

function XFubenConfigs.GetActivityPanelPrefabPath()
    return XFubenConfigs.GetCfgByIdKey(XFubenConfigs.TableKey.FubenClientConfig, "ActivityPanelPrefab").Values[1]
end

function XFubenConfigs.GetMainPanelTimeId()
    return tonumber(XFubenConfigs.GetCfgByIdKey(XFubenConfigs.TableKey.FubenClientConfig, "MainPanelTimeId").Values[1])
end

function XFubenConfigs.GetMainFestivalBg() -- 覆盖其他二级标签的活动背景图
    return XFubenConfigs.GetCfgByIdKey(XFubenConfigs.TableKey.FubenClientConfig, "MainFestivalBg").Values[1]
end

function XFubenConfigs.GetMainPanelItemId()
    return tonumber(XFubenConfigs.GetCfgByIdKey(XFubenConfigs.TableKey.FubenClientConfig, "MainPanelItemId").Values[1])
end

function XFubenConfigs.GetMainPanelName()
    return XFubenConfigs.GetCfgByIdKey(XFubenConfigs.TableKey.FubenClientConfig, "MainPanelName").Values[1]
end

function XFubenConfigs.GetMain3DBgPrefab()
    return XFubenConfigs.GetCfgByIdKey(XFubenConfigs.TableKey.FubenClientConfig, "Main3DBgPrefab").Values[1]
end

function XFubenConfigs.GetMain3DCameraPrefab()
    return XFubenConfigs.GetCfgByIdKey(XFubenConfigs.TableKey.FubenClientConfig, "Main3DCameraPrefab").Values[1]
end

function XFubenConfigs.GetMainVideoBgUrl()
    return XFubenConfigs.GetCfgByIdKey(XFubenConfigs.TableKey.FubenClientConfig, "MianVideoBgUrl").Values[1]
end

function XFubenConfigs.GetStageSettleWinSoundId()
    return XFubenConfigs.GetCfgByIdKey(XFubenConfigs.TableKey.FubenClientConfig, "StageSettleWinSoundId").Values
end

function XFubenConfigs.GetStageSettleLoseSoundId()
    return XFubenConfigs.GetCfgByIdKey(XFubenConfigs.TableKey.FubenClientConfig, "StageSettleLoseSoundId").Values
end

function XFubenConfigs.GetQxmsTryIcon()
    return XFubenConfigs.GetCfgByIdKey(XFubenConfigs.TableKey.FubenClientConfig, "UiFubenQxmsTryIcon").Values[1]
end

function XFubenConfigs.GetQxmsUseIcon()
    return XFubenConfigs.GetCfgByIdKey(XFubenConfigs.TableKey.FubenClientConfig, "UiFubenQxmsUseIcon").Values[1]
end

function XFubenConfigs.GetChallengeShowGridCount()
    return tonumber(XFubenConfigs.GetCfgByIdKey(XFubenConfigs.TableKey.FubenClientConfig, "ChallengeShowGridCount").Values[1])
end

function XFubenConfigs.GetChallengeShowGridList()
    local result = {}
    for i, value in ipairs(XFubenConfigs.GetCfgByIdKey(XFubenConfigs.TableKey.FubenClientConfig, "ChallengeShowGridList").Values) do
        result[#result + 1] = tonumber(value)
    end
    --Debug 代码
    --result = {
    --    XFubenConfigs.ChapterType.BossSingle,
    --    XFubenConfigs.ChapterType.ARENA,
    --    XFubenConfigs.ChapterType.Stronghold,
    --    XFubenConfigs.ChapterType.BiancaTheatre,
    --    XFubenConfigs.ChapterType.Theatre,
    --    XFubenConfigs.ChapterType.Transfinite
    --}
    return result
end

-- 判断副本主界面是否是用3D场景
function XFubenConfigs.GetIsMainHave3DBg()
    return not string.IsNilOrEmpty(XFubenConfigs.GetMain3DBgPrefab())
end

-- 判断副本主界面是否是用视频背景
function XFubenConfigs.GetIsMainHaveVideoBg()
    return not string.IsNilOrEmpty(XFubenConfigs.GetMainVideoBgUrl())
end

--endregion

function XFubenConfigs.GetSettleSpecialSoundCfgByStageId(stageId)
    local config = StageSettleSpecialSoundCfg[stageId]
    return config or {}
end
