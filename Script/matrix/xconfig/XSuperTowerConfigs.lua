--===========================
--超级爬塔配置读写
--模块负责：吕天元，陈思亮，张爽
--===========================
XSuperTowerConfigs = XSuperTowerConfigs or {}
------------------------------------------------------------------
--                         配置表地址                            --
------------------------------------------------------------------
local SHARE_TABLE_PATH = "Share/Fuben/SuperTower/"
local SHARE_CHARACTER_TABLE_PATH = "Share/Fuben/SuperTower/Character/"
local CLIENT_TABLE_PATH = "Client/Fuben/SuperTower/"

local TABLE_ACTIVITY = SHARE_TABLE_PATH .. "SuperTowerActivity.tab"
local TABLE_CONFIG = SHARE_TABLE_PATH .. "SuperTowerCfg.tab"
local TABLE_MAP = SHARE_TABLE_PATH .. "SuperTowerMap.tab"
local TABLE_PLUGIN = SHARE_TABLE_PATH .. "SuperTowerPlugin.tab"
local TABLE_PLUGIN_DROP = CLIENT_TABLE_PATH .. "SuperTowerPluginDrop.tab"
local TABLE_ENHANCE_DROP = CLIENT_TABLE_PATH .. "SuperTowerEnhanceDrop.tab"
local TABLE_ENHANCER = SHARE_TABLE_PATH .. "SuperTowerEnhancer.tab"
--local TABLE_ENHANCER_DROP = SHARE_TABLE_PATH .. "SuperTowerEnhancerDrop.tab"
local TABLE_MALL = SHARE_TABLE_PATH .. "SuperTowerMall.tab"
local TABLE_MALL_PLUGIN = SHARE_TABLE_PATH .. "SuperTowerMallPlugin.tab"
local TABLE_TARGET_STAGE = SHARE_TABLE_PATH .. "SuperTowerTargetStage.tab"
local TABLE_TIER_STAGE = SHARE_TABLE_PATH .. "SuperTowerTier.tab"
local TABLE_TIER_ENHANCER_AND_DROP = CLIENT_TABLE_PATH .. "SuperTowerTierEnhancerAndDrop.tab"
local TABLE_TIER_SCORE_RATIO = CLIENT_TABLE_PATH .. "SuperTowerTierScoreRatio.tab"
local TABLE_STAR_ICON = CLIENT_TABLE_PATH .. "SuperTowerStarIcon.tab"
local TABLE_CHARACTER_LEVEL = SHARE_TABLE_PATH .. "Character/SuperTowerCharacterLevel.tab"
local TABLE_FUNCTION = CLIENT_TABLE_PATH .. "SuperTowerFunction.tab"
local TABLE_GRANT_ROBOT = SHARE_TABLE_PATH .. "SuperTowerRobot.tab"
local TABLE_CHARACTER_PLUGIN = SHARE_CHARACTER_TABLE_PATH .. "SuperTowerCharacterExclusive.tab"
local TABLE_CHARACTER_INDULT = SHARE_CHARACTER_TABLE_PATH .. "SuperTowerIndultCharacter.tab"
local TABLE_CLIENT_CONFIG = CLIENT_TABLE_PATH .. "SuperTowerClientCfg.tab"
local TABLE_STAGE_ELEMENT = CLIENT_TABLE_PATH .. "SuperTowerStageElement.tab"
local TABLE_MAP_EFFECT = CLIENT_TABLE_PATH .. "SuperTowerMapEffect.tab"
------------------------------------------------------------------
--                         配置表数据                            --
------------------------------------------------------------------
local BaseConfigs = {} -- 超级爬塔基础配置 TABLE_CONFIG
local ActivityConfigs = {} -- 活动配置表 TABLE_ACTIVITY
local ThemeConfigs = {} -- 主题配置表 TABLE_MAP
local TargetStageConfigs = {} -- 普通关卡配置表 TABLE_TARGET_STAGE
local TierStageConfigs = {} -- 爬塔关卡(层)配置表 TABLE_TIER_STAGE
local TierEnDConfigs = {} -- (客户端表)爬塔增益与插件掉落展示配置表 TABLE_TIER_ENHANCER_AND_DROP
local TierScoreRatioConfigs = {} -- (客户端表)爬塔结算分数系数配置表 TABLE_TIER_SCORE_RATIO
local PluginConfigs = {} -- 插件配置表 TABLE_PLUGIN
local PluginDropConfigs = {} -- (客户端表)插件掉落表 TABLE_PLUGIN_DROP
local EnhanceDropConfigs = {} -- (客户端表)增益掉落表 TABLE_ENHANCE_DROP
local StarIconConfigs = {} --(客户端表)星级图标表 TABLE_STAR_ICON
local CharacterId2LevelConfigs = {} -- 角色Id映射等级培养配置 TABLE_CHARACTER_LEVEL
local FunctionConfigs = {} --(客户端表)特权表 TABLE_FUNCTION
local GrantRobotConfigs = {} -- 机器人发放配置 TABLE_GRANT_ROBOT
local CharacterPluginConfigs = {} -- 角色专属插件配置 TABLE_CHARACTER_PLUGIN
local CharacterInDultConfigs = {} -- 角色特典配置 TABLE_CHARACTER_INDULT
local ClientConfigs = {} -- (客户端表)客户端基础配置 TABLE_CLIENT_CONFIG
local EnhanceConfigs = {} -- 爬塔增益表 TABLE_ENHANCER
local StageElementConfigs = {} -- 目标关卡倾向属性 TABLE_STAGE_ELEMENT
local MallConfig = {}   --商店配置 TABLE_MALL
local MallPluginConfig = {} --商店插件信息配置 TABLE_MALL_PLUGIN
local MapEffectConfig = {} --地图特效配置 TABLE_MAP_EFFECT
local CharacterSpecialPluginIdDic = {} -- 角色专属槽插件id字典 TABLE_CHARACTER_PLUGIN
------------------------------------------------------------------
--                         搜索用字典                            --
------------------------------------------------------------------
local Theme2TargetStageDic = {} -- 主题Id<->目标字典
local Theme2TierStageDic = {} -- 主题Id<->爬塔关卡字典
local CharacterId2PluginDic = {} -- 角色Id<->绑定插件字典
local WithOutCharacterPluginList = {} -- 非绑定角色插件列表
local CharacterId2MaxLevelConfig = {} -- 角色Id对应最大超限等级
local CharacterId2InDultConfigs = {} -- 特典角色配置 TABLE_CHARACTER_INDULT
local DropGroupId2EnhanceIdListDic = {} -- 掉落组ID<->增益ID列表字典
local DropGroupId2PluginIdListDic = {} -- 掉落组ID<->插件ID列表字典
------------------------------------------------------------------
--                         逻辑定义                            --
------------------------------------------------------------------
XSuperTowerConfigs.MaxMultiTeamCount = 5 -- 多队伍关卡最大多队伍数量
------------------------------------------------------------------
--                      关卡配置初始化方法                        --
------------------------------------------------------------------
--===================
--创建主题ID<->普通关卡字典
--===================
local CreateTheme2TargetStageDic = function()
    for _, cfg in pairs(TargetStageConfigs) do
        if not Theme2TargetStageDic[cfg.MapId] then
            Theme2TargetStageDic[cfg.MapId] = {}
        end
        table.insert(Theme2TargetStageDic[cfg.MapId], cfg)
    end
