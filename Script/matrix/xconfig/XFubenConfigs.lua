local CSXGameClientConfig = CS.XGame.ClientConfig

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
    StageVoiceTip = { ReadKeyName = "StageId", DirType = XConfigCenter.DirectoryType.Client },
})

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
    NewYearLuck = 61, --春节奖券小游戏
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
    Festival = 75, -- 活动记录
    ShortStory = 76, -- 浮点纪实
    Prequel = 77, -- 间章旧闻
    CharacterFragment = 78, -- 角色碎片
    Activity = 79, -- 活动归纳整理
    Course = 80, -- v1.30 考级
    BiancaTheatre = 81, --肉鸽2.0
    Rift = 82, --战双大秘境
    CharacterTower = 83, --本我回廊（角色塔）
    ColorTable = 84, -- 调色板战争
    BrilliantWalk = 85, --光辉同行
    DlcHunt = 86, -- Dlc
    Maverick2 = 87, -- 异构阵线2.0
    Maze = 88, -- 情人节活动2023
    PlanetRunning = 89,
    CerberusGame = 90,
    Transfinite = 91, -- 超限连战
    Theatre3 = 92, -- 肉鸽3.0
}

function XFubenConfigs.Init()
end

function XFubenConfigs.GetStageCfgs()
    return XMVCA.XFuben:GetStageCfgs()
end

function XFubenConfigs.GetBuffDes(buffId)
    return XMVCA.XFuben:GetBuffDes(buffId)
end

function XFubenConfigs.GetStageLevelControlCfg()
    return XMVCA.XFuben:GetStageLevelControlCfg()
end

function XFubenConfigs.GetStageMultiplayerLevelControlCfg()
    return XMVCA.XFuben:GetStageMultiplayerLevelControlCfg()
end

function XFubenConfigs.GetStageMultiplayerLevelControlCfgById(id)
    return XMVCA.XFuben:GetStageMultiplayerLevelControlCfgById(id)
end

function XFubenConfigs.GetStageTransformCfg()
    return XMVCA.XFuben:GetStageTransformCfg()
end

function XFubenConfigs.GetFlopRewardTemplates()
    return XMVCA.XFuben:GetFlopRewardTemplates()
end

function XFubenConfigs.GetActivitySortRules()
    return XMVCA.XFuben:GetActivitySortRules()
end

function XFubenConfigs.GetFeaturesById(id)
    return XMVCA.XFuben:GetFeaturesById(id)
end

function XFubenConfigs.GetActivityPriorityByActivityIdAndType(activityId, type)
    return XMVCA.XFuben:GetActivityPriorityByActivityIdAndType(activityId, type)
end

function XFubenConfigs.GetStageFightControl(id)
    return XMVCA.XFuben:GetStageFightControl(id)
end

function XFubenConfigs.IsKeepPlayingStory(stageId)
    return XMVCA.XFuben:IsKeepPlayingStory(stageId)
end

function XFubenConfigs.GetChapterBannerByType(bannerType)
    return XMVCA.XFuben:GetChapterBannerByType(bannerType)
end

function XFubenConfigs.InitNewChallengeConfigs()
    return XMVCA.XFuben:InitNewChallengeConfigs()
end

function XFubenConfigs.GetNewChallengeConfigs()
    -- 获取新挑战玩法数据
    return XMVCA.XFuben:GetNewChallengeConfigs()
end

function XFubenConfigs.GetNewChallengeConfigById(id)
    -- 根据Id取得FubenChallengeBanner配置
    return XMVCA.XFuben:GetNewChallengeConfigById(id)
end

function XFubenConfigs.GetNewChallengeConfigsLength()
    -- 获取新活动数量
    return XMVCA.XFuben:GetNewChallengeConfigsLength()
end

function XFubenConfigs.GetNewChallengeFunctionId(index)
    return XMVCA.XFuben:GetNewChallengeFunctionId(index)
end

function XFubenConfigs.GetNewChallengeId(index)
    -- 根据索引获取新挑战活动的Id
    return XMVCA.XFuben:GetNewChallengeId(index)
