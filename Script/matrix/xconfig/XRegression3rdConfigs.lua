
---@class XRegressionV2Configs 2.0特殊回归配置器
XRegression3rdConfigs = XRegression3rdConfigs or {}

--- 标签类型
---@field Main 主界面
---@field Sign 签到
---@field Passport 战令
---@field Task 任务
---@field Shop 商店
---@field Activity 活动
XRegression3rdConfigs.ActivityType = {
    Main = 1,
    Sign = 2,
    Passport = 3,
    Task = 4,
    Shop = 5,
    Activity = 6
}

--- 任务类型
---@field Daily 日常
---@field Weekly 周常
---@field Permanent 常驻
---@field TimeLimit 限时
XRegression3rdConfigs.TaskType = {
    Daily       = 1,
    Weekly      = 2,
    Permanent   = 3,
    TimeLimit   = 4
}

--- 活动状态
---@field NotInRegression 不在活动开放期内
---@field InRegression 活动开放期内
---@field RegressionEnded 活动已结束
XRegression3rdConfigs.ActivityState = {
    NotInRegression = 1,
    InRegression    = 2,
    RegressionEnded = 3,
}

--- 无效值
XRegression3rdConfigs.InValidValue = -1

--- 玩法货币Id
XRegression3rdConfigs.Regression3rdCoinId = 104


--region   ------------------表格数据 start-------------------
local TablePassportActivity  = {}
local TablePassportLevel     = {}
local TablePassportReward    = {}
local TablePassportTaskGroup = {}
local TablePassportTypeInfo  = {}
local TableActivity          = {}
local TableNewContent        = {}
local TableSignIn            = {}
local TableActivityOverView  = {}
local TableClientConfig      = {}
--endregion------------------表格数据 finish------------------


--region   ------------------表格路径 start-------------------
local TABLE_ACTIVITY_PATH = "Share/Regression3/Regression3Activity.tab"
local TABLE_PASSPORT_ACTIVITY_PATH = "Share/Regression3/Regression3PassportActivity.tab"
local TABLE_PASSPORT_LEVEL_PATH = "Share/Regression3/Regression3PassportLevel.tab"
local TABLE_PASSPORT_REWARD_PATH = "Share/Regression3/Regression3PassportReward.tab"
local TABLE_PASSPORT_TASK_GROUP_PATH = "Share/Regression3/Regression3PassportTaskGroup.tab"
local TABLE_PASSPORT_TYPE_INFO_PATH = "Share/Regression3/Regression3PassportTypeInfo.tab"
local TABLE_SIGNIN_PATH = "Share/Regression3/Regression3SignIn.tab"
local TABLE_NEW_CONTENT_PATH = "Client/Regression3/Regression3NewContent.tab"
local TABLE_ACTIVITY_OVERVIEW_PATH = "Client/Regression3/Regression3ActivityOverview.tab"
local TABLE_CLIENT_CONFIG_PATH = "Client/Regression3/Regression3ClientConfig.tab"
--endregion------------------表格路径 finish------------------


--- 配置初始化入口
--------------------------
function XRegression3rdConfigs.Init()
    --- 活动
    TableActivity = XTableManager.ReadByIntKey(TABLE_ACTIVITY_PATH, XTable.XTableRegression3Activity, "Id")
    --- 签到
    TableSignIn = XTableManager.ReadByIntKey(TABLE_SIGNIN_PATH, XTable.XTableRegression3SignIn, "Id")
    --- 战令活动
    TablePassportActivity = XTableManager.ReadByIntKey(TABLE_PASSPORT_ACTIVITY_PATH, XTable.XTableRegression3PassportActivity, "Id")
    --- 战令等级
    TablePassportLevel = XTableManager.ReadByIntKey(TABLE_PASSPORT_LEVEL_PATH, XTable.XTableRegression3PassportLevel, "Id")
    --- 战令奖励
    TablePassportReward = XTableManager.ReadByIntKey(TABLE_PASSPORT_REWARD_PATH, XTable.XTableRegression3PassportReward, "Id")
    --- 战令任务
    TablePassportTaskGroup = XTableManager.ReadByIntKey(TABLE_PASSPORT_TASK_GROUP_PATH, XTable.XTableRegression3PassportTaskGroup, "Id")
    --- 战令描述
    TablePassportTypeInfo = XTableManager.ReadByIntKey(TABLE_PASSPORT_TYPE_INFO_PATH, XTable.XTableRegression3PassportTypeInfo, "Id")
    --- 新内容
    TableNewContent = XTableManager.ReadByIntKey(TABLE_NEW_CONTENT_PATH, XTable.XTableRegression3NewContent, "Id")
    --- 活动预览
    TableActivityOverView = XTableManager.ReadByIntKey(TABLE_ACTIVITY_OVERVIEW_PATH, XTable.XTableRegression3ActivityOverview, "Id")
    --- 客户端配置
    TableClientConfig = XTableManager.ReadByStringKey(TABLE_CLIENT_CONFIG_PATH, XTable.XTableRegression3ClientConfig, "Key")