end
--===================
--创建主题ID<->爬塔关卡字典
--===================
local CreateTheme2TierStageDic = function()
    for _, cfg in pairs(TierStageConfigs) do
        if not Theme2TierStageDic[cfg.MapId] then
            Theme2TierStageDic[cfg.MapId] = {}
        end
        Theme2TierStageDic[cfg.MapId][cfg.Tier] = cfg
    end
end
--===================
--初始化关卡配置表和关系字典
--===================
local InitStageCfgs = function()
    ThemeConfigs = XTableManager.ReadByIntKey(TABLE_MAP, XTable.XTableSuperTowerMap, "Id")
    TargetStageConfigs = XTableManager.ReadByIntKey(TABLE_TARGET_STAGE, XTable.XTableSuperTowerTargetStage, "Id")
    TierStageConfigs = XTableManager.ReadByIntKey(TABLE_TIER_STAGE, XTable.XTableSuperTowerTier, "Id")
    CreateTheme2TargetStageDic()
    CreateTheme2TierStageDic()
end
--===================
--创建增益掉落组相关字典
--===================
local CreateEnhanceDropGroupId2Dic = function()
    for _, cfg in pairs(EnhanceDropConfigs) do
        if not DropGroupId2EnhanceIdListDic[cfg.EnhancerDropGroupId] then
            DropGroupId2EnhanceIdListDic[cfg.EnhancerDropGroupId] = {}
        end
        table.insert(DropGroupId2EnhanceIdListDic[cfg.EnhancerDropGroupId], cfg.DropEnhanceId)
    end
