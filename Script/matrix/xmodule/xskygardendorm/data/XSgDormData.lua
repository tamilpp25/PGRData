local XSgFurnitureData = require("XModule/XSkyGardenDorm/Data/XSgFurnitureData")
local XSgDormLayout = require("XModule/XSkyGardenDorm/Data/XSgDormLayout")

---@class XSgDormData 宿舍数据
---@field _OwnFurnitureDict table<number, XSgFurnitureData> 所有家具
---@field _AreaType2LayoutData table<number, table<number, XSgDormLayout>>
---@field _FurnitureCfgId2IdDict table<number, number[]>
local XSgDormData = XClass(nil, "XSgDormData")

function XSgDormData:Ctor()
    --当前宿舍涂装
    self._FashionId = 0
    --已解锁涂装
    self._UnlockFashionDict = {}
    --拥有的家具
    self._OwnFurnitureDict = {}
    --家具配置Id索引自增Id
    self._FurnitureCfgId2IdDict = {}
    --已经解锁的家具
    self._UnlockFurnitureDict = {}
    --预设
    self._AreaType2LayoutData = {}
    --当前区域所选的预设Id
    self._AreaType2LayoutId = {}
end

function XSgDormData:Reset()
    self._FashionId = 0

    self._UnlockFashionDict = nil
    self._OwnFurnitureDict = nil
    self._FurnitureCfgId2IdDict = nil
    self._UnlockFurnitureDict = nil
    self._AreaType2LayoutData = nil
    self._AreaType2LayoutId = nil
end

function XSgDormData:NotifySgDormData(data)
    if not data then
        return
    end
    self._FashionId = data.CurFashionId
    self._AreaType2LayoutId = data.CurAreaLayout
    self:UpdateDormFashionList(data.DormFashionList)
    self:UpdateOwnDormFurnitureList(data.FurnitureList)
    --self:UpdatePutFurnitureDict(data.CurFurnitureInfo)
    self:UpdateLayoutList(data.LayoutList)
end

function XSgDormData:NotifySgDormFashionAdd(data)
    if not data then
        return
    end
    local fashion = data.AddDormFashion
    self._UnlockFashionDict[fashion.Id] = true
end

function XSgDormData:NotifySgDormCurLayout(data)
    if not data then
        return
    end
    local layoutData = data.CurLayout
    local areaType, id = layoutData.AreaType, layoutData.LayoutId
    local areaDict = self._AreaType2LayoutData[areaType]
    if not areaDict then
        areaDict = {}
        self._AreaType2LayoutData[areaType] = areaDict
    end
    local layout = areaDict[id]
    if not layout then
        layout = XSgDormLayout.New(id)
        areaDict[id] = layout
    end
    layout:UpdateData(layoutData)
end

--- 更新所有涂装列表
function XSgDormData:UpdateDormFashionList(fashionList)
    if XTool.IsTableEmpty(fashionList) then
        return
    end
    for _, fashion in pairs(fashionList) do
        self._UnlockFashionDict[fashion.Id] = true
    end
end

--- 更新拥有的家具
function XSgDormData:UpdateOwnDormFurnitureList(furnitureList)
    if XTool.IsTableEmpty(furnitureList) then
        return
    end
    
    local newFurnitureDict = {}
    local newUnlockDict = {}
    local newCfgId2IdDict = {}
    for _, fData in pairs(furnitureList) do
        local cfgId = fData.CfgId
        local furniture = self._OwnFurnitureDict[fData.Id]
        if not furniture then
            furniture = XSgFurnitureData.New(fData.Id)
        end
        furniture:UpdateData(fData)
        newFurnitureDict[fData.Id] = furniture
        
        
        local list = newCfgId2IdDict[cfgId]
        if not list then
            list = {}
            newCfgId2IdDict[cfgId] = list
        end
        list[#list + 1] = fData.Id
        newUnlockDict[cfgId] = true
    end
    self._OwnFurnitureDict = newFurnitureDict
    self._UnlockFurnitureDict = newUnlockDict
    self._FurnitureCfgId2IdDict = newCfgId2IdDict
    
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_DORM_FURNITURE_REFRESH)
end

function XSgDormData:AddFurnitureList(furnitureList)
    if XTool.IsTableEmpty(furnitureList) then
        return
    end
    local newFurnitureDict = self._OwnFurnitureDict
    local newUnlockDict = self._UnlockFurnitureDict
    local newCfgId2IdDict = self._FurnitureCfgId2IdDict
    for _, fData in pairs(furnitureList) do
        local cfgId = fData.CfgId
        local furniture = newFurnitureDict[fData.Id]
        if not furniture then
            furniture = XSgFurnitureData.New(fData.Id)
            newFurnitureDict[fData.Id] = furniture
        end
        furniture:UpdateData(fData)


        local list = newCfgId2IdDict[cfgId]
        if not list then
            list = {}
            newCfgId2IdDict[cfgId] = list
        end
        list[#list + 1] = fData.Id
        newUnlockDict[cfgId] = true
    end

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_DORM_FURNITURE_REFRESH)
end

