-- 命运模块数据（事件线）
---@class XTheatre4Fate
local XTheatre4Fate = XClass(nil, "XTheatre4Fate")

function XTheatre4Fate:Ctor()
    -- 命运配置id
    self.Id = 0
    -- 命运事件id
    self.FateEventId = 0
    -- 事件
    ---@type XTheatre4Event
    self.Event = nil
    -- 剩余时间
    self.EventTimeLeft = 0
end

-- 服务端通知
function XTheatre4Fate:NotifyFateData(data)
    self.Id = data.TableRowId
    self.FateEventId = data.UniqueId
    self:UpdateEvent(data.Event)
    self.EventTimeLeft = data.EventTimeLeft
end

-- 更新事件
function XTheatre4Fate:UpdateEvent(data)
    if not data then
        self.Event = nil
        return
    end
    if not self.Event then
        self.Event = require("XModule/XTheatre4/XEntity/XTheatre4Event").New()
    end
    self.Event:NotifyEventData(data)
end

-- 获取配置Id
function XTheatre4Fate:GetId()
    return self.Id
end

-- 获取命运事件Id
function XTheatre4Fate:GetFateEventId()
    return self.FateEventId
end

-- 获取事件Id
function XTheatre4Fate:GetEventId()
    if not self.Event then
        return 0
    end
    return self.Event:GetEventId()
end

-- 获取关卡Id
function XTheatre4Fate:GetStageId()
    if not self.Event then
        return 0
    end
    return self.Event:GetStageId()
end

-- 获取关卡分数
function XTheatre4Fate:GetStageScore()
    if not self.Event then
        return 0
    end
    return self.Event:GetStageScore()
end

-- 获取剩余时间
function XTheatre4Fate:GetEventTimeLeft()
    return self.EventTimeLeft
end

return XTheatre4Fate
