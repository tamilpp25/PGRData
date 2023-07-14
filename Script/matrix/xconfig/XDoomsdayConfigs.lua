local tonumber = tonumber
local tableInsert = table.insert
local tableSort = table.sort
local ipairs = ipairs
local pairs = pairs

XDoomsdayConfigs = XDoomsdayConfigs or {}

function XDoomsdayConfigs.Init()
    XDoomsdayConfigs.ActivityConfig =
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayActivity.tab", XTable.XTableDoomsdayActivity) --活动配置
    XDoomsdayConfigs.StageConfig =
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayStage.tab", XTable.XTableDoomsdayStage) --关卡配置
    XDoomsdayConfigs.PlaceConfig =
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayStagePlace.tab", XTable.XTableDoomsdayStagePlace) --探索地点配置
    XDoomsdayConfigs.ResourceConfig =
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayResource.tab", XTable.XTableDoomsdayResource) --资源配置
    XDoomsdayConfigs.EventConfig =
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayEvent.tab", XTable.XTableDoomsdayEvent) --关卡事件配置
    XDoomsdayConfigs.CreatTeamConfig =
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayCreateTeam.tab", XTable.XTableDoomsdayCreateTeam) --探索队伍创建消耗配置
    XDoomsdayConfigs.BuildingConfig =
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayBuilding.tab", XTable.XTableDoomsdayBuilding) --建筑配置
    XDoomsdayConfigs.AttributeConfig =
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayAttribute.tab", XTable.XTableDoomsdayAttribute) --属性配置
    XDoomsdayConfigs.TargetConfig =
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayTask.tab", XTable.XTableDoomsdayTask) --关卡目标配置
    XDoomsdayConfigs.StageEndingConfig =
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayStageEnding.tab", XTable.XTableDoomsdayStageEnding) --关卡结局配置
    XDoomsdayConfigs.AttributeTypeConfig =
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayAttributeType.tab", XTable.XTableDoomsdayAttributeType) --属性类型配置
    XDoomsdayConfigs.ReportConfig =
        XConfig.New("Client/MiniActivity/Doomsday/DoomsdayReportText.tab", XTable.XTableDoomsdayReportText) --报告内容随机文本库配置
    XDoomsdayConfigs.ResourceAllotConfig =
        XConfig.New("Client/MiniActivity/Doomsday/DoomsdayResourceAllot.tab", XTable.XTableDoomsdayResourceAllot) --资源分配方式配置
    XDoomsdayConfigs.WeatherConfig = 
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayWeather.tab", XTable.XTableDoomsdayWeather) --天气配置表
    XDoomsdayConfigs.ConditionConfig =
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayCondition.tab", XTable.XTableDoomsdayCondition) --条件配置表
    XDoomsdayConfigs.BroadcastConfig =
        XConfig.New("Client/MiniActivity/Doomsday/DoomsdayBroadcast.tab", XTable.XTableDoomsdayBroadcast, "Type") --条件配置表
    XDoomsdayConfigs.CommonConfig = 
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayCfg.tab", XTable.XTableDoomsdayCfg, "Key", true) --活动通用配置表
    XDoomsdayConfigs.InitText()

    --结算黑幕持续时间
    XDoomsdayConfigs.BLACK_MASK_DURATION = XDoomsdayConfigs.BLACK_MASK_DURATION or tonumber(XDoomsdayConfigs.CommonConfig:GetProperty("BlackMaskDuration", "Value"))
    --报告结算动画时间
    XDoomsdayConfigs.DOOMSDAY_REPORT_ANIMA_TIME = XDoomsdayConfigs.DOOMSDAY_REPORT_ANIMA_TIME or tonumber(XDoomsdayConfigs.CommonConfig:GetProperty("DoomsdayReportAnimaTime", "Value"))
end

-----------------活动相关 begin-----------------
function XDoomsdayConfigs.GetDefaultActivityId()
    local defaultActivityId = 0
    for activityId, config in pairs(XDoomsdayConfigs.ActivityConfig:GetConfigs()) do
        defaultActivityId = activityId
        if XTool.IsNumberValid(config.TimeId) and XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
            break
        end
    end
    return defaultActivityId