end

--region   ------------------活动 start-------------------

--- 活动配置
---@param activityId 活动Id
---@return XTableRegression3Activity
--------------------------
local function GetActivityConfig(activityId)
    local config = TableActivity[activityId]
    if not config then
        XLog.ErrorTableDataNotFound("XRegression3rdConfigs->GetActivityConfig", 
                "Regression3Activity", TABLE_ACTIVITY_PATH, "Id", tostring(activityId))
    end
    return config or {}
end

--- 活动开启时间
---@param activityId 活动Id
---@return number
--------------------------
local function GetActivityTimeId(activityId)
    return GetActivityConfig(activityId).TimeId
end

function XRegression3rdConfigs.GetActivityStartTime(activityId)
    return XFunctionManager.GetStartTimeByTimeId(GetActivityTimeId(activityId))
end

function XRegression3rdConfigs.GetActivityEndTime(activityId)
    return XFunctionManager.GetEndTimeByTimeId(GetActivityTimeId(activityId))
end

function XRegression3rdConfigs.GetShopId(activityId)
    return GetActivityConfig(activityId).ShopId
end

function XRegression3rdConfigs.GetStoryId(activityId)
    return GetActivityConfig(activityId).StoryId
end

function XRegression3rdConfigs.GetDurationTime(activityId)
    return GetActivityConfig(activityId).ContinueDays
end

function XRegression3rdConfigs.GetHelpKey(activityId)
    local helpId = GetActivityConfig(activityId).HelpId
    return XHelpCourseConfig.GetHelpCourseTemplateById(helpId).Function
end

function XRegression3rdConfigs.GetPackageUiType(activityId)
    return GetActivityConfig(activityId).PackageUiType
end

function XRegression3rdConfigs.GetContinueDays(activityId)
    return GetActivityConfig(activityId).ContinueDays
end

--- 回归活动页签配置
---@param activityId 回归活动Id
---@return XTableRegression3ActivityOverview[]
--------------------------
function XRegression3rdConfigs.GetActivityOverViewList(activityId)
    local list = {}
    for _, cfg in pairs(TableActivityOverView) do
        if cfg.ActivityId == activityId then
            table.insert(list, cfg)
        end
    end
    table.sort(list, function(a, b) 
        return a.Priority < b.Priority
    end)
    
    return list
end

--endregion------------------活动 finish------------------

--- 最大显示内容数
local MaxNewContentCount = 3

--- 获取全新内容配置
---@param lastLoginStamp 最后一次登录时间
---@return XTableRegression3NewContent[]
--------------------------
function XRegression3rdConfigs.GetNewContentList(lastLoginStamp)
    local list = {}
    for _, cfg in pairs(TableNewContent) do
        local timeStamp = XTime.ParseToTimestamp(cfg.UpdateTime)
        if lastLoginStamp < timeStamp then
            table.insert(list, cfg)
        end
    end

    table.sort(list, function(a, b)
        return a.Priority < b.Priority
    end)
    
    if #list > MaxNewContentCount then
        local tmpList = {}
        for i = 1, MaxNewContentCount do
            tmpList[i] = list[i]
        end
        
        list = tmpList
    end

    return list
end

--region   ------------------签到 start-------------------

--- 活动签到列表
---@param activityId 回归活动Id
---@return XTableRegression3SignIn[]
--------------------------
function XRegression3rdConfigs.GetSignInList(activityId)
    local list = {}
    for _, cfg in pairs(TableSignIn) do
        if cfg.ActivityId == activityId then
            table.insert(list, cfg)
        end
    end
    table.sort(list, function(a, b) 
        return a.Days < b.Days
    end)
    return list
end

--- 签到配置
---@param signId 签到配置Id
---@return XTableRegression3SignIn
function XRegression3rdConfigs.GetSignTemplate(signId)
    local template = TableSignIn[signId]
    if not template then
        XLog.ErrorTableDataNotFound("XRegression3rdConfigs.GetSignTemplate", "Regression3SignIn", TABLE_SIGNIN_PATH, "Id", tostring(signId))
        return {}
    end
    return template
end

--endregion------------------签到 finish------------------


--region   ------------------战令 start-------------------

