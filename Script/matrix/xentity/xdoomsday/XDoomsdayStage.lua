local XDoomsdayInhabitant = require("XEntity/XDoomsday/XDoomsdayInhabitant")
local XDoomsdayPlace = require("XEntity/XDoomsday/XDoomsdayPlace")
local XDoomsdayEvent = require("XEntity/XDoomsday/XDoomsdayEvent")
local XDoomsdayBuilding = require("XEntity/XDoomsday/XDoomsdayBuilding")
local XDoomsdayTarget = require("XEntity/XDoomsday/XDoomsdayTarget")
local XDoomsdayTeam = require("XEntity/XDoomsday/XDoomsdayTeam")
local XDoomsdayResource = require("XEntity/XDoomsday/XDoomsdayResource")
local XDoomsdayAttribute = require("XEntity/XDoomsday/XDoomsdayAttribute")

local tableInsert = table.insert
local tableSort = table.sort

--[[    
public class XDoomsdayStageDb
{
   public int Id;
    public int DayCount;
    public List<XDoomsdayPlaceDb> PlaceDbList = new List<XDoomsdayPlaceDb>();
    public List<XDoomsdayEventDb> EventDbList = new List<XDoomsdayEventDb>();
    public List<XDoomsdayBuildingDb> BuildingDbList = new List<XDoomsdayBuildingDb>();
    public List<XDoomsdayTaskDb> TaskDbList = new List<XDoomsdayTaskDb>();
    public List<XDoomsdayTeamDb> TeamDbList = new List<XDoomsdayTeamDb>();
    public List<XDoomsdayResourceDb> ResourceList = new List<XDoomsdayResourceDb>();
    public List<XDoomsdayPeopleDb> PeopleDbList = new List<XDoomsdayPeopleDb>();
}
]]
local Default = {
    _Id = 0, --StageId
    _Day = 0, --当前天数
    _MaxDay = 0, --最大天数（到达后战斗结束）
    _IsLastDay = false, --战斗结束
    _UnlockTeamCount = 0, --已解锁队伍数量
    _TeamCount = 0, --已组建队伍数量
    _ResourceDic = {}, -- 资源
    _InhabitantDic = {}, --居民
    _BuildingList = {}, --建筑地图（BuildingIndex->建筑）
    _TargetDic = {}, --关卡目标
    _Events = {}, --关卡事件
    _Teams = {}, --探索队伍
    _PlacesDic = {}, --探索地点
    _AccDeadInhabitantCount = 0, --累积死亡居民数量
    _CurDeathCount = 0,
    --当天死亡人数
    _CanExplore = false, --是否解锁探索
    -------------UI数据（ViewModel）---------
    _Opening = false, --开启状态（前置关卡是否通关）
    _Passed = false, --通关状态
    _Fighting = false, --是否作战中（天数未过完中途退出）
    _ForceLose = false, --是否强制失败
    _Star = 0, --通关星数
    _LeftDay = 1, --剩余天数
    _EventTypeRemindDic = {}, --事件类型提醒
    _InhabitantCount = 0, --居民总数
    _IdleInhabitantCount = 0, --空闲居民数
    _AverageInhabitantAttrList = {}, --居民平均属性
    _UnhealthyInhabitantInfoList = {}, --各种异常状态下居民数量
    _BuildingHistoryResourceDic = {}, --每日结算建筑资源变化
    _TeamHistoryResourceDic = {}, --每日结算小队资源变化
    _TeamHistoryAddInhabitant = 0, --每日结算小队增加居民数量
    _UnlockPlaceIds = {} --已解锁探索地点Id
}

--末日生存玩法单局战斗（生存解谜）
local XDoomsdayStage = XClass(XDataEntityBase, "XDoomsdayStage")

function XDoomsdayStage:Ctor(stageId)
    self:Init(Default, stageId)
end

function XDoomsdayStage:InitData(stageId)
    self:SetProperty("_Id", stageId)
    for _, id in ipairs(XDoomsdayConfigs.GetResourceIds()) do
        self._ResourceDic[id] = XDoomsdayResource.New(id)
        self._BuildingHistoryResourceDic[id] = XDoomsdayResource.New(id)
        self._TeamHistoryResourceDic[id] = XDoomsdayResource.New(id)
    end

    for _, attrType in ipairs(XDoomsdayConfigs.GetSortedAttrTypes()) do
        tableInsert(self._AverageInhabitantAttrList, XDoomsdayAttribute.New(attrType))
    end

    for index = 1, XDoomsdayConfigs.StageConfig:GetProperty(stageId, "MaxBuildingCount") do
        self._BuildingList[index] = XDoomsdayBuilding.New()
    end
end

