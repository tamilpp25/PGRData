local tonumber = tonumber
local tableInsert = table.insert
local tableSort = table.sort
local ipairs = ipairs
local pairs = pairs
local CSXTextManagerGetText = CS.XTextManager.GetText

XAreaWarConfigs = XAreaWarConfigs or {}

-----------------活动相关 begin-----------------
local TABLE_ACITIVTY_PATH = "Share/AreaWar/AreaWarActivity.tab"

local ActivityConfig = {}

local function InitActivityConfig()
    ActivityConfig = XTableManager.ReadByIntKey(TABLE_ACITIVTY_PATH, XTable.XTableAreaWarActivity, "Id")
end

local function GetActivityConfig(activityId)
    local config = ActivityConfig[activityId]
    if not config then
        XLog.Error(
            "XAreaWarConfigs GetActivityConfig error:配置不存在, activityId:" ..
                activityId .. ",path: " .. TABLE_ACITIVTY_PATH
        )
        return
    end
    return config
end

local function GetActivityTimeId(activityId)
    local config = GetActivityConfig(activityId)
    return config.TimeId
end

function XAreaWarConfigs.GetDefaultActivityId()
    local defaultActivityId = 0
    for activityId, config in pairs(ActivityConfig) do
        defaultActivityId = activityId
        if XTool.IsNumberValid(config.TimeId) and XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
            break
        end
    end
    return defaultActivityId
end

function XAreaWarConfigs.GetActivityStartTime(activityId)
    local config = GetActivityConfig(activityId)
    return XFunctionManager.GetStartTimeByTimeId(GetActivityTimeId(activityId))
end

function XAreaWarConfigs.GetActivityEndTime(activityId)
    return XFunctionManager.GetEndTimeByTimeId(GetActivityTimeId(activityId))
end

function XAreaWarConfigs.GetActivityTimeLimitTaskIds(activityId)
    local taskIds = {}
    local config = GetActivityConfig(activityId)
    for _, taskId in ipairs(config.TimeLimitTaskId) do
        if XTool.IsNumberValid(taskId) then
            tableInsert(taskIds, taskId)
        end
    end
    return taskIds
end

function XAreaWarConfigs.GetActivityShopIds(activityId)
    local shopIds = {}
    local config = GetActivityConfig(activityId)
    for _, shopId in ipairs(config.ShopId) do
        if XTool.IsNumberValid(shopId) then
            tableInsert(shopIds, shopId)
        end
    end
    return shopIds
end

function XAreaWarConfigs.GetActivityTimeLimitTaskId(activityId, index)
    local config = GetActivityConfig(activityId)
    return config.TimeLimitTaskId[index] or 0
end

function XAreaWarConfigs.GetActivityBanner(activityId)
    local config = GetActivityConfig(activityId)
    return config.ActivityBanner or ""
end

function XAreaWarConfigs.GetActivityName(activityId)
    local config = GetActivityConfig(activityId)
    return config.Name or ""
end
-----------------活动相关 end-------------------



--region   ------------------区块 start-------------------

-----------------区块相关 begin-------------------
local TABLE_BLOCK_PATH = "Share/AreaWar/AreaWarBlock.tab"
local TABLE_BLOCK_SHOW_TYPE_PATH = "Client/AreaWar/AreaWarBlockShowType.tab"
local TABLE_WORLD_BOSS_UI_PATH = "Client/AreaWar/AreaWarWorldBossUi.tab"

---@type table<number, XTable.XTableAreaWarBlock>
local BlockConfig = {}
local BlockShowTypeConfig = {}
local WorldBossUiConfig = {}


--区块类型
XAreaWarConfigs.BlockType = {
    Init = 1, --初始区块
    Normal = 2, --常规区块
    WorldBoss = 3, --世界BOSS区块
    Mystery = 4 --神秘区块
}

--区块展示类型
XAreaWarConfigs.BlockShowType = {
    Init = 1, --初始区块
    NormalExplore = 2, --常规区块（探索）
    WorldBoss = 3, --世界Boss区块
    Mystery = 4, --神秘区块
    NormalBox = 5, --常规区块（宝箱）
    NormalCharacter = 6, --常规区块（角色特攻）
    NormalPurify = 7, --常规区块（净化加成）
    NormalBeacon = 8, --常规区块（灯塔）
    NormalBoss = 9 --常规区块（Boss）
}

--世界BossUI类型
XAreaWarConfigs.WorldBossUiType = {
    Normal = 1,
    Special = 2
}

local function InitBlockConfig()
    BlockConfig = XTableManager.ReadByIntKey(TABLE_BLOCK_PATH, XTable.XTableAreaWarBlock, "Id")
    BlockShowTypeConfig =
        XTableManager.ReadByIntKey(TABLE_BLOCK_SHOW_TYPE_PATH, XTable.XTableAreaWarBlockShowType, "Id")
    WorldBossUiConfig = XTableManager.ReadByIntKey(TABLE_WORLD_BOSS_UI_PATH, XTable.XTableAreaWarWorldBossUi, "Id")

    
end

local function GetBlockConfig(blockId)
    local config = BlockConfig[blockId]
    if not config then
        XLog.Error("XAreaWarConfigs GetBlockConfig error:配置不存在, blockId:" .. blockId .. ",path: " .. TABLE_BLOCK_PATH)
        return
    end
    return config
end