function XSgDormData:UpdateLayoutList(layoutList)
    if XTool.IsTableEmpty(layoutList) then
        return
    end
    for _, lData in pairs(layoutList) do
        local areaType, id = lData.AreaType, lData.LayoutId
        local areaDict = self._AreaType2LayoutData[areaType]
        if not areaDict then
            areaDict = {}
            self._AreaType2LayoutData[areaType] = areaDict
        end
        local layout = areaDict[id]
        if not layout then
            layout = XSgDormLayout.New(id)
            areaDict[id] = layout
        end
        layout:UpdateData(lData)
    end
end

function XSgDormData:UpdateCurFashionId(fashionId)
    self._FashionId = fashionId
end

function XSgDormData:GetCurFashionId()
    return self._FashionId
end

function XSgDormData:IsFashionUnlock(fashionId)
    return self._UnlockFashionDict[fashionId] ~= nil
end

function XSgDormData:GetOwnFurnitureDict()
    return self._OwnFurnitureDict
end

function XSgDormData:CheckFurnitureUnlockById(id)
    return self._OwnFurnitureDict[id] ~= nil
end

function XSgDormData:CheckFurnitureUnlockByConfigId(cfgId)
    return self._UnlockFurnitureDict[cfgId]
end

--- 获取未摆放的家具
---@param cfgId number
---@param containerFurnitureData XSgContainerFurnitureData 当前区域已经摆放的家具
---@return number[]
function XSgDormData:GetNotPutFurnitureIdList(cfgId, containerFurnitureData)
    local list = self._FurnitureCfgId2IdDict[cfgId]
    if XTool.IsTableEmpty(list) then
        return list
    end
    local temp = {}
    for _, id in pairs(list) do
        local container = containerFurnitureData:GetContainer()
        if container:GetId() ~= id and not containerFurnitureData:CheckContainFurnitureById(id) then
            temp[#temp + 1] = id
        end
    end
    return temp
end

--- 根据配置Id获取已经拥有的家具Id列表
---@param cfgId number
---@return number[]
function XSgDormData:GetFurnitureIdListByConfigId(cfgId)
    return self._FurnitureCfgId2IdDict[cfgId]
end

--region Layout

function XSgDormData:IsLayoutEmpty(areaType, id)
    local layout = self:GetLayoutData(areaType, id)
    if not layout then
        return true
    end
    return layout:IsEmpty()
end

function XSgDormData:SetLayoutIdWithAreaType(areaType, id)
    self._AreaType2LayoutId[areaType] = id
end

---@param containerData XSgContainerFurnitureData
function XSgDormData:SetContainerFurnitureData(areaType, id, containerData)
    local areaDict = self._AreaType2LayoutData[areaType]
    if not areaDict then
        return
    end
    local layout = areaDict[id]
    if not layout then
        return
    end
    layout:SetContainerFurnitureData(containerData)
end

---@return XSgDormLayout
function XSgDormData:GetLayoutData(areaType, layoutId)
    local dict = self._AreaType2LayoutData[areaType]
    if XTool.IsTableEmpty(dict) then
        return false
    end
    local layoutData = dict[layoutId]
    return layoutData
end

---@return XSgContainerFurnitureData
function XSgDormData:GetContainerFurnitureData(areaType, layoutId)
    local layout = self:GetLayoutData(areaType, layoutId)
    if not layout then
        return
    end
    return layout:GetContainerFurnitureData()
end

function XSgDormData:SetContainerFurnitureData(areaType, layoutId, containerFurnitureData)
    local layout = self:GetLayoutData(areaType, layoutId)
    if not layout then
        return
    end
    layout:SetContainerFurnitureData(containerFurnitureData)
end

---@return XSgFurnitureData
function XSgDormData:GetLayoutContainer(areaType, layoutId)
    local containerFurnitureData = self:GetContainerFurnitureData(areaType, layoutId)
    if not containerFurnitureData then
        return
    end
    return containerFurnitureData:GetContainer()
end

function XSgDormData:CheckContainFurnitureById(areaType, layoutId, id)
    local containerFurnitureData = self:GetContainerFurnitureData(areaType, layoutId)
    if not containerFurnitureData then
        return false
    end
    return containerFurnitureData:CheckContainFurnitureById(id)
end

function XSgDormData:CheckContainFurnitureByConfigId(areaType, layoutId, cfgId)
    local containerFurnitureData = self:GetContainerFurnitureData(areaType, layoutId)
    if not containerFurnitureData then
        return false
    end
    return containerFurnitureData:CheckContainFurnitureByConfigId(cfgId)
end

function XSgDormData:GetLayoutIdByAreaType(areaType)
    return self._AreaType2LayoutId[areaType]
end

--endregion

return XSgDormData