
local XSgFurnitureData = require("XModule/XSkyGardenDorm/Data/XSgFurnitureData")

---@class XSgContainerFurnitureData 容器数据
---@field _Container XSgFurnitureData 
---@field _FurnitureDict table<number, XSgFurnitureData> 
local XSgContainerFurnitureData = XClass(nil, "XSgContainerFurnitureData")

function XSgContainerFurnitureData:Ctor()
    self._FurnitureDict = {}
end

function XSgContainerFurnitureData:UpdateData(data)
    if not data then
        return
    end
    local container = data.Container
    if not self._Container then
        self._Container = XSgFurnitureData.New(container.Id)
    end
    self._Container:UpdateData(container)
    local place = data.PlacementFurniture
    if not XTool.IsTableEmpty(place) then
        local newDict = {}
        for _, fData in pairs(place) do
            local f = self._FurnitureDict[fData.Id]
            if not f then
                f = XSgFurnitureData.New(fData.Id)
            end
            f:UpdateData(fData)
            newDict[fData.Id] = f
        end

        self._FurnitureDict = newDict
    else
        self:ClearAllFurniture()
    end
end

---@return XSgFurnitureData
function XSgContainerFurnitureData:GetContainer()
    return self._Container
end

function XSgContainerFurnitureData:ChangeContainer(id, cfgId)
    self._Container:UpdateData({
        Id = id,
        CfgId = cfgId
    })
end

function XSgContainerFurnitureData:ClearAllFurniture()
    self._FurnitureDict = {}
end

function XSgContainerFurnitureData:GetFurnitureDict()
    return self._FurnitureDict
end

---@return XSgFurnitureData
function XSgContainerFurnitureData:GetFurniture(id)
    return self._FurnitureDict[id]
end

function XSgContainerFurnitureData:CheckContainFurnitureById(id)
    if self._Container and self._Container:GetId() == id then
        return true
    end
    local furniture = self._FurnitureDict[id]
    return furniture ~= nil
end

function XSgContainerFurnitureData:CheckContainFurnitureByConfigId(cfgId)
    if self._Container and self._Container:GetCfgId() == cfgId then
        return true
    end
    for _, furniture in pairs(self._FurnitureDict) do
        if furniture:GetCfgId() == cfgId then
            return true
        end
    end
    return false
end

function XSgContainerFurnitureData:AddFurniture(id, cfgId, index, layer)
    local f = self._FurnitureDict[id]
    if not f then
        ---@type XSgFurnitureData
        f = XSgFurnitureData.New(id)
        self._FurnitureDict[id] = f
    end
    f:SetCfgId(cfgId)
    f:SetIndex(index)
    f:SetLayer(layer)
end

function XSgContainerFurnitureData:RemoveFurniture(id)
    self._FurnitureDict[id] = nil
end

---@param other XSgContainerFurnitureData
function XSgContainerFurnitureData:Equal(other)
    if not other then
        return false
    end
    if not self._Container:Equal(other:GetContainer()) then
        return false
    end
    local dict = other:GetFurnitureDict()
    for id, furniture in pairs(self._FurnitureDict) do
        local oF = dict[id]
        if not oF or not furniture:Equal(oF) then
            return false
        end
    end
    return XTool.GetTableCount(self._FurnitureDict) == XTool.GetTableCount(dict)
end

function XSgContainerFurnitureData:ToServerData()
    local list = {}
    local minLayer = 99999999
    for _, furniture in pairs(self._FurnitureDict) do
        local data = furniture:ToServerData()
        minLayer = math.min(minLayer, data.Layer)
        list[#list + 1] = data
    end
    --避免超出上限，每次tongue服务器时，将layer同比减少
    if minLayer > 1000 then
        for _, data in pairs(list) do
            data.Layer = data.Layer - minLayer
        end
    end
    
    return {
        Container = self._Container:ToServerData(),
        PlacementFurniture = list
    }
end

function XSgContainerFurnitureData:IsEmpty()
    if self._Container then
        return false
    end
    return XTool.IsTableEmpty(self._FurnitureDict)
end

---@return XSgContainerFurnitureData
function XSgContainerFurnitureData:Clone()
    ---@type XSgContainerFurnitureData
    local data = XSgContainerFurnitureData.New()
    
    data._Container = self._Container:Clone()
    local dict = data._FurnitureDict
    for id, f in pairs(self._FurnitureDict) do
        dict[id] = f:Clone()
    end
    
    return data
end

return XSgContainerFurnitureData