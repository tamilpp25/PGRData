local TABLE_SECTION_PATH = "Client/Fuben/InfestorExplore/ExploreSection.tab"
local TABLE_CHAPTER_PATH = "Share/Fuben/InfestorExplore/ExploreChapter.tab"
local TABLE_STAGE_PATH = "Share/Fuben/InfestorExplore/ExploreNode.tab"
local TABLE_LEVEL_GROUP_PATH = "Share/Fuben/InfestorExplore/InfestorGroup.tab"
local TABLE_DIFF_PATH = "Share/Fuben/InfestorExplore/InfestorDiff.tab"
local TABLE_FOG_PATH = "Client/Fuben/InfestorExplore/Fog.tab"
local TABLE_MAP_PATH = "Share/Fuben/InfestorExplore/Map/"
local TABLE_NODETYPE_PATH = "Client/Fuben/InfestorExplore/NodeType.tab"
local TABLE_EVENT_POOL_PATH = "Share/Fuben/InfestorExplore/ExploreEventPool.tab"
local TABLE_EVENT_POOL_RES_PATH = "Client/Fuben/InfestorExplore/ExploreEventPoolRes.tab"
local TABLE_FIGHTEVENT_PATH = "Share/Fuben/InfestorExplore/InfestorFightEvent.tab"
local TABLE_BUFF_PATH = "Client/Fuben/InfestorExplore/Buffs.tab"
local TABLE_CORE_PATH = "Share/Fuben/InfestorExplore/Core.tab"
local TABLE_CORE_LEVEL_PATH = "Share/Fuben/InfestorExplore/CoreLevelEffect.tab"
local TABLE_SUPPLY_REWARD_PATH = "Client/Fuben/InfestorExplore/SupplyReward.tab"
local TABLE_SHOP_PATH = "Share/Fuben/InfestorExplore/Shop.tab"
local TABLE_SHOP_GOODS_PATH = "Share/Fuben/InfestorExplore/ShopGoods.tab"
local TABLE_REWARD_PATH = "Share/Fuben/InfestorExplore/ExploreRewardPool.tab"
local TABLE_EVENT_GOODS_PATH = "Share/Fuben/InfestorExplore/InfestorEventGoods.tab"
local TABLE_EVENT_TYPE_PATH = "Client/Fuben/InfestorExplore/EventType.tab"
local TABLE_FIGHT_REWARD_COST_PATH = "Share/Fuben/InfestorExplore/FightRewardCost.tab"
local TABLE_ACTIVITY_PATH = "Share/Fuben/InfestorExplore/InfestorActivity.tab"
local TABLE_OUTPOST_DES_PATH = "Client/Fuben/InfestorExplore/OutPostDes.tab"
local TABLE_OUTPOST_DES_POOL_PATH = "Client/Fuben/InfestorExplore/OutPostDesPool.tab"
local TABLE_SCORE_RULE_PATH = "Share/Fuben/InfestorExplore/InfestorBossScoreRule.tab"

local CSXTextManagerGetText = CS.XTextManager.GetText
local tableInsert = table.insert
local tableUnpack = table.unpack
local stringFormat = string.format

local SectionTemplate = {}
local ChapterTemplate = {}
local StageTemplate = {}
local LevelGroupTemplate = {}
local NodeTypeTemplate = {}
local EventPoolMultionOptionsDic = {}
local EventTemplate = {}
local EventPoolTemplate = {}
local DiffConfigDic = {}
local MapTemplates = {}
local FogDepthDic = {}
local BuffTemplate = {}
local FightEventTemplate = {}
local CoreTemplate = {}
local CoreLevelDic = {}
local SupplyRewardTemplate = {}
local ShopTemplate = {}
local ShopGoodsTemplate = {}
local RewardTemplate = {}
local EventGoodsTemplate = {}
local EventTypeTemplate = {}
local FightRewardCostTemplate = {}
local ActivityTemplate = {}
local OutPostDesPoolDic = {}
local OutPostDesDic = {}
local ScoreRuleDict = {}

local QualityIconPath = {
    [1] = CS.XGame.ClientConfig:GetString("UiInfestorExploreCorePurple"),
    [2] = CS.XGame.ClientConfig:GetString("UiInfestorExploreCorePurple"),
    [3] = CS.XGame.ClientConfig:GetString("UiInfestorExploreCorePurple"),
    [4] = CS.XGame.ClientConfig:GetString("UiInfestorExploreCorePurple"),
    [5] = CS.XGame.ClientConfig:GetString("UiInfestorExploreCoreGold"),
    [6] = CS.XGame.ClientConfig:GetString("UiInfestorExploreCoreRed"),
}

local QualityLevel = {
    Purple = 4,
    Gold = 5, --插件单元金色品质
}

XFubenInfestorExploreConfigs = XFubenInfestorExploreConfigs or {}