function XDoomsdayStage:UpdateData(data)
    self:SetProperty("_Id", data.Id)
    self:SetProperty("_Day", data.DayCount)
    self:SetProperty("_AccDeadInhabitantCount", data.DeathCount)
    self:SetProperty("_MaxDay", XDoomsdayConfigs.StageConfig:GetProperty(self._Id, "DayCount"))
    self:SetProperty("_LeftDay", self._MaxDay - self._Day)
    self:SetProperty("_Fighting", self._Day ~= 0)
    self:SetProperty("_CanExplore", data.CanExplore)
    self:SetProperty("_ForceLose", data.ForceLose)

    --资源
    self:UpdateResourceList(data.ResourceList)

    --居民
    self:UpdateInhabitants(data.PeopleDbList)

    --建筑地图
    self:UpdateBuildings(data.BuildingDbList)

    --更新建筑居民关联
    self:UpdateBuildingWorkingInhabitantCount()

    --关卡目标
    self:UpdateTargets(data.TaskDbList)

    --关卡事件
    self:UpdateEvents(data.EventDbList)

    --探索队伍
    self:SetProperty("_UnlockTeamCount", data.UnlockTeamCount)
    self:UpdateTeams(data.TeamDbList)

    --探索地点
    self._PlacesDic = {}
    local unlockPlaceIds = {}
    for _, info in pairs(data.PlaceDbList) do
        self._PlacesDic[info.Id] = XDoomsdayPlace.New()
        self._PlacesDic[info.Id]:UpdateData(info)
        tableInsert(unlockPlaceIds, info.Id)
    end
    self:SetProperty("_UnlockPlaceIds", unlockPlaceIds)

    --更新队伍所在地点关联
    self:UpdatePlaceTeams()

    --更新队伍状态（与地点事件关联）
    self:UpdateTeamState()
end

--是否可挑战（开放中且到达解锁时间）,挑战开启剩余时间
function XDoomsdayStage:CanFight()
    if not self._Opening then
        return false, 0
    end

    local openTimeId = XDoomsdayConfigs.StageConfig:GetProperty(self._Id, "OpenTime")
    return XFunctionManager.CheckInTimeByTimeId(openTimeId), XFunctionManager.GetStartTimeByTimeId(openTimeId) -
        XTime.GetServerNowTimestamp()
end

--结算是否胜利（最后一天 and 关卡主目标达成）
function XDoomsdayStage:IsWin()
    if not self:GetProperty("_IsLastDay") then
        return false
    end

    local mainTargetId = XDoomsdayConfigs.StageConfig:GetProperty(self._Id, "MainTaskId")
    return self:IsTargetFinished(mainTargetId)
end

--获取结算失败原因
function XDoomsdayStage:GetLoseReason()
    if self:GetProperty("_InhabitantCount") <= 0 then
        return XDoomsdayConfigs.SETTLE_LOSE_REASON.INHABITANT_DIE_OUT
    end

    if self:GetAverageInhabitantAttr(XDoomsdayConfigs.ATTRUBUTE_TYPE.SAN):GetProperty("_Value") <= 0 then
        return XDoomsdayConfigs.SETTLE_LOSE_REASON.INHABITANT_CRAZY
    end

    return XDoomsdayConfigs.SETTLE_LOSE_REASON.INHABITANT_TIME_OUT
end
---------------关卡目标 begin-----------------
function XDoomsdayStage:UpdateTargets(data)
    if not data then
        return
    end
    for _, info in pairs(data) do
        local target = self:GetTarget(info.Id)
        target:UpdateData(info)
    end
end

--检查是否是关卡中额外接取的任务（不属于初始主任务/子任务）
function XDoomsdayStage:CheckIsExtraTarget(targetId)
    if not XTool.IsNumberValid(targetId) then
        return false
    end

    if targetId == XDoomsdayConfigs.StageConfig:GetProperty(self._Id, "MainTaskId") then
        return false
    end

    for _, subTargetId in pairs(XDoomsdayConfigs.StageConfig:GetProperty(self._Id, "SubTaskId")) do
        if subTargetId == targetId then
            return false
        end
    end

    return
end

function XDoomsdayStage:GetTarget(targetId)
    if not XTool.IsNumberValid(targetId) then
        XLog.Error(
            string.format(
                "XDoomsdayStage:GetTarget error：获取关卡目标错误，当前任务不属于该关卡: stageId:%d, targetId:%d, 配置路径：%s",
                self._Id,
                targetId,
                XDoomsdayConfigs.StageConfig:GetPath()
            )
        )
        return
    end

    local target = self._TargetDic[targetId]
    if not target then
        target = XDoomsdayTarget.New(self:CheckIsExtraTarget(targetId))
        self._TargetDic[targetId] = target
    end

    return target
end

function XDoomsdayStage:IsTargetFinished(targetId)
    return self:GetTarget(targetId):GetProperty("_Passed")
end

--获取支线任务列表（额外接取），只显示未完成未过期
function XDoomsdayStage:GetExtraTargetIds()
    local targetIds = {}
    for id, target in pairs(self._TargetDic) do
        if target:IsExtraToShow() then
            tableInsert(targetIds, id)
        end
    end
    tableSort(targetIds)
    return targetIds
end

function XDoomsdayStage:GetTargetGroup()
    return {
        --主要目标/次要目标
        [1] = {
            XDoomsdayConfigs.StageConfig:GetProperty(self._Id, "MainTaskId")
        },
        --额外接取任务
        [2] = self:GetExtraTargetIds()
    }
