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
local TABLE_HINT_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGameHint.tab"
local TABLE_HINT_ICON_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGameHintIcon.tab"
local TABLE_RANDOM_DIALOG_BOX_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGameRandomDialogBox.tab"
local TABLE_HINT_DIALOG_BOX_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGameHintDialogBox.tab"
local TABLE_MODEL_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGameModel.tab"
local TABLE_ANIMATION_PATH = "Client/MiniActivity/RpgMakerGame/RpgMakerGameAnimation.tab"
local RpgMakerGameChapterConfigs = {}
local RpgMakerGameStageConfigs = {}
local RpgMakerGameStarConditionConfigs = {}
local RpgMakerGameRoleConfigs = {}
local RpgMakerGameMapConfigs = {}
local RpgMakerGameStartPointConfigs = {}
local RpgMakerGameEndPointConfigs = {}
local RpgMakerGameBlockConfigs = {}
local RpgMakerGameGapConfigs = {}
local RpgMakerGameMonsterConfigs = {}
local RpgMakerGameTriggerConfigs = {}
local RpgMakerGameHintConfigs = {}
local RpgMakerGameHintIconConfigs = {}
local RpgMakerGameActivityConfigs = {}
local RpgMakerGameRandomDialogBoxConfigs = {}
local RpgMakerGameHintDialogBoxConfigs = {}
local RpgMakerGameModelConfigs = {}
local RpgMakerGameAnimationConfigs = {}

local RpgMakerGameChapterIdList = {}
local RpgMakerGameChapterIdToStageIdListDic = {}
local RpgMakerGameStageIdToStarConditionIdListDic = {}
local RpgMakerGameRoleIdList = {}
local RpgMakerGameStageIdList = {}
local RpgMakerGameMapIdToBlockIdList = {}
local RpgMakerGameMapIdToGapIdList = {}
local RpgMakerGameMapIdToMonsterIdList = {}
local RpgMakerGameMapIdToTriggerIdList = {}
local RpgMakerGameMapIdToHintIdList = {}
local RpgMakerGameRandomDialogBoxIdList = {}

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
    Normal = 1,
    BOSS = 2,
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
    Trigger1 = 1,   --本身是不能阻挡，可以触发类型2的机关状态转变
    Trigger2 = 2,   --由类型1触发
    Trigger3 = 3,   --玩家通过后，会从通过状态转变为阻挡状态
}

--一个关卡最多星星数
XRpgMakerGameConfigs.MaxStarCount = 3

--延迟被攻击回调的时间
XRpgMakerGameConfigs.BeAtkEffectDelayCallbackTime = CS.XGame.ClientConfig:GetInt("RpgMakerGamePlayBeAtkEffectDelayCallbackTime")

local InitRpgMakerGameChapterIdList = function()
    for id in pairs(RpgMakerGameChapterConfigs) do
        tableInsert(RpgMakerGameChapterIdList, id)
    end

    tableSort(RpgMakerGameChapterIdList, function(a, b)
        return a < b
    end)
end

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

local InitRpgMakerGameMapIdToHintIdList = function()
    local mapId
    for _, v in pairs(RpgMakerGameHintConfigs) do
        mapId = v.MapId
        if not RpgMakerGameMapIdToHintIdList[mapId] then
            RpgMakerGameMapIdToHintIdList[mapId] = {}
        end
        tableInsert(RpgMakerGameMapIdToHintIdList[mapId], v.Id)
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