end

function XFubenConfigs.GetNewChallengeStartTimeStamp(index)
    return XMVCA.XFuben:GetNewChallengeStartTimeStamp(index)
end

function XFubenConfigs.GetNewChallengeEndTimeStamp(index)
    return XMVCA.XFuben:GetNewChallengeEndTimeStamp(index)
end

function XFubenConfigs.IsNewChallengeStartByIndex(index)
    -- 根据索引获取新挑战时段是否已经开始
    return XMVCA.XFuben:IsNewChallengeStartByIndex(index)
end

function XFubenConfigs.IsNewChallengeStartById(id)
    -- 根据挑战活动Id获取新挑战时段是否已经开始
    return XMVCA.XFuben:IsNewChallengeStartById(id)
end

function XFubenConfigs.GetMultiChallengeStageConfigs()
    return XMVCA.XFuben:GetMultiChallengeStageConfigs()
end

function XFubenConfigs.GetTableStagePath()
    return XMVCA.XFuben:GetTableStagePath()
end

function XFubenConfigs.GetStageCharacterLimitType(stageId)
    return XMVCA.XFuben:GetStageCharacterLimitType(stageId)
end

function XFubenConfigs.GetStageCareerSuggestTypes(stageId)
    return XMVCA.XFuben:GetStageCareerSuggestTypes(stageId)
end

function XFubenConfigs.GetStageAISuggestType(stageId)
    return XMVCA.XFuben:GetStageAISuggestType(stageId)
end

function XFubenConfigs.GetStageCharacterLimitBuffId(stageId)
    return XMVCA.XFuben:GetStageCharacterLimitBuffId(stageId)
end

function XFubenConfigs.GetLimitShowBuffId(limitBuffId)
    return XMVCA.XFuben:GetLimitShowBuffId(limitBuffId)
end

function XFubenConfigs.IsStageCharacterLimitConfigExist(characterLimitType)
    return XMVCA.XFuben:IsStageCharacterLimitConfigExist(characterLimitType)
end

function XFubenConfigs.GetStageCharacterLimitImageTeamEdit(characterLimitType)
    return XMVCA.XFuben:GetStageCharacterLimitImageTeamEdit(characterLimitType)
end

function XFubenConfigs.GetStageCharacterLimitTextTeamEdit(characterLimitType, characterType, buffId)
    return XMVCA.XFuben:GetStageCharacterLimitTextTeamEdit(characterLimitType, characterType, buffId)
end

function XFubenConfigs.GetStageMixCharacterLimitTips(characterLimitType, characterTypes, isColorText)
    return XMVCA.XFuben:GetStageMixCharacterLimitTips(characterLimitType, characterTypes, isColorText)
end

function XFubenConfigs.GetStageCharacterLimitImageSelectCharacter(characterLimitType)
    return XMVCA.XFuben:GetStageCharacterLimitImageSelectCharacter(characterLimitType)
end

function XFubenConfigs.GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, buffId)
    return XMVCA.XFuben:GetStageCharacterLimitTextSelectCharacter(characterLimitType, characterType, buffId)
end

function XFubenConfigs.GetStageCharacterLimitName(characterLimitType)
    return XMVCA.XFuben:GetStageCharacterLimitName(characterLimitType)
end

function XFubenConfigs.GetChapterCharacterLimitText(characterLimitType, buffId)
    return XMVCA.XFuben:GetChapterCharacterLimitText(characterLimitType, buffId)
end

function XFubenConfigs.IsCharacterFitTeamBuff(teamBuffId, characterId)
    return XMVCA.XFuben:IsCharacterFitTeamBuff(teamBuffId, characterId)
end

function XFubenConfigs.GetTeamBuffFitCharacterCount(teamBuffId, characterIds)
    return XMVCA.XFuben:GetTeamBuffFitCharacterCount(teamBuffId, characterIds)
end

function XFubenConfigs.GetTeamBuffMaxBuffCount(teamBuffId)
    return XMVCA.XFuben:GetTeamBuffMaxBuffCount(teamBuffId)
end

