---@class XLottoDrawEntity
local XLottoDrawEntity = XClass(nil, "XLottoDrawEntity")
local XLottoRewardEntity = require("XEntity/XLotto/XLottoRewardEntity")

function XLottoDrawEntity:Ctor(id)
    self.Id = id
    self.ExtraRewardState = XLottoConfigs.ExtraRewardState.CanNotGet--额外奖励状态
    ---@type XLottoRewardEntity[]
    self.RewardDataList = {}
    self.LottoRecords = {}
    self.LottoRewards = {}
    self:CreateRewardDataList()
end

function XLottoDrawEntity:UpdateData(data)
    for key, value in pairs(data) do
        self[key] = value
    end
    self:UpdateRewardDataList()
end

function XLottoDrawEntity:CreateRewardDataList()
    local lottoRewardList = XLottoConfigs.GetLottoRewardListById(self.Id)
    for _,reward in pairs(lottoRewardList or {}) do
        local entity = XLottoRewardEntity.New(reward.Id)
        table.insert(self.RewardDataList,entity)
    end
    table.sort(self.RewardDataList,function (a, b)
        return a:GetPriority() < b:GetPriority()
    end)
end

function XLottoDrawEntity:UpdateRewardDataList()
    for _,entity in pairs(self.RewardDataList or {}) do
        for _,id in pairs(self.LottoRewards or {}) do
            if id == entity:GetId() then
                entity:MarkGeted()
                break
            end
        end
    end
end

function XLottoDrawEntity:GetCfg()
    return XLottoConfigs.GetLottoCfgById(self.Id)
end

function XLottoDrawEntity:GetId()
    return self.Id
end

function XLottoDrawEntity:GetLottoRewardList()
    return self.LottoRewards
end

function XLottoDrawEntity:GetExtraRewardState()
    return self.ExtraRewardState
end

function XLottoDrawEntity:GetRewardDataList()
    return self.RewardDataList
end

---@return XLottoRewardEntity
function XLottoDrawEntity:GetRewardDataById(lottoRewardId)
    for _,data in pairs(self.RewardDataList) do
        if data:GetId() == lottoRewardId then
            return data
        end
    end
end

function XLottoDrawEntity:GetCurRewardCount()
    return self.LottoRewards and #self.LottoRewards or 0
end

function XLottoDrawEntity:GetMaxRewardCount()
    return self.RewardDataList and #self.RewardDataList or 0
end

function XLottoDrawEntity:GetLottoRecordList()
    return self.LottoRecords
end

function XLottoDrawEntity:GetTimeId()
    return self:GetCfg().TimeId
end

function XLottoDrawEntity:GetLottoGroupId()
    return self:GetCfg().LottoGroupId
end

function XLottoDrawEntity:GetBanner()
    return self:GetCfg().Banner
end

function XLottoDrawEntity:GetExtraRewardId()
    return self:GetCfg().ExtraRewardId
end

function XLottoDrawEntity:GetExtraRewardCount()----达到额外奖励所需要的抽奖次数
    return self:GetCfg().ReachRewardTimes
end

function XLottoDrawEntity:GetBuyTicketRuleIdList()
    return self:GetCfg().BuyTicketRuleIdList
end

function XLottoDrawEntity:GetBuyTicketRuleId()
    return self:GetCfg().BuyTicketRuleIdList and self:GetCfg().BuyTicketRuleIdList[self:GetCurRewardCount() + 1] or 0
end

function XLottoDrawEntity:GetConsumeId()
    return self:GetCfg().ConsumeId
end

function XLottoDrawEntity:GetConsumeCountList()
    return self:GetCfg().ConsumeCountList
end

function XLottoDrawEntity:GetConsumeCount()
    return self:GetCfg().ConsumeCountList and self:GetCfg().ConsumeCountList[self:GetCurRewardCount() + 1] or -1
end

function XLottoDrawEntity:GetTopRewardData()
    local rewardData = {}
    for _,data in pairs(self.RewardDataList) do
        if data:GetRareLevel() == XLottoConfigs.RareLevel.One then
            rewardData = data
            break
        end
    end 
    return rewardData
end

function XLottoDrawEntity:IsLottoCountFinish()
    return self:GetCurRewardCount() >= self:GetMaxRewardCount()
end

function XLottoDrawEntity:GetBeginTime()
    local time = XFunctionManager.GetStartTimeByTimeId(self:GetTimeId())
    return time
end

function XLottoDrawEntity:GetEndTime()
    local time = XFunctionManager.GetEndTimeByTimeId(self:GetTimeId())
    return time
end

function XLottoDrawEntity:GetCoreRewardTemplateId()
    local rewardDataList = self:GetRewardDataList()
    local rewardId
    for _, rewardData in ipairs(rewardDataList) do
        if rewardData:GetRareLevel() == XLottoConfigs.RareLevel.One then
            rewardId = rewardData:GetTemplateId()
        end
    end
    return rewardId
end

return XLottoDrawEntity