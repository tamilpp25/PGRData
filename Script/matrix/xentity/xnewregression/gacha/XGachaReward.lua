local XGachaReward = XClass(nil, "XGachaReward")

function XGachaReward:Ctor(id)
    self.Config = XNewRegressionConfigs.GetGachaRewardConfig(id)
end

function XGachaReward:GetId()
    return self.Config.Id
end

function XGachaReward:GetTemplateId()
    return self.Config.TemplateId
end

function XGachaReward:GetCount()
    return self.Config.Count
end

-- 获取可抽中的次数
function XGachaReward:GetUsableTimes()
    return self.Config.UsableTimes
end

return XGachaReward