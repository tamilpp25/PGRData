local tableInsert = table.insert
local tableSort = table.sort
local ipairs = ipairs
local pairs = pairs
local stringGsub = string.gsub
local CSXTextManagerGetText = CS.XTextManager.GetText

local TABLE_CHAPTER_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameChapter.tab"
local TABLE_STAGE_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameStage.tab"
local TABLE_STAR_CONDITION_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameStarCondition.tab"
local TABLE_ROLE_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameRole.tab"
local TABLE_MAP_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameMap.tab"    --
local TABLE_START_POINT_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameStartPoint.tab"
local TABLE_END_POINT_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameEndPoint.tab"
local TABLE_BLOCK_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameBlock.tab"
local TABLE_GAP_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameGap.tab"
local TABLE_MONSTER_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameMonster.tab"
local TABLE_TRIGGER_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameTrigger.tab"
local TABLE_ACTIVITY_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameActivity.tab"
local TABLE_SHADOW_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameShadow.tab"
local TABLE_TRAP_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameTrap.tab"
local TABLE_ELECTRIC_FENCE_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameElectricFence.tab"
local TABLE_CHAPTER_GROUP_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameChapterGroup.tab"
local TABLE_ENTITY_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameEntity.tab"
local TABLE_TRANSFER_POINT_PATH = "Share/MiniActivity/RpgMakerGame/RpgMakerGameTransferPoint.tab"
local TABLE_HINT_ICON_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGameHintIcon.tab"
local TABLE_RANDOM_DIALOG_BOX_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGameRandomDialogBox.tab"
local TABLE_HINT_DIALOG_BOX_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGameHintDialogBox.tab"
local TABLE_MODEL_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGameModel.tab"
local TABLE_ANIMATION_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGameAnimation.tab"
local TABLE_PLAY_MAIN_DOWN_HINT_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGamePlayMainDownHint.tab"
local TABLE_HINT_LINE_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGameHintLine.tab"
local TABLE_DEATH_TITAL_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGameDeathTitle.tab"
local TABLE_SKILL_TYPE_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGameSkillType.tab"
local RpgMakerGameChapterConfigs = {}
local RpgMakerGameStageConfigs = {}
local RpgMakerGameSKillTypeConfigs = {}
local RpgMakerGameStarConditionConfigs = {}
local RpgMakerGameRoleConfigs = {}
local RpgMakerGameMapConfigs = {}
local RpgMakerGameStartPointConfigs = {}
local RpgMakerGameEndPointConfigs = {}
local RpgMakerGameBlockConfigs = {}
local RpgMakerGameGapConfigs = {}
local RpgMakerGameMonsterConfigs = {}
local RpgMakerGameTriggerConfigs = {}
local RpgMakerGameHintIconConfigs = {}
local RpgMakerGameActivityConfigs = {}
local RpgMakerGameRandomDialogBoxConfigs = {}
local RpgMakerGameHintDialogBoxConfigs = {}
local RpgMakerGameModelConfigs = {}
local RpgMakerGameAnimationConfigs = {}
local RpgMakerGamePlayMainDownHintConfigs = {}
local RpgMakerGameHintLineConfigs = {}
local RpgMakerGameShadowConfigs = {}
local RpgMakerGameTrapConfigs = {}
local RpgMakerGameElectricFenceConfigs = {}
local RpgMakerGameDeathTitleConfigs = {}
local RpgMakerGameChapterGroupConfigs = {}
local RpgMakerGameEntityConfigs = {}
local RpgMakerGameTransferPointConfigs = {}

local RpgMakerGameChapterIdList = {}
local RpgMakerGameChapterIdToStageIdListDic = {}
local RpgMakerGameStageIdToStarConditionIdListDic = {}
local RpgMakerGameRoleIdList = {}
local RpgMakerGameStageIdList = {}
local RpgMakerGameSkillTypeList = {}
local RpgMakerGameMapIdToBlockIdList = {}
local RpgMakerGameMapIdToGapIdList = {}
local RpgMakerGameMapIdToMonsterIdList = {}
local RpgMakerGameMapIdToTriggerIdList = {}
local RpgMakerGameMapIdToHintIdList = {}
local RpgMakerGameRandomDialogBoxIdList = {}
local RpgMakerGameMapIdToShadowIdList = {}
local RpgMakerGameMapIdToTrapIdList = {}
local RpgMakerGameMapIdToElectricFenceIdList = {}
local MapIdToTransferPointIdList = {} --key：mapId，value：transferPointIdList
local MapIdToEntityIdList = {}  --key：mapId，value：entityIdList
local EntityTypeDic = {}    --key1：MapId，key2：X，key3：Y，value：TypeList
local EntityIdDic = {}  --key1：MapId，key2：X，key3：Y，value：entityIdList
local RpgMakerGameChapterGroupToChapterIdList = {} --key：chapterGroupId，value：chapterIdList
local RpgMakerGameChapterGroupIdList = {}

local DefaultActivityId = 1

XRpgMakerGameConfigs = XRpgMakerGameConfigs or {}

--关卡状态
XRpgMakerGameConfigs.RpgMakerGameStageStatus = {
    Lock = 1,   --未开启
    UnLock = 2, --已开启
    Clear = 3,  --已通关
}

--方向
XRpgMakerGameConfigs.RpgMakerGameMoveDirection = {
    MoveLeft = 1,
    MoveRight = 2,
    MoveUp = 3,
    MoveDown = 4,
}

--行动类型
XRpgMakerGameConfigs.RpgMakerGameActionType = {
    ActionNone = 0,
    ActionPlayerMove = 1,   --玩家移动
    ActionKillMonster = 2,  --杀死怪物
    ActionStageWin = 3,     --关卡胜利
    ActionEndPointOpen = 4, --终点开启
    ActionMonsterRunAway = 5,   --怪物逃跑
    ActionMonsterChangeDirection = 6,   --怪物调整方向
    ActionMonsterKillPlayer = 7,    --怪物杀死玩家
    ActionTriggerStatusChange = 8,  --机关状态改变
    ActionMonsterPatrol = 9,    --怪物巡逻
    ActionUnlockRole = 10,  --解锁角色
    ActionMonsterPatrolLine = 11,   --怪物巡逻路线
    ActionShadowMove = 12,  --影子移动
    ActionShadowDieByTrap = 13, --影子掉落陷阱
    ActionPlayerDieByTrap = 14, --玩家掉落陷阱
    ActionMonsterDieByTrap = 15,    --怪物掉落陷阱
    ActionElectricStatusChange = 16,    --电墙状态改变
    ActionPlayerKillByElectricFence = 17,   --玩家被电墙杀死
    ActionMonsterKillByElectricFence = 18,  --怪物被电墙杀死
    ActionHumanKill = 19,   --人类被杀，关卡失败
    ActionSentrySign = 20,  --产生哨戒的标记
    ActionPlayerTransfer = 21,  --玩家传送
    ActionBurnGrass = 22,   --燃烧草圃
    ActionGrowGrass = 23,   --草圃生长
    ActionPlayerDrown = 24, --玩家淹死
    ActionMonsterDrown = 25,    --怪物淹死
    ActionSteelBrokenToTrap = 26,   --钢板破损变成陷阱
    ActionSteelBrokenToFlat = 27,   --钢板破损消失
    ActionMonsterTransfer = 28,     --怪物传送
}

--缝隙类型
XRpgMakerGameConfigs.RpgMakerGapDirection = {
    GridLeft = 1,   --格子左边线
    GridRight = 2,  --格子右边线
    GridTop = 3,    --格子顶部线
    GridBottom = 4, --格子底部线
}

--终点类型
XRpgMakerGameConfigs.XRpgMakerGameEndPointType = {
    DefaultClose = 0,  --默认关闭
    DefaultOpen = 1,    --默认开启
}

--阻挡状态
XRpgMakerGameConfigs.XRpgMakerGameBlockStatus = {
    UnBlock = 0,    --不阻挡
    Block = 1,      --阻挡
}

--怪物类型
XRpgMakerGameConfigs.XRpgMakerGameMonsterType = {
    Normal = 1,     --小怪
    BOSS = 2,
    Human = 3,      --人类
}

--怪物攻击范围方向
XRpgMakerGameConfigs.XRpgMakerGameMonsterViewAreaType = {
    ViewFront = 1,  --怪物的前方
    ViewBack = 2,   --怪物的后面
    ViewLeft = 3,   --怪物的左边
    ViewRight = 4,  --怪物的右边
}

--机关类型
XRpgMakerGameConfigs.XRpgMakerGameTriggerType = {
    Trigger1 = 1,   --本身是不能阻挡，停在上面可以触发类型2的机关状态转变
    Trigger2 = 2,   --由类型1触发
    Trigger3 = 3,   --经过后，会从通过状态转变为阻挡状态
    TriggerElectricFence = 4,   --电围栏触发机关
}

--电墙机关（开关）状态
XRpgMakerGameConfigs.XRpgMakerGameElectricStatus = {
    CloseElectricFence = 0,     --关闭电网
    OpenElectricFence = 1,      --开启电网
}

--电网状态
XRpgMakerGameConfigs.XRpgMakerGameElectricFenceStatus = {
    Close = 0,      --关闭
    Open = 1,       --开启
}

--答案类型
XRpgMakerGameConfigs.XRpgMakerGameRoleAnswerType = {
    Hint = 1,       --提示
    Answer = 2,     --答案
}

--角色技能
XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType = {
    Crystal = 1,    --冰霜
    Flame = 2,      --烈焰
    Raiden = 3,     --雷电
    Dark = 4        --暗元素
}

--实体类型
XRpgMakerGameConfigs.XRpgMakerGameEntityType = {
    Water = 1,      --水
    Ice = 2,        --冰
    Grass = 3,      --草圃
    Steel = 4       --钢板
}

--水类型
XRpgMakerGameConfigs.XRpgMakerGameWaterType = {
    Water = 1,      --水
    Ice = 2,        --冰
    Melt = 3,       --冰融化
}

XRpgMakerGameConfigs.XRpgMakerTransferPointColor = {
    Green = 1,      --
    Yellow = 2,      --
    Purple = 3,      --
}

--钢板破损后的类型
XRpgMakerGameConfigs.XRpgMakerGameSteelBrokenType = {
    Init = 0,       --默认状态
    Flat = 1,       --变成平地
    Trap = 2,       --变成陷阱
}

--小地图提示图标配置表的key
XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps = {
    BlockIcon = "BlockIcon",
    NormalMonsterIcon = "NormalMonsterIcon",
    BossIcon = "BossIcon",
    TriggerIcon1 = "TriggerIcon1",
    TriggerIcon2 = "TriggerIcon2",
    TriggerIcon3 = "TriggerIcon3",
    ElectricFencTrigger = "ElectricFencTrigger",
    GapIcon = "GapIcon",
    ShadowIcon = "ShadowIcon",
    ElectricFenceIcon = "ElectricFenceIcon",
    HumanIcon = "HumanIcon",
    StartPointIcon = "StartPointIcon",
    EndPointIcon = "EndPointIcon",
    TrapIcon = "TrapIcon",
    MoveLineIcon = "MoveLineIcon",
    CrystalMonsterIcon = "CrystalMonsterIcon",
    FlameMonsterIcon = "FlameMonsterIcon",
    RaidenMonsterIcon = "RaidenMonsterIcon",
    DarkMonsterIcon = "DarkMonsterIcon",
    CrystalBossIcon = "CrystalBossIcon",
    FlameBossIcon = "FlameBossIcon",
    RaidenBossIcon = "RaidenBossIcon",
    DarkBossIcon = "DarkBossIcon",
    EntityIcon1 = "EntityIcon1",
    EntityIcon2 = "EntityIcon2",
    EntityIcon3 = "EntityIcon3",
    EntityIcon4 = "EntityIcon4",
    TransferPointIcon1 = "TransferPointIcon1",
    TransferPointIcon2 = "TransferPointIcon2",
    TransferPointIcon3 = "TransferPointIcon3",
}