XFubenInfestorExploreConfigs.Region = {
    UpRegion = 1, --晋级区
    KeepRegion = 2, --保级区
    DownRegion = 3, --降级区
}

XFubenInfestorExploreConfigs.EventType = {
    Unknown = 0,
    AddCore = 101, --获得战术核心
    LostCore = 102, --失去一个现有战术核心
    LevelUpCore = 103, --升级一个已有核心
    ChangeTeamHpPer = 201, --改变队伍百分比血量
    ChangeCharacterHpPer = 202, --改变成员百分比血量
    ChangeMoneyPer = 301, --获得or失去百分比代币
    ChangeMoney = 302, --获得or失去指定数量代币
    ChangeMoneyRandom = 303, --获得or失去随机数量代币
    ChangeActionPoint = 401, --获得or失去指定数量行动点
    AddBuff = 501, --获得一个buff
    RemoveBuff = 502, --随机移除一个已有buff
}

XFubenInfestorExploreConfigs.MaxWearingCoreNum = 6  --核心最大穿戴数量
XFubenInfestorExploreConfigs.MaxEventOptionNum = 3  --可选择事件最大选项数量

local InitMapConfig = function()
    local paths = CS.XTableManager.GetPaths(TABLE_MAP_PATH)
    XTool.LoopCollection(paths, function(path)
        local key = tonumber(XTool.GetFileNameWithoutExtension(path))
        MapTemplates[key] = XTableManager.ReadByIntKey(path, XTable.XTableInfestorExploreGrid, "Id")
    end)
end

local MAX_FOG_DEPTH = 5--最大迷雾深度
local InitFogConfig = function()
    local template = XTableManager.ReadByIntKey(TABLE_FOG_PATH, XTable.XTableInfestorExploreFog, "Id")
    for _, config in pairs(template) do
        local depth = config.Depth
        if depth > MAX_FOG_DEPTH then
            XLog.Error("XFubenInfestorExploreConfigs InitFogConfig Erorr: 感染体玩法地图深度配置错误：超过最大深度上限: " .. MAX_FOG_DEPTH .. ", 配置路径: " .. TABLE_FOG_PATH)
            return
        end
        FogDepthDic[config.Type] = depth
    end
end

local InitDiffConfig = function()
    local template = XTableManager.ReadByIntKey(TABLE_DIFF_PATH, XTable.XTableInfestorExploreDiff, "Id")
    for _, config in pairs(template) do
        local groupId = config.GroupId
        local groupConfig = DiffConfigDic[groupId] or {}
        DiffConfigDic[groupId] = groupConfig

        local diff = config.Diff
        groupConfig[diff] = config
    end
end

local InitEventPoolResConfig = function()
    local template = XTableManager.ReadByIntKey(TABLE_EVENT_POOL_RES_PATH, XTable.XTableInfestorEventPoolRes, "PoolId")
    for _, config in pairs(template) do
        local poolId = config.PoolId
        local multiOption = EventPoolMultionOptionsDic[poolId] or {}

        for i = 1, XFubenInfestorExploreConfigs.MaxEventOptionNum do
            local options = multiOption[i] or {}
            multiOption[i] = options

            for index, eventId in pairs(config["EventId" .. i]) do
                options[index] = eventId
            end
        end

        EventPoolMultionOptionsDic[poolId] = multiOption
    end
    EventPoolTemplate = template
end

local InitCoreLevelConfig = function()
    local template = XTableManager.ReadByIntKey(TABLE_CORE_LEVEL_PATH, XTable.XTableInfestorExploreCoreLevelEffect, "Id")
    for _, config in pairs(template) do
        local coreId = config.CoreId
        local coreConfig = CoreLevelDic[coreId] or {}
        CoreLevelDic[coreId] = coreConfig

        local level = config.CoreLevel
        coreConfig[level] = config
    end
end

local InitOutPostDesPoolConfig = function()
    local template = XTableManager.ReadByIntKey(TABLE_OUTPOST_DES_POOL_PATH, XTable.XTableInfestorOutPostDesPool, "Id")
    for _, config in pairs(template) do
        local poolId = config.PoolId

        local desList = OutPostDesPoolDic[poolId] or {}
        OutPostDesPoolDic[poolId] = desList

        tableInsert(desList, config.Description)
    end
end

local InitOutPostDesConfig = function()
    local template = XTableManager.ReadByIntKey(TABLE_OUTPOST_DES_PATH, XTable.XTableInfestorOutPostDes, "Id")
    for _, config in pairs(template) do
        local key = config.Key
        OutPostDesDic[key] = config
    end
end

local InitScoreRuleConfig = function()
    ScoreRuleDict = XTableManager.ReadByIntKey(TABLE_SCORE_RULE_PATH, XTable.XTableInfestorBossScoreRule, "StageId")
end

