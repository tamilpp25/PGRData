local XBWCommanderDIYEntityBase = require("XModule/XBigWorldCommanderDIY/XEntity/XBWCommanderDIYEntityBase")
local XBWCommanderDIYColorEntity = require("XModule/XBigWorldCommanderDIY/XEntity/XBWCommanderDIYColorEntity")

---@class XBWCommanderDIYPartEntity : XBWCommanderDIYEntityBase
local XBWCommanderDIYPartEntity = XClass(XBWCommanderDIYEntityBase, "XBWCommanderDIYPartEntity")

function XBWCommanderDIYPartEntity:Ctor()
    self._PartId = 0
    ---@type XBWCommanderDIYColorEntity[]
    self._ColorEntitys = false
end

function XBWCommanderDIYPartEntity:SetData(partId)
    self:SetPartId(partId)
    self:_InitColor()
end

function XBWCommanderDIYPartEntity:IsTemporary()
    return false
end

function XBWCommanderDIYPartEntity:IsEmpty()
    return not XTool.IsNumberValid(self:GetPartId())
end

function XBWCommanderDIYPartEntity:IsAllowSelectColor()
    return not XTool.IsTableEmpty(self:GetColorEntitys())
end

function XBWCommanderDIYPartEntity:SetPartId(partId)
    self._PartId = partId
end

function XBWCommanderDIYPartEntity:GetPartId()
    return self._PartId
end

function XBWCommanderDIYPartEntity:GetTypeId()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionPartTypeIdById(self:GetPartId())
    end

    return 0
end

function XBWCommanderDIYPartEntity:IsRequired()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionTypeIsRequiredByTypeId(self:GetTypeId())
    end

    return false
end

function XBWCommanderDIYPartEntity:IsFashion()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionTypeIsFashionByTypeId(self:GetTypeId())
    end

    return false
end

function XBWCommanderDIYPartEntity:GetName()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionPartNameById(self:GetPartId())
    end

    return ""
end

function XBWCommanderDIYPartEntity:GetDescription()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionPartDescriptionById(self:GetPartId())
    end

    return ""
end

function XBWCommanderDIYPartEntity:GetCurrentGender()
    return self._OwnControl:GetCurrentGender()
end

---@return XBWCommanderDIYColorEntity[]
function XBWCommanderDIYPartEntity:GetColorEntitys()
    return self._ColorEntitys[self:GetCurrentGender()] or {}
end

function XBWCommanderDIYPartEntity:GetResId()
    if not self:IsNil() then
        local gender = self._Model:GetValidGender(self:GetCurrentGender())

        return self:GetResIdByGender(gender)
    end

    return 0
end

function XBWCommanderDIYPartEntity:GetResIdByGender(gender)
    if not self:IsNil() then
        local resIds = self._Model:GetDlcPlayerFashionPartResIdById(self:GetPartId())

        if XTool.IsTableEmpty(resIds) then
            return 0
        end

        return resIds[gender] or 0
    end

    return 0
end

function XBWCommanderDIYPartEntity:GetIcon()
    if not self:IsNil() then
        local resId = self:GetResId()

        return self._Model:GetDlcPlayerFashionResIconById(resId)
    end

    return ""
end

function XBWCommanderDIYPartEntity:GetFashionId()
    local gender = self._Model:GetValidGender(self:GetCurrentGender())

    return self:GetFashionIdByGender(gender)
end

function XBWCommanderDIYPartEntity:GetFashionIdByGender(gender)
    if not self:IsNil() and self:IsFashion() then
        local resId = self:GetResIdByGender(gender)

        return self._Model:GetDlcPlayerFashionResFashionIdById(resId)
    end

    return 0
end

function XBWCommanderDIYPartEntity:GetFashionModelId()
    local gender = self._Model:GetValidGender(self:GetCurrentGender())

    return self:GetFashionModelIdByGender(gender)
end

function XBWCommanderDIYPartEntity:GetFashionModelIdByGender(gender)
    if not self:IsNil() and self:IsFashion() then
        local resId = self:GetResIdByGender(gender)
        local fashionId = self._Model:GetDlcPlayerFashionResFashionIdById(resId)

        return XMVCA.XBigWorldCharacter:GetUiModelIdByFashionId(fashionId)
    end

    return ""
end

function XBWCommanderDIYPartEntity:GetPartModelId()
    local gender = self._Model:GetValidGender(self:GetCurrentGender())

    return self:GetPartModelIdByGender(gender)
end

function XBWCommanderDIYPartEntity:GetPartModelIdByGender(gender)
    if not self:IsNil() and not self:IsFashion() then
        local resId = self:GetResIdByGender(gender)

        return self._Model:GetDlcPlayerFashionResPartModelIdById(resId)
    end

    return ""
end

function XBWCommanderDIYPartEntity:GetPriority()
    if not self:IsNil() then
        return self._Model:GetDlcPlayerFashionPartPriorityById(self:GetPartId()) or 0
    end

    return 0
end

function XBWCommanderDIYPartEntity:OnRelease()
    self._PartId = 0
    self._ColorEntitys = {}
end

function XBWCommanderDIYPartEntity:_InitColor()
    self._ColorEntitys = {}
    if not self:IsNil() then
        for _, gender in pairs(XEnumConst.PlayerFashion.Gender) do
            local resId = self:GetResIdByGender(gender)
            local groupId = self._Model:GetDlcPlayerFashionResColorGroupIdById(resId)

            if XTool.IsNumberValid(groupId) then
                local colorIds = self._Model:GetDlcPlayerFashionColorGroupColorIdByGroupId(groupId)

                for _, colorId in pairs(colorIds) do
                    self:_AddColor(colorId, gender)
                end
            end
        end
        for _, entitys in pairs(self._ColorEntitys) do
            table.sort(entitys, function(entityA, entityB)
                return entityA:GetPriority() > entityB:GetPriority()
            end)
        end
    end
end

function XBWCommanderDIYPartEntity:_AddColor(colorId, gender)
    self._ColorEntitys[gender] = self._ColorEntitys[gender] or {}

    table.insert(self._ColorEntitys[gender], self:AddChildEntity(XBWCommanderDIYColorEntity, colorId))
end

return XBWCommanderDIYPartEntity
