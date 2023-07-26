---@class XHomeFurnitureData
XHomeFurnitureData = XClass(nil, "XHomeFurnitureData")

function XHomeFurnitureData:Ctor(data)
    self.Id = data.Id or 0
    self.PlayerId = 0
    self.ConfigId = data.ConfigId or 0
    self.X = data.X
    self.Y = data.Y
    self.Angle = data.Angle
    self.DormitoryId = data.DormitoryId or 0
    self.Addition = data.Addition
    self.AttrList = data.AttrList
    self.IsLocked = data.IsLocked
    self.BaseAttrList = data.BaseAttrList or {0, 0, 0} --基础属性分配
end

function XHomeFurnitureData:GetInstanceID()
    return self.Id
end

function XHomeFurnitureData:SetConfigId(cfgId)
    self.ConfigId = cfgId
end

function XHomeFurnitureData:GetConfigId()
    return self.ConfigId
end

function XHomeFurnitureData:SetUsedDormitoryId(dormitoryId)
    self.DormitoryId = dormitoryId
end

function XHomeFurnitureData:GetDormitoryId()
    return self.DormitoryId
end

function XHomeFurnitureData:CheckIsUsed()
    return self.DormitoryId > 0
end

function XHomeFurnitureData:GetScore()
    local score = 0
    if self.Addition > 0 then
        score = score + XFurnitureConfigs.GetAdditionalAddScore(self.Addition)
    end

    for _, attr in ipairs(self.AttrList) do
        score = score + attr
    end
    return score
end

function XHomeFurnitureData:GetAttrScore(attrType, attrScore)
    local score = attrScore or 0
    if self.Addition <= 0 then
        return score
    end

    local additionConfig = XFurnitureConfigs.GetAdditionAttrConfigById(self.Addition)
    if additionConfig == nil then
        return score
    end

    if additionConfig.AddType == XFurnitureConfigs.FurnitureAdditionType.AttrTotal then
        score = additionConfig.AddValue[attrType] + score
    elseif additionConfig.AddType == XFurnitureConfigs.FurnitureAdditionType.AttrTotalPercent then
        score = math.floor(additionConfig.AddValue[attrType] * score / 100) + score
    end

    return score
end

function XHomeFurnitureData:GetRedScore()
    return self:GetAttrScore(XFurnitureConfigs.AttrType.AttrA, self.AttrList[XFurnitureConfigs.AttrType.AttrA])
end

function XHomeFurnitureData:GetYellowScore()
    return self:GetAttrScore(XFurnitureConfigs.AttrType.AttrB, self.AttrList[XFurnitureConfigs.AttrType.AttrB])
end

function XHomeFurnitureData:GetBlueScore()
    return self:GetAttrScore(XFurnitureConfigs.AttrType.AttrC, self.AttrList[XFurnitureConfigs.AttrType.AttrC])
end

function XHomeFurnitureData:GetFurnitureTotalAttrLevel()
    if not XTool.IsNumberValid(self.ConfigId) then
        return XFurnitureConfigs.FurnitureAttrLevelId.LevelC
    end
    local template = XFurnitureConfigs.GetFurnitureTemplateById(self.ConfigId)
    local level, _, _ = XFurnitureConfigs.GetFurnitureTotalAttrLevel(template.TypeId, self:GetScore())
    return level
end

function XHomeFurnitureData:GetIsLocked()
    return self.IsLocked
end

function XHomeFurnitureData:SetIsLocked(isLocked)
    self.IsLocked = isLocked
end

function XHomeFurnitureData:GetSuitId()
    if not XTool.IsNumberValid(self.ConfigId) then
        return 0
    end
    local template = XFurnitureConfigs.GetFurnitureTemplateById(self.ConfigId)
    return template.SuitId
end 

function XHomeFurnitureData:GetTypeId()
    if not XTool.IsNumberValid(self.ConfigId) then
        return 0
    end
    local template = XFurnitureConfigs.GetFurnitureTemplateById(self.ConfigId)
    return template.TypeId
end

function XHomeFurnitureData:CheckIsBaseFurniture()
    return self:GetSuitId() == XFurnitureConfigs.BASE_SUIT_ID
end 

function XHomeFurnitureData:GetBaseAttrList()
    return self.BaseAttrList
end

function XHomeFurnitureData:GetBaseAttr()
    return table.unpack(self.BaseAttrList)
end

function XHomeFurnitureData:GetFurnitureName()
    if not XTool.IsNumberValid(self.ConfigId) then
        return ""
    end
    local template = XFurnitureConfigs.GetFurnitureTemplateById(self.ConfigId)
    return template.Name 
end

function XHomeFurnitureData:GetAttrTotal()
    local total = 0
    for _, attr in pairs(self.AttrList) do
        total = total + attr
    end
    return total
end