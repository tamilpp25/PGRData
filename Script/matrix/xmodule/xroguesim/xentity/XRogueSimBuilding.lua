---@class XRogueSimBuilding
local XRogueSimBuilding = XClass(nil, "XRogueSimBuilding")

function XRogueSimBuilding:Ctor()
    -- 自增Id
    self.Id = 0
    -- 配置表Id
    self.ConfigId = 0
    -- 格子ID
    self.GridId = 0
    -- 获取回合数
    self.CreateTurnNumber = 0
    -- 事件刷新倒计时(回合数)
    self.RefreshCountDown = 0
    -- 是否自建
    self.IsBuildByBluePrint = false
    -- 未收取奖励
    self.RefreshRewardId = 0
end

function XRogueSimBuilding:UpdateBuildingData(data)
    self.Id = data.Id or 0
    self.ConfigId = data.ConfigId or 0
    self.GridId = data.GridId or 0
    self.CreateTurnNumber = data.CreateTurnNumber or 0
    self.RefreshCountDown = data.RefreshCountDown or 0
    self.IsBuildByBluePrint = data.IsBuildByBluePrint or false
    self.RefreshRewardId = data.RefreshRewardId or 0
end

function XRogueSimBuilding:GetId()
    return self.Id
end

function XRogueSimBuilding:GetConfigId()
    return self.ConfigId
end

function XRogueSimBuilding:GetGridId()
    return self.GridId
end

function XRogueSimBuilding:GetIsBuildByBluePrint()
    return self.IsBuildByBluePrint
end

return XRogueSimBuilding
