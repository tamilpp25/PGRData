
---@class XSkyGardenDormConfig : XModel
local XSkyGardenDormConfig = XClass(XModel, "XSkyGardenDormConfig")


local TableKey = {
    SgDormFurniture = {
        ReadFunc = XConfigUtil.ReadType.IntAll,
        CacheType = XConfigUtil.CacheType.Normal,
    },
    SgDormFurnitureType = { 
        ReadFunc = XConfigUtil.ReadType.IntAll,
        CacheType = XConfigUtil.CacheType.Normal
    },
    SgDormLayout = {
        ReadFunc = XConfigUtil.ReadType.IntAll,
    },
    SgDormFashion = {
        ReadFunc = XConfigUtil.ReadType.IntAll,
        CacheType = XConfigUtil.CacheType.Normal,
    },
    SgDormConfig = {
        ReadFunc = XConfigUtil.ReadType.String,
        Identifier = "Key"
    }
}

function XSkyGardenDormConfig:OnInit()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/SkyGarden/Dormitory", TableKey)
end

function XSkyGardenDormConfig:ClearPrivate()
end

function XSkyGardenDormConfig:ResetAll() 
    self._AreaType2FurnitureTypeList = nil
    self._AreaType2LayoutIds = nil
    self._AllFashionIds = nil
    self._FurnitureCache = nil
    self._MajorType2TypeId = nil
end

---@return XTableSgDormFurniture
function XSkyGardenDormConfig:GetFurnitureTemplate(furnitureId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgDormFurniture, furnitureId)
end

function XSkyGardenDormConfig:InitFurnitureListCache()
    ---@type table<number, XTableSgDormFurniture>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.SgDormFurniture)

    local dict = {}
    for _, t in pairs(templates) do
        if t.IsShow then
            local cfgId, typeId = t.Id, t.TypeId
            local list = dict[typeId]
            if not list then
                list = {}
                dict[typeId] = list
            end
            list[#list + 1] = cfgId
        end
    end
    self._FurnitureCache = dict
end

function XSkyGardenDormConfig:GetFurnitureListByTypeId(typeId)
    if not XTool.IsTableEmpty(self._FurnitureCache) then
        return self._FurnitureCache[typeId]
    end
    self:InitFurnitureListCache()
    return self._FurnitureCache[typeId]
end

function XSkyGardenDormConfig:GetFurnitureTypeId(furnitureId)
    local t = self:GetFurnitureTemplate(furnitureId)
    return t and t.TypeId or 0
end

function XSkyGardenDormConfig:GetFurnitureAreaType(furnitureId)
    local typeId = self:GetFurnitureTypeId(furnitureId)
    local t = self:GetFurnitureTypeTemplate(typeId)
    return t and t.AreaType or 0
end

function XSkyGardenDormConfig:GetFurnitureMajorType(furnitureId)
    local typeId = self:GetFurnitureTypeId(furnitureId)
    local t = self:GetFurnitureTypeTemplate(typeId)
    return t and t.MajorType or 0
end

function XSkyGardenDormConfig:GetFurnitureMinorType(furnitureId)
    local typeId = self:GetFurnitureTypeId(furnitureId)
    local t = self:GetFurnitureTypeTemplate(typeId)
    return t and t.MinorType or 0
end

function XSkyGardenDormConfig:GetFurniturePutInfo(furnitureId)
    local t = self:GetFurnitureTemplate(furnitureId)
    return t.PutMajorType, t.PutCapacity
end

function XSkyGardenDormConfig:GetFurnitureSceneObjId(furnitureId)
    local t = self:GetFurnitureTemplate(furnitureId)
    return t and t.SceneObjId or 0
end

function XSkyGardenDormConfig:GetFurnitureTypeList(areaType)
    local list = self._AreaType2FurnitureTypeList
    if list and list[areaType] then
        return list[areaType]
    end
    self:InitFurnitureTypeList()
    
    return self._AreaType2FurnitureTypeList[areaType]
end

function XSkyGardenDormConfig:GetTypeIdByMajorType(majorType)
    return self._MajorType2TypeId[majorType]
end

function XSkyGardenDormConfig:InitFurnitureTypeList()
    local temp = {}
    local map = {}
    local major2Id = {}
    ---@type table<number, XTableSgDormFurnitureType>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.SgDormFurnitureType)
    for _, t in pairs(templates) do
        major2Id[t.MajorType] = t.Id
        local lA = map[t.AreaType]
        if not lA then
            lA = {}
            map[t.AreaType] = lA
        end
        local lMajor = lA[t.MajorType]
        if not lMajor then
            lMajor = {}
            lA[t.MajorType] = lMajor
        end
        lMajor[t.MinorType] = t.Id
    end
    for aType, lMajor in pairs(map) do
        local lA = temp[aType]
        if not lA then
            lA = {}
            temp[aType] = lA
        end
        for major, dict in pairs(lMajor) do
            local l = {}
            for minor, id in pairs(dict) do
                l[#l + 1] = id
            end
            lA[#lA + 1] = l
        end
    end

    local sortFunc = function(idA, idB)
        local pA = self:GetFurnitureTypeTemplate(idA).Priority
        local pB = self:GetFurnitureTypeTemplate(idB).Priority
        if pA ~= pB then
            return pA < pB
        end
        return idA < idB
    end

    for _, l in pairs(temp) do
        if #l > 1 then
            table.sort(l, function(a, b)
                return sortFunc(a[1], b[1])
            end)
        end

        for i, ids in pairs(l) do
            if #ids > 1 then
                table.sort(l[i], sortFunc)
            end
        end
    end

    self._MajorType2TypeId = major2Id
    self._AreaType2FurnitureTypeList = temp
end

---@return XTableSgDormFurnitureType
function XSkyGardenDormConfig:GetFurnitureTypeTemplate(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgDormFurnitureType, id)
end

function XSkyGardenDormConfig:GetDormLayoutIdList(areaType)
    local list = self._AreaType2LayoutIds
    if list and list[areaType] then
        return list[areaType]
    end

    local dict = {}
    ---@type table<number, XTableSgDormLayout>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.SgDormLayout)
    for id, t in pairs(templates) do
        local temp = dict[t.AreaType]
        if not temp then
            temp = {}
            dict[t.AreaType] = temp
        end
        temp[#temp + 1] = id
    end
    self._AreaType2LayoutIds = dict
    
    return dict[areaType]
end

---@return XTableSgDormLayout
function XSkyGardenDormConfig:GetDormLayoutTemplate(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgDormLayout, id)
end

function XSkyGardenDormConfig:GetAllFashionIds()
    if self._AllFashionIds then
        return self._AllFashionIds
    end
    local list = {}
    ---@type table<number, XTableSgDormFashion>
    local templates = self._ConfigUtil:GetByTableKey(TableKey.SgDormFashion)
    for _, t in pairs(templates) do
        list[#list + 1] = t.Id
    end
    self._AllFashionIds = list
    
    return list
end

---@return XTableSgDormFashion
function XSkyGardenDormConfig:GetFashionTemplate(id, noTips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgDormFashion, id, noTips)
end

function XSkyGardenDormConfig:GetFashionSkinId(id)
    local t = self:GetFashionTemplate(id, true)
    return t and t.SkinId or 0
end

function XSkyGardenDormConfig:IsDefaultFashion(id)
    local t = self:GetFashionTemplate(id, true)
    return t and t.IsDefault or false
end

function XSkyGardenDormConfig:GetConfigValue(key, index)
    ---@type XTableSgDormConfig
    local t = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SgDormConfig, key)
    return t and t.Values[index] or ""
end

return XSkyGardenDormConfig