---@class XRogueSimReward
local XRogueSimReward = XClass(nil, "XRogueSimReward")

function XRogueSimReward:Ctor()
    -- 自增Id
    self.Id = 0
    -- 掉落配置id
    self.DropId = 0
    -- 来源
    self.Source = 0
    -- 奖励列表
    ---@type number[]
    self.Rewards = {}
    -- 格子Id
    self.GridId = 0
    -- 是否已领取
    self.Pick = false
end

function XRogueSimReward:UpdateRewardData(data)
    self.Id = data.Id or 0
    self.DropId = data.DropId or 0
    self.Source = data.Source or 0
    self.Rewards = data.Rewards or {}
    self.GridId = data.GridId or 0
    self.Pick = data.Pick or false
end

-- 获取自增Id
function XRogueSimReward:GetId()
    return self.Id
end

-- 获取掉落配置id
function XRogueSimReward:GetDropId()
    return self.DropId
end

-- 获取来源
function XRogueSimReward:GetSource()
    return self.Source
end

-- 获取奖励列表
function XRogueSimReward:GetRewards()
    return self.Rewards
end

-- 获取格子Id
function XRogueSimReward:GetGridId()
    return self.GridId
end

-- 是否已领取
function XRogueSimReward:GetPick()
    return self.Pick
end

return XRogueSimReward