function XRpgMakerGameConfigs.Init()
    RpgMakerGameChapterConfigs = XTableManager.ReadByIntKey(TABLE_CHAPTER_PATH, XTable.XTableRpgMakerGameChapter, "Id")
    RpgMakerGameStageConfigs = XTableManager.ReadByIntKey(TABLE_STAGE_PATH, XTable.XTableRpgMakerGameStage, "Id")
    RpgMakerGameStarConditionConfigs = XTableManager.ReadByIntKey(TABLE_STAR_CONDITION_PATH, XTable.XTableRpgMakerGameStarCondition, "Id")
    RpgMakerGameRoleConfigs = XTableManager.ReadByIntKey(TABLE_ROLE_PATH, XTable.XTableRpgMakerGameRole, "Id")
    RpgMakerGameMapConfigs = XTableManager.ReadByIntKey(TABLE_MAP_PATH, XTable.XTableRpgMakerGameMap, "Id")
    RpgMakerGameStartPointConfigs = XTableManager.ReadByIntKey(TABLE_START_POINT_PATH, XTable.XTableRpgMakerGameStartPoint, "Id")
    RpgMakerGameEndPointConfigs = XTableManager.ReadByIntKey(TABLE_END_POINT_PATH, XTable.XTableRpgMakerGameEndPoint, "Id")
    RpgMakerGameBlockConfigs = XTableManager.ReadByIntKey(TABLE_BLOCK_PATH, XTable.XTableRpgMakerGameBlock, "Id")
    RpgMakerGameGapConfigs = XTableManager.ReadByIntKey(TABLE_GAP_PATH, XTable.XTableRpgMakerGameGap, "Id")
    RpgMakerGameMonsterConfigs = XTableManager.ReadByIntKey(TABLE_MONSTER_PATH, XTable.XTableRpgMakerGameMonster, "Id")
    RpgMakerGameTriggerConfigs = XTableManager.ReadByIntKey(TABLE_TRIGGER_PATH, XTable.XTableRpgMakerGameTrigger, "Id")
    RpgMakerGameHintConfigs = XTableManager.ReadByIntKey(TABLE_HINT_PATH, XTable.XTableRpgMakerGameHint, "Id")
    RpgMakerGameHintIconConfigs = XTableManager.ReadByStringKey(TABLE_HINT_ICON_PATH, XTable.XTableRpgMakerGameHintIcon, "Key")
    RpgMakerGameActivityConfigs = XTableManager.ReadByIntKey(TABLE_ACTIVITY_PATH, XTable.XTableRpgMakerGameActivity, "Id")
    RpgMakerGameRandomDialogBoxConfigs = XTableManager.ReadByIntKey(TABLE_RANDOM_DIALOG_BOX_PATH, XTable.XTableRpgMakerGameRandomDialogBox, "Id")
    RpgMakerGameHintDialogBoxConfigs = XTableManager.ReadByIntKey(TABLE_HINT_DIALOG_BOX_PATH, XTable.XTableRpgMakerGameHintDialogBox, "StageId")
    RpgMakerGameModelConfigs = XTableManager.ReadByStringKey(TABLE_MODEL_PATH, XTable.XTableRpgMakerGameModel, "Key")
    RpgMakerGameAnimationConfigs = XTableManager.ReadByStringKey(TABLE_ANIMATION_PATH, XTable.XTableRpgMakerGameAnimation, "ModelName")

    InitRpgMakerGameChapterIdList()
    InitRpgMakerGameChapterIdToStageIdListDic()
    InitRpgMakerGameStageIdToStarConditionIdListDic()
    InitRpgMakerGameRoleIdList()
    InitRpgMakerGameStageIdList()
    InitRpgMakerGameMapIdToBlockIdList()
    InitRpgMakerGameMapIdToGapIdList()
    InitRpgMakerGameMapIdToMonsterIdList()
    InitRpgMakerGameMapIdToTriggerIdList()
    InitRpgMakerGameMapIdToHintIdList()
    InitActivityConfig()
    InitRpgMakerGameRandomDialogBoxIdList()
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

function XRpgMakerGameConfigs.GetRpgMakerGameChapterIdList()
    return RpgMakerGameChapterIdList
end

function XRpgMakerGameConfigs.GetRpgMakerGameChapterId(index)
    return RpgMakerGameChapterIdList[index]
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
    return RpgMakerGameChapterIdToStageIdListDic[chapterId]
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
    return RpgMakerGameStageIdToStarConditionIdListDic[stageId]
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
-----------------RpgMakerGameRole 角色列表 end--------------------

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
    local typeCfg
    for _, monsterId in ipairs(monsterIdList) do
        typeCfg = XRpgMakerGameConfigs.GetRpgMakerGameMonsterType(monsterId)
        if typeCfg == monsterType then
            return true
        end
    end
    return false
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
    local isHaveType1Trigger, isHaveType2Trigger, isHaveType3Trigger
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
        end

        if isHaveType1Trigger and isHaveType2Trigger and isHaveType3Trigger then
            break
        end
    end
    return isHaveType1Trigger, isHaveType2Trigger, isHaveType3Trigger
end
-----------------RpgMakerGameTrigger 机关 end-------------------------

-----------------RpgMakerGameHint 通关提示 begin-----------------------
local GetRpgMakerGameHintConfig = function(id)
    local config = RpgMakerGameHintConfigs[id]
    if not config then
        XLog.ErrorTableDataNotFound("XRpgMakerGameConfigs.GetRpgMakerGameHintConfigs", "RpgMakerGameHintConfigs", TABLE_HINT_PATH, "Id", tostring(id))
        return
    end
    return config
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintRow(id)
    local config = GetRpgMakerGameHintConfig(id)
    return config.Row
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintColList(id)
    local config = GetRpgMakerGameHintConfig(id)
    return config.Col
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintIdList(mapId)
    return RpgMakerGameMapIdToHintIdList[mapId]
end