local function GetBlockShowTypeConfig(showType)
    local config = BlockShowTypeConfig[showType]
    if not config then
        XLog.Error(
            "XAreaWarConfigs GetBlockShowTypeConfig error:配置不存在, showType:" ..
                showType .. ",path: " .. TABLE_BLOCK_SHOW_TYPE_PATH
        )
        return
    end
    return config
end

local function GetWorldBossUiConfig(uiType)
    local config = WorldBossUiConfig[uiType]
    if not config then
        XLog.Error(
            "XAreaWarConfigs GetWorldBossUiConfig error:配置不存在, uiType:" ..
                uiType .. ",path: " .. TABLE_WORLD_BOSS_UI_PATH
        )
        return
    end
    return config
end

function XAreaWarConfigs.GetAllBlockIds()
    local blockIds = {}
    for blockId in pairs(BlockConfig) do
        if XTool.IsNumberValid(blockId) then
            tableInsert(blockIds, blockId)
        end
    end
    return blockIds
end

function XAreaWarConfigs.GetBlockIdByStageId(stageId)
    for blockId, config in pairs(BlockConfig) do
        if config.StageId == stageId then
            return blockId
        end
    end
    return 0
end

function XAreaWarConfigs.GetAllBlockStageIds()
    local stageIds = {}
    for _, config in pairs(BlockConfig) do
        if XTool.IsNumberValid(config.StageId) then
            tableInsert(stageIds, config.StageId)
        end
    end
    return stageIds
end

function XAreaWarConfigs.GetBlockRequirePurification(blockId)
    local config = GetBlockConfig(blockId)
    return config.CleanNeed
end

--获取前置区块Ids可选列表
function XAreaWarConfigs.GetBlockPreBlockIdsAlternativeList(blockId)
    local alternativeList = {}
    local config = GetBlockConfig(blockId)
    for _, preBlockIdStr in pairs(config.PreBlockId) do
        local result = string.Split(preBlockIdStr)
        for index, str in pairs(result) do
            result[index] = tonumber(str)
        end
        tableInsert(alternativeList, result)
    end
    return alternativeList
end

function XAreaWarConfigs.GetBlockName(blockId)
    local config = GetBlockConfig(blockId)
    return config.Name or ""
end

function XAreaWarConfigs.GetBlockNameEn(blockId)
    local config = GetBlockConfig(blockId)
    return config.NameEn or ""
end

--是否是初始区块
function XAreaWarConfigs.IsInitBlock(blockId)
    return XAreaWarConfigs.GetBlockType(blockId) == XAreaWarConfigs.BlockType.Init
end

--获取区块实际类型（服务端）
function XAreaWarConfigs.GetBlockType(blockId)
    local config = GetBlockConfig(blockId)
    return config.Type
end

--获取区块展示类型
function XAreaWarConfigs.GetBlockShowType(blockId)
    local config = GetBlockConfig(blockId)
    return config.ShowType
end

function XAreaWarConfigs.CheckBlockShowType(blockId, showType)
    return XAreaWarConfigs.GetBlockShowType(blockId) == showType
end

--活动开启后多少秒区块开启
function XAreaWarConfigs.GetBlockOpenSeconds(blockId)
    local chapterId = XAreaWarConfigs.GetBlockChapterId(blockId)
    local timeOfNow = XTime.GetServerNowTimestamp()
    local timeOfBgn = XFunctionManager.GetStartTimeByTimeId(XAreaWarConfigs.GetChapterTimeId(chapterId))
    return math.max(timeOfBgn - timeOfNow, 0)
end

--世界Boss在区块开放后一天几点开启/关闭
function XAreaWarConfigs.GetBlockWorldBossHour(blockId)
    local config = GetBlockConfig(blockId)
    return config.WorldBossStartHour, config.WorldBossEndHour
end

function XAreaWarConfigs.GetBlockShowRewardId(blockId)
    local config = GetBlockConfig(blockId)
    return config.ShowRewardId
end

--获取区块作战消耗活动体力
function XAreaWarConfigs.GetBlockActionPoint(blockId)
    local config = GetBlockConfig(blockId)
    return config.ActionPoint
end

--获取区块派遣消耗活动体力
function XAreaWarConfigs.GetBlockDetachActionPoint(blockId)
    local config = GetBlockConfig(blockId)
    return config.DetachActionPoint
end

function XAreaWarConfigs.GetBlockStageId(blockId)
    local config = GetBlockConfig(blockId)
    return config.StageId
end

function XAreaWarConfigs.GetBlockMovieId(blockId)
    local config = GetBlockConfig(blockId)
    return config.MovieId
end

--派遣基础奖励
function XAreaWarConfigs.GetBlockDetachBasicRewardItems(blockId)
    local rewardItems = {}
    local config = GetBlockConfig(blockId)
    local rewardId = config.DetachBasicRewardId
    if XTool.IsNumberValid(rewardId) then
        rewardItems = XRewardManager.GetRewardList(rewardId)
    end
    return XRewardManager.MergeAndSortRewardGoodsList(rewardItems)
end

--派遣鞭尸期奖励
function XAreaWarConfigs.GetBlockDetachWhippingPeriodRewardItems(blockId)
    local rewardItems = {}
    local config = GetBlockConfig(blockId)
    local rewardId = config.DetachRepeatChallengeRewardId
    if XTool.IsNumberValid(rewardId) then
        rewardItems = XRewardManager.GetRewardList(rewardId)
    end
    return XRewardManager.MergeAndSortRewardGoodsList(rewardItems)