end
--===================
--初始化爬塔相关配置
--===================
local InitTierCfgs = function()
    EnhanceConfigs = XTableManager.ReadByIntKey(TABLE_ENHANCER, XTable.XTableSuperTowerEnhancer, "Id")
    EnhanceDropConfigs = XTableManager.ReadByIntKey(TABLE_ENHANCE_DROP, XTable.XTableSuperTowerEnhanceDrop, "Id")
    TierEnDConfigs = XTableManager.ReadByIntKey(TABLE_TIER_ENHANCER_AND_DROP, XTable.XTableSuperTowerTierEnhancerAndDrop, "Id")
    TierScoreRatioConfigs = XTableManager.ReadByIntKey(TABLE_TIER_SCORE_RATIO, XTable.XTableSuperTowerTierScoreRatio, "Id")
    CreateEnhanceDropGroupId2Dic()
end
--===================
--初始化角色ID<->插件关系字典与列表
--===================
local CreateCharacterIdPluginRelative = function()
    for _, plugin in pairs(PluginConfigs) do
        if plugin.CharacterId and plugin.CharacterId > 0 then
            if not CharacterId2PluginDic[plugin.CharacterId] then
                CharacterId2PluginDic[plugin.CharacterId] = {}
            end
            CharacterId2PluginDic[plugin.CharacterId][plugin.Id] = plugin
        else
            WithOutCharacterPluginList[plugin.Id] = plugin
        end
    end
end
--===================
--创建插件掉落组相关字典
--===================
local CreatePluginDropGroupId2Dic = function()
    for _, cfg in pairs(PluginDropConfigs) do
        if not DropGroupId2PluginIdListDic[cfg.PluginsDropGroupId] then
            DropGroupId2PluginIdListDic[cfg.PluginsDropGroupId] = {}
        end
        table.insert(DropGroupId2PluginIdListDic[cfg.PluginsDropGroupId], cfg.DropPlugins)
    end
end
--===================
--初始化插件相关配置
--===================
local InitPluginCfgs = function()
    PluginConfigs = XTableManager.ReadByIntKey(TABLE_PLUGIN, XTable.XTableSuperTowerPlugin, "Id")
    PluginDropConfigs = XTableManager.ReadByIntKey(TABLE_PLUGIN_DROP, XTable.XTableSuperTowerPluginDrop, "Id")
    StarIconConfigs = XTableManager.ReadByIntKey(TABLE_STAR_ICON, XTable.XTableSuperTowerStarIcon, "Quality")
    CreateCharacterIdPluginRelative()
    CreatePluginDropGroupId2Dic()
