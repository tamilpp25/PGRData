
---@class XSgDormFightFurnitureData 
local XSgDormFightFurnitureData = XClass(nil, "XSgDormFightFurnitureData")

function XSgDormFightFurnitureData:Ctor(id)
    self._Id = id
end

function XSgDormFightFurnitureData:UpdateData(min, max, component)
    self._Min = min
    self._Max = max
    self._Component = component
end

function XSgDormFightFurnitureData:GetSize()
    return self._Min, self._Max
end

function XSgDormFightFurnitureData:GetComponent()
    return self._Component
end

return XSgDormFightFurnitureData