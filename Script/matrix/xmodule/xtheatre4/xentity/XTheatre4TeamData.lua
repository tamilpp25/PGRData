---@class XTheatre4TeamData
local XTheatre4TeamData = XClass(nil, "XTheatre4TeamData")

function XTheatre4TeamData:Ctor()
    -- 队长位置
    self.CaptainPos = 0
    -- 首发位置
    self.FirstFightPos = 0
    -- 入场NPC索引
    self.EnterCgIndex = 0
    -- 结算NPC索引
    self.SettleCgIndex = 0
    -- 角色Id
    ---@type number[]
    self.CardIds = {}
    -- 机器人Id
    ---@type number[]
    self.RobotIds = {}
end

-- 服务端通知
function XTheatre4TeamData:NotifyTeamData(data)
    self.CaptainPos = data.CaptainPos or 0
    self.FirstFightPos = data.FirstFightPos or 0
    self.EnterCgIndex = data.EnterCgIndex or 0
    self.SettleCgIndex = data.SettleCgIndex or 0
    self.CardIds = data.CardIds or {}
    self.RobotIds = data.RobotIds or {}
end

-- 获取队长位置
function XTheatre4TeamData:GetCaptainPos()
    return self.CaptainPos
end

-- 获取首发位置
function XTheatre4TeamData:GetFirstFightPos()
    return self.FirstFightPos
end

-- 获取入场NPC索引
function XTheatre4TeamData:GetEnterCgIndex()
    return self.EnterCgIndex
end

-- 获取结算NPC索引
function XTheatre4TeamData:GetSettleCgIndex()
    return self.SettleCgIndex
end

-- 获取角色Id
function XTheatre4TeamData:GetCardIds()
    return self.CardIds
end

-- 获取机器人Id
function XTheatre4TeamData:GetRobotIds()
    return self.RobotIds
end

return XTheatre4TeamData
