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
    XDoomsdayConfigs.AttributeTypeConfig =
        XConfig.New("Share/MiniActivity/Doomsday/DoomsdayAttributeType.tab", XTable.XTableDoomsdayAttributeType) --属性类型配置
    XDoomsdayConfigs.ReportConfig =
        XConfig.New("Client/MiniActivity/Doomsday/DoomsdayReportText.tab", XTable.XTableDoomsdayReportText) --报告内容随机文本库配置
    XDoomsdayConfigs.ResourceAllotConfig =
        XConfig.New("Client/MiniActivity/Doomsday/DoomsdayResourceAllot.tab", XTable.XTableDoomsdayResourceAllot) --资源分配方式配置
    XDoomsdayConfigs.InitText()
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
    for _, attrId in pairs(XDoomsdayConfigs.StageConfig:GetProperty(stageId, "AttributeId")) do
        if XDoomsdayConfigs.AttributeConfig:GetProperty(attrId, "ResourceId") == resourceId then
            return attrId
        end
    end
    return 0
end

--关卡事件类型
XDoomsdayConfigs.EVENT_TYPE = {
    MAIN = 1, --主要事件
    NORMAL = 2, --普通事件
    EXPLORE = 3 --探索事件
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
    PENDING = 3 --工作中断
}

--不同建筑状态的图标
local CSXGameClientConfig = CS.XGame.ClientConfig
XDoomsdayConfigs.BuildingTypeIcon = {
    [XDoomsdayConfigs.BUILDING_STATE.EMPTY] = CSXGameClientConfig:GetString("DoomsdayBuildingStateIconEmpty"),
    [XDoomsdayConfigs.BUILDING_STATE.WAITING] = CSXGameClientConfig:GetString("DoomsdayBuildingStateIconWaiting"),
    [XDoomsdayConfigs.BUILDING_STATE.WORKING] = CSXGameClientConfig:GetString("DoomsdayBuildingStateIconWorking"),
    [XDoomsdayConfigs.BUILDING_STATE.PENDING] = CSXGameClientConfig:GetString("DoomsdayBuildingStateIconPending")
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

--获取加减不同颜色的数字文本 （+50）（-50）
function XDoomsdayConfigs.GetNumerText(num)
    if num > 0 then
        return CsXTextManagerGetText("DoomsdayNumberUp", math.abs(num))
    end

    if num < 0 then
        return CsXTextManagerGetText("DoomsdayNumberDown", math.abs(num))
    end

    return ""
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
