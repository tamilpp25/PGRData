
XPivotCombatConfigs = XPivotCombatConfigs or {}

--region 配置表路径
--活动入口配置路径
local TABLE_ACTIVITY_PATH   = "Share/Fuben/PivotCombat/PivotCombatActivity.tab"
--区域总控路径
local TABLE_REGION_PATH     = "Share/Fuben/PivotCombat/PivotCombatRegion.tab"
--关卡库路径
local TABLE_STAGELIB_PATH   = "Share/Fuben/PivotCombat/PivotCombatStageLib.tab"
--排名->图标配置路径
local TABLE_RANKICON_PATH   = "Client/Fuben/PivotCombat/PivotCombatRankIcon.tab"
--供能效果库
local TABLE_EFFECTLIB_PATH  = "Share/Fuben/PivotCombat/PivotCombatEffectLib.tab"
--机器人配置表
local TABLE_ROBOT_PATH      = "Share/Fuben/PivotCombat/PivotCombatRobot.tab"
--积分关卡结算描述
local TABLE_SETTLE_PATH     = "Client/Fuben/PivotCombat/PivotCombatSettleDesc.tab"
--独域技能检测
local TABLE_SKILLCHECK_PATH      = "Client/Fuben/PivotCombat/PivotCombatSkillCheck.tab"
--困难度设置
local TABLE_DIFFICULT_PATH = "Client/Fuben/PivotCombat/PivotCombatDifficult.tab"
--endregion

--region 局部变量
local _ActivityConfigs          = {} -- 活动入口配置
local _RegionConfigs            = {} --区域总控
local _StageLibConfigs          = {} --关卡库
local _CurRegionConfigs         = {} --当期活动总控
local _LibId2StageLibConfigs    = {} --Key(关卡库Id):Value(关卡库配置)
local _StageId2Config           = {} --关卡Id -> 关卡库配置
local _Ranking2IconConfigs      = {} --排名->图标配置路径
local _EffectLibConfigs         = {} --供能效果库
local _EffectIdLevel2Configs    = {} --功能库Id + 等级 => 对应配置
local _RobotConfigs             = {} --机器人配置
local _SettleDesc               = {} --积分关卡结束二次结算描述
local _SkillCheck               = {} --检测玩家是否学习独域技能
local _DifficultList            = {} --检测玩家是否学习独域技能


--endregion

--region 全局变量

--二次结算key
XPivotCombatConfigs.FightResultKey = {
    --基础积分
    Basic               = 1, 
    --处决积分
    Execute             = 2, 
    --连续处决积分
    ContinuityExecute   = 3, 
    --最高评分积分
    HighestScore        = 4, 
    --最高评级积分
    HighestGrade        = 5
}

--评分等级
XPivotCombatConfigs.FightGrade = {
    [1] = "C",
    [2] = "B",
    [3] = "A",
    [4] = "S",
    [5] = "SS",
    [6] = "SSS",
    [7] = "SSS+",
}
--中心教学关id
XPivotCombatConfigs.TeachStageId                = CS.XGame.ClientConfig:GetInt("PivotCombatTeachStageId")
--动态评分教学关卡
XPivotCombatConfigs.DynamicScoreTeachStageId    = CS.XGame.ClientConfig:GetInt("PivotCombatDynamicScoreTeachStageId")

--通关时间积分初始值
XPivotCombatConfigs.FightTimeScoreInitialValue = 2000

--难度选择
XPivotCombatConfigs.DifficultType = {
    --普通难度
    Normal = 1,
    --困难难度
    Hard = 2,
}

--endregion

--region 局部函数

--===========================================================================
 ---@desc 获取活动配置
 ---@param {activityId} 活动id 
 ---@return {table} 对应活动的配置
--===========================================================================
local GetActivityConfigById = function(activityId)
    if not (activityId and XTool.IsNumberValid(activityId)) then
        return {}
    end
    local config = _ActivityConfigs[activityId]
    if not config then
        XLog.Error("XPivotCombat GetActivityConfigById Error:配置不存在, activityId = "..activityId..", Path = "..TABLE_ACTIVITY_PATH)
        return {}
    end
    return config
end

--===========================================================================
 ---@desc 初始化活动配置