end

--获取后置关卡Id
function XDoomsdayConfigs.GetAfterStageId(activityId, stageId)
    for _, inStageId in pairs(XDoomsdayConfigs.ActivityConfig:GetProperty(activityId, "StageId") or {}) do
        if XDoomsdayConfigs.StageConfig:GetProperty(inStageId, "PreStage") == stageId then
            return inStageId
        end
    end
    return 0
end
---------------活动相关 end-------------------
--居民属性类型
XDoomsdayConfigs.ATTRUBUTE_TYPE = {
    HEALTH = 1, --健康值
    HUNGER = 2, --饱腹值
    SAN = 3 --精神值
}

XDoomsdayConfigs.HOMELESS_ATTR_TYPE = 4 --无家可归属性类型（策划要放到其他居民属性一起展示）

function XDoomsdayConfigs.GetSortedAttrTypes()
    return {
        XDoomsdayConfigs.ATTRUBUTE_TYPE.HEALTH,
        XDoomsdayConfigs.ATTRUBUTE_TYPE.HUNGER,
        XDoomsdayConfigs.ATTRUBUTE_TYPE.SAN
    }
end

--获取关卡每日单居民需求资源数量（仅分配资源使用）
function XDoomsdayConfigs.GetStageDailyRequireResourceCount(stageId, resourceId)
    for index, inResourceId in pairs(XDoomsdayConfigs.StageConfig:GetProperty(stageId, "DailyConsumeResouceId")) do
        if inResourceId == resourceId then
            return XDoomsdayConfigs.StageConfig:GetProperty(stageId, "DailyConsumeResouceCount")[index] or 0
        end
    end
    return 0
end

--根据资源Id获取关联的居民属性Type
function XDoomsdayConfigs.GetRelatedAttrIdByResourceId(stageId, resourceId)
    local attrList = XDoomsdayConfigs.WeatherConfig:GetProperty(self._CurWeatherId, "AttributeId")
    --XDoomsdayConfigs.StageConfig:GetProperty(stageId, "AttributeId")
    for _, attrId in pairs(attrList) do
        if XDoomsdayConfigs.AttributeConfig:GetProperty(attrId, "ResourceId") == resourceId then
            return attrId
        end
    end
    return 0
end

function XDoomsdayConfigs.GetWeatherSortList(stageId)
    local list = XDoomsdayConfigs.StageConfig:GetProperty(stageId, "PossibleWeather")
    
    tableSort(list, function(a, b) 
        return a < b
    end)
    
    return list
end

--关卡事件类型
XDoomsdayConfigs.EVENT_TYPE = {
    MAIN = 1, --主要事件
    NORMAL = 2, --普通事件
    EXPLORE = 3 --探索事件
}

--事件类型按照表现形式
XDoomsdayConfigs.EVENT_TYPE_EXPRESSION = {
    NORMAL  = 1, --带子事件的事件类型
    SPECIAL = 2, --不带子事件，会直接执行
}

--播报类型
XDoomsdayConfigs.BROADCAST_TYPE = {
    DEATH       = 1, --死亡播报 
    LOG         = 2, --日志播报
    ACHIEVEMENT = 3, --成就播报
}

function XDoomsdayConfigs.GetEventTypeRemindDesc(eventType)
    if eventType == XDoomsdayConfigs.EVENT_TYPE.MAIN then
        return CsXTextManagerGetText("DoomsdayEventTypeRemindDescMain")
    elseif eventType == XDoomsdayConfigs.EVENT_TYPE.EXPLORE then
        return CsXTextManagerGetText("DoomsdayEventTypeRemindDescExplore")
    end
    return CsXTextManagerGetText("DoomsdayEventTypeRemindDescNormal")
end

--获取资源Id列表（brief：简明模式，只显示前两种资源）
function XDoomsdayConfigs.GetResourceIds(brief)
    local ids = {}
    local limitCount = brief and 2 or XMath.IntMax()
    for id in ipairs(XDoomsdayConfigs.ResourceConfig:GetConfigs()) do
        if id > limitCount then
            break
        end
        tableInsert(ids, id)
    end
    return ids
end

