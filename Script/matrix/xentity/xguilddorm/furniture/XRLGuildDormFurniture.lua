---@class XRLGuildDormFurniture
local XRLGuildDormFurniture = XClass(nil, "XRLGuildDormFurniture")

function XRLGuildDormFurniture:Ctor()
    self.GameObject = nil
    self.Transform = nil
end

function XRLGuildDormFurniture:GetGameObject()
    return self.GameObject
end

function XRLGuildDormFurniture:GetTransform()
    return self.Transform
end

return XRLGuildDormFurniture