end

function XAreaWarConfigs.GetBlockRepeatChallengeRewardItems(blockId)
    local rewardItems = {}
    local config = GetBlockConfig(blockId)
    local rewardId = config.RepeatChallengeRewardId
    if XTool.IsNumberValid(rewardId) then
        rewardItems = XRewardManager.GetRewardList(rewardId)
    end
    return XRewardManager.MergeAndSortRewardGoodsList(rewardItems)
end

--派遣满足条件额外奖励
function XAreaWarConfigs.GetBlockDetachDetachExtraRewardItems(blockId, index)
    local rewardItems = {}
    local config = GetBlockConfig(blockId)
    local rewardId = config.DetachExtraRewardId[index]
    if XTool.IsNumberValid(rewardId) then
        rewardItems = XRewardManager.GetRewardList(rewardId)
    end
    return XRewardManager.MergeAndSortRewardGoodsList(rewardItems)
end

function XAreaWarConfigs.GetPreBlockIds(blockId)
    local cfg = GetBlockConfig(blockId)
    return cfg and cfg.PreBlockId or {}
end

function XAreaWarConfigs.GetBlockChapterId(blockId)
    local cfg = GetBlockConfig(blockId)
    return cfg.ChapterId
end

function XAreaWarConfigs.GetAllBlockShowTypes()
    local showTypes = {}
    for showType in pairs(BlockShowTypeConfig) do
        tableInsert(showTypes, showType)
    end
    return showTypes
end

function XAreaWarConfigs.GetBlockShowTypeName(showType)
    local config = GetBlockShowTypeConfig(showType)
    return config.Name
end

--获取区块类型小图标
function XAreaWarConfigs.GetBlockShowTypeIconByBlockId(blockId)
    local showType = XAreaWarConfigs.GetBlockShowType(blockId)
    return XAreaWarConfigs.GetBlockShowTypeIcon(showType)
end

--获取区块类型关卡详情背景
function XAreaWarConfigs.GetBlockShowTypeStageBgByBlockId(blockId)
    local showType = XAreaWarConfigs.GetBlockShowType(blockId)
    return XAreaWarConfigs.GetBlockShowTypeStageBg(showType)
end

--获取区块类型格子预制体路径
function XAreaWarConfigs.GetBlockShowTypePrefab(blockId)
    local showType = XAreaWarConfigs.GetBlockShowType(blockId)
    local config = GetBlockShowTypeConfig(showType)
    return config.Prefab
end

--获取区块类型为常规区块（角色特攻）时对应的特攻角色小头像图标
function XAreaWarConfigs.GetRoleBlockIcon(blockId)
    local roleId = XAreaWarConfigs.GetUnlockSpecialRoleIdByBlockId(blockId)
    if not XTool.IsNumberValid(roleId) then
        XLog.Error("获取角色头像失败, 请检查配置: AreaWarBlock.tab与AreaWarSpecialRole.tab BlockId = " .. tostring(blockId))
        return
    end
    return XAreaWarConfigs.GetBlockSpecialRoleIcon(roleId)
end

function XAreaWarConfigs.GetWorldBossUiName(uiType)
    local config = GetWorldBossUiConfig(uiType)
    return config.UiName
end

function XAreaWarConfigs.GetBlockShowTypeIcon(showType)
    local config = GetBlockShowTypeConfig(showType)
    return config.Icon
end

function XAreaWarConfigs.GetBlockShowTypeStageBg(showType)
    local config = GetBlockShowTypeConfig(showType)
    return config.StageDetailBg
end

function XAreaWarConfigs.GetWorldBossUiTitleIcon(uiType)
    local config = GetWorldBossUiConfig(uiType)
    return config.TitleIcon
end

function XAreaWarConfigs.GetWorldBossUiHeadName(uiType)
    local config = GetWorldBossUiConfig(uiType)
    return config.HeadName
end

function XAreaWarConfigs.GetWorldBossUiHeadIcon(uiType)
    local config = GetWorldBossUiConfig(uiType)
    return config.HeadIcon
end

function XAreaWarConfigs.GetWorldBossRankTitle(uiType)
    local config = GetWorldBossUiConfig(uiType)
    return config.RankTitle
end

function XAreaWarConfigs.GetWorldBossUiModelIdDic(uiType)
    local modelIds = {}
    local config = GetWorldBossUiConfig(uiType)
    for index, modelId in pairs(config.ModelId) do
        if XTool.IsNumberValid(modelId) then
            modelIds[index] = modelId
        end
    end
    return modelIds
end

--获取世界Boss区块Ui名称
function XAreaWarConfigs.GetBlockWorldBossUiName(blockId)
    local chapterId = XAreaWarConfigs.GetBlockChapterId(blockId)
    local uiType = XAreaWarConfigs.GetChapterWorldBossUiType(chapterId)
    return XAreaWarConfigs.GetWorldBossUiName(uiType)
end

--获取世界Boss区块排行榜
function XAreaWarConfigs.GetBlockWorldBossRankTitle(blockId)
    local chapterId = XAreaWarConfigs.GetBlockChapterId(blockId)
    local uiType = XAreaWarConfigs.GetChapterWorldBossUiType(chapterId)
    return XAreaWarConfigs.GetWorldBossRankTitle(uiType)
