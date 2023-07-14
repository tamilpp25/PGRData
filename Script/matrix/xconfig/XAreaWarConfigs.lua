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
-----------------区域相关 begin-------------------
local TABLE_AREA_PATH = "Client/AreaWar/AreaWarArea.tab"

local AreaConfig = {}

XAreaWarConfigs.Difficult = {
    Normal = 1,
    Hard = 2
}

local function InitAreaConfig()
    AreaConfig = XTableManager.ReadByIntKey(TABLE_AREA_PATH, XTable.XTableAreaWarArea, "Id")
end

local function GetAreaConfig(areaId)
    local config = AreaConfig[areaId]
    if not config then
        XLog.Error("XAreaWarConfigs GetAreaConfig error:配置不存在, areaId:" .. areaId .. ",path: " .. TABLE_AREA_PATH)
        return
    end
    return config
end

function XAreaWarConfigs.GetAllAreaIds()
    local areaIds = {}
    for areaId in ipairs(AreaConfig) do
        tableInsert(areaIds, areaId)
    end
    return areaIds
end

function XAreaWarConfigs.GetAreaUnlockBlockId(areaId)
    local config = GetAreaConfig(areaId)
    return config.UnlockBlockId
end

function XAreaWarConfigs.GetAreaName(areaId)
    local config = GetAreaConfig(areaId)
    return config.Name
end

function XAreaWarConfigs.GetAreaBlockIds(areaId)
    local blockIds = {}
    local config = GetAreaConfig(areaId)
    for _, blockId in ipairs(config.BlockId) do
        if XTool.IsNumberValid(blockId) then
            tableInsert(blockIds, blockId)
        end
    end
    return blockIds
end

--获取指定区块所属区域Id
function XAreaWarConfigs.GetBlockAreaId(blockId)
    for areaId, config in pairs(AreaConfig) do
        for _, inBlockId in pairs(config.BlockId) do
            if inBlockId == blockId then
                return areaId
            end
        end
    end
    return 0
end

--获取指定区域内世界Boss的Ui类型（不同区域使用不同的UI）
function XAreaWarConfigs.GetAreaWorldBossUiType(areaId)
    local config = GetAreaConfig(areaId)
    return config.WorldBossUiType
end
-----------------区域相关 end-------------------
-----------------区块相关 begin-------------------
local TABLE_BLOCK_PATH = "Share/AreaWar/AreaWarBlock.tab"
local TABLE_BLOCK_SHOW_TYPE_PATH = "Client/AreaWar/AreaWarBlockShowType.tab"
local TABLE_WORLD_BOSS_UI_PATH = "Client/AreaWar/AreaWarWorldBossUi.tab"

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
    local config = GetBlockConfig(blockId)
    return config.OpenHour * 3600
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
    local areaId = XAreaWarConfigs.GetBlockAreaId(blockId)
    local uiType = XAreaWarConfigs.GetAreaWorldBossUiType(areaId)
    return XAreaWarConfigs.GetWorldBossUiName(uiType)
end

--获取世界Boss区块排行榜
function XAreaWarConfigs.GetBlockWorldBossRankTitle(blockId)
    local areaId = XAreaWarConfigs.GetBlockAreaId(blockId)
    local uiType = XAreaWarConfigs.GetAreaWorldBossUiType(areaId)
    return XAreaWarConfigs.GetWorldBossRankTitle(uiType)
end
-----------------区块相关 end-------------------
-----------------派遣相关 begin-------------------
local TABLE_DISPATCH_CHARACTER_PATH = "Share/AreaWar/AreaWarDetachRole.tab"
local TABLE_DISPATCH_CONDITION_PATH = "Share/AreaWar/AreaWarDetachCondition.tab"

local DispatchCharacterConfig = {}
local DispatchConditionConfig = {}

local function InitDispatchConfig()
    DispatchCharacterConfig =
        XTableManager.ReadByIntKey(TABLE_DISPATCH_CHARACTER_PATH, XTable.XTableAreaWarDetachRole, "Id")
    DispatchConditionConfig =
        XTableManager.ReadByIntKey(TABLE_DISPATCH_CONDITION_PATH, XTable.XTableAreaWarDetachCondition, "Id")
end

local function GetDispatchCharacterConfig(characterId)
    local config = DispatchCharacterConfig[characterId]
    if not config then
        XLog.Error(
            "XAreaWarConfigs GetDispatchCharacterConfig error:配置不存在, characterId:" ..
                characterId .. ",path: " .. TABLE_DISPATCH_CHARACTER_PATH
        )
        return
    end
    return config
end

local function GetDispatchConditionConfig(conditionId)
    local config = DispatchConditionConfig[conditionId]
    if not config then
        XLog.Error(
            "XAreaWarConfigs GetDispatchConditionConfig error:配置不存在, conditionId:" ..
                conditionId .. ",path: " .. TABLE_DISPATCH_CONDITION_PATH
        )
        return
    end
    return config
end

--获取指定派遣成员/机器人Id列表对应满足的所有条件检查表
function XAreaWarConfigs.GetDispatchCharacterCondtionIdCheckDic(entityIds)
    local conditionIdCheckDic = {}
    for _, entityId in pairs(entityIds or {}) do
        local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
        if XTool.IsNumberValid(characterId) then
            local config = GetDispatchCharacterConfig(characterId)
            for _, conditionId in pairs(config.DetachCondition) do
                conditionIdCheckDic[conditionId] = conditionId
            end
        end
    end
    return conditionIdCheckDic
end

--获取指定派遣成员/机器人Id列表对应满足的所有条件检查表
function XAreaWarConfigs.GetDispatchCharacterCondtionIds(entityId)
    local conditionIds = {}
    local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
    if XTool.IsNumberValid(characterId) then
        local config = GetDispatchCharacterConfig(characterId)
        for _, conditionId in ipairs(config.DetachCondition) do
            tableInsert(conditionIds, conditionId)
        end
    end
    return conditionIds
end

function XAreaWarConfigs.GetDispatchConditionDesc(conditionId)
    local config = GetDispatchConditionConfig(conditionId)
    return config.Desc
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
function XAreaWarConfigs.GetAreaSpecialRoleIds(areaId)
    local roleIds = {}
    local blockIds = XAreaWarConfigs.GetAreaBlockIds(areaId)
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
function XAreaWarConfigs.Init()
    InitActivityConfig()
    InitAreaConfig()
    InitBlockConfig()
    InitBuffConfig()
    InitSpecialRoleConfig()
    InitHangUpConfig()
    InitPurificationConfig()
    InitDispatchConfig()
end
