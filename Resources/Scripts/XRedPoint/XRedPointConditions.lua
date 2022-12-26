XRedPointConditionGroup = require("XRedPoint/XRedPointConditionGroup")
XRedPointEvent = require("XRedPoint/XRedPointEvent")
XRedPointListener = require("XRedPoint/XRedPointListener")
XRedPointEventElement = require("XRedPoint/XRedPointEventElement")

XRedPointConditions = XRedPointConditions or {}
XRedPointConditions.Conditions = {
    --角色界面红点相关UiCharacter-----------------------------------------------
    CONDITION_CHARACTER        = "XRedPointConditionCharacter", --角色列表红点，培养
    CONDITION_CHARACTER_GRADE    = "XRedPointConditionCharacterGrade", --晋升标签
    CONDITION_CHARACTER_QUALITY = "XRedPointConditionCharacterQuality", --升品标签
    CONDITION_CHARACTER_SKILL    = "XRedPointConditionCharacterSkill", --技能标签
    CONDITION_CHARACTER_LEVEL    = "XRedPointConditionCharacterLevel", --升级标签
    CONDITION_CHARACTER_UNLOCK = "XRedPointConditionCharacterUnlock", --解锁

    --好友红点相关 UiSocial-----------------------------------------------
    CONDITION_FRIEND_WAITPASS    = "XRedPointConditionFriendWaitPass", --等待通过
    CONDITION_FRIEND_CONTACT    = "XRedPointConditionFriendContact", --私聊信息标签
    CONDITION_FRIEND_CHAT_PRIVATE = "XRedPointConditionFriendChatPrivate", --个人私聊信息

    --邮件红点相关 UiMail-----------------------------------------------
    CONDITION_MAIL_PERSONAL    = "XRedPointConditionMailPersonal", --邮件

    --主界面红点相关 UiMain-----------------------------------------------
    CONDITION_MAIN_MEMBER        = "XRedPointConditionMainMember", --成员
    CONDITION_MAIN_FRIEND        = "XRedPointConditionMainFriend", --好友
    CONDITION_MAIN_NOTICE        = "XRedPointConditionMainNotice", --活动系统
    CONDITION_MAIN_MAIL        = "XRedPointConditionMainMail", --邮件
    CONDITION_MAIN_SET        = "XRedPointConditionMainSet", --设置
    CONDITION_MAIN_NEWPLAYER_TASK = "XRedPointConditionMainNewPlayerTask", --新手任务
    CONDITION_MAIN_TASK        = "XRedPointConditionMainTask", --任务
    CONDITION_MAIN_CHAPTER        = "XRedPointConditionMainChapter", --主线副本
    CONDITION_BASEEQUIP        = "XRedPointConditionBaseEquip", --基地装备
    CONDITION_MAIN_DISPATCH    = "XRedPointConditionMainDispatch", --派遣
    CONDITION_MAIN_SPECIAL_SHOP = "XRedPointConditionMainSpecialShop", -- 特殊商店

    --玩家红点相关 UiPlayer-----------------------------------------------
    CONDITION_PLAYER_SETNAME = "XRedPointConditionPlayerSetName",
    CONDITION_PLAYER_ACHIEVE    = "XRedPointConditionPlayerAchieve", --成就标签
    CONDITION_PLAYER_ACHIEVE_TYPE    = "XRedPointConditionPlayerAchieveType", --各类型成就标签

    -- 聊天红点相关 UiChatServeMain----------------------------------------
    CONDITION_RECEIVE_CHAT = "XRedPointConditionReceiveChat", -- 接收到消息

    --玩家任务红点相关 UiTask-----------------------------------------------
    CONDITION_TASK_TYPE    = "XRedPointConditionTaskType", --是否有对应类型的任务奖励
    CONDITION_TASK_COURSE    = "XRedPointConditionTaskCourse", --是否有历程任务奖励
    CONDITION_TASK_WEEK_ACTIVE    = "XRedPointConditionTaskWeekActive", --是否有周活跃任务奖励
    CONDITION_TASK_LIMIT_TYPE = "XRedPointConditionTaskLimited",
    --赏金任务
    CONDITION_BOUNTYTASK    = "XRedPointConditionBountyTask", --是否有赏金任务奖励
    --竞技
    CONDITION_ARENA_APPLY = "XRedPointConditionArenaApply", --是否有申请数据

    --玩家章节红点相关 UiFuBen-----------------------------------------------
    CONDITION_MAINLINE_CHAPTER_REWARD    = "XRedPointConditionChapterReward", --是否有主线章节进度奖励(包括收集进度与周目挑战任务)
    CONDITION_BFRT_CHAPTER_REWARD    = "XRedPointConditionBfrtChapterReward", --是否有据点战章节进度奖励
    CONDITION_CHALLEGE_NEW = "XRedPointConditionNewChallenge", --是否有在版本新玩法出现后点击过挑战页签
    CONDITION_EXTRA_CHAPTER_REWARD = "XRedPointConditionExtraChapterReward", --是否有番外章节进度奖励(包括收集进度与周目挑战任务)

    CONDITION_ZHOUMU_TASK = "XRedPointConditionZhouMuTask", -- 是否有周目任务奖励
    CONDITION_MAINLINE_TREASURE = "XRedPointConditionMainLineTreasure", -- 是否有主线收集进度
    CONDITION_EXTRA_TREASURE = "XRedPointConditionExtraTreasure", -- 是否有外篇收集进度
    CONDITION_NEWCHARACT_TREASURE = "XRedPointConditionNewCharActTreasure", -- 是否有新角色教学关卡收集进度

    CONDITION_EXPERIMENT_CHAPTER_REWARD = "XRedPointConditionExperimentChapterReward", -- 试玩关章节是否有未领取奖励
    CONDITION_EXPERIMENT_RED = "XRedPointConditionExperimentRed", -- 副本界面试玩关红点条件

    -- 好感度
    CONDITION_FAVORABILITY_RED = "XRedPointConditionFavorability", --好感度红点
    CONDITION_FAVORABILITY_DOCUMENT = "XRedPointConditionFavorabilityDocument", --好感度-档案
    CONDITION_FAVORABILITY_DOCUMENT_INFO = "XRedPointConditionFavorabilityInfo", --好感度-档案-资料
    CONDITION_FAVORABILITY_DOCUMENT_RUMOR = "XRedPointConditionFavorabilityRumor", --好感度-档案-异闻
    CONDITION_FAVORABILITY_DOCUMENT_AUDIO = "XRedPointConditionFavorabilityAudio", --好感度-档案-语音
    CONDITION_FAVORABILITY_DOCUMENT_ACTION = "XRedPointConditionFavorabilityAction", --好感度-档案-动作
    CONDITION_FAVORABILITY_PLOT = "XRedPointConditionFavorabilityPlot", --好感度-剧情
    CONDITION_FAVORABILITY_GIFT = "XRedPointConditionFavorabilityGift", --好感度-礼物
    -- 试炼
    CONDITION_TRIAL_RED = "XRedPointConditionTrial", --试炼关卡奖励
    CONDITION_TRIAL_REWARD_RED = "XRedPointConditionTrialReward", --试炼关卡奖励
    CONDITION_TRIAL_UNLOCK_RED = "XRedPointConditionTrialUnlock", --试炼关卡解锁

    -- 探索
    CONDITION_EXPLORE_REWARD = "XRedPointConditionExplore", --是否有探索奖励可领取

    -- 驻守玩法
    CONDITION_ASSIGN_REWARD = "XRedPointConditionAssign", --是否有驻守副本奖励可领取

    --竞技
    CONDITION_ARENA_MAIN_TASK = "XRedPointConditionArenaTask", --竞技战区任务

    --展示厅
    CONDITION_EXHIBITION_NEW = "XRedPointConditionExhibitionNew", --构造展示厅奖励可领取

    --活动系统
    CONDITION_ACTIVITY_NEW_ACTIVITIES = "XRedPointConditionActivityNewAcitivies", --活动系统-新活动
    CONDITION_ACTIVITY_NEW_NOTICES = "XRedPointConditionActivityNewNotices", --活动系统-新公告
    CONDITION_ACTIVITY_NEW_ACTIVITY_NOTICES = "XRedPointConditionActivityNewActivityNotices", --活动系统-新活动公告
    CONDITION_ACTIVITY_NEW_ACTIVITIES_TOGS = "XRedPointConditionActivityNewAcitiviesTogs", --活动系统-新活动的标签按钮红点
    -- 运营相关
    CONDITION_SUBMENU_NEW_NOTICES = "XRedPointConditionSubMenuNewNotices", -- 主界面二级菜单-新按钮

    --单机Boss奖励
    CONDITION_BOSS_SINGLE_REWARD = "XRedPointConditionBossSingleReward", --单机Boss奖励领取

    --充值
    CONDITION_PURCHASE_RED = "XRedPointConditionPurchase",
    CONDITION_PURCHASE_LB_RED = "XRedPointConditionPurchaseLB",
    CONDITION_PURCHASE_GET_RERARGE = "XRedPointConditionGetFirstRecharge", -- 是否有首充奖励领取
    CONDITION_PURCHASE_GET_CARD = "XRedPointConditionGetCard", -- 是否有月卡奖励领取
    CONDITION_NEWYEARDIVINING_NOTGET = "XRedPointConditionNewYearDiviningNotGet",
    CONDITION_ACCUMULATE_PAY_RED = "XRedPointConditionPurchaseAccumulate", -- 是否有累计奖励领取
    --宿舍红点
    CONDITION_DORM_RED = "XRedPointConditionDormRed", -- 宿舍红点
    CONDITION_DORM_TASK = "XRedPointConditionDormTaskType", -- 是否有奖励领取
    CONDITION_FURNITURE_CREATE = "XRedPointConditionFurnitureCreate", --是否有家具可以领取
    CONDITION_DORM_WORK_RED = "XRedPointConditionDormWork", -- 宿舍打工
    CONDITION_DORM_MAIN_TASK_RED = "XRedPointConditionDormMainTaskRed", -- 是否有奖励领取(宿舍主界面)

    --研究红点
    CONDITION_ACTIVITYDRAW_RED = "XRedPointConditionActivityDrawNew", -- 研究活动卡池红点

    --头像红点
    CONDITION_HEADPORTRAIT_RED = "XRedPointConditionHeadPortraitNew",
    --勋章红点
    CONDITION_MEDAL_RED = "XRedPointConditionMedalNew",

    --活动简介红点
    CONDITION_ACTIVITY_BRIRF_TASK_FINISHED = "XRedPointConditionActivityBriefTaskFinished", --活动简介任务完成

    --复刷关奖励红点
    CONDITION_REPEAT_CHALLENGE_REWARD = "XRedPointConditionRepeatChallengeReward", --是否有复刷关奖励
    CONDITION_REPEAT_CHALLENGE_CHAPTER_REWARD = "XRedPointConditionRepeatChallengeChapterReward", --是否有复刷关章节进度奖励

    --图鉴红点相关
    CONDITION_ARCHIVE_WEAPON = "XRedPointConditionArchiveWeapon",
    CONDITION_ARCHIVE_AWARENESS = "XRedPointConditionArchiveAwareness",

    CONDITION_ARCHIVE_WEAPON_NEW_TAG = "XRedPointConditionArchiveWeaponNewTag", --一级界面是否解锁了新武器
    CONDITION_ARCHIVE_WEAPON_GRID_NEW_TAG = "XRedPointConditionArchiveWeaponGridNewTag", --一级界面格子中是否解锁了新武器
    CONDITION_ARCHIVE_WEAPON_SETTING_RED = "XRedPointConditionArchiveWeaponSettingUnlock", --是否解锁了新武器设定

    CONDITION_ARCHIVE_AWARENESS_NEW_TAG = "XRedPointConditionArchiveAwarenessNewTag", --一级界面是否解锁了新意识
    CONDITION_ARCHIVE_AWARENESS_GRID_NEW_TAG = "XRedPointConditionArchiveAwarenessGridNewTag", --一级界面格子中是否解锁了新意识
    CONDITION_ARCHIVE_AWARENESS_SETTING_RED = "XRedPointConditionArchiveAwarenessSettingUnlock", --是否解锁了新意识设定

    CONDITION_ARCHIVE_MONSTER_ALL = "XRedPointConditionArchiveMonsterAll", --全部类型中是否有新怪或怪的新属性
    CONDITION_ARCHIVE_MONSTER_TYPE_RED = "XRedPointConditionArchiveMonsterTypeRed", --某种类型中是否有新怪或怪的新属性
    CONDITION_ARCHIVE_MONSTER_TYPE_TAG = "XRedPointConditionArchiveMonsterTypeTag", --某种类型中是否有新怪或怪的新属性
    CONDITION_ARCHIVE_MONSTER_RED = "XRedPointConditionArchiveMonsterRed", --是否有具体新怪
    CONDITION_ARCHIVE_MONSTER_TAG = "XRedPointConditionArchiveMonsterTag", --是否有具体新怪
    CONDITION_ARCHIVE_MONSTER_INFO = "XRedPointConditionArchiveMonsterInfo", --是否有新怪信息
    CONDITION_ARCHIVE_MONSTER_SKILL = "XRedPointConditionArchiveMonsterSkill", --是否有新怪技能
    CONDITION_ARCHIVE_MONSTER_SETTING = "XRedPointConditionArchiveMonsterSetting", --是否有新怪设定

    CONDITION_ARCHIVE_CG_ALL = "XRedPointConditionArchiveCGAll", --全部类型中是否有新CG
    CONDITION_ARCHIVE_CG_TYPE_RED = "XRedPointConditionArchiveCGTypeRed", --某种类型中是否有新CG
    CONDITION_ARCHIVE_CG_RED = "XRedPointConditionArchiveCGRed", --是否有具体新CG

    --活动简介红点
    CONDITION_PIC_COMPOSITION_TASK_FINISHED = "XRedPointConditionPicCompositionTaskFinished", --看图作文任务完成
    CONDITION_WINDOWS_COMPOSITION_DAILY = "XRedPointConditionWindowsInlay", --内嵌浏览器每日红点
    --回归活动红点相关
    CONDITION_REGRESSION = "XRedPointConditionRegression", --回归活动（回归任务等后续任务）
    CONDITION_REGRESSION_TASK_TYPE = "XRedPointConditionRegressionTaskType", --回归活动子类型任务（历程、每日、每天）
    CONDITION_REGRESSION_TASK = "XRedPointConditionRegressionTask", --回归活动任务（历程、每日、每天、进度奖励）

    -- 公会相关红点
    CONDITION_GUILD_MEMBER = "XRedPointConditionGuildMember", --公会成员相关红点
    CONDITION_GUILD_INFO = "XRedPointConditionGuildInformation", --公会主界面信息红点
    CONDITION_GUILD_APPLYLIST = "XRedPointConditionGuildApplyList", --公会招募红点
    CONDITION_GUILD_ACTIVEGIFT = "XRedPointConditionGuildActiveGift", --公会活跃度礼包红点
    CONDITION_GUILD_CHALLENGE = "XRedPointConditionGuildChallenge", --公会挑战红点
    CONDITION_GUILD_NEWS = "XRedPointConditionUnGuildNews", --未加入公会收到消息红点

    -- 工会boss相关红点
    CONDITION_GUILDBOSS_BOSSHP = "XRedPointConditionGuildBossHp", --有工会bosshp宝箱可以领取
    CONDITION_GUILDBOSS_SCORE = "XRedPointConditionGuildBossScore", --有工会boss积分宝箱可以领取

    -- 主干探索玩法相关红点
    CONDITION_EXPLORE_ITEM_GET = "XRedPointConditionMainLineExploreItem", --获取新探索道具
    CONDITION_EXTRA_EXPLORE_ITEM_GET = "XRedPointConditionExtraChapterExploreItem", --番外获取新探索道具

    -- 副本补给商店相关红点
    CONDITION_FUBEN_DAILY_SHOP = "XRedPointConditionFubenDailyShop", --副本补给商店新套装红点

    --水上乐园相关红点
    CONDITION_ACTIVITY_NEW_MAINENTRY = "XRedPointConditionBriefEntry", --Brief活动入口处红点
    CONDITION_ACTIVITY_NEW_ILLUSTRATEDHANDBOOK = "XRedPointConditionShortStory", --短篇故事新开启

    --虚像地平线相关红点
    CONDITION_EXPEDITION_CAN_RECRUIT = "XRedPointConditionExpeditionRecruit", --活动入口处红点
    --世界boss相关红点
    CONDITION_WORLDBOSS_RED = "XRedPointConditionWorldBossRed", --活动入口处红点

    -- 点消小游戏红点
    CONDITION_FUBEN_CLICKCLEARGAME_RED = "XRedPointConditionFuBenClickClearGameRed", --中元节点消小游戏副本入口红点
    CONDITION_CLICKCLEARGAME_DIFFICULT_UNLOCK = "XRedPointConditionClickClearDifficultUnlock", -- 点消小游戏难度红点
    CONDITION_CLICKCLEARGAME_REWARD = "XRedPointConditionClickClearReward", -- 点消小游戏奖励红点

    -- 预热关拼图游戏红点
    CONDITION_FUBEN_DRAGPUZZLEGAME_RED = "XRedPointConditionFuBenDragPuzzleGameRed", --预热关拼图小游戏副本入口红点
    CONDITION_DRAG_PUZZLE_GAME_SWITCH = "XRedPointConditionDragPuzzleSwitch", -- 转换碎片按钮红点
    CONDITION_DRAG_PUZZLE_GAME_AWARD = "XRedPointConditionDragPuzzleAward", -- 奖励红点
    CONDITION_DRAG_PUZZLE_GAME_VIDEO = "XRedPointConditionDragPuzzleVideo", -- 播放剧情红点
    CONDITION_DRAG_PUZZLE_GAME_TAB = "XRedPointConditionDragPuzzleTab", -- 关卡标题红点
    CONDITION_DRAG_PUZZLE_GAME_DECRYPTION = "XRedPointConditionDragPuzzleDecryption", -- 解密红点（特效）

    -- 圣诞树装饰小游戏红点
    CONDITION_CHRISTMAS_TREE = "XRedPointConditionChristmasTree", -- 小游戏红点
    CONDITION_CHRISTMAS_TREE_ORNAMENT_READ = "XRedPointConditionChristmasTreeOrnamentRead", -- 新饰品红点
    CONDITION_CHRISTMAS_TREE_ORNAMENT_ACTIVE = "XRedPointConditionChristmasTreeOrnamentActive", -- 兑换饰品红点
    CONDITION_CHRISTMAS_TREE_AWARD = "XRedPointConditionChristmasTreeAward", -- 奖励红点

    -- 春节对联小游戏红点
    CONDITION_COUPLET_GAME = "XRedPointConditionCoupletGameRed", -- 小游戏红点
    CONDITION_COUPLET_GAME_REWARD_TASK = "XRedPointConditionCoupletGameRewardTask", -- 奖励任务红点
    CONDITION_COUPLET_GAME_PLAY_VIDEO = "XRedPointConditionCoupletGamePlayVideo", -- 播放剧情红点

    --跑团红点（主线终焉福音）
    CONDITION_TRPG_MAIN_VIEW = "XRedPointConditionTRPGMainView", --主线界面红点
    CONDITION_TRPG_MAIN_MODE = "XRedPointConditionTRPGMainMode", --探索模式红点
    CONDITION_TRPG_TRUTH_ROAD_REWARD = "XRedPointTRPGTruthRoadReward", --求真之路奖励
    CONDITION_TRPG_COLLECTION_MEMOIR = "XRedPointTRPGCollectionMemoir", --珍藏-回忆
    CONDITION_TRPG_AREA_REWARD = "XRedPointTRPGAreaReward", --区域探索度奖励
    CONDITION_TRPG_WORLD_BOSS_REWARD = "XRedPointTRPGWorldBossReward", --跑团世界BOSS奖励
    CONDITION_TRPG_ROLE_TALENT = "XRedPointTRPGRoleTalent", --调查员天赋
    CONDITION_TRPG_SECOND_MAIN_REWARD = "XRedPointTRPGSecondMainReward", --常规主线奖励

    --活动入口可挑战
    CONDITION_ACTIVITYBRIE_ROGUELIKEMAIN = "XRedPointConditionRogueLikeMain", --roguelike爬塔红点
    CONDITION_ACTIVITYBRIE_BABELTOWER = "XRedPointConditionBabelTower", --巴别塔红点
    CONDITION_ACTIVITYBRIE_BOSSSINGLE = "XRedPointConditionBossSingle", --超难关
    CONDITION_ACTIVITYBRIE_EXTRA = "XRedPointConditionExtra", --番外剧情
    CONDITION_ACTIVITYBRIE_PREQUEL = "XRedPointConditionPrequel", --间章剧情
    CONDITION_ACTIVITYBRIE_NIER = "XRedPointConditionNierCanFight", --尼尔玩法可挑战

    -- 兵法蓝图玩法红点
    CONDITION_RPGTOWER_TEAM_RED = "XRedPointConditionRpgTowerTeamRed", --有可升星角色时
    CONDITION_RPGTOWER_TASK_RED = "XRedPointConditionRpgTowerTaskRed", --有可领取奖励的任务时
    CONDITION_RPGTOWER_DAILYREWARD_RED = "XRedPointConditionRpgTowerDailyRewardRed", --有每日奖励可领取时
    -- 尼尔玩法红点
    CONDITION_NIER_RED = "XRedPointConditionNieRRed",
    CONDITION_NIER_TASK_RED = "XRedPointConditionNieRTaskRed",
    CONDITION_NIER_POD_RED = "XRedPointConditionNieRPODRed",
    CONDITION_NIER_REPEAT_RED = "XRedPointConditionNieRRepeatRed",
    CONDITION_NIER_CHARACTER_RED = "XRedPointConditionNieRCharacterRed",

    -- 特训关三期红点显示
    CONDITION_SPECIALTRAIN_RED = "XRedPointConditionSpecialTrain",
    CONDITION_SPECIALTRAINPOINT_RED = "XRedPointConditionSpecialTrainPoint",
    --师徒系统相关红点
    CONDITION_MENTOR_APPLY_RED = "XRedPointConditionMentorApplyRed", --申请列表红点
    CONDITION_MENTOR_REWARD_RED = "XRedPointConditionMentorRewardRed", --奖励红点
    CONDITION_MENTOR_TASK_RED = "XRedPointConditionMentorTaskRed", --任务红点

    --炸服押注红点
    CONDITION_GUARD_CAMP_RED = "XRedPointConditionGuardCampRed",

    --口袋战双红点
    CONDITION_POKEMON_TIME_SUPPLY_RED = "XRedPointConditionPokemonCanGetTimeSupply", --口袋战双时间奖励红点
    CONDITION_POKEMON_RED = "XRedPointConditionPokemonRed", --口袋战双入口红点
    CONDITION_POKEMON_TASK_RED = "XRedPointConditionPokemonTaskRed", --口袋战双任务红点
    CONDITION_POKEMON_NEW_ROLE = "XRedPointConditionPokemonNewRole", --口袋战双培养界面新角色

    -- 模拟作战红点
    CONDITION_SIMULATED_COMBAT = "XRedPointConditionSimulatedCombat",
    CONDITION_SIMULATED_COMBAT_CHALLENGE = "XRedPointConditionSimulatedCombatChallenge",
    CONDITION_SIMULATED_COMBAT_POINT = "XRedPointConditionSimulatedCombatPoint",
    CONDITION_SIMULATED_COMBAT_STAR = "XRedPointConditionSimulatedCombatStar",
    CONDITION_SIMULATED_COMBAT_TASK = "XRedPointConditionSimulatedCombatTask",

    -- 骇入玩法
    CONDITION_FUBEN_HACK_STAR = "XRedPointConditionFubenHackStar", -- 星级奖励
    CONDITION_FUBEN_HACK_BUFF = "XRedPointConditionFubenHackBuff",  -- Buff解锁

    -- 双人玩法
    CONDITION_COUPLE_COMBAT_NORMAL = "XRedPointConditionCoupleCombatNormal",  -- 普通模式
    CONDITION_COUPLE_COMBAT_HARD = "XRedPointConditionCoupleCombatHard",  -- 挑战模式

    --追击玩法奖励可以领取
    CONDITION_CHESSPURSUIT_REWARD_RED = "XRedPointConditionChessPursuitReward",

    --超级据点
    XRedPointConditionStrongholdMineralLeft = "XRedPointConditionStrongholdMineralLeft", --有剩余矿石可领取
    XRedPointConditionStrongholdRewardCanGet = "XRedPointConditionStrongholdRewardCanGet", --有任务奖励未领取

    --巴别塔奖励可领取
    CONDITION_ACTIVITYBRIE_BABELTOWER_REWARD = "XRedPointConditionBabelTowerReward",

    --伙伴
    CONDITION_PARTNER_COMPOSE_RED = "XRedPointConditionPartnerCanCompose", --是否可以合成
    CONDITION_PARTNER_NEWSKILL_RED = "XRedPointConditionPartnerNewSkill", --是否有新技能解锁

    --春节集字活动红点
    CONDITION_SPRINGFESTIVAL_TASK_RED = "XRedPointConditionSpringFestivalTaskRed",
    CONDITION_SPRINGFESTIVAL_BAG_RED = "XRedPointConditionSpringFestivalBagRed",
    CONDITION_SPRINGFESTIVAL_GET_REWARD_RED = "XRedPointConditionSpringFestivalRewardRed",
    -- 海外定制烟花活动红点
    CONDITION_FIREWORKS_AVAILABLE = "XRedPointConditionFireworks",
    --2021白色情人节活动
    CONDITION_WHITEVALENTINE2021_INVITE = "XRedPointConditionWhite2021Invite", --邀约红点
    CONDITION_WHITEVALENTINE2021_ENCOUNTER = "XRedPointConditionWhite2021Encounter", --偶遇红点
    CONDITION_WHITEVALENTINE2021_TASK = "XRedPointConditionWhite2021Task", --任务红点
    CONDITION_WHITEVALENTINE2021_ENTRYRED = "XRedPointConditionWhiteValentineTaskRed", --入口红点

    --猜拳小游戏红点
    CONDITION_FINGERGUESSING_TASK = "XRedPointConditionFingerGuessingTaskRed", --猜拳小游戏任务红点

    --库洛姆人物活动红点
    CONDITION_KOROMCHARACTIVITYMAINRED = "XRedPointConditionKoroCharActivity", --库洛姆人物活动主界面红点
    CONDITION_KOROMCHARACTIVITYCHALLENGERED = "XRedPointConditionKoroCharActivityChallenge", --挑战关红点
    CONDITION_KOROMCHARACTIVITYTEACHINGRED = "XRedPointConditionKoroCharActivityTeaching", --教学关红点

    --萌战红点
    CONDITION_MOEWAR_PREPARATION = "XRedPointConditionMoeWarPreparation", --筹备红点
    CONDITION_MOEWAR_PREPARATION_REWARD = "XRedPointConditionMoeWarPreparationReward", --筹备奖励可领取
    CONDITION_MOEWAR_PREPARATION_OPEN_STAGE = "XRedPointConditionMoeWarPreparationOpenStage", --筹备关卡开启数量达到配置提醒的数量及以上
    CONDITION_MOEWAR_RECRUIT = "XRedPointConditionMoeWarRecruit", --招募通讯中
    CONDITION_MOEWAR_TASK_TAB = "XRedPointConditionMoeWarTaskTab", --任务面板红点
    CONDITION_MOEWAR_TASK = "XRedPointConditionMoeWarTask", --任务面板红点
    CONDITION_MOEWAR_DRAW = "XRedPointConditionMoeWarDrawRed", --抽奖红点

    --翻牌猜大小红点
    CONDITION_POKER_GUESSING_RED = "XRedPointConditionPokerGuessingRed", --翻牌猜大小活动列表红点
    -- 改造玩法红点
    CONDITION_REFORM_All_RED_POINT = "XRedPointConditionReformAllRedPoint", -- 改造玩法任务奖励获取
    CONDITION_REFORM_TASK_GET_REWARD = "XRedPointConditionReformTaskGetReward", -- 改造玩法任务奖励获取
    CONDITION_REFORM_BASE_STAGE_OPEN = "XRedPointConditionReformBaseStageOpen", -- 改造玩法基础关卡开启
    CONDITION_REFORM_EVOLVABLE_STAGE_UNLOCK = "XRedPointConditionReformEvolvableStageUnlock", -- 改造玩法改造难度解锁

    -- 剧情合集剧情红点
    CONDITION_MOVIE_ASSEMBLE_MOVIE_RED = "XRedPointConditionMovieAssembleMovieRed", -- 剧情上的红点
    CONDITION_MOVIE_ASSEMBLE_RED = "XRedPointConditionMovieAssembleRed", -- 剧情合集红点条件（参数：合集Id）
    CONDITION_MOVIE_ASSEMBLE_01 = "XRedPointConditionMovieAssemble01Red", -- 剧情合集Id为1的红点
    -- 翻牌小游戏红点
    CONDITION_INVERTCARDGAME_RED = "XRedPointConditionInvertCardGameRed", -- 翻牌小游戏红点条件
    CONDITION_INVERTCARDGAME_TOG = "XRedPointConditionInvertCardGameTog", -- 翻牌小游戏左侧标签红点
    --扫雷小游戏
    CONDITION_MINSWEEPING_RED = "XRedPointConditionMineSweepingRed",--门票剩余时有关卡未通关
    
    -- 系列涂装剧情活动
    CONDITION_FASHION_STORY_HAVE_STAGE = "XRedPointConditionFashionStoryHaveStage", -- 有关卡尚未通关

    --杀戮空间
    XRedPointConditionKillZoneActivity = "XRedPointConditionKillZoneActivity", --入口红点
    XRedPointConditionKillZoneNewChapter = "XRedPointConditionKillZoneNewChapter", --有新章节可挑战
    XRedPointConditionKillZoneNewDiff = "XRedPointConditionKillZoneNewDiff", --挑战模式已开启
    XRedPointConditionKillZoneStarReward = "XRedPointConditionKillZoneStarReward", --星级奖励可领取
    XRedPointConditionKillZoneDailyStarReward = "XRedPointConditionKillZoneDailyStarReward", --每日星级奖励可领取
    XRedPointConditionKillZonePluginOperate = "XRedPointConditionKillZonePluginOperate", --插件待操作

    --2021端午活动
    CONDITION_RPG_MAKER_GAME_RED = "XRedPointConditionRpgMakerGame",

    --战斗通行证
    CONDITION_PASSPORT_RED = "XRedPointConditionPassport",       --入口红点
    CONDITION_PASSPORT_PANEL_REWARD_RED = "XRedPointConditionPassportPanelReward",    --主界面奖励可领取
    CONDITION_PASSPORT_TASK_DAILY_RED = "XRedPointConditionPassportTaskDaily",  --每日任务奖励可领取
    CONDITION_PASSPORT_TASK_WEEKLY_RED = "XRedPointConditionPassportTaskWeekly",  --每周任务奖励可领取
    CONDITION_PASSPORT_TASK_ACTIVITY_RED = "XRedPointConditionPassportTaskActivity",  --活动任务奖励可领取

    --超级爬塔
    CONDITION_SUPERTOWER_ROLE_LEVELUP = "XRedPointConditionSTRoleLevelUp", -- 超级爬塔角色超限升级红点
    CONDITION_SUPERTOWER_ROLE_PLUGIN = "XRedPointConditionSTRolePlugin", -- 超级爬塔角色专属插件红点
    CONDITION_SUPERTOWER_ROLE_INDULT = "XRedPointConditionSTRoleInDult", -- 超级爬塔角色特典红点
    --日服老虎机活动红点
    CONDITION_SLOTMACHINE_RED = "XRedPointConditionSlotMachine",
    CONDITION_SLOTMACHINE_REDL = "XRedPointConditionSlotMachineL",
}

--注册所有条件
function XRedPointConditions.RegisterAllConditions()
    if not XRedPointConditions.Conditions then
        return
    end

    XRedPointConditions.Types = {}
    for key, value in pairs(XRedPointConditions.Conditions) do
        local m = require("XRedPoint/XRedPointConditions/" .. value)
        rawset(_G, value, m)
        XRedPointConditions[key] = m
        XRedPointConditions.Types[key] = key
    end
end

XRedPointConditions.RegisterAllConditions()