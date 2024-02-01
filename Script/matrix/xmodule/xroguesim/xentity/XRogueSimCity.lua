---@class XRogueSimCity
local XRogueSimCity = XClass(nil, "XRogueSimCity")

function XRogueSimCity:Ctor()
    -- 自增Id
    self.Id = 0
    -- 配置表Id
    self.ConfigId = 0
    -- 格子ID
    self.GridId = 0
    -- 是否探索
    self.IsExplored = false
    -- 任务自增Id
    self.TaskId = 0
end

function XRogueSimCity:UpdateCityData(data)
    self.Id = data.Id or 0
    self.ConfigId = data.ConfigId or 0
    self.GridId = data.GridId or 0
    self.IsExplored = data.IsExplored or false
    self.TaskId = data.TaskId or 0
end

function XRogueSimCity:GetId()
    return self.Id
end

function XRogueSimCity:GetConfigId()
    return self.ConfigId
end

function XRogueSimCity:GetGridId()
    return self.GridId
end

function XRogueSimCity:GetIsExplored()
    return self.IsExplored
end

function XRogueSimCity:GetTaskId()
    return self.TaskId
end

return XRogueSimCity