function XRpgMakerGameConfigs.IsRpgMakerGameHintShowMoveLine(mapId, row, colIndex)
    local hintIdList = XRpgMakerGameConfigs.GetRpgMakerGameHintIdList(mapId)
    local rowCfg
    local colList
    for _, hintId in ipairs(hintIdList or {}) do
        rowCfg = XRpgMakerGameConfigs.GetRpgMakerGameHintRow(hintId)
        colList = XRpgMakerGameConfigs.GetRpgMakerGameHintColList(hintId)
        if rowCfg == row then
            return colList and XTool.IsNumberValid(colList[colIndex])   --不为0则显示移动路线图标
        end
    end
    return false
end
-----------------RpgMakerGameHint 通关提示 end-------------------------

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
function XRpgMakerGameConfigs.GetRpgMakerGameHintIconKeyListByMapId(mapId)
    local hintIconKeyList = {}
    if not XTool.IsNumberValid(mapId) then
        return hintIconKeyList
    end

    local isHaveBlock = XRpgMakerGameConfigs.IsRpgMakerGameHaveBlock(mapId)
    local isHaveMonster = XRpgMakerGameConfigs.IsRpgMakerGameHaveMonster(mapId, XRpgMakerGameConfigs.XRpgMakerGameMonsterType.Normal)
    local isHaveBoss = XRpgMakerGameConfigs.IsRpgMakerGameHaveMonster(mapId, XRpgMakerGameConfigs.XRpgMakerGameMonsterType.Boss)
    local isHaveType1Trigger, isHaveType2Trigger, isHaveType3Trigger = XRpgMakerGameConfigs.IsRpgMakerGameHaveTrigger(mapId)
    local isHaveGap = not XTool.IsTableEmpty(XRpgMakerGameConfigs.GetRpgMakerGameMapIdToGapIdList(mapId))

    local isInsert = true
    for k in pairs(RpgMakerGameHintIconConfigs) do
        if k == "BlockIcon" then
            isInsert = isHaveBlock
        elseif k == "NormalMonsterIcon" then
            isInsert = isHaveMonster
        elseif k == "BossIcon" then
            isInsert = isHaveBoss
        elseif k == "TriggerIcon1" then
            isInsert = isHaveType1Trigger
        elseif k == "TriggerIcon2" then
            isInsert = isHaveType2Trigger
        elseif k == "TriggerIcon3" then
            isInsert = isHaveType3Trigger
        elseif k == "GapIcon" then
            isInsert = isHaveGap
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

function XRpgMakerGameConfigs.GetRpgMakerGameHintIconName(key)
    local config = GetRpgMakerGameHintIconConfig(key)
    return config.Name
end

function XRpgMakerGameConfigs.GetNormalMonsterIcon(monsterType)
    if XRpgMakerGameConfigs.XRpgMakerGameMonsterType.BOSS == monsterType then
        return XRpgMakerGameConfigs.GetRpgMakerGameHintIcon("BossIcon")
    end
    return XRpgMakerGameConfigs.GetRpgMakerGameHintIcon("NormalMonsterIcon")
end

function XRpgMakerGameConfigs.GetTriggerIcon(triggerType)
    if triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger1 then
        return XRpgMakerGameConfigs.GetRpgMakerGameHintIcon("TriggerIcon1")
    end

    if triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger2 then
        return XRpgMakerGameConfigs.GetRpgMakerGameHintIcon("TriggerIcon2")
    end

    return XRpgMakerGameConfigs.GetRpgMakerGameHintIcon("TriggerIcon3")
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

function XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxText(id)
    local config = GetRpgMakerGameHintDialogBoxConfigs(id)
    return config.Text or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameHintDialogBoxBackCount(id)
    local config = GetRpgMakerGameHintDialogBoxConfigs(id)
    return config.BackCount
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

function XRpgMakerGameConfigs.GetRpgMakerGameTriggerPath(triggerType)
    if triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger1 then
        return XRpgMakerGameConfigs.GetRpgMakerGameModelPath("TriggerType1")
    end

    if triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger2 then
        return XRpgMakerGameConfigs.GetRpgMakerGameModelPath("TriggerType2")
    end

    if triggerType == XRpgMakerGameConfigs.XRpgMakerGameTriggerType.Trigger3 then
        return XRpgMakerGameConfigs.GetRpgMakerGameModelPath("TriggerType3")
    end
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

function XRpgMakerGameConfigs.GetRpgMakerGameBeAtkEffectPath(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.BeAtkEffectPath or ""
end

function XRpgMakerGameConfigs.GetRpgMakerGameEffectRoot(modelName)
    local config = GetRpgMakerGameAnimationConfig(modelName)
    return config.EffectRoot or ""
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
-----------------RpgMakerGameAnimation 动画相关 end-----------------------