--===========================================================================
local InitTableConfig = function() 
    -- 活动入口初始化
    _ActivityConfigs        = XTableManager.ReadByIntKey(TABLE_ACTIVITY_PATH, XTable.XTablePivotCombatActivity, "Id")
    -- 区域总控初始化
    _RegionConfigs          = XTableManager.ReadByIntKey(TABLE_REGION_PATH, XTable.XTablePivotCombatRegion, "Id")
    -- 关卡库初始化
    _StageLibConfigs        = XTableManager.ReadByIntKey(TABLE_STAGELIB_PATH, XTable.XTablePivotCombatStageLib, "Id")
    -- 排名索引图标配置初始化
    _Ranking2IconConfigs    = XTableManager.ReadByIntKey(TABLE_RANKICON_PATH, XTable.XTablePivotCombatRankIcon, "Ranking")
    -- 供能效果库
    _EffectLibConfigs       = XTableManager.ReadByIntKey(TABLE_EFFECTLIB_PATH, XTable.XTablePivotCombatEffectLib, "Id")
    -- 机器人配
    _RobotConfigs           = XTableManager.ReadByIntKey(TABLE_ROBOT_PATH, XTable.XTablePivotCombatRobot, "Id")
    -- 积分关，二次结算描述
    _SettleDesc             = XTableManager.ReadByIntKey(TABLE_SETTLE_PATH, XTable.XTablePivotCombatSettleDesc, "Id")
    -- 检测角色是否学习了独域技能
    _SkillCheck             = XTableManager.ReadByIntKey(TABLE_SKILLCHECK_PATH, XTable.XTablePivotCombatSkillCheck, "CharacterId")
    -- 困难度配置
    _DifficultList             = XTableManager.ReadByIntKey(TABLE_DIFFICULT_PATH, XTable.XTablePivotCombatDifficult, "Id")
    
end

--===========================================================================
 ---@desc 获取活动的TimeId
 ---@param {activityId} 活动id 
 ---@return {int} 对应的timeId
--===========================================================================
local GetActivityTimeId = function(activityId) 
    local config = GetActivityConfigById(activityId)
    return config.TimeId or 0
end

--===========================================================================
 ---@desc 初始化自定义数据结构
--===========================================================================
local InitCustomConfig = function()
    for id, config in pairs(_StageLibConfigs or {}) do
        --关卡库id = {当前关卡库下的配置列表,....}
        if not _LibId2StageLibConfigs[config.StageLibId] then
            _LibId2StageLibConfigs[config.StageLibId] = {}
        end
        table.insert(_LibId2StageLibConfigs[config.StageLibId], config)

        _StageId2Config[config.StageId] = config
    end
    
    for _, config in pairs(_EffectLibConfigs or {}) do
        if not _EffectIdLevel2Configs[config.EffectLibId] then
            _EffectIdLevel2Configs[config.EffectLibId] = {}
        end
        _EffectIdLevel2Configs[config.EffectLibId][config.SupplyEnergyLevel] = config 
    end
end

--endregion

--===========================================================================
 ---@desc 根据活动Id更新数据
--===========================================================================
function XPivotCombatConfigs.InitConfigsByActivity(activityId)
    for _, config in pairs(_RegionConfigs or {}) do
        if config.ActivityId == activityId then
            local difficult = config.Difficulty
            if not _CurRegionConfigs[difficult] then
                _CurRegionConfigs[difficult] = {}
            end
            _CurRegionConfigs[difficult][config.RegionId] = config
        end
    end
end

--===========================================================================
---@desc:获取所有的StageId
---@return:[stageId, stageId,.....]
--===========================================================================
function XPivotCombatConfigs.GetAllStageIds()
    local stageIds = { XPivotCombatConfigs.TeachStageId, XPivotCombatConfigs.DynamicScoreTeachStageId }
    for _, config in ipairs(_StageLibConfigs) do
        if XTool.IsNumberValid(config.StageId) then
            table.insert(stageIds, config.StageId)
        end
    end
    return stageIds
end

--===========================================================================
 ---@desc 获取活动封面图
 ---@param {activityId} 活动id 
 ---@return {string} 对应活动的封面图路径
--===========================================================================
function XPivotCombatConfigs.GetActivityBanner(activityId)
    local config = GetActivityConfigById(activityId)
    return config.ActivityBanner or ""
end

--===========================================================================
 ---@desc 获取活动名
 ---@param {activityId} 活动id 
 ---@return {string} 对应活动的名称
--===========================================================================
function XPivotCombatConfigs.GetActivityName(activityId)
    local config = GetActivityConfigById(activityId)
    return config.Name or ""
end

--===========================================================================
 ---@desc 获取活动开始时间
 ---@param {activityId} 活动id  
 ---@return {int}活动开始时间戳
--===========================================================================
function XPivotCombatConfigs.GetActivityStartTime(activityId)
    local timeId = GetActivityTimeId(activityId)
    return XFunctionManager.GetStartTimeByTimeId(timeId)
end

--===========================================================================
 ---@desc 获取活动结束时间
 ---@param {activityId} 活动id 
 ---@return {int}活动结束时间戳
--===========================================================================
function XPivotCombatConfigs.GetActivityEndTime(activityId)
    local timeId = GetActivityTimeId(activityId)
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

--===========================================================================
 ---@desc 获取默认活动id
 ---@return {int} 活动id