end
---------------关卡目标 end-----------------
---------------居民 begin-----------------
function XDoomsdayStage:GetInhabitant(inhabitantId)
    return self._InhabitantDic[inhabitantId]
end

--更新各种异常状态下居民数量
function XDoomsdayStage:UpdateUnhealthyInhabitantCount()
    local tmpAttrDic, tmpValue =
        {
            [XDoomsdayConfigs.HOMELESS_ATTR_TYPE] = 0 --强行插入一条无家可归异常状态记录
        },
        0

    local attrTypes = XDoomsdayConfigs.GetSortedAttrTypes()
    for _, inhabitant in pairs(self._InhabitantDic) do
        for _, attrType in ipairs(attrTypes) do
            if inhabitant:GetAttr(attrType):IsBad() then
                tmpValue = tmpAttrDic[attrType] or 0
                tmpAttrDic[attrType] = tmpValue + 1
            end
        end

        if inhabitant:IsHomeless() then
            tmpValue = tmpAttrDic[XDoomsdayConfigs.HOMELESS_ATTR_TYPE] or 0
            tmpAttrDic[XDoomsdayConfigs.HOMELESS_ATTR_TYPE] = tmpValue + 1
        end
    end

    local list = {}

    local attrType = XDoomsdayConfigs.HOMELESS_ATTR_TYPE
    local count = tmpAttrDic[attrType]
    if XTool.IsNumberValid(count) then
        tableInsert(
            list,
            {
                AttrType = attrType,
                Count = count
            }
        )
    end

    for _, attrType in ipairs(attrTypes) do
        local count = tmpAttrDic[attrType]
        if XTool.IsNumberValid(count) then
            tableInsert(
                list,
                {
                    AttrType = attrType,
                    Count = count
                }
            )
        end
    end

    self:SetProperty("_UnhealthyInhabitantInfoList", list)
end

function XDoomsdayStage:CheckInhabitantAttrBad(attrType)
    for _, inhabitant in pairs(self._InhabitantDic) do
        if attrType == XDoomsdayConfigs.HOMELESS_ATTR_TYPE then
            if inhabitant:IsHomeless() then
                return true
            end
        else
            if inhabitant:GetAttr(attrType):IsBad() then
                return true
            end
        end
    end

    return false
end

function XDoomsdayStage:GetAverageInhabitantAttr(attrType)
    for _, attr in pairs(self._AverageInhabitantAttrList) do
        if attr:GetProperty("_Type") == attrType then
            return attr
        end
    end
end

--更新居民平均属性
function XDoomsdayStage:UpdateAverageInhabitantAttrs()
    local attrTypes = XDoomsdayConfigs.GetSortedAttrTypes()

    local tmpAttrDic = {}
    for _, attrType in ipairs(attrTypes) do
        for _, inhabitant in pairs(self._InhabitantDic) do
            local tmpValue = tmpAttrDic[attrType] or 0
            tmpAttrDic[attrType] = tmpValue + inhabitant:GetAttr(attrType):GetProperty("_Value")
        end
    end

    local inhabitantCount = self:GetProperty("_InhabitantCount")
    for _, attrType in ipairs(attrTypes) do
        local value = tmpAttrDic[attrType] or 0
        local tmpValue = inhabitantCount ~= 0 and math.floor(value / inhabitantCount) or 0
        self:GetAverageInhabitantAttr(attrType):SetProperty("_Value", tmpValue)
    end
end

function XDoomsdayStage:UpdateIdleInhabitantCount()
    local idleCount = 0
    for _, inhabitant in pairs(self._InhabitantDic) do
        if inhabitant:IsIdle() then
            idleCount = idleCount + 1
        end
    end
    self:SetProperty("_IdleInhabitantCount", idleCount)
end

--根据所需数量获取剩余空闲居民最大值
function XDoomsdayStage:TryGetIdleInhabitantCount(count)
    local idleCount = self:GetProperty("_IdleInhabitantCount")
    return XMath.Clamp(count, 0, idleCount)
end

--根据指定数量获取空闲中居民Id列表
--param:tmpIdDic 临时撤下的居民Id字典
function XDoomsdayStage:GetSortedIdleInhabitantIdsByCount(requireCount, tmpIdDic, random)
    tmpIdDic = tmpIdDic or {}
    local inhabitantIds = {}
    local ids = {}

    for id, inhabitant in pairs(self._InhabitantDic) do
        if tmpIdDic[id] or inhabitant:IsIdle() then
            tableInsert(ids, id)
        end
    end

    if random then
        XTool.RandomBreakTableOrder(ids)
    else
        --优先分配健康值、饱腹度更高的居民
        tableSort(
            ids,
            function(aId, bId)
                local aInhabitant = self:GetInhabitant(aId)
                local bInhabitant = self:GetInhabitant(aId)

                --居民健康值从大到小
                local aValue = aInhabitant:GetAttr(XDoomsdayConfigs.ATTRUBUTE_TYPE.HEALTH):GetProperty("_Value")
                local bValue = bInhabitant:GetAttr(XDoomsdayConfigs.ATTRUBUTE_TYPE.HEALTH):GetProperty("_Value")
                if aValue ~= bValue then
                    return aValue > bValue
                end

                --居民饱腹值从大到小
                local aValue = aInhabitant:GetAttr(XDoomsdayConfigs.ATTRUBUTE_TYPE.HUNGER):GetProperty("_Value")
                local bValue = bInhabitant:GetAttr(XDoomsdayConfigs.ATTRUBUTE_TYPE.HUNGER):GetProperty("_Value")
                if aValue ~= bValue then
                    return aValue > bValue
                end

                return false
            end
        )
    end

    local count = 0
    for _, id in ipairs(ids) do
        if count >= requireCount then
            break
        end
        tableInsert(inhabitantIds, id)
        count = count + 1
    end

    return inhabitantIds
