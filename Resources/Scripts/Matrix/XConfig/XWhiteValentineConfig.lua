--白情约会小游戏配置管理器
XWhiteValentineConfig = XWhiteValentineConfig or {}
--    ===================表地址
local SHARE_TABLE_PATH = "Share/MiniActivity/WhiteValentine2021/"
local CLIENT_TABLE_PATH = "Client/MiniActivity/WhiteValentine2021/"
-- 约会小游戏基础配置表
local TABLE_GAMECONFIG = SHARE_TABLE_PATH .. "WhiteValentinesDayConfig.tab"
-- 约会小游戏地点配置表
local TABLE_PLACE = SHARE_TABLE_PATH .. "WhiteValentinesDayPlace.tab"
-- 约会小游戏事件配置表
local TABLE_EVENT = SHARE_TABLE_PATH .. "WhiteValentinesDayEvent.tab"
-- 约会小游戏角色配置表
local TABLE_CHARA = SHARE_TABLE_PATH .. "WhiteValentinesDayRole.tab"
-- 约会小游戏故事内容配置表
local TABLE_STORY = CLIENT_TABLE_PATH .. "WhiteValentinesDayStory.tab"
-- 约会小游戏事件阶级详细表
local TABLE_RANK = SHARE_TABLE_PATH .. "WhiteValentinesDayRank.tab"
-- 约会小游戏角色属性详细表
local TABLE_ATTR = CLIENT_TABLE_PATH .. "WhiteValentinesDayAttr.tab"
--    ===================原表数据
-- 约会小游戏基础配置表
local WhiteValentineConfig = {}
-- 约会小游戏地点配置表
local WhiteValentinePlace = {}
-- 约会小游戏事件配置表
local WhiteValentineEvent = {}
-- 约会小游戏角色配置表
local WhiteValentineChara = {}
-- 约会小游戏故事内容配置表
local WhiteValentineStory = {}
-- 约会小游戏事件阶级详细表
local WhiteValentineRank = {}
-- 约会小游戏角色属性详细表
local WhiteValentineAttr = {}
--==================初始化方法======================
--===============
--初始化表配置
--===============
function XWhiteValentineConfig.Init()
    WhiteValentineConfig = XTableManager.ReadByIntKey(TABLE_GAMECONFIG, XTable.XTableWhiteValentinesDayConfig, "Id")
    WhiteValentinePlace = XTableManager.ReadByIntKey(TABLE_PLACE, XTable.XTableWhiteValentinesDayPlace, "Id")
    WhiteValentineEvent = XTableManager.ReadByIntKey(TABLE_EVENT, XTable.XTableWhiteValentinesDayEvent, "Id")
    WhiteValentineChara = XTableManager.ReadByIntKey(TABLE_CHARA, XTable.XTableWhiteValentinesDayRole, "Id")
    WhiteValentineStory = XTableManager.ReadByIntKey(TABLE_STORY, XTable.XTableWhiteValentinesDayStory, "Id")
    WhiteValentineRank = XTableManager.ReadByIntKey(TABLE_RANK, XTable.XTableWhiteValentinesDayRank, "Id")
    WhiteValentineAttr = XTableManager.ReadByIntKey(TABLE_ATTR, XTable.XTableWhiteValentinesDayAttr, "Id")
end
--==================================================
--==================读表方法======================
--===============
--获取所有活动基础配置
--===============
function XWhiteValentineConfig.GetAllWhiteValentineConfig()
    return WhiteValentineConfig
end
--===============
--获取最新的基础配置Id
--===============
function XWhiteValentineConfig.GetLastConfigId()
    local id = 0
    for configId, _ in pairs(WhiteValentineConfig) do
        if id < configId then id = configId end
    end
    return id
end
--===============
--根据GameId获取游戏基础配置
--@param gameId:游戏ID
--===============
function XWhiteValentineConfig.GetWhiteValentineConfigByGameId(gameId)
    local config = WhiteValentineConfig[gameId]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XWhiteValentineConfig.GetWhiteValentineConfigByGameId",
            "组合小游戏活动基础配置数据",
            TABLE_GAMECONFIG,
            "GameId",
            tostring(gameId)
        )
        return nil
    end
    return config
end
--===============
--获取所有地点配置
--===============
function XWhiteValentineConfig.GetAllWhiteValentinePlace()
    return WhiteValentinePlace
end
--===============
--根据PlaceId获取地点配置
--@param placeId:地点ID
--===============
function XWhiteValentineConfig.GetWhiteValentinePlaceByPlaceId(placeId)
    local config = WhiteValentinePlace[placeId]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XWhiteValentineConfig.GetWhiteValentinePlaceByPlaceId",
            "约会小游戏活动地点配置数据",
            TABLE_PLACE,
            "PlaceId",
            tostring(placeId)
        )
        return nil
    end
    return config
end
--===============
--获取所有事件配置
--===============
function XWhiteValentineConfig.GetAllWhiteValentineEvent()
    return WhiteValentineEvent
end
--===============
--根据EventId获取地点配置
--@param eventId:地点ID
--===============
function XWhiteValentineConfig.GetWhiteValentineEventByEventId(eventId)
    local config = WhiteValentineEvent[eventId]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XWhiteValentineConfig.GetWhiteValentineEventByEventId",
            "约会小游戏活动事件配置数据",
            TABLE_EVENT,
            "eventId",
            tostring(eventId)
        )
        return nil
    end
    return config
end
--===============
--获取所有角色配置
--===============
function XWhiteValentineConfig.GetAllWhiteValentineChara()
    return WhiteValentineChara
end
--===============
--根据CharaId获取地点配置
--@param charaId:角色ID
--===============
function XWhiteValentineConfig.GetWhiteValentineCharaByCharaId(charaId)
    local config = WhiteValentineChara[charaId]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XWhiteValentineConfig.GetWhiteValentineCharaByCharaId",
            "约会小游戏活动角色配置数据",
            TABLE_CHARA,
            "charaId",
            tostring(charaId)
        )
        return nil
    end
    return config
end
--===============
--根据Id获取约会内容配置
--@param id:约会ID
--===============
function XWhiteValentineConfig.GetWhiteValentineStoryById(id)
    local config = WhiteValentineStory[id]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XWhiteValentineConfig.GetWhiteValentineStoryById",
            "约会小游戏活动约会内容配置数据",
            TABLE_STORY,
            "Id",
            tostring(id)
        )
        return nil
    end
    return config
end
--===============
--根据Id获取约会阶级详细配置
--@param id:阶级ID
--===============
function XWhiteValentineConfig.GetWhiteValentineRankConfigById(id)
    local config = WhiteValentineRank[id]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XWhiteValentineConfig.GetWhiteValentineRankConfigById",
            "约会小游戏活动阶级详细配置数据",
            TABLE_RANK,
            "Id",
            tostring(id)
        )
        return nil
    end
    return config
end
--===============
--获取所有角色属性详细配置
--===============
function XWhiteValentineConfig.GetAllWhiteValentineAttr()
    return WhiteValentineAttr
end
--===============
--根据Id获取角色属性详细配置
--@param id:属性ID
--===============
function XWhiteValentineConfig.GetWhiteValentineAttrById(id)
    local config = WhiteValentineAttr[id]
    if not config then
        XLog.ErrorTableDataNotFound(
            "XWhiteValentineConfig.GetWhiteValentineAttrById",
            "约会小游戏活动角色属性详细配置数据",
            TABLE_ATTR,
            "Id",
            tostring(id)
        )
        return nil
    end
    return config
end
--==================================================