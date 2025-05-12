---@class XTheatre4Event
local XTheatre4Event = XClass(nil, "XTheatre4Event")

function XTheatre4Event:Ctor()
    -- 当前EventId
    self.EventId = 0
    -- 关卡Id
    self.StageId = 0
    -- 关卡得分
    self.StageScore = 0
end

-- 服务端通知
function XTheatre4Event:NotifyEventData(data)
    self.EventId = data.EventId or 0
    self.StageId = data.StageId or 0
    self.StageScore = data.StageScore or 0
end

-- 获取事件Id
function XTheatre4Event:GetEventId()
    return self.EventId
end

-- 获取关卡Id
function XTheatre4Event:GetStageId()
    return self.StageId
end

-- 获取关卡得分
function XTheatre4Event:GetStageScore()
    return self.StageScore
end

return XTheatre4Event