--- 战令活动配置
local _PassportActivity
--- 当期战令类型配置
local _PassportTypeInfo
--- 当期战令等级信息
local _PassportLevelInfo
--- 当期战令奖励信息
local _PassportRewardInfo
--- 战令任务
local _PassportTaskInfo = {}

--- 战令活动配置
---@param activityId 回归活动Id
---@return XTableRegression3PassportActivity
--------------------------
local function GetPassportActivity(activityId)
    if not XTool.IsNumberValid(activityId) then
        XLog.Error("XRegression3rdConfigs->GetPassportActivity: invalid activityId: " .. activityId)
        return {}
    end
    if not _PassportActivity or _PassportActivity.ActivityId ~= activityId then
        for _, cfg in pairs(TablePassportActivity) do
            if cfg.ActivityId == activityId then
                _PassportActivity = cfg
                break
            end
        end
    end
    return _PassportActivity
end

--- 活动结束前x秒，禁止购买战令
---@param passportActivityId 战令活动Id
---@return number
--------------------------
function XRegression3rdConfigs.GetBuyPassportEndTime(passportActivityId)
    return GetPassportActivity(passportActivityId).BuyPassPortEarlyEndTime
end

--- 战令活动名
---@param passportActivityId 战令活动Id
---@return string
--------------------------
function XRegression3rdConfigs.GetPassportName(passportActivityId)
    return GetPassportActivity(passportActivityId).Name
end

--- 战令任务组id
---@param passportActivityId 战令活动Id
---@return number
--------------------------
function XRegression3rdConfigs.GetPassportTaskGroupId(passportActivityId)
    return GetPassportActivity(passportActivityId).TaskGroup
end

--- 根据玩法活动Id获取战令活动Id
---@param activityId 玩法活动Id
---@return number
--------------------------
function XRegression3rdConfigs.GetPassportActivityId(activityId)
    local passportActivityId
    for _, passportActivity in pairs(TablePassportActivity) do
        if passportActivity.ActivityId == activityId then
            passportActivityId = passportActivity.Id
        end
    end
    return passportActivityId
end

--- 初始化战令类型数据
---@param passportActivityId 战令活动Id
---@return nil
--------------------------
local function InitPassportTypeInfo(passportActivityId)
    _PassportTypeInfo = {}
    for _, typeInfo in pairs(TablePassportTypeInfo) do
        if typeInfo.PassportActivityId == passportActivityId then
            table.insert(_PassportTypeInfo, typeInfo)
        end
    end
    table.sort(_PassportTypeInfo, function(a, b)
        return a.Id < b.Id
    end)
end

--- 初始化战令等级数据
---@param passportActivityId 战令活动Id
---@return
--------------------------
local function InitPassportLevelInfo(passportActivityId)
    _PassportLevelInfo = {}
    for _, levelInfo in pairs(TablePassportLevel) do
        if levelInfo.PassportActivityId == passportActivityId and levelInfo.Level > 0 then
            table.insert(_PassportLevelInfo, levelInfo)
        end
    end
    table.sort(_PassportLevelInfo, function(a, b)
        return a.Level < b.Level
    end)
end

--- 初始化战令奖励数据
---@param typeInfos 当期的战令类型
---@return
--------------------------
local function InitPassportRewardInfo(typeInfos) 
    local typeIdDict = {}
    for _, info in ipairs(typeInfos) do
        typeIdDict[info.Id] = true
    end
    _PassportRewardInfo = {}
    for _, info in pairs(TablePassportReward) do
        local passportId = info.PassportId
        --只存当期的奖励数据
        if typeIdDict[passportId] then
            _PassportRewardInfo[passportId] = _PassportRewardInfo[passportId] or {}
            _PassportRewardInfo[passportId][info.Level] = info.Id
        end
    end
end

--- 初始化战令任务数据
---@param taskType 任务类型
---@param groupId 任务组Id
---@return nil
--------------------------
local function InitPassportTask(taskType, groupId)
    _PassportTaskInfo[groupId] = _PassportTaskInfo[groupId] or {}
    local dict = {}
    for id, group in pairs(TablePassportTaskGroup) do
        local opened = XFunctionManager.CheckInTimeByTimeId(group.TimeId, true)
        if group.Type == taskType and group.Group == groupId and opened then
            for _, taskId in ipairs(group.TaskId) do
                dict[taskId] = id
            end
        end
    end
    _PassportTaskInfo[groupId][taskType] = dict
end

--- 获取任务数据
---@param taskType 任务类型
---@param groupId 任务组Id
---@return table<number, number>
--------------------------
local function GetPassportTaskDict(taskType, groupId)
    if not _PassportTaskInfo[groupId] or not _PassportTaskInfo[groupId][taskType] then
        InitPassportTask(taskType, groupId)
    end
    return _PassportTaskInfo[groupId][taskType]