end

--endregion------------------区块 finish------------------

--region   ------------------章节 start-------------------

local TABLE_CHAPTER_PATH = "Share/AreaWar/AreaWarChapter.tab"
local TABLE_PLATE_PATH = "Client/AreaWar/AreaWarPlate.tab"

---@type table<number, XTable.XTableAreaWarChapter>
local ChapterTemplate = {}
local ChapterIds
local ChapterId2BlockIds
local BlockId2PlateId

---@type table<number, XTableAreaWarPlate>
local PlateTemplate = {}

local function InitChapterConfig()
    ChapterTemplate = XTableManager.ReadByIntKey(TABLE_CHAPTER_PATH, XTable.XTableAreaWarChapter, "Id")
    PlateTemplate = XTableManager.ReadByIntKey(TABLE_PLATE_PATH, XTable.XTableAreaWarPlate, "Id")

    BlockId2PlateId = {}
    for id, template in pairs(PlateTemplate) do
        for _, blockId in pairs(template.BlockId) do
            BlockId2PlateId[blockId] = id
        end
    end
end

local function GetChapterTemplate(chapterId)
    local template = ChapterTemplate[chapterId]
    if not template then
        XLog.ErrorTableDataNotFound("XAreaWarConfigs->GetChapterTemplate",
                "AreaWarChapter", TABLE_CHAPTER_PATH, "Id", tostring(chapterId))
        return {}
    end

    return template
end

local function InitChapterId2BlockIds()
    ChapterId2BlockIds = {}
    for id, template in pairs(BlockConfig) do
        local chapterId = template.ChapterId
        if not ChapterId2BlockIds[chapterId] then
            ChapterId2BlockIds[chapterId] = {}
        end
        table.insert(ChapterId2BlockIds[chapterId], id)
    end

    local sortId = function(a, b) 
        return a < b
    end
    
    for id in pairs(ChapterId2BlockIds) do
        table.sort(ChapterId2BlockIds[id], sortId)
    end
end

local function InitChapterIds()
    ChapterIds = {}
    ChapterTemplate = ChapterTemplate or {}
    for id in pairs(ChapterTemplate) do
        tableInsert(ChapterIds, id)
    end
end

local function GetPlateTemplate(plateId) 
    local template = PlateTemplate[plateId]
    if not template then
        XLog.ErrorTableDataNotFound("XAreaWarConfigs->GetPlateTemplate",
                "AreaWarPlate", TABLE_PLATE_PATH, "Id", tostring(plateId))
        return {}
    end
    return template
end

--获取章节下的所有BlockId
function XAreaWarConfigs.GetBlockIdsByChapterId(chapterId)
    if not ChapterId2BlockIds then
        InitChapterId2BlockIds()
    end
    if not XTool.IsNumberValid(chapterId) then
        return {}
    end
    return ChapterId2BlockIds[chapterId] or {}
end

function XAreaWarConfigs.GetFirstBlockIdInChapter(chapterId)
    local blockIds = XAreaWarConfigs.GetBlockIdsByChapterId(chapterId)
    return blockIds and blockIds[1] or 0
end

function XAreaWarConfigs.GetChapterIds()
    if not ChapterIds then
        InitChapterIds()
    end
    return ChapterIds
end

function XAreaWarConfigs.GetChapterTimeId(chapterId)
    local template = GetChapterTemplate(chapterId)
    return template.TimeId or 0
end

function XAreaWarConfigs.CheckChapterInTime(chapterId, defaultOpen)
    local timeId = XAreaWarConfigs.GetChapterTimeId(chapterId)
    return XFunctionManager.CheckInTimeByTimeId(timeId, defaultOpen)
end

function XAreaWarConfigs.GetChapterName(chapterId)
    local template = GetChapterTemplate(chapterId)
    return template.ChapterName
end

function XAreaWarConfigs.GetChapterWorldBossUiType(chapterId)
    local template = GetChapterTemplate(chapterId)
    return template.WorldBossUiType
end

function XAreaWarConfigs.GetUnlockBlockIds(plateId)
    local template = GetPlateTemplate(plateId)
    return template.UnlockBlockId or {}
end

function XAreaWarConfigs.GetContainBlockIds(plateId)
    local template = GetPlateTemplate(plateId)
    return template.BlockId or {}
end

function XAreaWarConfigs.GetPlateIdByBlockId(blockId)
    return BlockId2PlateId[blockId]
end

--endregion------------------章节 finish------------------

-----------------派遣相关 begin-------------------
--local TABLE_DISPATCH_CHARACTER_PATH = "Share/AreaWar/AreaWarDetachRole.tab"
--local TABLE_DISPATCH_CONDITION_PATH = "Share/AreaWar/AreaWarDetachCondition.tab"

--local DispatchCharacterConfig = {}
--local DispatchConditionConfig = {}

local function InitDispatchConfig()
    --DispatchCharacterConfig =
    --    XTableManager.ReadByIntKey(TABLE_DISPATCH_CHARACTER_PATH, XTable.XTableAreaWarDetachRole, "Id")
    --DispatchConditionConfig =
    --    XTableManager.ReadByIntKey(TABLE_DISPATCH_CONDITION_PATH, XTable.XTableAreaWarDetachCondition, "Id")
end