end
--===================
--初始化角色相关配置
--===================
local InitCharacterCfgs = function()
    local characterLevelConfigs = XTableManager.ReadByIntKey(TABLE_CHARACTER_LEVEL, XTable.XTableSuperTowerCharacterLevel, "Id")
    local characterId2LevelConfigs = {}
    for id, config in pairs(characterLevelConfigs) do
        characterId2LevelConfigs[config.CharacterId] = characterId2LevelConfigs[config.CharacterId] or {}
        characterId2LevelConfigs[config.CharacterId][config.Level] = config
        -- 最大等级映射
        CharacterId2MaxLevelConfig[config.CharacterId] = CharacterId2MaxLevelConfig[config.CharacterId] or 0
        CharacterId2MaxLevelConfig[config.CharacterId] = math.max(CharacterId2MaxLevelConfig[config.CharacterId], config.Level)
    end
    CharacterId2LevelConfigs = characterId2LevelConfigs
    GrantRobotConfigs = XTableManager.ReadByIntKey(TABLE_GRANT_ROBOT, XTable.XTableSuperTowerRobot, "Id")
    CharacterPluginConfigs = XTableManager.ReadByIntKey(TABLE_CHARACTER_PLUGIN, XTable.XTableSuperTowerCharacterExclusive, "Id")
    for _, config in pairs(CharacterPluginConfigs) do
        CharacterSpecialPluginIdDic[config.ActivatePlugin] = true
    end
    -- 特典角色配置，改成根据角色id获取配置信息
    CharacterInDultConfigs = XTableManager.ReadByIntKey(TABLE_CHARACTER_INDULT, XTable.XTableSuperTowerIndultCharacter, "Id")
    for _, config in pairs(CharacterInDultConfigs) do
        for _, characterId in ipairs(config.CharacterId) do
            -- 这里是为了每个id有配置重复的角色，因此角色id是对应配置数组
            CharacterId2InDultConfigs[characterId] = CharacterId2InDultConfigs[characterId] or {}
            table.insert(CharacterId2InDultConfigs[characterId], config)
        end
    end
end
--=============
--初始化
--=============
function XSuperTowerConfigs.Init()
    BaseConfigs = XTableManager.ReadByStringKey(TABLE_CONFIG, XTable.XTableSuperTowerCfg, "Key")
    ActivityConfigs = XTableManager.ReadByIntKey(TABLE_ACTIVITY, XTable.XTableSuperTowerActivity, "Id")
    ClientConfigs = XTableManager.ReadByStringKey(TABLE_CLIENT_CONFIG, XTable.XTableSuperTowerClientCfg, "Key")
    FunctionConfigs = XTableManager.ReadByStringKey(TABLE_FUNCTION, XTable.XTableSuperTowerFunction, "Key")
    StageElementConfigs = XTableManager.ReadByIntKey(TABLE_STAGE_ELEMENT, XTable.XTableSuperTowerStageElement, "Element")
    MallConfig = XTableManager.ReadByIntKey(TABLE_MALL, XTable.XTableSuperTowerMall, "Id")
    MallPluginConfig = XTableManager.ReadByIntKey(TABLE_MALL_PLUGIN, XTable.XTableSuperTowerMallPlugin, "Id")
    MapEffectConfig = XTableManager.ReadByIntKey(TABLE_MAP_EFFECT, XTable.XTableSuperTowerMapEffect, "ThemeId")
    InitStageCfgs()
    InitTierCfgs()
    InitPluginCfgs()
    InitCharacterCfgs()
end
------------------------------------------------------------------
--                           配置表读取                          --
------------------------------------------------------------------
--=============
--根据键值获取基础配置
--@param key:配置项键值,XSuperTowerConfigs.BaseCfgKey
--=============
function XSuperTowerConfigs.GetBaseConfigByKey(key)
    if (not key) or (not BaseConfigs[key]) then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetBaseConfigByKey",
        "基础配置_Cfg",
        TABLE_CONFIG,
        "Key",
        tostring(key))
        return
    end
    return BaseConfigs[key].Value
end
--=============
--根据键值获取客户端基础配置
--@param key:配置项键值,XSuperTowerConfigs.BaseCfgKey
--=============
function XSuperTowerConfigs.GetClientBaseConfigByKey(key, noTips)
    if (not key) or (not ClientConfigs[key]) then
        if not noTips then
            XLog.ErrorTableDataNotFound(
            "XSuperTowerConfigs.GetClientBaseConfigByKey",
            "Client基础配置_ClientCfg",
            TABLE_CLIENT_CONFIG,
            "Key",
            tostring(key))
        end
        return
    end
    return ClientConfigs[key].Value
