---@class XRogueSimBuff
local XRogueSimBuff = XClass(nil, "XRogueSimBuff")

function XRogueSimBuff:Ctor()
    -- buff唯一id
    self.Id = 0
    -- buff配置id
    self.BuffId = 0
    -- 剩余回合数(小于0时为无限)
    self.RemainingTurn = -1
    -- 剩余次数(小于0时为无限)
    self.RemainingTimes = -1
    -- 创建回合数
    self.CreateTurn = 0
    -- 来源 SourceType
    self.Source = 0
    -- 标识
    self.Identify = 0
    -- 扩展数据
    ---@type number[]
    self.Extra = {}
end

function XRogueSimBuff:UpdateBuffData(data)
    self.Id = data.Id or 0
    self.BuffId = data.BuffId or 0
    self.RemainingTurn = data.RemainingTurn or -1
    self.RemainingTimes = data.RemainingTimes or -1
    self.CreateTurn = data.CreateTurn or 0
    self.Source = data.Source or 0
    self.Identify = data.Identify or 0
    self.Extra = data.Extra or {}
end

-- 获取buff唯一id
function XRogueSimBuff:GetId()
    return self.Id
end

-- 获取buff配置id
function XRogueSimBuff:GetBuffId()
    return self.BuffId
end

-- 获取剩余回合数
function XRogueSimBuff:GetRemainingTurn()
    return self.RemainingTurn
end

-- 获取来源
function XRogueSimBuff:GetSource()
    return self.Source
end

-- 获取标识
function XRogueSimBuff:GetIdentify()
    return self.Identify
end

return XRogueSimBuff