--模型/特效的key（RpgMakerGameModel.tab）
XRpgMakerGameConfigs.ModelKeyMaps = {
    GoldClose = "GoldClose",
    Gap = "Gap",
    TriggerType3 = "TriggerType3",
    ViewArea = "ViewArea",
    TriggerType1 = "TriggerType1",
    GoldOpen = "GoldOpen",
    MoveLine = "MoveLine",
    TriggerType2 = "TriggerType2",
    RoleMoveArrow = "RoleMoveArrow",
    MonsterTriggerEffect = "MonsterTriggerEffect",
    ElectricFence = "ElectricFence",
    Trap = "Trap",
    SentryLine = "SentryLine",
    Sentry = "Sentry",
    SentryRoand = "SentryRoand",
    TriggerElectricFenceOpen = "TriggerElectricFenceOpen",
    TriggerElectricFenceClose = "TriggerElectricFenceClose",
    ElectricFenceEffect = "ElectricFenceEffect",
    KillByElectricFenceEffect = "KillByElectricFenceEffect",
    BeAtkEffect = "BeAtkEffect",
    ShadowEffect = "ShadowEffect",
    Grass = "Grass",
    Pool = "Pool",
    TransferPointLoopColor1 = "TransferPointLoopColor1",
    TransferPointLoopColor2 = "TransferPointLoopColor2",
    TransferPointLoopColor3 = "TransferPointLoopColor3",
    TransferPointColor1 = "TransferPointColor1",
    TransferPointColor2 = "TransferPointColor2",
    TransferPointColor3 = "TransferPointColor3",
    Steel = "Steel",
    SteelBroken = "SteelBroken",
    Freeze = "Freeze",
    Melt = "Melt",
    Drown = "Drown",
    Burn = "Burn",
    WaterRipper = "WaterRipper",
    DarkSkillEffect = "DarkSkillEffect",
    CrystalSkillEffect = "CrystalSkillEffect",
    FlameSkillEffect = "FlameSkillEffect",
    RaidenSkillEffect = "RaidenSkillEffect",
}


--一个关卡最多星星数
XRpgMakerGameConfigs.MaxStarCount = 3

--延迟被攻击回调的时间
XRpgMakerGameConfigs.BeAtkEffectDelayCallbackTime = CS.XGame.ClientConfig:GetInt("RpgMakerGamePlayBeAtkEffectDelayCallbackTime")

--草埔生长、燃烧等动画播放间隔（毫秒）
XRpgMakerGameConfigs.PlayAnimaInterval = 50


local InitRpgMakerGameChapterIdToStageIdListDic = function()
    local chapterId
    for _, v in pairs(RpgMakerGameStageConfigs) do
        chapterId = v.ChapterId
        if not RpgMakerGameChapterIdToStageIdListDic[chapterId] then
            RpgMakerGameChapterIdToStageIdListDic[chapterId] = {}
        end
        tableInsert(RpgMakerGameChapterIdToStageIdListDic[chapterId], v.Id)
    end

    for chapterId, stageIdList in pairs(RpgMakerGameChapterIdToStageIdListDic) do
        tableSort(stageIdList, function(a, b)
            return a < b
        end)
    end
end

local InitRpgMakerGameStageIdToStarConditionIdListDic = function()
    local stageId
    for _, v in pairs(RpgMakerGameStarConditionConfigs) do
        stageId = v.StageId
        if not RpgMakerGameStageIdToStarConditionIdListDic[stageId] then
            RpgMakerGameStageIdToStarConditionIdListDic[stageId] = {}
        end

        tableInsert(RpgMakerGameStageIdToStarConditionIdListDic[stageId], v.Id)
    end
end

local InitRpgMakerGameRoleIdList = function()
    local tempTable = {}
    for _, v in pairs(RpgMakerGameRoleConfigs) do
        tableInsert(tempTable, v)
    end
    tableSort(tempTable, function(a, b)
        if a.RoleOrder ~= b.RoleOrder then
            return a.RoleOrder < b.RoleOrder
        end
        return a.Id < b.Id
    end)

    for _, v in ipairs(tempTable) do
        tableInsert(RpgMakerGameRoleIdList, v.Id)
    end
end

local InitRpgMakerGameStageIdList = function()
    for _, v in pairs(RpgMakerGameStageConfigs) do
        tableInsert(RpgMakerGameStageIdList, v.Id)
    end
    tableSort(RpgMakerGameStageIdList, function(a, b)
        return a < b
    end)
end

local InitRpgMakerGameSkillTypeList = function()
    for _, v in pairs(RpgMakerGameSKillTypeConfigs) do
        tableInsert(RpgMakerGameSkillTypeList, v.Id)
    end
    tableSort(RpgMakerGameSkillTypeList, function(a, b)
        return a < b
    end)
end

local InitRpgMakerGameMapIdToBlockIdList = function()
    local mapId
    for _, v in pairs(RpgMakerGameBlockConfigs) do
        mapId = v.MapId
        if not RpgMakerGameMapIdToBlockIdList[mapId] then
            RpgMakerGameMapIdToBlockIdList[mapId] = {}
        end
        tableInsert(RpgMakerGameMapIdToBlockIdList[mapId], v.Id)
    end
end

local InitRpgMakerGameMapIdToGapIdList = function()
    local mapId
    for _, v in pairs(RpgMakerGameGapConfigs) do
        mapId = v.MapId
        if not RpgMakerGameMapIdToGapIdList[mapId] then
            RpgMakerGameMapIdToGapIdList[mapId] = {}
        end
        tableInsert(RpgMakerGameMapIdToGapIdList[mapId], v.Id)
    end
end

local InitRpgMakerGameMapIdToMonsterIdList = function()
    local mapId
    for _, v in pairs(RpgMakerGameMonsterConfigs) do
        mapId = v.MapId
        if not RpgMakerGameMapIdToMonsterIdList[mapId] then
            RpgMakerGameMapIdToMonsterIdList[mapId] = {}
        end
        tableInsert(RpgMakerGameMapIdToMonsterIdList[mapId], v.Id)
    end
end

local InitRpgMakerGameMapIdToTriggerIdList = function()
    local mapId
    for _, v in pairs(RpgMakerGameTriggerConfigs) do
        mapId = v.MapId
        if not RpgMakerGameMapIdToTriggerIdList[mapId] then
            RpgMakerGameMapIdToTriggerIdList[mapId] = {}
        end
        tableInsert(RpgMakerGameMapIdToTriggerIdList[mapId], v.Id)
    end
end

local InitActivityConfig = function()
    for activityId, config in pairs(RpgMakerGameActivityConfigs) do
        if XTool.IsNumberValid(config.ActivityTimeId) then
            DefaultActivityId = activityId
            break
        end
        DefaultActivityId = activityId
    end
end

local InitRpgMakerGameRandomDialogBoxIdList = function()
    for _, v in pairs(RpgMakerGameRandomDialogBoxConfigs) do
        tableInsert(RpgMakerGameRandomDialogBoxIdList, v.Id)
    end
    tableSort(RpgMakerGameRandomDialogBoxIdList, function(a, b)
        return a < b
    end)
end

local InitRpgMakerGameMapIdToShadowIdList = function()
    local mapId
    for _, v in pairs(RpgMakerGameShadowConfigs) do
        mapId = v.MapId
        if not RpgMakerGameMapIdToShadowIdList[mapId] then
            RpgMakerGameMapIdToShadowIdList[mapId] = {}
        end
        tableInsert(RpgMakerGameMapIdToShadowIdList[mapId], v.Id)
    end
end

local InitRpgMakerGameMapIdToShadowIdList = function()
    local mapId
    for _, v in pairs(RpgMakerGameShadowConfigs) do
        mapId = v.MapId
        if not RpgMakerGameMapIdToShadowIdList[mapId] then
            RpgMakerGameMapIdToShadowIdList[mapId] = {}
        end
        tableInsert(RpgMakerGameMapIdToShadowIdList[mapId], v.Id)
    end
end

local InitRpgMakerGameMapIdToTrapIdList = function()
    local mapId
    for _, v in pairs(RpgMakerGameTrapConfigs) do
        mapId = v.MapId
        if not RpgMakerGameMapIdToTrapIdList[mapId] then
            RpgMakerGameMapIdToTrapIdList[mapId] = {}
        end
        tableInsert(RpgMakerGameMapIdToTrapIdList[mapId], v.Id)
    end
end

local InitRpgMakerGameMapIdToElectricFenceIdList = function()
    local mapId
    for _, v in pairs(RpgMakerGameElectricFenceConfigs) do
        mapId = v.MapId
        if not RpgMakerGameMapIdToElectricFenceIdList[mapId] then
            RpgMakerGameMapIdToElectricFenceIdList[mapId] = {}
        end
        tableInsert(RpgMakerGameMapIdToElectricFenceIdList[mapId], v.Id)
    end
end

local IsInitTransferPoint = false
local InitMapIdToTransferPointIdList = function()
    if IsInitTransferPoint then
        return
    end
    local mapId
    for _, v in pairs(RpgMakerGameTransferPointConfigs) do
        mapId = v.MapId
        if not MapIdToTransferPointIdList[mapId] then
            MapIdToTransferPointIdList[mapId] = {}
        end
        tableInsert(MapIdToTransferPointIdList[mapId], v.Id)
    end
    IsInitTransferPoint = true
end

local IsInitEntity = false
local InitMapIdToEntityIdList = function()
    if IsInitEntity then
        return
    end
    local mapId
    for _, v in pairs(RpgMakerGameEntityConfigs) do
        mapId = v.MapId
        if not MapIdToEntityIdList[mapId] then
            MapIdToEntityIdList[mapId] = {}
        end
        tableInsert(MapIdToEntityIdList[mapId], v.Id)

        --初始化实例所在的坐标、对应的实例类型列表
        if not EntityTypeDic[mapId] then
            EntityTypeDic[mapId] = {}
        end
        if not EntityTypeDic[mapId][v.X] then
            EntityTypeDic[mapId][v.X] = {}
        end
        if not EntityTypeDic[mapId][v.X][v.Y] then
            EntityTypeDic[mapId][v.X][v.Y] = {}
        end
        tableInsert(EntityTypeDic[mapId][v.X][v.Y], v.Type)

        --初始化实例所在的坐标、对应的实例Id列表
        if not EntityIdDic[mapId] then
            EntityIdDic[mapId] = {}
        end
        if not EntityIdDic[mapId][v.X] then
            EntityIdDic[mapId][v.X] = {}
        end
        if not EntityIdDic[mapId][v.X][v.Y] then
            EntityIdDic[mapId][v.X][v.Y] = {}
        end
        tableInsert(EntityIdDic[mapId][v.X][v.Y], v.Id)
    end
    IsInitEntity = true
end

local IsInitChapterGroup = false
local _DefaultChapterGroupId
local InitChapterGroup = function()
    if IsInitChapterGroup then
        return
    end

    local groupId
    for id, v in pairs(RpgMakerGameChapterConfigs) do
        groupId = v.GroupId
        if not RpgMakerGameChapterGroupToChapterIdList[groupId] then
            RpgMakerGameChapterGroupToChapterIdList[groupId] = {}
        end
        tableInsert(RpgMakerGameChapterGroupToChapterIdList[groupId], id)
    end

    for groupId, chapterIdList in pairs(RpgMakerGameChapterGroupToChapterIdList) do
        tableSort(chapterIdList, function(chapterIdA, chapterIdB)
            return chapterIdA < chapterIdB
        end)
    end
    

    for id, v in pairs(RpgMakerGameChapterGroupConfigs) do
        tableInsert(RpgMakerGameChapterGroupIdList, id)

        if v.IsFirstShow then
            _DefaultChapterGroupId = id
        end
    end
    tableSort(RpgMakerGameChapterGroupIdList, function(groupIdA, groupIdB)
        return groupIdA < groupIdB
    end)

    IsInitChapterGroup = true
end