end
--=============
--根据活动ID获取活动配置
--@param activityId:活动表Id
--@param noTips:默认false，会打印错误日志。true不会打出错误日志。
--=============
function XSuperTowerConfigs.GetActivityById(activityId, noTips)
    if not ActivityConfigs[activityId] then
        if not noTips then
            XLog.ErrorTableDataNotFound(
            "XSuperTowerConfigs.GetActivityById",
            "活动配置_Activity",
            TABLE_ACTIVITY,
            "Id",
            tostring(activityId))
        end
        return nil
    end
    return ActivityConfigs[activityId]
end
--=============
--通过当前配置了TimeId的活动ID获取活动配置(只能有一个活动配有TimeId)
--=============
function XSuperTowerConfigs.GetCurrentActivity()
    for _, cfg in pairs(ActivityConfigs) do
        if cfg.TimeId and cfg.TimeId > 0 then
            return cfg
        end
    end
    --XLog.Error("XSuperTowerConfigs.GetCurrentActivity:没有任何一项配置了TimeId！请检查表格：" .. TABLE_ACTIVITY)
    return nil
end
--=============
--根据主题ID获取主题配置
--@param themeId:主题表Id
--@param noTips:默认false，会打印错误日志。true不会打出错误日志。
--=============
function XSuperTowerConfigs.GetThemeById(themeId, noTips)
    if not ThemeConfigs[themeId] then
        if not noTips then
            XLog.ErrorTableDataNotFound(
            "XSuperTowerConfigs.GetThemeById",
            "主题配置_Map",
            TABLE_MAP,
            "Id",
            tostring(themeId))
        end
        return nil
    end
    return ThemeConfigs[themeId]
end
--=============
--根据目标关卡表Id获取关卡配置
--@param targetStageId:目标关卡表Id
--@param noTips:默认false，会打印错误日志。true不会打出错误日志。
--=============
function XSuperTowerConfigs.GetTargetStageById(targetStageId, noTips)
    if not TargetStageConfigs[targetStageId] then
        if not noTips then
            XLog.ErrorTableDataNotFound(
            "XSuperTowerConfigs.GetTargetStageById",
            "目标关卡配置_TargetStage",
            TABLE_TARGET_STAGE,
            "Id",
            tostring(targetStageId))
        end
        return nil
    end
    return TargetStageConfigs[targetStageId]
end
--=============
--根据主题ID获取该主题下的普通关卡配置
--@param themeId:主题表Id
--@param noTips:默认false，会打印错误日志。true不会打出错误日志。
--=============
function XSuperTowerConfigs.GetTargetStagesByThemeId(themeId, noTips)
    if not Theme2TargetStageDic[themeId] then
        if not noTips then
            XLog.ErrorTableDataNotFound(
            "XSuperTowerConfigs.GetTargetStagesByThemeId",
            "目标关卡配置_TargetStage",
            TABLE_TARGET_STAGE,
            "MapId",
            tostring(themeId))
        end
        return nil
    end
    return Theme2TargetStageDic[themeId]
end
--=============
--根据爬塔关卡表Id获取关卡配置
--@param tierStageId:爬塔关卡表Id
--@param noTips:默认false，会打印错误日志。true不会打出错误日志。
--=============
function XSuperTowerConfigs.GetTierStageById(tierStageId, noTips)
    if not TierStageConfigs[tierStageId] then
        if not noTips then
            XLog.ErrorTableDataNotFound(
            "XSuperTowerConfigs.GetTierStageById",
            "爬塔关卡配置_TierStage",
            TABLE_TIER_STAGE,
            "Id",
            tostring(tierStageId))
        end
        return nil
    end
    return TierStageConfigs[tierStageId]
