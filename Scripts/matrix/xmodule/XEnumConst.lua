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
        MAX_STAR_COUNT = 6,                     -- 最大星星数
        MAX_ATTR_COUNT = 2,                     -- 最大属性数量
        WEAPON_RESONANCE_COUNT = 3,             -- 武器的共鸣数量
        AWARENESS_RESONANCE_COUNT = 2,          -- 意识的共鸣数量
        OVERRUN_ADD_SUIT_CNT = 2,               -- 超限增加意识数量
        WEAR_AWARENESS_COUNT = 6,               -- 可穿戴意识的数量
        MAX_SUIT_SKILL_COUNT = 4,               -- 最大的意识套装技能数量
        SUIT_MAX_SKILL_COUNT = 3,               -- 同一意识套装里最大技能数量
        AWAKE_CRYSTAL_MONEY = 2,                -- 超频激活的晶币
        CAN_NOT_AUTO_EAT_STAR = 5,              -- 大于等于该星级的装备不会被当做默认狗粮选中
        FIVE_STAR = 5,                          -- 5星
        STRENGTHEN_EXP_OVERFLOW_CONFIRM = 300,  -- 强化经验溢出超过这个值需要二次确认
        -- XUiEquipDetailV2P6界面的页签按钮下标
        UI_EQUIP_DETAIL_BTN_INDEX = {          
            STRENGTHEN = 1,                     -- 强化
            RESONANCE = 2,                      -- 共鸣
            OVERCLOCKING = 3,                   -- 超频
            OVERRUN = 4,                        -- 超限
        },
        -- 武器模型用途
        WEAPON_USAGE = {
            ROLE = 1,                           -- ui角色身上
            BATTLE = 2,                         -- 战斗
            SHOW = 3,                           -- ui单独展示
        },
        -- 装备位置
        EQUIP_SITE = {
            WEAPON = 0,                         -- 武器
            AWARENESS = {                       -- 意识
                ONE = 1,                        -- 1号位
                TWO = 2,                        -- 2号位
                THREE = 3,                      -- 3号位
                FOUR = 4,                       -- 4号位
                FIVE = 5,                       -- 5号位
                SIX = 6,                        -- 6号位
            },
        },
        -- 狗粮类型
        EAT_TYPE = {
            EQUIP = 0,                          -- 装备
            ITEM = 1,                           -- 道具
        },
        -- 排序优先级选项
        PRIOR_SORT_TYPE = {
            STAR = 0,                           -- 星级
            BREAKTHROUGH = 1,                   -- 突破次数
            LEVEL = 2,                          -- 等级
            PROCEED = 3,                        -- 入手顺序
        },
        -- 装备适配角色类型
        USER_TYPE = {
            ALL = 0,                            -- 通用
            NORMAL = 1,                         -- 泛用机体
            ISOMER = 2,                         -- 独域机体
        },
        -- 武器类型
        EQUIP_TYPE = {
            UNIVERSAL = 0,                      -- 通用
            SUNCHA = 1,                         -- 双枪
            SICKLE = 2,                         -- 太刀
            MOUNT = 3,                          -- 挂载
            ARROW = 4,                          -- 弓箭
            CHAINSAW = 5,                       -- 电锯
            SWORD = 6,                          -- 大剑
            HCAN = 7,                           -- 巨炮
            DOUBLE_SWORDS = 8,                  -- 双短刀
            SICKLE = 9,                         -- 镰刀
            ISOMER_SWORD = 10,                  -- 感染者专用大剑
            FOOD = 99,                          -- 狗粮
        },
        -- 共鸣类型
        RESONANCE_TYPE = {
            ATTRIB = 1,                         -- 属性共鸣
            CHARACTER_SKILL = 2,                -- 角色技能共鸣
            WEAPON_SKILL = 3,                   -- 武器技能共鸣
        },
        IS_TEST_V2P6 = true,                   -- 是否测试2.6版本, true为打开2.6的界面, false为打开旧的界面
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
            UnionKill = 23, --列阵
            ArenaOnline = 24, --合众战局
            ExtraChapter = 25, --番外关卡
            SpecialTrain = 26, --特训关
            InfestorExplore = 27, --感染体玩法
            GuildBoss = 28, --工会boss
            Expedition = 29, --虚像地平线
            WorldBoss = 30, --世界Boss
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
            Hack = 41, --骇入玩法
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
            Course = 70,    -- v1.30-考级-ManagerStage
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
        }
    },
    CHARACTER = {
        IS_NEW_CHARACTER = true,
        MAX_QUALITY_STAR = 10,
        MAX_QUALITY = 6,
        QualityState = 
        {
            Activing = 1,
            EvoEnable = 2,
            ActiveFinish = 3,
            Lock = 4,
        },
        PerformState = 
        {
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
    THEATRE3 = {
        --步骤类型
        StepType = {
            RecruitCharacter = 1,   --设置编队
            Node = 2,               --节点
            FightReward = 3,        --战斗奖励
            ItemReward = 4,         --具体道具奖励
            WorkShop = 5,           --炼金工坊
            EquipReward = 6,        --打开装备选择界面
            EquipInherit = 7,       --打开装备继承界面
        },
        --节点类型
        NodeSlotType = {
            Fight = 1,              --战斗
            Event = 2,              --事件
            Shop = 3,               --商店
        },
        --节点奖励类型
        NodeRewardType = {
            ItemBox = 1,            --道具箱
            Gold = 2,               --金币
            EquipBox = 3,           --装备箱
        },
        --商店售卖项类型
        NodeShopItemType = {
            Item = 1,               --道具
            EquipBox = 2,           --装备箱
            ItemBox = 3,            --道具箱
        },
        NodeShopItemLockType = {
            Unlock = 0,             --已解锁
            Lock = 1,               --上锁
            NoItem = 2,             --没有物品
        },
        EventStepType = {
            Dialogue = 1,           --对话
            Options = 2,            --选项
            ChapterItem = 3,        --物品
            Fight = 4,              --战斗
            WorkShop = 5,           --炼金工坊
        },
        EventStepOptionType = {
            CostItem = 1,           --消耗物品
            CheckItem = 2,          --检查物品
            Dialogue = 3,           --对话
        },
        EventStepItemType = {
            OutSideItem = 1,        --局外物品
            InnerItem = 2,          --局内物品
            ItemBox = 3,            --道具箱
            EquipBox = 4,           --装备箱
        },
        --工坊节点类型
        WorkShopType = {
            Recast = 1,             --重铸
            Change = 2,             --交换
        },

        StrengthenPointType = {
            Small = 1,          --小节点
            Middle = 2,         --中节点
            Big = 3,            --大节点
        },
        RewardDisplayType = {
            Normal = 0, --普通
            Rare   = 1, --稀有
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
            Left = 1,   -- 居左
            Right = 2,  -- 居右
        },
    },
    Turntable = {
        RewardType = {
            Main = 1, -- 核心
            Height = 2, -- 高级
            Simple = 3, -- 普通
        },
    }
}