end

--根据居民状态值从小到大排序后的居民Id列表
function XDoomsdayStage:GetResourceRequireSortedInhabitantIds(attrId)
    local result = {}

    for id in pairs(self._InhabitantDic) do
        tableInsert(result, id)
    end

    local attrType = XDoomsdayConfigs.AttributeConfig:GetProperty(attrId, "Type")
    tableSort(
        result,
        function(aId, bId)
            --居民状态值从小到大
            local aValue = self:GetInhabitant(aId):GetAttr(attrType):GetProperty("_Value")
            local bValue = self:GetInhabitant(bId):GetAttr(attrType):GetProperty("_Value")
            if aValue ~= bValue then
                return aValue < bValue
            end

            return false
        end
    )

    return result
end

function XDoomsdayStage:UpdateInhabitants(data)
    if not data then
        return
    end
    self._InhabitantDic = {}
    local inhabitantCount = 0
    for _, info in pairs(data) do
        local inhabitant = XDoomsdayInhabitant.New()
        inhabitant:UpdateData(info)

        --初始化关卡内居民属性配置
        for _, attrId in pairs(XDoomsdayConfigs.StageConfig:GetProperty(self._Id, "AttributeId")) do
            if XTool.IsNumberValid(attrId) then
                local attrType = XDoomsdayConfigs.AttributeConfig:GetProperty(attrId, "Type")
                local threshold = XDoomsdayConfigs.AttributeConfig:GetProperty(attrId, "Threshold")
                inhabitant:GetAttr(attrType):SetProperty("_Threshold", threshold)
            end
        end

        self._InhabitantDic[info.Id] = inhabitant
        inhabitantCount = inhabitantCount + 1
    end
    self:SetProperty("_InhabitantCount", inhabitantCount)
    self:UpdateIdleInhabitantCount()
    self:UpdateAverageInhabitantAttrs()
    self:UpdateUnhealthyInhabitantCount()
end

--分配居民工作
function XDoomsdayStage:AllocateInhabitants(inhabitantIds, buildingIndex)
    local building = self:GetBuilding(buildingIndex)
    local buildingId = building:GetProperty("_Id")
    if not XTool.IsNumberValid(buildingId) then
        XLog.Error("XDoomsdayInhabitant:WorkAtBuilding error: buildingId illegal, buildingId: ", buildingId)
        return
    end

    local checkDic = {}
    for _, inhabitantId in pairs(inhabitantIds or {}) do
        checkDic[inhabitantId] = inhabitantId
        self:GetInhabitant(inhabitantId):SetProperty("_WorkingBuildingId", buildingId)
    end

    for inId, inhabitant in pairs(self._InhabitantDic) do
        if checkDic[inId] then
            inhabitant:SetProperty("_WorkingBuildingId", buildingId)
        elseif inhabitant:GetProperty("_WorkingBuildingId") == buildingId then
            --撤回指定建筑中之前的工作居民
            inhabitant:SetProperty("_WorkingBuildingId", 0)
        end
    end

    self:UpdateBuildingWorkingInhabitantCount()
    self:UpdateIdleInhabitantCount()
end

--撤回工作中居民
function XDoomsdayStage:RecallInhabitants(inhabitantIds)
    for _, inhabitantId in pairs(inhabitantIds or {}) do
        self:GetInhabitant(inhabitantId):SetProperty("_WorkingBuildingId", 0)
    end

    self:UpdateBuildingWorkingInhabitantCount()
    self:UpdateIdleInhabitantCount()
end
---------------居民 end-----------------
---------------资源 begin-----------------
function XDoomsdayStage:UpdateResourceList(data)
    if not data then
        return
    end
    for _, info in pairs(data) do
        local resource = self:GetResource(info.CfgId)
        if resource then
            resource:UpdateData(info)
        end
    end
end

function XDoomsdayStage:GetResource(resourceId)
    return self._ResourceDic[resourceId]
end

--结算报告-建筑收益（资源增加）
function XDoomsdayStage:UpdateBuildingHistoryResource(data)
    for _, resource in pairs(self._BuildingHistoryResourceDic) do
        resource:Reset()
    end
    for _, info in pairs(data.ResourceList) do
        local resource = self._BuildingHistoryResourceDic[info.CfgId]
        if resource then
            resource:UpdateData(info)
        end
    end