end
--=============
--根据主题ID获取该主题下的爬塔关卡配置
--@param themeId:主题表Id
--@param noTips:默认false，会打印错误日志。true不会打出错误日志。
--=============
function XSuperTowerConfigs.GetTierStagesByThemeId(themeId, noTips)
    if not Theme2TierStageDic[themeId] then
        if not noTips then
            XLog.ErrorTableDataNotFound(
            "XSuperTowerConfigs.GetTierStagesByThemeId",
            "爬塔关卡配置_Tier",
            TABLE_TIER_STAGE,
            "MapId",
            tostring(themeId))
        end
        return nil
    end
    return Theme2TierStageDic[themeId]
end
--=============
--根据增益ID获取增益配置
--@param enhanceId:增益Id
--@param noTips:默认false，会打印错误日志。true不会打出错误日志。
--=============
function XSuperTowerConfigs.GetEnhanceCfgById(enhanceId, noTips)
    if not EnhanceConfigs[enhanceId] then
        if not noTips then
            XLog.ErrorTableDataNotFound(
            "XSuperTowerConfigs.GetEnhanceCfgById",
            "爬塔增益配置_Enhancer",
            TABLE_ENHANCER,
            "Id",
            tostring(enhanceId))
        end
        return nil
    end
    return EnhanceConfigs[enhanceId]
end
--=============
--根据主题Id获取主题爬塔收益配置
--@param themeId:主题Id
--@param noTips:默认false，会打印错误日志。true不会打出错误日志。
--=============
function XSuperTowerConfigs.GetEnDConfigByThemeId(themeId, noTips)
    if not TierEnDConfigs[themeId] then
        if not noTips then
            XLog.ErrorTableDataNotFound(
            "XSuperTowerConfigs.GetEnDConfigByThemeId",
            "爬塔收益配置_TierEnhancerAndDrop",
            TABLE_TIER_ENHANCER_AND_DROP,
            "Id",
            tostring(themeId))
        end
        return nil
    end
    return TierEnDConfigs[themeId]
end
--=============
--获取没有绑定角色的插件列表
--=============
function XSuperTowerConfigs.GetWithOutCharacterPluginCfg()
    return WithOutCharacterPluginList
end
--=============
--获取所有插件配置
--=============
function XSuperTowerConfigs.GetAllPluginCfgs()
    return PluginConfigs
end
--=============
--根据插件ID获取插件配置
--@param pluginId:插件Id
--@param noTips:默认false，会打印错误日志。true不会打出错误日志。
--=============
function XSuperTowerConfigs.GetPluginCfgById(pluginId, noTips)
    if not PluginConfigs[pluginId] then
        if not noTips then
            XLog.ErrorTableDataNotFound(
            "XSuperTowerConfigs.GetPluginCfgById",
            "插件配置_Plugin",
            TABLE_PLUGIN,
            "Id",
            tostring(pluginId))
        end
        return nil
    end
    return PluginConfigs[pluginId]
end
--=============
--根据角色ID获取绑定该角色的插件列表
--=============
function XSuperTowerConfigs.GetPluginCfgsByCharacterId(characterId)
    return CharacterId2PluginDic[characterId] or {}
end
--=============
--根据掉落组Id获取插件掉落配置
--@param dropId:掉落组Id
--=============
function XSuperTowerConfigs.GetPluginDropByDropId(dropId)
    if not PluginDropConfigs[dropId] then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetPluginDropByDropId",
        "插件掉落配置_PluginDrop",
        TABLE_PLUGIN_DROP,
        "Id",
        tostring(dropId))
    end
    return PluginDropConfigs[dropId]
end
--=============
--根据星数获取星数图标地址
--@param quality:星数
--=============
function XSuperTowerConfigs.GetStarIconByQuality(quality)
    if not StarIconConfigs[quality] then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetStarIconByStar",
        "星级图标配置_StarIcon",
        TABLE_STAR_ICON,
        "Quality",
        tostring(quality))
    end
    return StarIconConfigs[quality].Icon
