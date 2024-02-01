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
end

function XRogueSimEvent:UpdateEventData(data)
    self.Id = data.Id or 0
    self.ConfigId = data.ConfigId or 0
    self.GridId = data.GridId or 0
    self.CreateTurnNumber = data.CreateTurnNumber or 0
end

function XRogueSimEvent:UpdateEventConfigId(id)
    self.ConfigId = id
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

return XRogueSimEvent