end

--结算报告-小队收益（居民数量，资源增加）
function XDoomsdayStage:UpdateTeamHistoryResource(data)
    for _, resource in pairs(self._TeamHistoryResourceDic) do
        resource:Reset()
    end
    for _, info in pairs(data.ResourceList) do
        local resource = self._TeamHistoryResourceDic[info.CfgId]
        if resource then
            resource:UpdateData(info)
        end
    end

    self._TeamHistoryAddInhabitant = #data.PeopleDbList
end

function XDoomsdayStage:GetTotalHistoryAddResourceCount(resourceId)
    return self._BuildingHistoryResourceDic[resourceId]:GetProperty("_Count") +
        self._TeamHistoryResourceDic[resourceId]:GetProperty("_Count")
end

function XDoomsdayStage:CheckResourceCount(resourceId, count)
    return self:GetResource(resourceId):GetProperty("_Count") >= count
end

--获取可分配资源信息
function XDoomsdayStage:GetCanAllotResourceList()
    local resourceList = {}
    for _, resource in pairs(self._ResourceDic) do
        local id = resource:GetProperty("_CfgId")
        if XDoomsdayConfigs.ResourceConfig:GetProperty(id, "CanAllot") then
            tableInsert(resourceList, resource)
        end
    end
    return resourceList
end

--获取已分配资源总量，被分配居民Id->单个分配资源数量字典(给所有人分配)
function XDoomsdayStage:GetResourceAllocationByAllocateToAll(resourceId)
    local allocatedCount, inhabitantResourceDic = 0, {}

    local totalCount = self:GetResource(resourceId):GetProperty("_Count")
    local attrId = XDoomsdayConfigs.GetRelatedAttrIdByResourceId(self._Id, resourceId)
    local perCount = XDoomsdayConfigs.AttributeConfig:GetProperty(attrId, "DailyRequireResourceCount")

    --给所有人分配
    local inhabitantIds = self:GetResourceRequireSortedInhabitantIds(attrId)
    for _, inhabitantId in ipairs(inhabitantIds) do
        totalCount = totalCount - perCount
        if totalCount < 0 then
            break
        end
        inhabitantResourceDic[inhabitantId] = perCount
        allocatedCount = allocatedCount + perCount
    end

    return allocatedCount, inhabitantResourceDic
end

