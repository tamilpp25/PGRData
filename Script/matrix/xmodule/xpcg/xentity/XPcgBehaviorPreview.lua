---@class XPcgBehaviorPreview
local XPcgBehaviorPreview = XClass(nil, "XPcgBehaviorPreview")

function XPcgBehaviorPreview:Ctor()
    -- 行为id
    ---@type number
    self.BehaviorId = 0
    -- 效果表id
    ---@type number
    self.Id = 0
    -- 行为值
    ---@type number
    self.Value = 0
end

function XPcgBehaviorPreview:RefreshData(data)
    self.BehaviorId = data.BehaviorId or 0
    self.Id = data.Id or 0
    self.Value = data.Value or 0
end

function XPcgBehaviorPreview:GetBehaviorId()
    return self.BehaviorId
end

function XPcgBehaviorPreview:GetId()
    return self.Id
end

function XPcgBehaviorPreview:GetValue()
    return self.Value
end

return XPcgBehaviorPreview