function XFubenConfigs.GetTeamBuffOnIcon(teamBuffId)
    return XMVCA.XFuben:GetTeamBuffOnIcon(teamBuffId)
end

function XFubenConfigs.GetTeamBuffOffIcon(teamBuffId)
    return XMVCA.XFuben:GetTeamBuffOffIcon(teamBuffId)
end

function XFubenConfigs.GetTeamBuffTitle(teamBuffId)
    return XMVCA.XFuben:GetTeamBuffTitle(teamBuffId)
end

function XFubenConfigs.GetTeamBuffDesc(teamBuffId)
    return XMVCA.XFuben:GetTeamBuffDesc(teamBuffId)
end

function XFubenConfigs.GetTeamBuffShowBuffId(teamBuffId, characterIds)
    return XMVCA.XFuben:GetTeamBuffShowBuffId(teamBuffId, characterIds)
end

function XFubenConfigs.GetStageFightEventByStageId(stageId)
    return XMVCA.XFuben:GetStageFightEventByStageId(stageId)
end

function XFubenConfigs.GetStageFightEventDetailsByStageFightEventId(eventId)
    return XMVCA.XFuben:GetStageFightEventDetailsByStageFightEventId(eventId)
end

function XFubenConfigs.GetTipDescList(settleLoseTipId)
    return XMVCA.XFuben:GetTipDescList(settleLoseTipId)
end

function XFubenConfigs.GetSkipIdList(settleLoseTipId)
    return XMVCA.XFuben:GetSkipIdList(settleLoseTipId)
end

function XFubenConfigs.GetStageRecommendCharacterType(stageId)
    return XMVCA.XFuben:GetStageRecommendCharacterType(stageId)
end

function XFubenConfigs.GetStageRecommendCharacterElement(stageId)
    return XMVCA.XFuben:GetStageRecommendCharacterElement(stageId)
end

function XFubenConfigs.IsStageRecommendCharacterType(stageId, id)
    return XMVCA.XFuben:IsStageRecommendCharacterType(stageId, id)
end

function XFubenConfigs.GetStageName(stageId, ignoreError)
    return XMVCA.XFuben:GetStageName(stageId, ignoreError)
end

function XFubenConfigs.GetStageDescription(stageId, ignoreError)
    return XMVCA.XFuben:GetStageDescription(stageId, ignoreError)
end

function XFubenConfigs.GetStageMainlineType(stageId)
    return XMVCA.XFuben:GetStageMainlineType(stageId)
end

function XFubenConfigs.GetStageIcon(stageId)
    return XMVCA.XFuben:GetStageIcon(stageId)
end

function XFubenConfigs.GetStarDesc(stageId)
    return XMVCA.XFuben:GetStarDesc(stageId)
end

function XFubenConfigs.GetFirstRewardShow(stageId)
    return XMVCA.XFuben:GetFirstRewardShow(stageId)
end

function XFubenConfigs.GetFinishRewardShow(stageId)
    return XMVCA.XFuben:GetFinishRewardShow(stageId)
end

function XFubenConfigs.GetBeginStoryId(stageId)
    return XMVCA.XFuben:GetBeginStoryId(stageId)
end

function XFubenConfigs.GetEndStoryId(stageId)
    return XMVCA.XFuben:GetEndStoryId(stageId)
end

function XFubenConfigs.GetPreStageId(stageId)
    return XMVCA.XFuben:GetPreStageId(stageId)
end

function XFubenConfigs.GetStageTypeCfg(stageId)
    return XMVCA.XFuben:GetStageTypeCfg(stageId)
end

function XFubenConfigs.GetStageTypeRobot(stageType)
    return XMVCA.XFuben:GetStageTypeRobot(stageType)
end

function XFubenConfigs.IsAllowRepeatChar(stageType)
    return XMVCA.XFuben:IsAllowRepeatChar(stageType)
end

function XFubenConfigs.GetCharacterLimitBuffDic(limitType)
    return XMVCA.XFuben:GetCharacterLimitBuffDic(limitType)
end

