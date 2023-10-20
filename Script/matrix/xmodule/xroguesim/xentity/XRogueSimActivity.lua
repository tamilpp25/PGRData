---@class XRogueSimActivity
local XRogueSimActivity = XClass(nil, "XRogueSimActivity")

function XRogueSimActivity:Ctor()
    -- 活动Id
    self.ActivityId = 0
    -- 当局关卡数据
    ---@type XRogueSimStage
    self.StageData = nil
    -- 已完成关卡列表
    ---@type number[]
    self.FinishedStageIds = {}
    -- 关卡记录
    ---@type XRogueSimStageRecord[]
    self.StageRecords = {}
    -- 已获得图鉴列表
    ---@type number[]
    self.Illustrates = {}
end

function XRogueSimActivity:NotifyRogueSimData(data)
    self.ActivityId = data.ActivityId or 0
    self:UpdateStageData(data.StageData)
    self:UpdateStageRecordData(data.StageRecords)
    self.FinishedStageIds = data.FinishedStageIds or {}
    self.Illustrates = data.Illustrates or {}
end

-- 获取活动Id
function XRogueSimActivity:GetActivityId()
    return self.ActivityId
end

-- 获取关卡数据
function XRogueSimActivity:GetStageData()
    return self.StageData
end

-- 获取关卡记录数据
function XRogueSimActivity:GetStageRecord(stageId)
    return self.StageRecords[stageId]
end

-- 获取图鉴数据
function XRogueSimActivity:GetIllustrates()
    return self.Illustrates
end

-- 检查是否存在已通关关卡id
function XRogueSimActivity:CheckFinishedStageId(id)
    if not XTool.IsNumberValid(id) then
        return false
    end
    for _, stageId in ipairs(self.FinishedStageIds) do
        if stageId == id then
            return true
        end
    end
    return false
end

-- 获取科技数据
function XRogueSimActivity:GetTechData()
    return self.StageData.TechData
end

-- 更新关卡数据
function XRogueSimActivity:UpdateStageData(data)
    if not data then
        self.StageData = nil
        return
    end
    if not self.StageData then
        self.StageData = require("XModule/XRogueSim/XEntity/XRogueSimStage").New()
    end
    self.StageData:UpdateStageData(data)
end

-- 更新关卡记录数据
function XRogueSimActivity:UpdateStageRecordData(stageRecords)
    self.StageRecords = {}
    for _, data in ipairs(stageRecords or {}) do
        self:AddStageRecord(data)
    end
end

function XRogueSimActivity:AddStageRecord(data)
    if not data then
        return
    end
    local record = self.StageRecords[data.StageId]
    if not record then
        record = require("XModule/XRogueSim/XEntity/XRogueSimStageRecord").New()
        self.StageRecords[data.StageId] = record
    end
    record:UpdateRecordData(data)
end

-- 更新图鉴数据
function XRogueSimActivity:UpdateIllustrates(illustrates)
    self.Illustrates = illustrates or {}
end

-- 更新生成货物ID
function XRogueSimActivity:UpdateProductCommodityId(id)
    if not self.StageData then
        return
    end
    self.StageData.ProductCommodityId = id
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_PRODUCE)
end

-- 更新当前货物出售计划
function XRogueSimActivity:UpdateSellPlan(plan)
    if not self.StageData then
        return
    end
    self.StageData.SellPlan = plan or {}
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_SELL)
end

-- 更新回合数
function XRogueSimActivity:UpdateTurnNumber(num)
    if not self.StageData then
        return
    end
    self.StageData.TurnNumber = num
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_TURN_NUMBER_CHANGE)
end

-- 更新行动点数
function XRogueSimActivity:UpdateActionPoint(point)
    if not self.StageData then
        return
    end
    self.StageData.ActionPoint = point
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_ACTION_POINT_CHANGE)
end

-- 更新主城等级
function XRogueSimActivity:UpdateMainLevel(level)
    if not self.StageData then
        return
    end
    self.StageData.MainLevel = level
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_MAIN_LEVEL_UP)
end

-- 更新科技数据
function XRogueSimActivity:UpdateTechData(data)
    if not self.StageData then
        return
    end
    self.StageData:UpdateTechData(data)
end

-- 更新事件Id
---@param id number 自增Id
function XRogueSimActivity:UpdateGridEventId(id, eventId)
    if not self.StageData then
        return
    end
    local eventData = self.StageData:GetEventDataById(id)
    if eventData and XTool.IsNumberValid(eventId) then
        eventData:UpdateEventConfigId(eventId)
    end
end

-- 更新建筑为已购买
---@param id number 自增Id
function XRogueSimActivity:UpdateBuildingIsBuy(id)
    if not self.StageData then
        return
    end
    local buildingData = self.StageData:GetBuildingDataById(id)
    if buildingData then
        buildingData:UpdateIsBuy()
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_BUILDING_BUY, buildingData:GetGridId())
    end
end

-- 添加销售记录
function XRogueSimActivity:AddSellResult(data)
    if not self.StageData then
        return
    end
    self.StageData:AddSellResult(data)
end

-- 更新货物价格波动
function XRogueSimActivity:UpdateCommodityPriceRates(data)
    if not self.StageData then
        return
    end
    self.StageData.CommodityPriceRates = data or {}
end

return XRogueSimActivity
