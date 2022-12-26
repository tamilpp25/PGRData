-- 刮刮乐玩法配置
XScratchTicketConfig = XScratchTicketConfig or {}
--    ===================表地址
local SHARE_TABLE_PATH = "Share/MiniActivity/ScratchTicket/"
local CLIENT_TABLE_PATH = "Client/MiniActivity/ScratchTicket/"

local TABLE_STAGE = SHARE_TABLE_PATH .. "ScratchTicket.tab"
local TABLE_ACTIVITY = SHARE_TABLE_PATH .. "ScratchTicketActivity.tab"
local TABLE_CHOSE = SHARE_TABLE_PATH .. "ScratchTicketChose.tab"
local TABLE_GRID = SHARE_TABLE_PATH .. "ScratchTicketGrid.tab"
--    ===================原表数据
local StageConfig = {}
local ActivityConfig = {}
local ChoseConfig = {}
local GridConfig = {}

--=================
--初始化
--=================
function XScratchTicketConfig.Init()
    StageConfig = XTableManager.ReadByIntKey(TABLE_STAGE, XTable.XTableScratchTicket, "Id")
    ActivityConfig = XTableManager.ReadByIntKey(TABLE_ACTIVITY, XTable.XTableScratchTicketActivity, "Id")
    ChoseConfig = XTableManager.ReadByIntKey(TABLE_CHOSE, XTable.XTableScratchTicketChose, "Id")
    GridConfig = XTableManager.ReadByIntKey(TABLE_GRID, XTable.XTableScratchTicketGrid, "Id")
end

--=================
--获取所有活动配置
--=================
function XScratchTicketConfig.GetAllActivityConfig()
    return ActivityConfig
end

--=================
--根据ID获取活动配置
--@param id:关卡配置表Id
--@param noLog:默认显示 true不显示报错提示
--=================
function XScratchTicketConfig.GetActivityConfigById(id, noLog)
    if not noLog and not ActivityConfig[id] then
        XLog.ErrorTableDataNotFound(
            "XScratchTicketConfig.GetActivityConfigById",
            "ScratchTicketActivity",
            TABLE_ACTIVITY,
            "Id",
            tostring(id))
        return
    end
    return ActivityConfig[id]
end


--=================
--获取所有关卡配置
--=================
function XScratchTicketConfig.GetAllStageConfig()
    return StageConfig
end

--=================
--根据ID获取关卡配置
--@param id:关卡配置表Id
--@param noLog:默认显示 true不显示报错提示
--=================
function XScratchTicketConfig.GetStageConfigById(id, noLog)
    if not noLog and not StageConfig[id] then
        XLog.ErrorTableDataNotFound(
            "XScratchTicketConfig.GetStageConfigById",
            "ScratchTicket",
            TABLE_STAGE,
            "Id",
            tostring(id))
        return
    end
    return StageConfig[id]
end

--=================
--获取所有行列配置
--=================
function XScratchTicketConfig.GetAllChoseConfig()
    return ChoseConfig
end

--=================
--根据ID获取行列配置
--@param id:行列配置表Id
--@param noLog:默认显示 true不显示报错提示
--=================
function XScratchTicketConfig.GetChoseConfigById(id, noLog)
    if not noLog and not ChoseConfig[id] then
        XLog.ErrorTableDataNotFound(
            "XScratchTicketConfig.GetChoseConfigById",
            "ScratchTicketChose",
            TABLE_CHOSE,
            "Id",
            tostring(id))
        return
    end
    return ChoseConfig[id]
end

--=================
--获取所有九宫格配置
--=================
function XScratchTicketConfig.GetAllGridConfig()
    return GridConfig
end

--=================
--根据ID获取九宫格配置
--@param id:九宫格配置表Id
--@param noLog:默认显示 true不显示报错提示
--=================
function XScratchTicketConfig.GetGridConfigById(id, noLog)
    if not noLog and not GridConfig[id] then
        XLog.ErrorTableDataNotFound(
            "XScratchTicketConfig.GetGridConfigById",
            "ScratchTicketGrid",
            TABLE_GRID,
            "Id",
            tostring(id))
        return
    end
    return GridConfig[id]
end 