function XFubenInfestorExploreConfigs.Init()
    SectionTemplate = XTableManager.ReadByIntKey(TABLE_SECTION_PATH, XTable.XTableInfestorExploreSection, "Id")
    ChapterTemplate = XTableManager.ReadByIntKey(TABLE_CHAPTER_PATH, XTable.XTableInfestorExploreChapter, "Id")
    StageTemplate = XTableManager.ReadAllByIntKey(TABLE_STAGE_PATH, XTable.XTableInfestorExploreNode, "Id")
    LevelGroupTemplate = XTableManager.ReadByIntKey(TABLE_LEVEL_GROUP_PATH, XTable.XTableInfestorGroup, "Id")
    NodeTypeTemplate = XTableManager.ReadByIntKey(TABLE_NODETYPE_PATH, XTable.XTableInfestorNodeType, "Type")
    BuffTemplate = XTableManager.ReadByIntKey(TABLE_BUFF_PATH, XTable.XTableInfestorBuffsRes, "Id")
    FightEventTemplate = XTableManager.ReadByIntKey(TABLE_FIGHTEVENT_PATH, XTable.XTableInfestorFightEvent, "Id")
    CoreTemplate = XTableManager.ReadByIntKey(TABLE_CORE_PATH, XTable.XTableInfestorExploreCore, "Id")
    SupplyRewardTemplate = XTableManager.ReadByIntKey(TABLE_SUPPLY_REWARD_PATH, XTable.XTableInfestorSupplyRewardRes, "Id")
    ShopTemplate = XTableManager.ReadByIntKey(TABLE_SHOP_PATH, XTable.XTableInfestorExploreShop, "Id")
    ShopGoodsTemplate = XTableManager.ReadByIntKey(TABLE_SHOP_GOODS_PATH, XTable.XTableInfestorExploreShopGoods, "Id")
    RewardTemplate = XTableManager.ReadByIntKey(TABLE_REWARD_PATH, XTable.XTableInfestorExploreReward, "Id")
    EventGoodsTemplate = XTableManager.ReadByIntKey(TABLE_EVENT_GOODS_PATH, XTable.XTableInfestorEventGoods, "EventId")
    EventTemplate = XTableManager.ReadByIntKey(TABLE_EVENT_POOL_PATH, XTable.XTableInfestorExploreEvent, "Id")
    EventTypeTemplate = XTableManager.ReadByIntKey(TABLE_EVENT_TYPE_PATH, XTable.XTableInfestorEventType, "Type")
    FightRewardCostTemplate = XTableManager.ReadByIntKey(TABLE_FIGHT_REWARD_COST_PATH, XTable.XTableInfestorFightRewardCost, "Times")
    ActivityTemplate = XTableManager.ReadAllByIntKey(TABLE_ACTIVITY_PATH, XTable.XTableInfestorActivity, "Id")
    InitDiffConfig()
    InitMapConfig()
    InitFogConfig()
    InitEventPoolResConfig()
    InitCoreLevelConfig()
    InitOutPostDesPoolConfig()
    InitOutPostDesConfig()
    InitScoreRuleConfig()
end

