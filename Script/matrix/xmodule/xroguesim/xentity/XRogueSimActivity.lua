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

-- 更新当前货物生产计划
function XRogueSimActivity:UpdateProducePlan(plan)
    if not self.StageData then
        return
    end
    self.StageData.ProducePlan = plan
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_PRODUCE)
end

-- 更新当前货物生产计划评分
function XRogueSimActivity:UpdateProducePlanScore(score)
    if not self.StageData then
        return
    end
    self.StageData.ProducePlanScore = score
end

-- 更新当前货物出售计划
function XRogueSimActivity:UpdateSellPlan(plan)
    if not self.StageData then
        return
    end
    self.StageData.SellPlan = plan or {}
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_COMMODITY_SETUP_SELL)
end

-- 更新当前货物出售计划预设
function XRogueSimActivity:UpdateSellPlanPreset(planPreset)
    if not self.StageData then
        return
    end
    self.StageData.SellPlanPreset = planPreset or {}
end

-- 更新回合数
function XRogueSimActivity:UpdateTurnNumber(num)
    if not self.StageData then
        return
    end
    self.StageData.TurnNumber = num
    XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_TURN_NUMBER_CHANGE)
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
---@param eventId number 事件Id
---@param rewardId number 拍卖行奖励ID
function XRogueSimActivity:UpdateGridEventId(id, eventId, rewardId, deadlineTurnNumber)
    if not self.StageData then
        return
    end
    local eventData = self.StageData:GetEventDataById(id)
    if eventData then
        if XTool.IsNumberValid(eventId) then
            eventData:UpdateEventConfigId(eventId)
        end
        if XTool.IsNumberValid(rewardId) then
            eventData:UpdateEventRewardId(rewardId)
        end
        if XTool.IsNumberValid(deadlineTurnNumber) then
            eventData:UpdateEventCurDeadlineTurnNumber(deadlineTurnNumber)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_ROGUE_SIM_EVENT_UPDATE)
    end
end

-- 设置区域已解锁
---@param areaId number 区域Id
function XRogueSimActivity:SetAreaIsUnlock(areaId)
    if not self.StageData then
        return
    end
    local mapData = self.StageData:GetMapData()
    mapData:SetAreaIsUnlock(areaId)
end

-- 设置区域已获得
---@param areaId number 区域Id
function XRogueSimActivity:SetAreaIsObtain(areaId)
    if not self.StageData then
        return
    end
    local mapData = self.StageData:GetMapData()
    mapData:SetAreaIsObtain(areaId)
end

-- 添加销售记录
function XRogueSimActivity:AddSellResult(data)
    if not self.StageData then
        return
    end
    self.StageData:AddSellResult(data)
end

-- 添加生产记录
function XRogueSimActivity:AddProduceResult(data)
    if not self.StageData then
        return
    end
    self.StageData:AddProduceResult(data)
end

-- 更新货物价格波动
function XRogueSimActivity:UpdateCommodityPriceRates(data)
    if not self.StageData then
        return
    end
    self.StageData.CommodityPriceRates = data or {}
end

-- 更新货物价格波动配置id列表
function XRogueSimActivity:UpdateCommodityPriceRateIds(data)
    if not self.StageData then
        return
    end
    self.StageData.CommodityPriceRateIds = data or {}
end

return XRogueSimActivity
