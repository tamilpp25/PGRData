 
--===========================================================================
---@desc 哈卡玛小游戏配置
--===========================================================================

XBodyCombineGameConfigs = XBodyCombineGameConfigs or {}


--region 路径

local TABLE_ACTIVITY_PATH  = "Share/MiniActivity/BodyCombineGame/BodyCombineGameActivity.tab"
local TABLE_STAGE_PATH     = "Share/MiniActivity/BodyCombineGame/BodyCombineGameStage.tab"
local TABLE_SMALL_ICON_PATH     = "Client/MiniActivity/BodyCombineGame/BodyCombineGameSmallIcon.tab"

--endregion

--region 局部变量
local _Activity  = {}
local _Stage     = {}
local _SmallIcon = {}
local _CoinId    = 1032 --活动代币Id
--endregion

--region 局部函数
local InitConfig = function()
    _Activity   = XTableManager.ReadByIntKey(TABLE_ACTIVITY_PATH, XTable.XTableBodyCombineGameActivity, "Id")
    _Stage      = XTableManager.ReadByIntKey(TABLE_STAGE_PATH, XTable.XTableBodyCombineGameStage, "Id")
    _SmallIcon  = XTableManager.ReadByIntKey(TABLE_SMALL_ICON_PATH, XTable.XTableBodyCombineGameSmallIcon, "Id")
       
end

---==============================
   ---@desc: 获取活动配置 
---==============================
local GetActivityCfg = function(activityId)
    if not activityId then return end
    local config = _Activity[activityId]
    if not config then
        XLog.Error("Can Not Get Activity Config, Path = "..TABLE_ACTIVITY_PATH..", ActivityId = "..activityId)
        return
    end
    return config
end

---==============================
   ---@desc: 当前活动的TimeId 
---==============================
local GetActivityTimeId = function(activityId) 
    local config = GetActivityCfg(activityId)
    if config then
        return config.TimeId
    end
    return 0
end
--endregion

--region 外部接口

--===========================================================================
 ---@desc 默认活动Id
--===========================================================================
function XBodyCombineGameConfigs.GetDefaultActivityId()
    for _, config in ipairs(_Activity) do
        local id = config.Id
        if XTool.IsNumberValid(id) then
           return id 
        end
    end
    return 0
end

--===========================================================================
 ---@desc 活动开始时间戳
--===========================================================================
function XBodyCombineGameConfigs.GetActivityStartTime(activityId)
    local timeId = GetActivityTimeId(activityId)
    return XFunctionManager.GetStartTimeByTimeId(timeId)
end

--===========================================================================
 ---@desc 活动结束时间戳
--===========================================================================
function XBodyCombineGameConfigs.GetActivityEndTime(activityId)
    local timeId = GetActivityTimeId(activityId)
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

--===========================================================================
 ---@desc 关卡数据
--===========================================================================
function XBodyCombineGameConfigs.GetStageData()
    return _Stage
end

--===========================================================================
 ---@desc 活动钱币物品Id
--===========================================================================
function XBodyCombineGameConfigs.GetCoinItemId()
    -- local cfg = GetActivityCfg(activityId)
    -- return cfg and cfg.CostItemId
    return _CoinId
end

--===========================================================================
 ---@desc 活动标题图
--===========================================================================
function XBodyCombineGameConfigs.GetActivityTitle(activityId)
    local cfg = GetActivityCfg(activityId)
    return cfg and cfg.ActivityTitle
end

--===========================================================================
 ---@desc 全部关卡完成图
--===========================================================================·
function XBodyCombineGameConfigs.GetActivityFinishBanner(activityId)
    local cfg = GetActivityCfg(activityId)
    return cfg and cfg.FinishBanner
end

--===========================================================================
 ---@desc 图片路径
--===========================================================================
function XBodyCombineGameConfigs.GetSmallIcon(iconId)
    local cfg = _SmallIcon[iconId]
    return cfg and cfg.Path
end

--endregion

---==============================
   ---@desc: 初始化入口 
---==============================
function XBodyCombineGameConfigs.Init()
    InitConfig()
end

