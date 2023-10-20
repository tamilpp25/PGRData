XEnumConst = {
    MAIL_STATUS = {
        STATUS_UNREAD = 0,
        STATUS_READ = 1 << 0,
        STATUS_GETREWARD = 1 << 0 | (1 << 1),
        STATUS_DELETE = 1 << 2,
    },
    MailType = {
        Normal = 0, --普通邮件
        FavoriteMail = 1, --收藏角色好感邮件
    },
    EQUIP = {
        MAX_STAR_COUNT = 6, -- 最大星星数
        MAX_ATTR_COUNT = 2, -- 最大属性数量
        WEAPON_RESONANCE_COUNT = 3, -- 武器的共鸣数量
        AWARENESS_RESONANCE_COUNT = 2, -- 意识的共鸣数量
        OVERRUN_ADD_SUIT_CNT = 2, -- 超限增加意识数量
        WEAR_AWARENESS_COUNT = 6, -- 可穿戴意识的数量
        MAX_SUIT_SKILL_COUNT = 4, -- 最大的意识套装技能数量
        SUIT_MAX_SKILL_COUNT = 3, -- 同一意识套装里最大技能数量
        AWAKE_CRYSTAL_MONEY = 2, -- 超频激活的晶币
        CAN_NOT_AUTO_EAT_STAR = 5, -- 大于等于该星级的装备不会被当做默认狗粮选中
        FIVE_STAR = 5, -- 5星
        STRENGTHEN_EXP_OVERFLOW_CONFIRM = 300, -- 强化经验溢出超过这个值需要二次确认
        -- XUiEquipDetailV2P6界面的页签按钮下标
        UI_EQUIP_DETAIL_BTN_INDEX = {
            STRENGTHEN = 1, -- 强化
            RESONANCE = 2, -- 共鸣
            OVERCLOCKING = 3, -- 超频
            OVERRUN = 4, -- 超限
        },
        -- 武器模型用途
        WEAPON_USAGE = {
            ROLE = 1, -- ui角色身上
            BATTLE = 2, -- 战斗
            SHOW = 3, -- ui单独展示
        },
        -- 装备位置
        EQUIP_SITE = {
            WEAPON = 0, -- 武器
            AWARENESS = {                       -- 意识
                ONE = 1, -- 1号位
                TWO = 2, -- 2号位
                THREE = 3, -- 3号位
                FOUR = 4, -- 4号位
                FIVE = 5, -- 5号位
                SIX = 6, -- 6号位
            },
        },
        -- 狗粮类型
        EAT_TYPE = {
            EQUIP = 0, -- 装备
            ITEM = 1, -- 道具
        },
        -- 排序优先级选项
        PRIOR_SORT_TYPE = {
            STAR = 0, -- 星级
            BREAKTHROUGH = 1, -- 突破次数
            LEVEL = 2, -- 等级
            PROCEED = 3, -- 入手顺序
        },
        -- 装备适配角色类型
        USER_TYPE = {
            ALL = 0, -- 通用
            NORMAL = 1, -- 泛用机体
            ISOMER = 2, -- 独域机体
        },
        -- 武器类型
        EQUIP_TYPE = {
            UNIVERSAL = 0, -- 通用
            SUNCHA = 1, -- 双枪
            SICKLE = 2, -- 太刀
            MOUNT = 3, -- 挂载
            ARROW = 4, -- 弓箭
            CHAINSAW = 5, -- 电锯
            SWORD = 6, -- 大剑
            HCAN = 7, -- 巨炮
            DOUBLE_SWORDS = 8, -- 双短刀
            SCYTHE = 9, -- 镰刀
            ISOMER_SWORD = 10, -- 感染者专用大剑
            FOOD = 99, -- 狗粮
        },
        -- 共鸣类型
        RESONANCE_TYPE = {
            ATTRIB = 1, -- 属性共鸣
            CHARACTER_SKILL = 2, -- 角色技能共鸣
            WEAPON_SKILL = 3, -- 武器技能共鸣
        },
        IS_TEST_V2P6 = true, -- 是否测试2.6版本, true为打开2.6的界面, false为打开旧的界面
    },
    FuBen = {
        ProcessFunc = { --战斗过程自定义函数
            InitStageInfo = "InitStageInfo",
            CheckPreFight = "CheckPreFight",
            CustomOnEnterFight = "CustomOnEnterFight",
            PreFight = "PreFight",
            FinishFight = "FinishFight",
            CallFinishFight = "CallFinishFight",
            OpenFightLoading = "OpenFightLoading",
            CloseFightLoading = "CloseFightLoading",
            ShowSummary = "ShowSummary",
            SettleFight = "SettleFight",
            CheckReadyToFight = "CheckReadyToFight",
            CheckAutoExitFight = "CheckAutoExitFight",
            ShowReward = "ShowReward",
            CheckUnlockByStageId = "CheckUnlockByStageId",
            CheckPassedByStageId = "CheckPassedByStageId",
            CustomRecordFightBeginData = "CustomRecordFightBeginData"
        },
        StageType = {
            Mainline = 1,
            Daily = 2,
            Tower = 3,
            Urgent = 4,
            BossSingle = 5,
            BossOnline = 6,
            Bfrt = 7,
            Resource = 8,
            BountyTask = 9,
            Trial = 10,
            Prequel = 11,
            Arena = 12,
            Experiment = 13, --试验区
            Explore = 14, --探索玩法关卡
            ActivtityBranch = 15, --活动支线副本
            ActivityBossSingle = 16, --活动单挑BOSS
            Practice = 17, --教学关卡
            Festival = 18, --节日副本
            BabelTower = 19, --  巴别塔计划
            RepeatChallenge = 20, --复刷本
            RogueLike = 21, --爬塔玩法
            Assign = 22, -- 边界公约
            ArenaOnline = 23, --合众战局
            UnionKill = 24, --列阵
            ExtraChapter = 25, --番外关卡
            InfestorExplore = 26, --感染体玩法
            SpecialTrain = 27, --特训关
            GuildBoss = 28, --工会boss
            WorldBoss = 29, --世界Boss
            Expedition = 30, --虚像地平线
            RpgTower = 31, --兵法蓝图
            MaintainerAction = 32, --大富翁
            TRPG = 33, --跑团玩法
            NieR = 34, --尼尔玩法
            ZhouMu = 35, --多周目
            NewCharAct = 36, -- 新角色教学
            Pokemon = 37, --口袋妖怪
            ChessPursuit = 38, --追击玩法
            Stronghold = 39, --超级据点
            SimulatedCombat = 40, --模拟作战
            MoeWarPreparation = 41, -- 萌战赛事筹备
            Hack = 42, --骇入玩法
            PartnerTeaching = 43, --宠物教学
            Reform = 44, --改造关卡
            KillZone = 45, --杀戮无双
            FashionStory = 46, --涂装剧情活动
            CoupleCombat = 47, --双人下场玩法
            SuperTower = 48, --超级爬塔
            PracticeBoss = 49, --拟真boss
            LivWarRace = 50, --二周年预热-赛跑小游戏
            SuperSmashBros = 51, --超限乱斗
            SpecialTrainMusic = 52, --特训关音乐关
            AreaWar = 53, -- 全服决战
            MemorySave = 54, -- 周年意识营救战
            Maverick = 55, -- 二周年射击玩法
            Theatre = 56, -- 肉鸽
            ShortStory = 57, --短篇小说
            Escape = 58, --大逃杀
            SpecialTrainSnow = 59, --特训关冰雪感谢祭2.0
            PivotCombat = 60, --SP枢纽作战
            SpecialTrainRhythmRank = 61, --特训关元宵
            DoubleTowers = 62, -- 动作塔防
            GuildWar = 63, -- 公会战
            MultiDimSingle = 64, -- 多维挑战单人
            MultiDimOnline = 65, -- 多维挑战多人
            TaikoMaster = 66, -- 音游
            --SpecialTrainBreakthrough = 67, --卡列特训关
            MoeWarParkour = 68, -- 萌战跑酷
            TwoSideTower = 69, --正逆塔
            Course = 70, -- v1.30-考级-ManagerStage
            BiancaTheatre = 71, --肉鸽2.0
            FubenPhoto = 72, -- 夏活特训关-拍照
            Rift = 73, -- 战双大秘境
            CharacterTower = 74, -- 本我回廊（角色塔）
            Awareness = 75, -- 意识公约
            SpecialTrainBreakthrough = 76, --魔方 2.0
            ColorTable = 77, -- 调色板战争
            BrillientWalk = 78, --光辉同行
            Maverick2 = 79, -- 异构阵线2.0
            Maze = 80, --情人节活动2023
            MonsterCombat = 81, -- 战双BVB
            CerberusGame = 82, -- 三头犬小队玩法
            Transfinite = 83, -- 超限连战
            Theatre3 = 84, -- 肉鸽3.0
            DlcCasual = 85, -- Dlc魔方嘉年华
        },
        ChapterType = {
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
            RogueSim = 93, -- 肉鸽模拟经营
            DlcCasual = 94, -- Dlc魔方嘉年华
        },
        CharacterLimitType = {
            All = 0, --构造体/感染体
            Normal = 1, --构造体
            Isomer = 2, --感染体
            IsomerDebuff = 3, --构造体/感染体(Debuff) [AKA:低浓度区]
            NormalDebuff = 4, --构造体(Debuff)/感染体 [AKA:重灾区]
        },
    },
    CHARACTER = {
        MAX_SHOW_SKILL_POS = 4,
        IS_NEW_CHARACTER = true,
        MAX_QUALITY_STAR = 10,
        MAX_QUALITY = 6,
        QualityState = {
            Activing = 1,
            EvoEnable = 2,
            ActiveFinish = 3,
            Lock = 4,
        },
        PerformState = {
            One = 1,
            Two = 2,
            Three = 3,
            Four = 4,
        },
        CameraV2P6 = {
            Main = 1,
            Train = 2,
            Quality = 3,
            LvUseItem = 4,
            QualitySingle = 5,
            QualityOverview = 6,
            QualityUpgradeDetail = 7,
            CharLeftMove = 8,
        },
        SkipEnumV2P6 = {
            Character = 1,
            PropertyLvUp = 2.1,
            PropertyGrade = 2.2,
            PropertySkill = 2.3,
        },
    },
    Filter = {
        TagName = {
            BtnAll = "BtnAll",
            BtnUniframe = "BtnUniframe",
            BtnRed = "BtnRed",
            BtnSupport = "BtnSupport",
            BtnElement1 = "BtnElement1",
            BtnElement2 = "BtnElement2",
            BtnElement3 = "BtnElement3",
            BtnElement4 = "BtnElement4",
            BtnElement5 = "BtnElement5",
        },
    },
    THEATRE3 = {
        --步骤类型
        StepType = {
            RecruitCharacter = 1, --设置编队
            Node = 2, --节点
            FightReward = 3, --战斗奖励
            ItemReward = 4, --具体道具奖励
            WorkShop = 5, --炼金工坊
            EquipReward = 6, --打开装备选择界面
            EquipInherit = 7, --打开装备继承界面
        },
        --节点类型
        NodeSlotType = {
            Fight = 1, --战斗
            Event = 2, --事件
            Shop = 3, --商店
        },
        --节点奖励类型
        NodeRewardType = {
            ItemBox = 1, --道具箱
            Gold = 2, --金币
            EquipBox = 3, --装备箱
        },
        --节点奖励类型
        NodeRewardTag = {
            None = 0,       --无
            Difficulty = 1, --困难
        },
        --商店售卖项类型
        NodeShopItemType = {
            Item = 1, --道具
            EquipBox = 2, --装备箱
            ItemBox = 3, --道具箱
        },
        NodeShopItemLockType = {
            Unlock = 0, --已解锁
            Lock = 1, --上锁
            NoItem = 2, --没有物品
        },
        EventStepType = {
            Dialogue = 1, --对话
            Options = 2, --选项
            ChapterItem = 3, --物品
            Fight = 4, --战斗
            WorkShop = 5, --炼金工坊
        },
        EventStepOptionType = {
            CostItem = 1, --消耗物品
            CheckItem = 2, --检查物品
            Dialogue = 3, --对话
        },
        EventStepItemType = {
            OutSideItem = 1, --局外物品
            InnerItem = 2, --局内物品
            ItemBox = 3, --道具箱
            EquipBox = 4, --装备箱
        },
        --工坊节点类型
        WorkShopType = {
            Recast = 1, --重铸
            Change = 2, --交换
        },

        StrengthenPointType = {
            Small = 1, --小节点
            Middle = 2, --中节点
            Big = 3, --大节点
        },
        RewardDisplayType = {
            Normal = 0, --普通
            Rare = 1, --稀有
        },
        -- 肉鸽3，天赋点，激活天赋强化
        Theatre3TalentPoint = 96187,
        -- 肉鸽3，BP经验，升级BP等级
        Theatre3OutCoin = 96188,
        -- 肉鸽3，肉鸽三期商店货币，复活也用这个
        Theatre3InnerCoin = 96189,
        MaxEnergyCount = 16,
        GetBattlePassRewardType = {
            GetOnce = 1, -- 领取一个
            GetAll = 2, -- 领取全部
        },
        TipAlign = {
            Left = 1, -- 居左
            Right = 2, -- 居右
        },
        EffectGroupDescType = {
            PassNode = 1,
            BuyCount = 2,
            ItemCount = 3,      -- 持有道具数
            CollectSuit = 4,    -- 收集齐套装数
            FightAndBoss = 5,   -- 关卡和boss节点收益不一致类型
            
        },
    },
    Turntable = {
        RewardType = {
            Main = 1, -- 核心
            Height = 2, -- 高级
            Simple = 3, -- 普通
        },
    },
    BLACK_ROCK_CHESS = {
        EVENT_FUNC_NAME = {
            SHOW_HEAD_HUD = "SHOW_HEAD_HUD",
            HIDE_HEAD_HUD = "HIDE_HEAD_HUD",
            SHOW_HP_HUD = "SHOW_HP_HUD",
            HIDE_HP_HUD = "HIDE_HP_HUD",
            BROADCAST_ROUND = "BROADCAST_ROUND",
            CAMERA_DISTANCE_CHANGED = "CAMERA_DISTANCE_CHANGED",
            PREVIEW_DAMAGE = "PREVIEW_DAMAGE",
            FOCUS_ENEMY = "FOCUS_ENEMY",
            CANCEL_FOCUS_ENEMY = "CANCEL_FOCUS_ENEMY",
            REFRESH_CHECK_MATE = "REFRESH_CHECK_MATE",
            CLOSE_BUBBLE_SKILL = "CLOSE_BUBBLE_SKILL",
            SHOW_DIALOG_BUBBLE = "SHOW_DIALOG_BUBBLE",
            SHOW_BUFF_HUD = "SHOW_BUFF_HUD",
            HIDE_BUFF_HUD = "HIDE_BUFF_HUD",
        },
        WEAPON_SKILL_TYPE = {
            SHOTGUN_ATTACK = 1,
            SHOTGUN_SKILL1 = 2,
            SHOTGUN_SKILL2 = 3,
            KNIFE_ATTACK = 4,
            KNIFE_SKILL1 = 5,
            KNIFE_SKILL2 = 6,
        },
        ACTION_TYPE = {
            --移动
            MOVE = 1,
            --被动技能
            PASSIVE_SKILL = 2,
            --攻击
            ATTACK = 3,
            --增援预告
            REINFORCE_PREVIEW = 4,
            --增援触发
            REINFORCE_TRIGGER = 5,
            --升变
            PROMOTION = 6,
            --召唤
            SUMMON = 7,
            --转化
            TRANSFORM = 8,
            --放弃回合
            SKIP_ROUND = 9,
            --玩家复活
            CHARACTER_REVIVE = 10,
        },
        REINFORCE_TYPE = {
            --国王周围8格随机
            KING_RANDOM = 1,
            --配置决定
            SPECIFIC = 2,
        },
        PLAYER_MEMBER_ID = -1, --玩家在Layout的MemberId
        CHESS_MEMBER_TYPE = {
            GAMER = 1,
            PIECE = 2,
            REINFORCE_PREVIEW = 3
        },
        SKILL_TIP_TYPE = {
            WEAPON = 1, -- 武器Tip
            WEAPON_SKILL = 2, -- 武器技能Tip
            CHARACTER = 3, -- 角色技能Tip
        },
        SKILL_TIP_ALIGN = {
            LEFT = 1,
            RIGHT = 2,
        },
        DIFFICULTY = {
            NORMAL = 1,
            HARD = 2
        },
        CHAPTER_ID = {
            CHAPTER_ONE = 1,
            CHAPTER_TWO = 2,
        },
        CUE_ID = {
            PIECE_BREAK         = 4177, --棋子破碎
            REINFORCE_COMING    = 4178, --增援触发
            PIECE_BUFF          = 4179, --棋子Buff
            CHANGE_PIECE_TARGET = 4181, --更换目标
            PIECE_MOVED         = 4182, --棋子落子
            GAME_WIN            = 4183, --游戏胜利
        },
        MASK_KEY = "BlackRockChess"
    },
    BLACK_ROCK = {
        STAGE = {
            FESTIVAL_ACTIVITY_ID = 32,
        },
    },
    PASSPORT = {
        --任务类型
        TASK_TYPE = {
            ACTIVITY = 0, --活动任务（前端自定义）
            DAILY = 1, --每日任务
            WEEKLY = 2, --每周任务
        },
        REWARD_TYPE = {
            NONE = 0,
            NORMAL = 1,
            INFINITE = 2
        }
    },
    TAIKO_MASTER = {
        SONG_STATE = {
            LOCK = 1,
            JUST_UNLOCK = 2, --刚解锁，还未浏览过
            BROWSED = 3         --已解锁，且浏览过
        },
        DIFFICULTY = {
            EASY = 1,
            HARD = 2
        },
        ASSESS = {
            NONE = "None",
            A = "A",
            S = "S",
            SS = "SS",
            SSS = "SSS"
        },
        SETTING_KEY = {
            APPEAR = 1,
            JUDGE = 2
        },
        TASK_TYPE = {
            NORMAL = 1,
            DAILY = 2,
        },
        -- 排行榜默认困难，简单难度不排行
        DEFAULT_RANK_DIFFICULTY = 2,
        MUSIC_PLAYER_TEXT_MOVE_PAUSE_INTERVAL = 1,
        MUSIC_PLAYER_TEXT_MOVE_SPEED = 70,
        STAGE_DEFAULT_ROLE_COUNT = 1,
        TEAM_TYPE_ID = 140,
        TEAM_ID = 20,
    },
    Ui_MAIN = {
        TerminalTipType = {
            MonthlyCard = 1,
            Gift = 2,
            Dorm = 3,
            ExpensiveItem = 4,
            Preload = 6, --预下载
        }
    },
    NewActivityCalendar = {
        ActivityType = {
            TimeLimit = 1, -- 限时任务
            Week = 2, -- 周常任务
        },
        WeekMainId = {
            BossSingle = 1001, -- 囚笼
            ArenaChallenge = 1002, -- 战区
            StrongHold = 1003, -- 矿区
            Transfinite = 1004, -- 超限连战
            GuildBoss = 1005, -- 工会Boss
        },
    },
    TwoSideTower = {
        ChapterType = {
            OutSide = 1, -- 超频裂缝
            Inside = 2, -- 本我牢笼
        },
        PointType = {
            Normal = 1,
            End = 2,
        },
    },
    Rift = {
        SystemBuffType = {
            Luck = 1, -- 幸运关累计进度提示、攻击力提示
            Currency = 2, -- 养成货币掉落量增加、属性伤害和爆伤提升
            PluginConvert = 3, -- 重复插件转化为养成材料量增加、敌人抗性削减
            PluginDrop = 4      -- 插件掉落数量增加、角色防御力与生命值上限增加
        },
        PropType = {
            Battle = 1, -- 战斗属性
            System = 2, -- 系统属性
        },
        Filter = {
            Star = 1, -- 星级
            Tag = 2, -- 标签
        },
        StarFilter = {
            3, 4, 5, 6  -- 插件星级筛选器
        },
        SpecialGoldTag = 7, -- 暗金标签Id（暗金装备特殊显示）
        RandomShopGoodType = 2, -- 商店随机物品类型
        FilterSetting = {
            PluginChoose = 1,   -- 插件选择
            PluginShop = 2,     -- 插件商店
        },
        StarConditionType = 10171,
    },
    Filt = {
        FilterTag = {
            All = "BtnAll",
            Physics = "BtnElement1",
            Fire = "BtnElement2",
            Ice = "BtnElement3",
            Lightning = "BtnElement4",
            Dark = "BtnElement5",
            Uniframe = "BtnUniframe",
        }
    },
    SAME_COLOR_GAME = {
        ---数据同步类型
        ACTION_TYPE = {
            NONE = 0,
            MAP_INIT = 1, --地图初始化
            ITEM_REMOVE = 2, --消除
            ITEM_DROP = 3, --下落
            ITEM_CREATE_NEW = 4, --新增
            MAP_SHUFFLE = 5, --洗牌
            GAME_INTERRUPT = 6, --游戏中断
            SETTLE_SCORE = 7, --分数结算
            ITEM_SWAP = 8, --交换球
            STEP_ADD = 9, --增加步数
            STEP_SUB = 10, --减少步数
            ITEM_CHANGE_COLOR = 11, --改变颜色
            BUFF_ADD = 12, --增加buff
            BUFF_REMOVE = 13, --删除buff
            BOSS_RELEASE_SKILL = 14, --boss释放技能
            BOSS_SKIP_SKILL = 15, --boss跳过技能
            ENERGY_CHANGE = 16, --能量改变
            SKILL_CD_CHANGE = 17, --技能cd改变
            LEFT_TIME_CHANGE = 18, --关卡剩余时间改变
            BUFF_LEFT_TIME_CHANGE = 19, --buff剩余时间改变
            MAP_RESET = 20, --棋盘重置
            TIME_ADD = 21,  -- 增加时间
            ITEM_SWAP_EX = 22, --交换列
        },
        UI_BOSS_CHILD_PANEL_TYPE = {
            MAIN = 1, -- 主页面
            BOSS = 2, -- Boss详情
            ROLE = 3, -- 角色详情
            READY = 4, -- 角色技能
        },
        TASK_TYPE = {
            DAY = 1, -- 日常任务
            REWARD = 2, -- 奖励任务
        },
        SKILL_TYPE = {
            COL_ALL_SWAP = 33,
        },
        ---技能准备时的黑幕类型
        SKILL_SCREEN_MASK_TYPE = {
            NONE = 0, --直接释放
            CONDITION = 1, --指向条件栏（回合数，伤害，评分）
            BOARD = 2, --指向棋盘
            BUFF = 3, --指向Buff栏
            ENERGY = 4, --指向能量栏
            SKILL = 5, --指向技能栏
            POPUP = 6, --指向弹窗
        },
        ---技能准备时的触发方式
        SKILL_CONTROL_TYPE = {
            NONE = 0, --无
            CLICK_BALL = 1, --选择球触发
            CLICK_POPUP = 2, --选择弹窗选定触发
            CLICK_TWO_BALL = 3, --选择两球触发
        },
        SKILL_COMBO_TYPE = {
            DEFAULT = 0,
            ONCE = 1, -- 触发即释放一次技能，根据本次combo数确定动画
        },
        ---key = server Define XSameColorGameSkillItemType 需要先开启再使用的技能，则第一次点击球是开启技能，后续的点击为使用技能
        SKILL_NEED_OPEN = {
            [22] = true,
            [30] = true,
        },
        ---key = server Define XSameColorGameSkillItemType动画不阻塞的技能
        SKILL_ANIM_NOT_MASK = {
            [22] = true,    
            [30] = true,
        },
        SKILL_EFFECT_TYPE = {
            ALL = 1,
            LOCAL_ONE = 2,  -- 定点单特效
            LOCAL_TWO = 3,  -- 定点双特效
            LIFU = 4,       -- 丽芙延申特效
        },
        SKILL_EFFECT_TIME_TYPE = {
            BEFORE_REMOVE = 1,  -- 消球前
            REMOVE = 2,         -- 消球时
            CHANGER_BALL = 3,   -- 换球时
        },
        ---消球Action中球类型
        BALL_REMOVE_TYPE = {
            NONE = 0,           -- 默认
            BOOM_CENTER = 1,    -- v1.31 三期爆炸技能爆炸中心
            LIFU_ROW = 2,       -- 丽芙横消
            LIFU_COL = 3,       -- 丽芙纵消
            VERA_SKILL_LT = 4,  -- 薇拉雷击左上角起始位置
            ALISA_LT = 5,       -- 回音技能左上锚点
        },
        ---常驻显示选中特效的球
        BALL_SHOW_SELECT_EFFECT = {
            [1000] = true,
        },
        ENERGY_CHANGE_TYPE = {
            ADD = 1,
            PERCENT = 2,
        },
        ENERGY_CHANGE_FROM = {
            USE_SKILL = 1, --使用充能技能
            BOSS = 2, --被boss攻击
            COMBO = 3, --连击
            BUFF = 4, --buff/技能效果
            ROUND = 5, --每回合环境造成
        },
        BUFF_TYPE = {
            NONE = 0,
            ADD_STEP = 1,               -- 增加步数
            SUB_STEP = 2,               -- 减少步数
            ADD_DAMAGE = 3,             -- 增加球百分比伤害
            SUB_DAMAGE = 4,             -- 减少球百分比伤害
            NO_DAMAGE = 5,              -- 免疫伤害
            COMBO_ADD_ENERGY = 6,       -- Combo增加、减少能量buff
            REMOVE_ONT_BALL = 7,        -- Combo结束后再随机消除1个球buff
            CHANGE_DROP_ITEM_COLOR = 8, -- 将下落的n个球改为指定颜色
            DROP_SPECIFY_ITEM = 9,      -- 下落的n个球指定为某几种颜色
            ADD_TIME = 10,              -- 加最大时间
            DROP_RAND_ITEM_COLOR = 11,  -- 下落的n个球指定为随机配置种的某1种颜色
        },
        SOUND = {
            BATTLE_BG = 237,
            SWAP_BALL = 2989,
            REMOVE_BALL = 2990,
        },
        ---角色最大装备技能数量
        ROLE_MAX_SKILL_COUNT = 3,
        ---排行榜百分比显示限制阈值
        RANK_PERCENT_LIMIT = 100,
        ---上榜最大人数
        RANK_MAX_TOP_COUNT = 100,
        ---特殊排名阈值
        RANK_MAX_SPECIAL_INDEX = 3,
        ---消球表现的时间
        TIME_BALL_REMOVE = 0.3,
        ---重置棋盘、使用技能扣除能量 的阻塞时间
        TIME_USE_SKILL_MASK = 0.5,
        BOARD_MIN_SIZE = 4,
        BOARD_MAX_SIZE = 6,
    },
    Favorability = {
        StrangeNewsUnlockType = {
            TrustLv = 1,
            DormEvent = 2,
        },
        SoundEventType = {
            FirstTimeObtain = 1, -- 首次获得角色
            LevelUp = 2, -- 角色升级
            Evolve = 3, -- 角色进化
            GradeUp = 4, -- 角色升军阶
            SkillUp = 5, -- 角色技能升级
            WearWeapon = 6, -- 角色穿戴武器
            MemberJoinTeam = 7, --角色入队(队员)
            CaptainJoinTeam = 8, --角色入队（队长）
        },
        FestivalActivityMailId = 0, --节日邮件活动Id
        InfoState = {
            Normal = 1,
            Available = 2,
            Lock = 3,
        },
        TrustItemType = {
            Normal = 1, -- 普通
            Communication = 2, -- 触发通讯的道具
        },
        RewardUnlockType = {
            FightAbility = 1,
            TrustLv = 2,
            CharacterLv = 3,
            Quality = 4,
        },
        XSignBoardEventType = {
            CLICK = 10001, --点击
            ROCK = 10002, --摇晃
            LOGIN = 101, --登录
            COMEBACK = 102, --n天未登录
            WIN = 103, --胜利
            WINBUT = 104, -- 胜利，看板不在队里
            LOST = 105, --失败
            LOSTBUT = 106, --失败，不在队伍
            MAIL = 107, --邮件
            TASK = 108, --任务奖励
            DAILY_REWARD = 109, --日常活跃奖励
            LOW_POWER = 110, -- 低电量
            PLAY_TIME = 111, --游戏时长
            RECEIVE_GIFT = 112, --收到礼物
            GIVE_GIFT = 113, --赠送礼物
            IDLE = 1, --待机
            FAVOR_UP = 2, --好感度提升
            CHANGE = 120, --改变角色
        },
        XSignBoardUiShowType = {
            UiPhotograph = 1,           --拍照界面
            UiPhotographPortrait = 2,   --拍照界面(竖屏)
            UiMain = 3,                 --主界面
            UiFavorabilityNew = 4,      --看板娘界面
        },
        XSignBoardUiAnimType = {
            Normal = 0,
            Self = 1,
            None = 2,
        },
        REQUEST_NAME = { --请求协议
            ClickRequest = "TouchBoardMutualRequest",
        },
        ShowTimesType = {
            Normal = 0, --可以重复播放
            PerLogin = 1, --每次登陆只会播放一次
            Daily = 2  --每日只能播放一次
        },
    },
    CONNECTING_LINE = {
        OPERATION_TYPE = {
            POINT_DOWN = 1,
            POINT_MOVE = 2,
            POINT_UP = 3,
        },
        FINISH_STATE = {
            UN_COMPLETE = 1,
            COMPLETE = 2,
            PERFECT_COMPLETE = 3,
        },
        MAX_COLUMN = 6,
        STAGE_STATUS = {
            LOCK = 1, -- 未解锁
            UNLOCK = 2, -- 已解锁 
            COMPLETE = 3, -- 已完成
            REWARD = 4, -- 已领奖
        },
        BUBBLE = {
            OPEN = 1,
            CONNECT_FAIL = 2,
            CONNECT_SUCCESS = 3,
            CONNECT_CHANGE = 4,
            FINISH = 5,
            IDLE_SECOND_15 = 6,
            FINISH_ALL = 7,
            DEFAULT = 8,
        },
        HELP_KEY = "ConnectingLineGame",
        COMPLETE_LINE_SOUND = 4271,
    },
    ---临时处理常量，一些特殊情况如：特定物品文本有误时特殊处理，将物品Id定义在这里，写明注释
    SpecialHandling = {
        ---黑岩超难关收藏品DEAD MASTER Id
        DEADCollectiblesId = 13019619,
    },
    Preload = {
        State = {
            IndexDownloadFail = -1, --preloadIndex文件下载失败
            PreIndexLoadFail = -2, --加载preloadIndex文件失败
            PreloadDisable = -3, --预下载不可用
            None = 0, --无状态
            Start = 1, --开始
            CheckIndex = 2, --检查Index文件
            ResolveIndex = 3, --分析加载文件
            Downloading = 4, --下载中
            Pausing = 5, --暂停中
            Pause = 6, --暂停
            Complete = 7, --完成预下载
        },
        CheckCode = { --检测预下载状态码
            None = 0, --需要下载
            Disable = 1, --关闭
            Complete = 2, --预下载完成
            Expire = 3 --过期的预下载
        },
        VersionCompare = { --版本号比较
            Equal = 1, --相等的
            Greater = 2, --大于的
            Less = 3 --小于的
        },
    },
    SUBPACKAGE = {
        DOWNLOAD_STATE = {
            NOT_DOWNLOAD        = 1, --未下载过
            PREPARE_DOWNLOAD    = 2, --等待下载
            PAUSE               = 3, --暂停
            DOWNLOADING         = 4, --下载中
            COMPLETE            = 5, --完全下载
        },
        CUSTOM_SUBPACKAGE_ID = {
            INVALID = -1, --无效Id
            NECESSARY = 0, --必要资源
        },
        ENTRY_TYPE = {
            CHARACTER_VOICE = 9997, --CV-入口检测参数
            MATERIAL_COLLECTION = 9998, --战斗-资源-入口检测参数
            DRAW = 9999, --研发检测参数
        },
        SUBPACKAGE_TYPE = {
            NECESSARY = 1, --必要资源
            OPTIONAL = 2, --可选资源
        },
    },
    CV_TYPE = {
        JPN = 1,
        CN = 2,
        HK = 3,
        EN = 4,
    },
    KICK_OUT = {
        LOCK = {
            NONE = 0,
            FIGHT = 1 << 0,
            DRAW = 1 << 1,
            GACHA = 1 << 2,
            TURNTABLE = 1 << 3,
            RECHARGE = 1 << 4,
        }
    },
    RogueSim = {
        -- 章节移动参数
        ChapterMove = {
            MinX = -500,
            MaxX = -300,
            TargetX = -400,
            Duration = 0.5,
        },
        IsDebug = true,                         -- 打印参数
        IsMapOptimization = false,              -- 是否启用地图优化
        MapGridSize = 0.5,                      -- 场景里六边形格子的大小
        MapExploredConst = 1,                   -- 地图探索消耗行动力
        MapDarkenValue = 0.7,                   -- 地图压黑的的程度 0为最黑 1为原亮度
        MapDarkToLightTime = 0.5,               -- 地图压黑变亮的时间(单位：秒)
        MapCloudAnimTime = 0.5,                 -- 地图云雾动画的时间(单位：秒)
        CameraMoveSpeed = 4,                    -- 镜头移动速度
        -- 地貌类型
        LandformType = {
            Main = 1,                           -- 主城
            City = 2,                           -- 城邦
            Building = 3,                       -- 建筑
            Event = 4,                          -- 事件
            Prop = 5,                           -- 道具
            Resource = 6,                       -- 资源
            Decoration = 7,                     -- 装饰
        },
        -- 格子周围的6个格子
        AroundGridsOffset0 = {{x = -1, y = 1}, {x = -1, y = 0}, {x = 0, y = -1}, {x = 0, y = 1}, {x = 1, y = 1}, {x = 1, y = 0}},
        AroundGridsOffset1 = {{x = -1, y =-1}, {x = -1, y = 0}, {x = 0, y = -1}, {x = 0, y = 1}, {x = 1, y =-1}, {x = 1, y = 0}},
        -- 已探索的来源类型
        ExploredType = {
            Explore = 0,        -- 消耗行动点探索格子获得
            Building = 1,       -- 赠送建筑获得
        },
        -- 资源Id
        ResourceId = {
            Invalid = 0,        --无效
            Exp = 1,            --经验
            Gold = 2,           --金币
            Population = 3,     --人口
            ActionPoint = 4,    --行动点
            SightRange = 5,     --视野范围
        },
        -- 货物Ids
        CommodityIds = {1, 2, 3},
        StageType = {
            Teach = 1,       -- 教学关
            Normal = 2,      -- 普通关
        },
        -- 奖励类型
        RewardType = {
            Assorted = 0,    -- 混合
            Resource = 1,    -- 资源
            Commodity = 2,   -- 货物
            Prop = 3,        -- 道具
            Building = 4,    -- 建筑
            Event = 5,       -- 事件
            City = 6,        -- 城邦
            Buff = 7,        -- buff 奖励弹框使用
        },
        -- 来源类型
        SourceType = {
            None = 0,
            Volatility = 1, -- 波动
            Prop = 2,       -- 道具
            Tech = 3,       -- 科技
            City = 4,       -- 城邦
            Building = 5,   -- 建筑
            Event = 6,      -- 事件
            Token = 7,      -- 信物
            Explore = 8,    -- 探索
            Cheat = 99,     -- 作弊
        },
        -- 视野增加类型
        AddVisibleGridIdType = {
            ByParent = 1,           -- 按父节点增加
            ByArea = 2,             -- 按区域增加
        },
        -- 统计类型
        StatisticsType = {
            CommoditySale = 1,   -- 商品销售统计
            CommodityProduce = 2,-- 商品生产统计
            EventTrigger = 3,    -- 事件触发 
            GoldAdd = 4,         -- 金币增加统计
            GoldInTurnAdd = 5,   -- 回合内金币增加统计
            ExpAdd = 6,          -- 经验增加统计
        },
        -- 图鉴类型
        IllustrateType = {
            Props = 1,           -- 道具
            Build = 2,           -- 建筑
            City = 3,            -- 城邦
            Event = 4,           -- 事件
        },
        -- 任务状态
        TaskState = {
            Activated = 1,
            Achieved = 2,
            Finished = 3,
        },
        -- 杂项加成
        MiscAdd = {
            BuildingDiscount = 1,       -- 建筑折扣
            TechDiscount = 2,           -- 科技点亮折扣
            MainDiscount = 3,           -- 主城升级折扣
            ExploreExpFixAdd = 4,       -- 繁荣度获取效率提升（固定值）
            ExploreExpRateAdd = 5,      -- 繁荣度获取效率提升（万分比）
            ActionPoint = 6,            -- 行动点上限
            ExploreGoldFixAdd = 7,      -- 探索金币获取效率提升（固定值）
            ExploreGoldRateAdd = 8,     -- 探索金币获取效率提升（万分比）
            BuildingGoldRateAdd = 9,    -- 建筑金币获取效率提升（万分比）
        },
        -- 资源属性类型
        CommodityAttrType = {
            Stock = 0,                -- 库存
            StockLimit = 1,           -- 库存上限
            StockLimitAdd = 2,        -- 库存上限加成
            PriceRateLockMax = 3,     -- 波动上限锁定
            PriceRateLockMin = 4,     -- 波动下限锁定
            StockTurnFixAdd = 5,      -- 库存回合开始时固定增减属性
            StockTurnRatioAdd = 6,    -- 库存回合开始时比率增减属性

            Price = 100,              -- 结算售价
            PriceBase = 101,          -- 基础售价
            PriceCrit = 102,          -- 售价暴击率
            PriceCritHurt = 103,      -- 售价暴伤率

            Produce = 200,            -- 结算产量
            ProduceBase = 201,        -- 基础产量
            ProduceCrit = 202,        -- 产量暴击率
            ProduceCritHurt = 203,    -- 产量暴伤率

            PriceAddBase = 1001,      -- 售价基础加成
            PriceAddFixed = 1002,     -- 售价固定加成
            PriceAddRatioA = 1003,    -- 售价比率加成
            PriceAddRatioB = 1004,    -- 售价波动（2级比率加成）
            PriceCritAdd = 1005,      -- 售价暴击率加成
            PriceCritHurtAdd = 1006,  -- 售价暴伤率加成
            PriceMaxRateAdd = 1007,   -- 市场波动上限加成
            PriceMinRateAdd = 1008,   -- 市场波动下限加成

            ProduceAddBase = 2001,    -- 产量基础加成
            ProduceAddFixed = 2002,   -- 产量固定加成
            ProduceAddRatioA = 2003,  -- 产量比率加成
            ProduceAddRatioB = 2004,  -- 产量波动（2级比率加成） 预留
            ProduceCritAdd = 2005,    -- 产量暴击率加成
            ProduceCritHurtAdd = 2006 -- 产量暴伤率加成
        },
        -- 科技树科技类型
        TechType = {
            Normal = 1,               -- 普通科技
            Level = 2,                -- 关键科技
        },
        Alignment = {
            Default = 0,             -- 默认
            LT = 1,                  -- 左上(目标UI的RT)
            RT = 2,                  -- 右上(目标UI的LT)
            LB = 3,                  -- 左下(目标UI的RB)
            RB = 4,                  -- 右下(目标UI的LB)
            CT = 5,                  -- 中上(目标UI的CB)
            CB = 6,                  -- 中下(目标UI的CT)
            LC = 7,                  -- 左中(目标UI的RC)
            RC = 8,                  -- 右中(目标UI的LC)
            LTB = 9,                 -- 左上(目标UI的LB)
            RTB = 10,                -- 右上(目标UI的RB)
        },
        -- 弹框类型
        PopupType = {
            None = 0,
            Buff = 1,                -- Buff弹框
            PropSelect = 2,          -- 道具选择弹框
            Reward = 3,              -- 奖励弹框
            Task = 4,                -- 城邦任务完成弹框
            TurnReward = 5,          -- 回合奖励弹框
            MainLevelUp = 6,         -- 主城升级弹框
            ExploreGrid = 10,        -- 探索格子信息
            VisibleGrid = 11,        -- 额外格子信息(镜头移动)
        },
        -- 条件操作类型
        ConditionOperateType = {
            None = 0,
            Greater = 1,             -- 大于
            GreaterEqual = 2,        -- 大于等于
            Equal = 3,               -- 等于
            LessEqual = 4,           -- 小于等于
            Less = 5,                -- 小于
        },
        BubbleType = {
            None = 0,
            Buff = 1,                -- buff气泡
            AssetDetail = 2,         -- 货物详情气泡
            Population = 3,          -- 人口气泡
            Property = 4,            -- 属性气泡
        },
    },
    DlcRoom = {
        RECONNECT_FAIL = {
            TEAM_SUCCESS = 1,
            TEAM_FAIL = 2,
            TIME_OUT = 3,
        },
        RoomSelect = {
            Character = 0,
            Chip = 1,
            None = 1001,
        },
        PlayerState = {
            Normal = 0,
            Ready = 1,
            Select = 2,
            Clump = 3,
            Fight = 4,
            Settle = 5,
            None = 1001,
        },
        RoomState = {
            Normal = 0,
            Fight = 1, --战斗
            Settle = 2, --结算
            None = 1001,
        },
        RoomUiType = {
            Room = 1,
            Loading = 2,
            ChallengeLose = 3,
            QuitDialog = 4,
            ReconnectDialog = 5,
            CancelMatchDialog = 6,
        },
    },
    DlcCasualGame = {
        WorldMode = {
            Easy = 1,
            Difficulty = 2,
        },
        TaskGroupType = {
            Daily = 1,
            Normal = 2,
        },
        ActivityType = {
            Cube = 1,  --Dlc魔方嘉年华
        }
    },
    DlcWorld = {
        WorldType = {
            Hunt = 1,  --狩猎
            Cube = 2,  --Dlc魔方嘉年华
        },
        SettleState = {
            None = 0,  --正常结算
            Exit = 1,  --中途退出
            LeaderExit = 2, --房主主动退出
        },
    },
    StrongHold = {
        AttrPluginId = 1, --攻击插件Id
    },
    CerberusGame = {
        ChapterIdIndex = {
            Story = 1,
            Challenge = 2,
            FashionStory = 3,
            FashionChallenge = 4,
        },
        StageDifficulty = {
            Normal = 1,
            Hard = 2,
        },
        StoryPointType = 
        {
            Story = 1,
            Communicate = 2,
            Battle = 3,
        },
        StoryPointShowType = 
        {
            [1] = "GirdStageFight",
            [2] = "GirdStageFightSpecial",
            [3] = "GridBossPrefab",
            [4] = "GridStory1",
            [5] = "GridStory2",
        },
        -- 默认队伍
        ChallengeStageStar = 
        {
            [0] = "CerberusGameChallengeStageStar0",
            [1] = "CerberusGameChallengeStageStar1",
            [2] = "CerberusGameChallengeStageStar2",
            [3] = "CerberusGameChallengeStageStar3",
        },
    },
    BFRT = {
        CAPTIAN_MEMBER_INDEX = 1,
        FIRST_FIGHT_MEMBER_INDEX = 1,
        MEMBER_POS_COLOR = {
            "FF1111FF", -- red
            "4F99FFFF", -- blue
            "F9CB35FF", -- yellow
        }
    },
    Archive={
        SubSystemType = {
            Monster = 1,
            Weapon = 2,
            Awareness = 3,
            Story = 4,
            CG = 5,
            NPC = 6,
            Email = 7,
            Partner = 8,
            PV = 9,
        },
        SettingType = {
            All = 0,
            Setting = 1,
            Story = 2,
        },
        -- 设定位置
        SettingIndex = {
            First = 1,
        },
        WeaponCamera = {
            Main = 1, --  武器详情默认是主镜头
            Setting = 2,
        },
        MonsterType = {
            Pawn = 1,
            Elite = 2,
            Boss = 3,
        },
        MonsterInfoType = {
            Short = 1,
            Long = 2,
        },
        MonsterSettingType = {
            Setting = 1,
            Story = 2,
        },
        MonsterDetailType = {
            Synopsis = 1,
            Info = 2,
            Setting = 3,
            Skill = 4,
            Zoom = 5,
            ScreenShot = 6,
        },
        EquipStarType = {
            All = 0,
            One = 1,
            Two = 2,
            Three = 3,
            Four = 4,
            Five = 5,
            Six = 6,
        },
        EquipLikeType = {
            NULL = 0,
            Dis = 1,
            Like = 2,
        },
        OnForAllState = {
            Off = 0,
            On = 1,
        },
        NpcGridState = {
            Open = 0,
            Close = 1,
        },
        EmailType = {
            Email = 1,
            Communication = 2,
        },
        PartnerSettingType = {
            Setting = 1,
            Story = 2,
        },
        MonsterDetailUiType = {
            Default = 1, -- 默认图鉴打开
            Show = 2, -- 只负责显示，屏蔽玩家操作
        },
        SpecialData = { --特判数据（仅武器天狼星使用）
            PayRewardId = 5,
            Equip = {--天狼星
                ResonanceCount = 0,
                Level = 1,
                Breakthrough = 0,
                Id = 2026003,
            },
        },
        EntityType = {
            Info = 1,
            Setting = 2,
            Skill = 3,
        },
        EquipInfoChildUiType = {
            Details = 1,
            Setting = 2,
        },
        MonsterRedPointType = {
            Monster = 1,
            MonsterInfo = 2,
            MonsterSkill = 3,
            MonsterSetting = 4,
        },
        METHOD_NAME = {
            GetEvaluateRequest = "GetEvaluateRequest",
            GetStoryEvaluateRequest = "GetStoryEvaluateRequest",
            ArchiveEvaluateRequest = "ArchiveEvaluateRequest",
            ArchiveGiveLikeRequest = "ArchiveGiveLikeRequest",
            UnlockMonsterSettingRequest = "UnlockMonsterSettingRequest",
            UnlockArchiveMonsterRequest = "UnlockArchiveMonsterRequest",
            UnlockMonsterInfoRequest = "UnlockMonsterInfoRequest",
            UnlockMonsterSkillRequest = "UnlockMonsterSkillRequest",

            UnlockArchiveWeaponRequest = "UnlockArchiveWeaponRequest",
            UnlockArchiveAwarenessRequest = "UnlockArchiveAwarenessRequest",
            UnlockWeaponSettingRequest = "UnlockWeaponSettingRequest",
            UnlockAwarenessSettingRequest = "UnlockAwarenessSettingRequest",
        },
        SYNC_EVALUATE_SECOND = 5,
    },
    Anniversary={
      ActivityType={
        SignIn=1,--签到
        DayDraw=2,--每日抽卡
        AnniversaryDraw=3,--周年卡池
        Review=4,--周年回顾
        RepeatChallenge=5,--复刷关
        FirstRecharge=6,--首充
      },
      ShareResult={
          Success=0,--分享成功
          ErrCodeUnInstalled=1, --应用未安装
          ErrCodeInvalidParameter=2, --传递参数错误
          ErrCodeImageExceedsTheSizeLimit=3, --图片大小超过限制
          ErrCodeInvalid=4, --未知错误
      },
      ReviewDataType={
        None=0,--没有数据
        PlayerBaseData=1, --昵称、入坑时间、加入的公会名
        ActionData=2, --今年 登录天数、消耗血清、消耗螺母
        CharaData1=3,--战力最高角色及其战力参数，出战次数最高的角色，及其出战次数，拥有辅助机的数量
        CharaData2=4, --在宿舍中被抚摸次数最高的角色，以及其次数|作为看板娘被点击次数最高的角色，及其次数|在宿舍中执勤次数最高的角色，以及其次数|拥有多少个达到爱意好感度的角色
        ActivityProcess1=5, --主线进度,边境公约进度已通关数,序列公约已通关数
        ActivityProcess2=6, --玩家在战区结算时，最高两个段位的达成次数|玩家在囚笼结算时累计的讨伐值|玩家在矿区结算时，最高一个矿区关底关卡的过关次数
        Reward1=7, --勋章展示
        Reward2=8, --收藏品展示
      },
      SharePlatform={
          KJQ_Share=1, --分享到库街区
      }
    },
}