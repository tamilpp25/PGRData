local XSkyGardenDormConfig = require("XModule/XSkyGardenDorm/XSkyGardenDormConfig")
local XSgDormFightFurnitureData = require("XModule/XSkyGardenDorm/Data/XSgDormFightFurnitureData")
local XSgDormFightContainerData = require("XModule/XSkyGardenDorm/Data/XSgDormFightContainerData")

---@class XSkyGardenDormModel : XSkyGardenDormConfig
---@field _DormData XSgDormData
---@field _FightFurnitureDict table<number, XSgDormFightFurnitureData>
local XSkyGardenDormModel = XClass(XSkyGardenDormConfig, "XSkyGardenDormModel")
function XSkyGardenDormModel:OnInit()
    self._FightFurnitureDict = {}
    self._Layer = 0
    XSkyGardenDormConfig.OnInit(self)
end

function XSkyGardenDormModel:ClearPrivate()
    XSkyGardenDormConfig.ClearPrivate(self)
end

function XSkyGardenDormModel:ResetAll()
    if self._DormData then
        self._DormData:Reset()
    end
    self._FightFurnitureDict = nil
    self._DormData = nil
    self._WallFightData = nil
    self._GiftShelfFightData = nil
    XSkyGardenDormConfig.ResetAll(self)
end

function XSkyGardenDormModel:NotifySgDormData(data)
    self:GetDormData():NotifySgDormData(data)
end

function XSkyGardenDormModel:NotifySgDormFurnitureAdd(data)
    if not data then
        return
    end
    self:GetDormData():AddFurnitureList(data.AddFurnitureList)
end

function XSkyGardenDormModel:NotifySgDormFashionAdd(data)
    self:GetDormData():NotifySgDormFashionAdd(data)
end

function XSkyGardenDormModel:NotifySgDormCurLayout(data)
    self:GetDormData():NotifySgDormCurLayout(data)
end

---@return XSgDormData
function XSkyGardenDormModel:GetDormData()
    if not self._DormData then
        self._DormData = require("XModule/XSkyGardenDorm/Data/XSgDormData").New()
    end
    return self._DormData
end

function XSkyGardenDormModel:CheckContainFurnitureById(areaType, id)
    local layoutId = self:GetLayoutIdByAreaType(areaType)
    return self:GetDormData():CheckContainFurnitureById(areaType, layoutId, id)
end

function XSkyGardenDormModel:CheckContainFurnitureByConfigId(areaType, cfgId)
    local layoutId = self:GetLayoutIdByAreaType(areaType)
    return self:GetDormData():CheckContainFurnitureByConfigId(areaType, layoutId, cfgId)
end

function XSkyGardenDormModel:GetLayoutContainer(areaType, index)
    local layoutId = self:GetLayoutIdByAreaType(areaType)
    return self:GetDormData():GetLayoutContainer(areaType, layoutId, index)
end

function XSkyGardenDormModel:GetContainerFurnitureData(areaType)
    local layoutId = self:GetLayoutIdByAreaType(areaType)
    return self:GetDormData():GetContainerFurnitureData(areaType, layoutId)
end

---@return XSgDormFightContainerData
function XSkyGardenDormModel:GetWallFightData()
    if not self._WallFightData then
        self._WallFightData = XSgDormFightContainerData.New()
    end
    
    return self._WallFightData
end

---@return XSgDormFightContainerData
function XSkyGardenDormModel:GetGiftShelfFightData()
    if not self._GiftShelfFightData then
        self._GiftShelfFightData = XSgDormFightContainerData.New()
    end
    
    return self._GiftShelfFightData
end

function XSkyGardenDormModel:GetLayoutIdByAreaType(areaType)
    local id = self:GetDormData():GetLayoutIdByAreaType(areaType)
    if not id then
        local list = self:GetDormLayoutIdList(areaType)
        id = list[1]
    end
    return id
end

function XSkyGardenDormModel:SetLayoutIdWithAreaType(areaType, id)
    self:GetDormData():SetLayoutIdWithAreaType(areaType, id)
end

function XSkyGardenDormModel:UpdateFightFurnitureData(fightDataList)
    if XTool.IsTableEmpty(fightDataList) then
        return
    end
    for index, data in pairs(fightDataList) do
        local id = data.Id
        self:AddFightFurnitureData(id, data, index)
    end
end

function XSkyGardenDormModel:AddFightFurnitureData(id, data, index)
    if not self._FightFurnitureDict then
        self._FightFurnitureDict = {}
    end
    local fightFurniture = self._FightFurnitureDict[id]
    if not fightFurniture then
        fightFurniture = XSgDormFightFurnitureData.New(id)
        self._FightFurnitureDict[id] = fightFurniture
    end
    local min, max, component
    if data.MoveComponent then
        min, max = data.MinPos, data.MaxPos
        component = data.MoveComponent
    else
        local giftShelfData = self:GetGiftShelfFightData()
        min, max = giftShelfData:GetSize(index)
        component = data.Transform
    end
    fightFurniture:UpdateData(min, max, component)