end

local function GetPassportTypeInfoTemplate(typeInfoId) 
    local template = TablePassportTypeInfo[typeInfoId]
    if not template then
        XLog.ErrorTableDataNotFound("XRegression3rdConfigs->GetPassportTypeInfoTemplate", 
                "Regression3PassportTypeInfo", TABLE_PASSPORT_TYPE_INFO_PATH, "Id", typeInfoId)
        return {}
    end
    return template
end

local function GetPassportRewardTemplate(rewardId) 
    local template = TablePassportReward[rewardId]
    if not template then
        XLog.ErrorTableDataNotFound("XRegression3rdConfigs->GetPassportRewardTemplate",
                "Regression3PassportReward", TABLE_PASSPORT_REWARD_PATH, "Id", rewardId)
        return {}
    end
    return template
end

function XRegression3rdConfigs.GetPassportTypeInfos(passportActivityId)
    if not _PassportTypeInfo or _PassportTypeInfo[1].PassportActivityId ~= passportActivityId then
        InitPassportTypeInfo(passportActivityId)
    end
    return _PassportTypeInfo
end

function XRegression3rdConfigs.GetPassportLevelInfos(passportActivityId)
    if not _PassportLevelInfo or _PassportLevelInfo[1].PassportActivityId ~= passportActivityId then
        InitPassportLevelInfo(passportActivityId)
    end
    return _PassportLevelInfo
end

function XRegression3rdConfigs.GetPassportRewardInfos(passportActivityId)
    local typeInfo = XRegression3rdConfigs.GetPassportTypeInfos(passportActivityId)
    local id = typeInfo[1].Id
    --兼容在线切换passportActivityId
    if not _PassportRewardInfo or _PassportRewardInfo[id] == nil then
        InitPassportRewardInfo(typeInfo)
    end
    return _PassportRewardInfo
end

function XRegression3rdConfigs.GetPassportRewardInfo(passportActivityId, typeInfoId, level)
    local infos = XRegression3rdConfigs.GetPassportRewardInfos(passportActivityId)
    local id = infos[typeInfoId][level]
    return TablePassportReward[id] or {}
end

function XRegression3rdConfigs.GetPassportRewardInfoById(rewardId)
    return GetPassportRewardTemplate(rewardId)
end

function XRegression3rdConfigs.GetPassportTypeInfoTemplate(typeInfoId)
    return GetPassportTypeInfoTemplate(typeInfoId)
end

function XRegression3rdConfigs.GetPassportTaskGroupTemplateByTaskId(groupId, taskId)
    if not _PassportTaskInfo[groupId] then
        XLog.Error("XRegression3rdConfigs.GetPassportTaskGroupTemplateByTaskId error: task info uninitialized complete!!")
        return {}
    end
    for _, taskType in pairs(XRegression3rdConfigs.TaskType) do
        local dict = GetPassportTaskDict(taskType, groupId)
        if not XTool.IsTableEmpty(dict) then
            local taskGroupId = dict[taskId]
            if XTool.IsNumberValid(taskGroupId) then
                return TablePassportTaskGroup[taskGroupId]
            end
        end
    end
    XLog.Error("XRegression3rdConfigs.GetPassportTaskGroupTemplateByTaskId error: task id = " .. taskId .. " not found")
    return {}
end

--- 获取任务列表
---@param taskType 任务类型
---@param groupId 任务组Id
---@return number[]
--------------------------
function XRegression3rdConfigs.GetPassportTaskList(taskType, groupId)
    local dict = GetPassportTaskDict(taskType, groupId)
    local list = {}
    local defaultOpen = taskType ~= XRegression3rdConfigs.TaskType.TimeLimit and true or false
    for taskId, group in pairs(dict or {}) do
        local template = TablePassportTaskGroup[group]
        local timeId = template and template.TimeId or 0
        local open = XFunctionManager.CheckInTimeByTimeId(timeId, defaultOpen)
        if open then
            table.insert(list, taskId)
        end
    end 
    return list
end

--endregion------------------战令 finish------------------

--region   ------------------客户端配置 start-------------------
local function GetClientConfig(key)
    local cfg = TableClientConfig[key]
    if not cfg then
        XLog.ErrorTableDataNotFound("XRegression3rdConfigs->GetClientConfig", "Regression3ClientConfig", TABLE_CLIENT_CONFIG_PATH, "Key", key)
        return {}
    end
    return cfg
end

--客户端配置
function XRegression3rdConfigs.GetClientConfigValue(key, index)
    local values = GetClientConfig(key).Values
    return values[index]
end
--endregion------------------客户端配置 finish------------------