
---@class XSgDormFightContainerData 
local XSgDormFightContainerData = XClass(nil, "XSgDormFightContainerData")

function XSgDormFightContainerData:Ctor()
end

function XSgDormFightContainerData:UpdateData(transform, sizeList)
    self._Transform = transform
    if sizeList then
        local list = {}
        for _, data in pairs(sizeList) do
            list[#list + 1] = data
        end
        self._SizeList = list
    end
end

function XSgDormFightContainerData:GetTransform()
    return self._Transform
end

function XSgDormFightContainerData:GetSize(posIndex)
    if not self._SizeList then
        return
    end
    return self._SizeList[posIndex]
end

return XSgDormFightContainerData