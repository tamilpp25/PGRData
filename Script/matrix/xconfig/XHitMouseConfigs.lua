--===========================
--打地鼠配置读写
--模块负责：吕天元
--===========================
XHitMouseConfigs = XHitMouseConfigs or {}
--================================================================
--                         配置表地址                            --
--================================================================
local SHARE_TABLE_PATH = "Share/MiniActivity/HitMouse/"
local CLIENT_TABLE_PATH = "Client/MiniActivity/HitMouse/"

local TABLE_ACTIVITY = SHARE_TABLE_PATH .. "HitMouseActivity.tab"
local TABLE_STAGE = SHARE_TABLE_PATH .. "HitMouseStage.tab"

local TABLE_MOLE = CLIENT_TABLE_PATH .. "HitMouseMole.tab"
local TABLE_GAME = CLIENT_TABLE_PATH .. "HitMouseGame.tab"
local TABLE_REFRESH = CLIENT_TABLE_PATH .. "HitMouseRefresh.tab"
--================================================================
--                         配置表                                --
--================================================================
local Configs = {}

--================================================================
--                         搜索用字典                            --
--================================================================

--================================================================
--                玩法枚举与常数定义                              --
--================================================================
--=============
--配置表枚举
--Id : 枚举Id
--Path : 关联的表地址 (日志中使用)
--Key : 要检查的字段名 (日志中使用)
--=============
XHitMouseConfigs.TableKey = {
    Activity = {Id = 1, Path = TABLE_ACTIVITY}, --基础活动配置
    Stage = {Id = 2, Path = TABLE_STAGE}, --模式配置
    Mole = {Id = 3, Path = TABLE_MOLE}, --地鼠配置
    Game = {Id = 4, Path = TABLE_GAME}, --小游戏配置
    Refresh = {Id = 5, Path = TABLE_REFRESH}, --刷新表配置
    Activity2Stage = {Id = 6, Path = TABLE_STAGE, Key = "ActivityId"}, --活动ID对应关卡
    Stage2Refresh = {Id = 7, Path = TABLE_STAGE, Key = "Id"}, --关卡ID对应到的刷新表集合
}

XHitMouseConfigs.MoleStatus = {
    Default = 0, --空
    SetMole = 1, --设置完地鼠
    Appear = 2, --地鼠出现
    Wait = 3, --地鼠待机
    Hit = 4, --地鼠被击中
    Disappear = 5, --地鼠消失
    Rest = 6, --休息时间
}

XHitMouseConfigs.MoleStatusName = {
    [0] = "Default",
    [1] = "SetMole",
    [2] = "Appear",
    [3] = "Wait",
    [4] = "Hit",
    [5] = "Disappear",
    [6] = "Rest"
}

local function InitActivity2Stage()
    Configs[XHitMouseConfigs.TableKey.Activity2Stage.Id] = {}
    local dic = Configs[XHitMouseConfigs.TableKey.Activity2Stage.Id]
    local allStagesCfgs = XHitMouseConfigs.GetAllConfigs(XHitMouseConfigs.TableKey.Stage)
    for stageId, cfg in pairs(allStagesCfgs or {}) do
        if not dic[cfg.ActivityId] then
            dic[cfg.ActivityId] = {}
        end
        table.insert(dic[cfg.ActivityId], cfg)
    end
end

local function InitStage2Refresh()
    Configs[XHitMouseConfigs.TableKey.Stage2Refresh.Id] = {}
    local dic = Configs[XHitMouseConfigs.TableKey.Stage2Refresh.Id]
    local allStagesCfgs = XHitMouseConfigs.GetAllConfigs(XHitMouseConfigs.TableKey.Stage)
    for stageId, cfg in pairs(allStagesCfgs or {}) do
        local refreshIds = string.Split(cfg.MouseRefresh, '|')
        dic[stageId] = {}
        for _, refreshId in pairs(refreshIds or {}) do
            local id = tonumber(refreshId)
            local cfg = XHitMouseConfigs.GetCfgByIdKey(
                XHitMouseConfigs.TableKey.Refresh,
                id
            )
            if cfg then
                dic[stageId][cfg.HitCount] = cfg
            end
        end
    end
end
--=============
--初始化所有配置表和字典
--=============
function XHitMouseConfigs.Init()
    Configs[XHitMouseConfigs.TableKey.Activity.Id] = XTableManager.ReadByIntKey(TABLE_ACTIVITY, XTable.XTableHitMouseActivity, "Id")
    Configs[XHitMouseConfigs.TableKey.Stage.Id] = XTableManager.ReadByIntKey(TABLE_STAGE, XTable.XTableHitMouseStage, "Id")
    Configs[XHitMouseConfigs.TableKey.Mole.Id] = XTableManager.ReadByIntKey(TABLE_MOLE, XTable.XTableHitMouseMole, "Id")
    Configs[XHitMouseConfigs.TableKey.Game.Id] = XTableManager.ReadByIntKey(TABLE_GAME, XTable.XTableHitMouseGame, "Id")
    Configs[XHitMouseConfigs.TableKey.Refresh.Id] = XTableManager.ReadByIntKey(TABLE_REFRESH, XTable.XTableHitMouseRefresh, "Id")
    InitActivity2Stage()
    InitStage2Refresh()
end

--=============
--给定配置表Key，获取该配置表全部配置
--@tableKey : XHitMouseConfigs.TableKey枚举项
--=============
function XHitMouseConfigs.GetAllConfigs(tableKey)
    if not tableKey or not tableKey.Id then
        XLog.Error("The tableKey given is not exist. tableKey : " .. tostring(tableKey))
        return {}
    end
    return Configs[tableKey.Id]
end
--=============
--给定配置表Key和Id，获取该配置表指定Id的配置
--@params:
--tableKey : XHitMouseConfigs.TableKey枚举项
--idKey : 该配置表的主键Id或Key
--noTips : 若没有查找到对应项，是否要打印错误日志
--=============
function XHitMouseConfigs.GetCfgByIdKey(tableKey, idKey, noTips)
    if not tableKey or not idKey then
        XLog.Error("XHitMouseConfigs.GetCfgByIdKey error: tableKey or idKey is null!")
        return {}
    end
    local allCfgs = XHitMouseConfigs.GetAllConfigs(tableKey)
    if not allCfgs then
        return {}
    end
    local cfg = allCfgs[idKey]
    if not cfg then
        if not noTips then
            XLog.ErrorTableDataNotFound(
                "XHitMouseConfigs.GetCfgByIdKey",
                tableKey.Key or "唯一Id",
                tableKey.Path,
                tableKey.Key or "唯一Id",
                tostring(idKey))
        end
        return {}
    end
    return cfg
end

function XHitMouseConfigs.GetCfgItem(tableKey, idKey, item, noTips)
    local cfg = XHitMouseConfigs.GetCfgByIdKey(tableKey, idKey, noTips)
    if next(cfg) then
        if cfg[item] then
            return cfg[item]
        elseif not noTips then
            XLog.ErrorTableDataNotFound(
                "XHitMouseConfigs.GetCfgItem",
                item or "唯一Id",
                tableKey.Path,
                tableKey.Key or "唯一Id",
                tostring(idKey))
        end
    end
    return nil
end