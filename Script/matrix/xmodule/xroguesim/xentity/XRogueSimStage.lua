---@class XRogueSimStage
local XRogueSimStage = XClass(nil, "XRogueSimStage")

function XRogueSimStage:Ctor()
    -- 关卡Id
    self.StageId = 0
    -- 当前回合数
    self.TurnNumber = 0
    -- 当前行动点
    self.ActionPoint = 0
    -- 等级
    self.MainLevel = 0
    -- 信物Id
    self.TokenId = 0
    -- 地图数据
    ---@type XRogueSimMap
    self.MapData = nil
    -- 已探索格子列表
    ---@type number[]
    self.ExploredGridIds = {}
    -- 额外开放视野的格子列表
    ---@type number[]
    self.VisibleGridIds = {}
    -- 奖池列表
    ---@type XRogueSimReward[]
    self.RewardData = {}
    -- Buff数据
    ---@type XRogueSimBuff[]
    self.BuffData = {}
    -- 资源数据
    ---@type XRogueSimResource[]
    self.ResourceData = {}
    -- 货物数据
    ---@type XRogueSimCommodity[]
    self.CommodityData = {}
    -- 货物价格波动
    ---@type table<number, number>
    self.CommodityPriceRates = {}
    -- 已解锁科技集
    ---@type XRogueSimTech
    self.TechData = nil
    -- 当前波动数据
    ---@type XRogueSimVolatility
    self.VolatilityData = nil
    -- 当前货物生成货物ID
    self.ProductCommodityId = 0
    -- 当前货物出售计划
    ---@type table<number, number>
    self.SellPlan = {}
    -- 道具箱数据
    ---@type XRogueSimPropBox
    self.PropBoxData = nil
    -- 事件数据
    ---@type XRogueSimEvent[]
    self.EventData = {}
    -- 建筑数据
    ---@type XRogueSimBuilding[]
    self.BuildingData = {}
    -- 城邦数据
    ---@type XRogueSimCity[]
    self.CityData = {}
    -- 任务数据
    ---@type XRogueSimTask[]
    self.TaskData = {}
    -- 统计数据
    ---@type XRogueSimStatistics
    self.StatisticsData = nil
    -- 销售记录
    ---@type XRogueSimCommoditySellResult[]
    self.SellResults = {}

    --region 加成数据

    -- 商品属性加成
    ---@type XRogueSimCommodityAdds[]
    self.CommodityAdds = {}
    -- 杂项加成
    ---@type table<number, number> key是MiscAdd value是加成值
    self.MiscAdds = {}

    --endregion
end

function XRogueSimStage:UpdateStageData(data)
    self.StageId = data.StageId or 0
    self.TurnNumber = data.TurnNumber or 0
    self.ActionPoint = data.ActionPoint or 0
    self.MainLevel = data.MainLevel or 0
    self.TokenId = data.TokenId or 0
    self:UpdateMapData(data.MapData)
    self.ExploredGridIds = data.ExploredGridIds or {}
    self.VisibleGridIds = data.VisibleGridIds or {}
    self:UpdateRewardData(data.RewardDatas)
    self:UpdateBuffData(data.BuffDatas)
    self.ResourceData = {}
    self:UpdateResourceData(data.ResourceDatas)
    self.CommodityData = {}
    self:UpdateCommodityData(data.CommodityDatas)
    self.CommodityPriceRates = data.CommodityPriceRates or {}
    self:UpdateTechData(data.TechData)
    self:UpdateVolatilityData(data.VolatilityData)
    self.ProductCommodityId = data.ProductCommodityId or 0
    self.SellPlan = data.SellPlan or {}
    self:UpdatePropBoxData(data.PropBoxData)
    self:UpdateEventData(data.EventDatas)
    self:UpdateBuildingData(data.BuildingDatas)
    self:UpdateCityData(data.CityDatas)
    self.TaskData = {}
    self:UpdateTaskData(data.TaskDatas)
    self:UpdateStatisticsData(data.StatisticsData)
    self:UpdateSellResults(data.SellResults)
end

function XRogueSimStage:UpdateMapData(data)
    if not data then
        return
    end
    if not self.MapData then
        self.MapData = require("XModule/XRogueSim/XEntity/XRogueSimMap").New()
    end
    self.MapData:UpdateMapData(data)
end