--local function GetDispatchCharacterConfig(characterId)
--    local config = DispatchCharacterConfig[characterId]
--    if not config then
--        XLog.Error(
--            "XAreaWarConfigs GetDispatchCharacterConfig error:配置不存在, characterId:" ..
--                characterId .. ",path: " .. TABLE_DISPATCH_CHARACTER_PATH
--        )
--        return
--    end
--    return config
--end

--local function GetDispatchConditionConfig(conditionId)
--    local config = DispatchConditionConfig[conditionId]
--    if not config then
--        XLog.Error(
--            "XAreaWarConfigs GetDispatchConditionConfig error:配置不存在, conditionId:" ..
--                conditionId .. ",path: " .. TABLE_DISPATCH_CONDITION_PATH
--        )
--        return
--    end
--    return config
--end

--获取指定派遣成员/机器人Id列表对应满足的所有条件检查表
function XAreaWarConfigs.GetDispatchCharacterCondtionIdCheckDic(entityIds)
    local conditionIdCheckDic = {}
    --2.5 版本去除角色条件判断
    --for _, entityId in pairs(entityIds or {}) do
    --    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    --    if XTool.IsNumberValid(characterId) then
    --        local config = GetDispatchCharacterConfig(characterId)
    --        for _, conditionId in pairs(config.DetachCondition) do
    --            conditionIdCheckDic[conditionId] = conditionId
    --        end
    --    end
    --end
    return conditionIdCheckDic
end

--获取指定派遣成员/机器人Id列表对应满足的所有条件检查表
function XAreaWarConfigs.GetDispatchCharacterCondtionIds(entityId)
    local conditionIds = {}
    --2.5 版本去除角色条件判断
    --local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    --if XTool.IsNumberValid(characterId) then
    --    local config = GetDispatchCharacterConfig(characterId)
    --    for _, conditionId in ipairs(config.DetachCondition) do
    --        tableInsert(conditionIds, conditionId)
    --    end
    --end
    return conditionIds
end

function XAreaWarConfigs.GetDispatchConditionDesc(conditionId)
    --2.5 版本去除角色条件判断
    --local config = GetDispatchConditionConfig(conditionId)
    --return config.Desc
    return ""
end
-----------------派遣相关 end-------------------
-----------------BUFF相关 begin-------------------
local TABLE_BUFF_PATH = "Share/AreaWar/AreaWarBuff.tab"

local BuffConfig = {}

local function InitBuffConfig()
    BuffConfig = XTableManager.ReadByIntKey(TABLE_BUFF_PATH, XTable.XTableAreaWarBuff, "Id")
end

local function GetBuffConfig(buffId)
    local config = BuffConfig[buffId]
    if not config then
        XLog.Error("XAreaWarConfigs GetBuffConfig error:配置不存在, buffId:" .. buffId .. ",path: " .. TABLE_BUFF_PATH)
        return
    end
    return config
end

function XAreaWarConfigs.GetBuffName(buffId)
    local config = GetBuffConfig(buffId)
    return config.Name
end

function XAreaWarConfigs.GetBuffDesc(buffId)
    local config = GetBuffConfig(buffId)
    return config.Desc
end

function XAreaWarConfigs.GetBuffIcon(buffId)
    local config = GetBuffConfig(buffId)
    return config.Icon
end
-----------------BUFF相关 end-------------------
-----------------特攻角色 begin-------------------
local TABLE_SPECIAL_ROLE_PATH = "Share/AreaWar/AreaWarSpecialRole.tab"
local TABLE_SPECIAL_ROLE_REWARD_PATH = "Share/AreaWar/AreaWarSpecialRoleReward.tab"

local SpecialRoleConfig = {}
local SpecialRoleRewardConfig = {}

local function InitSpecialRoleConfig()
    SpecialRoleConfig = XTableManager.ReadByIntKey(TABLE_SPECIAL_ROLE_PATH, XTable.XTableAreaWarSpecialRole, "Id")
    SpecialRoleRewardConfig =
        XTableManager.ReadByIntKey(TABLE_SPECIAL_ROLE_REWARD_PATH, XTable.XTableAreaWarSpecialRoleReward, "Id")
end

local function GetSpecialRoleConfig(roleId)
    local config = SpecialRoleConfig[roleId]
    if not config then
        XLog.Error(
            "XAreaWarConfigs GetSpecialRoleConfig error:配置不存在, roleId:" ..
                roleId .. ",path: " .. TABLE_SPECIAL_ROLE_PATH
        )
        return
    end
    return config
end

local function GetSpecialRoleRewardConfig(rewardId)
    local config = SpecialRoleRewardConfig[rewardId]
    if not config then
        XLog.Error(
            "XAreaWarConfigs GetSpecialRoleRewardConfig error:配置不存在, rewardId:" ..
                rewardId .. ",path: " .. TABLE_SPECIAL_ROLE_REWARD_PATH
        )
        return
    end
    return config
end

function XAreaWarConfigs.GetAllSpecialRoleIds()
    local roleIds = {}
    for roleId in pairs(SpecialRoleConfig) do
        if XTool.IsNumberValid(roleId) then
            tableInsert(roleIds, roleId)
        end
    end
    tableSort(
        roleIds,
        function(a, b)
            return GetSpecialRoleConfig(a).OrderId < GetSpecialRoleConfig(b).OrderId
        end
    )
    return roleIds
end

