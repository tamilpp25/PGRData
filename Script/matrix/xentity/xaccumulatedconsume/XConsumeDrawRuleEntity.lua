---@class ConsumeDrawRuleEntity
local XConsumeDrawRuleEntity = XClass(nil, "XConsumeDrawRuleEntity")

function XConsumeDrawRuleEntity:Ctor(drawId)
    self.RuleConfig = XAccumulatedConsumeConfig.GetDrawRule(drawId)
    self.ProbShowConfig = XAccumulatedConsumeConfig.GetDrawProbShowByDrawId(drawId)
    self.RewardTypeConfig = XAccumulatedConsumeConfig.GetDrawRewardTypeConfig()

    self.RewardTypeInfo = {}
    for _, probShow in pairs(self.ProbShowConfig) do
        if self.RewardTypeInfo[probShow.RewardType] == nil then
            self.RewardTypeInfo[probShow.RewardType] = {}
        end
        table.insert(self.RewardTypeInfo[probShow.RewardType], probShow)
    end
end

function XConsumeDrawRuleEntity:GetBaseRules()
    return self.RuleConfig.BaseRules
end

function XConsumeDrawRuleEntity:GetBaseRuleTitles()
    return self.RuleConfig.BaseRuleTitles
end

function XConsumeDrawRuleEntity:GetProbShow(rewardType)
    return self.RewardTypeInfo[rewardType]
end

function XConsumeDrawRuleEntity:GetRewardType()
    local config = {}
    for key, _ in pairs(self.RewardTypeInfo) do
        table.insert(config, key)
    end
    table.sort(config, function(a, b)
        return a < b
    end)
    return config
end

function XConsumeDrawRuleEntity:GetRewardTypeConfig(rewardType)
    return self.RewardTypeConfig[rewardType]
end

return XConsumeDrawRuleEntity