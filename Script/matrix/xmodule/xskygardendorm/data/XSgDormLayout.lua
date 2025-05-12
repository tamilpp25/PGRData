
local XSgContainerFurnitureData = require("XModule/XSkyGardenDorm/Data/XSgContainerFurnitureData")

--服务器是按照list进行存储的，但是前端只会有一条内容
local ContainerIndex = 1

---@class XSgDormLayout 预设
---@field _ContainerData XSgContainerFurnitureData
local XSgDormLayout = XClass(nil, "XSgDormLayout")

function XSgDormLayout:Ctor(id)
    self:Reset()
    self._Id = id
end

function XSgDormLayout:Reset()
    self._Id = 0
    self._AreaType = 0
    self._ContainerData = nil
end

function XSgDormLayout:UpdateData(data)
    if not data then
        return
    end
    self._Id = data.LayoutId
    self._AreaType = data.AreaType
    self:UpdateDormFashionList(data.FurnitureInfos)
end

--- 更新拥有的家具
function XSgDormLayout:UpdateDormFashionList(containerList)
    if XTool.IsTableEmpty(containerList) then
        return
    end
    if not self._ContainerData then
        self._ContainerData = XSgContainerFurnitureData.New()
    end
    
    for _, fInfo in pairs(containerList) do
        self._ContainerData:UpdateData(fInfo)
    end
end

---@return XSgContainerFurnitureData
function XSgDormLayout:GetContainerFurnitureData()
    return self._ContainerData
end

---@param containerData XSgContainerFurnitureData
function XSgDormLayout:SetContainerFurnitureData(containerData)
    self._ContainerData = containerData
end

function XSgDormLayout:IsEmpty()
    return not self._ContainerData or self._ContainerData:IsEmpty()
end

return XSgDormLayout