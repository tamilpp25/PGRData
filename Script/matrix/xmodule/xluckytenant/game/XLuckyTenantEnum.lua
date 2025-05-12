local XLuckyTenantEnum = {
    Item = {
        Piece = 1,
        RefreshProp = 98,
        DeleteProp = 99,
    },
    PropId = {
        RefreshProp = 99998,
        DeleteProp = 99999,
    },
    Skill = {
        Type1 = 1, --【1】回合后变成一个随机【2颜色】or【3颜色】【4类型】棋子
        Type2 = 2, --与【1类型】相邻自己会被消除，消除后立即获得【score】分数，同时该棋子基础价值 +【2基础价值】
        Type3 = 3, --与【1类型】相邻自己会被消除，消除自己的棋子基础价值 +【2基础价值】, 自己被消除后转化变成【3棋子id】
        Type4 = 4, --【1】回合后转化成【2】【3】【4】里的随机一个怪物
        Type5 = 5, --与【1类型】相邻自己会被消除，自己被消除后增加【2】个【3】
        Type6 = 6, --与【1类型】相邻自己会被消除，消除自己的棋子基础价值获得自己的基础价值, 消除后立即获得【score】分数
        Type7 = 7, --消除附近所有【1】，触发消除额外获得【score】分
        Type8 = 8, --每【1】回合，自身价值+【2】
        Type9 = 9, --每过【1】回合，产出【2】个【3】棋子
        Type10 = 10, --【1】回合后变成【2】
        Type11 = 11, --和【1】同时存在在棋盘上，消除自身，可让【1】直接完成转化，若场上有两个【1】，按照排序依次消耗【1】
        Type12 = 12, --与【1】棋子相邻会被消除，被消除后增加【2】个【3类】棋子和【4】个【5类】
        Type13 = 13, --蒲牢棋子进入背包后，初始价值=初始价值+（【1】-【2】之间的随机值）
        Type14 = 14, --消除相邻的【1棋子id】，每消除1个【1棋子id】，自身价值+【2】
        Type15 = 15, -- 消除棋盘上所有【1】，每吸收1个【1】可额外获得【score】分
        Type16 = 16, --消除棋盘上所有蓝色绿色怪物，自身价值=基础价值加上吸收怪物价值总和（优先级最高）(没支持配置，个人觉得这个不需要)
        Type17 = 17, --若存在多个自己，自身价值高的自己吸收价值低的自己
        Type18 = 18, --棋盘每发生消除（包括怪物消除怪物），永久提升自身1价值
        Type19 = 19, --与【2分数】的【1类型】棋子同时出现在棋盘上时会被消除
        Type20 = 20, --与自身相邻的【1】 临时+【score】分
        Type21 = 21, --每【1】回合随机【2（填1到100）】产出【3】棋子
        Type22 = 22, --每隔【1】回合，随机召唤【2】个【3类】棋子，不包括自身，但可重复
        Type23 = 23, --与【1类型】相邻自己会被消除， 自己被消除后转化变成【3棋子id】(类型3的mini版)
        Type24 = 24, --与【1】相邻时，额外获得【2】分
        Type25 = 25, --每【1】回合结算分数时可额外获得【2】-【3】分
        Type26 = 26, --【1】回合后消失
        Type27 = 27, --场上有【1】时，所有【1】价值+【2】
        Type28 = 28, --与【1】相邻时，每回合结算分数时可额外获得【2】-【3】分
        Type29 = 29, --消除身边的【1】
        Type30 = 30, --结算分数=棋盘上价值最高的棋子
        Type31 = 31, -- 与【1】相邻时，自身临时分数+【2】
        Type32 = 32, --与【1】相邻后生成1个【2】
        Type33 = 33, --曲所在的某一行上所有棋子基础价值+【1】
        Type34 = 34, --每回合消除棋盘上【1】个【2】并得他们的价值，触发清除后自身价值+【3】
        Type35 = 35, --与我相邻的棋子可额外获得【1】分
        Type36 = 36, --每次结算分数，自身价值会变成场上所有【1】价值之和
        Type37 = 37, --赛利卡在棋盘上时，场上所有【1】自身价值+【2】
        Type38 = 38, --累计消除【1】个螺母后，福袋变成1个【2颜色】【3类型】
        Type39 = 39, --棋盘上的【1】、【2】价值+【3】,技能在背包里生效
        Type40 = 40, --棋盘上的【1】、【2】价值+【3】,技能在背包里生效
        Type41 = 41, --棋盘上的【1】、【2】价值+【3】,技能在背包里生效
        Type42 = 42, --棋盘上存在2个三头犬成员时会被消除，永久提升三头犬成员价值【1】
        Type43 = 43, --与【1类型】相邻，增加【2】个【3】
        Type44 = 44, --当背包里同时出现薇拉，21号，诺克提时，3人的自身基础价值+3
        Type45 = 45, --
        Type46 = 46, --
        Type47 = 47, --
        Type48 = 48, --
        Type49 = 49, --
        Type50 = 50, --
        Type51 = 51, --
        Type52 = 52, --
        Type53 = 53, --
        Type54 = 54, --
        Type55 = 55, --
        Type56 = 56, --
        Type57 = 57, --
        Type58 = 58, --
        Type59 = 59, --
        Type60 = 60, --
        Type61 = 61, --
        Type62 = 62, --
        Type63 = 63, --
        Type64 = 64, --
        Type65 = 65, --
        Type66 = 66, --
        Type67 = 67, --
        Type68 = 68, --
        Type69 = 69, --
        Type70 = 70, --
    },
    Operation = {
        None = 0,
        Score = 1, --得分
        DeletePiece = 2, --删除
        AddNewPieceToBag = 3, --增加新棋子到背包, 如果棋盘有位置, 就放到棋盘上, 从左上角开始
        TransformPiece = 4, --变形成为新的棋子
        AddPieceValue = 5, -- 增加棋子分数
        SetPieceByPosition = 6, -- 从背包里设置棋子到棋盘上
        AddPassiveSkill = 7, --增加一个被动技能
        SetValueUponDeletion = 8, -- 设置消除得分
        Update = 9, -- 更新棋子信息
    },
    Quality = {
        None = 0,
        Green = 1,
        Blue = 2,
        Purple = 3,
        Orange = 4,
        Red = 5,
    },
    PieceType = {
        Monster = 3,
        SpecialMonster = 4,
        FightingRole = 5,
    },
    Tag = {
        Cerberus = 1, -- 三头犬
    },
    GameState = {
        ShowQuestGoalsOnFirstRound = 1, --第一回合弹出任务目标
        Roll = 2, -- 掷骰子（计算分数, 得分）
        Animation = 3,
        CheckQuestCompletionStatus = 4, --检查任务完成情况
        ShowNextQuestGoals = 5, --弹出任务目标
        SelectPiece = 6, --选择棋子
        GameOver = 7, -- 失败
        NormalClear = 8, -- 普通通关
        PerfectClear = 9, -- 通关
        Guide = 10, -- 指引中等待, 新增一个事件, 参数是继续和暂停
    },
    Condition = {
        Round = 1, -- 达到多少回合
        TagAmount = 2, -- tag数量达到多少
        Identical = 3, -- 相同id棋子达到多少
    },
    OverDetailUi = {
        Restart = 1,
        Over = 2,
    },
    Task = {
        418
    },
    Animation = {
        Shake = 1, --抖动
        SetPiece = 2, -- 刷新棋子
        AddScore = 3, -- 增加棋子分数
        GetScore = 4, -- 获得分数
        DeletePiece = 5, -- 删除棋子
        AddPiece = 6, -- 添加棋子
        PlayRollAnimation = 7,
        Wait = 8,
        UpdateChessboard = 9,
        End = 10,
    },
    Cost = 1,
    QualityIcon = {
        Circle = 1,
        Quad = 2,
    }
}

return XLuckyTenantEnum