function XFubenConfigs.GetStepSkipListByStageId(stageId)
    return XMVCA.XFuben:GetStepSkipListByStageId(stageId)
end

function XFubenConfigs.CheckStepIsSkip(stageId, stepSkipType)
    return XMVCA.XFuben:CheckStepIsSkip(stageId, stepSkipType)
end

function XFubenConfigs.HasStageGamePlayDesc(stageType)
    return XMVCA.XFuben:HasStageGamePlayDesc(stageType)
end

function XFubenConfigs.GetStageGamePlayBtnVisible(stageType)
    return XMVCA.XFuben:GetStageGamePlayBtnVisible(stageType)
end

function XFubenConfigs.GetStageGamePlayTitle(stageType)
    return XMVCA.XFuben:GetStageGamePlayTitle(stageType)
end

function XFubenConfigs.GetStageGamePlayDescDataSource(stageType)
    return XMVCA.XFuben:GetStageGamePlayDescDataSource(stageType)
end

function XFubenConfigs.GetFubenActivityConfigByManagerName(managerName)
    return XMVCA.XFuben:GetFubenActivityConfigByManagerName(managerName)
end

function XFubenConfigs.GetSecondTagConfigsByFirstTagId(firstTagId)
    return XMVCA.XFuben:GetSecondTagConfigsByFirstTagId(firstTagId)
end

function XFubenConfigs.GetSecondTagConfigById(id)
    return XMVCA.XFuben:GetSecondTagConfigById(id)
end

function XFubenConfigs.GetCollegeChapterBannerByType(chapterType)
    return XMVCA.XFuben:GetCollegeChapterBannerByType(chapterType)
end

function XFubenConfigs.GetActivityPanelPrefabPath()
    return XMVCA.XFuben:GetActivityPanelPrefabPath()
end

function XFubenConfigs.GetMainPanelTimeId()
    return XMVCA.XFuben:GetMainPanelTimeId()
end

function XFubenConfigs.GetMainFestivalBg()
    -- 覆盖其他二级标签的活动背景图
    return XMVCA.XFuben:GetMainFestivalBg()
end

function XFubenConfigs.GetMainPanelItemId()
    return XMVCA.XFuben:GetMainPanelItemId()
end

function XFubenConfigs.GetMainPanelName()
    return XMVCA.XFuben:GetMainPanelName()
end

function XFubenConfigs.GetMain3DBgPrefab()
    return XMVCA.XFuben:GetMain3DBgPrefab()
end

function XFubenConfigs.GetMain3DCameraPrefab()
    return XMVCA.XFuben:GetMain3DCameraPrefab()
end

function XFubenConfigs.GetMainVideoBgUrl()
    return XMVCA.XFuben:GetMainVideoBgUrl()
end

function XFubenConfigs.GetStageSettleWinSoundId()
    return XMVCA.XFuben:GetStageSettleWinSoundId()
end

function XFubenConfigs.GetStageSettleLoseSoundId()
    return XMVCA.XFuben:GetStageSettleLoseSoundId()
end

function XFubenConfigs.GetQxmsTryIcon()
    return XMVCA.XFuben:GetQxmsTryIcon()
end

function XFubenConfigs.GetQxmsUseIcon()
    return XMVCA.XFuben:GetQxmsUseIcon()
end

function XFubenConfigs.GetChallengeShowGridCount()
    return XMVCA.XFuben:GetChallengeShowGridCount()
end

function XFubenConfigs.GetChallengeShowGridList()
    return XMVCA.XFuben:GetChallengeShowGridList()
end

function XFubenConfigs.GetIsMainHave3DBg()
    return XMVCA.XFuben:GetIsMainHave3DBg()
end

function XFubenConfigs.GetIsMainHaveVideoBg()
    return XMVCA.XFuben:GetIsMainHaveVideoBg()
end

function XFubenConfigs.GetSettleSpecialSoundCfgByStageId(stageId)
    return XMVCA.XFuben:GetSettleSpecialSoundCfgByStageId(stageId)
end
-- abandon ~~~~~~~~~~~~~~~~~
-- 此文件即将被抛弃