--===========================================================================
function XPivotCombatConfigs.GetDefaultActivityId()
    local timeOfNow = XTime.GetServerNowTimestamp()
    local defaultId = 0
    --默认保底
    for _, config in ipairs(_ActivityConfigs) do
        if config.Id and XTool.IsNumberValid(config.Id) then
            defaultId = config.Id
        end
    end
    --在当前活动时间段内的
    for _, config in ipairs(_ActivityConfigs) do
        if config.Id and XTool.IsNumberValid(config.Id) then
            local timeOfBgn = XPivotCombatConfigs.GetActivityStartTime(config.Id)
            local timeOfEnd = XPivotCombatConfigs.GetActivityEndTime(config.Id)
            if timeOfBgn <= timeOfNow and timeOfEnd >= timeOfNow then
                return config.Id
            end
        end
    end
    return defaultId
end

--===========================================================================
 ---@desc 获取当期活动的区域数据
 ---@return {table} key = regionId value = regionConfig
--===========================================================================
function XPivotCombatConfigs.GetCurRegionConfigs()
    return _CurRegionConfigs
end

--===========================================================================
 ---@desc 获取当期活动的关卡
 ---@return {table} key = stageLibId value = stageLibConfig
--===========================================================================
function XPivotCombatConfigs.GetStageLibConfigs()
    return _LibId2StageLibConfigs
end

--===========================================================================
 ---@desc 根据关卡库Id获取对应的关卡列表
 ---@param {stageLibId} 关卡库id 
 ---@return {table} 对应的配置
--===========================================================================
function XPivotCombatConfigs.GetStageLibConfig(stageLibId)
    return _LibId2StageLibConfigs[stageLibId] or {}
end

--===========================================================================
---@desc 获取排名对应的图标
---@return {string} icon path
--===========================================================================
function XPivotCombatConfigs.GetRankingIcon(ranking)
    local config = _Ranking2IconConfigs[ranking] or {}
    return config.Icon
end

--===========================================================================
 ---@desc 获取供能配置
 ---@param {effectId} 特效库ID 
 ---@param {level} 等级 
 ---@return {table}供能配置
--===========================================================================
function XPivotCombatConfigs.GetEffectConfig(effectId, level)
    local config = _EffectIdLevel2Configs[effectId]
    if config then
        return config[level]
    end
    return {}
end

--===========================================================================
 ---@desc 获取机器人配置
--===========================================================================
function XPivotCombatConfigs.GetRobotSources()
    return _RobotConfigs
end

--===========================================================================
 ---@desc 获取积分结算，二次结算描述
--===========================================================================
function XPivotCombatConfigs.GetSettleDesc(resultKey)
    return _SettleDesc[resultKey].Desc or ""
end

--===========================================================================
 ---@desc 角色检查
--===========================================================================
function XPivotCombatConfigs.GetSpecialSkillCheck(characterId)
    local cfg = _SkillCheck[characterId]
    if not cfg then
        return
    end
    return cfg.Condition
end

--===========================================================================
---@desc 获取活动开启总时间
--===========================================================================
function XPivotCombatConfigs.GetTotalTime()
    local sTime = math.huge
    local eTime = -1
    for _,config in pairs(_ActivityConfigs) do
        if config.TimeId and config.TimeId ~= 0 and XFunctionManager.IsEffectiveTimeId(config.TimeId) then
            local startTime,endTime =  XFunctionManager.GetTimeByTimeId(config.TimeId)
            if startTime < sTime then sTime = startTime end
            if endTime > eTime then eTime = endTime end
        end
    end
    return sTime,eTime
end

--==============================
 ---@desc 代币Id
 ---@activityId 活动id 
 ---@return number
--==============================
function XPivotCombatConfigs.GetCoinId(activityId)
    local cfg = GetActivityConfigById(activityId)
    return cfg and cfg.CoinId or 0
end

--==============================
 ---@desc 商店类型
 ---@activityId 活动id 
 ---@return number
--==============================
function XPivotCombatConfigs.GetShopType(activityId)
    local cfg = GetActivityConfigById(activityId)
    return cfg.ShopType
end

--==============================
 ---@desc 获取难度名称
 ---@difficult 难度id
 ---@return string
--==============================
function XPivotCombatConfigs.GetDifficultName(difficult)
    local cfg = _DifficultList[difficult]
    return cfg and cfg.Name or ""
end

--==============================
 ---@desc 获取难度背景
 ---@difficult 难度id
 ---@return string
--==============================
function XPivotCombatConfigs.GetDifficultBg(difficult)
    local cfg = _DifficultList[difficult]
    return cfg and cfg.Background
end

--===========================================================================
 ---@desc XConfigCenter调用的初始化函数
--===========================================================================
function XPivotCombatConfigs.Init()
    InitTableConfig()
    InitCustomConfig()
end 