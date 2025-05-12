-- 上一次冒险结算数据
---@class XTheatre4AdventureSettle
local XTheatre4AdventureSettle = XClass(nil, "XTheatre4AdventureSettle")

function XTheatre4AdventureSettle:Ctor()
    -- 结算类型
    self.SettleType = 0
    -- 结局ID
    self.EndingId = 0
    -- 翻牌数
    self.GridPassCount = 0
    -- 可继承的藏品列表
    ---@type number[]
    self.InheritItems = {}
    -- 最终繁荣度
    self.Prosperity = 0
    -- 星级BP奖励
    self.StarBpExp = 0
    -- 奖励
    self.RewardGoods = {}
    -- 结算时间
    self.SettleTime = 0
end

-- 服务端通知
function XTheatre4AdventureSettle:NotifyPreAdventureSettleData(data)
    self.SettleType = data.SettleType or 0
    self.EndingId = data.EndingId or 0
    self.GridPassCount = data.GridPassCount or 0
    self.InheritItems = data.InheritItems or {}
    self.Prosperity = data.Prosperity or 0
    self.StarBpExp = data.StarBpExp or 0
    self.RewardGoods = data.RewardGoods or {}
    self.SettleTime = data.SettleTime or 0
end

-- 获取结算类型
function XTheatre4AdventureSettle:GetSettleType()
    return self.SettleType
end

-- 获取结局ID
function XTheatre4AdventureSettle:GetEndingId()
    return self.EndingId
end

-- 获取翻牌数
function XTheatre4AdventureSettle:GetGridPassCount()
    return self.GridPassCount
end

-- 获取可继承的藏品列表
function XTheatre4AdventureSettle:GetInheritItems()
    return self.InheritItems
end

-- 获取最终繁荣度
function XTheatre4AdventureSettle:GetProsperity()
    return self.Prosperity
end

-- 获取星级BP奖励
function XTheatre4AdventureSettle:GetStarBpExp()
    return self.StarBpExp
end

-- 获取奖励
function XTheatre4AdventureSettle:GetRewardGoods()
    return self.RewardGoods
end

-- 获取结算时间
function XTheatre4AdventureSettle:GetSettleTime()
    return self.SettleTime
end

return XTheatre4AdventureSettle