function XAreaWarConfigs.GetSpecialRoleUnlockBlockId(roleId)
    local config = GetSpecialRoleConfig(roleId)
    return config.UnlockBlockId
end

function XAreaWarConfigs.GetSpecialRoleRobotId(roleId)
    local config = GetSpecialRoleConfig(roleId)
    return config.RobotId
end

function XAreaWarConfigs.GetSpecialRoleName(roleId)
    local config = GetSpecialRoleConfig(roleId)
    return config.Name
end

function XAreaWarConfigs.GetSpecialRoleIcon(roleId)
    local config = GetSpecialRoleConfig(roleId)
    return config.Icon
end

--获取小地图上用的头像图标
function XAreaWarConfigs.GetBlockSpecialRoleIcon(roleId)
    local config = GetSpecialRoleConfig(roleId)
    return config.HeadIcon
end

function XAreaWarConfigs.GetSpecialRoleBuffId(roleId)
    local config = GetSpecialRoleConfig(roleId)
    return config.BuffId
end

function XAreaWarConfigs.GetSpecialRoleLihui(roleId)
    local config = GetSpecialRoleConfig(roleId)
    return config.Lihui
end

function XAreaWarConfigs.GetUnlockSpecialRoleIdByBlockId(blockId)
    if not XTool.IsNumberValid(blockId) then
        return 0
    end
    for roleId, config in pairs(SpecialRoleConfig) do
        if blockId == config.UnlockBlockId then
            return roleId
        end
    end
    return 0
end

--获取所有角色解锁奖励Id
function XAreaWarConfigs.GetAllSpecialRoleUnlockRewardIds()
    local rewardIds = {}
    for rewardId, config in ipairs(SpecialRoleRewardConfig) do
        if XTool.IsNumberValid(config.RewardId) then
            tableInsert(rewardIds, rewardId)
        end
    end
    return rewardIds
end

function XAreaWarConfigs.GetSpecialRoleRewardRewardId(rewardId)
    local config = GetSpecialRoleRewardConfig(rewardId)
    return config.RewardId
end

function XAreaWarConfigs.GetSpecialRoleRewardUnlockCount(rewardId)
    local config = GetSpecialRoleRewardConfig(rewardId)
    return config.UnlockCount
end

--获取指定奖励Id的上一个奖励解锁需要的区块净化数量
function XAreaWarConfigs.GetSpecialRoleRewardLastUnlockCount(rewardId)
    local targetRewardId = rewardId - 1
    if SpecialRoleRewardConfig[targetRewardId] then
        return SpecialRoleRewardConfig[targetRewardId].UnlockCount
    end
    return 0
end

--获取指定区域所有特攻角色Id
function XAreaWarConfigs.GetChapterSpecialRoleIds(chapterId)
    local roleIds = {}
    local blockIds = XAreaWarConfigs.GetBlockIdsByChapterId(chapterId)
    for _, blockId in ipairs(blockIds) do
        local roleId = XAreaWarConfigs.GetUnlockSpecialRoleIdByBlockId(blockId)
        if XTool.IsNumberValid(roleId) then
            tableInsert(roleIds, roleId)
        end
    end
    return roleIds
end
-----------------特攻角色 end-------------------
-----------------挂机收益 begin-------------------
local TABLE_HANG_UP_PATH = "Share/AreaWar/AreaWarHangUpReward.tab"

local HangUpConfig = {}

local function InitHangUpConfig()
    HangUpConfig = XTableManager.ReadByIntKey(TABLE_HANG_UP_PATH, XTable.XTableAreaWarHangUpReward, "Id")
end

local function GetHangUpConfig(id)
    local config = HangUpConfig[id]
    if not config then
        XLog.Error("XAreaWarConfigs GetHangUpConfig error:配置不存在, id:" .. id .. ",path: " .. TABLE_HANG_UP_PATH)
        return
    end
    return config
end

function XAreaWarConfigs.GetAllHangUpIds()
    local ids = {}
    for roleId in ipairs(HangUpConfig) do
        if XTool.IsNumberValid(roleId) then
            tableInsert(ids, roleId)
        end
    end
    return ids
end

function XAreaWarConfigs.GetHangUpUnlockBlockId(id)
    local config = GetHangUpConfig(id)
    return config.UnlockBlockId
end

function XAreaWarConfigs.GetHangUpUnlockAmount(id)
    local config = GetHangUpConfig(id)
    return config.ProductionAmount
end
-----------------挂机收益 end-------------------
-----------------净化加成/插件相关 begin-------------------
local TABLE_PURIFICATION_LEVEL_PATH = "Share/AreaWar/AreaWarPurificationLevel.tab"

local PurificationLevelConfig = {}

XAreaWarConfigs.PluginSlotCount = 3 --插件槽数量

local function InitPurificationConfig()
    PurificationLevelConfig =
        XTableManager.ReadByIntKey(TABLE_PURIFICATION_LEVEL_PATH, XTable.XTableAreaWarPurificationLevel, "Id")
end

local function GetPurificationLevelConfig(level, ignoreError)
    local config = PurificationLevelConfig[level]
    if not config then
        if not ignoreError then
            XLog.Error(
                "XAreaWarConfigs GetPurificationLevelConfig error:配置不存在, level:" ..
                    level .. ",path: " .. TABLE_PURIFICATION_LEVEL_PATH
            )
        end
        return
    end
    return config
end

