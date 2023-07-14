local XRewardPreviewViewModel = require("XEntity/XCommon/XRewardPreviewViewModel")
local XGachaReward = require("XEntity/XNewRegression/Gacha/XGachaReward")
local XGachaGroup = XClass(nil, "XGachaGroup")

function XGachaGroup:Ctor(id)
    self.Config = XNewRegressionConfigs.GetGachaGroupConfig(id)
    -- 核心奖励数据 XGachaReward
    self.CoreRewards = nil
    -- 普通奖励数据 XGachaReward
    self.NormalRewards = nil
    -- XNewRegressionConfigs.GachaGroupState
    self.State = XNewRegressionConfigs.GachaGroupState.Begin
    -- 奖励抽中次数字典
    self.RewardTimesDic = {}
end

function XGachaGroup:InitWithServerData(data)
    self.State = data.State
    if data.GridDatas then
        self:UpdateRewardTimesDic(data.GridDatas)
    end
end

function XGachaGroup:UpdateWithServerData(data)
    self.State = data.State
    if data.GridDatas then
        self:UpdateRewardTimesDic(data.GridDatas)
    end
end

function XGachaGroup:UpdateRewardTimesDic(value)
    for _, rewardData in ipairs(value) do
        self.RewardTimesDic[rewardData.Id] = rewardData.Times
    end
end

function XGachaGroup:GetId()
    return self.Config.Id
end

function XGachaGroup:GetGachaId()
    return self.Config.GachaId
end

function XGachaGroup:GetRewardTotalCount()
    if self._rewardTotalCount == nil then
        self._rewardTotalCount = 0
        local config
        for _, groupId in ipairs(self.Config.RewardGroup) do
            for _, id in ipairs(XNewRegressionConfigs.GetGachaRewardIds(groupId)) do
                config = XNewRegressionConfigs.GetGachaRewardConfig(id)
                self._rewardTotalCount = self._rewardTotalCount + config.UsableTimes
            end
        end
    end
    return self._rewardTotalCount
end

function XGachaGroup:GetRewardRemainingCount()
    local totalCount = self:GetRewardTotalCount()
    local usedCount = 0
    for _, count in pairs(self.RewardTimesDic) do
        usedCount = usedCount + count
    end
    return totalCount - usedCount
end

-- 获取核心奖励数据
function XGachaGroup:GetCoreRewards()
    if self.CoreRewards == nil then
        self.CoreRewards = {}
        local rewardGroupId = self.Config.CoreRewardGroupId
        for _, id in ipairs(XNewRegressionConfigs.GetGachaRewardIds(rewardGroupId)) do
            table.insert(self.CoreRewards, XGachaReward.New(id))
        end
    end
    return self.CoreRewards
end

-- 获取普通奖励数据
function XGachaGroup:GetNormalRewards()
    if self.NormalRewards == nil then
        self.NormalRewards = {} 
        local rewardGroupId
        for i = 1, #self.Config.RewardGroup do
            rewardGroupId = self.Config.RewardGroup[i]
            if rewardGroupId ~= self.Config.CoreRewardGroupId then
                for _, id in ipairs(XNewRegressionConfigs.GetGachaRewardIds(rewardGroupId)) do
                    table.insert(self.NormalRewards, XGachaReward.New(id))
                end
            end
        end
    end
    return self.NormalRewards
end

-- XNewRegressionConfigs.GachaGroupState
function XGachaGroup:GetState()
    return self.State
end

function XGachaGroup:GetIsFinishedCoreReward()
    return self.State == XNewRegressionConfigs.GachaGroupState.CoreFinished
        or self.State == XNewRegressionConfigs.GachaGroupState.Done
end

function XGachaGroup:GetIsDone()
    return self.State == XNewRegressionConfigs.GachaGroupState.Done
end

function XGachaGroup:GetRewardUsedTimes(id)
    return self.RewardTimesDic[id] or 0
end

function XGachaGroup:GetRewardPreviewViewModel()
    local viewModel = XRewardPreviewViewModel.New()
    -- 特殊奖励
    local specialRewards = {}
    for _, reward in ipairs(self:GetCoreRewards()) do
        table.insert(specialRewards, {
            TemplateId = reward:GetTemplateId(),
            Count = reward:GetCount(),
            StockCount = reward:GetUsableTimes() - self:GetRewardUsedTimes(reward:GetId())
        })
    end
    viewModel:SetSpecialRewards(specialRewards)
    -- 普通奖励
    local normalRewards = {}
    for _, reward in ipairs(self:GetNormalRewards()) do
        table.insert(normalRewards, {
            TemplateId = reward:GetTemplateId(),
            Count = reward:GetCount(),
            StockCount = reward:GetUsableTimes() - self:GetRewardUsedTimes(reward:GetId())
        })
    end
    viewModel:SetNormalRewards(normalRewards)
    return viewModel
end

return XGachaGroup