function XRogueSimStage:UpdateRewardData(data)
    self.RewardData = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddReward(v)
    end
end

function XRogueSimStage:AddReward(data)
    if not data then
        return
    end
    local reward = self.RewardData[data.Id]
    if not reward then
        reward = require("XModule/XRogueSim/XEntity/XRogueSimReward").New()
        self.RewardData[data.Id] = reward
    end
    reward:UpdateRewardData(data)
end

function XRogueSimStage:UpdateBuffData(data)
    self.BuffData = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddBuffData(v)
    end
end

function XRogueSimStage:AddBuffData(data)
    if not data then
        return
    end
    local buff = self.BuffData[data.Id]
    if not buff then
        buff = require("XModule/XRogueSim/XEntity/XRogueSimBuff").New()
        self.BuffData[data.Id] = buff
    end
    buff:UpdateBuffData(data)
end

function XRogueSimStage:RemoveBuffData(id)
    if not XTool.IsNumberValid(id) then
        return
    end
    self.BuffData[id] = nil
end

function XRogueSimStage:UpdateResourceData(data)
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddResourceData(v)
    end
end

function XRogueSimStage:AddResourceData(data)
    if not data then
        return
    end
    local resource = self.ResourceData[data.Id]
    if not resource then
        resource = require("XModule/XRogueSim/XEntity/XRogueSimResource").New()
        self.ResourceData[data.Id] = resource
    end
    resource:UpdateResourceData(data)
end

function XRogueSimStage:UpdateCommodityData(data)
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddCommodityData(v)
    end
end

function XRogueSimStage:AddCommodityData(data)
    if not data then
        return
    end
    local commodity = self.CommodityData[data.Id]
    if not commodity then
        commodity = require("XModule/XRogueSim/XEntity/XRogueSimCommodity").New()
        self.CommodityData[data.Id] = commodity
    end
    commodity:UpdateCommodityData(data)
end

function XRogueSimStage:UpdateTechData(data)
    if not data then
        return
    end
    if not self.TechData then
        self.TechData = require("XModule/XRogueSim/XEntity/XRogueSimTech").New()
    end
    self.TechData:UpdateTechData(data)
end

function XRogueSimStage:UpdateVolatilityData(data)
    if not data then
        return
    end
    if not self.VolatilityData then
        self.VolatilityData = require("XModule/XRogueSim/XEntity/XRogueSimVolatility").New()
    end
    self.VolatilityData:UpdateVolatilityData(data)
end

function XRogueSimStage:UpdatePropBoxData(data)
    if not data then
        return
    end
    if not self.PropBoxData then
        self.PropBoxData = require("XModule/XRogueSim/XEntity/XRogueSimPropBox").New()
    end
    self.PropBoxData:UpdatePropBoxData(data)
end

function XRogueSimStage:UpdateEventData(data)
    self.EventData = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddEventData(v)
    end
end

function XRogueSimStage:AddEventData(data)
    if not data then
        return
    end
    local event = self.EventData[data.Id]
    if not event then
        event = require("XModule/XRogueSim/XEntity/XRogueSimEvent").New()
        self.EventData[data.Id] = event
    end
    event:UpdateEventData(data)
end

function XRogueSimStage:RemoveEventData(ids)
    if not ids then
        return
    end
    for _, id in ipairs(ids) do
        self.EventData[id] = nil
    end
end

function XRogueSimStage:UpdateBuildingData(data)
    self.BuildingData = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddBuildingData(v)
    end
end

function XRogueSimStage:AddBuildingData(data)
    if not data then
        return
    end
    local building = self.BuildingData[data.Id]
    if not building then
        building = require("XModule/XRogueSim/XEntity/XRogueSimBuilding").New()
        self.BuildingData[data.Id] = building
    end
    building:UpdateBuildingData(data)
end

function XRogueSimStage:UpdateCityData(data)
    self.CityData = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddCityData(v)
    end
end

function XRogueSimStage:AddCityData(data)
    if not data then
        return
    end
    local city = self.CityData[data.Id]
    if not city then
        city = require("XModule/XRogueSim/XEntity/XRogueSimCity").New()
        self.CityData[data.Id] = city
    end
    city:UpdateCityData(data)
end

function XRogueSimStage:UpdateTaskData(data)
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddTaskData(v)
    end
end

