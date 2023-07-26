--==================
--成就系统相关配置表
--模块负责：吕天元
--==================
XAchievementConfigs = XAchievementConfigs or {}
--================================================================
--                         配置表地址                            --
--================================================================
local SHARE_TABLE_PATH = "Share/Achievement/"
local CLIENT_TABLE_PATH = "Client/Achievement/"

local TABLE_ACHIEVEMENT_BASETYPE = CLIENT_TABLE_PATH .. "AchievementBaseTypeInfo.tab"
local TABLE_ACHIEVEMENT_TYPE = CLIENT_TABLE_PATH .. "AchievementTypeInfo.tab"
--local TABLE_REVIEW_ACTIVITY_INFO = CLIENT_TABLE_PATH .. "ReviewActivityInfo.tab"
local TABLE_ACHIEVEMENT = SHARE_TABLE_PATH .. "Achievement.tab"
--local TABLE_REVIEW_ACTIVITY = SHARE_TABLE_PATH .. "ReviewActivity.tab"
--=================================================
--=================================================
local Configs = {}
--=============
--配置表枚举
--Id : 枚举Id
--Path : 关联的表地址 (日志中使用)
--Key : 要检查的字段名 (日志中使用)
--=============
XAchievementConfigs.TableKey = {
    AchievementBaseType = {Id = 1, Path = TABLE_ACHIEVEMENT_BASETYPE}, --成就基础类型配置
    AchievementType = {Id = 2, Path = TABLE_ACHIEVEMENT_TYPE}, --成就类型配置
    --ReviewActivityInfo = {Id = 3, Path = TABLE_REVIEW_ACTIVITY_INFO}, --回顾活动文本信息
    Achievement = {Id = 3, Path = TABLE_ACHIEVEMENT}, --成就表配置
    --ReviewActivity = {Id = 5, Path = TABLE_REVIEW_ACTIVITY}, --回顾活动配置
    Type2AchievementDic = {Id = 4, Path = TABLE_ACHIEVEMENT, Key = "AchievementTypeId"}, --
    BaseId2AchievementTypeDic = {Id = 5, Path = TABLE_ACHIEVEMENT_TYPE, Key = "BaseTypeId"}
}

--=============
--初始化BaseTypeId -> 成就类型字典
--=============
local InitBaseId2AchievementTypeDic = function()
    local tableId = XAchievementConfigs.TableKey.BaseId2AchievementTypeDic.Id
    Configs[tableId] = {}
    for _, cfg in pairs (XAchievementConfigs.GetAllConfigs(XAchievementConfigs.TableKey.AchievementType) or {}) do
        local id = cfg.BaseTypeId
        if not Configs[tableId][id] then Configs[tableId][id] = {} end
        table.insert(Configs[tableId][id], cfg)
    end
end
--=============
--初始化TypeId -> 成就类型字典
--=============
local InitType2AchievementDic = function()
    local tableId = XAchievementConfigs.TableKey.Type2AchievementDic.Id
    Configs[tableId] = {}
    for _, cfg in pairs (XAchievementConfigs.GetAllConfigs(XAchievementConfigs.TableKey.Achievement) or {}) do
        local id = cfg.AchievementTypeId
        if not Configs[tableId][id] then Configs[tableId][id] = {} end
        table.insert(Configs[tableId][id], cfg)
    end
end
--=============
--初始化所有配置表和字典
--=============
function XAchievementConfigs.Init()
    Configs[XAchievementConfigs.TableKey.AchievementBaseType.Id] = XTableManager.ReadByIntKey(TABLE_ACHIEVEMENT_BASETYPE, XTable.XTableAchievementBaseTypeInfo, "Id")
    Configs[XAchievementConfigs.TableKey.AchievementType.Id] = XTableManager.ReadByIntKey(TABLE_ACHIEVEMENT_TYPE, XTable.XTableAchievementTypeInfo, "Id")
    --Configs[XAchievementConfigs.TableKey.ReviewActivityInfo.Id] = XTableManager.ReadByStringKey(TABLE_REVIEW_ACTIVITY_INFO, XTable.XTableReviewActivityInfo, "Key")
    Configs[XAchievementConfigs.TableKey.Achievement.Id] = XTableManager.ReadByIntKey(TABLE_ACHIEVEMENT, XTable.XTableAchievement, "Id")
    --Configs[XAchievementConfigs.TableKey.ReviewActivity.Id] = XTableManager.ReadByIntKey(TABLE_REVIEW_ACTIVITY, XTable.XTableReviewActivity, "Id")
    InitBaseId2AchievementTypeDic()
    InitType2AchievementDic()
end
--=============
--给定配置表Key，获取该配置表全部配置
--@tableKey : XAchievementConfigs.TableKey枚举项
--=============
function XAchievementConfigs.GetAllConfigs(tableKey)
    if not tableKey or not tableKey.Id then
        XLog.Error("The tableKey given is not exist. tableKey : " .. tostring(tableKey))
        return {}
    end
    return Configs[tableKey.Id]
end
--=============
--给定配置表Key和Id，获取该配置表指定Id的配置
--@params:
--tableKey : XAchievementConfigs.TableKey枚举项
--idKey : 该配置表的主键Id或Key
--noTips : 若没有查找到对应项，是否要打印错误日志
--=============
function XAchievementConfigs.GetCfgByIdKey(tableKey, idKey, noTips)
    if not tableKey or not idKey then
        if not noTips then
            XLog.Error("XAchievementConfigs.GetCfgByIdKey error: tableKey or idKey is null!")
        end
        return {}
    end
    local allCfgs = XAchievementConfigs.GetAllConfigs(tableKey)
    if not allCfgs then
        return {}
    end
    local cfg = allCfgs[idKey]
    if not cfg then
        if not noTips then
            XLog.ErrorTableDataNotFound(
                "XAchievementConfigs.GetCfgByIdKey",
                tableKey.Key or "唯一Id",
                tableKey.Path,
                tableKey.Key or "唯一Id",
                tostring(idKey))
        end
        return {}
    end
    return cfg
end