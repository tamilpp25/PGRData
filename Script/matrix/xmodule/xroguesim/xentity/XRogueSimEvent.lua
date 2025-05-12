---@class XRogueSimEvent
local XRogueSimEvent = XClass(nil, "XRogueSimEvent")

function XRogueSimEvent:Ctor()
    -- 自增Id
    self.Id = 0
    -- 配置表Id
    self.ConfigId = 0
    -- 格子Id
    self.GridId = 0
    -- 获取回合数
    self.CreateTurnNumber = 0
    -- 创建截止回合数
    self.CreateDeadlineTurnNumber = 0
    -- 拍卖行奖励ID
    self.RewardId = 0
    -- 当前截止回合数
    self.CurDeadlineTurnNumber = 0
end

function XRogueSimEvent:UpdateEventData(data)
    self.Id = data.Id or 0
    self.ConfigId = data.ConfigId or 0
    self.GridId = data.GridId or 0
    self.CreateTurnNumber = data.CreateTurnNumber or 0
    self.CreateDeadlineTurnNumber = data.CreateDeadlineTurnNumber or 0
    self.RewardId = data.RewardId or 0
    self.CurDeadlineTurnNumber = data.CurDeadlineTurnNumber or 0
end

function XRogueSimEvent:UpdateEventConfigId(id)
    self.ConfigId = id
end

function XRogueSimEvent:UpdateEventRewardId(rewardId)
    self.RewardId = rewardId or 0
end

function XRogueSimEvent:UpdateEventCurDeadlineTurnNumber(turnNumber)
    self.CurDeadlineTurnNumber = turnNumber or 0
end

function XRogueSimEvent:GetId()
    return self.Id
end

function XRogueSimEvent:GetConfigId()
    return self.ConfigId
end

function XRogueSimEvent:GetGridId()
    return self.GridId
end

function XRogueSimEvent:GetCreateTurnNumber()
    return self.CreateTurnNumber
end

function XRogueSimEvent:GetCreateDeadlineTurnNumber()
    return self.CreateDeadlineTurnNumber
end

function XRogueSimEvent:GetRewardId()
    return self.RewardId
end

function XRogueSimEvent:GetCurDeadlineTurnNumber()
    return self.CurDeadlineTurnNumber
end

return XRogueSimEvent