function XRogueSimStage:AddTaskData(data)
    if not data then
        return
    end
    local task = self.TaskData[data.Id]
    if not task then
        task = require("XModule/XRogueSim/XEntity/XRogueSimTask").New()
        self.TaskData[data.Id] = task
    end
    task:UpdateTaskData(data)
end

function XRogueSimStage:UpdateStatisticsData(data)
    if not data then
        return
    end
    if not self.StatisticsData then
        self.StatisticsData = require("XModule/XRogueSim/XEntity/XRogueSimStatistics").New()
    end
    self.StatisticsData:UpdateStatisticsData(data)
end

function XRogueSimStage:UpdateSellResults(data)
    self.SellResults = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddSellResult(v)
    end
end

function XRogueSimStage:AddSellResult(data)
    if not data then
        return
    end
    local sellResult = self.SellResults[data.TurnNumber]
    if not sellResult then
        sellResult = require("XModule/XRogueSim/XEntity/XRogueSimCommoditySellResult").New()
        self.SellResults[data.TurnNumber] = sellResult
    end
    sellResult:UpdateSellResultData(data)
end

function XRogueSimStage:AddExploredGridIds(gridIds)
    for _, gridId in ipairs(gridIds) do
        table.insert(self.ExploredGridIds, gridId)
    end
end

function XRogueSimStage:AddVisibleGridIds(gridIds)
    for _, gridId in ipairs(gridIds) do
        table.insert(self.VisibleGridIds, gridId)
    end
end

-- 获取关卡Id
function XRogueSimStage:GetStageId()
    return self.StageId
end

-- 获取回合数
function XRogueSimStage:GetTurnNumber()
    return self.TurnNumber
end

-- 获取行动点数
function XRogueSimStage:GetActionPoint()
    return self.ActionPoint
end

-- 获取资源数量
function XRogueSimStage:GetResourceCount(id)
    local resource = self.ResourceData[id]
    if not resource then
        return 0
    end
    return resource:GetCount()
end

-- 获取货物数量
function XRogueSimStage:GetCommodityCount(id)
    local commodity = self.CommodityData[id]
    if not commodity then
        return 0
    end
    return commodity:GetCount()
end

-- 获取货物价格波动
---@param id number 货物Id
function XRogueSimStage:GetCommodityPriceRate(id)
    return self.CommodityPriceRates[id] or 0
end

-- 获取生成货物Id
function XRogueSimStage:GetProductCommodityId()
    return self.ProductCommodityId
end

-- 货物出售数量
function XRogueSimStage:GetSellPlanCount(id)
    return self.SellPlan[id] or 0
end

-- 获取主城等级
function XRogueSimStage:GetMainLevel()
    return self.MainLevel
end

-- 获取信物Id
function XRogueSimStage:GetTokenId()
    return self.TokenId
end

-- 获取所有Buff数据
function XRogueSimStage:GetBuffData()
    return self.BuffData
end

-- 获取单个buff数据通过自增Id
function XRogueSimStage:GetBuffDataById(id)
    return self.BuffData[id] or nil
end

-- 获取所有奖励数据
function XRogueSimStage:GetRewardData()
    return self.RewardData
end

-- 获取单个奖励数据通过自增Id
function XRogueSimStage:GetRewardDataById(id)
    return self.RewardData[id] or nil
end

-- 获取单个奖励数据通过格子id
function XRogueSimStage:GetRewardDataByGridId(gridId)
    for _, reward in pairs(self.RewardData) do
        if reward:GetGridId() == gridId then
            return reward
        end
    end
    return nil
end

-- 获取单个奖励数据通过来源和格子id
function XRogueSimStage:GetRewardDataBySourceAndGridId(source, gridId)
    for _, reward in pairs(self.RewardData) do
        if reward:GetSource() == source and reward:GetGridId() == gridId then
            return reward
        end
    end
    return nil
end

-- 获取所有事件数据
function XRogueSimStage:GetEventData()
    return self.EventData
end

-- 获取单个事件数据通过自增Id
function XRogueSimStage:GetEventDataById(id)
    return self.EventData[id] or nil
end

-- 获取单个事件数据通过格子Id
function XRogueSimStage:GetEventDataByGridId(gridId)
    for _, event in pairs(self.EventData) do
        if event:GetGridId() == gridId then
            return event
        end
    end
    return nil
end

-- 获取所有建筑数据
function XRogueSimStage:GetBuildingData()
    return self.BuildingData
