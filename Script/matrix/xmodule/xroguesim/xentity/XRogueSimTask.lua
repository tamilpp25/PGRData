---@class XRogueSimTask
local XRogueSimTask = XClass(nil, "XRogueSimTask")

function XRogueSimTask:Ctor()
    -- 自增Id
    self.Id = 0
    -- 配置表Id
    self.ConfigId = 0
    self.Schedule = 0
    self.State = 1
end

function XRogueSimTask:UpdateTaskData(data)
    self.Id = data.Id or 0
    self.ConfigId = data.ConfigId or 0
    self.Schedule = data.Schedule or 0
    self.State = data.State or 1
end

function XRogueSimTask:GetConfigId()
    return self.ConfigId
end

function XRogueSimTask:GetSchedule()
    return self.Schedule
end

function XRogueSimTask:GetState()
    return self.State
end

return XRogueSimTask
