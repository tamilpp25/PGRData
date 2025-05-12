---@class XRogueSimStageSettleData
local XRogueSimStageSettleData = XClass(nil, "XRogueSimStageSettleData")

function XRogueSimStageSettleData:Ctor()
    self.StageId = 0
    self.TurnNumber = 0
    -- 销售记录
    ---@type XRogueSimCommoditySellResult[]
    self.SellResults = {}
    -- 生产记录
    ---@type XRogueSimCommodityProduceResult[]
    self.ProduceResults = {}
    -- 记录当前关卡三星完成状态
    ---@type table<number, boolean> key:条件Id value:是否完成
    self.StarConditionFinished = {}
    --关卡结算数据
    self.IsStageFinished = false
    self.Point = 0
    self.AwardCoinCount = 0
    self.AwardNutCount = 0
    self.MainLevel = 0
    self.CityLevel = 0
    self.BuildingCount = 0
    self.AccumulateGoldCount = 0
    self.UnlockAreaCount = 0
    self.FinishedEventCount = 0
    self.RewardGoodsList = {}
    -- 判断是否有关卡结算数据用
    self.IsStageSettle = false
end

-- 设置关卡Id
function XRogueSimStageSettleData:SetStageId(stageId)
    self.StageId = stageId
end

-- 获取关卡Id
function XRogueSimStageSettleData:GetStageId()
    return self.StageId
end

-- 设置回合数
function XRogueSimStageSettleData:SetTurnNumber(turnNumber)
    self.TurnNumber = turnNumber
end

-- 获取回合数
function XRogueSimStageSettleData:GetTurnNumber()
    return self.TurnNumber
end

-- 更新销售记录
function XRogueSimStageSettleData:UpdateSellResults(data)
    self.SellResults = XTool.Clone(data)
end

-- 添加销售记录
function XRogueSimStageSettleData:AddSellResult(data)
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

-- 获取销售记录通过回合数
function XRogueSimStageSettleData:GetSellResultByTurnNumber(turnNumber)
    return self.SellResults[turnNumber] or nil
end

-- 更新生产记录
function XRogueSimStageSettleData:UpdateProduceResults(data)
    self.ProduceResults = XTool.Clone(data)
end

-- 添加生产记录
function XRogueSimStageSettleData:AddProduceResult(data)
    if not data then
        return
    end
    local produceResult = self.ProduceResults[data.TurnNumber]
    if not produceResult then
        produceResult = require("XModule/XRogueSim/XEntity/XRogueSimCommodityProduceResult").New()
        self.ProduceResults[data.TurnNumber] = produceResult
    end
    produceResult:UpdateProduceResultData(data)
end

-- 获取生产记录通过回合数
function XRogueSimStageSettleData:GetProduceResultByTurnNumber(turnNumber)
    return self.ProduceResults[turnNumber] or nil
end

-- 更新三星完成状态
function XRogueSimStageSettleData:UpdateStarConditionFinished(starFinish)
    self.StarConditionFinished = starFinish
end

-- 获取三星完成状态
function XRogueSimStageSettleData:GetStarConditionFinished(conditionId)
    return self.StarConditionFinished[conditionId] or false
end

-- 更新关卡结算数据
function XRogueSimStageSettleData:UpdateStageSettleData(data)
    self.IsStageFinished = data.IsStageFinished or false
    self.Point = data.Point or 0
    self.AwardCoinCount = data.AwardCoinCount or 0
    self.AwardNutCount = data.AwardNutCount or 0
    self.MainLevel = data.MainLevel or 0
    self.CityLevel = data.CityLevel or 0
    self.BuildingCount = data.BuildingCount or 0
    self.AccumulateGoldCount = data.AccumulateGoldCount or 0
    self.UnlockAreaCount = data.UnlockAreaCount or 0
    self.FinishedEventCount = data.FinishedEventCount or 0
    self.RewardGoodsList = data.RewardGoodsList or {}
    self.IsStageSettle = true
end

-- 是否是关卡结算
function XRogueSimStageSettleData:GetIsStageSettle()
    return self.IsStageSettle
end

function XRogueSimStageSettleData:GetIsStageFinished()
    return self.IsStageFinished
end

function XRogueSimStageSettleData:GetPoint()
    return self.Point
end

function XRogueSimStageSettleData:GetAwardCoinCount()
    return self.AwardCoinCount
end

function XRogueSimStageSettleData:GetAwardNutCount()
    return self.AwardNutCount
end

function XRogueSimStageSettleData:GetMainLevel()
    return self.MainLevel
end

function XRogueSimStageSettleData:GetCityLevel()
    return self.CityLevel
end

function XRogueSimStageSettleData:GetBuildingCount()
    return self.BuildingCount
end

function XRogueSimStageSettleData:GetAccumulateGoldCount()
    return self.AccumulateGoldCount
end

function XRogueSimStageSettleData:GetUnlockAreaCount()
    return self.UnlockAreaCount
end

function XRogueSimStageSettleData:GetFinishedEventCount()
    return self.FinishedEventCount
end

function XRogueSimStageSettleData:GetRewardGoodsList()
    return self.RewardGoodsList or {}
end

return XRogueSimStageSettleData
