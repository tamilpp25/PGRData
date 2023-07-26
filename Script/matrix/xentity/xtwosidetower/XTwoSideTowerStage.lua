---@class XTwoSideTowerStage
local XTwoSideTowerStage = XClass(nil, "XTwoSideTowerStage")

function XTwoSideTowerStage:Ctor(id)
    self.Cfg = XTwoSideTowerConfigs.GetStageCfg(id)
end

function XTwoSideTowerStage:GetName()
    return XDataCenter.FubenManager.GetStageName(self.Cfg.Id)
end

function XTwoSideTowerStage:GetSmallMonsterIcon()
    return self.Cfg.SmallMonsterIcon
end

function XTwoSideTowerStage:GetBigMonsterIcon()
    return self.Cfg.BigMonsterIcon
end

function XTwoSideTowerStage:GetWeakIcon()
    return self.Cfg.WeakIcon
end

function XTwoSideTowerStage:GetFeatureId()
    return self.Cfg.FeatureId
end

function XTwoSideTowerStage:GetStageTypeName()
    return self.Cfg.StageTypeName
end

function XTwoSideTowerStage:GetStageNumberName()
    return self.Cfg.StageNumberName
end

function XTwoSideTowerStage:UpdateData(data)
    self.Direction = data.Direction
end

function XTwoSideTowerStage:IsPass()
    return self.Direction ~= nil
end
 
function XTwoSideTowerStage:GetStageId()
    return self.Cfg.Id
end

-- self.Direction 默认为nil
-- 选择正向关卡并挑战成功时，self.Direction = XTwoSideTowerConfigs.Direction.Positive
function XTwoSideTowerStage:IsPositive()
    return self.Direction == XTwoSideTowerConfigs.Direction.Positive
end

function XTwoSideTowerStage:IsNegative()
    return self.Direction ~= XTwoSideTowerConfigs.Direction.Positive
end

function XTwoSideTowerStage:GetDirection()
    return self.Direction
end

function XTwoSideTowerStage:GetDesc()
    return XDataCenter.FubenManager.GetStageDes(self.Cfg.Id)
end

return XTwoSideTowerStage