local function CreateReourceList(ids, counts, daily)
    local resources = {}
    for index, id in ipairs(ids) do
        if XTool.IsNumberValid(id) then
            tableInsert(
                resources,
                {
                    Id = id,
                    Count = counts[index],
                    Daily = daily
                }
            )
        end
    end
    return resources
end

--获取建筑建造消耗资源列表
function XDoomsdayConfigs.GetBuildingConstructResourceInfos(buildingId)
    return CreateReourceList(
        XDoomsdayConfigs.BuildingConfig:GetProperty(buildingId, "SpendResourceType"),
        XDoomsdayConfigs.BuildingConfig:GetProperty(buildingId, "SpendResourceCount")
    )
end

--获取建筑工作中每日消耗资源列表
function XDoomsdayConfigs.GetBuildingDailyConsumeResourceInfos(buildingId)
    return CreateReourceList(
        XDoomsdayConfigs.BuildingConfig:GetProperty(buildingId, "WorkingDailyConsumeResourceId"),
        XDoomsdayConfigs.BuildingConfig:GetProperty(buildingId, "WorkingDailyConsumeResourceCount"),
        true
    )
end

--获取建筑工作中每日获得资源列表
function XDoomsdayConfigs.GetBuildingDailyGainResourceInfos(buildingId)
    return CreateReourceList(
        XDoomsdayConfigs.BuildingConfig:GetProperty(buildingId, "WorkingDailyGainResourceId"),
        XDoomsdayConfigs.BuildingConfig:GetProperty(buildingId, "WorkingDailyGainResourceCount"),
        true
    )
end

--建筑类型（一期只区分简单建筑类型）
XDoomsdayConfigs.BUILDING_TYPE = {
    NORMAL = 0, --普通
    RUINS = 1, --废墟
    INOPERABLE = 2, --不可操作类型
    TEAM = 3 --哨站（用于解锁探索小队）
}

function XDoomsdayConfigs.IsBuildingRuins(buildingId)
    return XDoomsdayConfigs.BuildingConfig:GetProperty(buildingId, "Type") == XDoomsdayConfigs.BUILDING_TYPE.RUINS
end

function XDoomsdayConfigs.IsBuildingInOperable(buildingId)
    if not XTool.IsNumberValid(buildingId) then
        return false
    end
    return XDoomsdayConfigs.BuildingConfig:GetProperty(buildingId, "Type") == XDoomsdayConfigs.BUILDING_TYPE.INOPERABLE
end

--建筑状态
XDoomsdayConfigs.BUILDING_STATE = {
    EMPTY = 0, --空
    WAITING = 1, --等待分配
    WORKING = 2, --工作中
    PENDING = 3, --工作中断
    BUILDING = 4, --建造中
    UNDERSTAFFED = 5 --人手不足
}

--不同建筑状态的图标
local CSXGameClientConfig = CS.XGame.ClientConfig
XDoomsdayConfigs.BuildingTypeIcon = {
    --[XDoomsdayConfigs.BUILDING_STATE.EMPTY] = CSXGameClientConfig:GetString("DoomsdayBuildingStateIconEmpty"),
    [XDoomsdayConfigs.BUILDING_STATE.WAITING] = CSXGameClientConfig:GetString("DoomsdayBuildingStateIconWaiting"),
    [XDoomsdayConfigs.BUILDING_STATE.WORKING] = CSXGameClientConfig:GetString("DoomsdayBuildingStateIconWorking"),
    [XDoomsdayConfigs.BUILDING_STATE.PENDING] = CSXGameClientConfig:GetString("DoomsdayBuildingStateIconPending"),
    [XDoomsdayConfigs.BUILDING_STATE.BUILDING] = CSXGameClientConfig:GetString("DoomsdayBuildingStateIconBuilding"),
    [XDoomsdayConfigs.BUILDING_STATE.UNDERSTAFFED] = CSXGameClientConfig:GetString("DoomsdayBuildingStateIconUnderstaffed"),
}
XDoomsdayConfigs.EmptyBuildingIcon = CSXGameClientConfig:GetString("DoomsdayBuildingIconEmpty")
--资源类型
XDoomsdayConfigs.RESOURCE_TYPE = {
    WOOD = 1, --木材
    STEEL = 2, --钢材
    MEDICINE = 3, --血清
    FOOD = 4 --食物
}
XDoomsdayConfigs.SPECIAL_RESOURCE_TYPE_INHANBITANT = -1 --特殊资源类型：居民

