---@class XRogueSimProp
local XRogueSimProp = XClass(nil, "XRogueSimProp")

function XRogueSimProp:Ctor()
    -- 道具唯一Id
    self.Id = 0
    -- 道具配置id
    self.PropId = 0
    -- 剩余回合数(小于0为无回合限制)
    self.Turns = 0
    -- 获取时间
    self.Date = 0
end

function XRogueSimProp:UpdatePropData(data)
    self.Id = data.Id or 0
    self.PropId = data.PropId or 0
    self.Turns = data.Turns or 0
    self.Date = data.Date or 0
end

-- 获取道具自增Id
function XRogueSimProp:GetId()
    return self.Id
end

-- 获取道具配置id
function XRogueSimProp:GetPropId()
    return self.PropId
end

return XRogueSimProp