function XRpgMakerGameConfigs.Init()
    RpgMakerGameChapterConfigs = XTableManager.ReadByIntKey(TABLE_CHAPTER_PATH, XTable.XTableRpgMakerGameChapter, "Id")
    RpgMakerGameStageConfigs = XTableManager.ReadByIntKey(TABLE_STAGE_PATH, XTable.XTableRpgMakerGameStage, "Id")
    RpgMakerGameStarConditionConfigs = XTableManager.ReadByIntKey(TABLE_STAR_CONDITION_PATH, XTable.XTableRpgMakerGameStarCondition, "Id")
    RpgMakerGameRoleConfigs = XTableManager.ReadByIntKey(TABLE_ROLE_PATH, XTable.XTableRpgMakerGameRole, "Id")
    RpgMakerGameMapConfigs = XTableManager.ReadByIntKey(TABLE_MAP_PATH, XTable.XTableRpgMakerGameMap, "Id")
    RpgMakerGameStartPointConfigs = XTableManager.ReadByIntKey(TABLE_START_POINT_PATH, XTable.XTableRpgMakerGameStartPoint, "Id")
    RpgMakerGameSKillTypeConfigs = XTableManager.ReadByIntKey(TABLE_SKILL_TYPE_PATH, XTable.XTableRpgMakerGameSkillType, "SkillType")
    RpgMakerGameEndPointConfigs = XTableManager.ReadByIntKey(TABLE_END_POINT_PATH, XTable.XTableRpgMakerGameEndPoint, "Id")
    RpgMakerGameBlockConfigs = XTableManager.ReadByIntKey(TABLE_BLOCK_PATH, XTable.XTableRpgMakerGameBlock, "Id")
    RpgMakerGameGapConfigs = XTableManager.ReadByIntKey(TABLE_GAP_PATH, XTable.XTableRpgMakerGameGap, "Id")
    RpgMakerGameMonsterConfigs = XTableManager.ReadByIntKey(TABLE_MONSTER_PATH, XTable.XTableRpgMakerGameMonster, "Id")
    RpgMakerGameTriggerConfigs = XTableManager.ReadByIntKey(TABLE_TRIGGER_PATH, XTable.XTableRpgMakerGameTrigger, "Id")
    RpgMakerGameHintIconConfigs = XTableManager.ReadByStringKey(TABLE_HINT_ICON_PATH, XTable.XTableRpgMakerGameHintIcon, "Key")
    RpgMakerGameActivityConfigs = XTableManager.ReadByIntKey(TABLE_ACTIVITY_PATH, XTable.XTableRpgMakerGameActivity, "Id")
    RpgMakerGameRandomDialogBoxConfigs = XTableManager.ReadByIntKey(TABLE_RANDOM_DIALOG_BOX_PATH, XTable.XTableRpgMakerGameRandomDialogBox, "Id")
    RpgMakerGameHintDialogBoxConfigs = XTableManager.ReadByIntKey(TABLE_HINT_DIALOG_BOX_PATH, XTable.XTableRpgMakerGameHintDialogBox, "StageId")
    RpgMakerGameModelConfigs = XTableManager.ReadByStringKey(TABLE_MODEL_PATH, XTable.XTableRpgMakerGameModel, "Key")
    RpgMakerGameAnimationConfigs = XTableManager.ReadByStringKey(TABLE_ANIMATION_PATH, XTable.XTableRpgMakerGameAnimation, "ModelName")
    RpgMakerGamePlayMainDownHintConfigs = XTableManager.ReadByIntKey(TABLE_PLAY_MAIN_DOWN_HINT_PATH, XTable.XTableRpgMakerGamePlayMainDownHint, "Id")
    RpgMakerGameHintLineConfigs = XTableManager.ReadByIntKey(TABLE_HINT_LINE_PATH, XTable.XTableRpgMakerGameHintLine, "MapId")
    RpgMakerGameShadowConfigs = XTableManager.ReadByIntKey(TABLE_SHADOW_PATH, XTable.XTableRpgMakerGameShadow, "Id")
    RpgMakerGameTrapConfigs = XTableManager.ReadByIntKey(TABLE_TRAP_PATH, XTable.XTableRpgMakerGameTrap, "Id")
    RpgMakerGameElectricFenceConfigs = XTableManager.ReadByIntKey(TABLE_ELECTRIC_FENCE_PATH, XTable.XTableRpgMakerGameElectricFence, "Id")
    RpgMakerGameDeathTitleConfigs = XTableManager.ReadByIntKey(TABLE_DEATH_TITAL_PATH, XTable.XTableRpgMakerGameDeathTitle, "Type")
    RpgMakerGameChapterGroupConfigs = XTableManager.ReadByIntKey(TABLE_CHAPTER_GROUP_PATH, XTable.XTableRpgMakerGameChapterGroup, "Id")
    RpgMakerGameEntityConfigs = XTableManager.ReadByIntKey(TABLE_ENTITY_PATH, XTable.XTableRpgMakerGameEntity, "Id")
    RpgMakerGameTransferPointConfigs = XTableManager.ReadByIntKey(TABLE_TRANSFER_POINT_PATH, XTable.XTableRpgMakerGameTransferPoint, "Id")

    InitRpgMakerGameChapterIdToStageIdListDic()
    InitRpgMakerGameStageIdToStarConditionIdListDic()
    InitRpgMakerGameRoleIdList()
    InitRpgMakerGameStageIdList()
    InitRpgMakerGameSkillTypeList()
    InitRpgMakerGameMapIdToBlockIdList()
    InitRpgMakerGameMapIdToGapIdList()
    InitRpgMakerGameMapIdToMonsterIdList()
    InitRpgMakerGameMapIdToTriggerIdList()
    InitActivityConfig()
    InitRpgMakerGameRandomDialogBoxIdList()
    InitRpgMakerGameMapIdToShadowIdList()
    InitRpgMakerGameMapIdToTrapIdList()
    InitRpgMakerGameMapIdToElectricFenceIdList()
end

-----------------RpgMakerGameChapter begin--------------------
local GetRpgMakerGameChapterConfig = function(id)
    local config = RpgMakerGameChapterConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameChapterConfig", "RpgMakerGameChapterCfg", TABLE_CHAPTER_PATH, "Id", tostring(id))
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameChapterOpenTimeId(id)
    local config = GetRpgMakerGameChapterConfig(id)
    return config.OpenTimeId
end

function XRpgMakerGameConfigs.GetRpgMakerGameChapterName(id)
    local config = GetRpgMakerGameChapterConfig(id)
    return config.Name
end

function XRpgMakerGameConfigs.GetRpgMakerGameChapterTagBtnBG(id)
    local config = GetRpgMakerGameChapterConfig(id)
    return config.TagBtnBG
end

function XRpgMakerGameConfigs.GetRpgMakerGameChapterPrefab(id)
    local config = GetRpgMakerGameChapterConfig(id)
    return config.Prefab
end

function XRpgMakerGameConfigs.GetRpgMakerGameStageIdList(chapterId)
    return RpgMakerGameChapterIdToStageIdListDic[chapterId] or {}
end
-----------------RpgMakerGameChapter end--------------------

-----------------RpgMakerGameStage begin--------------------
local GetRpgMakerGameStageConfig = function(id)
    local config = RpgMakerGameStageConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameStageConfig", "RpgMakerGameStageConfig", TABLE_STAGE_PATH, "Id", tostring(id))
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameStageChapterId(id)
    local config = GetRpgMakerGameStageConfig(id)
    return config.ChapterId
end

function XRpgMakerGameConfigs.GetRpgMakerGameStagePreStage(id)
    local config = GetRpgMakerGameStageConfig(id)
    return config.PreStage
end

function XRpgMakerGameConfigs.GetRpgMakerGameStageBG(id)
    local config = GetRpgMakerGameStageConfig(id)
    return config.BG
end

function XRpgMakerGameConfigs.GetRpgMakerGameStagePrefab(id)
    local config = GetRpgMakerGameStageConfig(id)
    return config.Prefab
end

function XRpgMakerGameConfigs.GetRpgMakerGameStarConditionIdList(stageId)
    return RpgMakerGameStageIdToStarConditionIdListDic[stageId] or {}
end

function XRpgMakerGameConfigs.GetRpgMakerGameStageName(id)
    local config = GetRpgMakerGameStageConfig(id)
    return config.Name or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameStageHint(id)
    local config = GetRpgMakerGameStageConfig(id)
    return config.StageHint or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameAllStageIdList()
    return RpgMakerGameStageIdList
end

function XRpgMakerGameConfigs.GetRpgMakerGameNextStageId(currStageId)
    local chapterId = XRpgMakerGameConfigs.GetRpgMakerGameStageChapterId(currStageId)
    local stageIdList = XRpgMakerGameConfigs.GetRpgMakerGameStageIdList(chapterId)
    local nextStageId = 0
    for i, stageId in ipairs(stageIdList or {}) do
        if stageId == currStageId then
            nextStageId = stageIdList[i + 1] or 0
            return nextStageId
        end
    end

    return nextStageId
end

function XRpgMakerGameConfigs.GetRpgMakerGameStageLoseHintList(id)
    local config = GetRpgMakerGameStageConfig(id)
    return config.LoseHint or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameNumberName(id)
    local config = GetRpgMakerGameStageConfig(id)
    return config.NumberName or ""
end

function XRpgMakerGameConfigs.GetStageHintCost(id)
    local config = GetRpgMakerGameStageConfig(id)
    return config.HintCost
end

function XRpgMakerGameConfigs.GetStageAnswerCost(id)
    local config = GetRpgMakerGameStageConfig(id)
    return config.AnswerCost
end

function XRpgMakerGameConfigs.GetStageMapId(id)
    local config = GetRpgMakerGameStageConfig(id)
    return config.MapId
end

function XRpgMakerGameConfigs.GetStageUseRoleId(id)
    local config = GetRpgMakerGameStageConfig(id)
    return config.UseRoleId
end
-----------------RpgMakerGameStage end--------------------

-----------------RpgMakerGameStarCondition 通关获得的星星条件 begin--------------------
local GetRpgMakerGameStarConditionConfig = function(id)
    local config = RpgMakerGameStarConditionConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameStarConditionConfig", "RpgMakerGameStarConditionConfig", TABLE_STAR_CONDITION_PATH, "Id", tostring(id))
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameStarConditionStar(id)
    local config = GetRpgMakerGameStarConditionConfig(id)
    return config.Star
end

function XRpgMakerGameConfigs.GetRpgMakerGameStarConditionStepCount(id)
    local config = GetRpgMakerGameStarConditionConfig(id)
    return config.StepCount
end

function XRpgMakerGameConfigs.GetRpgMakerGameStarConditionMonsterCount(id)
    local config = GetRpgMakerGameStarConditionConfig(id)
    return config.MonsterCount
end

function XRpgMakerGameConfigs.GetRpgMakerGameStarConditionMonsterBossCount(id)
    local config = GetRpgMakerGameStarConditionConfig(id)
    return config.MonsterBossCount or 0
end

function XRpgMakerGameConfigs.GetRpgMakerGameStarConditionDesc(id)
    local config = GetRpgMakerGameStarConditionConfig(id)
    return config.ConditionDesc
end

function XRpgMakerGameConfigs.GetRpgMakerGameTotalStar(chapterId)
    local stageIdList = XRpgMakerGameConfigs.GetRpgMakerGameStageIdList(chapterId)
    local starConditionIdList
    local totalStarCount = 0
    for _, stageId in ipairs(stageIdList) do
        starConditionIdList = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionIdList(stageId)
        for _, starConditionId in ipairs(starConditionIdList) do
            totalStarCount = totalStarCount + XRpgMakerGameConfigs.GetRpgMakerGameStarConditionStar(starConditionId)
        end
    end
    return totalStarCount
end

function XRpgMakerGameConfigs.GetRpgMakerGameStageTotalStar(stageId)
    local starConditionIdList = XRpgMakerGameConfigs.GetRpgMakerGameStarConditionIdList(stageId)
    local totalCount = 0
    for _, starConditionId in ipairs(starConditionIdList) do
        totalCount = totalCount + XRpgMakerGameConfigs.GetRpgMakerGameStarConditionStar(starConditionId)
    end
    return totalCount
end

function XRpgMakerGameConfigs.GetStarConditionReward(id)
    local config = GetRpgMakerGameStarConditionConfig(id)
    return config.Reward
end
-----------------RpgMakerGameStarCondition 通关获得的星星条件 end----------------------

-----------------RpgMakerGameRole 角色列表 begin--------------------
local GetRpgMakerGameRoleConfig = function(id)
    local config = RpgMakerGameRoleConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameRoleConfig", "RpgMakerGameRoleConfigs", TABLE_ROLE_PATH, "Id", tostring(id))
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameRoleIdList()
    return RpgMakerGameRoleIdList