end
--=============
--根据星数获取星数图标地址
--@param quality:星数
--=============
function XSuperTowerConfigs.GetStarBgByQuality(quality)
    if not StarIconConfigs[quality] then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetStarIconByStar",
        "星级图标配置_StarIcon",
        TABLE_STAR_ICON,
        "Quality",
        tostring(quality))
    end
    return StarIconConfigs[quality].Bg
end
--=============
--根据角色id和等级获取角色等级培养配置
--=============
function XSuperTowerConfigs.GetCharacterLevelConfig(characterId, level, noTips)
    if not CharacterId2LevelConfigs[characterId] then
        if noTips then return end
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetCharacterLevelConfig",
        "角色等级培养配置_CharacterId",
        TABLE_CHARACTER_LEVEL,
        "CharacterId",
        tostring(characterId))
    end
    if not CharacterId2LevelConfigs[characterId][level] then
        if noTips then return end
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetCharacterLevelConfig",
        "角色等级培养配置_Level",
        TABLE_CHARACTER_LEVEL,
        "Level",
        tostring(level))
    end
    return CharacterId2LevelConfigs[characterId][level]
end
--=============
--获取所有特权配置
--=============
function XSuperTowerConfigs.GetAllFunctionCfgs()
    return FunctionConfigs
end
--=============
--根据键值获取特权配置
--@param key:键值
--=============
function XSuperTowerConfigs.GetFunctionCfgByKey(key)
    if not FunctionConfigs[key] then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetFunctionCfgByKey",
        "特权配置_Function",
        TABLE_FUNCTION,
        "Key",
        tostring(key))
    end
    return FunctionConfigs[key]
end
--=============
--获取所有目标关卡属性配置
--=============
function XSuperTowerConfigs.GetStageElementCfgs()
    return StageElementConfigs
end
--=============
--根据属性ID获取目标关卡属性配置
--@param element:属性ID
--=============
function XSuperTowerConfigs.GetStageElementCfgByKey(element)
    if not StageElementConfigs[element] then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetStageElementCfgByKey",
        "目标关卡属性_StageElement",
        TABLE_STAGE_ELEMENT,
        "Element",
        tostring(element))
    end
    return StageElementConfigs[element]
end
--=============
--根据属性ID获取目标关卡属性图标
--@param element:属性ID
--=============
function XSuperTowerConfigs.GetElementIconByKey(element)
    return XSuperTowerConfigs.GetStageElementCfgByKey(element).StageElementIcon
end
--=============
--获取所有地图特效配置
--=============
function XSuperTowerConfigs.GetMapEffectCfgs()
    return MapEffectConfig
end
--=============
--根据主题ID获取地图特效配置
--@param themeId:主题ID
--=============
function XSuperTowerConfigs.GetMapEffectCfgByKey(themeId)
    if not MapEffectConfig[themeId] then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetMapEffectCfgByKey",
        "地图特效_MapEffect",
        TABLE_MAP_EFFECT,
        "themeId",
        tostring(themeId))
    end
    return MapEffectConfig[themeId]
end
--=============
--获取机器人发放配置数据
--=============
function XSuperTowerConfigs.GetGrantRobotConfigs()
    return GrantRobotConfigs
end
--=============
--根据id获取机器人发放配置数据
--=============
function XSuperTowerConfigs.GetGrantRobotConfig(id)
    if not GrantRobotConfigs[id] then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetGrantRobotConfig",
        "发放机器人配置_Id",
        TABLE_GRANT_ROBOT,
        "Id",
        tostring(id))
    end
    return GrantRobotConfigs[id]
end
--=============
--根据角色id获取专属插件配置
--=============
function XSuperTowerConfigs.GetCharacterPluginConfig(id)
    if not CharacterPluginConfigs[id] then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetCharacterPlugin",
        "角色专属插件_Id",
        TABLE_CHARACTER_PLUGIN,
        "Id",
        tostring(id))
    end
    return CharacterPluginConfigs[id]
