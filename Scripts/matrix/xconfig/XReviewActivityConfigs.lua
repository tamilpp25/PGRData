--==================
--成就系统相关配置表
--模块负责：吕天元
--==================
XReviewActivityConfigs = XReviewActivityConfigs or {}
--================================================================
--                         配置表地址                            --
--================================================================
local SHARE_TABLE_PATH = "Share/ReviewActivity/"
local CLIENT_TABLE_PATH = "Client/ReviewActivity/"

local TABLE_REVIEW_ACTIVITY_INFO = CLIENT_TABLE_PATH .. "ReviewActivityInfo.tab"
local TABLE_REVIEW_ACTIVITY = SHARE_TABLE_PATH .. "ReviewActivity.tab"
local TABLE_REVIEW_ACTIVITY_PAGE_INFO = CLIENT_TABLE_PATH .. "ReviewActivityPageInfo.tab"
--=================================================
--=================================================
local Configs = {}
--=============
--配置表枚举
--Id : 枚举Id
--Path : 关联的表地址 (日志中使用)
--Key : 要检查的字段名 (日志中使用)
--=============
XReviewActivityConfigs.TableKey = {
    ReviewActivityInfo = {Id = 1, Path = TABLE_REVIEW_ACTIVITY_INFO}, --回顾活动文本信息
    ReviewActivityPageInfo = {Id = 2, Path = TABLE_REVIEW_ACTIVITY},
    ActivityId2InfoDic = {Id = 3, Path = TABLE_REVIEW_ACTIVITY_INFO, Key = "ActivityId"}, --回顾活动Id对应文本信息列表字典
    ActivityId2PageDic = {Id = 4, Path = TABLE_REVIEW_ACTIVITY_PAGE_INFO, Key = "ActivityId"} --回顾活动Id对应页面内容配置字典
}

XReviewActivityConfigs.ModelType = {
    None = 0,
    TopAbility = 1
}

XReviewActivityConfigs.ModelTypeName = {
    [0] = "None",
    [1] = "TopAbility",
}
--=============
--初始化ActivityId -> 文本信息列表字典
--=============
local InitActivityId2InfoDic = function()
    local tableId = XReviewActivityConfigs.TableKey.ActivityId2InfoDic.Id
    Configs[tableId] = {}
    for _, cfg in pairs (XReviewActivityConfigs.GetAllConfigs(XReviewActivityConfigs.TableKey.ReviewActivityInfo) or {}) do
        local activityId = cfg.ActivityId
        local page = cfg.Page
        if not Configs[tableId][activityId] then Configs[tableId][activityId] = {} end
        local pageDic = Configs[tableId][activityId]
        if not pageDic[page] then pageDic[page] = {} end
        table.insert(pageDic[page], cfg)
    end
end

local InitActivityId2PageDic = function()
    local tableId = XReviewActivityConfigs.TableKey.ActivityId2PageDic.Id
    Configs[tableId] = {}
    for _, cfg in pairs (XReviewActivityConfigs.GetAllConfigs(XReviewActivityConfigs.TableKey.ReviewActivityPageInfo) or {}) do
        local activityId = cfg.ActivityId
        local page = cfg.Page
        if not Configs[tableId][activityId] then Configs[tableId][activityId] = {} end
        Configs[tableId][activityId][page] = cfg
    end
end
--=============
--初始化所有配置表和字典
--=============
function XReviewActivityConfigs.Init()
    Configs[XReviewActivityConfigs.TableKey.ReviewActivityInfo.Id] = XTableManager.ReadByIntKey(TABLE_REVIEW_ACTIVITY_INFO, XTable.XTableReviewActivityInfo, "Id")
    --Configs[XReviewActivityConfigs.TableKey.ReviewActivity.Id] = XTableManager.ReadByIntKey(TABLE_REVIEW_ACTIVITY, XTable.XTableReviewActivity, "Id")
    Configs[XReviewActivityConfigs.TableKey.ReviewActivityPageInfo.Id] = XTableManager.ReadByIntKey(TABLE_REVIEW_ACTIVITY_PAGE_INFO, XTable.XTableReviewActivityPageInfo, "Id")
    InitActivityId2InfoDic()
    InitActivityId2PageDic()
end
--=============
--给定配置表Key，获取该配置表全部配置
--@tableKey : XReviewActivityConfigs.TableKey枚举项
--=============
function XReviewActivityConfigs.GetAllConfigs(tableKey)
    if not tableKey or not tableKey.Id then
        XLog.Error("The tableKey given is not exist. tableKey : " .. tostring(tableKey))
        return {}
    end
    return Configs[tableKey.Id]
end
--=============
--给定配置表Key和Id，获取该配置表指定Id的配置
--@params:
--tableKey : XReviewActivityConfigs.TableKey枚举项
--idKey : 该配置表的主键Id或Key
--noTips : 若没有查找到对应项，是否要打印错误日志
--=============
function XReviewActivityConfigs.GetCfgByIdKey(tableKey, idKey, noTips)
    if not tableKey or not idKey then
        if not noTips then
            XLog.Error("XReviewActivityConfigs.GetCfgByIdKey error: tableKey or idKey is null!")
        end
        return {}
    end
    local allCfgs = XReviewActivityConfigs.GetAllConfigs(tableKey)
    if not allCfgs then
        return {}
    end
    local cfg = allCfgs[idKey]
    if not cfg then
        if not noTips then
            XLog.ErrorTableDataNotFound(
                "XReviewActivityConfigs.GetCfgByIdKey",
                tableKey.Key or "唯一Id",
                tableKey.Path,
                tableKey.Key or "唯一Id",
                tostring(idKey))
        end
        return {}
    end
    return cfg
end

function XReviewActivityConfigs.GetTotlePageNum(activityId)
    local pages = XReviewActivityConfigs.GetCfgByIdKey(
        XReviewActivityConfigs.TableKey.ActivityId2PageDic,
        activityId
    )
    return pages and #pages or 0
end