end

function XRpgMakerGameConfigs.GetRpgMakerGameRoleUnlockChapterId(id)
    local config = GetRpgMakerGameRoleConfig(id)
    return config.UnlockChapterId
end

function XRpgMakerGameConfigs.GetRpgMakerGameRoleName(id)
    local config = GetRpgMakerGameRoleConfig(id)
    return config.Name or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameRoleStyle(id)
    local config = GetRpgMakerGameRoleConfig(id)
    return config.Style or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameRoleSkillType(id)
    local config = GetRpgMakerGameRoleConfig(id)
    return config.SkillType or nil
end

function XRpgMakerGameConfigs.GetRpgMakerGameRoleModelAssetPath(id)
    local config = GetRpgMakerGameRoleConfig(id)
    return config.ModelAssetPath
end

function XRpgMakerGameConfigs.GetRpgMakerGameRoleInfoName(id)
    local config = GetRpgMakerGameRoleConfig(id)
    return config.InfoName or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameRoleInfo(id)
    local config = GetRpgMakerGameRoleConfig(id)
    return config.Info or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameRoleHeadPath(id)
    local config = GetRpgMakerGameRoleConfig(id)
    return config.HeadPath
end

function XRpgMakerGameConfigs.GetRpgMakerGameRoleLockTipsDesc(id)
    local config = GetRpgMakerGameRoleConfig(id)
    return config.LockTipsDesc or ""
end

--根据解锁的关卡id，返回对应的角色id列表
function XRpgMakerGameConfigs.GetRpgMakerGameRoleIdListByUnlockChapterId(unlockChapterId)
    local roleIdList = XRpgMakerGameConfigs.GetRpgMakerGameRoleIdList()
    local unlockChapterIdCfg
    local roleIdList = {}
    for _, roleId in ipairs(roleIdList) do
        unlockChapterIdCfg = XRpgMakerGameConfigs.GetRpgMakerGameRoleUnlockChapterId(roleId)
        if unlockChapterIdCfg == unlockChapterId then
            tableInsert(roleIdList, roleId)
        end
    end
    return roleIdList
end

function XRpgMakerGameConfigs.GetRoleSkillType(id)
    local config = GetRpgMakerGameRoleConfig(id)
    return config.SkillType or ""
end

function XRpgMakerGameConfigs.GetRoleGraphicBefore(id)
    local config = GetRpgMakerGameRoleConfig(id)
    return config.GraphicBefore
end

function XRpgMakerGameConfigs.GetRoleGraphicAfter(id)
    local config = GetRpgMakerGameRoleConfig(id)
    return config.GraphicAfter
end
-----------------RpgMakerGameRole 角色列表 end--------------------

-----------------RpgMakerGameSkillType 技能类型列表 begin--------------------
local GetRpgMakerGameSkillTypeConfig = function(skillType)
    local config = RpgMakerGameSKillTypeConfigs[skillType]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameSkillTypeConfig", "RpgMakerGameSkillTypeConfigs", TABLE_SKILL_TYPE_PATH, "skillType", tostring(skillType))
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameSkillTypeIcon(skillType)
    local config = GetRpgMakerGameSkillTypeConfig(skillType)
    return config.Icon
end
-----------------RpgMakerGameSkillType 技能类型列表 end--------------------

-----------------RpgMakerGameMap 地图 begin-----------------------
local GetRpgMakerGameMapConfigs = function(id)
    local config = RpgMakerGameMapConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameMapConfigs", "RpgMakerGameMapConfigs", TABLE_MAP_PATH, "Id", tostring(id))
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameMaxRound(id)
    local config = GetRpgMakerGameMapConfigs(id)
    return config.MaxRound
end

function XRpgMakerGameConfigs.GetRpgMakerGameStartPointId(id)
    local config = GetRpgMakerGameMapConfigs(id)
    return config.StartPointId
end

function XRpgMakerGameConfigs.GetRpgMakerGameEndPointId(id)
    local config = GetRpgMakerGameMapConfigs(id)
    return config.EndPointId
end

function XRpgMakerGameConfigs.GetRpgMakerGamePrefab(id)
    local config = GetRpgMakerGameMapConfigs(id)
    return config.Prefab
end

--行
function XRpgMakerGameConfigs.GetRpgMakerGameRow(id)
    local config = GetRpgMakerGameMapConfigs(id)
    return config.Row
end

--列
function XRpgMakerGameConfigs.GetRpgMakerGameCol(id)
    local config = GetRpgMakerGameMapConfigs(id)
    return config.Col
end
-----------------RpgMakerGameMap 地图 end-------------------------

-----------------RpgMakerGameStartPoint 玩家起点 begin-----------------------
local GetRpgMakerGameStartPointConfigs = function(id)
    local config = RpgMakerGameStartPointConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameStartPointConfigs", "RpgMakerGameStartPointConfigs", TABLE_START_POINT_PATH, "Id", tostring(id))
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameStartPointX(id)
    local config = GetRpgMakerGameStartPointConfigs(id)
    return config.X
end

function XRpgMakerGameConfigs.GetRpgMakerGameStartPointY(id)
    local config = GetRpgMakerGameStartPointConfigs(id)
    return config.Y
end

function XRpgMakerGameConfigs.GetRpgMakerGameStartPointDirection(id)
    local config = GetRpgMakerGameStartPointConfigs(id)
    return config.Direction
end

function XRpgMakerGameConfigs.IsRpgMakerGameStartPoint(mapId, x, y)
    local startPointId = XRpgMakerGameConfigs.GetRpgMakerGameStartPointId(mapId)
    local startPointX = XRpgMakerGameConfigs.GetRpgMakerGameStartPointX(startPointId)
    local startPointY = XRpgMakerGameConfigs.GetRpgMakerGameStartPointY(startPointId)
    return startPointX == x and startPointY == y
end
-----------------RpgMakerGameStartPoint 玩家起点 end-------------------------

-----------------RpgMakerGameEndPoint 终点 begin-----------------------
local GetRpgMakerGameEndPointConfigs = function(id)
    local config = RpgMakerGameEndPointConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameEndPointConfigs", "RpgMakerGameEndPointConfigs", TABLE_END_POINT_PATH, "Id", tostring(id))
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameEndPointX(id)
    local config = GetRpgMakerGameEndPointConfigs(id)
    return config.X
end

function XRpgMakerGameConfigs.GetRpgMakerGameEndPointY(id)
    local config = GetRpgMakerGameEndPointConfigs(id)
    return config.Y
end

function XRpgMakerGameConfigs.GetRpgMakerGameEndPointType(id)
    local config = GetRpgMakerGameEndPointConfigs(id)
    return config.Type
end

function XRpgMakerGameConfigs.IsRpgMakerGameEndPoint(mapId, x, y)
    local endPointId = XRpgMakerGameConfigs.GetRpgMakerGameEndPointId(mapId)
    local endPointX = XRpgMakerGameConfigs.GetRpgMakerGameEndPointX(endPointId)
    local endPointY = XRpgMakerGameConfigs.GetRpgMakerGameEndPointY(endPointId)
    return endPointX == x and endPointY == y
end
-----------------RpgMakerGameEndPoint 终点 end-------------------------

-----------------RpgMakerGameBlock 阻挡物 begin-----------------------
local GetRpgMakerGameBlockConfigs = function(id)
    local config = RpgMakerGameBlockConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameBlockConfigs", "RpgMakerGameBlockConfigs", TABLE_BLOCK_PATH, "Id", tostring(id))
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameBlockRow(id)
    local config = GetRpgMakerGameBlockConfigs(id)
    return config.Row
end

function XRpgMakerGameConfigs.GetRpgMakerGameBlockColList(id)
    local config = GetRpgMakerGameBlockConfigs(id)
    return config.Col
end

function XRpgMakerGameConfigs.GetRpgMakerGameMapIdToBlockIdList(mapId)
    return RpgMakerGameMapIdToBlockIdList[mapId] or {}
end

function XRpgMakerGameConfigs.IsRpgMakerGameHaveBlock(mapId)
    local blockIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToBlockIdList(mapId)
    local colList
    for _, blockId in ipairs(blockIdList) do
        colList = XRpgMakerGameConfigs.GetRpgMakerGameBlockColList(blockId)
        for _, col in ipairs(colList) do
            if not XTool.IsNumberValid(col) then
                return true
            end
        end
    end
    return false
end
-----------------RpgMakerGameBlock 阻挡物 end-------------------------

-----------------RpgMakerGameGap 墙 begin-----------------------
local GetRpgMakerGameGapConfigs = function(id)
    local config = RpgMakerGameGapConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameGapConfigs", "RpgMakerGameGapConfigs", TABLE_GAP_PATH, "Id", tostring(id))
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameGapX(id)
    local config = GetRpgMakerGameGapConfigs(id)
    return config.X
end

function XRpgMakerGameConfigs.GetRpgMakerGameGapY(id)
    local config = GetRpgMakerGameGapConfigs(id)
    return config.Y
end

function XRpgMakerGameConfigs.GetRpgMakerGameGapDirection(id)
    local config = GetRpgMakerGameGapConfigs(id)
    return config.Direction
end

function XRpgMakerGameConfigs.GetRpgMakerGameMapIdToGapIdList(id)
    return RpgMakerGameMapIdToGapIdList[id] or {}
end

--获得相同x和y坐标的gapId列表
function XRpgMakerGameConfigs.GetRpgMakerGameSameXYGapIdIdList(mapId, x, y)
    local gapIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToGapIdList(mapId)
    local gapX
    local gapY
    local sameXYGapIdList = {}
    for _, gapId in ipairs(gapIdList) do
        gapX = XRpgMakerGameConfigs.GetRpgMakerGameGapX(gapId)
        gapY = XRpgMakerGameConfigs.GetRpgMakerGameGapY(gapId)
        if gapX == x and gapY == y then
            tableInsert(sameXYGapIdList, gapId)
        end
    end
    return sameXYGapIdList
end
-----------------RpgMakerGameGap 墙 end-------------------------

