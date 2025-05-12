---@class XBigWorldTeachConfigModel : XModel
local XBigWorldTeachConfigModel = XClass(XModel, "XBigWorldTeachConfigModel")

local HelpCourseTableKey = {
    BigWorldHelpCourse = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldHelpCourseDetail = {},
    BigWorldHelpCourseGroup = {},
}

function XBigWorldTeachConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/HelpCourse", HelpCourseTableKey)
end

---@return XTableBigWorldHelpCourse[]
function XBigWorldTeachConfigModel:GetBigWorldHelpCourseConfigs()
    return self._ConfigUtil:GetByTableKey(HelpCourseTableKey.BigWorldHelpCourse) or {}
end

---@return XTableBigWorldHelpCourse
function XBigWorldTeachConfigModel:GetBigWorldHelpCourseConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(HelpCourseTableKey.BigWorldHelpCourse, id, false) or {}
end

function XBigWorldTeachConfigModel:GetBigWorldHelpCourseGroupIdById(id)
    local config = self:GetBigWorldHelpCourseConfigById(id)

    return config.GroupId
end

function XBigWorldTeachConfigModel:GetBigWorldHelpCoursePriorityById(id)
    local config = self:GetBigWorldHelpCourseConfigById(id)

    return config.Priority
end

function XBigWorldTeachConfigModel:GetBigWorldHelpCourseNameById(id)
    local config = self:GetBigWorldHelpCourseConfigById(id)

    return config.Name
end

function XBigWorldTeachConfigModel:GetBigWorldHelpCourseIsPauseById(id)
    local config = self:GetBigWorldHelpCourseConfigById(id)

    return config.IsPause
end

function XBigWorldTeachConfigModel:GetBigWorldHelpCourseIsForceById(id)
    local config = self:GetBigWorldHelpCourseConfigById(id)

    return config.IsForce
end

---@return XTableBigWorldHelpCourseDetail[]
function XBigWorldTeachConfigModel:GetBigWorldHelpCourseDetailConfigs()
    return self._ConfigUtil:GetByTableKey(HelpCourseTableKey.BigWorldHelpCourseDetail) or {}
end

---@return XTableBigWorldHelpCourseDetail
function XBigWorldTeachConfigModel:GetBigWorldHelpCourseDetailConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(HelpCourseTableKey.BigWorldHelpCourseDetail, id, false) or {}
end

function XBigWorldTeachConfigModel:GetBigWorldHelpCourseDetailHelpCourseIdById(id)
    local config = self:GetBigWorldHelpCourseDetailConfigById(id)

    return config.HelpCourseId
end

function XBigWorldTeachConfigModel:GetBigWorldHelpCourseDetailPriorityById(id)
    local config = self:GetBigWorldHelpCourseDetailConfigById(id)

    return config.Priority
end

function XBigWorldTeachConfigModel:GetBigWorldHelpCourseDetailNameById(id)
    local config = self:GetBigWorldHelpCourseDetailConfigById(id)

    return config.Name
end

function XBigWorldTeachConfigModel:GetBigWorldHelpCourseDetailImageById(id)
    local config = self:GetBigWorldHelpCourseDetailConfigById(id)

    return config.Image
end

function XBigWorldTeachConfigModel:GetBigWorldHelpCourseDetailDescById(id)
    local config = self:GetBigWorldHelpCourseDetailConfigById(id)

    return config.Desc
end

---@return XTableBigWorldHelpCourseGroup[]
function XBigWorldTeachConfigModel:GetBigWorldHelpCourseGroupConfigs()
    return self._ConfigUtil:GetByTableKey(HelpCourseTableKey.BigWorldHelpCourseGroup) or {}
end

---@return XTableBigWorldHelpCourseGroup
function XBigWorldTeachConfigModel:GetBigWorldHelpCourseGroupConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(HelpCourseTableKey.BigWorldHelpCourseGroup, id, false) or {}
end

function XBigWorldTeachConfigModel:GetBigWorldHelpCourseGroupPriorityById(id)
    local config = self:GetBigWorldHelpCourseGroupConfigById(id)

    return config.Priority
end

function XBigWorldTeachConfigModel:GetBigWorldHelpCourseGroupNameById(id)
    local config = self:GetBigWorldHelpCourseGroupConfigById(id)

    return config.Name
end

function XBigWorldTeachConfigModel:GetBigWorldHelpCourseGroupIconById(id)
    local config = self:GetBigWorldHelpCourseGroupConfigById(id)

    return config.Icon
end

return XBigWorldTeachConfigModel
