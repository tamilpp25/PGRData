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
    self.EventRefreshCountDown = 0
    -- 是否购买
    self.IsBuy = false
end

function XRogueSimBuilding:UpdateBuildingData(data)
    self.Id = data.Id or 0
    self.ConfigId = data.ConfigId or 0
    self.GridId = data.GridId or 0
    self.CreateTurnNumber = data.CreateTurnNumber or 0
    self.EventRefreshCountDown = data.EventRefreshCountDown or 0
    self.IsBuy = data.IsBuy or false
end

function XRogueSimBuilding:UpdateIsBuy()
    self.IsBuy = true
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

function XRogueSimBuilding:CheckIsBuy()
    return self.IsBuy
end

return XRogueSimBuilding
