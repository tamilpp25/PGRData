---@class XTwoSideTowerPoint
local XTwoSideTowerPoint = XClass(nil, "XTwoSideTowerPoint")
local XTwoSideTowerStage = require("XEntity/XTwoSideTower/XTwoSideTowerStage")

local REDUCE_SCORE_CNT = 2 -- 屏蔽2个特性以上开始扣分

function XTwoSideTowerPoint:Ctor(id)
    self.Cfg = XTwoSideTowerConfigs.GetPointCfg(id)
    self.PointScore = 0
    self.MaxPointScore = 0
    self.ShieldFeatures = {}
    self.FinishFeatures = {}
    self.StageDataList = {}
    for _, stageId in pairs(self.Cfg.StageIds) do
        if not self.StageDataList[stageId] then
            self.StageDataList[stageId] = XTwoSideTowerStage.New(stageId)
        end
    end
end

function XTwoSideTowerPoint:GetId()
    return self.Cfg.Id
end

function XTwoSideTowerPoint:GetName()
    return self.Cfg.Name
end

function XTwoSideTowerPoint:GetNumberName()
    return self.Cfg.NumberName
end

function XTwoSideTowerPoint:GetStageDataList()
    local list = {}
    for _, stageData in pairs(self.StageDataList) do
        table.insert(list, stageData)
    end
    table.sort(list, function(a, b)
        return a:GetStageId() < b:GetStageId()
    end)
    return list
end

function XTwoSideTowerPoint:GetPointScore()
    local isPass = true
    for _, stageData in pairs(self.StageDataList) do
        if not stageData:IsPass() then
            isPass = false
        end
    end

    if isPass then
        return self.PointScore
    else
        return self:CalculateGetScore()
    end
end

function XTwoSideTowerPoint:GetMaxPointScore()
    return self.MaxPointScore
end

function XTwoSideTowerPoint:IsShieldFeature(featureId)
    for _, id in pairs(self.ShieldFeatures) do
        if id == featureId then
            return true
        end
    end
    return false
end

function XTwoSideTowerPoint:GetShieldFeatures()
    return self.ShieldFeatures
end

function XTwoSideTowerPoint:GetFinishFeatures()
    return self.FinishFeatures
end

function XTwoSideTowerPoint:IsFinishFeature(featureId)
    for _, id in pairs(self.FinishFeatures) do
        if id == featureId then
            return true
        end
    end
    return false
end

function XTwoSideTowerPoint:GetInitScore()
    return self.Cfg.InitScore or 0
end

function XTwoSideTowerPoint:UpdateData(data)
    self.PointScore = data.PointScore or 0
    self.MaxPointScore = data.MaxPointScore
    self.ShieldFeatures = data.ShieldFeatures
    self.FinishFeatures = data.FinishFeatures
    for _, stageData in pairs(data.StageDataList) do
        if not self.StageDataList[stageData.StageId] then
            self.StageDataList[stageData.StageId] = XTwoSideTowerStage.New(stageData.StageId)
        end
        self.StageDataList[stageData.StageId]:UpdateData(stageData)
    end
end

function XTwoSideTowerPoint:GetPointIconByDirection(isPositive)
    if isPositive then
        return CS.XGame.ClientConfig:GetString("TwoSideTowerPositiveIcon")
    else
        return CS.XGame.ClientConfig:GetString("TwoSideTowerNegativeIcon")
    end
end

function XTwoSideTowerPoint:GetNegativeStage()
    for _, stageData in pairs(self.StageDataList) do
        if stageData:IsNegative() then
            return stageData
        end
    end
end

-- 获取逆向关卡的特性id
function XTwoSideTowerPoint:GetNegativeStageFeatureId()
    local positiveStage = nil
    local negativeStage = nil
    for _, stageData in pairs(self.StageDataList) do
        if stageData:IsPositive() then
            positiveStage = stageData
        elseif stageData:IsNegative() then
            negativeStage = stageData
        end
    end

    if positiveStage then
        return negativeStage:GetFeatureId()
    else
        return XTwoSideTowerConfigs.UnknowFeatureId
    end
end

function XTwoSideTowerPoint:CalculateGetScore()
    return math.floor(self.Cfg.InitScore - self:GetReduceScore())
end

function XTwoSideTowerPoint:GetReduceScore()
    return #self.ShieldFeatures >= REDUCE_SCORE_CNT and self.Cfg.ReduceScoreParam or 0
end

function XTwoSideTowerPoint:IsFinish(direction)
    for _, stageData in pairs(self.StageDataList) do
        if stageData:GetDirection() == direction then
            return true, stageData:GetDirection()
        end
    end
    return false, nil
end

return XTwoSideTowerPoint