--资源分配方式
XDoomsdayConfigs.RESOURCE_ALLOCTION_FUNC_NAME = {
    ALL = "GetResourceAllocationByAllocateToAll", --给所有人分配
    HALF = "GetResourceAllocationByAllocateToHalf", --给一半人分配
    MOST = "GetResourceAllocationByAllocateToMost", --给尽可能多的人分配
    NONE = "GetResourceAllocationByAllocateToNone" --不分配
}

local GetNumberTextWithColor = function(num, isInverse, isHidePlus, isBrackets, unit)
    unit = unit or ""
    if num > 0 then
        local symbol = isHidePlus and "" or "+"
        local content = isBrackets and "(%s%s)" or "%s%s"
        local tmpNum = string.format(content, symbol, math.abs(num))
        local tmpStr = isInverse and CSXTextManagerGetText("DoomsdayNumberNegativeGrowth", tmpNum) or CSXTextManagerGetText("DoomsdayNumberPositiveGrowth", tmpNum)
        return tmpStr .. unit
    end

    if num < 0 then
        local content = isBrackets and "(-%s)" or "-%s"
        local tmpNum = string.format(content, math.abs(num))
        local tmpStr = isInverse and CSXTextManagerGetText("DoomsdayNumberPositiveGrowth", tmpNum) or CSXTextManagerGetText("DoomsdayNumberNegativeGrowth", tmpNum)
        return tmpStr .. unit
    end

    return ""
end

--==============================
 ---@desc 获取上升，下降两中颜色的数字文本
 ---@isInverse 是否翻转， 上升为红色，下降为绿色 
 ---@isHidePlus 正数不显示加号
 ---@isBrackets 是否显示小括号
 ---@unit 单位 50/天
 ---@return string
--==============================
function XDoomsdayConfigs.GetNumberText(num, isInverse, isHidePlus, isBrackets, unit)
    return GetNumberTextWithColor(num, isInverse, isHidePlus, isBrackets, unit)
end

-- 属性消耗  心情值上升50 心情值下降50
function XDoomsdayConfigs.GetDoomsdayAttributeWithDaily(num, attrName)
    num = num or 0
    if num > 0 then
        return CSXTextManagerGetText("DoomsdayAttributeUpWithDaily", attrName, num)
    else
        return CSXTextManagerGetText("DoomsdayAttributeDownWithDaily", attrName, num)
    end
end

--获取加减不同颜色的数字文本 （50/100 红色）（100/100 蓝色）
function XDoomsdayConfigs.GetRequireNumerText(cur, max)
    if cur < max then
        return CsXTextManagerGetText("DoomsdayRequireNumberDown", cur, max)
    else
        return CsXTextManagerGetText("DoomsdayRequireNumberUp", cur, max)
    end
end

--每日结算报告
XDoomsdayConfigs.REPORT_ID = {
    BUILDING_ADD = 1, --营地增加资源
    TEAM_ADD = 2, --探索小队增加资源/居民数量
    DEAD = 3, --死去居民文本显示
    HOMELESS = 4, --不良状态随机文本(无家可归)
    UNHEALTHY = 5, --不良状态随机文本(不健康)
    HUNGER = 6, --不良状态随机文本(饥饿)
    LOW_SAN = 7, --不良状态随机文本(精神值过低)
    HOMELESS_RT = 8, --不良状态随机文本(无家可归)【反向判断】
    UNHEALTHY_RT = 9, --不良状态随机文本(不健康)【反向判断】
    HUNGER_RT = 10, --不良状态随机文本(饥饿)【反向判断】
    LOW_SAN_RT = 11, --不良状态随机文本(精神值过低)【反向判断】
    BUILDING_ADD_RT = 12 --营地增加资源【反向判断】
}

