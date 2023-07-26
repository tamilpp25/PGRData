---@class XTurntableActivity
local XTurntableActivity = XClass(nil, "XTurntableActivity")

function XTurntableActivity:Ctor()
    ---活动Id
    self.ActivityId = 0
    ---累计抽取次数
    self.AccumulateDrawNum = 0
    ---已获得奖励信息 key=id,value=次数
    self.GainRewardInfos = {}
    ---抽奖记录 key=id,value=时间
    self.GainRecords = {}
    ---已领取累抽奖励
    self.GainAccumulateRewardIndexs = {}
end

function XTurntableActivity:NotifyTurntableActivity(data)
    self.ActivityId = data.ActivityId
    self.AccumulateDrawNum = data.AccumulateDrawNum
    self:UpdateGainRewardIndexs(data.GainAccumulateRewardIndexs)
    self:UpdateReward(data.GainRewardInfos)
    self:UpdateRecord(data.GainRecords)
end

function XTurntableActivity:UpdateReward(datas)
    if not datas then
        return
    end

    self.GainRewardInfos = {}
    for _, v in pairs(datas) do
        self.GainRewardInfos[v.Id] = v.GainTimes
    end
    XEventManager.DispatchEvent(XEventId.EVENT_TURNTABLE_ITEM_UPDATE)
end

function XTurntableActivity:UpdateRecord(datas, isAdd)
    if not datas then
        return
    end

    if not isAdd then
        self.GainRecords = {}
    end

    for _, v in pairs(datas) do
        local data = {}
        data.id = v.Id
        data.reward = v.RewardGoods
        data.time = v.GainTimestamp
        table.insert(self.GainRecords, data)
    end
end

function XTurntableActivity:GetActivityId()
    return self.ActivityId
end

function XTurntableActivity:GetAccumulateDrawNum()
    return self.AccumulateDrawNum
end

function XTurntableActivity:GetGainRewardInfos()
    return self.GainRewardInfos
end

function XTurntableActivity:GetGainRecords()
    return self.GainRecords
end

function XTurntableActivity:GetItemGainTimes(id)
    return self.GainRewardInfos[id] or 0
end

function XTurntableActivity:IsRewardGain(index)
    return self.GainAccumulateRewardIndexs[index] ~= nil
end

function XTurntableActivity:UpdateGainRewardIndexs(data)
    self.GainAccumulateRewardIndexs = data
    XEventManager.DispatchEvent(XEventId.EVENT_TURNTABLE_PROGRESS_REWARD)
end

function XTurntableActivity:GetNewTurntableId(rewards)
    local results = {}
    for _, v in pairs(rewards) do
        local lastNum = self:GetItemGainTimes(v.Id)
        for i = lastNum + 1, v.GainTimes do
            table.insert(results, v.Id)
        end
    end
    return results
end

return XTurntableActivity