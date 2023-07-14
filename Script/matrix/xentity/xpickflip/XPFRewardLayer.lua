local XRewardPreviewViewModel = require("XEntity/XCommon/XRewardPreviewViewModel")
local XPFReward = require("XEntity/XPickFlip/XPFReward")
local XPFRewardLayer = XClass(nil, "XPFRewardLayer")

function XPFRewardLayer:Ctor(id)
    self.Config = XPickFlipConfigs.GetRewardLayerConfig(id)
    self.Rewards = {}
    -- PickFlipFinishRewardState 0未完成 1完成
    self.FinishedState = 0
    -- -- 当前选择的奖励数量
    -- self.CurrentSelectRewardCount = 0
    self.IsConfigFinised = false
    self.CurrentComsumeLimitCount = self:GetMaxConsumeLimitCount()
end

function XPFRewardLayer:InitOrUpadateWithServerData(data)
    -- rewardData : XPickFlipRewardData
    local rewardDatas = data.RewardDatas
    local reward = nil
    self.IsConfigFinised = false
    if rewardDatas then
        self.Rewards = {}
        for index, rewardData in ipairs(rewardDatas) do
            reward = XPFReward.New(rewardData.RewardId)
            reward:SetState(rewardData.State)
            reward:SetIndex(index)
            table.insert(self.Rewards, reward)
            self.IsConfigFinised = true
        end
    end
    -- 层奖励完成状态
    self.FinishedState = data.FinishRewardState
    self.CurrentComsumeLimitCount = self:GetMaxConsumeLimitCount() - data.ExchangeTimes
end

function XPFRewardLayer:GetId()
    return self.Config.Id
end

function XPFRewardLayer:GetGroupId()
    return self.Config.ActivityId
end

function XPFRewardLayer:GetLayerIndex()
    return self.Config.Order
end

function XPFRewardLayer:GetConsumeIcon()
    return XDataCenter.ItemManager.GetItemIcon(self:GetConsumeItemId())
end

-- 获取单次消耗的数量
function XPFRewardLayer:GetConsumeCount()
    return self.Config.ConsumeItemCount
end

function XPFRewardLayer:GetFinishRewardId()
    return self.Config.FinishRewardId
end

function XPFRewardLayer:GetRewardIcon()
    return XEntityHelper.GetRewardIcon(self.Config.FinishRewardId)
end

function XPFRewardLayer:GetProgress()
    return self:GetCurrentRewardCount() / self:GetMaxRewardCount()
end

-- 获取本层奖励是否已经被领取
function XPFRewardLayer:GetRewardIsReceived()
    return self.FinishedState == XPickFlipConfigs.LayerRewardState.Rewarded
end

function XPFRewardLayer:GetConsumeItemId()
    return self.Config.ConsumeItemId
end

function XPFRewardLayer:GetAssetPath()
    return XUiConfigs.GetComponentUrl("UiPickFlip0" .. 
        ((self:GetLayerIndex() % 2) + 1))
end

function XPFRewardLayer:GetRewardAssetPath()
    return XUiConfigs.GetComponentUrl("UiPickFlipGrid")
end

-- 获取奖励是否配置完成
function XPFRewardLayer:GetIsConfigFinished()
    return self.IsConfigFinised
end

function XPFRewardLayer:GetMaxSelectCount()
    return self.Config.SelectRewardCount
end

function XPFRewardLayer:GetMaxRewardCount()
    return self.Config.SelectRewardCount + self.Config.RandomRewardCount
end

function XPFRewardLayer:GetCurrentRewardCount()
    local result = 0
    for _, reward in ipairs(self.Rewards) do
        if reward:GetState() == XPickFlipConfigs.RewardState.Fliped then
            result = result + 1
        end
    end
    return result
end

function XPFRewardLayer:GetRewardByIndex(index)
    return self.Rewards[index]
end

-- XPickFlipConfigs.RewardType
function XPFRewardLayer:GetConfigFinishedRewards(rewardType)
    if rewardType == nil then rewardType = XPickFlipConfigs.RewardType.All end
    local result = {}
    for _, reward in ipairs(self.Rewards) do
        if reward:GetType() == rewardType 
            or rewardType == XPickFlipConfigs.RewardType.All then
            table.insert(result, reward)
        end
    end
    table.sort(result, function(rewardA, rewardB)
        return rewardA:GetIndex() < rewardB:GetIndex()
    end)
    return result
end

function XPFRewardLayer:GetAllSelectableRewards()
    local rewardIds = XPickFlipConfigs.GetLayerRewardIds(self.Config.Id, XPickFlipConfigs.RewardType.Select)
    local result = {}
    for _, id in ipairs(rewardIds) do
        table.insert(result, XPFReward.New(id))
    end
    return result
end

function XPFRewardLayer:GetRewardPreviewViewModel()
    local result = XRewardPreviewViewModel.New()
    local currentCount = 0
    -- 特殊奖励
    local specialRewards = {}
    for _, reward in ipairs(self:GetConfigFinishedRewards(XPickFlipConfigs.RewardType.Random)) do
        table.insert(specialRewards, {
            TemplateId = reward:GetShowItemId(),
            Count = reward:GetCount(),
            StockCount = reward:GetState() == XPickFlipConfigs.RewardState.Fliped and 0 or 1
        })
        if reward:GetState() == XPickFlipConfigs.RewardState.Fliped then
            currentCount = currentCount + 1
        end
    end
    XEntityHelper.SortItemDatas(specialRewards)
    -- 正常奖励
    local normalRewards = {}
    for _, reward in ipairs(self:GetConfigFinishedRewards(XPickFlipConfigs.RewardType.Select)) do
        table.insert(normalRewards, {
            TemplateId = reward:GetShowItemId(),
            Count = reward:GetCount(),
            StockCount = reward:GetState() == XPickFlipConfigs.RewardState.Fliped and 0 or 1
        })
        if reward:GetState() == XPickFlipConfigs.RewardState.Fliped then
            currentCount = currentCount + 1
        end
    end
    XEntityHelper.SortItemDatas(normalRewards)
    -- 设置数量
    result:SetCurrentCount(currentCount)
    result:SetMaxCount(#normalRewards + #specialRewards)
    -- 设置标题
    result:SetSpecialTitle(XUiHelper.GetText("PickFlipRandomRewardTitle"))
    result:SetNormalTitle(XUiHelper.GetText("PickFlipFixedRewardTitle"))
    -- 设置奖励
    result:SetNormalRewards(normalRewards)
    result:SetSpecialRewards(specialRewards)
    return result
end

function XPFRewardLayer:GetMaxConsumeLimitCount()
    return self:GetMaxRewardCount()
end

function XPFRewardLayer:GetCurrentConsumeLimitCount(value)
    return self.CurrentComsumeLimitCount
end

function XPFRewardLayer:SetCurrentConsumeLimitCount(value)
    XNetwork.Call("PickFlipActivityAddExchangeTimesRequest", { Id = self.Config.ActivityId, Times = value }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self.CurrentComsumeLimitCount = self:GetMaxConsumeLimitCount() - res.Times
    end)
end

return XPFRewardLayer