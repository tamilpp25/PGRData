---@class XTheatre4Asset
local XTheatre4Asset = XClass(nil, "XTheatre4Asset")

function XTheatre4Asset:Ctor()
    -- 类型
    self.Type = 0
    -- 类型对应物品id
    self.Id = 0
    -- 数量
    self.Num = 0
    -- 奖励配置Id
    self.RewardId = 0
end

-- 服务端通知
function XTheatre4Asset:NotifyAssetData(data)
    self.Type = data.Type or 0
    self.Id = data.Id or 0
    self.Num = data.Num or 0
    self.RewardId = data.RewardId or 0
end

-- 获取类型
function XTheatre4Asset:GetType()
    return self.Type
end

-- 获取物品Id
function XTheatre4Asset:GetId()
    return self.Id
end

-- 获取数量
function XTheatre4Asset:GetNum()
    return self.Num
end

-- 获取奖励配置Id
function XTheatre4Asset:GetRewardId()
    return self.RewardId
end

return XTheatre4Asset
