-- 组合小游戏Config
XComposeGameConfig = XComposeGameConfig or {}

--    ===================表地址====================
local SHARE_TABLE_PATH = "Share/MiniActivity/ComposeGame/"
local CLIENT_TABLE_PATH = "Client/MiniActivity/ComposeGame/"

local TABLE_GAMECONFIGS = SHARE_TABLE_PATH .. "ComposeGame.tab"
local TABLE_GOODS = SHARE_TABLE_PATH .. "ComposeGoods.tab"
local TABLE_CLIENT_CONFIG = CLIENT_TABLE_PATH .. "ComposeClientConfig.tab"
--=================================================
--    ===================原表数据===================
local GameConfigs = {}
local GoodsConfigs = {}
local ClientConfig = {}
--=================================================

--    ================构建搜索用字典================
local GameId2GoodsDic = {}
local GameId2ClientConfigDic = {}
--=================================================

--==================初始化方法======================
--===============
--构建活动ID<-->活动道具列表字典
--===============
local CreateGameId2GoodsDic = function()
    for _, good in pairs(GoodsConfigs) do
        if not GameId2GoodsDic[good.ActId] then GameId2GoodsDic[good.ActId] = {} end
        table.insert(GameId2GoodsDic[good.ActId], good)
    end
end
--===============
--构建活动ID<-->活动客户端配置字典
--===============
local CreateGameId2ClientConfigDic = function()
    for id, config in pairs(ClientConfig) do
        -- 通用配置不进入构建字典
        if id > 0 then GameId2ClientConfigDic[config.ActId] = config end
    end
end
--===============
--初始化表配置
--===============
function XComposeGameConfig.Init()
    GameConfigs = XTableManager.ReadByIntKey(TABLE_GAMECONFIGS, XTable.XTableComposeGame, "Id")
    GoodsConfigs = XTableManager.ReadByIntKey(TABLE_GOODS, XTable.XTableComposeGoods, "Id")
    ClientConfig = XTableManager.ReadByIntKey(TABLE_CLIENT_CONFIG, XTable.XTableComposeClientConfig, "Id")
    CreateGameId2GoodsDic()
    CreateGameId2ClientConfigDic()
end
--==================================================
--==================读表方法======================

--===============
--获取所有组合小游戏活动基础配置
--===============
function XComposeGameConfig.GetGameConfigs()
    return GameConfigs
end
--===============
--根据Id获取组合小游戏活动基础配置
--@param gameId:活动ID
--===============
function XComposeGameConfig.GetGameConfigsByGameId(gameId)
    local config = GameConfigs[gameId]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XComposeGameConfig.GetGameConfigsByGameId",
            "组合小游戏活动基础配置数据",
            TABLE_GAMECONFIGS,
            "Id",
            tostring(gameId)
        )
        return nil
    end
    return config
end
--===============
--获取所有组合小游戏物品配置
--===============
function XComposeGameConfig.GetGoodsConfigs()
    return GoodsConfigs
end
--===============
--根据Id获取组合小游戏物品配置
--@param itemId:物品ID
--===============
function XComposeGameConfig.GetItemConfigByItemId(itemId)
    local config = GoodsConfigs[itemId]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XComposeGameConfig.GetItemConfigByItemId",
            "组合小游戏物品配置数据",
            TABLE_GOODS,
            "Id",
            tostring(itemId)
        )
        return nil
    end
    return config
end
--===============
--根据活动Id获取活动对应的所有物品配置
--@param gameId:活动ID
--===============
function XComposeGameConfig.GetItemListConfigByGameId(gameId)
    local itemCfgsList = GameId2GoodsDic[gameId]
    if not itemCfgsList then
        XLog.ErrorTableDataNotFound(
            "XComposeGameConfig.GetItemListConfigByGameId",
            "组合小游戏物品配置数据",
            TABLE_GOODS,
            "ActId",
            tostring(gameId)
        )
        return nil
    end
    return itemCfgsList
end
--===============
--根据活动ID获取组合小游戏客户端配置(对个别组合小游戏的客户端配置)
--@param gameId:活动ID
--===============
function XComposeGameConfig.GetClientConfigByGameId(gameId)
    local config = GameId2ClientConfigDic[gameId]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XComposeGameConfig.GetClientConfigByGameId",
            "组合小游戏活动客户端配置",
            TABLE_CLIENT_CONFIG,
            "ActId",
            tostring(gameId)
        )
        return nil
    end
    return config
end
--===============
--获取组合小游戏默认客户端配置(全组合小游戏通用配置)
--===============
function XComposeGameConfig.GetDefaultConfig()
    return ClientConfig[0]
end
--==================================================