--获取随机文本报告
local function GetRandomReportText(reportId)
    local descs = XDoomsdayConfigs.ReportConfig:GetProperty(reportId, "Desc")
    return descs[XTool.GetRandomNumbers(#descs, 1)[1]]
end

--获取异常状态/死亡居民随机文本报告
function XDoomsdayConfigs.GetRandomReportTextBad(reportId, addInhabitantCount)
    local desc, addText = GetRandomReportText(reportId), ""

    if XTool.IsNumberValid(addInhabitantCount) then
        addText =
            CsXTextManagerGetText(
            "DoomsdayReportResource",
            addInhabitantCount,
            CsXTextManagerGetText("DoomsdayInhabitantName")
        )
    end

    if not string.IsNilOrEmpty(addText) then
        desc = string.gsub(desc, "{0}", addText)
    end

    return desc
end

--获取获得资源随机文本报告
function XDoomsdayConfigs.GetRandomReportTextFix(reportId, addResourceDic, addInhabitantCount)
    local desc, addText = "", ""

    if XTool.IsNumberValid(addInhabitantCount) then
        addText =
            CsXTextManagerGetText(
            "DoomsdayReportResource",
            addInhabitantCount,
            CsXTextManagerGetText("DoomsdayInhabitantName")
        )
    end

    if not XTool.IsTableEmpty(addResourceDic) then
        for resourceId, resource in pairs(addResourceDic) do
            local count = resource:GetProperty("_Count")
            if XTool.IsNumberValid(count) then
                local newText =
                    CsXTextManagerGetText(
                    "DoomsdayReportResource",
                    count,
                    XDoomsdayConfigs.ResourceConfig:GetProperty(resourceId, "Name")
                )
                addText = string.IsNilOrEmpty(addText) and newText or addText .. "、" .. newText
            end
        end
    end

    if not string.IsNilOrEmpty(addText) then
        desc = GetRandomReportText(reportId)
        desc = string.gsub(desc, "{0}", addText)
    else
        if reportId == XDoomsdayConfigs.REPORT_ID.BUILDING_ADD then
            desc = GetRandomReportText(XDoomsdayConfigs.REPORT_ID.BUILDING_ADD_RT)
        end
    end

    return desc
end

--检查指定地点Id是否为大本营
function XDoomsdayConfigs.CheckPlaceIsCamp(stageId, placeId)
    if not XTool.IsNumberValid(stageId) 
            or not XTool.IsNumberValid(placeId) then
        return false
    end
    return XDoomsdayConfigs.StageConfig:GetProperty(stageId, "FirstPlace") == placeId
end

function XDoomsdayConfigs.GetCreateTeamCostResourceList(teamId)
    local infoList = {}

    local countList = XDoomsdayConfigs.CreatTeamConfig:GetProperty(teamId, "SpendResourceCount")
    for index, resourceId in pairs(XDoomsdayConfigs.CreatTeamConfig:GetProperty(teamId, "SpendResourceType")) do
        tableInsert(
            infoList,
            {
                ResourceId = resourceId,
                Count = countList[index] or 0
            }
        )
    end

    return infoList
end

--关卡失败原因
XDoomsdayConfigs.SETTLE_LOSE_REASON = {
    INHABITANT_DIE_OUT = 1, --居民死光
    INHABITANT_CRAZY = 2, --居民SAN值全部降为0
    INHABITANT_TIME_OUT = 3 --时间用尽未达成主目标
}

--关卡失败描述文本
function XDoomsdayConfigs.InitText()
    XDoomsdayConfigs.LOSE_REASON_TEXT = {
        [XDoomsdayConfigs.SETTLE_LOSE_REASON.INHABITANT_DIE_OUT] = CsXTextManagerGetText("DoomsdayLoseReasonDieOut"), --居民死光
        [XDoomsdayConfigs.SETTLE_LOSE_REASON.INHABITANT_CRAZY] = CsXTextManagerGetText("DoomsdayLoseReasonCrazy"), --居民SAN值全部降为0
        [XDoomsdayConfigs.SETTLE_LOSE_REASON.INHABITANT_TIME_OUT] = CsXTextManagerGetText("DoomsdayLoseReasonTimeOut") --时间用尽未达成主目标
    }
end

--探索小队状态
XDoomsdayConfigs.TEAM_STATE = {
    WAITING = 1, --待命
    MOVING = 2, --行进中
    BUSY = 3 --事件中
}

--探索路线特效
function XDoomsdayConfigs.GetExplorePathFx()
    return XUiConfigs.GetComponentUrl("DoomsdayFxUiTansuoluxian")
end


local ConditionType = {
    
    [101] = function(condition, ...)  --指定资源存量小于一定数量
        local args = { ... }
        local stageId = args[1]
        local resourceId, resourceCount = condition.Args[1], condition.Args[2]
        local stage = XDataCenter.DoomsdayManager.GetStageData(stageId)
        local resource = stage:GetResource(resourceId)
        if not resource or resource:GetProperty("_Count") >= resourceCount then
            return false, condition.Desc
        end
        return true, condition.Desc
    end,
    
    [102] = function(condition, ...) --指定资源存量大于等于一定数量
        local args = { ... }
        local stageId = args[1]
        local resourceId, resourceCount = condition.Args[1], condition.Args[2]
        local stage = XDataCenter.DoomsdayManager.GetStageData(stageId)
        local resource = stage:GetResource(resourceId)
        if not resource or resource:GetProperty("_Count") < resourceCount then
            return false, condition.Desc
        end
        return true, condition.Desc
    end,
    
    [205] = function(condition, ...) --营地内某属性值小于等于指定值
        local args = { ... }
        local stageId = args[1]
        local stage = XDataCenter.DoomsdayManager.GetStageData(stageId)
        local attrType, value = condition.Args[1], condition.Args[2]
        local attrValue = stage:GetAverageInhabitantAttr(attrType)
        if attrValue > value then
            return false, condition.Desc
        end
        return true, condition.Desc
    end,

    [206] = function(condition, ...) --营地内某属性值大于指定值
        local args = { ... }
        local stageId = args[1]
        local stage = XDataCenter.DoomsdayManager.GetStageData(stageId)
        local attrType, value = condition.Args[1], condition.Args[2]
        local attrValue = stage:GetAverageInhabitantAttr(attrType)
        if attrValue <= value then
            return false, condition.Desc
        end
        return true, condition.Desc
    end,
    
    [301] = function(condition, ...) --拥有指定数量的指定建筑（场上存在建筑就算）
        local args = { ... }
        local stageId = args[1]
        local stage = XDataCenter.DoomsdayManager.GetStageData(stageId)
        local preBuildId, needCount = tonumber(condition.Args[1]), tonumber(condition.Args[2])
        local desc = string.format(condition.Desc, needCount, XDoomsdayConfigs.BuildingConfig:GetProperty(preBuildId, "Name"))
        local hasBuildCount = stage:GetFinishBuildingMember(preBuildId)
        return hasBuildCount >= needCount, desc
    end,
    
    [601] = function(condition, ...) --已完成前置事件
        local args = { ... }
        local stageId = args[1]
        local stage = XDataCenter.DoomsdayManager.GetStageData(stageId)
        local eventId, select = tonumber(condition.Args[1]), tonumber(condition.Args[2] or 0)
        local event = stage:GetEvent(eventId)
        if not event then
            return false, condition.Desc
        end
        if select == 0 then
            return event:GetProperty("_Finished"), condition.Desc
        else
            --配置起始值为1，代码为0
            return event:GetProperty("_Select") == select - 1, condition.Desc
        end
    end,
    
    [901] = function(condition, ...) --已完成指定事件事件
        local args = { ... }
        local stageId = args[1]
        local stage = XDataCenter.DoomsdayManager.GetStageData(stageId)
        local eventId = condition.Args[1]
        local event = stage:GetEvent(eventId)
        if not event then
            return false, condition.Desc
        end
        return event:GetProperty("_Finished"), condition.Desc
    end,
}

function XDoomsdayConfigs.CheckCondition(id, ...)
    local type = XDoomsdayConfigs.ConditionConfig:GetProperty(id, "Type")
    
    local func = ConditionType[type]
    if not func then
        XLog.Error(
                "XDoomsdayConfigs.CheckCondition error: can not found condition, id is " ..
                        id .. " type is " .. type
        )
        return true
    end
    return func(XDoomsdayConfigs.ConditionConfig:GetConfig(id), ...)
end