local GetOutPostDesPoolDesList = function(poolId)
    local config = OutPostDesPoolDic[poolId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetOutPostDesPoolConfig error:配置不存在, : " .. poolId .. ", 配置路径: " .. TABLE_OUTPOST_DES_POOL_PATH)
        return
    end
    return config
end

local GetOutPostDesConfig = function(key)
    local config = OutPostDesDic[key]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetOutPostDesConfig error:配置不存在, : " .. key .. ", 配置路径: " .. TABLE_OUTPOST_DES_PATH)
        return
    end
    return config
end

local GetScoreRuleConfig = function(key)
    local config = ScoreRuleDict[key]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetScoreRuleConfig error:配置不存在, : " .. key .. ", 配置路径: " .. TABLE_SCORE_RULE_PATH)
        return
    end
    return config
end

local GetActivityConfig = function(activityId)
    local config = ActivityTemplate[activityId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetActivityConfig error:配置不存在, : " .. activityId .. ", 配置路径: " .. TABLE_ACTIVITY_PATH)
        return
    end
    return config
end

local GetSectionConfig = function(sectionId)
    local config = SectionTemplate[sectionId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetChapterConfig error:配置不存在, sectionId: " .. sectionId .. ", 配置路径: " .. TABLE_SECTION_PATH)
        return
    end
    return config
end

local GetChapterConfig = function(chapterId)
    local config = ChapterTemplate[chapterId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetChapterConfig error:配置不存在, chapterId: " .. chapterId .. ", 配置路径: " .. TABLE_CHAPTER_PATH)
        return
    end
    return config
end

local GetStageConfig = function(stageId)
    local config = StageTemplate[stageId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetStageConfig error:配置不存在, stageId: " .. stageId .. ", 配置路径: " .. TABLE_STAGE_PATH)
        return
    end
    return config
end

local GetLevelGroupConfig = function(groupId)
    local config = LevelGroupTemplate[groupId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetLevelGroupConfig error:配置不存在, groupId: " .. groupId .. ", 配置路径: " .. TABLE_LEVEL_GROUP_PATH)
        return
    end
    return config
end

local GetGroupDiffConfigs = function(groupId)
    local config = DiffConfigDic[groupId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetGroupDiffConfigs error:配置不存在, groupId: " .. groupId .. ", 配置路径: " .. TABLE_DIFF_PATH)
        return
    end
    return config
end

local GetGroupDiffConfig = function(groupId, diff)
    local config = GetGroupDiffConfigs(groupId)[diff]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetGroupDiffConfig error:配置不存在, diff: " .. diff .. ", 配置路径: " .. TABLE_DIFF_PATH)
        return
    end
    return config
end

local GetNodeTypeConfig = function(nodeType)
    local config = NodeTypeTemplate[nodeType]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetNodeTypeConfig error:配置不存在, nodeType: " .. nodeType .. ", 配置路径: " .. TABLE_NODETYPE_PATH)
        return
    end
    return config
end

local GetEventConfig = function(eventId)
    local config = EventTemplate[eventId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetEventConfig error:配置不存在, eventId: " .. eventId .. ", 配置路径: " .. TABLE_EVENT_POOL_PATH)
        return
    end
    return config
end

local GetEventPoolConfig = function(poolId)
    local config = EventPoolTemplate[poolId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetEventPoolConfig error:配置不存在, poolId: " .. poolId .. ", 配置路径: " .. TABLE_EVENT_POOL_RES_PATH)
        return
    end
    return config
end

local GetBuffConfig = function(buffId)
    local config = BuffTemplate[buffId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetBuffConfig error:配置不存在, buffId: " .. buffId .. ", 配置路径: " .. TABLE_BUFF_PATH)
        return
    end
    return config
end

local GetFightEventConfig = function(fightEventId)
    local config = FightEventTemplate[fightEventId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetFightEventConfig error:配置不存在, fightEventId: " .. fightEventId .. ", 配置路径: " .. TABLE_FIGHTEVENT_PATH)
        return
    end
    return config
end

local GetCoreConfig = function(coreId)
    local config = CoreTemplate[coreId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetCoreConfig error:配置不存在, coreId : " .. coreId .. ", 配置路径: " .. TABLE_CORE_PATH)
        return
    end
    return config
end

local GetCoreLevelConfig = function(coreId, level)
    local config = CoreLevelDic[coreId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetCoreLevelConfig error:配置不存在, coreId : " .. coreId .. ", level : " .. level .. ", 配置路径: " .. TABLE_CORE_LEVEL_PATH)
        return
    end

    config = config[level]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetCoreLevelConfig error:配置不存在 coreId : " .. coreId .. ", level : " .. level .. ", 配置路径: " .. TABLE_CORE_LEVEL_PATH)
        return
    end

    return config
end

local GetShopConfig = function(shopId)
    local config = ShopTemplate[shopId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetShopConfig error:配置不存在, shopId : " .. shopId .. ", 配置路径: " .. TABLE_SHOP_PATH)
        return
    end
    return config
end

local GetShopGoodsConfig = function(goodsId)
    local config = ShopGoodsTemplate[goodsId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetShopGoodsConfig error:配置不存在, goodsId : " .. goodsId .. ", 配置路径: " .. TABLE_SHOP_GOODS_PATH)
        return
    end
    return config
end

local GetRewardConfig = function(rewardId)
    local config = RewardTemplate[rewardId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetRewardConfig error:配置不存在, rewardId : " .. rewardId .. ", 配置路径: " .. TABLE_REWARD_PATH)
        return
    end
    return config
end

local GetEventGoodsConfig = function(eventId)
    local config = EventGoodsTemplate[eventId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetEventGoodsConfig error:配置不存在, eventId : " .. eventId .. ", 配置路径: " .. TABLE_EVENT_GOODS_PATH)
        return
    end
    return config
end

local function GetEventPoolMultiOptions(poolId)
    local config = EventPoolMultionOptionsDic[poolId]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetEventGoodsConfig error:配置不存在, poolId : " .. poolId .. ", 配置路径: " .. TABLE_EVENT_POOL_RES_PATH)
        return
    end
    return config
end

local function GetEventTypeConfig(eventType)
    local config = EventTypeTemplate[eventType]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetEventTypeConfig error:配置不存在, eventType : " .. eventType .. ", 配置路径: " .. TABLE_EVENT_TYPE_PATH)
        return
    end
    return config
end

local GetFightRewardCostConfig = function(times)
    local config = FightRewardCostTemplate[times]
    if not config then
        XLog.Error("XFubenInfestorExploreConfigs GetFightRewardCostConfig error:配置不存在, times : " .. times .. ", 配置路径: " .. TABLE_FIGHT_REWARD_COST_PATH)
        return
    end
    return config
end

function XFubenInfestorExploreConfigs.GetBuffId(fightEventId)
    return GetFightEventConfig(fightEventId).ExploreFightEventId[1]
end

function XFubenInfestorExploreConfigs.GetBuffIdTwo(fightEventId)
    return GetFightEventConfig(fightEventId).BossFightEventId[1]
end

function XFubenInfestorExploreConfigs.GetBuffName(buffId)
    return GetBuffConfig(buffId).Name
end

function XFubenInfestorExploreConfigs.GetBuffDes(buffId)
    return GetBuffConfig(buffId).Description
end

function XFubenInfestorExploreConfigs.GetBuffIcon(buffId)
    return GetBuffConfig(buffId).Icon
end

function XFubenInfestorExploreConfigs.GetSectionName(sectionId)
    return GetSectionConfig(sectionId).Name
end

function XFubenInfestorExploreConfigs.GetChapterConfigs()
    return ChapterTemplate
end

function XFubenInfestorExploreConfigs.GetStageConfigs()
    return StageTemplate
end

function XFubenInfestorExploreConfigs.GetPreChapterId(chapterId)
    return GetChapterConfig(chapterId).PreChapterId
end

function XFubenInfestorExploreConfigs.GetNextChapterId(chapterId)
    for paramChapterId in pairs(ChapterTemplate) do
        if chapterId == XFubenInfestorExploreConfigs.GetPreChapterId(paramChapterId) then
            return paramChapterId
        end
    end
    return 0
end

function XFubenInfestorExploreConfigs.GetChapterName(chapterId)
    return GetChapterConfig(chapterId).Name
end

function XFubenInfestorExploreConfigs.GetChapterCharacterLimitType(chapterId)
    return GetChapterConfig(chapterId).CharacterLimitType
end

function XFubenInfestorExploreConfigs.GetChapterLimitBuffId(chapterId)
    local limitBuffId = GetChapterConfig(chapterId).LimitBuffId
    return XFubenConfigs.GetLimitShowBuffId(limitBuffId)
end

function XFubenInfestorExploreConfigs.GetChapterPrefabPath(chapterId)
    return GetChapterConfig(chapterId).Prefab
end

function XFubenInfestorExploreConfigs.GetChapterDescription(chapterId)
    return GetChapterConfig(chapterId).Description
end

function XFubenInfestorExploreConfigs.GetChapterIcon(chapterId)
    return GetChapterConfig(chapterId).Icon
end

function XFubenInfestorExploreConfigs.GetChapterBg(chapterId)
    return GetChapterConfig(chapterId).Bg
end

function XFubenInfestorExploreConfigs.GetMapId(chapterId)
    return GetChapterConfig(chapterId).MapId
end

function XFubenInfestorExploreConfigs.GetNodeType(stageId)
    return GetStageConfig(stageId).Type
end

function XFubenInfestorExploreConfigs.GetNodeResType(stageId)
    return GetStageConfig(stageId).ResType
end

function XFubenInfestorExploreConfigs.GetFightStageId(stageId)
    return GetStageConfig(stageId).FightStageId
end

function XFubenInfestorExploreConfigs.GetShowRewardId(stageId)
    return GetStageConfig(stageId).ShowRewardId
end

function XFubenInfestorExploreConfigs.GetUseActionPoint(stageId)
    return GetStageConfig(stageId).UseActionPoint
end

function XFubenInfestorExploreConfigs.GetGroupLevelBorder(groupId)
    local config = GetLevelGroupConfig(groupId)
    return config.MinLevel, config.MaxLevel
end

function XFubenInfestorExploreConfigs.GetDiffName(groupId, diff)
    local config = GetGroupDiffConfig(groupId, diff)
    return config.Name
end

function XFubenInfestorExploreConfigs.GetDiffIcon(groupId, diff)
    local config = GetGroupDiffConfig(groupId, diff)
    return config.Icon
end

function XFubenInfestorExploreConfigs.GetDiffUpNum(groupId, diff)
    return GetGroupDiffConfig(groupId, diff).UpNum
end

function XFubenInfestorExploreConfigs.GetDiffKeepNum(groupId, diff)
    local joinNum = GetGroupDiffConfig(groupId, diff).JoinNum
    local upNum = XFubenInfestorExploreConfigs.GetDiffUpNum(groupId, diff)
    local downNum = XFubenInfestorExploreConfigs.GetDiffDownNum(groupId, diff)
    return joinNum - upNum - downNum
end

function XFubenInfestorExploreConfigs.GetDiffDownNum(groupId, diff)
    return GetGroupDiffConfig(groupId, diff).DownNum
end

function XFubenInfestorExploreConfigs.GetDiffShowScoreGap(groupId, diff)
    return GetGroupDiffConfig(groupId, diff).ShowScoreGap
end

function XFubenInfestorExploreConfigs.GetDiffShowScoreLimit(groupId, diff)
    return GetGroupDiffConfig(groupId, diff).ShowScoreLimit
end

function XFubenInfestorExploreConfigs.GetNodeTypeIcon(nodeResType)
    return GetNodeTypeConfig(nodeResType).Icon
end

function XFubenInfestorExploreConfigs.GetNodeTypeStageBg(nodeResType)
    return GetNodeTypeConfig(nodeResType).StageBg
end

function XFubenInfestorExploreConfigs.GetMapConfig(chapterId)
    local mapId = XFubenInfestorExploreConfigs.GetMapId(chapterId)
    return MapTemplates[mapId]
end

function XFubenInfestorExploreConfigs.GetFogDepth(nodeType)
    return FogDepthDic[nodeType] or 0
end

function XFubenInfestorExploreConfigs.GetEventPoolId(stageId)
    return GetStageConfig(stageId).EventPoolId
end

function XFubenInfestorExploreConfigs.GetEventPoolName(poolId)
    return GetEventPoolConfig(poolId).Name
end

function XFubenInfestorExploreConfigs.GetEventPoolDes(poolId)
    return GetEventPoolConfig(poolId).Description
end

function XFubenInfestorExploreConfigs.GetEventPoolBtnName(poolId)
    return GetEventPoolConfig(poolId).BtnName
end

function XFubenInfestorExploreConfigs.GetEventPoolMultiOptionEventIds(poolId, index)
    local eventIds = {}

    local multiOptions = GetEventPoolMultiOptions(poolId)
    local multiOption = multiOptions[index]
    for _, eventId in pairs(multiOption) do
        tableInsert(eventIds, eventId)
    end

    return eventIds
end

function XFubenInfestorExploreConfigs.GetEventPoolMultiOptionDesList(poolId, index)
    local desList = {}

    local multiOption = XFubenInfestorExploreConfigs.GetEventPoolMultiOptionEventIds(poolId, index)
    for _, eventId in pairs(multiOption) do
        tableInsert(desList, XFubenInfestorExploreConfigs.GetEventDes(eventId))
    end

    return desList
end

function XFubenInfestorExploreConfigs.GetEventDes(eventId)
    return GetEventConfig(eventId).Description
end

function XFubenInfestorExploreConfigs.GetEventName(eventId)
    return GetEventConfig(eventId).Name
end

function XFubenInfestorExploreConfigs.GetEventIcon(eventId)
    return GetEventConfig(eventId).Icon
end

function XFubenInfestorExploreConfigs.GetEventQuality(eventId)
    return GetEventConfig(eventId).Quality
end

function XFubenInfestorExploreConfigs.GetEventQualityIcon(eventId)
    return QualityIconPath[XFubenInfestorExploreConfigs.GetEventQuality(eventId)]
end


local RankNotRegionText = {
    [XFubenInfestorExploreConfigs.Region.UpRegion] = CSXTextManagerGetText("ArenaActivityNotUpRegionDesc"),
    [XFubenInfestorExploreConfigs.Region.KeepRegion] = CSXTextManagerGetText("ArenaActivityNotKeepRegionDesc"),
    [XFubenInfestorExploreConfigs.Region.DownRegion] = CSXTextManagerGetText("ArenaActivityNotDownRegionDesc"),
}

function XFubenInfestorExploreConfigs.GetRankNotRegionDescText(rankRegion)
    return RankNotRegionText[rankRegion]
end

function XFubenInfestorExploreConfigs.GetRankRegionName(rankRegion)
    if rankRegion == XFubenInfestorExploreConfigs.Region.UpRegion then
        return CSXTextManagerGetText("ArenaActivityUpRegion")
    elseif rankRegion == XFubenInfestorExploreConfigs.Region.KeepRegion then
        return CSXTextManagerGetText("ArenaActivityKeepRegion")
    elseif rankRegion == XFubenInfestorExploreConfigs.Region.DownRegion then
        return CSXTextManagerGetText("ArenaActivityDownRegion")
    else
        XLog.Error("XFubenInfestorExploreConfigs.GetRankRegionName Error: 配置找不到, rankRegion" .. rankRegion)
    end
end

function XFubenInfestorExploreConfigs.GetRankRegionDescText(groupId, diff, rankRegion)
    local config = GetGroupDiffConfig(groupId, diff)
    if rankRegion == XFubenInfestorExploreConfigs.Region.UpRegion then
        return CSXTextManagerGetText("ArenaActivityUpRegionDesc", 1, config.UpNum)
    elseif rankRegion == XFubenInfestorExploreConfigs.Region.DownRegion then
        return CSXTextManagerGetText("ArenaActivityDownRegionDesc", config.JoinNum - config.DownNum + 1, config.JoinNum)
    elseif rankRegion == XFubenInfestorExploreConfigs.Region.KeepRegion then
        return CSXTextManagerGetText("ArenaActivityKeepRegionDesc", config.UpNum + 1, config.JoinNum - config.DownNum)
    else
        XLog.Error("XFubenInfestorExploreConfigs.GetRankRegionDescText Error: 配置找不到, groupId: " .. groupId .. ", diff: " .. diff .. ", rankRegion" .. rankRegion)
    end
end

local RankRegionColorText = {
    [XFubenInfestorExploreConfigs.Region.UpRegion] = CSXTextManagerGetText("ArenaActivityUpRegionColor"),
    [XFubenInfestorExploreConfigs.Region.KeepRegion] = CSXTextManagerGetText("ArenaActivityKeepRegionColor"),
    [XFubenInfestorExploreConfigs.Region.DownRegion] = CSXTextManagerGetText("ArenaActivityDownRegionColor"),
}

function XFubenInfestorExploreConfigs.GetRankRegionColorText(rankRegion)
    return RankRegionColorText[rankRegion]
end

function XFubenInfestorExploreConfigs.GetRankRegionMailId(groupId, diff, rankRegion)
    local config = GetGroupDiffConfig(groupId, diff)
    if rankRegion == XFubenInfestorExploreConfigs.Region.UpRegion then
        return config.UpMailId
    elseif rankRegion == XFubenInfestorExploreConfigs.Region.DownRegion then
        return config.DownMailId
    else
        return config.KeepMailId
    end
end

function XFubenInfestorExploreConfigs.GetCoreIcon(coreId)
    return GetCoreConfig(coreId).Icon
end

function XFubenInfestorExploreConfigs.GetCoreQuality(coreId)
    return GetCoreConfig(coreId).Quality
end

--获得等级
function XFubenInfestorExploreConfigs.GetCoreQualityIcon(coreId)
    return QualityIconPath[XFubenInfestorExploreConfigs.GetCoreQuality(coreId)]
end

function XFubenInfestorExploreConfigs.GetCoreMaxLevel(coreId)
    return GetCoreConfig(coreId).MaxLevel
end

function XFubenInfestorExploreConfigs.GetCoreName(coreId)
    return GetCoreConfig(coreId).Name
end

function XFubenInfestorExploreConfigs.GetCoreLevelDes(coreId, level)
    return GetCoreLevelConfig(coreId, level).Description
end

function XFubenInfestorExploreConfigs.GetCoreDecomposeMoney(coreId, level)
    return GetCoreLevelConfig(coreId, level).DecomposeMoney
end

function XFubenInfestorExploreConfigs.GetSupplyRewardDesTotalNum()
    return #SupplyRewardTemplate
end

function XFubenInfestorExploreConfigs.GetSupplyRewardDes(index)
    return SupplyRewardTemplate[index].Description or ""
end

function XFubenInfestorExploreConfigs.GetShopRefreshCost(shopId)
    return GetShopConfig(shopId).RefreshCost
end

function XFubenInfestorExploreConfigs.GetGoodsCost(goodsId)
    return GetShopGoodsConfig(goodsId).Cost
end

function XFubenInfestorExploreConfigs.GetGoodsCoreId(goodsId)
    return GetShopGoodsConfig(goodsId).CoreId
end

function XFubenInfestorExploreConfigs.GetGoodsCoreLevel(goodsId)
    return GetShopGoodsConfig(goodsId).CoreLevel
end

function XFubenInfestorExploreConfigs.GetGoodsLimitCount(goodsId)
    return GetShopGoodsConfig(goodsId).LimitCount or 0
end

function XFubenInfestorExploreConfigs.GetGoodsName(goodsId)
    local coreId = XFubenInfestorExploreConfigs.GetGoodsCoreId(goodsId)
    return XFubenInfestorExploreConfigs.GetCoreName(coreId)
end

function XFubenInfestorExploreConfigs.GetRewardCoreId(rewardId)
    return GetRewardConfig(rewardId).CoreId
end

function XFubenInfestorExploreConfigs.GetRewardCoreLevel(rewardId)
    return GetRewardConfig(rewardId).CoreLevel
end

function XFubenInfestorExploreConfigs.GetEventGoodsCost(eventId)
    return GetEventGoodsConfig(eventId).Cost
end

function XFubenInfestorExploreConfigs.GetFightRewardCost(buyTimes)
    return GetFightRewardCostConfig(buyTimes).Cost
end

function XFubenInfestorExploreConfigs.GetActivityConfigs()
    return ActivityTemplate
end

function XFubenInfestorExploreConfigs.GetChapter2StageIds(activityId)
    return GetActivityConfig(activityId).BossStageId
end

function XFubenInfestorExploreConfigs.GetOutPostDesPoolIds(key)
    return GetOutPostDesConfig(key).PoolId
end

function XFubenInfestorExploreConfigs.GetScoreRuleConfig(stageId)
    return GetScoreRuleConfig(stageId)
end

local RandomInterver = 0
function XFubenInfestorExploreConfigs.GetRandomOutPostDes(poolId)
    local desList = GetOutPostDesPoolDesList(poolId)

    local totalDesNum = #desList
    RandomInterver = RandomInterver + 100
    math.randomseed(os.time() + RandomInterver)
    local ret = math.random(totalDesNum)

    return desList[ret]
end

function XFubenInfestorExploreConfigs.GetEventTypeTipContent(eventType, eventArgs)
    local des = GetEventTypeConfig(eventType).Description

    if eventType == XFubenInfestorExploreConfigs.EventType.LostCore then
        local coreId = eventArgs and eventArgs[1]
        if not XDataCenter.FubenInfestorExploreManager.IsHaveCore(coreId) then
            return GetEventTypeConfig(eventType).DescriptionEmpty
        end
        local coreName = XFubenInfestorExploreConfigs.GetCoreName(coreId)
        return stringFormat(des, coreName)
    elseif eventType == XFubenInfestorExploreConfigs.EventType.ChangeTeamHpPer then
        local hpPer = tableUnpack(eventArgs)
        if hpPer < 0 then
            des = GetEventTypeConfig(eventType).DescriptionRevert
            hpPer = -hpPer
        end
        return stringFormat(des, hpPer)
    elseif eventType == XFubenInfestorExploreConfigs.EventType.ChangeCharacterHpPer then
        local hpPer, characterId = tableUnpack(eventArgs)
        local characterName = XCharacterConfigs.GetCharacterFullNameStr(characterId)
        if hpPer < 0 then
            hpPer = -hpPer
            des = GetEventTypeConfig(eventType).DescriptionRevert
        end
        return stringFormat(des, characterName, hpPer)
    elseif eventType == XFubenInfestorExploreConfigs.EventType.ChangeMoneyPer
    or eventType == XFubenInfestorExploreConfigs.EventType.ChangeMoney
    or eventType == XFubenInfestorExploreConfigs.EventType.ChangeMoneyRandom then
        local addMoney = eventArgs and eventArgs[1]
        if not addMoney or addMoney == 0 then
            des = GetEventTypeConfig(eventType).DescriptionEmpty
            return stringFormat(des, 0)
        end
        if addMoney < 0 then
            addMoney = -addMoney
            if XDataCenter.FubenInfestorExploreManager.IsMoneyEmpty() then
                des = GetEventTypeConfig(eventType).DescriptionEmpty
                local oldMoney = XDataCenter.FubenInfestorExploreManager.GetOldMoneyCount()
                return stringFormat(des, oldMoney)
            end
            des = GetEventTypeConfig(eventType).DescriptionRevert
        end
        return stringFormat(des, addMoney)
    elseif eventType == XFubenInfestorExploreConfigs.EventType.ChangeActionPoint then
        local addActionPoint = eventArgs and eventArgs[1]
        if not addActionPoint or addActionPoint == 0 then
            return GetEventTypeConfig(eventType).DescriptionEmpty
        end
        if addActionPoint < 0 then
            addActionPoint = -addActionPoint
            if XDataCenter.FubenInfestorExploreManager.IsActionPointEmpty() then
                return GetEventTypeConfig(eventType).DescriptionEmpty
            end
            des = GetEventTypeConfig(eventType).DescriptionRevert
        end
        return stringFormat(des, addActionPoint)
    elseif eventType == XFubenInfestorExploreConfigs.EventType.AddBuff then
        local buffId = eventArgs and eventArgs[1]
        if buffId then
            local buffName = XFubenInfestorExploreConfigs.GetBuffName(buffId)
            return stringFormat(des, buffName)
        end
    elseif eventType == XFubenInfestorExploreConfigs.EventType.RemoveBuff then
        local buffIds = eventArgs
        if not buffIds then
            return GetEventTypeConfig(eventType).DescriptionEmpty
        end
        for _, buffId in pairs(buffIds) do
            if XDataCenter.FubenInfestorExploreManager.CheckBuffExsit(buffIds) then
                return des
            end
        end
    elseif eventType == XFubenInfestorExploreConfigs.EventType.LevelUpCore then
        if not eventArgs then
            if XDataCenter.FubenInfestorExploreManager.IsHaveOnceCore() then
                return GetEventTypeConfig(eventType).DescriptionRevert
            else
                return GetEventTypeConfig(eventType).DescriptionEmpty
            end
        end
        return ""
    end

    return stringFormat(des, tableUnpack(eventArgs))
end

--判断奖励的等级
function XFubenInfestorExploreConfigs.IsPrecious(quality)
    if quality >= QualityLevel.Gold then
        return true
    end
end

XFubenInfestorExploreConfigs.GetGroupDiffConfigs = GetGroupDiffConfigs