--获取分配资源数量，被分配居民Id列表(给一半人分配)
function XDoomsdayStage:GetResourceAllocationByAllocateToHalf(resourceId)
    local allocatedCount, inhabitantResourceDic = 0, {}

    local totalCount = self:GetResource(resourceId):GetProperty("_Count")
    local attrId = XDoomsdayConfigs.GetRelatedAttrIdByResourceId(self._Id, resourceId)
    local perCount = XDoomsdayConfigs.AttributeConfig:GetProperty(attrId, "DailyRequireResourceCount")

    --给一半人分配
    local inhabitantIds = self:GetResourceRequireSortedInhabitantIds(attrId)
    local halfCount = math.floor(#inhabitantIds * 0.5)
    for i = 1, halfCount do
        local inhabitantId = inhabitantIds[i]
        totalCount = totalCount - perCount
        if totalCount < 0 then
            break
        end
        inhabitantResourceDic[inhabitantId] = perCount
        allocatedCount = allocatedCount + perCount
    end

    return allocatedCount, inhabitantResourceDic
end

--获取分配资源数量，被分配居民Id列表(给尽可能多的人分配)
function XDoomsdayStage:GetResourceAllocationByAllocateToMost(resourceId)
    return self:GetResourceAllocationByAllocateToAll(resourceId)
end

--获取分配资源数量，被分配居民Id列表(不分配)
function XDoomsdayStage:GetResourceAllocationByAllocateToNone(resourceId)
    return 0, {}
end

--资源增量更新
function XDoomsdayStage:AddResource(addResourceDic)
    for resourceId, addCount in pairs(addResourceDic) do
        self:GetResource(resourceId):AddCount(addCount)
    end
end
---------------资源 end-----------------
---------------建筑 begin-----------------
function XDoomsdayStage:UpdateBuildings(data)
    local updatedIdx = {}

    for _, info in pairs(data) do
        local buildingIndex = info.Pos + 1
        local building = self:GetBuilding(buildingIndex)
        building:UpdateData(info)
        self:UpdateBuildingState(buildingIndex)
        updatedIdx[buildingIndex] = buildingIndex
    end

    for buildingIndex, building in pairs(self._BuildingList) do
        if not updatedIdx[buildingIndex] then
            building:Reset()
        end
    end
end

function XDoomsdayStage:GetBuilding(buildingIndex)
    return self._BuildingList[buildingIndex]
end

function XDoomsdayStage:GetBuildingIndexList()
    local indexList = {}
    for index in ipairs(self._BuildingList) do
        tableInsert(indexList, index)
    end
    return indexList
end

--获取同Id的Building配置
function XDoomsdayStage:GetSameTypeBuildingCount(buildingCfgId)
    local count = 0
    for _, building in ipairs(self._BuildingList) do
        if building:GetProperty("_CfgId") == buildingCfgId then
            count = count + 1
        end
    end
    return count
end

--更新建筑中工作居民数量
function XDoomsdayStage:UpdateBuildingWorkingInhabitantCount()
    local buildingIdHoldCountDic = {}

    for _, inhabitant in pairs(self._InhabitantDic) do
        local buildingId = inhabitant:GetProperty("_WorkingBuildingId")
        if XTool.IsNumberValid(buildingId) then
            local count = buildingIdHoldCountDic[buildingId] or 0
            buildingIdHoldCountDic[buildingId] = count + 1
        end
    end

    for buildingIndex, building in pairs(self._BuildingList) do
        local count = buildingIdHoldCountDic[building:GetProperty("_Id")] or 0
        building:SetProperty("_WorkingInhabitantCount", count)
        self:UpdateBuildingState(buildingIndex)
    end
end

--获取建筑中工作的居民Id字典
function XDoomsdayStage:GetBuildingWorkingInhabitantIdDic(buildingIndex)
    local idDic = {}
    local buildingId = self:GetBuilding(buildingIndex):GetProperty("_Id")
    for inhabitantId, inhabitant in pairs(self._InhabitantDic) do
        local inBuildingId = inhabitant:GetProperty("_WorkingBuildingId")
        if XTool.IsNumberValid(inBuildingId) and inBuildingId == buildingId then
            idDic[inhabitantId] = inhabitantId
        end
    end
    return idDic
end

--获取当前建筑中全部居民Id
function XDoomsdayStage:GetBuildingWorkingInhabitantIds(buildingIndex)
    local inhabitantIds = {}
    local cmpBuildingId = self:GetBuilding(buildingIndex):GetProperty("_Id")
    for _, inhabitant in pairs(self._InhabitantDic) do
        if XTool.IsNumberValid(cmpBuildingId) and cmpBuildingId == inhabitant:GetProperty("_WorkingBuildingId") then
            tableInsert(inhabitantIds, inhabitant:GetProperty("_Id"))
        end
    end
    return inhabitantIds
end

--更新建筑状态
function XDoomsdayStage:UpdateBuildingState(buildingIndex)
    local building = self:GetBuilding(buildingIndex)
    local state = XDoomsdayConfigs.BUILDING_STATE.EMPTY
    if self:IsBuildingBuilding(buildingIndex) or self:IsBuildingWorking(buildingIndex) then
        state = XDoomsdayConfigs.BUILDING_STATE.WORKING
    elseif self:IsBuildingPending(buildingIndex) then
        state = XDoomsdayConfigs.BUILDING_STATE.PENDING
    elseif self:IsBuildingWaiting(buildingIndex) then
        state = XDoomsdayConfigs.BUILDING_STATE.WAITING
    end

    building:SetProperty("_State", state)
end

--拆除建筑
function XDoomsdayStage:DeleteBuilding(buildingIndex)
    local building = self:GetBuilding(buildingIndex)

    local buildingId = building:GetProperty("_Id")
    for _, inhabitant in pairs(self._InhabitantDic) do
        if buildingId == inhabitant:GetProperty("_WorkingBuildingId") then
            inhabitant:SetProperty("_WorkingBuildingId", 0)
        end
        if buildingId == inhabitant:GetProperty("_LivingBuildingId") then
            inhabitant:SetProperty("_LivingBuildingId", 0)
        end
    end

    self:UpdateIdleInhabitantCount()
    self:UpdateUnhealthyInhabitantCount() --更新无家可归状态
    building:Reset()
end

--是否建造中
function XDoomsdayStage:IsBuildingBuilding(buildingIndex)
    local building = self:GetBuilding(buildingIndex)

    if building:IsEmpty() then
        return false
    end

    if building:GetProperty("_IsDone") then
        return false
    end

    local limit = XDoomsdayConfigs.BuildingConfig:GetProperty(building:GetProperty("_CfgId"), "LockPeopleOnBuilding")
    if not XTool.IsNumberValid(limit) then
        return false
    end

    return building:GetProperty("_WorkingInhabitantCount") == limit
end

--是否生产中
function XDoomsdayStage:IsBuildingProducing(buildingIndex)
    local building = self:GetBuilding(buildingIndex)

    if building:IsEmpty() then
        return false
    end

    if not building:GetProperty("_IsDone") then
        return false
    end

    local limit = XDoomsdayConfigs.BuildingConfig:GetProperty(building:GetProperty("_CfgId"), "LockPeopleOnWorking")
    if not XTool.IsNumberValid(limit) then
        return false
    end

    return building:GetProperty("_WorkingInhabitantCount") == limit
end

--是否工作中（建造中/生产中）
function XDoomsdayStage:IsBuildingWorking(buildingIndex)
    return self:IsBuildingProducing(buildingIndex) or self:IsBuildingBuilding(buildingIndex)
end

--是否待分配
function XDoomsdayStage:IsBuildingWaiting(buildingIndex)
    local building = self:GetBuilding(buildingIndex)

    if building:IsEmpty() then
        return false
    end

    if not building:GetProperty("_IsDone") then
        return false
    end

    return building:GetProperty("_WorkingInhabitantCount") == 0
end

--是否工作中断
function XDoomsdayStage:IsBuildingWorkPending(buildingIndex)
    local building = self:GetBuilding(buildingIndex)

    if building:IsEmpty() then
        return false
    end

    if not building:GetProperty("_IsDone") then
        return false
    end

    local limit = XDoomsdayConfigs.BuildingConfig:GetProperty(building:GetProperty("_CfgId"), "LockPeopleOnWorking")
    if not XTool.IsNumberValid(limit) then
        return false
    end

    return building:GetProperty("_WorkingInhabitantCount") ~= limit
end

--是否建造中断
function XDoomsdayStage:IsBuildingBuildPending(buildingIndex)
    local building = self:GetBuilding(buildingIndex)

    if building:IsEmpty() then
        return false
    end

    if building:GetProperty("_IsDone") then
        return false
    end

    local limit = XDoomsdayConfigs.BuildingConfig:GetProperty(building:GetProperty("_CfgId"), "LockPeopleOnBuilding")
    if not XTool.IsNumberValid(limit) then
        return false
    end

    return building:GetProperty("_WorkingInhabitantCount") ~= limit
end

--是否工作中断/建造中断
function XDoomsdayStage:IsBuildingPending(buildingIndex)
    return self:IsBuildingWorkPending(buildingIndex) or self:IsBuildingBuildPending(buildingIndex)
end
---------------建筑 end-----------------
---------------关卡事件 begin-----------------
function XDoomsdayStage:UpdateEvents(data)
    local remindDic = {}

    local eventIdxDic = {}
    for index, event in pairs(self._Events) do
        eventIdxDic[event._Id] = index
    end

    local eventType
    for _, info in ipairs(data) do
        local index = eventIdxDic[info.Id]
        local event = index and self._Events[index]
        if not event then
            event = XDoomsdayEvent.New()
            tableInsert(self._Events, event)
        end
        event:UpdateData(info)

        --事件提醒
        if not event:GetProperty("_Finished") then
            eventType = event:GetProperty("_Type")
            if not remindDic[eventType] then
                remindDic[eventType] = event
            end
        end
    end

    tableSort(
        self._Events,
        function(a, b)
            return a._Id < b._Id
        end
    )

    self:SetProperty("_EventTypeRemindDic", remindDic)
end

--获取自动剧情事件列表
function XDoomsdayStage:GetNextPopupEvent(popedEventIdDic)
    for _, event in pairs(self._Events) do
        if not popedEventIdDic[event._Id] and event:IsAutoPopupEvent() and not event:GetProperty("_Finished") then
            popedEventIdDic[event._Id] = event._Id
            return event
        end
    end
end

--关卡事件是否全部完成
function XDoomsdayStage:IsEventsFinished(eventType)
    for _, event in pairs(self._Events) do
        if not eventType or eventType == event:GetProperty("_Type") then
            if not event:GetProperty("_Finished") then
                return false
            end
        end
    end
    return true
end

--获取所有未完成的关联地点关卡事件
function XDoomsdayStage:GetPlaceEventDic()
    local eventDic = {}
    for _, event in pairs(self._Events) do
        if not event:GetProperty("_Finished") then
            local placeId = event:GetProperty("_PlaceId")
            if XTool.IsNumberValid(placeId) then
                eventDic[placeId] = event
            end
        end
    end
    return eventDic
end

--获取指定关联地点未完成关卡事件
function XDoomsdayStage:GetPlaceEvent(placeId)
    for _, event in pairs(self._Events) do
        if not event:GetProperty("_Finished") then
            if placeId == event:GetProperty("_PlaceId") then
                return event
            end
        end
    end
end

--获取指定未完成事件关联地点
function XDoomsdayStage:GetEventPlaceId(eventId)
    for _, event in pairs(self._Events) do
        if event:GetProperty("_Id") == eventId and not event:GetProperty("_Finished") then
            return event:GetProperty("_PlaceId")
        end
    end
end

--获取所有未完成的建筑关卡事件（随机指定建筑Index）
function XDoomsdayStage:GetBuildingEventDic()
    local eventDic = {}

    local events = {}
    for _, event in pairs(self._Events) do
        if not event:GetProperty("_Finished") then
            local placeId = event:GetProperty("_PlaceId")
            if not XTool.IsNumberValid(placeId) then
                tableInsert(events, event)
            end
        end
    end

    --从关卡所有建筑中随机一批index出来
    local maxIndex = XDoomsdayConfigs.StageConfig:GetProperty(self._Id, "MaxBuildingCount")
    local buildingIndexs = XTool.GetRandomNumbers(maxIndex, #events)
    local eventIndex = 0
    for _, buildingIndex in ipairs(buildingIndexs) do
        eventDic[buildingIndex] = events[eventIndex]
        eventIndex = eventIndex + 1
    end

    return eventDic
end
---------------关卡事件 end-----------------
---------------探索地点 begin-----------------
function XDoomsdayStage:GetPlace(placeId)
    return self._PlacesDic[placeId]
end

function XDoomsdayStage:GetPlaceIds()
    local placeIds = {}
    for placeId in pairs(self._PlacesDic) do
        tableInsert(placeIds, placeId)
    end
    return placeIds
end

--地点事件是否全部探索完成
function XDoomsdayStage:IsPlaceFinished(placeId)
    local place = self:GetPlace(placeId)
    if not place then
        return false
    end

    return place:IsFinished()
end

--更新队伍所在地点关联
function XDoomsdayStage:UpdatePlaceTeams()
    local placeTeamDic = {}

    for teamId, team in pairs(self._Teams) do
        local placeId = team:GetProperty("_PlaceId")
        if XTool.IsNumberValid(placeId) then
            placeTeamDic[placeId] = placeTeamDic[placeId] or {}
            tableInsert(placeTeamDic[placeId], teamId)
        end
    end

    for placeId, place in pairs(self._PlacesDic) do
        place:SetProperty("_TeamIds", placeTeamDic[placeId] or {})
    end
end

--获取指定地点正在行进中/已在地点中的队伍Id
function XDoomsdayStage:GetPlaceSelectTeamId(placeId)
    if not XTool.IsNumberValid(placeId) then
        return 0
    end
    for teamId, team in pairs(self._Teams) do
        if placeId == team:GetProperty("_PlaceId") or placeId == team:GetProperty("_TargetPlaceId") then
            return teamId
        end
    end
end

function XDoomsdayStage:CheckPlaceHasSelectTeamId(placeId)
    return XTool.IsNumberValid(self:GetPlaceSelectTeamId(placeId))
end
---------------探索地点 end-----------------
---------------探索队伍 begin-----------------
function XDoomsdayStage:UpdateTeams(data)
    for _, team in pairs(self._Teams) do
        team:Reset()
    end

    for _, info in pairs(data) do
        local team = self:GetTeam(info.Id)
        team:UpdateData(info)
    end
    self:SetProperty("_TeamCount", self:GetTeamCount())
end

function XDoomsdayStage:GetTeamCount()
    local count = 0
    for _, team in pairs(self._Teams) do
        if not team:IsEmpty() then
            count = count + 1
        end
    end
    return count
end

function XDoomsdayStage:GetTeam(teamIndex)
    local team = self._Teams[teamIndex]
    if not team then
        team = XDoomsdayTeam.New()
        self._Teams[teamIndex] = team
    end
    return team
end

--队伍是否已经存在
function XDoomsdayStage:CheckTeamExist(teamIndex)
    return not self:GetTeam(teamIndex):IsEmpty()
end

function XDoomsdayStage:AddTeam(teamIndex, data)
    self:GetTeam(teamIndex):UpdateData(data)
    self:SetProperty("_TeamCount", self:GetTeamCount())
    self:UpdatePlaceTeams()
end

--是否可创建指定index的队伍
function XDoomsdayStage:CanCreateTeam(teamIndex)
    return teamIndex <= self._UnlockTeamCount
end

--获取队伍关联事件
function XDoomsdayStage:GetTeamEvent(teamIndex)
    if not XTool.IsNumberValid(teamIndex) then
        return
    end

    local team = self:GetTeam(teamIndex)
    if team:IsEmpty() then
        return
    end

    local placeId = team:GetProperty("_PlaceId")
    return self:GetPlaceEvent(placeId)
end

--更新队伍状态
function XDoomsdayStage:UpdateTeamState()
    for teamId, team in pairs(self._Teams) do
        if team:IsMoving() then
            team:SetProperty("_State", XDoomsdayConfigs.TEAM_STATE.MOVING)
        elseif self:IsTeamBusy(teamId) then
            team:SetProperty("_State", XDoomsdayConfigs.TEAM_STATE.BUSY)
        else
            team:SetProperty("_State", XDoomsdayConfigs.TEAM_STATE.WAITING)
        end
    end
end

--队伍是否事件中
function XDoomsdayStage:IsTeamBusy(teamIndex)
    local team = self:GetTeam(teamIndex)

    if team:IsEmpty() then
        return false
    end

    if not team:ReachPlace() then
        return false
    end

    local placeId = team:GetProperty("_PlaceId")
    if self:IsPlaceFinished(placeId) then
        return false
    end

    local event = self:GetPlaceEvent(placeId)
    if not event then
        return false
    end

    return true
end

--指定队伍是否在大本营中
function XDoomsdayStage:IsTeamInCamp(teamIndex)
    local team = self:GetTeam(teamIndex)
    if team:IsEmpty() then
        return false
    end

    local placeId = team:GetProperty("_PlaceId")
    return not XTool.IsNumberValid(placeId) or
        placeId == XDoomsdayConfigs.StageConfig:GetProperty(self._Id, "FirstPlace")
end
---------------探索队伍 end-----------------
return XDoomsdayStage