end

function XSkyGardenDormModel:RemoveFightFurnitureData(id)
    if not self._FightFurnitureDict then
        return
    end
    self._FightFurnitureDict[id] = nil
end

function XSkyGardenDormModel:RemoveAllFightFurnitureData()
    self._FightFurnitureDict = {}
end

---@return XSgDormFightFurnitureData
function XSkyGardenDormModel:GetFightFurnitureData(id)
    if not self._FightFurnitureDict then
        return
    end
    local fightFurniture = self._FightFurnitureDict[id]
    if not fightFurniture then
        XLog.Error("不存在家具Transform数据! Id = " .. id)
        return
    end
    return fightFurniture
end

function XSkyGardenDormModel:GetFightInitData(containWall, containGift)
    
    local photos, adorns, gifts

    if containWall then
        --照片墙
        local containerFurnitureData = self:GetContainerFurnitureData(XMVCA.XSkyGardenDorm.XSgDormAreaType.Wall)
        photos, adorns = self:GetPhotoWallFightInitData(containerFurnitureData)
    end

    if containGift then
        --摆件架
        local containerFurnitureData = self:GetContainerFurnitureData(XMVCA.XSkyGardenDorm.XSgDormAreaType.GiftShelf)
        gifts = self:GetGiftShelfFightInitData(containerFurnitureData)
        
    end
    return photos, adorns, gifts
end

---@param containerFurnitureData XSgContainerFurnitureData
function XSkyGardenDormModel:GetPhotoWallFightInitData(containerFurnitureData)
    if not containerFurnitureData then
        containerFurnitureData = self:GetContainerFurnitureData(XMVCA.XSkyGardenDorm.XSgDormAreaType.Wall)
    end
    local photos, adorns = {}, {}
    local photoType = XMVCA.XSkyGardenDorm.XSgFurnitureType.Photo
    local decorationType = XMVCA.XSkyGardenDorm.XSgFurnitureType.Decoration
    local ratio = XMVCA.XSkyGardenDorm.Ratio
    
    local dict = containerFurnitureData:GetFurnitureDict()
    for _, f in pairs(dict) do
        local cfgId = f:GetCfgId()
        local majorType = self:GetFurnitureMajorType(cfgId)
        local x, y = f:GetPos()
        if majorType == photoType then
            photos[#photos + 1] = {
                Id = f:GetId(),
                SoId = self:GetFurnitureSceneObjId(cfgId),
                X = x / ratio,
                Y = y / ratio,
                Angle = f:GetAngle() / ratio,
                Layer = f:GetLayer()
            }
        elseif majorType == decorationType then
            adorns[#adorns + 1] = {
                Id = f:GetId(),
                SoId = self:GetFurnitureSceneObjId(cfgId),
                X = x / ratio,
                Y = y / ratio,
                Angle = f:GetAngle() / ratio,
                Layer = f:GetLayer()
            }
        end
    end
    return photos, adorns
end

---@param containerFurnitureData XSgContainerFurnitureData
function XSkyGardenDormModel:GetGiftShelfFightInitData(containerFurnitureData)
    if not containerFurnitureData then
        containerFurnitureData = self:GetContainerFurnitureData(XMVCA.XSkyGardenDorm.XSgDormAreaType.GiftShelf)
    end
    local giftType = XMVCA.XSkyGardenDorm.XSgFurnitureType.Gift
    local gifts = {}
    local dict = containerFurnitureData:GetFurnitureDict()
    for _, f in pairs(dict) do
        local cfgId = f:GetCfgId()
        local majorType = self:GetFurnitureMajorType(cfgId)
        if majorType == giftType then
            gifts[#gifts + 1] = {
                Id = f:GetId(),
                SoId = self:GetFurnitureSceneObjId(cfgId),
                PosIndex = f:GetIndex()
            }
        end
    end
    return gifts
end

function XSkyGardenDormModel:SetMaxLayer(layer)
    self._Layer = layer
end

function XSkyGardenDormModel:AddLayer()
    self._Layer = self._Layer + 1
    return self._Layer
end

function XSkyGardenDormModel:GetLayer()
    return self._Layer
end

function XSkyGardenDormModel:IsFashionUnlock(fashionId)
    local unlock = self:GetDormData():IsFashionUnlock(fashionId)
    if unlock then
        return true
    end
    return self:IsDefaultFashion(fashionId)
end

function XSkyGardenDormModel:GetCookieKey(key)
    return string.format("SKY_GARDEN_DORM_%s_%s", tostring(XPlayer.Id), key)
end

function XSkyGardenDormModel:GetDormLayoutIconFileName(areaType, id)
    return string.format("%s_sky_dorm_%s_%s", tostring(XPlayer.Id), tostring(areaType), tostring(id))
end

return XSkyGardenDormModel