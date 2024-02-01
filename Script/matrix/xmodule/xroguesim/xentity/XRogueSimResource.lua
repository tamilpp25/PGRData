---@class XRogueSimResource
local XRogueSimResource = XClass(nil, "XRogueSimResource")

function XRogueSimResource:Ctor()
    self.Id = 0
    self.Count = 0
end

function XRogueSimResource:UpdateResourceData(data)
    self.Id = data.Id or 0
    self.Count = data.Count or 0
end

function XRogueSimResource:GetCount()
    return self.Count
end

return XRogueSimResource