-----------------RpgMakerGameMonster 怪物 begin-----------------------
local GetRpgMakerGameMonsterConfigs = function(id)
    local config = RpgMakerGameMonsterConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameMonsterConfigs", "RpgMakerGameMonsterConfigs", TABLE_MONSTER_PATH, "Id", tostring(id))
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameMonsterType(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.Type
end

function XRpgMakerGameConfigs.GetRpgMakerGameMonsterSkillType(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.SkillType
end

function XRpgMakerGameConfigs.GetRpgMakerGameMonsterX(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.X
end

function XRpgMakerGameConfigs.GetRpgMakerGameMonsterY(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.Y
end

function XRpgMakerGameConfigs.GetRpgMakerGameMonsterDirection(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.Direction
end

function XRpgMakerGameConfigs.GetRpgMakerGameMonsterViewFront(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.ViewFront
end

function XRpgMakerGameConfigs.GetRpgMakerGameMonsterViewBack(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.ViewBack
end

function XRpgMakerGameConfigs.GetRpgMakerGameMonsterViewLeft(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.ViewLeft
end

function XRpgMakerGameConfigs.GetRpgMakerGameMonsterViewRight(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.ViewRight
end

function XRpgMakerGameConfigs.GetRpgMakerGameSentryFront(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.SentryFront
end

function XRpgMakerGameConfigs.GetRpgMakerGameSentryBack(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.SentryBack
end

function XRpgMakerGameConfigs.GetRpgMakerGameSentryLeft(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.SentryLeft
end

function XRpgMakerGameConfigs.GetRpgMakerGameSentryRight(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.SentryRight
end

function XRpgMakerGameConfigs.GetRpgMakerGameSentryStopRound(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.SentryStopRound
end

function XRpgMakerGameConfigs.GetRpgMakerGameMapIdToMonsterIdList(mapId)
    return RpgMakerGameMapIdToMonsterIdList[mapId] or {}
end

function XRpgMakerGameConfigs.GetRpgMakerGameMonsterPrefab(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.Prefab
end

function XRpgMakerGameConfigs.GetRpgMakerGameMonsterId(mapId, x, y)
    local monsterIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToMonsterIdList(mapId)
    local monsterX
    local monsterY
    for _, monsterId in ipairs(monsterIdList) do
        monsterX = XRpgMakerGameConfigs.GetRpgMakerGameMonsterX(monsterId)
        monsterY = XRpgMakerGameConfigs.GetRpgMakerGameMonsterY(monsterId)
        if monsterX == x and monsterY == y then
            return monsterId
        end
    end
end

function XRpgMakerGameConfigs.GetRpgMakerGameMonsterPatrolIdList(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.PatrolId
end

function XRpgMakerGameConfigs.IsRpgMakerGameMonsterTriggerEnd(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return XTool.IsNumberValid(config.TriggerEnd)
end

function XRpgMakerGameConfigs.IsRpgMakerGameHaveMonster(mapId, monsterType)
    local monsterIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToMonsterIdList(mapId)
    local isHaveNormalIcon, isHaveCrystalIcon, isHaveFlameIcon, isHaveRaidenIcon, isHaveDarkIcon
    local typeCfg
    local skillCfg
    for _, monsterId in ipairs(monsterIdList) do
        typeCfg = XRpgMakerGameConfigs.GetRpgMakerGameMonsterType(monsterId)
        skillCfg = XRpgMakerGameConfigs.GetRpgMakerGameMonsterSkillType(monsterId)
        if typeCfg == monsterType then
            if monsterType == XRpgMakerGameConfigs.XRpgMakerGameMonsterType.Human then
                return true
            elseif skillCfg then
                if skillCfg == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Crystal then isHaveCrystalIcon = true
                elseif skillCfg == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Flame then isHaveFlameIcon = true
                elseif skillCfg == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Raiden then isHaveRaidenIcon = true
                elseif skillCfg == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Dark then isHaveDarkIcon = true
                else isHaveNormalIcon = true end
            else
                isHaveNormalIcon = true
            end
        end
        if isHaveNormalIcon and isHaveCrystalIcon and isHaveFlameIcon and isHaveRaidenIcon and isHaveDarkIcon then
            break
        end
    end
    return isHaveNormalIcon, isHaveCrystalIcon, isHaveFlameIcon, isHaveRaidenIcon, isHaveDarkIcon
end

function XRpgMakerGameConfigs.GetMonsterSkillType(id)
    local config = GetRpgMakerGameMonsterConfigs(id)
    return config.SkillType
end
-----------------RpgMakerGameMonster 怪物 end-------------------------

-----------------RpgMakerGameTrigger 机关 begin-----------------------
local GetRpgMakerGameTriggerConfigs = function(id)
    local config = RpgMakerGameTriggerConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameTriggerConfigs", "RpgMakerGameTriggerConfigs", TABLE_TRIGGER_PATH, "Id", tostring(id))
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameTriggerX(id)
    local config = GetRpgMakerGameTriggerConfigs(id)
    return config.X
end

function XRpgMakerGameConfigs.GetRpgMakerGameTriggerY(id)
    local config = GetRpgMakerGameTriggerConfigs(id)
    return config.Y
end

function XRpgMakerGameConfigs.GetRpgMakerGameTriggerDefaultBlock(id)
    local config = GetRpgMakerGameTriggerConfigs(id)
    return config.DefaultBlock
end

function XRpgMakerGameConfigs.GetRpgMakerGameTriggerType(id)
    local config = GetRpgMakerGameTriggerConfigs(id)
    return config.Type
end

function XRpgMakerGameConfigs.GetRpgMakerGameMapIdToTriggerIdList(mapId)
    return RpgMakerGameMapIdToTriggerIdList[mapId] or {}
end

function XRpgMakerGameConfigs.GetRpgMakerGameTriggerId(mapId, x, y)
    local triggerIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToTriggerIdList(mapId)
    local triggerX
    local triggerY
    for _, triggerId in ipairs(triggerIdList) do
        triggerX = XRpgMakerGameConfigs.GetRpgMakerGameTriggerX(triggerId)
        triggerY = XRpgMakerGameConfigs.GetRpgMakerGameTriggerY(triggerId)
        if triggerX == x and triggerY == y then
            return triggerId
        end
    end
end

function XRpgMakerGameConfigs.IsRpgMakerGameHaveTrigger(mapId)
    local isHaveType1Trigger, isHaveType2Trigger, isHaveType3Trigger, isHaveElectricFencTrigger
    local triggerIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToTriggerIdList(mapId)
    local typeCfg
    for _, triggerId in ipairs(triggerIdList) do
        typeCfg = XRpgMakerGameConfigs.GetRpgMakerGameTriggerType(triggerId)
        if typeCfg == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger1 then
            isHaveType1Trigger = true
        elseif typeCfg == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger2 then
            isHaveType2Trigger = true
        elseif typeCfg == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger3 then
            isHaveType3Trigger = true
        elseif typeCfg == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.TriggerElectricFence then
            isHaveElectricFencTrigger = true
        end

        if isHaveType1Trigger and isHaveType2Trigger and isHaveType3Trigger and isHaveElectricFencTrigger then
            break
        end
    end
    return isHaveType1Trigger, isHaveType2Trigger, isHaveType3Trigger, isHaveElectricFencTrigger
end
-----------------RpgMakerGameTrigger 机关 end-------------------------

-----------------RpgMakerGameHintIcon 通关提示图标 begin-----------------------
local GetRpgMakerGameHintIconConfig = function(key)
    local config = RpgMakerGameHintIconConfigs[key]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameHintIconConfig", "RpgMakerGameHintIconConfigs", TABLE_HINT_ICON_PATH, "Key", key)
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintIconKeyList()
    local hintIconKeyList = {}
    for k in pairs(RpgMakerGameHintIconConfigs) do
        tableInsert(hintIconKeyList, k)
    end
    return hintIconKeyList
end

--只获取该地图上有对应对象的图标
function XRpgMakerGameConfigs.GetRpgMakerGameHintIconKeyListByMapId(mapId, isNotShowLine)
    local hintIconKeyList = {}
    if not XTool.IsNumberValid(mapId) then
        return hintIconKeyList
    end

    local isHaveBlock = XRpgMakerGameConfigs.IsRpgMakerGameHaveBlock(mapId)
    -- 不同属性库洛洛不同图标
    local isHaveNormalMonster, isHaveCrystalMonsterIcon, isHaveFlameMonsterIcon, isHaveRaidenMonsterIcon, isHaveDarkMonsterIcon
        = XRpgMakerGameConfigs.IsRpgMakerGameHaveMonster(mapId, XRpgMakerGameConfigs.XRpgMakerGameMonsterType.Normal)
    local isHaveNormalBoss, isHaveCrystalBossIcon, isHaveFlameBossIcon, isHaveRaidenBossIcon, isHaveDarkBossIcon
        = XRpgMakerGameConfigs.IsRpgMakerGameHaveMonster(mapId, XRpgMakerGameConfigs.XRpgMakerGameMonsterType.BOSS)

    local isHaveType1Trigger, isHaveType2Trigger, isHaveType3Trigger, isHaveElectricFencTrigger = XRpgMakerGameConfigs.IsRpgMakerGameHaveTrigger(mapId)
    local isHaveGap = not XTool.IsTableEmpty(XRpgMakerGameConfigs.GetRpgMakerGameMapIdToGapIdList(mapId))
    local isHaveShadow = not XTool.IsTableEmpty(XRpgMakerGameConfigs.GetRpgMakerGameMapIdToShadowIdList(mapId))
    local isHaveElectricFence = not XTool.IsTableEmpty(XRpgMakerGameConfigs.GetRpgMakerGameMapIdToElectricFenceIdList(mapId))
    local isHaveHuman = XRpgMakerGameConfigs.IsRpgMakerGameHaveMonster(mapId, XRpgMakerGameConfigs.XRpgMakerGameMonsterType.Human)
    local isHaveTrap = not XTool.IsTableEmpty(XRpgMakerGameConfigs.GetRpgMakerGameMapIdToTrapIdList(mapId))
    -- 地图实体：1 水面、2 冰面、3 草圃、4 钢板
    local isHaveEntity1, isHaveEntity2, isHaveEntity3, isHaveEntity4 = XRpgMakerGameConfigs.IsRpgMakerGameHaveEntity(mapId)
    local isHaveTransferPoint1, isHaveTransferPoint2, isHaveTransferPoint3 = XRpgMakerGameConfigs.IsRpgMakerGameHaveTransferPoint(mapId)

    local isInsert = true
    for k in pairs(RpgMakerGameHintIconConfigs) do
        if k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.BlockIcon then
            isInsert = isHaveBlock
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.CrystalMonsterIcon then
            isInsert = isHaveCrystalMonsterIcon
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.FlameMonsterIcon then
            isInsert = isHaveFlameMonsterIcon
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.RaidenMonsterIcon then
            isInsert = isHaveRaidenMonsterIcon
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.DarkMonsterIcon then
            isInsert = isHaveDarkMonsterIcon
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.NormalMonsterIcon then
            isInsert = isHaveNormalMonster
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.CrystalBossIcon then
            isInsert = isHaveCrystalBossIcon
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.FlameBossIcon then
            isInsert = isHaveFlameBossIcon
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.RaidenBossIcon then
            isInsert = isHaveRaidenBossIcon
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.DarkBossIcon then
            isInsert = isHaveDarkBossIcon
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.BossIcon then
            isInsert = isHaveNormalBoss
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.TriggerIcon1 then
            isInsert = isHaveType1Trigger
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.TriggerIcon2 then
            isInsert = isHaveType2Trigger
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.TriggerIcon3 then
            isInsert = isHaveType3Trigger
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.ElectricFencTrigger then
            isInsert = isHaveElectricFencTrigger
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.GapIcon then
            isInsert = isHaveGap
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.ShadowIcon then
            isInsert = isHaveShadow
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.ElectricFenceIcon then
            isInsert = isHaveElectricFence
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.HumanIcon then
            isInsert = isHaveHuman
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.TrapIcon then
            isInsert = isHaveTrap
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.EntityIcon1 then
            isInsert = isHaveEntity1
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.EntityIcon2 then
            isInsert = isHaveEntity2
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.EntityIcon3 then
            isInsert = isHaveEntity3
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.EntityIcon4 then
            isInsert = isHaveEntity4
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.TransferPointIcon1 then
            isInsert = isHaveTransferPoint1
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.TransferPointIcon2 then
            isInsert = isHaveTransferPoint2
        elseif k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.TransferPointIcon3 then
            isInsert = isHaveTransferPoint3
        elseif isNotShowLine and k == XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.MoveLineIcon then
            isInsert = false
        end

        if isInsert then
            tableInsert(hintIconKeyList, k)
        end
        isInsert = true
    end
    return hintIconKeyList
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintIcon(key)
    local config = GetRpgMakerGameHintIconConfig(key)
    return config.Icon
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintLayer(key)
    local config = GetRpgMakerGameHintIconConfig(key)
    return config.Layer
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintIconName(key)
    local config = GetRpgMakerGameHintIconConfig(key)
    return config.Name
end

function XRpgMakerGameConfigs.GetMonsterIconKey(monsterType, skillType)
    if XRpgMakerGameConfigs.XRpgMakerGameMonsterType.BOSS == monsterType then
        if skillType then
            if skillType == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Crystal then
                return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.CrystalBossIcon
            elseif skillType == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Flame then
                return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.FlameBossIcon
            elseif skillType == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Raiden then
                return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.RaidenBossIcon
            elseif skillType == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Dark then
                return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.DarkBossIcon
            end
        end
        
        return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.BossIcon
    end

    if XRpgMakerGameConfigs.XRpgMakerGameMonsterType.Human == monsterType then
        return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.HumanIcon
    end

    if skillType then
        if skillType == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Crystal then
            return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.CrystalMonsterIcon
        elseif skillType == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Flame then
            return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.FlameMonsterIcon
        elseif skillType == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Raiden then
            return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.RaidenMonsterIcon
        elseif skillType == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Dark then
            return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.DarkMonsterIcon
        end
    end

    return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.NormalMonsterIcon
end

function XRpgMakerGameConfigs.GetTriggerIconKey(triggerType)
    if triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger1 then
        return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.TriggerIcon1
    end

    if triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger2 then
        return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.TriggerIcon2
    end

    if triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.TriggerElectricFence  then
        return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.ElectricFencTrigger
    end

    return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.TriggerIcon3
end

function XRpgMakerGameConfigs.GetEntityIconKey(entityType)
    if entityType == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Water then
        return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.EntityIcon1
    end

    if entityType == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Ice then
        return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.EntityIcon2
    end

    if entityType == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Grass  then
        return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.EntityIcon3
    end

    return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.EntityIcon4
end

function XRpgMakerGameConfigs.GetTransferPointIconKey(transferPointColor)
    if transferPointColor == XRpgMakerGameConfigs.XRpgMakerTransferPointColor.Green then
        return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.TransferPointIcon1
    end

    if transferPointColor == XRpgMakerGameConfigs.XRpgMakerTransferPointColor.Yellow then
        return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.TransferPointIcon2
    end

    return XRpgMakerGameConfigs.RpgMakerGameHintIconKeyMaps.TransferPointIcon3
end
-----------------RpgMakerGameHintIcon 通关提示图标 end-------------------------

-----------------RpgMakerGameActivity 活动相关 begin-----------------------
local GetRpgMakerGameActivityConfig = function(id)
    local config = RpgMakerGameActivityConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameActivityConfig", "RpgMakerGameActivityConfigs", TABLE_ACTIVITY_PATH, "Id", id)
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetDefaultActivityId()
    return DefaultActivityId
end

function XRpgMakerGameConfigs.GetRpgMakerGameActivityTaskTimeLimitId(id)
    local config = GetRpgMakerGameActivityConfig(id)
    return config.TaskTimeLimitId
end

function XRpgMakerGameConfigs.GetRpgMakerGameActivityTimeId(id)
    local config = GetRpgMakerGameActivityConfig(id)
    return config.TimeId
end

function XRpgMakerGameConfigs.GetActivityName(id)
    local config = GetRpgMakerGameActivityConfig(id)
    return config.Name
end

function XRpgMakerGameConfigs.GetActivityBannerBg(id)
    local config = GetRpgMakerGameActivityConfig(id)
    return config.BannerBg
end

function XRpgMakerGameConfigs.GetActivityCollectionIcon(id)
    local config = GetRpgMakerGameActivityConfig(id)
    return config.CollectionIcon
end

function XRpgMakerGameConfigs.GetActivityGuideMoveDirection(id)
    id = id or XRpgMakerGameConfigs.GetDefaultActivityId()
    local config = GetRpgMakerGameActivityConfig(id)
    return config.GuideMoveDirection
end
-----------------RpgMakerGameActivity 活动相关 end-------------------------

-----------------RpgMakerGameRandomDialogBox 随机提示 begin-----------------------
local GetRpgMakerGameRandomDialogBoxConfigs = function(id)
    local config = RpgMakerGameRandomDialogBoxConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameRandomDialogBoxConfigs", "RpgMakerGameRandomDialogBoxConfigs", TABLE_RANDOM_DIALOG_BOX_PATH, "Id", id)
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameRandomDialogBoxIdList()
    return RpgMakerGameRandomDialogBoxIdList
end

function XRpgMakerGameConfigs.GetRpgMakerGameRandomDialogBoxPreStage(id)
    local config = GetRpgMakerGameRandomDialogBoxConfigs(id)
    return config.PreStage
end

function XRpgMakerGameConfigs.GetRpgMakerGameRandomDialogBoxText(id)
    local config = GetRpgMakerGameRandomDialogBoxConfigs(id)
    return config.Text or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameRandomDialogBoxWeight(id)
    local config = GetRpgMakerGameRandomDialogBoxConfigs(id)
    return config.Weight
end

function XRpgMakerGameConfigs.GetRpgMakerGameRandomDialogBoxDuration(id)
    local config = GetRpgMakerGameRandomDialogBoxConfigs(id)
    return config.Duration
end
-----------------RpgMakerGameRandomDialogBox 随机提示 end-------------------------

-----------------RpgMakerGameHintDialogBox 点击头像提示 begin-----------------------
local GetRpgMakerGameHintDialogBoxConfigs = function(id)
    local config = RpgMakerGameHintDialogBoxConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxConfigs", "RpgMakerGameHintDialogBoxConfigs", TABLE_HINT_DIALOG_BOX_PATH, "Id", id)
        return
    end
    return config
end

function XRpgMakerGameConfigs.IsHasRpgMakerGameHintDialogBox(id)
    return RpgMakerGameHintDialogBoxConfigs[id] and true or false
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxText(id)
    local config = GetRpgMakerGameHintDialogBoxConfigs(id)
    return config and config.Text or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxBackCount(id)
    local config = GetRpgMakerGameHintDialogBoxConfigs(id)
    return config and config.BackCount or 0
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxResetCount(id)
    local config = GetRpgMakerGameHintDialogBoxConfigs(id)
    return config.ResetCount
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxTotalLoseCount(id)
    local config = GetRpgMakerGameHintDialogBoxConfigs(id)
    return config.TotalLoseCount
end
-----------------RpgMakerGameHintDialogBox 点击头像提示 end-------------------------

-----------------RpgMakerGameModel 模型相关 begin-----------------------
local GetRpgMakerGameModelConfig = function(key)
    local config = RpgMakerGameModelConfigs[key]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.RpgMakerGameModelConfig", "RpgMakerGameModelConfigs", TABLE_MODEL_PATH, "Key", key)
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameModelPath(key)
    local config = GetRpgMakerGameModelConfig(key)
    return config.ModelPath or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameTriggerKey(triggerType, isOpen)
    if triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger1 then
        return XRpgMakerGameConfigs.ModelKeyMaps.TriggerType1
    end

    if triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger2 then
        return XRpgMakerGameConfigs.ModelKeyMaps.TriggerType2
    end

    if triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger3 then
        return XRpgMakerGameConfigs.ModelKeyMaps.TriggerType3
    end

    if triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.TriggerElectricFence then
        return isOpen and XRpgMakerGameConfigs.ModelKeyMaps.TriggerElectricFenceOpen or XRpgMakerGameConfigs.ModelKeyMaps.TriggerElectricFenceClose
    end
end

function XRpgMakerGameConfigs.GetTransferPointLoopColorKey(colorIndex)
    return XRpgMakerGameConfigs.ModelKeyMaps["TransferPointLoopColor" .. colorIndex]
end

function XRpgMakerGameConfigs.GetTransferPointColorKey(colorIndex)
    return XRpgMakerGameConfigs.ModelKeyMaps["TransferPointColor" .. colorIndex]
end

function XRpgMakerGameConfigs.GetModelEntityKey(entityType)
    if entityType == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Water then
        return XRpgMakerGameConfigs.ModelKeyMaps.WaterRipper
    elseif entityType == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Ice then
        return XRpgMakerGameConfigs.ModelKeyMaps.Freeze
    elseif entityType == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Grass then
        return XRpgMakerGameConfigs.ModelKeyMaps.Grass
    elseif entityType == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Steel then
        return XRpgMakerGameConfigs.ModelKeyMaps.Steel
    end
end

function XRpgMakerGameConfigs.GetModelSkillEffctKey(skillType)
    if skillType == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Crystal then
        return XRpgMakerGameConfigs.ModelKeyMaps.CrystalSkillEffect
    elseif skillType == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Flame then
        return XRpgMakerGameConfigs.ModelKeyMaps.FlameSkillEffect
    elseif skillType == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Raiden then
        return XRpgMakerGameConfigs.ModelKeyMaps.RaidenSkillEffect
    elseif skillType == XRpgMakerGameConfigs.XRpgMakerGameRoleSkillType.Dark then
        return XRpgMakerGameConfigs.ModelKeyMaps.DarkSkillEffect
    end
end

function XRpgMakerGameConfigs.GetRpgMakerGameModelName(key)
    local config = GetRpgMakerGameModelConfig(key)
    return config.Name or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameModelDesc(key)
    local config = GetRpgMakerGameModelConfig(key)
    return config.Desc or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameModelIcon(key)
    local config = GetRpgMakerGameModelConfig(key)
    return config.Icon or ""
end

function XRpgMakerGameConfigs.GetModelSize(key)
    local config = GetRpgMakerGameModelConfig(key)
    local size = config.Size
    local sizeList = string.Split(size, "|")
    return {x = tonumber(sizeList[1]) or 0, 
        y = tonumber(sizeList[2]) or 0, 
        z = tonumber(sizeList[3] or 0)
        }
end
-----------------RpgMakerGameModel 模型相关 end-----------------------

-----------------RpgMakerGameAnimation 动画相关 begin-----------------------
local GetRpgMakerGameAnimationConfig = function(modelName)
    local config = RpgMakerGameAnimationConfigs[modelName]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.RpgMakerGameAnimationConfig", "RpgMakerGameAnimationConfigs", TABLE_ANIMATION_PATH, "ModelName", modelName)
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameStandAnimaName(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.StandAnimaName or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameRunAnimaName(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.RunAnimaName or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameAtkAnimaName(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.AtkAnimaName or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameElectricFenceAnimaName(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.ElectricFenceAnimaName or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameAlarmAnimaName(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.AlarmAnimaName or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameDrownAnimaName(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.DrownAnimaName or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameAdsorbAnimaName(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.AdsorbAnimaName or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameTransferAnimaName(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.TransferAnimaName or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameTransferDisAnimaName(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.TransferDisAnimaName or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameEffectRoot(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.EffectRoot or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameSentrySignYOffset(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    local yOffset = config and config.SentrySignYOffset
    return yOffset and yOffset / 1000 or 0
end

function XRpgMakerGameConfigs.GetRpgMakerGameXOffSet(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.XOffSet or 0
end

function XRpgMakerGameConfigs.GetRpgMakerGameYOffSet(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.YOffSet or 0
end

function XRpgMakerGameConfigs.GetRpgMakerGameZOffSet(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.ZOffSet or 0
end

function XRpgMakerGameConfigs.GetRpgMakerGameName(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.Name or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameDesc(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.Desc or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameIcon(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.Icon or ""
end
-----------------RpgMakerGameAnimation 动画相关 end-----------------------

-----------------RpgMakerGamePlayMainDownHint 玩法主界面下方提示 begin-----------------------
local GetRpgMakerGamePlayMainDownHintConfig = function(id)
    local config = RpgMakerGamePlayMainDownHintConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.RpgMakerGamePlayMainDownHintConfig", "RpgMakerGamePlayMainDownHintConfigs", TABLE_PLAY_MAIN_DOWN_HINT_PATH, "Id", id)
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGamePlayMainDownHintConfigMaxCount()
    return #RpgMakerGamePlayMainDownHintConfigs
end

function XRpgMakerGameConfigs.GetRpgMakerGamePlayMainDownHintText(id)
    local config = GetRpgMakerGamePlayMainDownHintConfig(id)
    return config.Text or ""
end
-----------------RpgMakerGamePlayMainDownHint 玩法主界面下方提示 end-----------------------

-----------------RpgMakerGameHintLine 通关提示线路 begin--------------------
local GetRpgMakerGameHintLineConfig = function(mapId)
    local config = RpgMakerGameHintLineConfigs[mapId]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.RpgMakerGameHintLineConfig", "RpgMakerGameHintLineConfigs", TABLE_HINT_LINE_PATH, "MapId", mapId)
        return
    end
    return config
end

local GetStringSplitTwoNumParam = function(text)
    local textList = string.Split(text, "|")
    return textList[1] and tonumber(textList[1]) or 0, textList[2] and tonumber(textList[2]) or 0
end

function XRpgMakerGameConfigs.GetHintLineHintTitle(mapId)
    local config = GetRpgMakerGameHintLineConfig(mapId)
    return config.HintTitle or ""
end

--获得开始绘制线的格子行和列
function XRpgMakerGameConfigs.GetHintLineStartRowAndCol(mapId)
    local config = GetRpgMakerGameHintLineConfig(mapId)
    local row, line = GetStringSplitTwoNumParam(config.StartRowAndCol)
    return row, line
end

function XRpgMakerGameConfigs.GetHintLineStartGridPercent(mapId)
    local config = GetRpgMakerGameHintLineConfig(mapId)
    local widthPercent, heightPercent = GetStringSplitTwoNumParam(config.StartGridPercent)
    return widthPercent, heightPercent
end

--获得格子中从哪一点开始
function XRpgMakerGameConfigs.GetHintLineStartGridPos(mapId, width, height)
    local percentWidth, percentHeight = XRpgMakerGameConfigs.GetHintLineStartGridPercent(mapId)
    local x = width and width * percentWidth or 0
    local y = height and height * percentHeight or 0
    return x, y
end

function XRpgMakerGameConfigs.GetHintLineNextRowAndColList(mapId)
    local config = GetRpgMakerGameHintLineConfig(mapId)
    return config.NextRowAndCol
end

function XRpgMakerGameConfigs.GetHintLineNextRowAndCol(mapId, index)
    local row, line = 0, 0
    local config = GetRpgMakerGameHintLineConfig(mapId)
    local nextRowAndCol = config.NextRowAndCol[index]
    if not nextRowAndCol then
        return row, line
    end

    row, line = GetStringSplitTwoNumParam(nextRowAndCol)
    return row, line
end

function XRpgMakerGameConfigs.GetHintLineNextGridPercent(mapId, index)
    local widthPercent, heightPercent = 0, 0
    local config = GetRpgMakerGameHintLineConfig(mapId)
    local nextGridPercent = config.NextGridPercent[index]
    if not nextGridPercent then
        return widthPercent, heightPercent
    end

    widthPercent, heightPercent = GetStringSplitTwoNumParam(nextGridPercent)
    return widthPercent, heightPercent
end

--获得格子中终点位置的宽度和高度百分比
--direction：方向
--isEnd：是否为绘制一条线的最后一个格子
--endWidthPercent：绘制一条线的最后一个格子的宽度百分比
--endHeightPercent：绘制一条线的最后一个格子的高度百分比
local GetEndPercent = function(direction, isEnd, endWidthPercent, endHeightPercent)
    if isEnd then
        return endWidthPercent, endHeightPercent
    end

    endWidthPercent = (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft and 0) or (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight and 1) or endWidthPercent
    endHeightPercent = (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown and 0) or (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp and 1) or endHeightPercent
    return endWidthPercent, endHeightPercent
end

--获得格子中起点位置的宽度和高度百分比
--direction：方向
--startWidthPercent：绘制一条线的第一个格子的宽度百分比
--startHeightPercent：绘制一条线的第一个格子的高度百分比
local GetStartPercent = function(direction, startWidthPercent, startHeightPercent)
    startWidthPercent = (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft and 1) or (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight and 0) or startWidthPercent
    startHeightPercent = (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown and 1) or (direction == XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp and 0) or startHeightPercent
    return startWidthPercent, startHeightPercent
end

--获得各个格子绘制线的数据
function XRpgMakerGameConfigs.GetHintLineMap(mapId)
    local hintLineMap = {}
    local mapId = mapId
    local lineId = 0

    local InsertHintLineMap = function(row, col, widthPercent, heightPercent, direction, isStart, endWidthPercent, endHeightPercent)
        lineId = lineId + 1
        if not hintLineMap[row] then
            hintLineMap[row] = {}
        end
        if not hintLineMap[row][col] then
            hintLineMap[row][col] = {}
        end

        local param = {
            IsStart = isStart,              --是否是第一条绘制的线
            WidthPercent = widthPercent,    --格子宽度百分比，用来计算线在格子中的起始位置
            HeightPercent = heightPercent,  --格子高度百分比，用来计算线在格子中的起始位置
            EndWidthPercent = endWidthPercent,      --格子宽度百分比，用来计算线在格子中的终点位置
            EndHeightPercent = endHeightPercent,    --格子高度百分比，用来计算线在格子中的终点位置
            Direction = direction,          --箭头方向
            Id = lineId,
        }

        table.insert(hintLineMap[row][col], param)
    end

    local startRow, startCol = XRpgMakerGameConfigs.GetHintLineStartRowAndCol(mapId)
    local startWidthPercent, startHeightPercent = XRpgMakerGameConfigs.GetHintLineStartGridPercent(mapId)
    local nextRow, nextCol = XRpgMakerGameConfigs.GetHintLineNextRowAndCol(mapId, 1)
    local endWidthPercent, endHeightPercent = XRpgMakerGameConfigs.GetHintLineNextGridPercent(mapId, 1)
    local direction = XRpgMakerGameConfigs.GetHintLineDirection(startRow, startCol, nextRow, nextCol, startWidthPercent, startHeightPercent, endWidthPercent, endHeightPercent)
    local isSameGrid = startRow == nextRow and startCol == nextCol and (startWidthPercent ~= endWidthPercent or startHeightPercent ~= endHeightPercent) --前后两点是否在同一格子里，且宽高百分比至少有一个不同
    local distance = (nextCol ~= startCol and nextRow ~= startRow) and 0 or math.floor(math.sqrt((nextCol - startCol) ^ 2 + (nextRow - startRow) ^ 2))  --前后两点的距离，不在一条直线上时为0
    if distance ~= 0 or isSameGrid then
        endWidthPercent, endHeightPercent = GetEndPercent(direction, distance == 0, endWidthPercent, endHeightPercent)
        InsertHintLineMap(startRow, startCol, startWidthPercent, startHeightPercent, direction, true, endWidthPercent, endHeightPercent)
    end

    local nextRowAndColList = XRpgMakerGameConfigs.GetHintLineNextRowAndColList(mapId)
    local isStart
    local isEnd
    local startWidthPercentTemp
    local startHeightPercentTemp
    local endWidthPercentTemp
    local endHeightPercentTemp
    local row
    local col
    for nextRowAndColIndex in ipairs(nextRowAndColList) do
        isStart = nextRowAndColIndex == 1
        endWidthPercent, endHeightPercent = XRpgMakerGameConfigs.GetHintLineNextGridPercent(mapId, nextRowAndColIndex)
        nextRow, nextCol = XRpgMakerGameConfigs.GetHintLineNextRowAndCol(mapId, nextRowAndColIndex)
        direction = XRpgMakerGameConfigs.GetHintLineDirection(startRow, startCol, nextRow, nextCol, startWidthPercent, startHeightPercent, endWidthPercent, endHeightPercent)

        distance = (nextCol ~= startCol and nextRow ~= startRow) and 0 or math.floor(math.sqrt((nextCol - startCol) ^ 2 + (nextRow - startRow) ^ 2))
        isEnd = distance == 0
        isSameGrid = startRow == nextRow and startCol == nextCol and (startWidthPercent ~= endWidthPercent or startHeightPercent ~= endHeightPercent)
        if (not isStart) and (distance ~= 0 or isSameGrid) then
            endWidthPercentTemp, endHeightPercentTemp = GetEndPercent(direction, isEnd, endWidthPercent, endHeightPercent)
            InsertHintLineMap(startRow, startCol, startWidthPercent, startHeightPercent, direction, false, endWidthPercentTemp, endHeightPercentTemp)
        end

        for i = 1, distance do
            isEnd = i == distance
            startWidthPercentTemp, startHeightPercentTemp = GetStartPercent(direction, startWidthPercent, startHeightPercent)
            endWidthPercentTemp, endHeightPercentTemp = GetEndPercent(direction, isEnd, endWidthPercent, endHeightPercent)

            if isEnd then
                InsertHintLineMap(nextRow, nextCol, startWidthPercentTemp, startHeightPercentTemp, direction, isStart, endWidthPercentTemp, endHeightPercentTemp)
            else
                row = (startRow - nextRow == 0 and startRow) or (startRow > nextRow and startRow - i or startRow + i)
                col = (startCol - nextCol == 0 and startCol) or (startCol > nextCol and startCol - i or startCol + i)
                InsertHintLineMap(row, col, startWidthPercentTemp, startHeightPercentTemp, direction, isStart, endWidthPercentTemp, endHeightPercentTemp)
            end
        end

        startRow, startCol = nextRow, nextCol
        startWidthPercent, startHeightPercent = XRpgMakerGameConfigs.GetHintLineNextGridPercent(mapId, nextRowAndColIndex)
    end

    return hintLineMap, lineId
end

--获得一条线的方向
--startRow, startCol：起点的行数和列数
--endRow, endCol：终点的行数和列数
--startWidthPercent, startHeightPercent：起点在格子中的宽度百分比和高度百分比
--endWidthPercent, endHeightPercent：终点在格子中的宽度百分比和高度百分比
function XRpgMakerGameConfigs.GetHintLineDirection(startRow, startCol, endRow, endCol, startWidthPercent, startHeightPercent, endWidthPercent, endHeightPercent)
    local horizontalDistance = startRow - endRow      --垂直方向距离
    local verticalDistance = startCol - endCol        --水平方向距离
    local widthPercentDistance = (startWidthPercent and endWidthPercent) and startWidthPercent - endWidthPercent or 0
    local heightPercentDistance = (startHeightPercent and endHeightPercent) and startHeightPercent - endHeightPercent or 0
    if horizontalDistance ~= 0 and verticalDistance ~= 0 then
        return
    end

    if horizontalDistance ~= 0 then
        return horizontalDistance > 0 and XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown or XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp
    end

    if verticalDistance ~= 0 then
        return verticalDistance > 0 and XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft or XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight
    end

    if widthPercentDistance ~= 0 then
        return widthPercentDistance > 0 and XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveLeft or XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveRight
    end

    if heightPercentDistance ~= 0 then
        return heightPercentDistance > 0 and XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveDown or XRpgMakerGameConfigs.RpgMakerGameMoveDirection.MoveUp
    end
end
-----------------RpgMakerGameHintLine 通关提示线路 end----------------------

-----------------RpgMakerGameShadow 影子 begin--------------------
local GetRpgMakerGameShadowConfig = function(id)
    local config = RpgMakerGameShadowConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.RpgMakerGameHintLineConfig", "RpgMakerGameShadowConfigs", TABLE_SHADOW_PATH, "Id", id)
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameMapIdToShadowIdList(mapId)
    return RpgMakerGameMapIdToShadowIdList[mapId] or {}
end

function XRpgMakerGameConfigs.GetRpgMakerGameShadowX(id)
    local config = GetRpgMakerGameShadowConfig(id)
    return config.X
end

function XRpgMakerGameConfigs.GetRpgMakerGameShadowY(id)
    local config = GetRpgMakerGameShadowConfig(id)
    return config.Y
end

function XRpgMakerGameConfigs.GetRpgMakerGameShadowDirection(id)
    local config = GetRpgMakerGameShadowConfig(id)
    return config.Direction
end

function XRpgMakerGameConfigs.GetRpgMakerGameShadowId(mapId, x, y)
    local shadowIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToShadowIdList(mapId)
    local shadowX
    local shadowY
    for _, shadowId in ipairs(shadowIdList) do
        shadowX = XRpgMakerGameConfigs.GetRpgMakerGameShadowX(shadowId)
        shadowY = XRpgMakerGameConfigs.GetRpgMakerGameShadowY(shadowId)
        if shadowX == x and shadowY == y then
            return shadowId
        end
    end
end
-----------------RpgMakerGameShadow 影子 end----------------------

-----------------RpgMakerGameTrap 陷阱 begin--------------------
local GetRpgMakerGameTrapConfig = function(id)
    local config = RpgMakerGameTrapConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.RpgMakerGameHintLineConfig", "RpgMakerGameTrapConfigs", TABLE_TRAP_PATH, "Id", id)
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameMapIdToTrapIdList(mapId)
    return RpgMakerGameMapIdToTrapIdList[mapId] or {}
end

function XRpgMakerGameConfigs.GetRpgMakerGameTrapX(id)
    local config = GetRpgMakerGameTrapConfig(id)
    return config.X
end

function XRpgMakerGameConfigs.GetRpgMakerGameTrapY(id)
    local config = GetRpgMakerGameTrapConfig(id)
    return config.Y
end

function XRpgMakerGameConfigs.GetRpgMakerGameTrapId(mapId, x, y)
    local trapIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToTrapIdList(mapId)
    local trapX
    local trapY
    for _, trapId in ipairs(trapIdList) do
        trapX = XRpgMakerGameConfigs.GetRpgMakerGameTrapX(trapId)
        trapY = XRpgMakerGameConfigs.GetRpgMakerGameTrapY(trapId)
        if trapX == x and trapY == y then
            return trapId
        end
    end
end
-----------------RpgMakerGameTrap 陷阱 end----------------------

-----------------RpgMakerGameElectricFence 电网 begin--------------------
local GetRpgMakerGameElectricFenceConfig = function(id)
    local config = RpgMakerGameElectricFenceConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.RpgMakerGameElectricFenceConfig", "RpgMakerGameElectricFenceConfigs", TABLE_ELECTRIC_FENCE_PATH, "Id", id)
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameMapIdToElectricFenceIdList(mapId)
    return RpgMakerGameMapIdToElectricFenceIdList[mapId] or {}
end

function XRpgMakerGameConfigs.GetRpgMakerGameElectricFenceX(id)
    local config = GetRpgMakerGameElectricFenceConfig(id)
    return config.X
end

function XRpgMakerGameConfigs.GetRpgMakerGameElectricFenceY(id)
    local config = GetRpgMakerGameElectricFenceConfig(id)
    return config.Y
end

function XRpgMakerGameConfigs.GetRpgMakerGameElectricDirection(id)
    local config = GetRpgMakerGameElectricFenceConfig(id)
    return config.Direction
end

function XRpgMakerGameConfigs.GetRpgMakerGameSameXYElectricFenceIdList(mapId, x, y)
    local electricFenceIdList = XRpgMakerGameConfigs.GetRpgMakerGameMapIdToElectricFenceIdList(mapId)
    local gapX
    local gapY
    local sameXYElectricFenceIdList = {}
    for _, gapId in ipairs(electricFenceIdList) do
        gapX = XRpgMakerGameConfigs.GetRpgMakerGameElectricFenceX(gapId)
        gapY = XRpgMakerGameConfigs.GetRpgMakerGameElectricFenceY(gapId)
        if gapX == x and gapY == y then
            tableInsert(sameXYElectricFenceIdList, gapId)
        end
    end
    return sameXYElectricFenceIdList
end
-----------------RpgMakerGameElectricFence 电网 end----------------------

-----------------RpgMakerGameDeathTitle 不同类型的死亡弹窗标题 begin--------------------
local GetRpgMakerGameDeathTitleConfig = function(type)
    local config = RpgMakerGameDeathTitleConfigs[type]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.RpgMakerGameDeathTitleConfig", "RpgMakerGameDeathTitleConfigs", TABLE_DEATH_TITAL_PATH, "Type", type)
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameDeathTitle(type)
    local config = GetRpgMakerGameDeathTitleConfig(type)
    return config and config.Name or ""
end
-----------------RpgMakerGameDeathTitle 不同类型的死亡弹窗标题 end----------------------

-----------------RpgMakerGameChapterGroup 第X期章节组 begin-----------------
local GetRpgMakerGameChapterGroupConfig = function(id)
    local config = RpgMakerGameChapterGroupConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.RpgMakerGameChapterGroupConfig", "RpgMakerGameChapterGroupConfigs", TABLE_CHAPTER_GROUP_PATH, "Id", id)
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameChapterGroupIdList()
    InitChapterGroup()
    return RpgMakerGameChapterGroupIdList
end

function XRpgMakerGameConfigs.GetRpgMakerGameChapterIdList(groupId)
    InitChapterGroup()
    return RpgMakerGameChapterGroupToChapterIdList[groupId] or {}
end

function XRpgMakerGameConfigs.GetDefaultChapterGroupId()
    InitChapterGroup()
    return _DefaultChapterGroupId
end

function XRpgMakerGameConfigs.GetChapterGroupName(id)
    local config = GetRpgMakerGameChapterGroupConfig(id)
    return config.Name
end

function XRpgMakerGameConfigs.GetChapterGroupOpenTimeId(id)
    local config = GetRpgMakerGameChapterGroupConfig(id)
    return config.OpenTimeId
end

function XRpgMakerGameConfigs.GetChapterGroupActivityIcon(id)
    local config = GetRpgMakerGameChapterGroupConfig(id)
    return config.ActivityIcon
end

function XRpgMakerGameConfigs.GetChapterGroupBg(id)
    local config = GetRpgMakerGameChapterGroupConfig(id)
    return config.Bg
end

function XRpgMakerGameConfigs.GetChapterGroupIsShowTask(id)
    local config = GetRpgMakerGameChapterGroupConfig(id)
    return config.IsShowTask
end

function XRpgMakerGameConfigs.GetChapterGroupIsFirstShow(id)
    local config = GetRpgMakerGameChapterGroupConfig(id)
    return config.IsFirstShow
end

function XRpgMakerGameConfigs.GetChapterGroupTitlePrefab(id)
    local config = GetRpgMakerGameChapterGroupConfig(id)
    return config.TitlePrefab
end

function XRpgMakerGameConfigs.GetChapterGroupGroundPrefab(id)
    local config = GetRpgMakerGameChapterGroupConfig(id)
    return config.GroundPrefab
end

function XRpgMakerGameConfigs.GetChapterGroupBlockPrefab(id)
    local config = GetRpgMakerGameChapterGroupConfig(id)
    return config.BlockPrefab
end

function XRpgMakerGameConfigs.GetChapterGroupHelpKey(id)
    local config = GetRpgMakerGameChapterGroupConfig(id)
    return config.HelpKey
end
-----------------RpgMakerGameChapterGroup 第X期章节组 end-------------------

-----------------RpgMakerGameEntity begin-----------------
local GetRpgMakerGameEntityConfig = function(id)
    local config = RpgMakerGameEntityConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.RpgMakerGameEntityConfig", "RpgMakerGameEntityConfigs", TABLE_ENTITY_PATH, "Id", id)
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetEntityTypeListByDic(mapId, x, y)
    InitMapIdToEntityIdList()
    return EntityTypeDic[mapId] and EntityTypeDic[mapId][x] and EntityTypeDic[mapId][x][y]
end

function XRpgMakerGameConfigs.GetMapIdToEntityIdList(mapId)
    InitMapIdToEntityIdList()
    return MapIdToEntityIdList[mapId] or {}
end

function XRpgMakerGameConfigs.GetEntityIdListByDic(mapId, x, y)
    InitMapIdToEntityIdList()
    return (EntityIdDic[mapId] and EntityIdDic[mapId][x] and EntityIdDic[mapId][x][y]) or {}
end

function XRpgMakerGameConfigs.IsSameEntity(mapId, x, y, type)
    local entityTypeList = XRpgMakerGameConfigs.GetEntityTypeListByDic(mapId, x, y)
    if XTool.IsTableEmpty(entityTypeList) then
        return false
    end
    for _, entityType in ipairs(entityTypeList) do
        if entityType == type then
            return true
        end
    end
    return false
end

function XRpgMakerGameConfigs.GetEntityMapId(id)
    local config = GetRpgMakerGameEntityConfig(id)
    return config.MapId
end

function XRpgMakerGameConfigs.GetEntityType(id)
    local config = GetRpgMakerGameEntityConfig(id)
    return config.Type
end

function XRpgMakerGameConfigs.GetEntityX(id)
    local config = GetRpgMakerGameEntityConfig(id)
    return config.X
end

function XRpgMakerGameConfigs.GetEntityY(id)
    local config = GetRpgMakerGameEntityConfig(id)
    return config.Y
end

function XRpgMakerGameConfigs.GetEntityBrokenType(id)
    local config = GetRpgMakerGameEntityConfig(id)
    return config.BrokenType
end

function XRpgMakerGameConfigs.GetRpgMakerGameEntityTypeListByXY(mapId, x, y)
    local entityIdList = XRpgMakerGameConfigs.GetMapIdToEntityIdList(mapId)
    local idList = {}
    local entityX
    local entityY
    for _, entityId in ipairs(entityIdList) do
        entityX = XRpgMakerGameConfigs.GetEntityX(entityId)
        entityY = XRpgMakerGameConfigs.GetEntityY(entityId)
        if entityX == x and entityY == y then
            tableInsert(idList, XRpgMakerGameConfigs.GetEntityType(entityId))
            tableSort(idList)
        end
    end
    return idList or {}
end

function XRpgMakerGameConfigs.IsRpgMakerGameHaveEntity(mapId)
    -- 地图实体：1 水面、2 冰面、3 草圃、4 钢板
    local isHaveEntity1, isHaveEntity2, isHaveEntity3, isHaveEntity4
    local entityIdList = XRpgMakerGameConfigs.GetMapIdToEntityIdList(mapId)
    local typeCfg
    for _, entityId in ipairs(entityIdList) do
        typeCfg = XRpgMakerGameConfigs.GetEntityType(entityId)
        if typeCfg == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Water then
            isHaveEntity1 = true
        elseif typeCfg == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Ice then
            isHaveEntity2 = true
        elseif typeCfg == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Grass then
            isHaveEntity3 = true
        elseif typeCfg == XRpgMakerGameConfigs.XRpgMakerGameEntityType.Steel then
            isHaveEntity4 = true
        end

        if isHaveEntity1 and isHaveEntity2 and isHaveEntity3 and isHaveEntity4 then
            break
        end
    end
    return isHaveEntity1, isHaveEntity2, isHaveEntity3, isHaveEntity4
end
-----------------RpgMakerGameEntity end-------------------

-----------------RpgMakerGameTransferPoint 传送点 begin-----------------
local GetRpgMakerGameTransferPointConfig = function(id)
    local config = RpgMakerGameTransferPointConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.RpgMakerGameTransferPointConfig", "RpgMakerGameTransferPointConfigs", TABLE_TRANSFER_POINT_PATH, "Id", id)
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetMapIdToTransferPointIdList(mapId)
    InitMapIdToTransferPointIdList()
    return MapIdToTransferPointIdList[mapId] or {}
end

function XRpgMakerGameConfigs.GetTransferPointMapId(id)
    local config = GetRpgMakerGameTransferPointConfig(id)
    return config.MapId
end

function XRpgMakerGameConfigs.GetTransferPointX(id)
    local config = GetRpgMakerGameTransferPointConfig(id)
    return config.X
end

function XRpgMakerGameConfigs.GetTransferPointY(id)
    local config = GetRpgMakerGameTransferPointConfig(id)
    return config.Y
end

function XRpgMakerGameConfigs.GetTransferPointColor(id)
    local config = GetRpgMakerGameTransferPointConfig(id)
    return config.Color
end

function XRpgMakerGameConfigs.GetRpgMakerGameTransferPointId(mapId, x, y)
    local transferPointIdList = XRpgMakerGameConfigs.GetMapIdToTransferPointIdList(mapId)
    local transferPointX
    local transferPointY
    for _, transferPointId in ipairs(transferPointIdList) do
        transferPointX = XRpgMakerGameConfigs.GetTransferPointX(transferPointId)
        transferPointY = XRpgMakerGameConfigs.GetTransferPointY(transferPointId)
        if transferPointX == x and transferPointY == y then
            return transferPointId
        end
    end
end

function XRpgMakerGameConfigs.IsRpgMakerGameHaveTransferPoint(mapId)
    -- 地图实体：1 水面、2 冰面、3 草圃、4 钢板
    local isHaveTransferPoint1, isHaveTransferPoint2, isHaveTransferPoint3
    local entityIdList = XRpgMakerGameConfigs.GetMapIdToTransferPointIdList(mapId)
    local colorCfg
    for _, transferId in ipairs(entityIdList) do
        colorCfg = XRpgMakerGameConfigs.GetTransferPointColor(transferId)
        if colorCfg == XRpgMakerGameConfigs.XRpgMakerTransferPointColor.Green then
            isHaveTransferPoint1 = true
        elseif colorCfg == XRpgMakerGameConfigs.XRpgMakerTransferPointColor.Yellow then
            isHaveTransferPoint2 = true
        elseif colorCfg == XRpgMakerGameConfigs.XRpgMakerTransferPointColor.Purple then
            isHaveTransferPoint3 = true
        end

        if isHaveTransferPoint1 and isHaveTransferPoint2 and isHaveTransferPoint3 then
            break
        end
    end
    return isHaveTransferPoint1, isHaveTransferPoint2, isHaveTransferPoint3
end
-----------------RpgMakerGameTransferPoint 传送点 end-------------------