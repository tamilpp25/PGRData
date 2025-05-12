---@class XRogueSimCity
local XRogueSimCity = XClass(nil, "XRogueSimCity")

function XRogueSimCity:Ctor()
    -- 自增Id
    self.Id = 0
    -- 城邦Id
    self.ConfigCityId = 0
    -- 格子ID
    self.GridId = 0
    -- 是否探索
    self.IsExplored = false
    -- 任务自增Id列表
    self.TaskIds = {}
    -- 城邦等级
    self.Level = 0
end

function XRogueSimCity:UpdateCityData(data)
    self.Id = data.Id or 0
    self.ConfigCityId = data.ConfigCityId or 0
    self.GridId = data.GridId or 0
    self.IsExplored = data.IsExplored or false
    self.TaskIds = data.TaskIds or {}
    self.Level = data.Level or 0
end

function XRogueSimCity:GetId()
    return self.Id
end

function XRogueSimCity:GetConfigCityId()
    return self.ConfigCityId
end

function XRogueSimCity:GetGridId()
    return self.GridId
end

function XRogueSimCity:GetIsExplored()
    return self.IsExplored
end

function XRogueSimCity:GetTaskIds()
    return self.TaskIds
end

function XRogueSimCity:GetLevel()
    return self.Level
end

return XRogueSimCity
