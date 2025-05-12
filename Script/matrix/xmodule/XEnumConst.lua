XEnumConst = {
    CustomReportModuleId = {
        XTaskManager = "XTaskManager",
        XTeam = "XTeam"
    },
    MAIL_STATUS = {
        STATUS_UNREAD = 0,
        STATUS_READ = 1 << 0,
        STATUS_GETREWARD = 1 << 0 | (1 << 1),
        STATUS_DELETE = 1 << 2,
    },
    PLAYER = {
        GENDER_TYPE = {
            MAN = 1,        -- 男
            WOMAN = 2,      -- 女
            SECRECY = 3,    -- 保密
        },
        -- 未设置/设置保密 性别按男性处理XEnumConst.PLAYER.GENDER_TYPE.MAN
        DEFAULT_GENDER_TYPE = 1,
    },
    MailType = {
        Normal = 0, --普通邮件
        FavoriteMail = 1, --收藏角色好感邮件
        SpecialMail = 3, --与CS端的MailType.Special枚举对应
    },
    EQUIP = {
        MIN_LEVEL = 1, -- 装备：最低等级
        MIN_BREAKTHROUGH = 0, -- 装备：最低突破数
        MAX_STAR_COUNT = 6, -- 装备：最大星星数
        MAX_ATTR_COUNT = 2, -- 装备：最大属性数量
        MIN_RESONANCE_EQUIP_STAR_COUNT = 5, -- 共鸣：装备最低星级
        MAX_RESONANCE_SKILL_COUNT = 3, -- 共鸣：装备最大共鸣数量
        WEAPON_RESONANCE_COUNT = 3, -- 共鸣：武器的共鸣数量
        AWARENESS_RESONANCE_COUNT = 2, -- 共鸣：意识的共鸣数量
        MAX_AWAKE_COUNT = 2, -- 超频：意识的最大超频个数
        AWAKE_CRYSTAL_MONEY = 2, -- 超频：超频激活的晶币
        OVERRUN_ADD_SUIT_CNT = 2, -- 超限：超限增加意识数量
        OVERRUN_BLIND_SUIT_MIN_QUALITY = 6, -- 超限：超限绑定意识的最低品质
        WEAR_AWARENESS_COUNT = 6, -- 角色：可穿戴意识的数量
        OLD_MAX_SUIT_SKILL_COUNT = 3, -- 旧的最大的意识套装技能数量
        MAX_SUIT_SKILL_COUNT = 4, -- 最大的意识套装技能数量
        SUIT_MAX_SKILL_COUNT = 3, -- 同一意识套装里最大技能数量
        CAN_NOT_AUTO_EAT_STAR = 5, -- 大于等于该星级的装备不会被当做默认狗粮选中
        FIVE_STAR = 5, -- 5星
        SIX_STAR = 6, -- 6星
        STRENGTHEN_EXP_OVERFLOW_CONFIRM = 300, -- 强化经验溢出超过这个值需要二次确认
        ALL_SUIT_ID = 0, -- 显示全部套装对应的id
        MAX_SUIT_COUNT = 6, -- 套装最大数量

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
            AWARENESS = {
                ONE = 1, -- 1号位
                TWO = 2, -- 2号位
                THREE = 3, -- 3号位
                FOUR = 4, -- 4号位
                FIVE = 5, -- 5号位
                SIX = 6, -- 6号位
            },
        },
        -- 装备适用角色类型
        USERTYPE = {
            ALL = 0, --通用
            NORMAL = 1, --构造体
            ISOMER = 2, --异构体/感染体
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
        -- 武器超限解锁类型
        WEAPON_OVERRUN_UNLOCK_TYPE = {
            SUIT = 1, -- 意识套装
            ATTR_EFFECT = 2, -- 属性效果
        },
        -- 要显示的属性排序
        ATTR_SORT_TYPE = {
            XNpcAttribType.Life,
            XNpcAttribType.AttackNormal,
            XNpcAttribType.DefenseNormal,
            XNpcAttribType.Crit,
        },
        -- 装备分类
        CLASSIFY = {
            WEAPON = 1, -- 武器
            AWARENESS = 2, -- 意识
        },
        -- 武器部位
        WEAPON_CASE = {
            CASE1 = 1,
            CASE2 = 2,
            CASE3 = 3,
        },
        -- 用来显示全部套装数量的默认套装Id
        DEFAULT_SUIT_ID = {
            NORMAL = 1, -- 泛用机体
            ISOMER = 2, -- 独域机体
        },
        -- 武器指定状态机相关
        SIGNBOARD_ACTIVE_TYPE = {
            CHARACTER = 1,
            FASHION = 1,
        },
    },
    FuBen = {
        PlayerAmount = 3,
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
            CustomRecordFightBeginData = "CustomRecordFightBeginData",
            GetDifficult = "GetDifficult",
            CheckIsOpen = "CheckIsOpen",
            GetChapterId = "GetChapterId",
            GetOrderId = "GetOrderId",
            GetStarMap = "GetStarMap",
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
            KotodamaActivity = 86, --言灵
            Mainline2 = 87, -- 主线2.0
            LinkCraftActivity = 88, -- 战双工艺
            BossInshot = 89, -- Boss跃升
            MechanismActivity = 90, -- 机制玩法
            Theatre4 = 91, -- 肉鸽4.0
            SucceedBoss = 92, -- 超难BOSS
            FpsGame = 93, --首席打枪
            FavorabilityStory = 95, -- 好感度剧情关
            StageMemory = 96, --策划精选关
            Maverick3 = 97, --孤胆枪手
            ScoreTower = 98, -- 新矿区
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
            FangKuai = 95, -- 大方块
            MainLine2 = 96, -- 主线2
            DlcMultiMouseHunter = 97, -- Dlc猫鼠游戏
            BossInshot = 98, -- Boss跃升
            Theatre4 = 99, -- 肉鸽4.0
            SucceedBoss = 100, -- 超难BOSS
            FpsGame = 101, -- 首席打枪
            Maverick3 = 102, -- 孤胆枪手
            Pcg = 103, -- 打牌
            ScoreTower = 104, -- 新矿区
        },
        CharacterLimitType = {
            All = 0, --构造体/感染体
            Normal = 1, --构造体
            Isomer = 2, --感染体
            IsomerDebuff = 3, --构造体/感染体(Debuff) [AKA:低浓度区]
            NormalDebuff = 4, --构造体(Debuff)/感染体 [AKA:重灾区]
        },
        -- 通用编队房间每个位置的编辑权限
        StageLineupType = {
            RobotOnly = 1, --只允许使用配置给定的机器人
            CharacterOnly = 2, --只允许使用与配置给定同角色的机体
            Free = 3, --自由上阵不与限制冲突的机体
            Lock = 4, --禁止上阵任何角色
        }
    },
    CHARACTER = {
        BUTTON_SKILL_TEACH_ACTIVE = false, -- 角色详情界面的教学按钮显示状态
        BUTTON_SKILL_DETAILS_ACTIVE = true, -- 角色技能详情按钮状态
        MAX_LEBERATION_SKILL_POS_INDEX = 13, -- 角色终阶解放技能ID约定配置
        MAX_SHOW_SKILL_POS = 4, -- 展示用技能组数量
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
        -- 角色类型
        CharacterType = {
            Normal = 1, --构造体
            Isomer = 2, --异构体/感染体
            Robot = 3, --试玩角色
            Sp = 4, --Sp角色
        },
        --角色解放等级
        GrowUpLevel = {
            New = 1, -- 新兵
            Lower = 2, -- 低级
            Middle = 3, -- 中级
            Higher = 4, -- 终阶
            Super = 5, -- 超级
            End = 5,
        },
        -- 推荐类型
        RecommendType = {
            Character = 1, --推荐角色
            Equip = 2, --推荐装备
        },
        XUiCharacter_Camera = {
            MAIN = 0,
            LEVEL = 1,
            GRADE = 2,
            QULITY = 3,
            SKILL = 4,
            EXCHANGE = 5,
            ENHANCESKILL = 6,
        },
        SkillUnLockType = {
            Enhance = 1,
            Sp = 2,
        },
        SkillDetailsType = {
            Normal = 1,
            Enhance = 2,
        },
        -- 信号球颜色
        CharacterLiberateBallColorType = {
            Red = 1,
            Yellow = 2,
            Blue = 3,
        },
        -- 职业类型
        Career = 
        {
            None = 0, -- 无
            Attacker = 1, -- 攻击
            Tank = 2, -- 装甲
            Support = 3, -- 辅助
            Vanguard = 4, -- 先锋
            Amplifier = 5, -- 增幅
            Annihilator = 6, -- 湮灭
            Observation = 7, -- 侦察
        },
        -- 元素类型
        Element = {
            Physical = 1,   --物理
            Fire = 2,       --火
            Ice = 3,        --冰
            Lightning = 4,  --雷
            Dark = 5,       --暗
            Nihil = 6,      --空
        }
    },
    Filter = {
        MaxEnableElementNum = 6,
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
            BtnElement6 = "BtnElement6", -- 增加新元素时需要同步修改下下面的ElementTagId
        },
        BtnGeneralSkillType = { -- 效应筛选按钮的位置
            Left = 1, -- 左下角
            Bottom = 2, -- 展开/关闭按钮隔壁
        },
        ElementTagId = {    -- 根据页签名字获得选择的元素Id
            BtnElement1 = 1,
            BtnElement2 = 2,
            BtnElement3 = 3,
            BtnElement4 = 4,
            BtnElement5 = 5,
            BtnElement6 = 6,
        },
    },
    THEATRE3 = {
        ChapterType = {
            A = 1,
            B = 2,
        },
        --步骤类型
        StepType = {
            RecruitCharacter = 1, --设置编队
            Node = 2, --节点
            FightReward = 3, --战斗奖励
            ItemReward = 4, --具体道具奖励
            WorkShop = 5, --炼金工坊
            EquipReward = 6, --打开装备选择界面
            EquipInherit = 7, --打开装备继承界面
            LuckyCharSelect = 8, --天选角色选择
            PropSelect = 9, --初始道具选择
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
            None = 0, --无
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
            Rebuild = 1, --重铸
            ExChange = 2, --交换
            Qubit = 3, --量子化
        },
        EquipBoxType = {
            Normal = 0,
            Qubit = 2   --量子箱
        },
        QuantumType = {
            QuantumA = 1, --量子1
            QuantumB = 2, --量子2
            QuantumC = 3, --量子3
        },
        QuantumEffectShowType = {
            QuantumA = 1, --量子1
            QuantumB = 2, --量子2
            All = 3, --都显示
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
        SuitUseType = {
            Attribute = 1,
            OnSite = 2,
            Backend = 3,
        },
        EndingPassType = {
            Fail = 1,
            Success = 2,
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
            ItemCount = 3, -- 持有道具数
            CollectSuit = 4, -- 收集齐套装数
            FightAndBoss = 5, -- 关卡和boss节点收益不一致类型
        },
        RefreshBoxCoin = 96189, -- 刷新装备箱道具
        ShopType = {
            Normal = 1, -- 普通商店
            GiveMoney = 2, -- 给钱商店
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
        BOARD_WIDTH = 8, -- 棋盘宽度
        BOARD_HEIGHT = 8, -- 棋盘高度
        -- 角色技能
        CHARACTER_SKILL_TYPE = {
            BANSHOU_ADD_MOVE_RANGE = 8, -- 扳手小子增加移动距离
            BANSHOU_ADD_SKILL_RANGE = 9, -- 扳手跳劈增加技能范围
        },
        WEAPON_SKILL_TYPE = {
            SHOTGUN_ATTACK = 1,
            SHOTGUN_SKILL1 = 2,
            SHOTGUN_SKILL2 = 3,
            KNIFE_ATTACK = 4,
            KNIFE_SKILL1 = 5,
            KNIFE_SKILL2 = 6,
            LUNA_ATTACK = 7,
            LUNA_SKILL1 = 8,
            LUNA_SKILL2 = 9,
            LUNA_SKILL3 = 10,
            LUCIA_ATTACK = 11,
            LUCIA_SKILL1 = 12,
            LUCIA_SKILL2 = 13,
            VERA_ATTACK = 14, -- 薇拉普攻
            VERA_SKILL1 = 15, -- 普通格挡,
            VERA_RED_SKILL1 = 16, -- 红莲格挡
            VERA_SKILL2 = 17, -- 普通咖喱棒
            VERA_RED_SKILL2 = 18, -- 红莲咖喱棒
            VERA_SKILL3 = 19, -- 红莲大招
            BANSHOU_ATTACK = 20, -- 扳手小子普攻
            BANSHOU_SKILL = 21, -- 扳手小子技能
            BANSHOU_BIG_SKILL = 22, -- 扳手小子大招
            ZHETIAN_BLACK_ATTACK = 23, -- 遮天碧碧黑形态普攻
            ZHETIAN_BLACK_CHANGE = 24, -- 遮天碧碧黑形态切换白形态
            ZHETIAN_BLACK_SKILL = 25, -- 遮天碧碧黑形态技能
            ZHETIAN_BLACK_BIGSKILL = 26, -- 遮天碧碧黑形态大招
            ZHETIAN_WHITE_ATTACK = 27, -- 遮天碧碧白形态普攻
            ZHETIAN_WHITE_CHANGE = 28, -- 遮天碧碧白形态切换黑形态
            ZHETIAN_WHITE_SKILL = 29, -- 遮天碧碧白形态技能
            ZHETIAN_WHITE_BIGSKILL = 30, -- 遮天碧碧白形态大招
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
            --buff带来的转化
            TRANSFORM = 8,
            --放弃回合
            SKIP_ROUND = 9,
            --玩家复活
            CHARACTER_REVIVE = 10,
            --玩家被动
            CHARACTER_SKILL = 11,
            --角色反击
            CHARACTER_ATTACK_BACK = 12,
            --延迟技能使用
            DELAY_SKILL = 13,
            --召唤虚影
            SUMMON_VIRTUAL = 14,
        },
        REINFORCE_TYPE = {
            --棋盘指定位置
            SPECIFIC = 2,
            --国王周围随机
            KING_AROUND = 1,
            --国王相对位置
            KING_RELATIVE = 3,
            --主控角色身边
            MASTER_AROUND = 4,
            --主控相对位置
            MASTER_RELATIVE = 5,
        },
        PLAYER_MEMBER_ID = -1, --玩家在Layout的MemberId
        CHESS_MEMBER_TYPE = {
            MASTER = 1, --玩家主控角色
            PIECE = 2, --敌人
            REINFORCE_PREVIEW = 3, --敌人增援
            ASSISTANT = 4, --玩家召唤角色
            PARTNERPIECE_PREVIEW = 5, -- 友方棋子预告
            PARTNERPIECE = 6, -- 友方棋子
            BOSS = 7, -- Boss
            PIECE_PREVIEW = 8, -- Boss召唤敌方棋子预览
        },
        CHESS_OBJ_TYPE = {
            CHARACTER = 1,
            ENEMY = 2,
            PARTNER = 3,
            BOSS = 4,
        },
        SKILL_TIP_TYPE = {
            WEAPON = 1, -- 武器Tip
            WEAPON_SKILL = 2, -- 武器技能Tip
            CHARACTER_SKILL = 3, -- 角色技能Tip
            CHARACTER = 4, -- 角色Tip
        },
        SKILL_TIP_ALIGN = {
            LEFT = 1,
            RIGHT = 2,
        },
        DIFFICULTY = {
            NORMAL = 1,
            HARD = 2
        },
        CUE_ID = {
            PIECE_BREAK = 5582, --棋子破碎（策划配在特效里了 不需要手动播放）
            REINFORCE_COMING = 4178, --增援触发
            PIECE_BUFF = 4179, --棋子Buff
            CHANGE_PIECE_TARGET = 4181, --更换目标
            PIECE_MOVED = 4182, --棋子落子
            GAME_WIN = 4183, --游戏胜利
            STAND_BLACK = 4444, --站在黑色格子
            STAND_WHITE = 4445, --站在白色格子
            THUNDER_BREAK = 4442, --雷电击碎
            JUMP_MOVE = 5579, --角色跳跃移动
            TELEPOR_MOVE = 4634, --角色瞬移移动
            ENTER_RED_MODEL = 5577, --角色进入红怒模式
            DEFENSE_SUCCESS = 5580, --格挡成功
            DEFENSE_ATTACK = 4442, --格挡反击
            BANSHOU_BIGSKILL = 5568, -- 扳手释放必杀音效
            BANSHOU_SKILL = 5570, -- 扳手释放技能音效
            BANSHOU_ATTACK = 5571, -- 扳手普攻音效
            BANSHOU_ATTACKED = 5569, -- 扳手受击音效
            ZHETIAN_BIGSKILL = 5585, --遮天碧碧大招音效
            ZHETIAN_SKILL = 5584, -- 遮天碧碧技能音效
            ZHETIAN_ATTACK = 5583, -- 遮天普攻技能音效
        },
        CHARACTER_TYPE = {
            MASTER = 1, --主控角色
            ASSISTANT = 2, --召唤角色
        },
        STAGE_STATE = {
            STAGE_END = 1, --关卡结束
            ROUND_EXTRA = 2, --额外回合
            ROUND_END = 3, --回合结束
            ACTOR_CHANGE = 4, --更换操作角色
        },
        MASK_KEY = "BlackRockChess",
        NODE_TYPE = {
            NORMAL = 1,
            BOSS = 2,
        },
        GOOD_TYPE = {
            PIECE = 1,
            BUFF = 2,
        },
        PIECE_TYPE = {
            PARTNER = 1, -- 友方
            ENEMY = 2, -- 敌方
        },
        PARTNER_PIECE_STATE = {
            SITE = 1, -- 备战
            GOINTO_BATTLE = 2, --上阵
            BATTLE = 3, -- 战斗
        },
        CONDITION_TYPE = {
            ENTER_RED_MODEL = 6, -- 当前能量达到N时进入红莲状态
            WEAPON = 7, -- 获得指定武器
        },
        -- 武器类型
        WEAPON_TYPE = {
            VERA_NORMAL = 5,    --薇拉普通
            VERA_REDMODEL = 6,  --薇拉红莲
            BANSHOU = 7, -- 扳手小子的武器
            ZHETIAN_WHITE = 8, -- 遮天碧碧的白武器
            ZHETIAN_BLACK = 9, -- 遮天碧碧的黑武器
        },
        CHESS_TYPE = {
            --士兵
            PAWN = 1,
            --骑士
            KNIGHT = 2,
            --主教
            BISHOP = 3,
            --城堡
            ROOK = 4,
            --女王
            QUEEN = 5,
            --国王
            KING = 6,
        },
        -- 特效Id
        EFFECT_ID = {
            DANGER_EFFECT = 45, --危险区域（红色）
            DELAY_DAMAGE_WARNING = 64, -- 延迟伤害预警
            BANSHOU_BIGSKILL_EFFECT1 = 65, -- 扳手大招特效符号
            BANSHOU_BIGSKILL_EFFECT2 = 66, -- 扳手大招常驻特效
            BANSHOU_SKILL_EFFECT = 67, -- 扳手跳劈技能延迟结算格子伤害特效
            BANSHOU_SKILL_SCREAN_EFFECT = 68, -- 扳手跳劈技能处于大招状态下时的震屏特效
            BANSHOU_ATTACK_EFFECT = 69, -- 扳手普攻特效
            ZHETIAN_ATTACK = 70, -- 遮天碧碧普攻雷击特效
            ZHETIAN_CHANGE_EFFECT = 71, -- 切换形态表情
            ZHETIAN_CHANGE_EFFECT_BLACK = 72, -- 黑色切入特效
            ZHETIAN_CHANGE_EFFECT_WHITE = 73, -- 白色切入特效
            ZHETIAN_SKILL_EFFECT1 = 74, -- 雷击技能表情
            ZHETIAN_SKILL_EFFECT2 = 75, -- 雷击技能特效
            ZHETIAN_BIGSKILLSKILL_EFFECT = 76, -- 召唤表情
            ZHETIAN_BIGSKILLSKILL_DISAPPER = 77, -- 第一次延迟阶段消失特效
            ZHETIAN_BIGSKILLSKILL_LOCK_GRID = 78, -- 第一次延迟阶段锁定格子特效特效
            ZHETIAN_BIGSKILLSKILL_THUNDER = 79, -- 第一次延迟阶段锁定格子特效特效
            VERA_ENERGY_NOTFULL = 82, --薇拉红怒且怒气未满
            VERA_ENERGY_FULL = 83, --薇拉红怒且怒气已满
            VERA_DEFENCE = 84, --薇拉普通格挡
            VERA_DEFENCE_SUCCESS = 85, --薇拉普通格挡成功
            VERA_REDMODEL_DEFENCE = 86, --薇拉红怒格挡
            VERA_BLEND = 88, --薇拉融合
            NODE_SUCCESS = 89, --节点胜利
            VERA_REDMODEL_DEFENCE_ATTACK_1 = 90, --薇拉红怒格挡反击
            VERA_REDMODEL_DEFENCE_ATTACK_2 = 91, --薇拉红怒格挡刀光
            BLACK_HOLE = 93, --底板黑洞
            ZHETIAN_BIGSKILLSKILL_LOOP = 98, -- 遮天碧碧大招期间常驻特效
        },
        -- Buff类型
        BUFF_TYPE = {
            INVINCIBLE_ATTACK_CNT = 2, -- 免疫伤害次数
        },
        -- Buff目标
        BUFF_TARGET_TYPE = {
            BOSS = 200,
        },
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
        },
        UiSceneSettingMainBtnSyncState =
        {
            Enable = 0,
            Using = 1,
            Lock = 2,
        },
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
            6, 5, 4, 3  -- 插件星级筛选器
        },
        SpecialGoldTag = 7, -- 暗金标签Id（暗金装备特殊显示）
        RandomShopGoodType = 2, -- 商店随机物品类型
        FilterSetting = {
            PluginChoose = 1, -- 插件选择
            PluginShop = 2, -- 插件商店
        },
        StarConditionType = 10171,
        StageGroupType = {
            Normal = 1,
            Zoom = 2, -- 跃升（废弃）
            Multi = 3, -- 多关卡（废弃）
        },
        FuncUnlockId = {
            Attribute = 1,
            LuckyStage = 2,
            PluginShop = 3,
            Mopup = 4,
            Plugin = 5,
        },
        AttrTemplateCnt = 5,
        DefaultAttrTemplateId = 1,
        LayerType = {
            Normal = 1,
            Zoom = 2, -- 跃升（废弃）
            Multi = 3, -- 多关卡（废弃）
            Challenge = 4, -- 挑战关
        },
        AttributeLevelStr = {
            [1] = "B",
            [2] = "A",
            [3] = "S",
        },
        AttributeFixEffectType = -- 属性补正效果类型
        {
            Value = 1, -- 加成值
            Percent = 2, -- 加成百分比
        },
        AttrCnt = 4, -- 属性数量
        Currency = 63401, -- 解锁/重置词条、购买插件消耗的货币
    },
    SAME_COLOR_GAME = {
        ---数据同步类型
        ACTION_TYPE = {
            NONE = 0,
            MAP_INIT = 1, --地图初始化
            ITEM_REMOVE = 2, --消除
            ITEM_DROP = 3, --下落
            ITEM_CREATE_NEW = 4, --新增
            MAP_SHUFFLE = 5, --洗牌（飘字）
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
            TIME_ADD = 21, -- 增加时间
            ITEM_SWAP_EX = 22, --交换列
            PROP_CREATE_NEW = 23, --新增道具
            ITEM_TRANSFORM = 24, --球变化
            PROP_TRIGGER = 25, --道具触发
            WEAK_Hit = 26, -- 破绽受击
            NEW_MAP_SHUFFLE = 27, --洗牌（不飘字）
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
            LOCAL_ONE = 2, -- 定点单特效
            LOCAL_TWO = 3, -- 定点双特效
            LIFU = 4, -- 丽芙延申特效
        },
        SKILL_EFFECT_TIME_TYPE = {
            BEFORE_REMOVE = 1, -- 消球前
            REMOVE = 2, -- 消球时
            CHANGER_BALL = 3, -- 换球时
        },
        ---消球Action中球类型
        BALL_REMOVE_TYPE = {
            NONE = 0, -- 默认
            BOOM_CENTER = 1, -- v1.31 三期爆炸技能爆炸中心
            LIFU_ROW = 2, -- 丽芙横消
            LIFU_COL = 3, -- 丽芙纵消
            VERA_SKILL_LT = 4, -- 薇拉雷击左上角起始位置
            ALISA_LT = 5, -- 回音技能左上锚点
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
            ADD_STEP = 1, -- 增加步数
            SUB_STEP = 2, -- 减少步数
            ADD_DAMAGE = 3, -- 增加球百分比伤害
            SUB_DAMAGE = 4, -- 减少球百分比伤害
            NO_DAMAGE = 5, -- 免疫伤害
            COMBO_ADD_ENERGY = 6, -- Combo增加、减少能量buff
            REMOVE_ONT_BALL = 7, -- Combo结束后再随机消除1个球buff
            CHANGE_DROP_ITEM_COLOR = 8, -- 将下落的n个球改为指定颜色
            DROP_SPECIFY_ITEM = 9, -- 下落的n个球指定为某几种颜色
            ADD_TIME = 10, -- 加最大时间
            DROP_RAND_ITEM_COLOR = 11, -- 下落的n个球指定为随机配置种的某1种颜色
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
        ---道具球类型
        PropType = {
            DaoDan = 1, -- 导弹
            ZhaDan = 2, -- 炸弹
            ShiZi = 3, -- 十字
            TouZi = 4, -- 骰子
        },
        ---特效类型
        SkillType = {
            DaoDan = 1, -- 导弹
            ZhaDan = 2, -- 炸弹
            LineX = 3, -- 单行
            LineY = 4, -- 单列
            LineXY = 5, -- 十字
            TouZi = 6, -- 骰子
        },
        ---球类型
        BallType = {
            Normal = 1, --普通球
            Prop = 2, --道具球
            Weak = 3, --破绽球
        }
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
            UiPhotograph = 1, --拍照界面
            UiPhotographPortrait = 2, --拍照界面(竖屏)
            UiMain = 3, --主界面
            UiFavorabilityNew = 4, --看板娘界面
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
        StoryOpenType = { -- 好感度剧情开放类型
            OnlyOnwer = 1, -- 仅当玩家拥有对应角色时
            NoLimit = 2, -- 无限制
        },
        FavorabilityStoryEntranceType = { -- 入口类型：用于埋点
            FavorabilityMainFile = 1, --看板交流界面入口
            CharacterFile = 2, -- 档案/试玩关入口
            ExtraLine = 3, -- 支线章节入口
        },
        StoryLayoutBgType = { -- 好感度界面背景类型
            Default = 1, -- 默认旧版
            Style3_4 = 2, --3.4新增样式
        }
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
        UI_STATUS = {
            CHAPTER = 1,
            GAME = 2,
            CG = 3,
        },
        HELP_KEY = "ConnectingLineGame",
        COMPLETE_LINE_SOUND = 4271,
        TASK = 327
    },
    ---临时处理常量，一些特殊情况如：特定物品文本有误时特殊处理，将物品Id定义在这里，写明注释
    SpecialHandling = {
        ---黑岩超难关收藏品DEAD MASTER Id
        DEADCollectiblesId = 13019619,
        ---修特罗尔藏品
        ShotrolCollectiblesId = 13019648,
        ---21号森息涂装模型Id
        CoatingModelId = "R3TwentyoneMd019091",
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
            NOT_DOWNLOAD = 1, --未下载过
            PREPARE_DOWNLOAD = 2, --等待下载
            PAUSE = 3, --暂停
            DOWNLOADING = 4, --下载中
            COMPLETE = 5, --完全下载
        },
        CUSTOM_SUBPACKAGE_ID = {
            INVALID = -1, --无效Id
            NECESSARY = 0, --必要资源
        },
        ENTRY_TYPE = {
            MAIN_RIGHT_TOP_ACTIVITY = 9994, --主界面右侧活动按钮
            MAIN_LEFT_TOP_ACTIVITY = 9995, --主界面左侧活动按钮
            AUTO_WINDOW = 9996, --打脸图
            CHARACTER_VOICE = 9997, --CV-入口检测参数
            MATERIAL_COLLECTION = 9998, --战斗-资源-入口检测参数
            DRAW = 9999, --研发检测参数
        },
        SUBPACKAGE_TYPE = {
            NECESSARY = 1, --必要资源
            OPTIONAL = 2, --可选资源
        },
        TEMP_VIDEO_SUBPACKAGE_ID = {
            STORY = 904, --剧情视频
            GAMEPLAY = 905, --玩法视频
        }
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
        IsDebug = false,           -- 是否开启日志打印
        IsMapOptimization = false, -- 是否启用地图优化
        Percentage = 100,         -- 百分比
        Denominator = 10000,      -- 分母
        Inaccurate = 0.0000001,   -- 用于消除误差
        -- 区域解锁类型
        AreaUnlockType = {
            Buy = 1,           -- 购买解锁
            Reward = 2,        -- 任务/事件奖励解锁
            DefaultUnlock = 3, -- 默认解锁
        },
        -- 区域状态类型
        AreaStateType = {
            Invalid = 0,  -- 无效
            Hidden = 1,   -- 隐藏
            Locked = 2,   -- 锁定
            Unlocked = 3, -- 已解锁
        },
        -- 地貌类型
        LandformType = {
            Main = 1,          -- 主城
            City = 2,          -- 城邦
            Building = 3,      -- 建筑
            Event = 4,         -- 事件
            Prop = 5,          -- 道具
            Resource = 6,      -- 资源
            Block = 7,         -- 障碍, 无任何效果
            BuildingField = 8, -- 可放置建筑点
        },
        -- 资源Id
        ResourceId = {
            Invalid = 0,        --无效
            Exp = 1,            --经验
            Gold = 2,           --金币
            Population = 3,     --人口/生成力
            ActionPoint = 4,    --行动点 （已废弃）
            SightRange = 5,     --视野范围
            FreeBuildCount = 6, --免费建造次数
        },
        -- 货物Ids
        CommodityIds = { 1, 2, 3 },
        -- 奖励类型
        RewardType = {
            Assorted = 0,       -- 混合
            Resource = 1,       -- 资源
            Commodity = 2,      -- 货物
            Prop = 3,           -- 道具
            Building = 4,       -- 建筑
            Event = 5,          -- 事件
            City = 6,           -- 城邦
            BuildBluePrint = 7, -- 建筑蓝图
        },
        -- 来源类型
        SourceType = {
            None = 0,
            Volatility = 1,       -- 波动
            Prop = 2,             -- 道具
            Tech = 3,             -- 科技
            City = 4,             -- 城邦
            Building = 5,         -- 建筑
            Event = 6,            -- 事件
            Token = 7,            -- 信物
            Explore = 8,          -- 探索
            UnlockArea = 9,       -- 解锁区域
            TemporaryReward = 10, -- 临时背包奖励
            Cheat = 99,           -- 作弊
        },
        -- 视野增加类型
        AddVisibleGridIdType = {
            ByParent = 1, -- 按父节点增加
            ByArea = 2,   -- 按区域增加
        },
        -- 图鉴类型
        IllustrateType = {
            Props = 1, -- 道具
            Build = 2, -- 建筑
            City = 3,  -- 城邦
            Event = 4, -- 事件
        },
        -- 科技树科技类型
        TechType = {
            Normal = 1, -- 普通科技
            Level = 2,  -- 关键科技
        },
        Alignment = {
            Default = 0, -- 默认
            LT = 1,      -- 左上(目标UI的RT)
            RT = 2,      -- 右上(目标UI的LT)
            LB = 3,      -- 左下(目标UI的RB)
            RB = 4,      -- 右下(目标UI的LB)
            CT = 5,      -- 中上(目标UI的CB)
            CB = 6,      -- 中下(目标UI的CT)
            LC = 7,      -- 左中(目标UI的RC)
            RC = 8,      -- 右中(目标UI的LC)
            LTB = 9,     -- 左上(目标UI的LB)
            RTB = 10,    -- 右上(目标UI的RB)
        },
        -- 弹框类型
        PopupType = {
            None = 0,
            PropSelect = 1,     -- 道具选择弹框
            Reward = 2,         -- 奖励弹框
            MainLevelUp = 3,    -- 主城升级弹框
            CityLevelUp = 4,    -- 城邦升级弹框
            Task = 5,           -- 城邦任务完成弹框
            TurnReward = 6,     -- 回合奖励弹框
            AreaCanUnlock = 10, -- 区域变成可解锁
            AreaUnlock = 11,    -- 区域解锁
            GridLevelUp = 12,   -- 格子升级表现
            ExploreGrid = 13,   -- 探索格子信息
            VisibleGrid = 14,   -- 额外格子信息(镜头移动)
            ChangeGrid = 15,    -- 格子变化信息
            NewTips = 16,       -- 传闻提示弹框
        },
        BubbleType = {
            None = 0,
            Buff = 1,        -- buff气泡
            AssetDetail = 2, -- 货物详情气泡
            Population = 3,  -- 人口气泡
            Property = 4,    -- 属性气泡
        },
        EventType = {
            Normal = 0,     -- 普通事件
            Auction = 1,    -- 拍卖事件
            Gamble = 2,     -- 投机事件
        },
        BagGetRewardType = {
            Commodity = 1,  -- 货物
            Prop = 2,       -- 道具
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
            Match = 1, --匹配
            Fight = 2, --战斗
            Settle = 3, --结算
            Close = 4, --关闭
            None = 1001,
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
            Cube = 1, --Dlc魔方嘉年华
        }
    },
    DlcWorld = {
        WorldType = {
            Hunt = 1, --狩猎
            Cube = 2, --Dlc魔方嘉年华
            MouseHunter = 3, --猫鼠游戏
            BigWorld = 4, --大世界
        },
        SettleState = {
            None = 0, --正常结算
            ForceExit = 1, --未完成对局主动退出
            AdvanceExit = 2, --完成对局提前结算(不一定胜利)
            PlayerOffline = 3, --玩家掉线
            ErrorState = 1001, --状态错误
        },
        MatchStrategy = {
            Normal = 1, -- 单人匹配进入房间
            Multiplayer = 2, -- 多人匹配进入战斗
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
        StoryPointType = {
            Story = 1,
            Communicate = 2,
            Battle = 3,
        },
        StoryPointShowType = {
            [1] = "GirdStageFight",
            [2] = "GirdStageFightSpecial",
            [3] = "GridBossPrefab",
            [4] = "GridStory1",
            [5] = "GridStory2",
        },
        -- 默认队伍
        ChallengeStageStar = {
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
    Archive = {
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
            Comic = 10,
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
    Anniversary = {
        ActivityType = {
            SignIn = 1, --签到
            DayDraw = 2, --每日抽卡
            AnniversaryDraw = 3, --周年卡池
            Review = 4, --周年回顾
            RepeatChallenge = 5, --复刷关
            FirstRecharge = 6, --首充
            ReCall = 7, -- 召回活动
            BasicDraw = 8, -- 基准卡池
            ReviewH5 = 9, -- 周年回顾H5界面
        },
        ShareResult = {
            Success = 0, --分享成功
            ErrCodeUnInstalled = 1, --应用未安装
            ErrCodeInvalidParameter = 2, --传递参数错误
            ErrCodeImageExceedsTheSizeLimit = 3, --图片大小超过限制
            ErrCodeInvalid = 4, --未知错误
        },
        ReviewDataType = {
            None = 0, --没有数据
            PlayerBaseData = 1, --昵称、入坑时间、加入的公会名
            ActionData = 2, --今年 登录天数、消耗血清、消耗螺母
            CharaData1 = 3, --战力最高角色及其战力参数，出战次数最高的角色，及其出战次数，拥有辅助机的数量
            CharaData2 = 4, --在宿舍中被抚摸次数最高的角色，以及其次数|作为看板娘被点击次数最高的角色，及其次数|在宿舍中执勤次数最高的角色，以及其次数|拥有多少个达到爱意好感度的角色
            ActivityProcess1 = 5, --主线进度,边境公约进度已通关数,序列公约已通关数
            ActivityProcess2 = 6, --玩家在战区结算时，最高两个段位的达成次数|玩家在囚笼结算时累计的讨伐值|玩家在矿区结算时，最高一个矿区关底关卡的过关次数
            Reward1 = 7, --勋章展示
            Reward2 = 8, --收藏品展示
        },
        SharePlatform = {
            KJQ_Share = 1, --分享到库街区
        }
    },
    FangKuai = {
        ItemId = 1, --货币Id
        Expression = {
            Standby = 1, --待机
            ClearUp = 2, --清除
            Click = 3, --选中
        },
        ItemType = {
            LengthReduce = 1, --长度缩减
            SingleLineRemove = 2, --单行消除
            BecomeOneGrid = 3, --以大化小
            AddRound = 4, --加回合
            TwoLineExChange = 5, --双行交换
            AdjacentExchange = 6, --相邻交换
            Frozen = 7, --冰冻
            Alignment = 8, --磁吸
            RandomBlock = 9, --骰子A
            RandomLine = 10, --骰子B
            Convertion = 11, --净化
            Grow = 12, --生长
            Born = 13, --孵化
        },
        RoleAnim = {
            Standby = 1, -- 待机
            Attack = 2, -- 消除方块
            Joyful = 3, -- 出现特殊道具/获得道具
            Move = 4, -- 移动
        },
        BossAnim = {
            BossStandby = 1, -- 待机
            BossAttack = 2, -- 出现新行
        },
        OperateMode = {
            MoveX = 1,
            MoveY = 2,
            MoveUp = 3,
            Clear = 4, -- 清除一行
            Wane = 5, -- 变短
            Remove = 6, -- 只用在以大化小中
            Create = 7,
            Grow = 8,
        },
        Environment = {
            Up = 1, -- 上升规则变化
        },
        BlockType = {
            Invalid = 0, -- 无效
            Normal = 1, -- 普通
            BossWane = 2, -- 衰弱BOSS
            BossHit = 3, -- 受击BOSS
            BossFission = 4, -- 分裂BOSS
        },
        Difficulty = {
            Normal = 1,
            Hard = 2,
        },
        RecordUiType = {
            Fight = 1, -- 玩法主界面
            Main = 2, -- 活动主界面
        },
        RecordButtonType = {
            Leave = 1, -- 中途放弃
            GiveUp = 2, -- 主动放弃
            Reset = 3, -- 重置关卡
            Continue = 4, -- 继续游戏
        },
        DirectionType = {
            Random = 0, --随机
            Left = 1,
            Right = 2,
        },
        SimpleTab = 1,
        DifficultTab = 2,
        Settle = {
            Normal = 1, -- 正常结算
            GiveUp = 4, -- 放弃
            Reset = 2, -- 重置
            Advance = 3, -- 提前结算
        },
        ItemOperate = {
            Use = 0,
            Get = 1,
            Discard = 2, -- 丢弃
        },
    },
    GOLDEN_MINER = {
        PERCENT = 100,
        HOOK_IGNORE_HIT = "HookIgnoreHit",
        -- Camera
        CAMERA_TYPE = {         -- 摄像机类型
            MAIN = 1, -- 主界面
            CHANGE = 2, -- 更换角色
        },
        MAP_TYPE = {
            Normal = 0, -- 普通关
            Hide = 1, -- 隐藏关
        },
        MAP_SUN_MOON_TYPE = {
            NORMAL = 0, -- 无日月转换机制地图
            MOON = 1, -- 日月转换地图（初始为月状态）
            SUN = 2, -- 日月转换地图（初始为日状态）
        },
        -- Ship
        SHIP_APPEARANCE_ICON_KEY = {                    -- 飞船外观图标
            DEFAULT_SHIP = "DefaultShip", -- 默认飞船图标
            MAX_SPEED_SHIP = "MaxSpeedShip", -- 最高移动速度飞船图标
            MAX_CLAMP_SHIP = "MaxClampShip", -- 最速抓取飞船图标
            FINAL_SHIP = "FinalShip", -- 终极形态飞船图标
        },
        SHIP_APPEARANCE_SIZE_KEY = {                    -- 飞船外观尺寸
            DEFAULT_SHIP_SIZE = "DefaultShipSize", -- 默认飞船尺寸
            MAX_SPEED_SHIP_SIZE = "MaxSpeedShipSize", -- 最高移动速度飞船尺寸
            MAX_CLAMP_SHIP_SIZE = "MaxClampShipSize", -- 最速抓取飞船尺寸
            FINAL_SHIP_SIZE = "FinalShipSize"           -- 终极形态飞船尺寸
        },
        SHIP_MOVE_STATUS = {
            NONE = 1,
            LEFT = 2,
            RIGHT = 3,
        },
        -- Item
        ITEM_TYPE = {           -- 道具类型
            NORMAL_ITEM = 1, -- 普通道具
            LIFT_TIME_ITEM = 2, -- 带有生存时间的道具，不可主动使用
        },
        ITEM_CHANGE_TYPE = {    -- 道具状态改变类型
            ON_USE = 1, -- 消耗
            ON_GET = 2, -- 获得
        },
        -- Hook
        HOOK_TYPE = {                   -- 钩爪类型
            NORMAL = 1,
            MAGNETIC = 2, -- 电磁贯通
            BIG = 3, -- 大的钩爪
            AIMING_ANGLE = 4, -- 自瞄角度
            STORE_PRESS_MAGNETIC = 5, -- 长按电磁
            DOUBLE = 6, -- 双头替身
            HAMMER = 7, -- 锤头爪
        },
        GAME_SYSTEM_HOOK_STATUS = {     -- 飞船钩爪使用状态
            NONE = 0,
            IDLE = 1, -- 待使用
            USING = 2, -- 使用中
        },
        GAME_HOOK_STATUS = {            -- 钩爪状态
            NONE = 0,
            IDLE = 1, -- 待发射
            READY = 2, -- 按键 & 长按
            SHOOTING = 3, -- 发射中
            GRABBING = 4, -- 抓取中
            REVOKING = 5, -- 收回中
            QTE = 6, -- QTE
        },
        -- Stone
        STONE_TYPE = {                  -- 抓取物类型
            ALL = 999, -- 所有类型
            STONE = 1, -- 石头
            GOLD = 2, -- 黄金
            DIAMOND = 3, -- 钻石
            BOOM = 4, -- 炸弹
            MOUSE = 5, -- 定春
            RED_ENVELOPE = 6, -- 红包箱
            ADD_TIME_STONE = 7, -- 加时物品
            ITEM_STONE = 8, -- 道具(抓起来立刻使用)
            HOOK_DIRECTION_POINT = 9, -- 转向点(改变钩爪方向物体)
            MUSSEL = 10, -- 河蚌
            QTE = 11, -- QTE类型
            PROJECTION = 12, -- 投影
            PROJECTOR = 13, -- 投影仪
            AIM_DIRECTION = 14, -- 指定转向器(指定转向stoneId)
            RELIC_FRAG = 15, -- 遗迹碎片
            CAN_NOT_ADD_STONE_AREA = 16, -- 不能生成抓取物的区域
            SHIELD = 17, -- 盾牌
        },
        STONE_SUN_MOON_TYPE = {         -- 抓取物日月转换类型
            NORMAL = 0, -- 无日月转换
            MOON = 1, -- 月
            SUN = 2, -- 日
        },
        STONE_SUN_MOON_REAL_TYPE = {
            NONE = 0,
            REAL = 1, -- 实体
            VIRTUAL = 2, -- 虚拟 
        },
        GAME_STONE_STATUS = {
            NONE = 0,
            BE_ALIVE = 1, -- 延迟出现
            ALIVE = 2, -- 可被抓状态
            GRABBING = 3, -- 被抓住
            GRABBED = 4, -- 已被抓
            BE_DESTROY = 5, -- 将销毁(炸弹爆炸等)
            DESTROY = 6, -- 被销毁(自动销毁、被炸弹炸等)
            HIDE = 7, -- 隐藏状态(河蚌关闭、某种隐藏)
            SHIP_AIM = 8, -- (Partner)被小飞碟瞄准
            SHIP_CATCHING = 9, -- (Partner)被小飞碟收取中
        },
        GAME_STONE_MOVE_TYPE = {-- 抓取物移动状态
            NONE = 0, -- 静止
            HORIZONTAL = 1, -- 左右直线
            VERTICAL = 2, -- 上下直线
            CIRCLE = 3, -- 圆周
        },
        GAME_MOUSE_STATE = {    -- 定春状态
            NONE = 0,
            ALIVE = 1, -- 跑动
            GRABBING = 2, -- 被抓
            BOOM = 3, -- 被炸
        },
        GAME_MUSSEL_STATUS = {  -- 河蚌状态
            NONE = 0,
            OPEN = 1, -- 生效中
            CLOSE = 2, -- 点击冷却
        },
        -- Buff
        BUFF_TYPE = {
            INIT_ITEM = 1, -- Skill-开局初始化xx类型xx个道具
            INIT_SCORES = 2, -- Skill-开具自带拥有xx积分
            SKIP_DISCOUNT = 3, -- Shop-飞船打x折
            STONE_SCORE = 4, -- All-抓取物获得的分数变为原本的 X 倍
            SHORTEN_SPEED = 5, -- All-钩爪拉回速度变为原本的 X 倍
            BOOM = 6, -- Item-炸毁正在拉回的抓取物
            SHOP_DROP = 7, -- Shop-额外刷新x个道具
            SHOP_DISCOUNT = 8, -- Shop-打x折
            STONE_CHANGE_GOLD = 9, -- Item-正在拉回的物品变为同样重量的金块
            MOUSE_STOP = 10, -- Item-鼬鼠暂停移动X秒
            NOT_ACTIVE_BOOM = 11, -- Item-下X次抓取不会触发爆破装置
            HUMAN_SPEED = 12, -- Level-飞船移动速度变为原本的 X 倍
            STRETCH_SPEED = 13, -- Level-钩爪发射速度变为原本的 X 倍
            CORD_MODE = 14, -- Level-钩爪模式变更
            AIM = 15, -- Level-钩爪增加额外瞄准红线
            RAND_ITEM = 16, -- Skill-回合开始随机增加道具
            USE_ITEM_ADD_BUFF = 17, -- Skill-使用道具时获得buff
            ITEM_STOP_TIME = 18, -- Item-时停
            INIT_ADD_TIME = 19, -- Skill-开局增加游戏时间
            ADD_TIME = 20, -- Skill-使用道具增加游戏时间
            WEIGHT_FLOAT = 21, -- Item-变化重量
            TYPE_BOOM = 22, -- Item-炸某种类型的抓取物
            SCORE_FLOAT = 23, -- Skill-每次夹物品价值变化
            ROLE_HOOK = 24, -- Skill-默认钩爪,优先级比14低
            BOOM_GET_SCORE = 25, -- Skill-抓到或使用炸弹加分数(min ~ max)
            MOUSE_GET_ITEM = 26, -- Skill-抓到定春加道具(redEnvelopeRandPool GroupId)
            QTE_GET_SCORE = 27, -- Skill-QTE结束被抓取额外获得(min ~ max)%的分数
            DEFAULT_UPGRADE = 28, -- Skill-默认升级项(后端buff)
            ADD_PARTNER = 29, -- Skill-携带Partner
            HOOK_EX_IGNORE = 30, -- Skill-额外无视一些抓取物类型
            HOOK_GRAB_DESTROY = 31, -- Skill-接触指定抓取物类型直接销毁并加分
            HOOK_KARENINA = 32, -- Skill-钩爪速度随着出钩次数提升（土木老姐）
            STAGE_ADD_ITEM = 33, -- Skill-每关进入时有道具栏则获得道具
            ELECTROMAGNETIC = 34, -- Item-电磁炮：炸掉一个方向指定类型的抓取物并生成钻石
            SHIP_SPEED_MOVE = 35, -- BUFF-飞船移动速度变为原本的 X 倍,且可以一边移动一边出钩
            STAGE_ADD_SCORE_FLOAT = 36, -- BUFF-关卡内一切加分方式所加的分数按照百分比浮动
            HOOK_EX_FORCE = 37, -- Skill-强制抓取一些类型
            HOOK_EX_GRAB_VIRTUAL = 38, -- Skill-能够抓取日月机制下的虚拟抓取物
            REFLECT_EDGE = 39, -- Skill- 使钩爪能够变得弹射的BUFF
            SLOT_MACHINE_ANY_STONE = 40, -- Skill-指定某些抓取物为老虎机的任意抓取物（赖子）
            HUMAN_REVERSE_MOVE = 41, -- Skill-飞船和钩子翻转移动（勾中后飞船移动，钩子不动)
            HUMAN_REVERSE_MOVE_GRAB_STONES = 42, -- Skill-飞船可以碰撞拾取的抓取物类型（参数1是虚实类型）
            HUMAN_CHANGE_SHELL = 43, -- Skill- 飞船改变外形图
            HOOK_CHANGE_IDLE_SPEED = 44, -- Skill- 钩爪改变摇晃速度
        },
        BUFF_TIME_TYPE = {      -- Buff生命周期
            NONE = 0,
            GLOBAL = 1, -- 全局有效
            COUNT = 2, -- 按次数生效
            TIME = 3, -- 按时间生效
        },
        BUFF_TIP_TYPE = {       -- Buff倒计时显示
            NONE = 0,
            ONCE = 1, -- 只展示3秒
            UNTIL_DIE = 2, -- 直到BUff消失
        },
        BUFF_DISPLAY_TYPE = {   -- Buff展示类型(暂停和预览Ui显示)
            NONE = 0,
            SHIP = 1, -- 飞船(角色+升级)
            ITEM = 2, -- 货舱(道具)
            BUFF = 3, -- 临时插件(buff)
        },
        GAME_BUFF_STATUS = {    -- 关卡内Buff生效状态
            CREATE = 0,
            ALIVE = 1, -- 生效中
            BE_DIE = 2, -- 待失效
            DIE = 3, -- 已失效
        },
        -- Upgrade
        UPGRADE_TYPE = {        -- 飞船升级类型
            LEVEL = 0, -- 升级
            SAME_BUY = 1, -- 同位购买
            SAME_REPLACE = 2, -- 同位替换
        },
        -- QTE
        QTE_GROUP_TYPE = {      -- QTE奖励类型
            SCORE = 1,
            BUFF = 2,
            ITEM = 3,
            SCORE_AND_BUFF = 4,
            SCORE_AND_ITEM = 5,
            BUFF_AND_ITEM = 6,
            ALL = 7,
        },
        GAME_QTE_STATUS = {     -- 关卡内QTE状态
            NONE = 0,
            ALIVE = 1, -- 生效中
            WAIT = 2, -- 点击冷却
            BE_DIE = 3, -- 待失效
            DIE = 4, -- 已失效
        },
        -- Partner
        PARTNER_TYPE = {
            PARTNER_SHIP = 1, -- 帮忙抓的飞船
            SCAN_LINE = 2, -- 扫描线
            PARTNER_RADAR = 3, -- 发现抓取物的雷达
        },
        GAME_PARTNER_STATUS = {
            NONE = 0,
            ALIVE = 1,
            BE_DIE = 2,
            DIE = 3,
        },
        GAME_PARTNER_SHIP_STATUS = {
            NONE = 0,
            IDLE = 1,
            AIM = 2,
            MOVE = 3,
            GRAB = 4,
            BACK = 5,
        },
        GAME_SCAN_LINE_STATUS = {
            NONE = 0,
            ALIVE = 1,
            DIE = 3,
        },
        GAME_PARTNER_RADAR_STATUS = {
            NONE = 0,
            IDLE = 1,
            SCAN = 3,
        },
        -- Game Face
        GAME_FACE_PLAY_TYPE = {
            NONE = 0,
            SHOOTING = 1, -- 发射中表情
            REVOKING = 2, -- 收回表情
            GRAB_STONE = 3, -- 抓到抓取物
            GRAB_NONE = 4, -- 什么都没抓到
            GRABBED = 5, -- 成功收回表情
            USE_ITEM = 6, -- 使用道具表情(只显示一种)
            USE_BY_WEIGHT = 7, -- 使用道具表情(根据重量变化)
            USE_BY_SCORE = 8, -- 使用道具表情(根据价值变化)
            QTE_START = 9, -- QTE开始
            QTE_Click = 10, -- QTE点击
            QTE_END = 11, -- QTE结束
            PLAY_BY_SCORE = 12, -- 通过分数弹表情
        },
        GAME_FACE_PLAY_STATUS = {
            NONE = 0,
            SHOOTING = 1, -- 发射中表情
            REVOKING = 2, -- 收回表情
        },
        GAME_FACE_PLAY_ID = {
            SHOOTING = 2, --发射中表情
            GRAB_NONE = 3, --抓不中表情
            REVOKING = 5, --抓取拉回表情1
            GRABBED = 8, --成功拉回表情1
            QTE_START = 9, -- QTE开始
            QTE_END = 11, -- QTE结束
        },
        -- Game Anim
        GAME_ANIM = {
            NONE = "None",
            HOOK_OPEN = "HookOpen",
            HOOK_CLOSE = "HookClose",
        },
        -- Game Control
        GAME_PAUSE_TYPE = {
            NONE = 0,
            PLAYER = 1 << 0, -- 玩家手动暂停
            ITEM = 1 << 1, -- 使用道具暂停
            AUTO = 1 << 2, -- 自动暂停(进入游戏/关闭暂停弹窗)
        },
        -- Game Effect
        GAME_EFFECT_TYPE = {
            STONE_BOOM = 1, -- 炸弹爆炸
            TIME_STOP = 2, -- 时停
            TIME_RESUME = 3, -- 时停恢复
            GRAB_BOOM = 4, -- 抓取爆炸
            TYPE_BOOM = 5, -- 类型爆炸
            TO_GOLD = 6, -- 点石成金
            GRAB = 7, -- 被抓取
            WEIGHT_FLOAT = 8, -- 重量浮动
            WEIGHT_RESUME = 9, -- 重量浮动
            QTE_CLICK = 10, -- QTE点击
            QTE_COMPLETE = 11, -- QTE完成
            SHIP_GRAB = 12, -- 船体碰撞抓取
            CHANGE_TO_SUN = 13, -- 切换到白昼
            CHANGE_TO_MOON = 14, -- 切换到夜晚
            RADAR_RANDOM_ITEM = 15 -- 雷达随机生成物品
        },
        -- HideTaskType
        HIDE_TASK_TYPE = {
            GRAB_STONE = 1, -- 抓取到x个指定stoneId对象
            GRAB_STONE_BY_ONCE = 2, -- 在一次出勾中抓取到x个指定stoneId对象
            GRAB_STONE_IN_BUFF = 3, -- 在某个buff影响下抓取x个指定stoneId对象
            GRAB_STONE_BY_REFLECTION = 4, -- 通过x个转向板反射抓取到地图上的一个指定stoneId对象
            GRAB_DRAW_MAP = 5, -- 通过抓取在地图画图
        },
        -- Rank
        RANK_MAX_SPECIAL_NUM = 3,
        RANK_MAX_COUNT = 100,
        -- Pc Key 关联Client\KeySet\DefaultKeyMap.tab
        GAME_PC_KEY = {
            Shoot = 1,
            Left = 2,
            Right = 3,
            Item1 = 4,
            Item2 = 5,
            Item3 = 6,
            ExitGame = 141,
            ChangeSunAndMoon = 8,
        },
        -- Record
        CLIENT_RECORD_UI = {
            UI_STAGE = 1,
            UI_SHOP = 2,
        },
        CLIENT_RECORD_ACTION = {
            SAVE_STAGE = 1,
            STAGE_PREVIEW = 2,
            SHIP_DETAIL = 3,
        },
        -- SlotScore
        SLOT_SCORE_ANY_TYPE = 999,
        SLOT_SCORE_TYPE = {
            Diff = 1,
            Double = 2,
            Triple = 3,
        },
        REFLECT_EDGE_FLAG = {
            NONE = 0,
            TOP = 1,
            BOTTOM = 2,
            LEFT = 3,
            RIGHT = 4,
        }
    },
    KotodamaActivity = {
        PatternEffectTarget = {
            SELF = 1,
            ENEMY = 2
        },
        LocalNewState = { --存储在本地的新旧状态枚举
            Old = 0,
            New = 1
        },
        ArtifactType = {
            DeleteSentence = 1,
        }
    },
    -- 客服接口枚举
    FeedBackType = {
        From = {
            Unknown = 0, -- 未知来源
            Login = 1, -- 登录主页
            Setting = 2, -- 设置页面
            Pay = 3 -- 充值页面
        },
        isLogin = {
            UnLogin = 0, -- 不强制登录
            Login = 1, -- 强制登录
        }
    },
    --特训关manager和config的枚举移植备份
    SpecialTrain = {
        StageType = {
            None = -1,
            Normal = 0,
            Broadsword = 1,
            Alive = 2,
            Music = 3,
            Photo = 4,
            Snow = 5,
            Rhythm = 6, --元宵
            --Breakthrough = 7, --超卡列特训关 1.0
            Breakthrough = 8, --超卡列特训关 2.0
        },

        Type = {
            Normal = 1,
            Photo = 2,
            Music = 3,
            Snow = 4,
            Rhythm = 5, --元宵
            --Breakthrough = 6, --超卡列特训关 1.0
            Breakthrough = 7, --超卡列特训关 2.0
        },

        SpecialTrainMusicTaskId = {
            DailyId = 83,
            ChallengeId = 84
        },

        --活动类型
        RewardType = {
            Task = 1,
            StarReward = 2
        },
    },
    UiCharacterAttributeDetail = {
        BtnTab = {
            Career = 1,
            Element = 2,
            GeneralSkill = 3,
        }
    },
    SharePlatform = {
        KJQ = 1, -- 库街区
        QQ = 2, -- QQ
        QQSpace = 3, -- QQ空间
        WX = 4, -- 微信
        WXMoments = 5, -- 微信朋友圈
        Bilibili = 6, -- B站
        Weibo = 7, -- 微博
    },
    -- 主线2
    MAINLINE2 = {
        -- 章节故事类型
        STORY_TYPE = {
            MAINLINE = 1, -- 主线
            SHORT_STORY = 2, -- 浮点纪实
        },
        -- 关卡分组类型
        GROUP_TYPE = {
            INDEPENDENT_ENTRANCE = 1, -- 每个stage都有独立入口
            COMBINE_ENTRANCE = 2, -- 所有stage合并一个入口
        },
        -- 章节难度模式
        DIFFICULTY_TYPE = {
            NORMAL = 1, -- 普通模式
            HARD = 2, -- 隐藏模式
            VARIATIONS = 3, -- 重映模式
        },
        -- 关卡细分类型
        STAGE_DETAIL_TYPE = {
            MOVIE = 1, -- 剧情
            CG = 2, -- CG
            FIGHT_NORMAL = 3, -- 普通战斗
            FIGHT_SPECIAL = 4, -- 特殊战斗
            FIGHT_BOSS = 5, -- BOSS战
        },
        -- 关卡成就类型
        ACHIEVEMENT_TYPE = {
            NORMAL = 1, -- 普通成就 
            SPECIAL = 2, -- 特殊成就
            HIDE = 3, -- 隐藏成就
        },
        SHORT_STORY_GROUP_ID = 0, -- 浮点纪实入口GroupId为0
        -- 主章节入口页签颜色
        MAIN_TAG_COLOR = {
            NEW = "0290FF", -- 新章节
            LIMIT_TIME = "6738F8", -- 限时开放
            SPECIAL = "F83847", -- 特殊页签，配置表配置开放
        }
    },
    BossSingle = {
        LevelType = {
            ChooseAble = 0, --未选择（高级区达成晋级终极区条件）
            Normal = 1, --低级区
            Medium = 2, --中极区
            High = 3, --高级区
            Extreme = 4, --终极区
            Challenge = 9, --凹分区
        },
        DifficultyType = {
            Experiment = 1,
            Elites = 2,
            Knight = 3,
            Chaos = 4,
            Hell = 5,
            Hide = 6,
        },
        Platform = {
            Win = 0,
            Android = 1,
            IOS = 2,
            All = 3,
        },
        StageType = {
            Normal = 1, -- 常规挑战
            Trial = 2, -- 离群点
            Challenge = 3, -- 凹分区
        },
        RankType = {
            Normal = 1, -- 普通排行榜
            Challenge = 2, -- 凹分区排行榜
        }
    },
    WaterMarkStatus = {
        AllOff = 0,
        AllOn = 1,
        OnlyWaterMarkOn = 2,
        OnlySuperWaterMarkOn = 3,
    },
    FSM = {
        AutoState = {
            Init = 1,
            Play = 2,
            Pause = 3,
            Stop = 4,
        }
    },
    -- 2.12战双工艺
    LinkCraftActivity = {
        Items = {
            [1] = 96198
        },
        GoodsSpecialType = {
            Skill = 1,
            Link = 2,
        }
    },
    REFORM = {
        DIFFICULTY = {
            NORMAL = 1,
            HARD = 2,
        }
    },
    -- BOSS跃升
    BOSSINSHOT = {
        SCORE_TYPE = {
            Add = 1, -- 积分累加
            MULTIPLY = 2, -- 积分相乘
        },
        WEAR_TALENT_MAX_CNT = 2, -- 穿戴天赋最大数量
        TALENT_TYPE = {
            DEFAULT_WEAR = 1, -- 默认穿戴
            HAND_WEAR = 2, -- 手动穿戴
        },
        BOSS_PLAYBACK_CNT = 2, -- 一个BOSS可以缓存的战斗录像数量
    },
    -- v2.14 战斗音游解密小游戏
    FIGHT_LEVEL_MUSIC = {
        GAME_STATE = {
            NONE = 0,
            GAMING = 1, -- 游戏中 - Update
            CLEAR = 2, -- 游戏胜利 - Update Stop
            TIMEOUT = 3, -- 游戏失败:超时 - Update Stop
            MISS = 4, -- 踩点Miss - Update
            TRACK_CHANGE = 5, -- 轨道切换 - Update Stop
        },
        AREA_MOVE_TYPE = {
            REBOUND = 1, -- 始终沿单方向移动，到达轨道终点，弹回起始点
            STRAIGHT = 2, -- 始终沿单方向移动，到达轨道终点，从最初的起点出发
            TRIGGER = 3, -- 沿最初方向移动，每次敲击按钮会沿反方向运动，若无敲击，到边界则反弹
        },
        AREA_MOVE_DIRECTION = {
            LEFT = 1,
            RIGHT = 2,
        },
        TRIGGER_RESULT = {
            NONE = 0,
            MISS = 1,
            CLEAR = 2,
        },
        NOTE_TYPE = {
            A = 1,
            B = 2,
        },
        NOTE_STATE = {
            NONE = 0,
            UNCLEAR = 1,
            CLEAR = 2,
        }
    },
    --- 战区
    Arena = {
        ActivityStatus = {
            --Game服和竞技服等待数据的时候用
            Loading = -1,
            --默认状态
            Default = 0,
            --休息状态
            Rest = 1,
            --战斗状态
            Fight = 2,
            --结束
            Over = 3,
        },
        RegionType = {
            Up = 1, --晋级区
            Keep = 2, --保级区
            Down = 3, --降级区
        },
    },

    -- 2.14 机制玩法
    MechanismActivity = {
        StageType = {
            Default = 0,
            Normal = 1,
            Hard = 2,
        }
    },
    -- 肉鸽4
    Theatre4 = {
        IsDebug = false, -- 是否开启调试模式
        MapGridSizeX = 280, -- 地图格子X轴大小
        MapGridSizeY = 240, -- 地图格子Y轴大小
        MapExploredCost = 1, -- 探索消耗
        RatioDenominator = 10000, -- 概率分母
        -- 格子内容类型
        GridType = {
            Nothing = 1, -- 无
            Empty = 2, -- 空
            Hurdle = 3, -- 障碍
            Shop = 4, -- 商店
            Box = 5, -- 宝箱
            Monster = 6, -- 怪物
            Boss = 7, -- Boss
            Event = 8, -- 事件
            Start = 9, -- 起点
            Blank = 10, -- 白
            Building = 11, -- 建筑
        },
        -- 格子探索状态
        GridExploreState = {
            Unknown = 0, -- 未知
            Visible = 1, -- 可见(不可探索)
            Discover = 2, -- 发现(可探索)
            Explored = 3, -- 探索
            Processed = 4, -- 已处理
        },
        TransactionType = {
            Recruit = 1, -- 招募
            Item = 2, -- 藏品选择
            Reward = 3, -- 奖励选择
            FightReward = 4, -- 战斗奖励
        },
        -- 颜色枚举
        ColorType = {
            Red = 1, -- 红
            Yellow = 2, -- 黄
            Blue = 3, -- 蓝
        },
        -- 天赋树
        TreeTalent = {
            War = 1,
            Economics = 2,
            Technology = 3,
            Awake = 4,
        },
        -- 资产实体类型
        AssetType = {
            ItemBox = 1, -- 藏品箱
            Item = 2, -- 藏品
            Recruit = 3, -- 招募券
            Gold = 4, -- 金币
            Hp = 5, -- 血量
            Prosperity = 6, -- 繁荣度
            ColorLevel = 7, -- 颜色等级
            ColorResource = 8, -- 颜色资源
            ColoPoint = 9, -- 颜色天赋点
            BuildPoint = 10, -- 建造点
            ActionPoint = 11, -- 行动点
            ColorDailyResource = 12, -- 日结算颜色资源
            ItemLimit = 13, -- 藏品上限
            SettleBpExp = 14, -- 结算额外给予的Bp经验
            AwakeningPoint = 15, -- 觉醒点
            ColorCostPoint = 16, -- 可扣除的颜色资源（不影响其上限） 红色买死值
            TimeBack = 17, -- 时间回溯次数
        },
        -- 事件类型
        EventType = {
            Dialogue = 1, -- 对话
            Options = 2, -- 选项
            Reward = 3, -- 奖励
            Fight = 4, -- 战斗
        },
        -- 事件选项类型
        EventOptionType = {
            CostItem = 1,           -- 消耗物品
            CheckItem = 2,          -- 检查物品
            Dialogue = 3,           -- 对话
            CheckStageScore = 4,    -- 检查关卡得分
            DialogueSpecial = 5,        -- 对话(紫)
        },
        -- 领取类型
        BattlePassGetRewardType = {
            GetOnce = 1, -- 领一个
            GetAll = 2, -- 领取全部
        },
        -- 结算类型
        SettleType = {
            Failed = 1, -- 失败
            Success = 2, -- 成功
            Quit = 3, -- 退出
        },
        -- 建筑类型
        BuildingType = {
            Bonfire = 1, -- 篝火
            ArrowTower = 2, -- 箭塔
            MoneyCan = 3, -- 存钱罐
            Wonder = 4, -- 奇观
            TempBase = 5, -- (三合一建筑)临时基地
        },
        -- 任务类型
        BattlePassTaskType = {
            VersionTask = 1, -- 版本任务
            ProcessTask = 2, -- 流程任务
            ChallengeTask = 3, -- 挑战任务
        },
        -- 格子建筑类型
        GridBuiltType = {
            Building = 1, -- 建筑
            Shop = 2, -- 商店
        },
        -- 格子改造类型
        GridAlterType = {
            CreateBuilding = 1, -- 创建建筑
            AlterGridColor = 2, -- 改格子颜色
            RemoveHurdle = 3, -- 移除障碍
            CreateShop = 4, -- 改造商店
        },
        -- 颜色天赋类型
        ColorTalentType = {
            Regular = 1, -- 常规
            Building = 2, -- 建筑
        },
        -- 效果类型
        EffectType = {
            Type1 = 1, -- 每天翻3个以上的同色格时，本局内对应颜色资源+n
            Type2 = 2, -- 在商店每购买1个物品，本局内随机颜色资源+n
            Type4 = 4, -- 每翻一个空格，下次翻到非空格时获取的颜色资源+n（翻到非空格后重置加成）
            Type8 = 8, -- 结算时，所有颜色的颜色等级提升，提升值=最高星级角色的星级
            Type12 = 12, -- 结算时，已翻格子组合成的形状为 【直线】时，每个格子对应颜色资源+n
            Type13 = 13, -- 每对格子进行1次【建造/改造】时，结算时的所有颜色资源+n
            Type14 = 14, -- 结算时，藏品倍率+x，该倍率加成y天-z，最低为1（结算后移除加成）
            Type16 = 16, -- 每有藏品被销毁时，本局内结算时的藏品倍率+n
            Type17 = 17, -- 箭塔每击杀一个怪物，本局内结算时的藏品倍率+n
            Type19 = 19, -- 每天翻n个及以上不同色格子时，本局内结算时的藏品倍率+m
            Type20 = 20, -- 结算时，根据剩余行动点增加颜色等级
            Type22 = 22, -- 在商店内每购买1个物品，藏品倍率+n
            Type27 = 27, -- 每天消耗5金币，累计消耗25金币后，获得稀有奖励并销毁自身
            Type28 = 28, -- 结算时，获得持有【改造能量点】*2的金币
            Type29 = 29, -- 结算时，已翻格子组合成的形状为【 L】时，获得1个2星招募券
            Type32 = 32, -- 每翻X格获得X奖励
            Type33 = 33, -- 每翻X格获得fightEvent
            Type34 = 34, -- 每招安一个怪物，本局藏品倍率+x
            Type35 = 35, -- 每X天获得1个X奖励
            Type36 = 36, -- 结算时，已翻格子组合成的形状为 【直线】时，资产+x
            Type37 = 37, -- 结算时，已翻格子组合成的形状为 【L】时，藏品倍率永久+z,颜色资源+y
            Type38 = 38, -- 效果1：每天翻X个及以上不同色格子时，对应颜色等级+2 效果2：每天翻X个及以上不同色格子时，对应颜色资源+10
            Type101 = 101, -- 主动-创建建筑
            Type102 = 102, -- 主动技能消耗下降
            Type111 = 111, -- 每天奖励
            Type113 = 113, -- 每天奖励(建筑数量相关)
            Type115 = 115, -- 主动-改造格子颜色
            Type116 = 116, -- 同步改造格子颜色
            Type117 = 117, -- 主动-移除障碍
            Type119 = 119, -- 同步移除障碍
            Type120 = 120, -- 移除障碍可作用于怪物
            Type201 = 201, -- 主动-改造商店
            Type204 = 204, -- 开启商店刷新功能
            Type205 = 205, -- 主动-怪物诏安
            Type206 = 206, -- 降低诏安消耗
            Type207 = 207, -- 每次诏安后增加利息
            Type208 = 208, -- 增加利息上限
            Type209 = 209, -- 未满利息结算时奖励
            Type210 = 210, -- 满利息结算时增加利息上限
            Type218 = 218, -- 每天开始奖励(本局购物次数相关)
            Type301 = 301, -- 天赋刷新价格变化
            Type407 = 407, -- 扣除血量
            Type409 = 409, -- 调整当前资源(加减乘除)
            Type410 = 410, -- 结算时根据行动点获得资源
            Type411 = 411, -- 交战禁止标记
            Type412 = 412, -- 调整当前资产至指定值
            Type414 = 414, -- 关闭部分建筑,开启新类型建筑
            Type416 = 416, -- 获得觉醒值额外增加10%
            Type421 = 421, -- 只能减少怪物血量的xxx
            Type422 = 422, -- 是否具有红色买死效果
            Type423 = 423, -- 是否开启时间回溯功能
            Type424 = 424, -- 是否开启觉醒值
        },
        -- 效果409参数操作枚举
        Effect409OptType = {
            Add = 1,       -- 添加
            Sub = 2,       -- 减少
            Multiply = 3,  -- 乘
            Division = 4,  -- 除
        },
        -- 战斗类型
        FightType = {
            Normal = 1, -- 普通
            Difficult = 2, -- 困难
            Boss = 3, -- Boss
            Event = 4, -- 事件
        },
        -- 战斗定位类型
        FightLocateType = {
            Grid = 1, -- 格子
            Fate = 2, -- 命运  
        },
        -- 结局条件类型
        EndingConditionType = {
            None = 1, -- 无
            Event = 2, -- 事件
            Chapter = 3, -- 章节
            Stage = 4, -- 关卡
        },
        -- 弹框类型
        PopupType = {
            None = 0,
            RecruitMember = 1, -- 招募成员
            ItemReplace = 2, -- 藏品替换
            ItemSelect = 3, -- 藏品选择
            RewardSelect = 4, -- 奖励选择
            FightReward = 5, -- 战斗奖励
            AssetReward = 6, -- 资产奖励
            TalentSelect = 7, -- 天赋选择 
            NpcDialogue = 8, -- NPC对话
            TalentLevelUp = 9, -- 天赋等级提升
            ArriveNewArea = 10, -- 到达新地区
            BloodEffect = 11, -- 血特效
        },
        UnlockType = {
            Genius = 1,
            Prop = 2,
        },
        ItemQuality = {
            White = 0,
            Green = 1,
            Blue = 2,
            Purple = 3,
            Yellow = 4,
            Gold = 5,
            Red = 6,
        },
        TalentType = {
            Small = 1,
            Big = 2,
        },
        -- 格子探索步骤
        GridExploreStep = {
            None = 0, -- 无
            Explore = 1, -- 探索
            Event = 2, -- 事件
            Battle = 3, -- 战斗
            Shop = 4, -- 商店
            End = 5, -- 结束
        },
        -- 藏品奖励操作类型
        ItemRewardOperateType = {
            Awards = 1, -- 获取
            Recycling = 2, -- 回收
        },
        -- 查看地图类型
        ViewMapType = {
            None = 0, -- 无
            ReplaceItem = 1, -- 替换藏品
            SelectItem = 2, -- 选择藏品
            SelectReward = 3, -- 选择奖励
            SelectTalent = 4, -- 选择天赋
        },
        -- 星级类型
        StarType = {
            BossCountDown = 1,  -- 按boss倒计时
            Condition = 2,      -- 按condition
        },
        OpeningEffectRed = 7, -- 红色买死效果
        BtnOptionStyle = {
            Normal = 1,
            Red = 2,    -- 红色买死效果
            Purple = 3, -- 紫色效果  
        },
        SweepType = {
            NormalFight = 0,
            Red = 1,
            Yellow = 2,
        },
    },
    -- 数据演习
    SIMULATE_TRAIN = {
        TASK_TYPE = {
            NORMAL = 1,
            HARD = 2,
        },
    },
    -- 2.16高难继承玩法
    SucceedBoss = {
        ChapterType = {
            Normal = 1, -- 普通
            Optional = 2, -- 自选凹分
        },
        BossType = {
            Boss = 1, -- Boss
            Normal = 2, -- 精英
        },
        BossHeadUseType = {
            Main = 1, -- 主界面
            Chapter = 2, -- 章节界面
            Settle = 3, -- 结算界面
        }
    },
    -- 指挥官DIY系统
    PlayerFashion = {
        PartType = {
            Fashion = 1,
            Hair = 2,
            Eyes = 3,
            Hand = 4,
        },
        Gender = {
            Male = 1, -- 男性
            Female = 2, -- 女性
        }
    },
    -- 2.17 数织小游戏
    Nonogram = {
        NonogramChapterStatus = {
            Lock = 1, -- 未解锁
            Init = 2, -- 初始状态（不消耗解锁道具）
            Ongoing = 3, -- 进行中
            Reward = 4, -- 通关（可重新挑战，并且不消耗解锁道具）
        },
        NonogramStageStatus = {
            None = 0,
            Ongoing = 1, -- 进行中
            Finish = 2, -- 通关
        },
        NonogramStageGameStatus = {
            None = 0,
            Init = 1, -- 初始状态
            Ready = 2, -- 准备状态（此时倒计时开始）
            Playing = 3, -- 游戏中
            NextStage = 4, -- 切下一关状态
            Pause = 5, -- 暂停状态
            Finish = 6, -- 结束状态
        },
        NonogramGridBlockStatus = {
            None = 0,
            UnKnown = 1, -- 未知
            TrueStatus = 2, -- 正确
            FalseStatus = 3, -- 错误
        }
    },
    -- 涂装
    Fashion = {
        EffectType = {
            UiEffect = 1, -- 角色特效
            WeaponEffect = 2, -- 武器特效
        }
    },
    -- 背包系统
    BWBackpack = {
        ItemType = {
            Normal = 0,
            All = 1,
            Quest = 2,
        }
    },
    -- 首席打枪
    FpsGame = {
        Teach = 0,
        Story = 1,
        Challenge = 2,
        Reward = {
            None = 1, -- 不可领取
            Rewarded = 2, -- 已领取
            CanReward = 3, -- 未领取，可领取
        },
    },
    -- 短信系统
    BWMessage = {
        ContentType = {
            ReceiveDialog = 1,
            SendDialog = 2,
            OptionsDialog = 3,
            System = 4,
            ReceiveMemes = 5,
            SendMemes = 6,
            None = 1001
        },
        MessageState = {
            NotFinish = 0,
            Finish = 1,
            NotRead = 2,
        },
        CompleteType = {
            None = 0,
            ActiveTask = 1,
            PushTask = 2,
        },
        MessageType = {
            ForcePlay = 1,
            Tips = 2,
            Normal = 3,
        },
    },
    -- 轮椅手册
    WheelchairManual = {
        TabType = {
            StepReward = 1, --阶段奖励
            BPReward = 2, --BP奖励
            StepTask = 3, --阶段任务
            Lotto = 4, --卡池
            Gift = 5, --礼包
            Teaching = 6, --教学
            Guide = 7, --活动引导
        },
        TabTypeModule = {
            [1] = "XUi/XUiWheelchairManual/UiPanelWheelchairManualStepReward/XUiPanelWheelchairManualStepReward",
            [2] = "XUi/XUiWheelchairManual/UiPanelWheelChairManualPassport/XUiPanelWheelChairManualPassport",
            [3] = "XUi/XUiWheelchairManual/UiPanelWheelchairManualTask/XUiPanelWheelchairManualTask",
            [4] = "XUi/XUiWheelchairManual/UiPanelWheelchairManualLotto/XUiPanelWheelchairManualLotto",
            [5] = "XUi/XUiWheelchairManual/UiPanelWheelchairManualGiftPack/XUiPanelWheelchairManualGiftPack",
            [6] = "XUi/XUiWheelchairManual/UiPanelWheelChairManualTeaching/XUiPanelWheelChairManualTeaching",
            [7] = "XUi/XUiWheelchairManual/UiPanelWheelchairManualGuide/XUiPanelWheelchairManualGuide",
        },
        --  蓝点KEY
        ReddotKey = {
            -- xxNew: 首次开放且未点击
            -- 目前和切页类型值一一对应，若有更改，相应的取消红点的逻辑也要调整
            StepRewardNew = 1, --阶段奖励
            BPRewardNew = 2, --BP奖励
            StepTaskNew = 3, --阶段任务
            LottoNew = 4, --卡池
            GiftNew = 5, --礼包
            TeachingNew = 6, --教学
            GuideNew = 7, --活动引导
            
            EntranceChangedNew = 100, -- 活动入口转移的未点击提示蓝点
        },
        WeekMainId = {
            FubenPrequel = 1001, -- 角色碎片
            ArenaChallenge = 1002, -- 战区
            BossSingle = 1003, -- 囚笼
            StrongHold = 1004, -- 矿区
            Transfinite = 1005, -- 超限连战
            GuildBoss = 1006, -- 工会Boss
        },
    },
    -- Pc Key 关联Client\KeySet\DefaultKeyMap.tab InputMapId==5
    GAME_PC_KEY = {
        Space = 1,
        Left = 2,
        Right = 3,
        Alpha1 = 4,
        Alpha2 = 5,
        Alpha3 = 6,
        Esc = 141,
        Tab = 8,
        Up = 9,
        Down = 10,
        Alpha4 = 14,
    },
    Lotto = {
        Lifu = 1,
        Luna = 2,
        Karenina = 3,
        Vera = 4,
    },
    Maverick3 = {
        Currency = {
            Shop = 97039, --商店代币
            Cultivate = 97038, --养成代币
        },
        Difficulty = {
            Normal = 1,
            Hard = 2,
        },
        ChapterType = {
            MainLine = 1, --主线
            Infinite = 2, --无尽
            Teach = 3,    --教学
        },
        Plugin = {
            Talent = 1, -- 天赋
            Slay = 2, -- 必杀
            Ornaments = 3, -- 挂饰
        },
        TeachChapterId = 0, -- 教学关
    },
    GachaCanLiver = {
        DrawButtonType = {
            One = 1, -- 单抽
            Ten = 2, -- 十连
        },
        ReddotKey = {
            ShopNoEnter = 'ShopNoEnter',
            ShopNoEnterAfterTLClsoed = 'ShopNoEnterAfterTLClsoed',
            TaskNoEnter = 'TaskNoEnter',
            TimelimitDrawNoEnter = 'TimelimitDrawNoEnter',
            TimelimitDrawNoEnterAfterUnLock = 'TimelimitDrawNoEnterAfterUnLock',
            ResistenceDrawNoEnterAfterTLClsoed = 'ResistenceDrawNoEnterAfterTLClsoed'
        }
    },
    RhythmGameTaiko = {
        NoteType = {
            RedNormal = 1,
            BlueNormal = 2,        
            SliderHead = 3,
            SliderTail = 4,
        },

        HitPoint = {
            JudgmentTimeMs = 
            {
                Perfect = 70,
                Good = 150,
                Bad = 170,
                Miss = -1,
            },
            Score = 
            {
                Perfect = 100,
                Good = 50,
                Bad = 20,
                Miss = 0,
            },
            Rank =
            {
                S = 60,
                A = 40,
                B = 20,
                C = 0,
            }
        }
    },
    BWMap = {
        TrackType = {
            Normal = 1,
            Quest = 2,
        },
    },
    ModelDisplayDelay = {
        Character = 1, -- 角色特效延迟
        Weapon = 2, -- 武器特效延迟
    },
    -- 打牌
    PCG = {
        MAX_CHAR_CNT = 3,                       -- 最大角色数量
        MAX_MONSTER_CNT = 5,                    -- 最大怪物数量
        ATTACK_CHAR_INDEX = 1,                  -- 角色列表进攻角色下标
        ANIM_TIME_ATTR_CHANGE = 500,            -- 属性变化飘字时间(毫秒)
        ANIM_TIME_EXHIBITION = 100,             -- 展示区的停留时间(毫秒)
        ANIM_TIME_CARD_OFFSET = 200,            -- 卡牌错开播放移动时间(毫秒)
        ANIM_TIME_CARD_FLIP = 1150,             -- 卡牌翻面的时间(毫秒)
        ANIM_TIME_CARD_FLIP_CHANGE = 200,       -- 卡牌翻面动画过程中切换卡牌(毫秒)
        ANIM_TIME_CARD_BACK = 300,              -- 卡牌归位动画时间(毫秒)
        ANIM_TIME_CHARACTER_CHANGE = 500,       -- 切换角色时间(毫秒)
        ANIM_TIME_MONSTER_ENABLE = 500,         -- 怪物出场动画时间(毫秒)
        ANIM_TIME_MONSTER_DIE = 600,            -- 怪物死亡动画时间(毫秒)
        ANIM_TIME_CHARACTER_ATTACK = 600,       -- 成员攻击动画时间(毫秒)
        ANIM_TIME_CHARACTER_ATTACK_PART1 = 220, -- 成员攻击动画第1步时间(毫秒)
        ANIM_TIME_CHARACTER_ATTACK_PART2 = 120, -- 成员攻击动画第2步时间(毫秒)
        ANIM_TIME_CHARACTER_ATTACK_PART3 = 500, -- 成员攻击动画第3步时间(毫秒)
        ANIM_TIME_SLAY = 1000,                  -- 必杀技时间(毫秒)
        ANIM_TIME_SETTLE_OFFSET = 100,          -- EffectSettle效果处理的间隔(毫秒)
        ANIM_TIME_SETTLE_DELAY_FINISH = 200,    -- 所有EffectSettle效果处理完成的延迟结束(毫秒)
        ANIM_TIME_CARD_SPACING_OFFSET = 200,    -- 手牌数量变化时，调整卡牌间隔时间(毫秒)
        ANIM_TIME_INIT_ENABLE_OFFSET = 300,     -- 游戏初始化战斗单位出场间隔
        CUE_ID_CARD_MOVE = 5419,                -- 卡牌移动音效
        CUE_ID_CARD_ENABLE = 5422,              -- 卡牌出现音效
        CUE_ID_CARD_MOVE_HAND = 5456,           -- 卡牌移动到手上音效
        CUE_ID_CARD_OUT_HAND = 5429,            -- 卡牌从手上打出到展示区音效
        CUE_ID_CHARACTER_SWITCH = 5434,         -- 切换角色
        -- 游戏状态
        GAME_STATE = {
            Init = 1,               -- 初始化
            Playing = 2,            -- 游戏中
            End = 3,                -- 游戏结束
        },
        -- 回合状态
        ROUND_STATE = {
            PLAY_CARDS = 1,         -- 出牌
            ROUND_END = 2,          -- 回合结束
            MONSTER_ATTACK = 3,     -- 怪物进攻
            GET_CARDS = 4,          -- 抽卡
        },
        -- 卡牌类型
        CARD_TYPE = {
            NORMAL = 1,             -- 基础牌
            SLAY = 2,               -- 必杀牌
            DERIVATIVE = 3,         -- 衍生牌
        },
        -- 颜色类型
        COLOR_TYPE = {
            RED = 1,                -- 红
            BLUE = 2,               -- 蓝
            YELLOW = 3,             -- 黄
            WHITE = 4,              -- 白色
        },
        -- 怪物类型
        MONSTER_TYPE = {
            BOSS = 1,               -- Boss
            NORMAL = 2,             -- 普通怪
        },
        -- 关卡类型
        STAGE_TYPE = {
            TEACHING = 1,           -- 教学关
            NORMAL = 2,             -- 普通关
            ENDLESS = 3,            -- 无尽关
        },
        -- 弹窗详情类型
        POPUP_DETAIL_TYPE = {
            COMMANDER = 1,          -- 指挥官
            MONSTER = 2,            -- 怪物
            CHARACTER = 3,          -- 成员
            CARD = 4,               -- 卡牌
        },
        -- 效果类型
        EFFECT_TYPE = { 
            ATTACK_COMMANDER_DAMAGE = 2,      -- 对指挥官攻击的伤害
            ADD_MONSTER_ARMOR = 28,           -- 对怪物增加护甲
        },
        -- 效果结算类型
        EFFECT_SETTLE_TYPE = {
            NONE = 0,
            DAMAGE = 1, -- 造成伤害  Param1:伤害值 Param2:来源类型 Param3:来源Id Param4:来源位置 Param5:目标类型 Param6:目标Id Param7:目标位置
            HP_CHANGE = 2, -- 目标血量变化  Param1:变化后血量值 Param2:目标类型 Param3:目标Id Param4:目标位置
            ARMOR_CHANGE = 3, -- 目标护甲变化  Param1:变化后护甲值 Param2:目标类型 Param3:目标Id Param4:目标位置
            ACTION_POINT_CHANGE = 4, -- 行动点变化 Param1:变化后行动点
            CHARACTER_POS_CHANGE = 5, -- 角色切换到中间 Param1:角色Id
            CARD_POOL_CHANGE = 6,  -- 牌堆变化 Param1:变化卡牌Id Param2:来源 Param3:去向
            TOKEN_CHANGE = 7, -- 标记变化 Param1:目标类型 Param2:目标Id Param3:标记Id Param4:层数 Param5:目标位置
            MONSTER_CHANGE = 8, -- 新怪物刷新 Param1:位置1的怪物Id Param2:位置2的怪物Id Param3:位置3的怪物Id Param4:位置4的怪物Id Param5:位置5的怪物Id
            HAND_POOL_SORT = 9, -- 手牌排序 CardList:排序后手牌
            ADJUST_CARD_POOL_ORDER = 10, -- 调整卡牌在卡池中的顺序 Param1:卡池类型 Param2:卡牌id Param3:原位置 Param4:现位置
            DROP_HAND_CARDS = 11, -- 弃置手牌 CardList:弃置卡牌 CardIdxList:弃置卡牌下标
            REMOVE_CARDS = 12, -- 移除卡牌 CardList:移除卡牌 CardIdxList:移除卡牌下标
            ADD_HAND_CARDS = 13, -- 直接生成卡牌 Param1:卡池类型 CardList:生成手牌 CardIdxList:生成手牌下标
            WAVE_MONSTER_DEAD = 14, -- 怪物波次死亡
        },
        -- 效果结算目标类型
        TARGET_TYPE = {
            COMMANDER = 1, -- 指挥官
            MONSTER = 2, -- 怪物
            CHARACTER = 3, -- 成员
        },
        -- 牌位置类型
        CARD_POS_TYPE = {
            DRAW = 0, -- 抽牌堆
            DROP = 1, -- 弃牌堆
            HAND = 2, -- 手牌
            DERIVATIVE = 4, -- 衍生区
        },
        -- 标记效果类型
        TOKEN_EFFECT_TYPE = {
            BUFF = 1, -- 增益buff
            DEBUFF = 2, -- 减益buff
        },
    },
    BWSetting = {
        SetType = {
            Voice = 1,
            Graphics = 2,
            Other = 3,
        },
        CursorSize = {
            Small = 0,
            Medium = 1,
            Large = 2,
        },
        VolumeControl = {
            ON = 1,
            OFF = 2,
        },
        FashionVoice = {
            Close = 0,
            Open = 1,
        },
        --- 对应C# : enum XQualityLevelSix
        GraphicsQuality = {
            Custom = 0, 
            Lowest = 1, 
            Low = 2, 
            Middle = 3, 
            High = 4, 
            Highest = 5,
        },
        --- 对应C# : enum XQualityLevelFive
        GraphicsFrameRate = {
            Lowest = 0, 
            Low = 1, 
            Middle = 2, 
            High = 3, 
            Highest = 4,
        },
    },
    --- 合版本活动
    VersionGift = {
        RewardType = {
            DailyReward = 1, -- 每日奖励
            VersionReward = 2, -- 版本赠礼
            ProgressReward = 3, -- 历程奖励
        }
    },
    InstrumentSimulator = {
        KeyboradKeyCount = 22,
        InstrumentFurnitureId = {
            Piano = 6001,
        }
    },
    ScoreTower = {
        MaxChapterCount = 5,        -- 最大章节数
        MaxBelongChapterCount = 4,  -- 最大强化所属章节数
        MaxStrengthenSlotCount = 3, -- 最大强化槽位数量
        StageType = {
            Normal = 1,   -- 普通关
            Boss = 2,     -- Boss关
        },
        -- 词缀关获取点数途径
        PointType = {
            Tag = 1,        -- 角色tag( 或逻辑）
            Fa = 2,         -- 平均战力
            Liberate = 3,   -- 判断角色是否完成【终解】【超解】
            Equip = 4,      -- 判断角色是否装备【武器谐振】
            TagCompose = 5, -- 角色tag（和逻辑，参数【A|B】，A表示有几个，B表示tag）
        },
        -- boss关插件类型
        PlugType = {
            AddFightTime = 1, -- 增加战斗时间
            SetScore = 2,     -- 设置分数目标
            RemoveBuff = 3,   -- 移除特定词缀
            AddBuff = 4,      -- 增加词缀
            AddRobot = 5,     -- 增加机器人
        },
    },
    AprilFool = {
        Random2025Type = {
            Cat = 1,
            Wolf = 2,
        }
    }
}
