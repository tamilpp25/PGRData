---@class XBigWorldBackpackConfigModel : XModel
local XBigWorldBackpackConfigModel = XClass(XModel, "XBigWorldBackpackConfigModel")

local BackpackTableKey = {
    BigWorldBackpackType = {
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "Type",
    },
}

function XBigWorldBackpackConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Backpack", BackpackTableKey)
end

---@return XTableBigWorldBackpackType[]
function XBigWorldBackpackConfigModel:GetBackpackTypeConfigs()
    return self._ConfigUtil:GetByTableKey(BackpackTableKey.BigWorldBackpackType) or {}
end

---@return XTableBigWorldBackpackType
function XBigWorldBackpackConfigModel:GetBackpackTypeConfigByType(type)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(BackpackTableKey.BigWorldBackpackType, type, false) or {}
end

function XBigWorldBackpackConfigModel:GetBackpackTypeDescriptionByType(type)
    local config = self:GetBackpackTypeConfigByType(type)

    return config.Description
end

function XBigWorldBackpackConfigModel:GetBackpackTypeIconUrlByType(type)
    local config = self:GetBackpackTypeConfigByType(type)

    return config.IconUrl
end

function XBigWorldBackpackConfigModel:GetBackpackTypeTagTypeByType(type)
    local config = self:GetBackpackTypeConfigByType(type)

    return config.TagType
end

function XBigWorldBackpackConfigModel:GetBackpackTypePriorityByType(type)
    local config = self:GetBackpackTypeConfigByType(type)

    return config.Priority
end

function XBigWorldBackpackConfigModel:GetBackpackTypeItemTypesByType(type)
    local config = self:GetBackpackTypeConfigByType(type)

    return config.ItemTypes
end

return XBigWorldBackpackConfigModel