end

-- 获取单个建筑数据通过自增Id
function XRogueSimStage:GetBuildingDataById(id)
    return self.BuildingData[id] or nil
end

-- 获取单个建筑数据通过格子Id
function XRogueSimStage:GetBuildingDataByGridId(gridId)
    for _, build in pairs(self.BuildingData) do
        if build:GetGridId() == gridId then
            return build
        end
    end
    return nil
end

-- 获取所有城邦数据
function XRogueSimStage:GetCityData()
    return self.CityData
end

-- 获取单个城邦数据通过自增Id
function XRogueSimStage:GetCityDataById(id)
    return self.CityData[id] or nil
end

-- 获取单个城邦数据通过格子Id
function XRogueSimStage:GetCityDataByGridId(gridId)
    for _, city in pairs(self.CityData) do
        if city:GetGridId() == gridId then
            return city
        end
    end
    return nil
end

-- 获取所有道具数据
function XRogueSimStage:GetPropData()
    if not self.PropBoxData then
        return {}
    end
    return self.PropBoxData:GetPropData()
end

-- 获取单个道具数据通过自增Id
function XRogueSimStage:GetPropDataById(id)
    if not self.PropBoxData then
        return nil
    end
    return self.PropBoxData:GetPropDataById(id)
end

-- 获取地图数据
function XRogueSimStage:GetMapData()
    return self.MapData
end

-- 获取已探索格子列表
function XRogueSimStage:GetExploredGridIds()
    return self.ExploredGridIds
end

-- 获取额外开放视野的格子列表
function XRogueSimStage:GetVisibleGridIds()
    return self.VisibleGridIds
end

-- 获取所有任务数据资源
function XRogueSimStage:GetTaskData()
    return self.TaskData
end

-- 获取单个任务数据通过自增Id
function XRogueSimStage:GetTaskDataById(id)
    return self.TaskData[id] or nil
end

-- 获取所有销售记录
function XRogueSimStage:GetSellResults()
    return self.SellResults
end

-- 获取单个销售记录通过回合数
function XRogueSimStage:GetSellResultByTurnNumber(turnNumber)
    return self.SellResults[turnNumber] or nil
end

-- 获取当前波动数据
function XRogueSimStage:GetVolatilityData()
    return self.VolatilityData
end

-- 获取销售统计数量通过货物Id
function XRogueSimStage:GetSellStatisticsCountById(id)
    if not self.StatisticsData then
        return 0
    end
    return self.StatisticsData:GetSellStatisticsCountById(id)
end

-- 获取生产统计数量通过货物Id
function XRogueSimStage:GetProductionStatisticsCountById(id)
    if not self.StatisticsData then
        return 0
    end
    return self.StatisticsData:GetProductionStatisticsCountById(id)
end

-- 获取事件统计数量通过事件Id
function XRogueSimStage:GetEventStatisticsCountById(id)
    if not self.StatisticsData then
        return 0
    end
    return self.StatisticsData:GetEventStatisticsCountById(id)
end

-- 获取金币统计数量
function XRogueSimStage:GetGoldStatisticsCount()
    if not self.StatisticsData then
        return 0
    end
    return self.StatisticsData:GetGoldStatisticsCount()
end

--region 加成数据相关

function XRogueSimStage:UpdateCommodityAdds(data)
    self.CommodityAdds = {}
    if not data then
        return
    end
    for _, v in pairs(data) do
        self:AddCommodityAdds(v)
    end
end

function XRogueSimStage:AddCommodityAdds(data)
    if not data then
        return
    end
    local commodityAdds = self.CommodityAdds[data.CommodityId]
    if not commodityAdds then
        commodityAdds = require("XModule/XRogueSim/XEntity/XRogueSimCommodityAdds").New()
        self.CommodityAdds[data.CommodityId] = commodityAdds
    end
    commodityAdds:UpdateCommodityAddsData(data)
end

function XRogueSimStage:UpdateMiscAdds(data)
    self.MiscAdds = data or {}
end

function XRogueSimStage:GetCommodityAdds(commodityId)
    return self.CommodityAdds[commodityId] or nil
end

-- 获取杂项加成通过加成类型
function XRogueSimStage:GetMiscAdd(miscAddType)
    return self.MiscAdds[miscAddType] or 0
end

--endregion

return XRogueSimStage
