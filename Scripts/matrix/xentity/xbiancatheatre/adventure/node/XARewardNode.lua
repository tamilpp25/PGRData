--奖励选择节点
local XARewardNode = XClass(nil, "XARewardNode")

function XARewardNode:Ctor(data)
    --唯一Id
    self._Uid = data.Uid
    --奖励类型, XBiancaTheatreNodeRewardType
    self._RewardType = data.RewardType
    --BiancaTheatreItemBox表的ID，
    --BiancaTheatreGold表的ID,
    --BiancaTheatreRecruitTicket表的ID
    self._ConfigId = data.ConfigId
    --物品数量，保底金币会有系统效果加成，没办法读表
    self._Count = data.Count
    -- 标签类型，XBiancaTheatreConfigs.NodeRewardTagType
    self._TagType = data.TagType
    --是否已领取
    self:UpdateReceived(data.Received)
end

function XARewardNode:GetUid()
    return self._Uid
end

function XARewardNode:GetRewardType()
    return self._RewardType
end

function XARewardNode:GetConfigId()
    return self._ConfigId
end

function XARewardNode:GetCount()
    return self._Count
end

function XARewardNode:GetTagType()
    return self._TagType
end

function XARewardNode:UpdateReceived(received)
    self._Received = received
end

function XARewardNode:IsReceived()
    return XTool.IsNumberValid(self._Received)
end

return XARewardNode