--获取指定净化等级解锁插件槽数量
function XAreaWarConfigs.GetPfLevelUnlockSlot(level)
    if not XTool.IsNumberValid(level) then
        return 0
    end
    local config = GetPurificationLevelConfig(level)
    return config.HoleCount
end

--获取解锁指定插件槽需要净化等级
function XAreaWarConfigs.GetUnlockSlotPfLevel(slot)
    for level in ipairs(PurificationLevelConfig) do
        if XAreaWarConfigs.GetPfLevelUnlockSlot(level) == slot then
            return level
        end
    end
    return 0
end

--获取指定净化等级升到下一级所需经验
function XAreaWarConfigs.GetPfLevelNextLevelExp(level)
    local config = GetPurificationLevelConfig(level + 1, true)
    return config and config.Exp or 0
end

--获取指定插件解锁等级
function XAreaWarConfigs.GetPfLevelByPluginId(pluginId)
    for level, config in pairs(PurificationLevelConfig) do
        if config.BuffId == pluginId then
            return level
        end
    end
    return 0
end

--获取指定净化等级固定加成属性值
function XAreaWarConfigs.GetPfLevelAddAttrs(level)
    if level < 1 then
        return {0, 0, 0, 0}
    end
    local config = GetPurificationLevelConfig(level)
    return config.AddAttr
end

function XAreaWarConfigs.GetAllPluginIds()
    local pluginIds = {}
    for _, config in pairs(PurificationLevelConfig) do
        if XTool.IsNumberValid(config.BuffId) then
            tableInsert(pluginIds, config.BuffId)
        end
    end
    return pluginIds
end

--获取从0级升到指定净化等级总共需要经验
function XAreaWarConfigs.GetAccumulatedPfExp(targetLevel)
    local totalExp = 0
    for level = 0, targetLevel - 1 do
        totalExp = totalExp + XAreaWarConfigs.GetPfLevelNextLevelExp(level)
    end
    return totalExp
end

--获取最大净化等级
function XAreaWarConfigs.GetMaxPfLevel()
    return #PurificationLevelConfig
end
-----------------净化加成/插件相关 end-------------------

--region   ------------------客户端配置 start-------------------
local ClientConfigTemplate = {}
local TABLE_CLIENT_CONFIG_PATH = "Client/AreaWar/AreaWarClientConfig.tab"

local function InitClientConfig() 
    ClientConfigTemplate = XTableManager.ReadByStringKey(TABLE_CLIENT_CONFIG_PATH, XTable.XTableAreaWarClientConfig, "Key")
end

---@return XTable.XTableAreaWarClientConfig
local function GetClientConfig(key) 
    local template = ClientConfigTemplate[key]
    if not template then
        XLog.ErrorTableDataNotFound("XAreaWarConfigs->GetClientConfig", 
                "AreaWarClientConfig", TABLE_CLIENT_CONFIG_PATH, "Key", key)
        return
    end
    
    return template
end

function XAreaWarConfigs.GetCameraMinAndMaxDistance()
    local template = GetClientConfig("CameraDistance")
    if not template then
        return 0, 0
    end
    return tonumber(template.Values[1]), tonumber(template.Values[2])
end

function XAreaWarConfigs.GetPrefabPath()
    local template = GetClientConfig("PrefabPath")
    return template.Values[1]
end

function XAreaWarConfigs.GetCameraZoomSpeed()
    local template = GetClientConfig("CameraZoomSpeed")
    return tonumber(template.Values[1])
end

function XAreaWarConfigs.GetArticleLockTips()
    local template = GetClientConfig("ArticleTips")
    return template.Values[1]
end

function XAreaWarConfigs.GetArticleAuthorAndTimeTips()
    local template = GetClientConfig("ArticleTips")
    return template.Values[2]
end


function XAreaWarConfigs.GetArticleLikeBoundary()
    local template = GetClientConfig("ArticleLikeCountBoundary")
    return tonumber(template.Values[1])
end

function XAreaWarConfigs.GetArticleGroupLockTip()
    local template = GetClientConfig("ArticleGroupTip")
    return template.Values[1]
end

function XAreaWarConfigs.GetArticleLikeBoundaryUnit()
    local template = GetClientConfig("ArticleLikeCountBoundary")
    return template.Values[2]
end

function XAreaWarConfigs.GetEndTimeTip(index)
    local template = GetClientConfig("EndTimeTips")
    return template.Values[index]
end

function XAreaWarConfigs.GetRewardData()
    local list = {}
    local template = GetClientConfig("GiftsRewardIds")
    for _, value in ipairs(template.Values) do
        local data = string.Split(value, "|")
        tableInsert(list, {
            Id = tonumber(data[1]),
            Count = tonumber(data[2])
        })
    end
    return list
end

function XAreaWarConfigs.GetFirstPlayStoryId()
    local template = GetClientConfig("FirstPlayStoryId")
    return template.Values[1]
end

function XAreaWarConfigs.GetUnlockAnimationInfo()
    local template = GetClientConfig("UnlockAnimationInfo")
    local type = tonumber(template.Values[1]) or CS.XAnimationType.PingPongAndDiffusion
    local duration =  tonumber(template.Values[2]) or 6
    local offsetY = tonumber(template.Values[3]) or 0.82
    local maxDistance = tonumber(template.Values[4]) or 10
    
    return type, duration, offsetY, maxDistance
end

