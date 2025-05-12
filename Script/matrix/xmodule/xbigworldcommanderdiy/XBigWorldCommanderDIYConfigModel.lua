---@class XBigWorldCommanderDIYConfigModel : XModel
local XBigWorldCommanderDIYConfigModel = XClass(XModel, "XBigWorldCommanderDIYConfigModel")

local BigWorldDIYTableKey = {
    BigWorldDIYColor = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldDIYColorGroup = {
        Identifier = "GroupId",
    },
    BigWorldDIYPart = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldDIYPartGroup = {
        Identifier = "TypeId",
    },
    BigWorldDIYRes = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldDIYType = {
        Identifier = "TypeId",
        CacheType = XConfigUtil.CacheType.Normal,
    },
}

function XBigWorldCommanderDIYConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/CommanderDIY", BigWorldDIYTableKey)
end

---@return XTableBigWorldDIYColor[]
function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionColorConfigs()
    return self._ConfigUtil:GetByTableKey(BigWorldDIYTableKey.BigWorldDIYColor) or {}
end

---@return XTableBigWorldDIYColor
function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionColorConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BigWorldDIYTableKey.BigWorldDIYColor, id, false) or {}
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionColorGroupIdById(id)
    local config = self:GetDlcPlayerFashionColorConfigById(id)

    return config.GroupId
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionColorPriorityById(id)
    local config = self:GetDlcPlayerFashionColorConfigById(id)

    return config.Priority
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionColorIconById(id)
    local config = self:GetDlcPlayerFashionColorConfigById(id)

    return config.Icon
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionColorMaterialNameById(id)
    local config = self:GetDlcPlayerFashionColorConfigById(id)

    return config.MaterialName
end

---@return XTableBigWorldDIYColorGroup[]
function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionColorGroupConfigs()
    return self._ConfigUtil:GetByTableKey(BigWorldDIYTableKey.BigWorldDIYColorGroup) or {}
end

---@return XTableBigWorldDIYColorGroup
function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionColorGroupConfigByGroupId(groupId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BigWorldDIYTableKey.BigWorldDIYColorGroup, groupId, false) or {}
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionColorGroupColorIdByGroupId(groupId)
    local config = self:GetDlcPlayerFashionColorGroupConfigByGroupId(groupId)

    return config.ColorId
end

---@return XTableBigWorldDIYPart[]
function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionPartConfigs()
    return self._ConfigUtil:GetByTableKey(BigWorldDIYTableKey.BigWorldDIYPart) or {}
end

---@return XTableBigWorldDIYPart
function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionPartConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BigWorldDIYTableKey.BigWorldDIYPart, id, false) or {}
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionPartNameById(id)
    local config = self:GetDlcPlayerFashionPartConfigById(id)

    return config.Name
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionPartDescriptionById(id)
    local config = self:GetDlcPlayerFashionPartConfigById(id)

    return config.Description
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionPartWorldDescriptionById(id)
    local config = self:GetDlcPlayerFashionPartConfigById(id)

    return config.WorldDescription
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionPartQualityById(id)
    local config = self:GetDlcPlayerFashionPartConfigById(id)

    return config.Quality
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionPartPriorityById(id)
    local config = self:GetDlcPlayerFashionPartConfigById(id)

    return config.Priority
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionPartTypeIdById(id)
    local config = self:GetDlcPlayerFashionPartConfigById(id)

    return config.TypeId
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionPartResIdById(id)
    local config = self:GetDlcPlayerFashionPartConfigById(id)

    return config.ResId
end

---@return XTableBigWorldDIYPartGroup[]
function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionPartGroupConfigs()
    return self._ConfigUtil:GetByTableKey(BigWorldDIYTableKey.BigWorldDIYPartGroup) or {}
end

---@return XTableBigWorldDIYPartGroup
function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionPartGroupConfigByTypeId(typeId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BigWorldDIYTableKey.BigWorldDIYPartGroup, typeId, true) or {}
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionPartGroupPartIdByTypeId(typeId)
    local config = self:GetDlcPlayerFashionPartGroupConfigByTypeId(typeId)

    return config.PartId
end

---@return XTableBigWorldDIYRes[]
function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionResConfigs()
    return self._ConfigUtil:GetByTableKey(BigWorldDIYTableKey.BigWorldDIYRes) or {}
end

---@return XTableBigWorldDIYRes
function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionResConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BigWorldDIYTableKey.BigWorldDIYRes, id, false) or {}
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionResBigIconById(id)
    local config = self:GetDlcPlayerFashionResConfigById(id)

    return config.BigIcon
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionResIconById(id)
    local config = self:GetDlcPlayerFashionResConfigById(id)

    return config.Icon
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionResPartModelIdById(id)
    local config = self:GetDlcPlayerFashionResConfigById(id)

    return config.PartModelId
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionResFashionIdById(id)
    local config = self:GetDlcPlayerFashionResConfigById(id)

    return config.FashionId
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionResColorGroupIdById(id)
    local config = self:GetDlcPlayerFashionResConfigById(id)

    return config.ColorGroupId
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionResDefaultColorIdById(id)
    local config = self:GetDlcPlayerFashionResConfigById(id)

    return config.DefaultColorId
end

---@return XTableBigWorldDIYType[]
function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionTypeConfigs()
    return self._ConfigUtil:GetByTableKey(BigWorldDIYTableKey.BigWorldDIYType) or {}
end

---@return XTableBigWorldDIYType
function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionTypeConfigByTypeId(typeId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BigWorldDIYTableKey.BigWorldDIYType, typeId, false) or {}
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionTypeNameByTypeId(typeId)
    local config = self:GetDlcPlayerFashionTypeConfigByTypeId(typeId)

    return config.Name
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionTypePriorityByTypeId(typeId)
    local config = self:GetDlcPlayerFashionTypeConfigByTypeId(typeId)

    return config.Priority
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionTypeIsRequiredByTypeId(typeId)
    local config = self:GetDlcPlayerFashionTypeConfigByTypeId(typeId)

    return config.IsRequired
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionTypeIsFashionByTypeId(typeId)
    local config = self:GetDlcPlayerFashionTypeConfigByTypeId(typeId)

    return config.IsFashion
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionTypeDefaultPartIdByTypeId(typeId)
    local config = self:GetDlcPlayerFashionTypeConfigByTypeId(typeId)

    return config.DefaultPartId
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionTypeDefaultAnimationParamByTypeId(typeId)
    local config = self:GetDlcPlayerFashionTypeConfigByTypeId(typeId)

    return config.DefaultAnimationParam
end

function XBigWorldCommanderDIYConfigModel:GetDlcPlayerFashionTypeEntryAnimationNameByTypeId(typeId)
    local config = self:GetDlcPlayerFashionTypeConfigByTypeId(typeId)

    return config.EntryAnimationName
end

return XBigWorldCommanderDIYConfigModel