end
--=============
--根据角色id获取特典配置信息数组，返回数组的原因是防止策划配置重复的角色Id
--=============
function XSuperTowerConfigs.GetCharacterInDultConfigs(id)
    -- if not CharacterId2InDultConfigs[id] then  
    --     XLog.ErrorTableDataNotFound(
    --         "XSuperTowerConfigs.GetCharacterInDultConfigs",
    --         "特典角色配置_Id",
    --         TABLE_CHARACTER_INDULT,
    --         "Id",
    --         tostring(id))
    -- end
    return CharacterId2InDultConfigs[id]
end
--=============
--根据角色id获取最大超限等级
--=============
function XSuperTowerConfigs.GetCharacterMaxLevel(id)
    if not CharacterId2MaxLevelConfig[id] then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetCharacterMaxLevel",
        "角色超限最大等级_Id",
        TABLE_CHARACTER_LEVEL,
        "Id",
        tostring(id))
    end
    return CharacterId2MaxLevelConfig[id]
end
--=============
--获取所有角色特典配置
--=============
function XSuperTowerConfigs.GetAllCharacterInDultConfigs()
    return CharacterInDultConfigs
end
--=============
--获取所有爬塔关卡分数配置
--=============
function XSuperTowerConfigs.GetAllTierScoreRatioCfg()
    return TierScoreRatioConfigs
end
--=============
--根据Id获取爬塔关卡分数配置
--=============
function XSuperTowerConfigs.GetTierScoreRatioCfgById(id)
    if not TierScoreRatioConfigs[id] then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetTierScoreRatioCfgById",
        "超级爬塔爬塔关卡分数配置_Id",
        TABLE_TIER_SCORE_RATIO,
        "Id",
        tostring(id))
    end
    return TierScoreRatioConfigs[id]
end
--=============
--根据掉落组Id获取超级爬塔增益掉落展示Id列表
--=============
function XSuperTowerConfigs.GetEnhanceIdListByGroupId(id)
    if not DropGroupId2EnhanceIdListDic[id] then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetEnhanceIdListByGroupId",
        "超级爬塔增益掉落展示配置_EnhancerDropGroupId",
        TABLE_ENHANCE_DROP,
        "EnhancerDropGroupId",
        tostring(id))
        return
    end
    return DropGroupId2EnhanceIdListDic[id]
end
--=============
--根据掉落组Id获取超级爬塔插件掉落展示Id列表
--=============
function XSuperTowerConfigs.GetPluginIdListByGroupId(id)
    if not DropGroupId2PluginIdListDic[id] then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetPluginIdListByGroupId",
        "超级爬塔插件掉落展示配置_PluginsDropGroupId",
        TABLE_PLUGIN_DROP,
        "PluginsDropGroupId",
        tostring(id))
        return
    end
    return DropGroupId2PluginIdListDic[id]
end


--=============
--获取商店配置
--=============
function XSuperTowerConfigs.GetMallConfig(id)
    if not MallConfig[id] then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetMallConfig",
        "商店配置不存在",
        TABLE_MALL,
        "Id",
        tostring(id))
    end
    return MallConfig[id]
end
--=============
--获取商店插件配置
--=============
function XSuperTowerConfigs.GetMallPluginConfig(id)
    if not MallPluginConfig[id] then
        XLog.ErrorTableDataNotFound(
        "XSuperTowerConfigs.GetMallConfig",
        "商店插件配置不存在",
        TABLE_MALL,
        "Id",
        tostring(id))
    end
    return MallPluginConfig[id]
end
--=============
--获取资源物品id数组
--=============
function XSuperTowerConfigs.GetMainAssetsPanelItemIds()
    local itemIds = {}
    for i = 1, 3 do
        local itemId = XSuperTowerConfigs.GetClientBaseConfigByKey(XDataCenter.SuperTowerManager.BaseCfgKey["MainAssetsPanelItem" .. i], true)
        if itemId and itemId > 0 then
            table.insert(itemIds, itemId)
        end
    end
    return itemIds
end
--=============
--获取插件id是否属于角色专属槽插件
--=============
function XSuperTowerConfigs.GetPluginIdIsCharacterSlot(pluginId)
    return CharacterSpecialPluginIdDic[pluginId] or false
end