function XAreaWarConfigs.GetIdleAnimationInfo()
    local template = GetClientConfig("IdleAnimationInfo")
    local type = tonumber(template.Values[1]) or CS.XAnimationType.PingPong
    local duration =  tonumber(template.Values[2]) or 5
    local offsetY = tonumber(template.Values[3]) or 0.82

    return type, duration, offsetY
end

function XAreaWarConfigs.GetPlateLiftUpInfo()
    local template = GetClientConfig("PlateLiftUpInfo")
    local offsetY = tonumber(template.Values[1]) or -3
    local duration = tonumber(template.Values[2]) or 0.8
    
    return offsetY, duration
end

function XAreaWarConfigs.GetCameraSmallDisRatio()
    local template = GetClientConfig("CameraSmallDisRatio")
    return template and tonumber(template.Values[1]) or 0.4
end

function XAreaWarConfigs.GetStageDetailFightTip(isRepeatChallenge)
    local index = isRepeatChallenge and 2 or 1
    local template = GetClientConfig("StageDetailFightTip")
    return template and template.Values[index]or ""
end
--endregion------------------客户端配置 finish------------------

--region   ------------------全服战况 start-------------------
local ArticleGroupTemplate = {}
local ArticleTemplate = {}
local ArticleGroupMap

local TABLE_ARTICLE_GROUP_PATH = "Share/AreaWar/AreaWarArticleGroup.tab"
local TABLE_ARTICLE_PATH = "Share/AreaWar/AreaWarArticle.tab"

local function InitWarLogConfig()
    ArticleGroupTemplate = XTableManager.ReadByIntKey(TABLE_ARTICLE_GROUP_PATH, XTable.XTableAreaWarArticleGroup, "Id")
    ArticleTemplate = XTableManager.ReadByIntKey(TABLE_ARTICLE_PATH, XTable.XTableAreaWarArticle, "Id")
end

local function GetArticleGroupTemplate(groupId) 
    local template = ArticleGroupTemplate[groupId]
    if not template then
        XLog.ErrorTableDataNotFound("XAreaWarConfigs->GetArticleGroupTemplate", 
                "AreaWarArticleGroup", TABLE_ARTICLE_GROUP_PATH, "Id", tostring(groupId))
        return {}
    end
    
    return template
end

---@return XTable.XTableAreaWarArticle
local function GetArticleTemplate(id)
    local template = ArticleTemplate[id]
    if not template then
        XLog.ErrorTableDataNotFound("XAreaWarConfigs->GetArticleTemplate", 
                "AreaWarArticle", TABLE_ARTICLE_PATH, "Id", tostring(id))
        return {}
    end

    return template
end

local function CompareId(a, b) 
    return a < b
end

local function ComparePriority(a, b)
    local pA = XAreaWarConfigs.GetArticlePriority(a)
    local pB = XAreaWarConfigs.GetArticlePriority(b)
    if pA ~= pB then
        return pA <pB
    end
    
    return CompareId(a, b)
end

function XAreaWarConfigs.GetArticleGroupList()
    local list = {}
    for id in pairs(ArticleGroupTemplate) do
        tableInsert(list, id)
    end
    
    tableSort(list, CompareId)
    
    return list
end

function XAreaWarConfigs.GetArticleGroupMap()
    if ArticleGroupMap then
        return ArticleGroupMap
    end
    local map = {}
    for id, template in pairs(ArticleTemplate) do
        local groupId = template.GroupId
        if not map[groupId] then
            map[groupId] = {}
        end
        tableInsert(map[groupId], id)
    end
    for _, list in pairs(map) do
        tableSort(list, ComparePriority)
    end
    ArticleGroupMap = map
    return map
end

function XAreaWarConfigs.GetArticleGroupName(groupId)
    local template = GetArticleGroupTemplate(groupId)
    return template and template.Name or ""
end

function XAreaWarConfigs.GetArticleTitle(id)
    local template = GetArticleTemplate(id)
    return template and template.Title or ""
end

function XAreaWarConfigs.GetArticleContent(id)
    local template = GetArticleTemplate(id)
    local content = template and template.Content or ""
    return XUiHelper.ReplaceTextNewLine(content)
end

function XAreaWarConfigs.GetArticleGroupId(id)
    local template = GetArticleTemplate(id)
    return template.GroupId
end

function XAreaWarConfigs.GetArticleUnlockBlockIdAndProgress(id)
    local template = GetArticleTemplate(id)
    return template.UnlockBlockId, template.UnlockBlockProgress
end

function XAreaWarConfigs.GetArticleAuthor(id)
    local template = GetArticleTemplate(id)
    return template.Author
end

function XAreaWarConfigs.GetArticleStoryId(id)
    local template = GetArticleTemplate(id)
    return template.StoryId
end

function XAreaWarConfigs.GetArticleBackground(id)
    local template = GetArticleTemplate(id)
    return template.Background
end

function XAreaWarConfigs.GetArticlePriority(id)
    local template = GetArticleTemplate(id)
    return template.Priority
end

--endregion------------------全服战况 finish------------------
function XAreaWarConfigs.Init()
    InitActivityConfig()
    InitBlockConfig()
    InitChapterConfig()
    InitBuffConfig()
    InitSpecialRoleConfig()
    InitHangUpConfig()
    InitPurificationConfig()
    InitDispatchConfig()
    InitClientConfig()
    InitWarLogConfig()
end
