---@class XTheatre4Fight
local XTheatre4Fight = XClass(nil, "XTheatre4Fight")

function XTheatre4Fight:Ctor()
    -- 战斗组Id
    self.FightGroupId = 0
    -- 关卡Id
    self.StageId = 0
    -- 怪物血量万分比
    self.HpPercent = 0
    -- 惩罚倒计时
    self.PunishCountdown = 0
    -- 战斗事件
    ---@type number[]
    self.FightEvents = {}
    -- 奖励
    ---@type XTheatre4Asset[]
    self.Rewards = {}
end

-- 服务端通知
function XTheatre4Fight:NotifyFightData(data)
    self.FightGroupId = data.FightGroupId or 0
    self.StageId = data.StageId or 0
    self.HpPercent = data.HpPercent or 0
    self.PunishCountdown = data.PunishCountdown or 0
    self.FightEvents = data.FightEvents or {}
    self:UpdateRewards(data.Rewards)
end

-- 更新奖励
function XTheatre4Fight:UpdateRewards(data)
    self.Rewards = {}
    if not data then
        return
    end
    for k, v in ipairs(data) do
        self:AddReward(k, v)
    end
end

-- 更新奖励
function XTheatre4Fight:AddReward(index, data)
    if not data then
        return
    end
    ---@type XTheatre4Asset
    local reward = require("XModule/XTheatre4/XEntity/XTheatre4Asset").New()
    reward:NotifyAssetData(data)
    self.Rewards[index] = reward
end

-- 获取战斗组Id
function XTheatre4Fight:GetFightGroupId()
    return self.FightGroupId
end

-- 获取关卡Id
function XTheatre4Fight:GetStageId()
    return self.StageId
end

-- 获取怪物血量万分比
function XTheatre4Fight:GetHpPercent()
    return self.HpPercent
end

-- 获取惩罚倒计时
function XTheatre4Fight:GetPunishCountdown()
    return self.PunishCountdown
end

-- 获取战斗事件
function XTheatre4Fight:GetFightEvents()
    return self.FightEvents
end

-- 获取奖励
---@return XTheatre4Asset[]
function XTheatre4Fight:GetRewards()
    return self.Rewards
end

return XTheatre4Fight
